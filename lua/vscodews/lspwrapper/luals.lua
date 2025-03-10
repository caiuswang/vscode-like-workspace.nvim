local lspconfig = require("lspconfig")

local M = {}
M.setup = function (opts)
  lspconfig.lua_ls.setup{
    settings = {
      Lua = {
        diagnostics = {
          globals = {'vim'},
        },
        runtime = {
          version = 'LuaJIT',
          path = vim.split(package.path, ';'),
        },
        workspace = {
          library = {
            [vim.fn.expand('$VIMRUNTIME/lua')] = true,
            [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
            [vim.fn.expand('$HOME/.config/nvim/lua')] = true,
            [vim.fn.expand('$HOME/.config/nvim/lua/plugins')] = true,
            [vim.fn.expand('/usr/local/share/lua/5.1')] = true,
            [vim.fn.expand('$HOME/.local/share/nvim/site')]=true,
            [vim.fn.expand('$HOME/.local/share/nvim/lazy')]=true,
          },
          checkThirdParty = false,
        },
      },
    },
  }
end

return M

