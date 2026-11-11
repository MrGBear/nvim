-- Undotree - visualize undo history
-- https://github.com/mbbill/undotree

vim.g.undotree_SetFocusWhenToggle = 1
vim.keymap.set('n', '<leader>u', '<cmd>UndotreeToggle<cr>', { desc = 'Toggle [U]ndotree' })
