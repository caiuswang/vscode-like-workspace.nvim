
---@class WorkspaceConfigSettingsNeovim
---@field enabled_plugins string[]
---@field keymaps table
---
local WorkspaceConfigSettingsNeovim = {}

---@class WorkspaceConfigSettings
---@field neovim table
---@field editor table
local WorkspaceConfigSettings = {}


--- @class WorkspaceFolder
--- @field path string
--- @field name string
--- @field base_modules string[]
--- @field enabled boolean
local WorkspaceFolder = {}

---@class WorkspaceConfig
---@field folders WorkspaceFolder[]
---@field settings table -- Neovim-specific settings
local WorkspaceConfig = {}
