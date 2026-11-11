local M = {}

function M.guard()
  _G.editor_smoke_errors = {}
  -- Retained parser caches must not shadow packaged grammars.
  local legacy_parsers = vim.fn.stdpath 'data' .. '/site/parser'
  vim.fn.mkdir(legacy_parsers, 'p')
  vim.fn.writefile({ 'obsolete parser must not be loaded' }, legacy_parsers .. '/lua.so')
  local local_config = vim.fn.getcwd() .. '/.nvim.lua'
  local contents = 'vim.g.editor_smoke_project_config = true\n'
  vim.fn.writefile({ contents:sub(1, -2) }, local_config)
  vim.fn.mkdir(vim.fn.stdpath 'state', 'p')
  vim.fn.writefile({ vim.fn.sha256(contents) .. ' ' .. local_config }, vim.fn.stdpath 'state' .. '/trust')
  local function forbidden(name)
    return function()
      local message = 'Installer/build called: ' .. name
      table.insert(editor_smoke_errors, message)
      error(message)
    end
  end
  vim.pack.add = forbidden 'vim.pack.add'
  vim.pack.update = forbidden 'vim.pack.update'
  -- Install APIs are guarded before the user's init.lua can require them.
  package.preload['nvim-treesitter'] = function()
    local paths = vim.fn.globpath(vim.o.packpath, 'pack/*/start/nvim-treesitter/lua/nvim-treesitter/init.lua', false, true)
    local module = assert(loadfile(assert(paths[1], 'Missing packaged treesitter')))()
    module.install = forbidden 'nvim-treesitter.install'
    module.update = forbidden 'nvim-treesitter.update'
    return module
  end
  local notify = vim.notify
  vim.notify = function(message, level, opts)
    if level == vim.log.levels.ERROR then table.insert(editor_smoke_errors, tostring(message)) end
    return notify(message, level, opts)
  end
  local system = vim.system
  vim.system = function(command, ...)
    local executable = vim.fs.basename(command[1])
    if
      vim.tbl_contains({ 'make', 'gcc', 'cc', 'npm', 'tree-sitter' }, executable)
      or (executable == 'git' and vim.tbl_contains({ 'clone', 'fetch', 'pull' }, command[2]))
    then
      return forbidden(table.concat(command, ' '))()
    end
    return system(command, ...)
  end
end

local core_modules = {
  'guess-indent',
  'gitsigns',
  'which-key',
  'tokyonight',
  'mini.ai',
  'mini.icons',
  'mini.pairs',
  'mini.surround',
  'mini.statusline',
  'telescope',
  'plenary',
  'telescope._extensions.fzf',
  'telescope._extensions.ui-select',
  'oil',
  'grug-far',
  'nvim-treesitter',
  'treesitter-context',
  'nvim-treesitter-textobjects',
}
local ide_modules = {
  'todo-comments',
  'lspconfig',
  'jdtls',
  'fidget',
  'conform',
  'luasnip',
  'blink.cmp',
  'dap',
  'dapui',
  'nio',
  'lint',
  'trouble',
  'render-markdown',
}

local function check(condition, message) assert(condition, message) end

