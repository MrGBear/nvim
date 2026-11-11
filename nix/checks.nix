{ pkgs, mkNeovim }:
let
  inherit (pkgs) lib;
  source = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../init.lua
      ../lua
      ../after
    ];
  };
  fullSelection = import ./plugins.nix {
    inherit pkgs;
    profile = "full";
  };
  parserEditor = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
    wrapRc = false;
    plugins = lib.filter (
      plugin:
      builtins.elem plugin.pname [
        "nvim-treesitter"
        "nvim-treesitter-textobjects"
      ]
    ) fullSelection.plugins;
  };
  smoke =
    profile: configMode:
    let
      editor = mkNeovim {
        inherit pkgs profile configMode;
        appName = "nvim-smoke";
      };
    in
    pkgs.runCommand "neovim-${profile}-${configMode}-smoke"
      {
        nativeBuildInputs = [ editor ];
        EDITOR_SMOKE_PROFILE = profile;
        EDITOR_SMOKE_MODE = configMode;
        EDITOR_SMOKE_NIXPKGS = toString pkgs.path;
        EDITOR_SMOKE_GRAMMARS = builtins.toJSON editor.grammarNames;
        EDITOR_SMOKE_ROOT = if configMode == "immutable" then toString editor.configRoot else "";
      }
      ''
        export HOME="$TMPDIR/home"
        export XDG_CONFIG_HOME="$HOME/config"
        export XDG_DATA_HOME="$HOME/data"
        export XDG_STATE_HOME="$HOME/state"
        export XDG_CACHE_HOME="$HOME/cache"
        export XDG_RUNTIME_DIR="$HOME/runtime"
        unset VIMINIT EXINIT NVIM_LOG_FILE NVIM_RPLUGIN_MANIFEST
        mkdir -p "$XDG_CONFIG_HOME" "$XDG_RUNTIME_DIR" "$TMPDIR/project/bin"
        chmod 700 "$XDG_RUNTIME_DIR"
        ${lib.optionalString (configMode == "live") ''
          cp -R ${source} "$TMPDIR/live"
          chmod -R u+w "$TMPDIR/live"
          ln -s "$TMPDIR/live" "$XDG_CONFIG_HOME/nvim-smoke"
          export EDITOR_SMOKE_ROOT="$XDG_CONFIG_HOME/nvim-smoke"
          export EDITOR_SMOKE_LIVE_SOURCE="$TMPDIR/live"
        ''}
        # A project formatter must beat the wrapper's fallback tools.
        cat > "$TMPDIR/project/bin/stylua" <<'SH'
        #!${pkgs.runtimeShell}
        exit 0
        SH
        chmod +x "$TMPDIR/project/bin/stylua"
        export PATH="$TMPDIR/project/bin:$PATH"
        export EDITOR_SMOKE_PROJECT_BIN="$TMPDIR/project/bin"
        cd "$TMPDIR/project"
        if ! nvim-smoke --headless -i NONE -n \
          --cmd "lua dofile('${../tests/smoke.lua}').guard()" \
          -c "lua dofile('${../tests/smoke.lua}').run()" > "$TMPDIR/startup.log" 2>&1; then
          cat "$TMPDIR/startup.log"
          exit 1
        fi
        cat "$TMPDIR/startup.log"
        mkdir -p "$out"
        cp "$TMPDIR/startup.log" "$out/startup.log"
      '';
in
{
  full-immutable = smoke "full" "immutable";
  full-live = smoke "full" "live";
  minimal-immutable = smoke "minimal" "immutable";
  minimal-live = smoke "minimal" "live";
  aliases =
    let
      editor = mkNeovim {
        inherit pkgs;
        profile = "minimal";
      };
    in
    pkgs.runCommand "neovim-editor-aliases" { } ''
      test -L ${editor}/bin/vi
      test -L ${editor}/bin/vim
      ${editor}/bin/vi --version > /dev/null
      ${editor}/bin/vim --version > /dev/null
      touch "$out"
    '';
  parsers =
    pkgs.runCommand "neovim-all-parsers-smoke"
      {
        nativeBuildInputs = [ parserEditor ];
        EDITOR_SMOKE_GRAMMARS = builtins.toJSON fullSelection.grammarNames;
      }
      ''
        export HOME="$TMPDIR/home"
        export XDG_CONFIG_HOME="$HOME/config"
        export XDG_DATA_HOME="$HOME/data"
        export XDG_STATE_HOME="$HOME/state"
        export XDG_CACHE_HOME="$HOME/cache"
        unset VIMINIT EXINIT
        mkdir -p "$HOME"
        nvim --headless -u NONE -i NONE -n -c packloadall \
          -c "lua dofile('${../tests/smoke.lua}').parsers()"
        touch "$out"
      '';
  lint =
    pkgs.runCommand "neovim-nix-lint"
      {
        nativeBuildInputs = [
          pkgs.nixfmt
          pkgs.statix
          pkgs.deadnix
          pkgs.luaPackages.luacheck
        ];
      }
      ''
        cp ${../flake.nix} flake.nix
        mkdir nix
        cp ${./plugins.nix} ${./mkNeovim.nix} ${./java-tools.nix} ${./home-manager.nix} ${./checks.nix} nix/
        nixfmt --check flake.nix nix/*.nix
        statix check .
        deadnix --fail .
        luacheck ${../tests/smoke.lua} --std luajit --globals vim editor_smoke_errors --no-max-line-length
        touch "$out"
      '';
}
