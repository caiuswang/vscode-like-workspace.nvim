local lspconfig = require'lspconfig'
local M = {}
M.setup = function (opts)
  lspconfig.clangd.setup{
    cmd = {
      "clangd",
      "--offset-encoding=utf-16",
    }
  }
end

return M
