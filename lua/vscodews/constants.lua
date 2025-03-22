local Path = require("plenary.path")
NVIM_SETTING_CONFIG_BASE_DIR = ".nvim"
WORKSPACE_FILE_NAME = "workspace.json"
USER_DEFAULT_WORKSPACE_FILE_NAME = Path:new(vim.fn.expand("$HOME")):joinpath(NVIM_SETTING_CONFIG_BASE_DIR):joinpath(WORKSPACE_FILE_NAME)
