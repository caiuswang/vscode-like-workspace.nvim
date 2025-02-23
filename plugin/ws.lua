local WorkspaceManager = require('vscodews.workspace-manager')
local log = require('vscodews.log')

WorkspaceManager:init()

WorkspaceManager:register_pre_load_callback(function(path)
    -- Custom actions to perform before the workspace loads
    log.info('Loading workspace:', path)
end)

