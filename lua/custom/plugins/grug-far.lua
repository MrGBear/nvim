vim.pack.add { 'https://github.com/MagicDuck/grug-far.nvim' }

require('grug-far').setup({
  -- basic configuration
})

vim.keymap.set('n', '<leader>sr', function() require('grug-far').open() end, { desc = '[S]earch and [R]eplace (Grug Far)' })
