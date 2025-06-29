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
    -- return M.process_path_with_env("/opt/homebrew/Cellar/openjdk/23.0.2")
    return M.process_path_with_env("$LSP_JAVA_HOME")
end

function M.get_jdt_server_version()
  return vim.env.JDT_SERVER_VERSION  or "1.46.0-202503271314"
end


function M.get_jdt_server_dir_name()
  return "jdt-language-server-" .. M.get_jdt_server_version()
end

function M.get_jtd_server_major_version()
  -- split wit - 
  local major_version = string.match(M.get_jdt_server_version(), "^[0-9.]+")
  return major_version
end

function M.get_java_executable()
  return M.path_join(M.get_java_home(), "bin", "java")
end

function M.get_jdtls_executable()
  return M.process_path_with_env(string.format("$HOME/Downloads/%s/bin/jdtls", M.get_jdt_server_dir_name()))
end

function M.download_jdtls_if_not_exist()
  -- let user choose if they want to download the latest version of jdtlsj
  if vim.fn.filereadable(M.get_jdtls_executable()) == 1 then
    return
  end
  local choice = vim.fn.input("Do you want to download the latest version of jdtls? (y/n): ")
  if choice:lower() ~= 'y' then
    print("Skipping download of jdtls.")
    return
  end
  local jdt_languer_server_dir_name = M.get_jdt_server_dir_name()
  local download_url = string.format("https://www.eclipse.org/downloads/download.php?file=/jdtls/milestones/%s/%s.tar.gz", M.get_jtd_server_major_version(), jdt_languer_server_dir_name)
  print("jdtls download url is:" .. download_url)
  local tmp_dir = vim.fn.tempname()
  vim.fn.mkdir(tmp_dir, "p")
  local tar_file = M.path_join(tmp_dir, "jdtls.tar.gz")

  -- Download the file
  vim.fn.system({"curl", "-L", download_url, "-o", tar_file, "--proxy", "http://localhost:7890"})

  -- Extract the tar file
  local final_path_dir = M.path_join(vim.fn.expand("$HOME"), "Downloads", jdt_languer_server_dir_name)
  print("final jdt path:" .. final_path_dir)
  vim.fn.system({"tar", "-xzf", tar_file, "-C", final_path_dir})
  print(tmp_dir)
  -- Clean up
  vim.fn.delete(tar_file)
  -- vim.fn.system({"rm", "-rf", tmp_dir})
end

return M

