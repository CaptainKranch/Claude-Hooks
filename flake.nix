{
  description = "Claude Hooks Using Nix!";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          python313
        ];
        
        shellHook = ''
          # Make git hook available
          export PATH="$PWD/scripts:$PATH"
        '';
      };
      
      packages.${system}.git-hook = pkgs.writeShellScriptBin "git-hook" ''
        ${pkgs.python312}/bin/python ${./scripts/git_hook.py} "$@"
      '';
    };
}
