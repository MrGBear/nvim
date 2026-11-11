require('treesitter-context').setup {}

vim.keymap.set('n', '<leader>ts', function() require('treesitter-context').toggle() end, { desc = '[T]oggle [S]ticky' })
