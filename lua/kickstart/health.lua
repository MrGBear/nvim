local check_version = function()
  local verstr = tostring(vim.version())
  if vim.fn.has 'nvim-0.12' == 1 then
    vim.health.ok(string.format("Neovim version is: '%s'", verstr))
  else
    vim.health.error(string.format("Neovim >= 0.12 required; found '%s'", verstr))
  end
end

local check_executables = function(executables)
  for _, exe in ipairs(executables) do
    if vim.fn.executable(exe) == 1 then
      vim.health.ok(string.format("Found executable: '%s'", exe))
    else
      vim.health.error(string.format("Could not find executable: '%s'; rebuild the Nix wrapper", exe))
    end
  end
end

return {
  check = function()
    vim.health.start 'Nix-managed Neovim'
    check_version()
    local profile = vim.g.editor_profile
    if profile ~= 'full' and profile ~= 'minimal' then
      vim.health.error 'Start Neovim with the Nix wrapper to select a profile'
      return
    end
    vim.health.info('Profile: ' .. profile)
    local config_root = vim.g.editor_config_root
    if config_root and vim.fn.isdirectory(config_root) == 1 then
      vim.health.ok('Configuration: ' .. config_root)
    else
      vim.health.error 'The wrapper configuration root is missing'
    end
    check_executables { 'fish', 'git', 'rg', 'fd', 'trash-put', 'ouch', 'diff' }
    if profile == 'full' then
      check_executables {
        'nixd',
        'basedpyright-langserver',
        'vscode-json-language-server',
        'yaml-language-server',
        'lemminx',
        'vscode-html-language-server',
        'vscode-css-language-server',
        'lua-language-server',
        'jdtls',
        'stylua',
        'nixfmt',
        'shfmt',
        'google-java-format',
        'markdownlint',
        'statix',
        'deadnix',
        'shellcheck',
      }
    else
      vim.health.info 'LSP, completion, formatting, debugging and linting are disabled in minimal'
    end
  end,
}
