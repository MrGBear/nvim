-- Keep module order and profile membership explicit; dependencies come from Nix.
local core = {
  'custom.plugins.oil',
  'custom.plugins.undotree',
  'custom.plugins.grug-far',
  'custom.plugins.treesitter-context',
  'custom.plugins.textobjects',
}
local full = {
  'kickstart.plugins.debug',
  'kickstart.plugins.lint',
  'custom.plugins.trouble',
  'custom.plugins.render-markdown',
}

for _, module in ipairs(core) do
  require(module)
end
if vim.g.editor_profile == 'full' then
  for _, module in ipairs(full) do
    require(module)
  end
end
