
local M = {}
M.setup = function(opts)
  vim.lsp.enable("yamlls", true)
  vim.lsp.config("yamlls",{})
end
return M
