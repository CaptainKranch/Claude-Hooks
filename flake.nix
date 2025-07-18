{
  description = "Claude Hooks Using Nix!";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
  };

  outputs = { self, nixpkgs, agenix }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      
      python-with-packages = pkgs.python313.withPackages (ps: with ps; [
        python-dotenv
      ]);
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          python-with-packages
          age
          agenix.packages.${system}.default
        ];
        
        shellHook = ''
          # Make git hook available
          export PATH="$PWD/scripts:$PATH"
        '';
      };

      packages.${system} = {
        test = pkgs.writeShellScriptBin "test" ''
          ${python-with-packages}/bin/python ${./scripts/test.py} "$@"
        '';
        
        git-hook = pkgs.writeShellScriptBin "git-hook" ''
          ${python-with-packages}/bin/python ${./scripts/git_hook.py} "$@"
        '';
        
        dangerous-commands = pkgs.writeShellScriptBin "dangerous-commands" ''
          ${python-with-packages}/bin/python ${./scripts/dangerous_commands.py} "$@"
        '';
        
        notification = pkgs.writeShellScriptBin "notification" ''
          # Try to decrypt secrets from multiple locations
          SECRET_LOCATIONS=(
            "${./secrets/encrypted}"         # From the flake source (works with nix run github:...)
            "./secrets/encrypted"            # Current directory (for local dev)
            "$PWD/secrets/encrypted"         # Absolute path to current directory
            "./secrets"                      # Legacy location for submodule
            "$PWD/secrets"                   # Legacy absolute path
          )
          
          FOUND_SECRETS=false
          for secret_dir in "''${SECRET_LOCATIONS[@]}"; do
            if [ -f "$secret_dir/telegram-token.age" ] && [ -f "$secret_dir/telegram-chat-id.age" ]; then
              # Try multiple SSH key types
              SSH_KEYS=("$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ecdsa")
              
              for ssh_key in "''${SSH_KEYS[@]}"; do
                if [ -f "$ssh_key" ]; then
                  if BOT_TOKEN=$(${pkgs.age}/bin/age -d -i "$ssh_key" "$secret_dir/telegram-token.age" 2>&1) && \
                     CHAT_ID=$(${pkgs.age}/bin/age -d -i "$ssh_key" "$secret_dir/telegram-chat-id.age" 2>&1); then
                    export CLAUDE_TELEGRAM_BOT_TOKEN="$BOT_TOKEN"
                    export CLAUDE_TELEGRAM_CHAT_ID="$CHAT_ID"
                    FOUND_SECRETS=true
                    echo "✅ Successfully decrypted secrets from: $secret_dir" >&2
                    break 2  # Break out of both loops
                  fi
                fi
              done
            fi
          done
          
          # Check if credentials are available
          if [ "$FOUND_SECRETS" = "false" ]; then
            if [ -z "$CLAUDE_TELEGRAM_BOT_TOKEN" ] || [ -z "$CLAUDE_TELEGRAM_CHAT_ID" ]; then
              echo "ℹ️  Telegram credentials not found in Silencer submodule." >&2
              echo "   For admins with Silencer access:" >&2
              echo "   nix run 'github:CaptainKranch/Claude-Hooks?submodules=1#notification'" >&2
              echo "" >&2
              echo "   For others: Set environment variables:" >&2
              echo "   export CLAUDE_TELEGRAM_BOT_TOKEN='your_token'" >&2
              echo "   export CLAUDE_TELEGRAM_CHAT_ID='your_chat_id'" >&2
              echo "" >&2
            fi
          fi
          
          ${python-with-packages}/bin/python ${./scripts/notifications.py} "$@"
        '';
        
        create-telegram-secrets = pkgs.writeShellScriptBin "create-telegram-secrets" ''
          echo "Setting up encrypted Telegram secrets..."
          
          # Find available SSH public keys
          SSH_PUB_KEYS=()
          SSH_KEY_NAMES=()
          
          for key_type in id_ed25519 id_rsa id_ecdsa; do
            if [ -f "$HOME/.ssh/$key_type.pub" ]; then
              SSH_PUB_KEYS+=("$HOME/.ssh/$key_type.pub")
              SSH_KEY_NAMES+=("$key_type")
            fi
          done
          
          if [ ''${#SSH_PUB_KEYS[@]} -eq 0 ]; then
            echo "❌ Error: No SSH public keys found!" >&2
            echo "   Expected one of: ~/.ssh/id_ed25519.pub, ~/.ssh/id_rsa.pub, ~/.ssh/id_ecdsa.pub" >&2
            echo "   Please generate an SSH key first with: ssh-keygen -t ed25519" >&2
            exit 1
          fi
          
          # Select SSH key to use
          SELECTED_KEY=""
          if [ ''${#SSH_PUB_KEYS[@]} -eq 1 ]; then
            SELECTED_KEY="''${SSH_PUB_KEYS[0]}"
            echo ""
            echo "Found SSH key: $SELECTED_KEY"
          else
            echo ""
            echo "Multiple SSH keys found. Please select which one to use:"
            for i in "''${!SSH_KEY_NAMES[@]}"; do
              echo "  $((i+1))) ''${SSH_KEY_NAMES[$i]}"
            done
            
            while true; do
              read -p "Enter selection (1-''${#SSH_KEY_NAMES[@]}): " selection
              if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ''${#SSH_KEY_NAMES[@]} ]; then
                SELECTED_KEY="''${SSH_PUB_KEYS[$((selection-1))]}"
                break
              else
                echo "Invalid selection. Please try again."
              fi
            done
          fi
          
          TEMP_TOKEN=$(mktemp)
          TEMP_CHAT=$(mktemp)
          
          echo ""
          echo "Please enter your Telegram Bot Token:"
          echo "(format: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz)"
          read -r TELEGRAM_TOKEN
          echo "$TELEGRAM_TOKEN" > "$TEMP_TOKEN"
          
          echo ""
          echo "Please enter your Telegram Chat ID:"
          echo "(format: -123456789 or 123456789)"
          read -r TELEGRAM_CHAT
          echo "$TELEGRAM_CHAT" > "$TEMP_CHAT"
          
          mkdir -p secrets
          
          echo ""
          echo "Encrypting secrets with: $SELECTED_KEY"
          
          if ! ${pkgs.age}/bin/age -e -R "$SELECTED_KEY" -o secrets/telegram-token.age < "$TEMP_TOKEN"; then
            echo "❌ Error: Failed to encrypt bot token" >&2
            rm -f "$TEMP_TOKEN" "$TEMP_CHAT"
            exit 1
          fi
          
          if ! ${pkgs.age}/bin/age -e -R "$SELECTED_KEY" -o secrets/telegram-chat-id.age < "$TEMP_CHAT"; then
            echo "❌ Error: Failed to encrypt chat ID" >&2
            rm -f "$TEMP_TOKEN" "$TEMP_CHAT" secrets/telegram-token.age
            exit 1
          fi
          
          rm -f "$TEMP_TOKEN" "$TEMP_CHAT"
          
          echo ""
          echo "✅ Secrets created successfully!"
          echo "Files created:"
          echo "  - secrets/telegram-token.age (encrypted bot token)"
          echo "  - secrets/telegram-chat-id.age (encrypted chat ID)"
          echo ""
          echo "These files are encrypted with $SELECTED_KEY and safe to commit."
          echo ""
          echo "Note: To decrypt these secrets, you'll need the corresponding private key."
        '';
        
        # Agenix wrapper for managing secrets
        secrets = pkgs.writeShellScriptBin "secrets" ''
          echo "Claude-Hooks Secrets Management"
          echo "=============================="
          echo ""
          echo "Commands:"
          echo "  edit <secret>    - Edit an encrypted secret"
          echo "  rekey           - Re-encrypt all secrets with updated keys"
          echo "  create <secret> - Create a new encrypted secret"
          echo ""
          
          case "$1" in
            edit)
              if [ -z "$2" ]; then
                echo "Usage: $0 edit <secret-name>"
                echo "Example: $0 edit telegram-token"
                exit 1
              fi
              ${agenix.packages.${system}.default}/bin/agenix -e "secrets/encrypted/$2.age"
              ;;
            rekey)
              ${agenix.packages.${system}.default}/bin/agenix -r
              ;;
            create)
              if [ -z "$2" ]; then
                echo "Usage: $0 create <secret-name>"
                echo "Example: $0 create telegram-token"
                exit 1
              fi
              ${agenix.packages.${system}.default}/bin/agenix -e "secrets/encrypted/$2.age"
              ;;
            *)
              echo "Unknown command: $1"
              echo "Use: edit, rekey, or create"
              exit 1
              ;;
          esac
        '';
      };
    };
}
