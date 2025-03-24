local Path = require('plenary.path')
local log = require("vscodews.log")

---@class Workspace
---@field file_path string
---@field config WorkspaceConfig
---@field config_root string
local Workspace = {}

Workspace.__index = Workspace

function Workspace:new(path)
  self = setmetatable({}, Workspace)
  self.file_path = path
  self.config_root = Path:new(path):parent():parent().filename
  self.config = {
    folders = {},
    settings = {}
  }
  self.loaded = false
  return self
end


function Workspace:create_one_from_defaults()
  local ws = Workspace:new(USER_DEFAULT_WORKSPACE_FILE_NAME.filename)
  ws:load()
  -- remove all folders
  ws.config.folders = {}
  -- add current cwd to workspace
  ws:add_folder(vim.fn.getcwd(), 'current')
  local content = vim.json.encode(ws.config)
  local new_file_dir = Path:new(vim.fn.getcwd()):joinpath(NVIM_SETTING_CONFIG_BASE_DIR)
  if not new_file_dir:exists() then
    new_file_dir:mkdir()
  end
  local new_config_path = new_file_dir:joinpath(WORKSPACE_FILE_NAME)
  new_config_path:write(content, 'w')
  vim.notify("Workspace saved: " .. new_config_path.filename, vim.log.levels.INFO)
  ws:load()
  return ws
end

function Workspace:load()
  -- Add debug statements in your workspace code
  local ok, content = pcall(Path:new(self.file_path).read, Path:new(self.file_path))
  if not ok then
    log.error("Workspace file not found: " .. (self.file_path or "nil"))
    return
  end

  local parsed = vim.json.decode(content)
  local folders = parsed.folders
  local home = vim.fn.expand("$HOME")
  for _, folder in ipairs(folders) do
    folder.path = folder.path:gsub("%$HOME", home)
  end
  for _, folder in ipairs(folders) do
    if not folder.name then
      folder.name = Path:new(folder.path):basename()
    end
  end
  self.config = parsed
  log.info("Loading workspace from: " .. self.file_path)
  self:_apply_settings()
  self:_load_projects()
  self.loaded = true
end


function Workspace:_apply_settings()
  ---@type WorkspaceSettings
  local settings = self.config.settings
  -- Apply Neovim-specific settings
  if settings.neovim then
    local nvim_settings = settings.neovim
    if nvim_settings.enabled_plugins then
      -- Implement plugin management logic
    end
    if nvim_settings.keymaps then
      self:_setup_keymaps(nvim_settings.keymaps)
    end
    if nvim_settings.editor then
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "*",
        callback = function()
          self:_setup_editor_settings(nvim_settings.editor)
        end
      })
    end
    if nvim_settings.language_editor then
      --create aucmd by file type
      for file_type, editor_settings in pairs(nvim_settings.language_editor) do
        vim.api.nvim_create_autocmd("BufEnter", {
          pattern = "*." .. file_type,
          callback = function()
            self:_setup_editor_settings(editor_settings)
          end
        })
      end
    end
  end
end

function Workspace:_setup_editor_settings(editor_settings)
  if editor_settings.tabsize then
    vim.bo.tabstop = editor_settings.tabsize
  end
  if editor_settings.shiftwidth then
    vim.bo.shiftwidth = editor_settings.shiftwidth
  end
  if editor_settings.softtab then
    vim.bo.softtabstop = editor_settings.softtab
  end
  if editor_settings.expandtab then
    vim.bo.expandtab = editor_settings.expandtab
  end
  if editor_settings.spell then
    -- enable for all file types
    vim.cmd("setlocal spell spelllang=en_us,cjk")
  end
end
function Workspace:_setup_keymaps(keymaps)
  for action, keys in pairs(keymaps) do
    if action == "workspace.save" then
      vim.keymap.set('n', keys, function() self:save() end)
    elseif action == "workspace.reload" then
      vim.keymap.set('n', keys, function() self:load() end)
    end
  end
end

function Workspace:_load_projects()
  for _, folder in ipairs(self.config.folders) do
    local full_path = Path:new(self.file_path):parent():joinpath(folder.path).fsname
    if vim.fn.isdirectory(full_path) == 1 then
      self:_add_to_workspace(full_path)
    end
  end
end

function Workspace:_add_to_workspace(path)
  -- Add to Neovim's path
  vim.opt.path:append(path .. '/**')

  -- Optional: Load project-specific config
  local project_config = Path:new(path):joinpath('.nvim-project.lua')
  if project_config:exists() then
    dofile(project_config.filename)
  end
end

function Workspace:save()
  -- local content = json.encode(self.config, { indent = true })
  local content = vim.json.encode(self.config)
  Path:new(self.file_path):write(content, 'w')
  vim.notify("Workspace saved: " .. self.file_path)
end

function Workspace:add_folder(folder_path, name)
  table.insert(self.config.folders, {
    path = folder_path,
    name = name or vim.fn.fnamemodify(folder_path, ':t')
  })
end

function Workspace:remove_folder()
  local choose_folder_name = self:choose_folder()
  self.config.folders = vim.tbl_filter(function(folder)
    return folder.name ~= choose_folder_name
  end, self.config.folders)

end

function Workspace:choose_folder()
  -- list all workspace folders, let user choose one to remove
  local current_folders = vim.tbl_map(function(folder)
    return folder.name
  end, self.config.folders)
  local show_list = {}
  for i, folder in ipairs(current_folders) do
    show_list[i] = i .. ". " .. folder
  end
  local choose_folder =  vim.fn.inputlist(show_list)
  vim.notify("\nChoose folder: " .. current_folders[choose_folder])
  return current_folders[choose_folder]
end

function Workspace:toggle_folder()
  local choose_folder_name = self:choose_folder()
  for _, folder in ipairs(self.config.folders) do
    if folder.name == choose_folder_name then
      if folder.enabled == nil then
        folder.enabled = false
      else
        folder.enabled = not folder.enabled
      end
    end
  end
end

---@return WorkspaceFolder[]
function Workspace:get_enabled_folders()
  return vim.tbl_filter(function(folder)
    return folder.enabled == nil or folder.enabled
  end, self.config.folders)
end


return Workspace
