local Path = require('plenary.path')
local M = {}

vim.env.VIM_DATA_PATH = vim.fn.stdpath("data")
vim.env.VIM_CONFIG_PATH = vim.fn.stdpath("config")

local predfiend_env = {
  VIM_DATA_PATH = vim.env.VIM_DATA_PATH,
  VIM_CONFIG_PATH = vim.env.VIM_CONFIG_PATH,
}

---@param folders WorkspaceFolder[]
---@return table
function M.process_workspace_folders(folders)
  local final_workspace_folders = {}
  for _,folder_config in pairs(folders) do
    local p = M.process_path_with_env(folder_config.path)
    local path = Path:new(p)
    local folder_path = path:absolute()
    if not path:exists() then
      vim.notify("Workspace folder " .. folder_config.name .. " does not exist: " .. folder_path, vim.log.levels.WARN, {
        title = "vscodews"
      })
      goto continue
    end
    if folder_config.modules ~= nil then
      for _, module in pairs(folder_config.modules) do
        local module_path = Path:new(folder_path, module)
        if not module_path:exists() then
          vim.notify("Module " .. module .. " in workspace folder " .. folder_config.name .. " does not exist.", vim.log.levels.WARN, {
            title = "vscodews"
          })
        else
            local parent_folder_name = folder_config.name or path:make_relative()
            local current_module_name = parent_folder_name .. "-> " .. module
            local workspace_folder = {
              name = current_module_name,
              path = module_path:absolute(),
              enabled = folder_config.enabled
            }
            M.append_if_not_exist(final_workspace_folders, workspace_folder)
        end
      end
    else
      local workspace_folder = {
        name = folder_config.name or path:make_relative(),
        path = folder_path
      }
      M.append_if_not_exist(final_workspace_folders, workspace_folder)
    end
    ::continue::
  end
  return final_workspace_folders
end


function M.append_if_not_exist(final_workspace_folders, workspace_folder)
  if M.check_if_table_exists_path(final_workspace_folders, workspace_folder.path) then
    vim.notify("Workspace folder " .. workspace_folder.name .. "'s path already exists, skipping.", vim.log.levels.WARN, {
      title = "vscodews"
    })
  else
    table.insert(final_workspace_folders, workspace_folder)
  end
  return final_workspace_folders
end


function M.check_if_table_exists_path(t, path)
  for _, v in pairs(t) do
    if v.path == path then
      return true
    end
  end
  return false
end

function M.process_path_with_env(path)
  local env = vim.fn.environ()
  for k, v in pairs(predfiend_env) do
    path = string.gsub(path, '$' .. k, v)
  end
  for k, v in pairs(env) do
    path = string.gsub(path, '$' .. k, v)
  end
  -- if still exists $ then return to nil
  if string.find(path, '%$') then
    vim.notify("Path contains undefined environment variables: " .. path, vim.log.levels.DEBUG, {
      title = "vscodews"
    })
    return nil
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
    return M.process_path_with_env("$LSP_JAVA_HOME") or M.process_path_with_env("$JAVA_HOME")
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
  if M.get_java_home() == nil then
    vim.notify("LSP_JAVA_HOME or JAVA_HOME is not set, please set one of it .", vim.log.levels.ERROR, {
      title = "vscodews"
    })
    return "java"
  end
  return M.path_join(M.get_java_home(), "bin", "java")
end

function M.get_jdtls_executable()
  return M.process_path_with_env(string.format("$HOME/Downloads/%s/bin/jdtls", M.get_jdt_server_dir_name()))
end

function M.download_jdtls_if_not_exist()
  -- let user choose if they want to download the latest version of jdtls
  local jdtls_executable = M.get_jdtls_executable()
  if jdtls_executable ~= nil and vim.fn.filereadable(jdtls_executable) == 1 then
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

