local M = {}

function M.process_path_with_env(path)
  local env = vim.fn.environ()
  for k, v in pairs(env) do
    path = string.gsub(path, '$' .. k, v)
  end
  return path
end

function M.path_join(...)
  return table.concat({...}, '/')
end

function M.get_java_version()
  local java_version = vim.fn.systemlist(M.get_java_executable() .. " -version")
  return java_version[1]
end

function M.get_java_home()
  -- return M.process_path_with_env("$HOME/Library/Java/JavaVirtualMachines/temurin-21.0.3/Contents/Home")
    -- return M.process_path_with_env("$HOME//Library/Java/JavaVirtualMachines/corretto-19.0.2/Contents/Home")
    return M.process_path_with_env("/opt/homebrew/Cellar/openjdk/23.0.2")


end

function M.get_java_executable()
  return M.path_join(M.get_java_home(), "bin", "java")
end

function M.get_jdtls_executable()
  -- return M.process_path_with_env("$HOME/Downloads/jdt-language-server-1.45.0-202502271238/bin/jdtls")
  return M.process_path_with_env("$HOME/Downloads/jdt-language-server-1.46.0-202503271314/bin/jdtls")
end

return M

