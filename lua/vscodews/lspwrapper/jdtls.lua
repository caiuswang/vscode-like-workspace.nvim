local M = {}
local lspconfig = require("lspconfig")
local util = require("vscodews.util")
local lspconfig_util = require("lspconfig.util")

local env = {
  HOME = vim.uv.os_homedir(),
  XDG_CACHE_HOME = os.getenv 'XDG_CACHE_HOME',
  JDTLS_JVM_ARGS = os.getenv 'JDTLS_JVM_ARGS',
}
local function get_cache_dir()
  return env.XDG_CACHE_HOME and env.XDG_CACHE_HOME or lspconfig_util.path.join(env.HOME, '.cache')
end

local function get_jdtls_cache_dir()
  return lspconfig_util.path.join(get_cache_dir(), 'jdtls')
end

---@param workspaceFolders table
---@return string
local function get_jdtls_workspace_dir(workspaceFolders)
  local all_paths = ""
  for _, ws_config in ipairs(workspaceFolders) do
    all_paths = all_paths .. ws_config.path
  end
  -- sha1 cwd
  local cwd_sha1 = vim.fn.systemlist("echo -n "..all_paths.." | sha1sum | awk '{print $1}'")[1]
  return lspconfig_util.path.join(get_jdtls_cache_dir(), 'workspace', cwd_sha1)
end
local function wrap_workspace_folder_path(path)
  if path == nil then
    return nil
  end
  return "file://" .. path
end

M.setup = function (opts)
  local extendedClientCapabilities = {
    ["classFileContentsSupport"] = false,
    ["advancedExtractRefactoringSupport"] = true,
    ["dynamicRegistration"] = true,
  }
  --- @alias Config  vim.lsp.ClientConfig
  local set_map = {
    ["java.completion.filteredTypes"] = "antlr.* com.sun.* groovyjarjarantlr.* org.apache.xmlbeans.* org.hibernate.mapping.* groovyjarjarantlr.collections.* java.awt.*",
    ["java.autobuild.enabled"] = false,
    ["java.format.enabled"] = true,
    ["java.completion.chain.enabled"] = true,
    ["java.sharedIndexes.enabled"] = true,
    ["java.completion.maxResults"] = 10,
    ["java.trace.server"] = "verbose",
  }
  local workspace_folders = {}
  local extra_folders = {}
  for _, ws_config in ipairs(opts.folders) do
    table.insert(extra_folders, wrap_workspace_folder_path(ws_config.path))
    local single_workspace_folder = { uri = wrap_workspace_folder_path(ws_config.path), name = ws_config.name }
    table.insert(workspace_folders, single_workspace_folder)
  end
  local jdtls_data_path = get_jdtls_workspace_dir(opts.folders)
  local init_options = {
    workspace = jdtls_data_path,
    jvm_args = {"-Dlog.level=INFO"},
    settings = set_map,
    workspaceFolders = extra_folders,
    extendedClientCapabilities = extendedClientCapabilities,
    dynamicRegistration = true,
  }
  lspconfig.jdtls.setup({
    on_attach = opts.on_attach,
    capabilities = opts.capabilities,
    cmd = {
      "jdtls",
      "--java-executeable",
      util.process_path_with_env("$HOME/Library/Java/JavaVirtualMachines/temurin-21.0.3/Contents/Home/bin/java"),
      "--configuration",
      util.process_path_with_env("$HOME/.cache/jdtls/config"),
      "-data",
      jdtls_data_path,
      "-vmargs",
      "-Xms4G",
      "-Xmx4G",
      util.process_path_with_env("--jvm-arg=-javaagent:$HOME/.m2/repository/org/projectlombok/lombok/1.18.26/lombok-1.18.26.jar"),
      "--jvm-arg=-Dlog.level=ALL",
      "-DwatchParentProcess=false",
      "-debug",
    },
    init_options = init_options,
    workspace_folders = workspace_folders,
    workspace_folders_dir = extra_folders,
  })
end
return M
