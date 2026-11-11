{
  pkgs,
  profile ? "full",
  configMode ? "immutable",
  appName ? "nvim",
}:
assert builtins.elem profile [
  "full"
  "minimal"
];
assert builtins.elem configMode [
  "immutable"
  "live"
];
assert builtins.match "[a-zA-Z0-9][a-zA-Z0-9_-]*" appName != null;
let
  inherit (pkgs) lib;
  selection = import ./plugins.nix { inherit pkgs profile; };
  javaTools = import ./java-tools.nix pkgs;
  pluginInfo = pkgs.neovimUtils.makeVimPackageInfo selection.plugins;
  packDir = pkgs.neovimUtils.packDir { myNeovimPackages = pluginInfo.vimPackage; };
  configSource = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../init.lua
      ../lua
      ../after
    ];
  };
  runtimePackages =
    (with pkgs; [
      fish
      git
      ripgrep
      fd
      trash-cli
      ouch
      unzip
      gnutar
      p7zip
      diffutils
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.wl-clipboard ]
    ++ lib.optionals (profile == "full") (
      (with pkgs; [
        lua-language-server
        nixd
        basedpyright
        vscode-langservers-extracted
        yaml-language-server
        lemminx
        ast-grep
        stylua
        shfmt
        shellcheck
        markdownlint-cli
        nixfmt
        statix
        deadnix
      ])
      ++ javaTools.packages
    );
  wrapped = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
    extraName = "-${profile}-${configMode}-${appName}";
    inherit (selection) plugins;
    # Native advised snippets must precede setup(), not follow our init.lua.
    autoconfigure = false;
    autowrapRuntimeDeps = false;
    waylandSupport = false;
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
    withPerl = false;
    viAlias = appName == "nvim";
    vimAlias = appName == "nvim";
    wrapperArgs = [
      "--set"
      "NVIM_APPNAME"
      appName
      "--suffix"
      "PATH"
      ":"
      (lib.makeBinPath (runtimePackages ++ pluginInfo.runtimeDeps))
    ]
    ++ lib.optionals (profile == "full") (
      lib.concatLists (
        lib.mapAttrsToList (name: value: [
          "--set"
          name
          value
        ]) javaTools.sessionVariables
      )
    );
    luaRcContent = ''
      vim.g.editor_profile = ${builtins.toJSON profile}
      vim.g.editor_nixpkgs = ${builtins.toJSON (toString pkgs.path)}
      vim.g.editor_config_root = ${
        if configMode == "immutable" then
          builtins.toJSON (toString configSource)
        else
          "vim.fn.stdpath('config')"
      }
      local root = vim.g.editor_config_root
      vim.opt.runtimepath:remove(vim.fn.stdpath('config'))
      vim.opt.runtimepath:remove(vim.fn.stdpath('config') .. '/after')
      vim.opt.runtimepath:remove(vim.fn.stdpath('data') .. '/site')
      vim.opt.runtimepath:remove(vim.fn.stdpath('data') .. '/site/after')
      vim.opt.runtimepath:prepend(root)
      vim.opt.runtimepath:append(root .. '/after')
      vim.opt.packpath = { ${builtins.toJSON (toString packDir)} }
      vim.g.mapleader = ' '
      vim.g.maplocalleader = ' '
      ${lib.concatStringsSep "\n" pluginInfo.pluginAdvisedLua}
      vim.cmd('packloadall')
      dofile(root .. '/init.lua')
    '';
  };
in
wrapped.overrideAttrs (old: {
  postBuild =
    old.postBuild
    + lib.optionalString (appName != "nvim") ''
      mv "$out/bin/nvim" "$out/bin/${appName}"
    '';
  meta = old.meta // {
    mainProgram = appName;
  };
  passthru = old.passthru // {
    inherit profile configMode appName;
    inherit (selection) grammarNames;
    configRoot = if configMode == "immutable" then configSource else null;
  };
})
