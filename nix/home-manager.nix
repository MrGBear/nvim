{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.neovim;
  mkNeovim = import ./mkNeovim.nix;
  validLivePath = cfg.configPath != null && lib.hasPrefix "/" cfg.configPath;
in
{
  options.neovim = {
    profile = lib.mkOption {
      type = lib.types.enum [
        "full"
        "minimal"
      ];
      default = "full";
      description = "Select the editor's plugin, parser and runtime-tool profile";
    };
    configMode = lib.mkOption {
      type = lib.types.enum [
        "immutable"
        "live"
      ];
      default = "immutable";
      description = "Load packaged Lua or the live checkout supplied by configPath";
    };
    configPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/user/neovim";
      description = "Absolute checkout directory containing init.lua; required only in live mode";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.configMode == "live" -> validLivePath;
        message = "neovim.configPath must be an absolute checkout path when configMode is live.";
      }
    ];

    home.packages = [
      (mkNeovim {
        inherit pkgs;
        inherit (cfg) profile configMode;
      })
    ];
    home.sessionVariables = {
      EDITOR = lib.mkDefault "nvim";
      VISUAL = lib.mkDefault "nvim";
    };
    xdg.configFile."nvim" = lib.mkIf (cfg.configMode == "live" && validLivePath) {
      source = config.lib.file.mkOutOfStoreSymlink cfg.configPath;
    };
  };
}
