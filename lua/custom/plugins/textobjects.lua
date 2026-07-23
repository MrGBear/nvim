vim.pack.add { 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects' }

require('nvim-treesitter-textobjects').setup {
  select = {
    enable = true,
    lookahead = true,
  },
  move = {
    enable = true,
    set_jumps = true,
  },
}

local select = require('nvim-treesitter-textobjects.select')
local move = require('nvim-treesitter-textobjects.move')

-- Select
vim.keymap.set({ 'x', 'o' }, 'af', function() select.select_textobject('@function.outer', 'textobjects') end, { desc = 'Select [A]round [F]unction' })
vim.keymap.set({ 'x', 'o' }, 'if', function() select.select_textobject('@function.inner', 'textobjects') end, { desc = 'Select [I]nside [F]unction' })
vim.keymap.set({ 'x', 'o' }, 'ac', function() select.select_textobject('@class.outer', 'textobjects') end, { desc = 'Select [A]round [C]lass' })
vim.keymap.set({ 'x', 'o' }, 'ic', function() select.select_textobject('@class.inner', 'textobjects') end, { desc = 'Select [I]nside [C]lass' })
-- Using ap/ip to avoid conflict with mini.ai's aa/ii
vim.keymap.set({ 'x', 'o' }, 'ap', function() select.select_textobject('@parameter.outer', 'textobjects') end, { desc = 'Select [A]round [P]arameter' })
vim.keymap.set({ 'x', 'o' }, 'ip', function() select.select_textobject('@parameter.inner', 'textobjects') end, { desc = 'Select [I]nside [P]arameter' })

-- Move
vim.keymap.set({ 'n', 'x', 'o' }, ']f', function() move.goto_next_start('@function.outer', 'textobjects') end, { desc = 'Next [F]unction start' })
vim.keymap.set({ 'n', 'x', 'o' }, ']c', function() move.goto_next_start('@class.outer', 'textobjects') end, { desc = 'Next [C]lass start' })
vim.keymap.set({ 'n', 'x', 'o' }, ']F', function() move.goto_next_end('@function.outer', 'textobjects') end, { desc = 'Next [F]unction end' })
vim.keymap.set({ 'n', 'x', 'o' }, ']C', function() move.goto_next_end('@class.outer', 'textobjects') end, { desc = 'Next [C]lass end' })

vim.keymap.set({ 'n', 'x', 'o' }, '[f', function() move.goto_previous_start('@function.outer', 'textobjects') end, { desc = 'Previous [F]unction start' })
vim.keymap.set({ 'n', 'x', 'o' }, '[c', function() move.goto_previous_start('@class.outer', 'textobjects') end, { desc = 'Previous [C]lass start' })
vim.keymap.set({ 'n', 'x', 'o' }, '[F', function() move.goto_previous_end('@function.outer', 'textobjects') end, { desc = 'Previous [F]unction end' })
vim.keymap.set({ 'n', 'x', 'o' }, '[C', function() move.goto_previous_end('@class.outer', 'textobjects') end, { desc = 'Previous [C]lass end' })
