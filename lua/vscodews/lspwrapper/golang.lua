local lspconfig = require('lspconfig')
local M = {}
M.setup = function (ops)
  lspconfig.gopls.setup{}
end

return M
