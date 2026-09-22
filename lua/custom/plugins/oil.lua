vim.pack.add { 'https://github.com/stevearc/oil.nvim' }

-- Toggle detail view (gd)
local show_details = false
local function toggle_detail_view()
  show_details = not show_details
  if show_details then
    require('oil').set_columns {
      'icon',
      'permissions',
      'size',
      { 'mtime', format = '%Y-%m-%d %H:%M' },
    }
  else
    require('oil').set_columns { 'icon' }
  end
end

-- Show file properties floating popup (gp)
local function show_file_properties()
  local oil = require 'oil'
  local entry = oil.get_cursor_entry()
  local dir = oil.get_current_dir()
  if not entry or not dir then return end

  local full_path = vim.fs.normalize(((dir .. entry.name):gsub('^oil[%w_-]*://', '')))
  local lstat = vim.uv.fs_lstat(full_path)
  if not lstat then
    vim.notify('Could not stat: ' .. full_path, vim.log.levels.WARN)
    return
  end

  local is_link = lstat.type == 'link'
  local stat = is_link and vim.uv.fs_stat(full_path) or lstat

  local function format_size(bytes)
    local units = { 'B', 'KiB', 'MiB', 'GiB' }
    local i = 1
    while bytes >= 1024 and i < #units do
      bytes = bytes / 1024
      i = i + 1
    end
    return string.format('%.1f %s', bytes, units[i])
  end

  local function mode_to_rwx(m)
    local rwx = { 'r', 'w', 'x' }
    local s = {}
    for i = 8, 0, -1 do
      local b = bit.band(bit.rshift(m, i), 1)
      table.insert(s, b == 1 and rwx[(8 - i) % 3 + 1] or '-')
    end
    return table.concat(s)
  end

  local lines = {
    ' Name:     ' .. entry.name,
    ' Path:     ' .. full_path,
    ' Type:     ' .. (is_link and 'symlink' or (stat and stat.type or 'unknown')),
  }

  if is_link then
    local target = vim.uv.fs_readlink(full_path)
    table.insert(lines, ' Target:   ' .. (target or 'unknown'))
  end

  if stat then
    if stat.type == 'directory' then
      local count = 0
      local ok, dir_iter = pcall(vim.fs.dir, full_path)
      if ok and dir_iter then
        for _ in dir_iter do
          count = count + 1
        end
      end
      table.insert(lines, ' Items:    ' .. count .. ' items')
    else
      table.insert(lines, ' Size:     ' .. format_size(stat.size) .. string.format(' (%d bytes)', stat.size))
    end
    table.insert(lines, ' Mode:     ' .. string.format('0%o (%s)', stat.mode % 512, mode_to_rwx(stat.mode)))
    table.insert(lines, ' Created:  ' .. (stat.birthtime and os.date('%Y-%m-%d %H:%M:%S', stat.birthtime.sec) or 'N/A'))
    table.insert(lines, ' Modified: ' .. os.date('%Y-%m-%d %H:%M:%S', stat.mtime.sec))
    table.insert(lines, ' Accessed: ' .. os.date('%Y-%m-%d %H:%M:%S', stat.atime.sec))
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'

  -- Apply syntax highlights to field labels
  local ns = vim.api.nvim_create_namespace 'oil_properties'
  local max_w = 0
  for i, line in ipairs(lines) do
    max_w = math.max(max_w, #line)
    local colon = line:find ':'
    if colon then vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 1, {
      end_col = colon,
      hl_group = 'Keyword',
    }) end
  end

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = max_w + 3,
    height = #lines,
    style = 'minimal',
    border = 'rounded',
    title = ' File Properties ',
    title_pos = 'center',
    footer = ' [q/Esc] close ',
    footer_pos = 'right',
  })

  for _, key in ipairs { 'q', '<Esc>', '<CR>' } do
    vim.keymap.set('n', key, function()
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    end, { buffer = buf, nowait = true })
  end
end

-- Buffer-local path yanking for Oil
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

  if is_visual then vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'nx', false) end

  local result = table.concat(paths, '\n')
  vim.fn.setreg('+', result)
  if #paths == 1 then
    vim.notify('Yanked ' .. label .. ' path: ' .. result)
  else
    vim.notify(string.format('Yanked %d %s paths', #paths, label))
  end
end

require('oil').setup {
  default_file_explorer = true,
  columns = { 'icon' },

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
    ['gd'] = { desc = 'Toggle detail view (ls -l)', callback = toggle_detail_view },
    ['gp'] = { desc = 'Show file properties popup', callback = show_file_properties },
  },
}

-- Open oil in the parent directory of the current file
vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory (Oil)' })

-- Buffer-local path yanking overrides for Oil
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'oil',
  callback = function(args)
    local opts = function(desc) return { buffer = args.buf, desc = desc } end
    vim.keymap.set({ 'n', 'x' }, '<leader>yp', function() yank_oil_path(':.', 'relative', args.buf) end, opts 'Oil: [Y]ank relative path(s)')
    vim.keymap.set({ 'n', 'x' }, '<leader>yP', function() yank_oil_path(':~', 'absolute', args.buf) end, opts 'Oil: [Y]ank absolute path(s)')
  end,
})
