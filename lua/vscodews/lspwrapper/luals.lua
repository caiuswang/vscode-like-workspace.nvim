
local M = {}
M.setup = function (opts)
  local runtime_path = vim.split(package.path, ';')
  vim.lsp.enable('lua_ls')
  vim.lsp.config('lua_ls', {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    on_init = function(client)
      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if vim.loop.fs_stat(path..'/.luarc.json') or vim.loop.fs_stat(path..'/.luarc.jsonc') then
          return
        end
      end
    end,
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
          enable = false,
        },
        runtime = {
          version = 'LuaJIT',
          path = runtime_path,
          pathStrict = false,
        },
        workspace = {
          library = {
            vim.fn.expand('$VIMRUNTIME/lua'),
            vim.fn.expand('$VIMRUNTIME/lua/vim/lsp'),
            vim.fn.expand('$HOME/.config/nvim/lua'),
            vim.fn.expand('$HOME/.config/nvim/lua/plugins'),
            vim.fn.expand('/usr/local/share/lua/5.1'),
            -- vim.fn.expand('$HOME/.local/share/nvim/site'),
            -- vim.fn.expand('$HOME/.local/share/nvim/lazy'),
            vim.fn.expand('$HOME/.local/share/nvim/lazy/nvim-lspconfig'),
          },
          checkThirdParty = false,
          maxPreload = 100000,
          preloadFileSize = 10000,
        },
      },
    },
  })
end

return M

