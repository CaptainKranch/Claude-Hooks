{
  description = "Claude Hooks Using Nix!";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
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
          ${python-with-packages}/bin/python ${./scripts/notifications.py} "$@"
        '';
      };
    };
}
