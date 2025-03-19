local M = {}

local required_plugins = {
  { lib = "telescope", optional = false },
  {
    lib = "nvim-treesitter",
    optional = true,
    info = "(Required for `:Telescope treesitter`.)",
  },
  {
    lib = "lspconfig",
  },
}

local required_executables = {
  { name = "git", args= "--version", info = "Required for git commands." },
  { name = "rg", args = "--version", info = "Required for searching." },
  { name = "fd", args = "--version", info = "Required for searching." },
  { name = "jdtls", args = "-h", info = "Required for Java LSP." },
}

local function lualib_installed(lib_name)
  local res, _ = pcall(require, lib_name)
  return res
end

local function run_command(executable, command)
  local is_present = vim.fn.executable(executable)
  if is_present == 0 then
    return false
  else
    local success, result = pcall(vim.fn.system, { executable, command })
    if success then
      return vim.trim(result)
    else
      return false
    end
  end
end

M.check = function()
  vim.health.start("check neovim")
  print("Checking health...")
  vim.health.info("check neovim", "info", "Checking health...")
  vim.health.ok("check neovim")
  for _, plugin in ipairs(required_plugins) do
    if lualib_installed(plugin.lib) then
      vim.health.ok(plugin.lib .. " installed.")
    else
      local lib_not_installed = plugin.lib .. " not found."
      if plugin.optional then
        vim.health.warn(("%s %s"):format(lib_not_installed, plugin.info))
      else
        vim.health.error(lib_not_installed)
      end
    end
  end
  for _, executable in ipairs(required_executables) do
    local result = run_command(executable.name, executable.args)
    if result then
      vim.health.ok(("%s installed."):format(executable.name))
    else
      vim.health.error(("%s not found. %s"):format(executable.name, executable.info))
    end
  end

end
return M
