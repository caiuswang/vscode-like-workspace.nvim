local util = require("vscodews.util")
local eq = assert.are.same
local wsManager = require("vscodews.workspace-manager")
-- local WorkspaceManager = require('vscodews.workspace-manager')
local tester_function = function ()
  error(7)
end

describe("find workspace file in current directory", function ()

  it("should find at current .nvim current directory", function ()
    eq(
      "./.nvim/workspace.json",
      wsManager:find_workspace_file("."))
  end)
  it ("could call user command ", function ()
    wsManager:init()
  end)
end)

describe("detecet lsp java home", function ()
  it ("should return nil when no env LSP_JAVA_HOME", function ()
    local path = util.process_path_with_env("$LSP_JAVA_HOME")
    assert.are_equals(
      nil,
      path
    )
  end
)
end
)

describe("detecet java home env", function ()
  it ("should return no nil when no env LSP_JAVA_HOME", function ()
    vim.env.JAVA_HOME = "/xxx/java_home"
    local path = util.process_path_with_env("$JAVA_HOME")
    assert.are_equals(
      vim.env.JAVA_HOME,
      path
    )
  end)
end)
