local WorkspaceManager = require('vscodews.workspace-manager')

---@param ws Workspace
local start_func = function(ws)
  local opts = {}
  opts.folders = ws:get_enabled_folders()
  -- opts.config_root = ws.config_root
  -- require('vscodews.lspwrapper.nvim-jdtls').setup(opts)
  require('vscodews.lspwrapper.jdtls').setup(opts)
  -- require('spring_boot_dash').setup(opts)
end
WorkspaceManager:register_post_load_callback(start_func)
