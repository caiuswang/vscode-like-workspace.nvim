local M = {}
local util = require("vscodews.util")

local env = {
  HOME = vim.uv.os_homedir(),
  XDG_CACHE_HOME = os.getenv 'XDG_CACHE_HOME',
  JDTLS_JVM_ARGS = os.getenv 'JDTLS_JVM_ARGS',
  JAVA_HOME = os.getenv 'JAVA_HOME',
}

local function get_cache_dir()
  return env.XDG_CACHE_HOME and env.XDG_CACHE_HOME or util.path_join(env.HOME, '.cache')
end

local function get_jdtls_cache_dir()
  return table.concat({get_cache_dir(), 'jdtls'}, '/')
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
  return util.path_join(get_jdtls_cache_dir(), 'workspace', cwd_sha1)
end
local function wrap_workspace_folder_path(path)
  if path == nil then
    return nil
  end
  return "file://" .. path
end
local disable_completeTypes = {
  "antlr.*",
  "com.sun.*",
  "groovyjarjarantlr.*",
  "org.apache.xmlbeans.*",
  "org.hibernate.mapping.*",
  "groovyjarjarantlr.collections.*",
  "java.awt.*",
  "org.apache.commons.collections.*",
}

local import_orders = {
  "java",
  "javax",
  "com.lucky.lotttery.lotto",
  "com.lucky.lotttery",
  "org.apache.commons",
  "org",
  "com"
}

M.setup = function (opts)
  util.download_jdtls_if_not_exist()
  local set_map = {
    ["java.completion.filteredTypes"] = table.concat(disable_completeTypes, ' '),
    ["java.completion.importOrder"] = table.concat(import_orders, ","),
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
  local bundles =  {
    -- util.process_path_with_env("$HOME/.vscode-insiders/extensions/vmware.vscode-spring-boot-1.61.1/jars/io.projectreactor.reactor-core.jar"),
    -- util.process_path_with_env("$HOME/.vscode-insiders/extensions/vmware.vscode-spring-boot-1.61.1/jars/org.reactivestreams.reactive-streams.jar"),
    -- util.process_path_with_env("$HOME/.vscode-insiders/extensions/vmware.vscode-spring-boot-1.61.1/jars/jdt-ls-commons.jar"),
    -- util.process_path_with_env("$HOME/.vscode-insiders/extensions/vmware.vscode-spring-boot-1.61.1/jars/sts-gradle-tooling.jar"),
    util.process_path_with_env("$HOME/.vscode-insiders/extensions/vscjava.vscode-java-debug-0.58.2025042405/server/com.microsoft.java.debug.plugin-0.53.1.jar")
    -- util.process_path_with_env("$HOME/.vscode/extensions/vmware.vscode-spring-boot-1.61.1/jars/io.projectreactor.reactor-core.jar"),
    -- util.process_path_with_env("$HOME/.vscode/extensions/vmware.vscode-spring-boot-1.61.1/jars/org.reactivestreams.reactive-streams.jar"),
    -- util.process_path_with_env("$HOME/.vscode/extensions/vmware.vscode-spring-boot-1.61.1/jars/jdt-ls-commons.jar"),
    -- util.process_path_with_env("$HOME/.vscode/extensions/vmware.vscode-spring-boot-1.61.1/jars/sts-gradle-tooling.jar"),
    -- vim.fn.glob(util.process_path_with_env("$HOME/.vscode-insiders/extensions/vmware.vscode-spring-boot-1.61.1/jars/*.jar")),
  }
  local init_options = {
    -- workspace = jdtls_data_path,
    jvm_args = {"-Dlog.level=DEBUG"},
    settings = set_map,
    -- workspaceFolders = extra_folders,
    -- extendedClientCapabilities = extendedClientCapabilities,
    dynamicRegistration = true,
    bundles = bundles
  }
  local cmd = {
    opts.bin_path or util.get_jdtls_executable(),
    "--java-executable",
    util.get_java_executable(),
    "--configuration",
    util.process_path_with_env("$HOME/.cache/jdtls/config"),
    "-data",
    jdtls_data_path,
    "-vmargs",
    "-Xms4G",
    "-Xmx8G",
    util.process_path_with_env("--jvm-arg=-javaagent:$HOME/.m2/repository/org/projectlombok/lombok/1.18.26/lombok-1.18.26.jar"),
    "--jvm-arg=-Dlog.level=DEBUG",
    -- "--jvm-arg=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5007",
    "-DwatchParentProcess=false",
    "-debug",
  }
  vim.print(table.concat(cmd, ' '))
  require('jdtls').start_or_attach({
    cmd = cmd,
    on_attach =
    function(client, bufnr)
      if (opts.on_attach) then
        opts.on_attach(client, bufnr)
      end
      require("jdtls").setup_dap()
    end,
    init_options = init_options,
    bundles = bundles,
    workspace_folders = workspace_folders,
  })
end

return M
