vim.pack.add {
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/nvim-neotest/nvim-nio', -- required by nvim-dap-ui
}

local dap = require 'dap'
local dapui = require 'dapui'
-- TODO: Persistent Breakpoints? https://github.com/Weissle/persistent-breakpoints.nvim
-- NOTE: nvim-dap-virtual-text for IntelliJ-style inline values

-- Basic debugging keymaps
vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<leader>B', function() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, { desc = 'Debug: Set Breakpoint' })
vim.keymap.set(
  'n',
  '<leader>da',
  function()
    dap.run {
      type = 'java',
      request = 'attach',
      name = 'Attach to Quarkus :5005',
      hostName = '127.0.0.1',
      port = 5005,
    }
  end,
  { desc = 'Debug: Attach to Quarkus' }
)
vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: Toggle UI' })

-- Partial config: dapui merges this over its defaults (config/init.lua tbl_deep_extend).
---@diagnostic disable: missing-fields
dapui.setup {
  icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
  -- Scopes only, variables are the main thing. Frames/breakpoints/watches have no pane here
  layouts = {
    { elements = { 'scopes' }, size = 45, position = 'left' },
    { elements = { 'repl' }, size = 10, position = 'bottom' },
  },
  controls = { enabled = false }, -- keymaps only, no winbar toolbar
}
---@diagnostic enable: missing-fields

-- Float popups for the panes we removed (nvim-dap/ui, no extra plugin).
local widgets = require 'dap.ui.widgets'
vim.keymap.set('n', '<leader>dh', widgets.hover, { desc = 'Debug: Hover value' })
vim.keymap.set('n', '<leader>ds', function() widgets.centered_float(widgets.scopes) end, { desc = 'Debug: Scopes' })
vim.keymap.set('n', '<leader>df', function() widgets.centered_float(widgets.frames) end, { desc = 'Debug: Frames' })
vim.keymap.set('n', '<leader>dt', function() widgets.centered_float(widgets.threads) end, { desc = 'Debug: Threads' })
vim.keymap.set('n', '<leader>de', function() widgets.centered_float(widgets.expression) end, { desc = 'Debug: Evaluate' })
vim.keymap.set('n', '<leader>dw', function() dapui.float_element 'watches' end, { desc = 'Debug: Watches' })

-- Auto-open/close dapui with sessions
dap.listeners.after.event_initialized['dapui_config'] = dapui.open
dap.listeners.before.event_terminated['dapui_config'] = dapui.close
dap.listeners.before.event_exited['dapui_config'] = dapui.close
