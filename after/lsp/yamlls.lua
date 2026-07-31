-- Extra yamlls config, merged on top of nvim-lspconfig's lsp/yamlls.lua
--
-- NOTE: unlike bb223 config, SchemaStore is left enabled

---@type vim.lsp.Config
return {
  ---@type lspconfig.settings.yamlls
  settings = {
    yaml = {
      schemas = {
        -- Authoritative source; SchemaStore's copy tends to lag GitLab releases.
        ['https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json'] = {
          '.gitlab-ci.yml',
          '.gitlab-ci.yaml',
        },
        ['https://json.schemastore.org/github-workflow.json'] = '/.github/workflows/*',
      },
    },
  },
}
