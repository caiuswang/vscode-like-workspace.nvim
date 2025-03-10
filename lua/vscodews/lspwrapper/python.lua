local lspconfig = require'lspconfig'
local M = {}

M.setup = function (opts)
  lspconfig.pyright.setup{
    -- pass python path to pyright
    settings = {
      python = {
        pythonPath = "./venv/bin/python3",
      },
    },
  }
end

return M
