local lspconfig = require("lspconfig")


local M = {}
M.setup = function (opts)
  local runtime_path = vim.split(package.path, ';')

  lspconfig.lua_ls.setup{
    on_attach = opts.on_attach,
    capabilities = opts.capabilities,
    settings = {
      Lua = {
        diagnostics = {
          globals = {'vim'},
        },
        semantics = {
          enable = true,
          globals = {
            'vim',
            'describe',
            'it',
            'before_each',
            'after_each',
            'teardown',
            'pending',
            'clear',
            'cl',
            'cd',
            'eq',
            'neq',
            'spy',
            'mock',
            'stub',
            'match',
            'near',
            'same'
          },
        },
        telemetry = {
          enable = true,
        },
        runtime = {
          version = 'LuaJIT',
          path = runtime_path,
          pathStrict = false,
        },
        workspace = {
          library = {
            [vim.fn.expand('$VIMRUNTIME/lua')] = true,
            [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
            [vim.fn.expand('$HOME/.config/nvim/lua')] = true,
            [vim.fn.expand('$HOME/.config/nvim/lua/plugins')] = true,
            [vim.fn.expand('/usr/local/share/lua/5.1')] = true,
            [vim.fn.expand('$HOME/.local/share/nvim/site')]=true,
            [vim.fn.expand('$HOME/.local/share/nvim/lazy')]=true
          },
          checkThirdParty = false,
        },
      },
    },
  }
end

return M

