local M = {}

local on_init = function(client, _)
  if client.supports_method "textDocument/semanticTokens" then
    client.server_capabilities.semanticTokensProvider = nil
  end
end

local on_attach = function(client, bufnr)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr })
  local keymap = vim.keymap.set
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc , noremap = true, silent = true}
  end
  keymap("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts "List workspace folders")
  keymap('n', 'K', vim.lsp.buf.hover, opts "Show hover")
  keymap('n', '<C-k>', vim.lsp.buf.signature_help, opts "Show signature help")
  keymap('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
  keymap('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")
  keymap('n', '<space>wl', vim.lsp.buf.list_workspace_folders, opts "List workspace folders")
  keymap('n', '<space>D', vim.lsp.buf.type_definition, opts "Go to type definition")
  keymap('n', '<space>rn', vim.lsp.buf.rename, opts "Rename")
  keymap('n', '<space>ca', vim.lsp.buf.code_action, opts "Code action")
  keymap('n', 'gr', vim.lsp.buf.references, opts "Show references")
  keymap("n", "gh", "<cmd>Lspsaga finder<CR>")
  keymap("n", "gs", "<cmd>Lspsaga signature_help<CR>")
  keymap("n", "<C-k>", "<cmd>Lspsaga show_line_diagnostics<CR>")
  keymap("n", "<Leader>ci", "<cmd>Lspsaga incoming_calls<CR>")
  keymap("n", "<Leader>co", "<cmd>Lspsaga outgoing_calls<CR>")
  keymap("n", "gp", "<cmd>Lspsaga peek_definition<CR>")
  keymap("n", "gr", "<cmd>Lspsaga rename<CR>")
  keymap("n", "<Leader>gp", "<cmd>Lspsaga preview_definition<CR>")
  -- keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
  keymap("n", "gi", "<cmd>Lspsaga implementation<CR>")
  keymap("n", "<space>ca", "<cmd>Lspsaga code_action<CR>")
  -- diagnostics prev
  keymap("n", "[e", "<cmd>Lspsaga diagnostic_jump_prev<CR>")
  -- diagnostics next
  keymap("n", "]e", "<cmd>Lspsaga diagnostic_jump_next<CR>")
  if client and vim.lsp.buf.completion and client.server_capabilities and client.server_capabilities.completionProvider then
    keymap("i", "<C-k>", vim.lsp.buf.completion, opts "Show completion")
    --   --previous completion item
      keymap("i", "<C-p>", vim.lsp.buf.completion_prev, opts "Previous completion item")
      --next completion item
      keymap("i", "<C-n>", vim.lsp.buf.completion_next, opts "Next completion item")
  end

end



M.default_config = {
  enable_type  = {
    "lua",
    "go",
    "rust",
    "c",
    "py",
    "json",
    "java"
  },
  diable_type = {
    'tailwindcss',
  },
  diable_func = {
    'find_text',
  },
  type_func = {
    lua = require('vscodews.lspwrapper.luals').setup,
    tailwindcss = require('vscodews.lspwrapper.tailwindcss').setup,
    rust = require('vscodews.lspwrapper.rust').setup,
    go = require('vscodews.lspwrapper.golang').setup,
    c = require('vscodews.lspwrapper.c').setup,
    java = require('vscodews.lspwrapper.jdtls').setup,
    py = require('vscodews.lspwrapper.python').setup,
    json = require('vscodews.lspwrapper.jsonls').setup,
  },
}
---@param c table
M.setup = function(c)
  vim.lsp.set_log_level("info")
  local config = vim.tbl_extend("force", M.default_config, c)
  config.on_attach = on_attach
  -- local capabilities = require('blink.cmp').get_lsp_capabilities()
  -- config.capabilities = capabilities
  local enable_type = config.enable_type or M.default_config.enable_type
  local diable_type = config.diable_type or M.default_config.diable_type
  --local diable_func = config.diable_func or M.default_config.diable_func
  local type_func = config.type_func or M.default_config.type_func
  -- prepare
  for _, v in ipairs(enable_type) do
    -- check if exist in diable_type
    if not vim.tbl_contains(diable_type, v) then
      if type_func[v] then
        vim.api.nvim_create_autocmd('LspAttach', { callback = on_attach, pattern = "*" .. "." .. v })
        type_func[v](config)
      end
    end
  end
end

return M
