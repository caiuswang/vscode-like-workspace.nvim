local lspconfig = require('lspconfig')

local M = {}
M.setup = function (opts)
  lspconfig.rust_analyzer.setup{}
end

return M

