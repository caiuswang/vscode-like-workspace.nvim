-- local json = require('json')  -- Requires lua-json package or use vim.json
local json = vim.json
local Path = require('plenary.path')
local log = require("vscodews.log")

---@class Workspace
---@field file_path string
---@field config WorkspaceConfig
---@field get_enabled_folders fun(): WorkspaceFolder[]
local Workspace = {}
Workspace.__index = Workspace

function Workspace:new(path)
    self = setmetatable({}, Workspace)
    self.file_path = path
    self.config = {
        folders = {},
        settings = {}
    }
    self.loaded = false
    return self
end

function Workspace:load()
    -- Add debug statements in your workspace code
    local ok, content = pcall(Path:new(self.file_path).read, Path:new(self.file_path))
    if not ok then
        log.info("Workspace file not found: " .. (self.file_path or "nil"))
        return
    end

    local parsed = json.decode(content)
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
    -- Apply Neovim-specific settings
    if self.config.settings.neovim then
        local nvim_settings = self.config.settings.neovim
        if nvim_settings.enabled_plugins then
            -- Implement plugin management logic
        end

        if nvim_settings.keymaps then
            self:_setup_keymaps(nvim_settings.keymaps)
        end
    end

    -- Apply editor settings
    if self.config.settings.editor then
        vim.bo.tabstop = self.config.settings.editor.tabSize
        vim.bo.shiftwidth = self.config.settings.editor.tabSize
        vim.bo.expandtab = self.config.settings.editor.insertSpaces
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
    local content = json.encode(self.config)
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
