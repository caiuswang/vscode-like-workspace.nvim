require('vscodews.constants')
local Path = require('plenary.path')
local Workspace = require('vscodews.workspace')
local log = require('vscodews.log')
local WorkspaceManager = {
  active_workspace = nil,
  workspaces = {},
  pre_load_callbacks = {},
  post_load_callbacks = {},
}

function WorkspaceManager:find_workspace_file(start_dir)
  local dir = Path:new(start_dir or vim.fn.getcwd())
  for _ = 1, 10 do -- Search up to 10 parent directories
    local candidate = dir:joinpath(NVIM_SETTING_CONFIG_BASE_DIR):joinpath(WORKSPACE_FILE_NAME)
    if candidate:exists() then
      log.info('Found workspace file: ' .. candidate.filename)
      return candidate.filename
    end
    dir = dir:parent()
    if dir.filename == '/' then break end
  end
end

function WorkspaceManager:load_workspace(path)
  if self.active_workspace then
    self.active_workspace:save()
  end

  local ws = Workspace:new(path)
  for _, callback in ipairs(self.pre_load_callbacks) do
    callback(path)
  end
  ws:load()
  self.active_workspace = ws
  self.workspaces[path] = ws

  vim.api.nvim_exec_autocmds('User', { pattern = 'WorkspaceLoaded' })

  -- Execute post-load callbacks
  for _, callback in ipairs(self.post_load_callbacks) do
    callback(ws)
  end
end

---@param callback fun(workspace: Workspace)
function WorkspaceManager:register_pre_load_callback(callback)
  local filter_table = vim.tbl_filter(function(cb) return cb == callback end, self.pre_load_callbacks)
  if #filter_table == #self.pre_load_callbacks then
    table.insert(self.pre_load_callbacks, callback)
  end
end

---@param callback fun(workspace: Workspace)
function WorkspaceManager:register_post_load_callback(callback)
  -- check if exists and ,if not insert, and check if loaded, if loaded, call the callback
  if self.loaded then
    callback(self.active_workspace)
  end
  local filter_table = vim.tbl_filter(function(cb) return cb == callback end, self.post_load_callbacks)
  if not filter_table or #filter_table == 0 then
    table.insert(self.post_load_callbacks, callback)
  end
end

function WorkspaceManager:create_user_command()
  vim.api.nvim_create_user_command('WorkspaceAddFolder', function(opts)
    -- Ensure there are exactly 2 arguments
    if #opts.fargs ~= 2 then
      -- Print an error if not exactly 2 arguments
      vim.api.nvim_err_writeln("Error: workspace add-folder requires exactly 2 arguments: name + path")
      return
    end
    vim.notify('Adding folder name: ' .. opts.fargs[1])
    vim.notify('Adding folder path: ' .. opts.fargs[2])
    if self.active_workspace then
      self.active_workspace:add_folder(opts.fargs[2], opts.fargs[1])
    end
  end, { nargs = "+" , count = 1, complete = 'dir' })
  -- workspace folder remove
  vim.api.nvim_create_user_command('WorkspaceRemoveFolder', function(opts)
    if self.active_workspace then
      self.active_workspace:remove_folder()
    end
  end, { nargs = 0 })

  -- workspace folder toggle
  vim.api.nvim_create_user_command('WorkspaceToggleFolder', function()
    if self.active_workspace then
      self.active_workspace:toggle_folder()
    end
  end, { nargs = 0 })
  vim.api.nvim_create_user_command('WorkspaceOpenSetting', function()
    if self.active_workspace then
      vim.cmd('e ' .. self.active_workspace.file_path)
    end
  end, {})

  vim.api.nvim_create_user_command('WorkspaceReload', function()
    if self.active_workspace then
      self.active_workspace:load()
    end
  end, {})

  vim.api.nvim_create_user_command('WorkspaceSave', function()
    if self.active_workspace then
      self.active_workspace:save()
    end
  end, {})
  -- workspace folder list
  vim.api.nvim_create_user_command('WorkspaceFolders', function()
    if self.active_workspace then
      local folders = self.active_workspace:get_enabled_folders()
      for _, folder in ipairs(folders) do
        vim.notify('Name: ' .. folder.name .. ' Path: ' .. folder.path)
      end
    end
  end, {})
end

function WorkspaceManager:init()
  -- workspace create in cwd
  vim.api.nvim_create_autocmd('VimEnter', {
    callback = function()
      local ws_file = self:find_workspace_file()
      if ws_file then
        self:load_workspace(ws_file)
        self:create_user_command()
      else
        log.info('No workspace file found')
      end
      vim.api.nvim_create_user_command('WorkspaceCreate', function()
        Workspace:create_one_from_defaults()
      end, { nargs = 0 })
    end
  })
end

return WorkspaceManager
