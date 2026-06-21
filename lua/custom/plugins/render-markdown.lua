vim.pack.add { 'https://github.com/MeanderingProgrammer/render-markdown.nvim' }

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'norg', 'org' },
  callback = function()
    require('render-markdown').setup({})
  end,
})
