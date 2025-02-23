local M = {}

function M.process_path_with_env(path)
  local env = vim.fn.environ()
  for k, v in pairs(env) do
    path = string.gsub(path, '$' .. k, v)
  end
  return path
end

return M

