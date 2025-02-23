local WorkspaceManager = require('vscodews.workspace-manager')
local log = require('vscodews.log')
local project = require('vscodews.project')

local M = {}

log.info("Enter workspace init")
WorkspaceManager:init()

WorkspaceManager:register_pre_load_callback(function(path)
    -- Custom actions to perform before the workspace loads
    log.info('Loading workspace:', path)
end)

WorkspaceManager:register_post_load_callback(function(workspace)
    -- Custom actions to perform after the workspace has loaded
    local opts = {}
    opts.folders = workspace:get_enabled_folders()
    local lsp = require('vscodews.lsp')
    lsp.setup(opts)
    log.info('Registered LSP for workspace:', workspace.file_path)
    project.setup(opts)
    log.info('Initialized workspace:', workspace.file_path)
end)

function M.setup(opts_default)
    print("setup")
end

function M.check()
    vim.print("Checking workspace...")
end

return M

