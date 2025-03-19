local M = {}

-- Default configuration
M.config = {
  log_file_path = vim.fn.stdpath("data") .. "/nvim-workspace.log", -- Default log file
  debug = false, -- Whether to also use vim.notify when logging
}

--- Configure the logging system
---@param opts table Configuration options: { log_file_path = string, debug = boolean }
function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})
end

--- Write a message to the log file with a timestamp
---@param level string|"INFO"|"WARN"|"ERROR" The logging level
---@vararg string The messages to log
function M.write(level, ...)
  M._auto_delete_log_file()
  level = level or "INFO"

  -- Concatenate all messages into a single string
  local message = table.concat({...}, " ")

  -- Write to log file
  local file, err = io.open(M.config.log_file_path, "a")
  if not file then
    vim.api.nvim_err_writeln(string.format("Failed to open log file (%s): %s", M.config.log_file_path, err))
    return
  end

  -- Get the current timestamp
  local time = os.date("%Y-%m-%d %H:%M:%S")

  -- Write the log message with timestamp and level
  file:write(string.format("[%s] [%s] %s\n", time, level, message))
  file:close()

  -- If debug mode is enabled, also notify in Neovim
  if M.config.debug then
    vim.notify(message, M._get_notify_level(level))
  end
end

--- Convenience function for logging an INFO-level message
---@vararg string The messages to log
function M.info(...)
  M.write("INFO", ...)
end

--- Convenience function for logging a WARN-level message
---@vararg string The messages to log
function M.warn(...)
  M.write("WARN", ...)
end

--- Convenience function for logging an ERROR-level message
---@vararg string The messages to log
function M.error(...)
  M.write("ERROR", ...)
end

--- Internal helper: Map log levels to vim.notify levels
---@param level string Log level ("INFO", "WARN", "ERROR")
---@return number Vim notify level (vim.log.levels)
function M._get_notify_level(level)
  local notify_levels = {
    INFO = vim.log.levels.INFO,
    WARN = vim.log.levels.WARN,
    ERROR = vim.log.levels.ERROR,
  }
  return notify_levels[level] or vim.log.levels.INFO
end

function M._auto_delete_log_file()
  local log_file_path = M.config.log_file_path
  if vim.fn.filereadable(log_file_path) == 1 then
    -- if file size is greater than 10MB, delete it
    if vim.fn.getfsize(log_file_path) > 10 * 1024 * 1024 then
      vim.fn.delete(log_file_path)
    end
  end
end

return M
