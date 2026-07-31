-- Extra jdtls config. `after/` is the last runtimepath entry, so this is merged
-- on top of the `lsp/jdtls.lua` shipped by both nvim-lspconfig and nvim-jdtls
--
---@type vim.lsp.Config
return {
  -- NOTE: jdtls has a history of desyncing on incremental document sync, but full
  -- sync costs a little throughput on large files
  flags = { allow_incremental_sync = false },

  settings = {
    -- Only rendered when inlay hints are toggled on (<leader>th).
    java = { inlayHints = { parameterNames = { enabled = 'all' } } },
    redhat = { telemetry = { enabled = false } },
  },
}
