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
          # Try to decrypt secrets from local directory (works with submodules)
          if [ -f "secrets/telegram-token.age" ] && [ -f "secrets/telegram-chat-id.age" ]; then
            export CLAUDE_TELEGRAM_BOT_TOKEN=$(${pkgs.age}/bin/age -d -i ~/.ssh/id_ed25519 secrets/telegram-token.age 2>/dev/null || echo "")
            export CLAUDE_TELEGRAM_CHAT_ID=$(${pkgs.age}/bin/age -d -i ~/.ssh/id_ed25519 secrets/telegram-chat-id.age 2>/dev/null || echo "")
          fi
          
          ${python-with-packages}/bin/python ${./scripts/notifications.py} "$@"
        '';
        
        create-telegram-secrets = pkgs.writeShellScriptBin "create-telegram-secrets" ''
          echo "Setting up encrypted Telegram secrets..."
          
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
          echo "Encrypting secrets..."
          
          ${pkgs.age}/bin/age -e -R ~/.ssh/id_ed25519.pub -o secrets/telegram-token.age < "$TEMP_TOKEN"
          ${pkgs.age}/bin/age -e -R ~/.ssh/id_ed25519.pub -o secrets/telegram-chat-id.age < "$TEMP_CHAT"
          
          rm -f "$TEMP_TOKEN" "$TEMP_CHAT"
          
          echo ""
          echo "✅ Secrets created successfully!"
          echo "Files created:"
          echo "  - secrets/telegram-token.age (encrypted bot token)"
          echo "  - secrets/telegram-chat-id.age (encrypted chat ID)"
          echo ""
          echo "These files are encrypted with your SSH key and safe to commit."
        '';
      };
    };
}
