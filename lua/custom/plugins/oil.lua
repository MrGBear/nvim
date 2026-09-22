vim.pack.add { 'https://github.com/stevearc/oil.nvim' }

require('oil').setup {
  default_file_explorer = true,

  keymaps = {
    ['g?'] = 'actions.show_help',
    ['<CR>'] = 'actions.select',
    ['<C-s>'] = 'actions.select_vsplit',
    ['<C-h>'] = 'actions.select_split',
    ['<C-t>'] = 'actions.select_tab',
    ['<C-p>'] = 'actions.preview',
    ['<C-c>'] = 'actions.close',
    ['<C-l>'] = 'actions.refresh',
    ['-'] = 'actions.parent',
    ['_'] = 'actions.open_cwd',
    ['gs'] = 'actions.change_sort',
    ['gx'] = 'actions.open_external',
    ['g.'] = 'actions.toggle_hidden',
    ['g\\'] = 'actions.toggle_trash',
  },
}

-- Open oil in the parent directory of the current file
vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory (Oil)' })

local function yank_oil_path(modifier, label, bufnr)
  local oil = require 'oil'
  local dir = oil.get_current_dir(bufnr) or ''
  local is_visual = vim.api.nvim_get_mode().mode:match '^[vV\22]' ~= nil

  local l1 = is_visual and vim.fn.line 'v' or vim.fn.line '.'
  local l2 = vim.fn.line '.'
  local paths = {}

  for lnum = math.min(l1, l2), math.max(l1, l2) do
    local entry = oil.get_entry_on_line(bufnr, lnum)
    if entry and entry.name then
      local clean = ((dir .. entry.name):gsub('^oil[%w_-]*://', ''))
      table.insert(paths, vim.fn.fnamemodify(vim.fs.normalize(clean), modifier))
    end
  end

  if #paths == 0 and dir ~= '' then
    local clean = (dir:gsub('^oil[%w_-]*://', ''))
    table.insert(paths, vim.fn.fnamemodify(vim.fs.normalize(clean), modifier))
  end

  if #paths == 0 then
    vim.notify('No file path to yank', vim.log.levels.WARN)
    return
  end

  if is_visual then
    vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'nx', false)
  end

  local result = table.concat(paths, '\n')
  vim.fn.setreg('+', result)
  if #paths == 1 then
    vim.notify('Yanked ' .. label .. ' path: ' .. result)
  else
    vim.notify(string.format('Yanked %d %s paths', #paths, label))
  end
end

-- Buffer-local path yanking overrides for Oil
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'oil',
  callback = function(args)
    local opts = function(desc)
      return { buffer = args.buf, desc = desc }
    end
    vim.keymap.set({ 'n', 'x' }, '<leader>yp', function() yank_oil_path(':.', 'relative', args.buf) end, opts 'Oil: [Y]ank relative path(s)')
    vim.keymap.set({ 'n', 'x' }, '<leader>yP', function() yank_oil_path(':~', 'absolute', args.buf) end, opts 'Oil: [Y]ank absolute path(s)')
  end,
})
