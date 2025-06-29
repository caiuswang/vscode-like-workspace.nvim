rockspec_format = '3.0'
package = "vscode-like-workspace"
version = "scm-1"
source = {
  -- TODO: Update this URL
  url = "git+https://github.com/caiuswang/vscode-like-workspace.nvim/",
}
dependencies = {
  -- Add runtime dependencies here
  -- e.g. "plenary.nvim",
  -- "plenary.nvim",
  -- "telescoep.nvim"
}
test_dependencies = {
  "nlua"
}
build = {
  type = "builtin",
  copy_directories = {
    -- Add runtimepath directories, like
    -- 'plugin', 'ftplugin', 'doc'
    -- here. DO NOT add 'lua' or 'lib'.
  },
}
