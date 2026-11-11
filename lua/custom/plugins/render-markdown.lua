vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'norg', 'org' },
  callback = function() require('render-markdown').setup { latex = { enabled = false } } end,
})
