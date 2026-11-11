# Personal Neovim Dots

> [!NOTE] Attribution
> I started with this config from the original [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) and then adapted it to use the nix-wrapper like in [kickstart-nix.nvim](https://github.com/nix-community/kickstart-nix.nvim)

Neovim >= 0.12 with plugins, parsers and runtime tools supplied by Nix.

## Run and develop

```sh
nix run .                 # Packaged full profile
nix run .#nvim-minimal    # Packaged minimal profile
direnv allow              # Live checkout, isolated nvim-dev state loaded via dev shell
```

The development shell links this checkout into the `nvim-dev` configuration slot,
without replacing an existing target. It keeps editor data/cache/state separate from `nvim`.
`<leader>sn` searches the active configuration in either mode.

| Profile | Purpose |
| --- | --- |
| `full` | Core editing plus LSP, completion, formatting, linting, debugging and richer diagnostics/Markdown UI |
| `minimal` | Core editing, Git/search/navigation, undo history and Treesitter. No language servers, completion, formatting, linting or debugging |

Project builds still use their own development shells and build wrappers. LuaLS
respects project `.luarc.json`/`.luarc.jsonc` files. Optional modules are loaded in
the explicit core/full lists in `lua/custom/plugins/init.lua`; autopairs and
Neo-tree examples remain disabled.

## Home Manager

With this flake available as an input named `nvim`, import its module:

```nix
{
  imports = [ inputs.nvim.homeManagerModules.default ];
  neovim = {
    profile = "full"; # or "minimal"
    configMode = "live"; # defaults to "immutable"
    configPath = "/absolute/path/to/editor"; # directory containing init.lua
  };
}
```

## Update dependencies

Change plugin/parser/tool declarations in `nix/` or input pins in `flake.nix`, then:

```sh
nix flake update
nix flake check
```

Review and commit the dependency changes with `flake.lock`. Rebuild/reload the
wrapper after dependency edits; Lua edits in the live shell only need an editor
restart.

Run `:checkhealth kickstart` to check the selected profile's runtime tools.
See [Nix development shells](https://nix.dev/tutorials/first-steps/declarative-shell.html)
and [direnv](https://direnv.net/) for the underlying workflow.
