local f = require("vscodews.file")
require("vscodews.types")

--- @class Project
--- @field workspace_fodlers WorkspaceFolder[]
local M = {}


local function startsWith(str, prefix)
  return string.sub(str, 1, #prefix) == prefix
end
local function has_more_than_one_file(folder_path)
  -- list all children of the folder
  local children = vim.fn.readdir(folder_path)
  if children == nil then
    return false
  end
  if #children == 1 then
    return false
  end
  return true

end
-- Function to get the relative path
local function get_relative_path(file_path, base_ecaped_folder_path)
  -- Check if the file path starts with the escaped folder path
  if startsWith(file_path, base_ecaped_folder_path) then
    -- Get the relative path
    return file_path:sub(#base_ecaped_folder_path + 1)
  end
  return file_path
end


function M.get_common_workspace_relative_path(file_path)
  -- sort with the longest path first
  for _, folder in pairs(M.workspace_fodlers) do
    -- join the folder path with the file path
    local relative_path = get_relative_path(file_path, folder.path)
    if relative_path ~= file_path then
      local show_path = relative_path
      if folder.base_modules ~= nil then
        for _, module_dir in pairs(folder.base_modules) do
          vim.notify("module_dir: " .. module_dir)
          if startsWith(relative_path, module_dir) then
            show_path = relative_path:sub(#module_dir + 1)
            break
          end
        end
      end
      return {
        base_name = folder.name,
        show_path = show_path,
      }
    end
  end
  return {
    base_name = nil,
    show_path = file_path,
  }
end

function M.beautify_path(file_path)
  local tail = require("telescope.utils").path_tail(file_path)
  local show_config = M.get_common_workspace_relative_path(file_path)
  if show_config.base_name then
    return string.format("[🔥%s]:%s (%s)", show_config.base_name, tail, show_config.show_path)
  end
  return string.format("%s (%s)", tail, show_config.show_path)
end
local java_custom_path_func = function(path)
  local tail = require("telescope.utils").path_tail(path)
  local show_path = path
  local lotto_project = ""
  local workspace_folders = M.workspace_fodlers
  -- check if file is a java file
  for _, folder in pairs(workspace_folders) do
    if string.match(path, '^'..folder.path) then
      lotto_project = folder.name
      break
    end
  end
  local base_projet_prefix_pattern = ".*src/main/java/com/lucky/lottery"
  if string.match(path, base_projet_prefix_pattern .. ".*") then
    -- find the index of "/tkl-project", sub all the string before it
    -- show_path = string.gsub(path, ".*%tkl%-project/tkl%-api/", "")
    -- show_path = string.gsub(show_path, ".*%tkl%-project/", "")
    show_path = string.gsub(path,  base_projet_prefix_pattern .. "/tkl%-api/", "")
    show_path = string.gsub(show_path, base_projet_prefix_pattern .. "/", "")
    -- get the first word of the show_path is the project name
    local index = string.find(show_path, "/")
    if index ~= nil then
      lotto_project = string.sub(show_path, 1, index - 1)
      -- conceal file if lotto_project is "tkl-platform-engine"
      if lotto_project == "tkl-platform-engine" then
        return nil
      end
    end
    show_path = string.gsub(show_path, ".*src/main/java/com/lucky/lottery/lotto", "lt:")
    show_path = string.gsub(show_path, ".*src/main/java/com/lucky/lottery", "")
    return string.format("[🔥[%s]]:%s (%s)", lotto_project, tail, show_path)

  end
  return string.format("%s (%s)", tail, path)
end

local lua_custom_path_func = function (path)
  local tail = require("telescope.utils").path_tail(path)
  local show_path = path
  local default_nvim_cfg_path = vim.fn.expand('$HOME').. "/.config/nvim"
  if string.find(path, default_nvim_cfg_path, 1, true)  then
    show_path = string.gsub(path, ".*%/.config/nvim/", "")
    return string.format("[🔥[nvim]]:%s (%s)", tail, show_path)
  end
  local other_path = vim.fn.expand('$HOME').. "/.local/share/nvim/lazy"
  if string.find(path, other_path, 1, true)  then
    show_path = string.gsub(path, ".*%/.local/share/nvim/lazy/", "")
    return string.format("[🔥[lazy]]:%s (%s)", tail, show_path)
  end
  return string.format("%s (%s)", tail, path)
end

local find_java_project_root_dir = function()
  local current_file_dir = vim.fn.expand('%:p:h')
  local patterns = {".*/src/main/java", ".*/src/test/java"}
  for _, pattern in pairs(patterns) do
    local matched = string.match(current_file_dir, pattern)
    if matched ~= nil then
      return string.gsub(matched, "/src/*/java", "")
    end
  end
  return nil
end



local find_lua_project_root_dir = function ()
  local home_path  = vim.fn.expand('$HOME')
  local current_file_dir = vim.fn.expand('%:p:h')
  local lazy_root =  home_path.."/.local/share/nvim/lazy/"
  local index = string.find(current_file_dir, lazy_root, 1, true)
  if index then
    local sub_project_str = string.sub(current_file_dir, string.len(lazy_root)+1)
    local project_name =  string.match(sub_project_str, "[^/]*", 1)
    return lazy_root..  project_name
  end
  local default_nvim_cfg_path = home_path.. "/.config/nvim"
  if string.find(current_file_dir, default_nvim_cfg_path, 1, true)  then
    return default_nvim_cfg_path
  end
  return nil
end

function M.setup(opts)
  -- copy the workspace folders use builtin
  local sorted_workspace_folders = vim.deepcopy(opts.folders, true)
  table.sort(sorted_workspace_folders, function(a, b)
    return string.len(a.path) > string.len(b.path)
  end)
  M.workspace_fodlers = sorted_workspace_folders


  -- f.register_file_type_path_display("java", java_custom_path_func)
  f.register_file_type_path_display("default", M.beautify_path)
  f.register_file_type_path_display("lua", M.beautify_path)
  f.register_file_type_path_display("java", M.beautify_path)
  f.register_file_type_project_root_func("java", find_java_project_root_dir)
  f.register_file_type_project_root_func("lua", find_lua_project_root_dir)
  f.setup(opts)
end


return M
