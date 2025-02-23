local M = {}
local lspconfig = require("lspconfig")
local util = require("vscodews.util")
local extendedClientCapabilities = {
	["classFileContentsSupport"] = true,
	["advancedExtractRefactoringSupport"] = true,
	["dynamicRegistration"] = true,
}
--- @alias Config  vim.lsp.ClientConfig
local set_map = {
	["java.completion.filteredTypes"] = "antlr.* com.sun.* groovyjarjarantlr.* org.apache.xmlbeans.* org.hibernate.mapping.* groovyjarjarantlr.collections.* java.awt.*",
	["java.autobuild.enabled"] = true,
	["java.format.enabled"] = true,
	["java.completion.chain.enabled"] = true,
	["java.sharedIndexes.enabled"] = true,
	["java.completion.maxResults"] = 10,
	["java.trace.server"] = "verbose",
}
local function wrap_workspace_folder_path(path)
	if path == nil then
		return nil
	end
	return "file://" .. path
end
local extra_folders = {}

local init_options = {
	["settings"] = set_map,
	["workspaceFolders"] = extra_folders,
	["extendedClientCapabilities"] = extendedClientCapabilities,
	["dynamicRegistration"] = true,
}

---@param opts table
function M.setup(opts)
	-- vim.notify_once("Setting up LSP", vim.log.levels.INFO)
	local extra_folders_map = {}
	local workspace_folders = {}
	for _, ws_config in ipairs(opts.folders) do
		table.insert(extra_folders, wrap_workspace_folder_path(ws_config.path))
		extra_folders_map[ws_config.name] = wrap_workspace_folder_path(ws_config.path)
		local single_workspace_folder = { uri = wrap_workspace_folder_path(ws_config.path), name = ws_config.name }
		table.insert(workspace_folders, single_workspace_folder)
	end
	lspconfig.jdtls.setup({
		cmd = {
			"jdtls",
			"--java-executeable",
			util.process_path_with_env("$HOME/Library/Java/JavaVirtualMachines/temurin-21.0.3/Contents/Home/bin/java"),
			"--configuration",
			util.process_path_with_env("$HOME/.cache/jdtls/config"),
			-- "-data",
			-- util.process_path_with_env("$HOME/.cache/jdtls/workspace/data-1"),
			"-vmargs",
			"-Xmx4G",
			util.process_path_with_env("--jvm-arg=-javaagent:$HOME/.m2/repository/org/projectlombok/lombok/1.18.26/lombok-1.18.26.jar"),
			"--jvm-arg=-Dlog.level=ALL",
			"-debug",
		},
		init_options = init_options,
		workspace_folders = workspace_folders,
		workspace_folders_dir = extra_folders,
		workspace_folders_dir_map = extra_folders_map,
	})
end

return M
