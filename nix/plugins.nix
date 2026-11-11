{ pkgs, profile }:
let
  inherit (pkgs) lib vimPlugins;
  minimalGrammars = [
    "bash"
    "nix"
    "lua"
    "luadoc"
    "json"
    "yaml"
    "markdown"
    "markdown_inline"
    "diff"
    "vim"
    "vimdoc"
    "query"
  ];
  treesitter =
    if profile == "full" then
      vimPlugins.nvim-treesitter.withAllGrammars
    else
      vimPlugins.nvim-treesitter.withPlugins (grammars: map (name: grammars.${name}) minimalGrammars);
  # Avoid a second bare treesitter derivation with the same package name.
  textobjects = vimPlugins.nvim-treesitter-textobjects.overrideAttrs {
    passthru.dependencies = [ treesitter ];
  };
in
{
  grammarNames =
    if profile == "full" then
      map (grammar: grammar.language) vimPlugins.nvim-treesitter.allGrammars
    else
      minimalGrammars;
  plugins =
    (with vimPlugins; [
      guess-indent-nvim
      gitsigns-nvim
      which-key-nvim
      tokyonight-nvim
      mini-nvim
      telescope-nvim
      plenary-nvim
      telescope-fzf-native-nvim
      telescope-ui-select-nvim
      oil-nvim
      undotree
      grug-far-nvim
      treesitter
      nvim-treesitter-context
      textobjects
    ])
    ++ lib.optionals (profile == "full") (
      with vimPlugins;
      [
        todo-comments-nvim
        nvim-lspconfig
        nvim-jdtls
        fidget-nvim
        conform-nvim
        luasnip
        blink-cmp
        nvim-dap
        nvim-dap-ui
        nvim-nio
        nvim-lint
        trouble-nvim
        render-markdown-nvim
      ]
    );
}
