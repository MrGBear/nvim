-- Undotree - visualize undo history
-- https://github.com/jiaoshijie/undotree

vim.pack.add { 'https://github.com/jiaoshijie/undotree' }
require('undotree').setup({})
vim.keymap.set('n', '<leader>u', '<cmd>lua require("undotree").toggle()<cr>', { desc = 'Toggle [U]ndotree' })
