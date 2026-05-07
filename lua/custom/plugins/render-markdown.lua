---@module 'lazy'
---@type LazySpec
return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = { 'markdown', 'norg', 'org' },
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {},
}
