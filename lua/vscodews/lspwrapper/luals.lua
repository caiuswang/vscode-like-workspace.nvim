
local M = {}
M.gloabl_workspace_libraray = {
  vim.fn.expand('$VIMRUNTIME/lua'),
  vim.fn.expand('$VIMRUNTIME/lua/vim/lsp'),
}

M.setup = function (opts)
  local runtime_path = vim.split(package.path, ';')
  vim.lsp.enable('lua_ls')
  local workspace_library = {}
  for _, path in ipairs(M.gloabl_workspace_libraray) do
    table.insert(workspace_library, path)
  end
  for _, folder in ipairs(opts.folders) do
   table.insert(workspace_library, folder.path)
  end
  vim.lsp.config('lua_ls', {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
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
          library = workspace_library,
          checkThirdParty = false,
          maxPreload = 100000,
          preloadFileSize = 10000,
        },
      },
    },
  })
end

return M

