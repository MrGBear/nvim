-- Extra jdtls config. `after/` is the last runtimepath entry, so this is merged
-- on top of the `lsp/jdtls.lua` shipped by both nvim-lspconfig and nvim-jdtls
--
local bundles = {}
local debug_plugin_path = vim.fn.getenv('JDTLS_DEBUG_PLUGIN')
if debug_plugin_path ~= vim.NIL and debug_plugin_path ~= '' then
  local debug_bundle = vim.split(vim.fn.glob(debug_plugin_path .. '/com.microsoft.java.debug.plugin-*.jar'), '\n')
  vim.list_extend(bundles, debug_bundle)
end

local test_plugin_path = vim.fn.getenv('JDTLS_TEST_PLUGIN')
if test_plugin_path ~= vim.NIL and test_plugin_path ~= '' then
  local test_bundles = vim.split(vim.fn.glob(test_plugin_path .. '/*.jar', true), '\n')
  vim.list_extend(bundles, test_bundles)
end

---@type vim.lsp.Config
return {
  -- NOTE: jdtls has a history of desyncing on incremental document sync, but full
  -- sync costs a little throughput on large files
  flags = { allow_incremental_sync = false },
  
  init_options = {
    bundles = bundles,
  },

  settings = {
    -- Only rendered when inlay hints are toggled on (<leader>th).
    java = { inlayHints = { parameterNames = { enabled = 'all' } } },
    redhat = { telemetry = { enabled = false } },
  },
}
