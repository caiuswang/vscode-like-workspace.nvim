local capabilities = vim.lsp.protocol.make_client_capabilities()

local M = {}

M.setup = function (opts)
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  require'lspconfig'.jsonls.setup {
    capabilities = capabilities,
  }
end

return M
