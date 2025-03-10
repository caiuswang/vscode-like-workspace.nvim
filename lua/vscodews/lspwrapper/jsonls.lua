local capabilities = vim.lsp.protocol.make_client_capabilities()

local M = {}

M.setup = function (opts)
  vim.notify_once("Setting up LSP", vim.log.levels.INFO)
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  require'lspconfig'.jsonls.setup {
    capabilities = capabilities,
  }
end

return M
