{
  description = "Nix-managed Neovim with full and minimal profiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      git-hooks,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      mkNeovim = import ./nix/mkNeovim.nix;
      packagesFor =
        pkgs:
        let
          nvim = mkNeovim { inherit pkgs; };
        in
        {
          inherit nvim;
          default = nvim;
          nvim-minimal = mkNeovim {
            inherit pkgs;
            profile = "minimal";
          };
          nvim-runtime = mkNeovim {
            inherit pkgs;
            configMode = "live";
          };
          nvim-minimal-runtime = mkNeovim {
            inherit pkgs;
            profile = "minimal";
            configMode = "live";
          };
          nvim-dev = mkNeovim {
            inherit pkgs;
            configMode = "live";
            appName = "nvim-dev";
          };
        };
    in
    {
      lib = { inherit mkNeovim; };
      homeManagerModules.default = ./nix/home-manager.nix;
      packages = forAllSystems (system: packagesFor nixpkgs.legacyPackages.${system});
      checks = forAllSystems (system: {
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
            typos = {
              enable = true;
              # Bracketed keybinding mnemonics split otherwise valid words.
              settings.config.type.lua.extend-ignore-re = [ "\\[[A-Za-z]\\][A-Za-z]+" ];
            };
          };
        };
      });
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          hookCheck = self.checks.${system}.pre-commit-check;
        in
        {
          git-hooks = pkgs.mkShell {
            inherit (hookCheck) shellHook;
            packages = hookCheck.enabledPackages;
          };
          default = pkgs.mkShell {
            packages = [
              (packagesFor pkgs).nvim-dev
              pkgs.nixfmt-tree
              pkgs.statix
              pkgs.deadnix
              pkgs.stylua
              pkgs.luaPackages.luacheck
              pkgs.lua-language-server
            ];
            shellHook = ''
              config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
              target="$config_home/nvim-dev"
              source="$PWD"
              if [ ! -f "$source/init.lua" ]; then
                echo "nvim-dev: enter the repository root to link the live config" >&2
              elif [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
                :
              elif [ -e "$target" ] || [ -L "$target" ]; then
                echo "nvim-dev: leaving existing $target untouched" >&2
              else
                mkdir -p "$config_home"
                ln -s "$source" "$target"
              fi
              unset config_home target source
            '';
          };
        }
      );
    };
}
