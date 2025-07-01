--- @class WorkspaceFolder
--- @field path string
--- @field name string
--- @field modules string[]
--- @field enabled boolean
local WorkspaceFolder = {}

---@class WorkspaceConfig
---@field folders WorkspaceFolder[]
---@field settings table 
local WorkspaceConfig = {}


---@class WorkspaceSettings
---@field neovim NeoVimSettings
local WorkspaceSettings = {}


---@class NeoVimSettings
---@field enabled_plugins string[]
---@field keymaps table
---@field editor EditorSettings
---@field language_editor LanguageEditorSettings
local NeoVimSettings = {}

---@class EditorSettings
---@field tabsize number
---@field shiftwidth number
---@field softtab boolean
---@field expandtab boolean
---@field spell boolean
local EditorSettings = {}

---@class LanguageEditorSettings
---@field tab_size number
---@field shift_width number
---@field soft_tab boolean
---@field expand_tab boolean
local LanguageEditorSettings = {}
