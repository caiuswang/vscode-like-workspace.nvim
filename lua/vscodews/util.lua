local M = {}

function M.process_path_with_env(path)
  local env = vim.fn.environ()
  for k, v in pairs(env) do
    path = string.gsub(path, '$' .. k, v)
  end
  return path
end

function M:path_join(...)
  return table.concat({...}, '/')
end

return M

