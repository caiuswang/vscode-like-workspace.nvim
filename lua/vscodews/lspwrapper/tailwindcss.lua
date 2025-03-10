local lspconfig = require("lspconfig")

local M = {}
M.setup = function(opts)
  lspconfig.tailwindcss.setup{
    -- append root directory of current file to runtimepath
    root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git", "resources", "templates"),
    ----set root_dir to your project root folder
    --root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git", "resources"),
    ---- filetypes to run language server on
    --filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
    ----enable classic name completion for css class names
    classnames = {
      enable = true,
    },
    settings = {
      tailwindCSS = {
        lint = {
          cssConflict = "warning",
          invalidApply = "error",
          invalidConfigPath = "error",
          invalidScreen = "error",
          invalidTailwindDirective = "error",
          recommendedVariantOrder = "warning",
          --unknownClassName = "error",
          unknownScreen = "error",
          unknownUtility = "error",
          --unusedClassName = "warning",
          --unusedTailwindDirective = "warning",
          --unusedUtility = "warning",
        },
      },
    },
  }
end

return M