local function check_grammars()
  local grammars = vim.json.decode(vim.env.EDITOR_SMOKE_GRAMMARS)
  local packaged = {}
  for _, path in ipairs(vim.api.nvim_get_runtime_file('parser/*', true)) do
    check(vim.uv.fs_realpath(path):match '^/nix/store/', 'Parser outside store: ' .. path)
    packaged[vim.fs.basename(path):gsub('%.so$', '')] = path
  end
  for _, language in ipairs(grammars) do
    check(packaged[language], 'Missing grammar: ' .. language)
    check(vim.treesitter.language.add(language), 'Cannot load grammar: ' .. language)
  end
  for _, language in ipairs { 'lua', 'nix', 'bash', 'json', 'yaml', 'markdown', 'vim' } do
    check(vim.treesitter.query.get(language, 'highlights') ~= nil, 'Missing highlights: ' .. language)
  end
  local textobjects = vim.treesitter.query.get('lua', 'textobjects')
  check(textobjects ~= nil, 'Missing Lua textobjects query')
  check(vim.tbl_contains(textobjects.captures, 'function.outer'), 'Missing function textobject capture')
  local parser = vim.treesitter.get_string_parser('local function sample(value) return value end', 'lua')
  check(#parser:parse() == 1, 'Parser does not parse Lua')
  print(('Loaded %d requested store grammars'):format(#grammars))
  return packaged
end

local function tests()
  local full = vim.env.EDITOR_SMOKE_PROFILE == 'full'
  check(vim.g.editor_profile == vim.env.EDITOR_SMOKE_PROFILE, 'Wrong editor profile')
  check(vim.g.editor_config_root == vim.env.EDITOR_SMOKE_ROOT, 'Wrong config root')
  check(vim.g.editor_nixpkgs == vim.env.EDITOR_SMOKE_NIXPKGS, 'Wrong caller nixpkgs')
  check(vim.fn.stdpath 'config' == vim.env.XDG_CONFIG_HOME .. '/nvim-smoke', 'NVIM_APPNAME escaped isolation')
  check(vim.o.exrc, 'Native project-local config disabled')
  check(vim.g.editor_smoke_project_config == true, 'Native trusted .nvim.lua not sourced')
  check(vim.g.mapleader == ' ', 'Wrong leader')
  check(vim.fn.exepath 'stylua' == vim.env.EDITOR_SMOKE_PROJECT_BIN .. '/stylua', 'Project tools lost PATH precedence')
  check(vim.g.loaded_node_provider == 0 and vim.g.loaded_python3_provider == 0, 'Provider initialization missing')

  for _, name in ipairs(core_modules) do
    check(pcall(require, name), 'Missing core module: ' .. name)
  end
  check(vim.fn.exists ':UndotreeToggle' == 2, 'Undotree runtime not loaded')
  for _, name in ipairs(ide_modules) do
    check(pcall(require, name) == full, 'Wrong IDE module availability: ' .. name)
  end
  for _, lhs in ipairs { '<leader>sf', '<leader>sn', '<leader>yp', '<leader>u', '-' } do
    check(next(vim.fn.maparg(lhs, 'n', false, true)) ~= nil, 'Missing map: ' .. lhs)
  end
  check(vim.fn.maparg('af', 'o') ~= '', 'Missing treesitter textobject map')
  local search = vim.fn.maparg('<leader>sn', 'n', false, true).callback
  local builtin = require 'telescope.builtin'
  local find_files, requested_root = builtin.find_files, nil
  builtin.find_files = function(opts) requested_root = opts.cwd end
  search()
  builtin.find_files = find_files
  check(requested_root == vim.g.editor_config_root, 'Config search does not follow config root')

  local packaged = check_grammars()

  if full then
    for _, name in ipairs { 'nixd', 'basedpyright', 'jsonls', 'yamlls', 'lemminx', 'html', 'cssls', 'lua_ls', 'jdtls' } do
      check(vim.lsp.is_enabled(name), 'LSP not enabled: ' .. name)
      local capabilities = vim.lsp.config[name].capabilities
      check(capabilities.textDocument.completion.completionItem.snippetSupport, 'Missing Blink capabilities: ' .. name)
      check(capabilities.workspace.fileOperations.willRename, 'Missing file-operation capabilities: ' .. name)
    end
    local expr = vim.lsp.config.nixd.settings.nixd.nixpkgs.expr
    check(expr:find(vim.g.editor_nixpkgs, 1, true), 'Nixd ignores pinned caller nixpkgs')
    local java = vim.lsp.config.jdtls
    check(#java.init_options.bundles > 1, 'JDTLS after/lsp bundle settings were not merged')
    check(java.flags.allow_incremental_sync == false, 'JDTLS sync override was not merged')
    check(java.settings.redhat.telemetry.enabled == false, 'JDTLS telemetry override was not merged')
    check(vim.env.JDTLS_JVM_ARGS:match '^-javaagent:/nix/store/.+/share/java/lombok.jar$', 'Missing Lombok agent')
    for _, name in ipairs { 'JDTLS_DEBUG_PLUGIN', 'JDTLS_TEST_PLUGIN' } do
      check(vim.env[name]:match '^/nix/store/', 'Java plugin outside store: ' .. name)
      check(#vim.fn.glob(vim.env[name] .. '/*.jar', false, true) > 0, 'Missing Java bundles: ' .. name)
    end
    local formatter = vim.system({ 'google-java-format', '--version' }, { text = true }):wait()
    check(formatter.code == 0, 'Java formatter failed')
    check(((formatter.stdout or '') .. (formatter.stderr or '')):find('1.28.0', 1, true), 'Java formatter pin changed')
    local conform = require 'conform'
    check(conform.formatters_by_ft.java[1] == 'google-java-format', 'Wrong Java formatter')
    check(conform.formatters_by_ft.java.lsp_format == 'never', 'Java LSP formatting enabled')
    local nix_args = conform.formatters.nixfmt.args
    check(vim.deep_equal(nix_args, { '-' }), 'Nixfmt does not use explicit stdin')
    local nix_format = vim.system({ 'nixfmt', unpack(nix_args) }, { stdin = '{answer=42;}', text = true }):wait()
    check(nix_format.code == 0, 'Nixfmt stdin formatting failed')
    check(nix_format.stderr == '', 'Nixfmt emitted a warning: ' .. nix_format.stderr)
    check(nix_format.stdout:find('answer = 42;', 1, true), 'Nixfmt did not format stdin')
  else
    for _, name in ipairs { 'nixd', 'lua_ls', 'jdtls', 'basedpyright' } do
      check(not vim.lsp.is_enabled(name), 'Minimal enabled IDE server: ' .. name)
    end
    check(vim.fn.maparg('<leader>f', 'n') == '', 'Minimal exposes IDE formatting map')
    check(vim.api.nvim_get_commands({}).W == nil, 'Minimal defines formatting command')
    check(not packaged.java and not packaged.python, 'Minimal includes full grammar set')
  end

  -- Mutating only the sandbox copy proves reload does not use bundled Lua.
  if vim.env.EDITOR_SMOKE_MODE == 'live' then
    local path = vim.env.EDITOR_SMOKE_LIVE_SOURCE .. '/init.lua'
    vim.fn.writefile({ 'vim.g.editor_smoke_reloaded = true' }, path, 'a')
    vim.cmd.source(vim.g.editor_config_root .. '/init.lua')
    check(vim.g.editor_smoke_reloaded == true, 'Reload ignored live source')
  else
    check(vim.g.editor_config_root:match '^/nix/store/', 'Immutable root outside store')
    check(vim.fn.filereadable(vim.g.editor_config_root .. '/flake.nix') == 0, 'Immutable source not filtered')
  end
  check(vim.fn.isdirectory(vim.fn.stdpath 'data' .. '/site/pack') == 0, 'Startup created plugin installer data')
  vim.wait(200, function() return false end)
  check(vim.v.errmsg == '', 'Startup error: ' .. vim.v.errmsg)
  check(#editor_smoke_errors == 0, table.concat(editor_smoke_errors, '\n'))
end

local function finish(test, label)
  local ok, err = xpcall(test, debug.traceback)
  if not ok then
    io.stderr:write(err .. '\n')
    vim.cmd 'cquit 1'
  else
    print('Smoke passed: ' .. label)
    vim.cmd 'qa!'
  end
end

function M.run() finish(tests, vim.env.EDITOR_SMOKE_PROFILE .. '/' .. vim.env.EDITOR_SMOKE_MODE) end

function M.parsers() finish(check_grammars, 'all parsers') end

return M
