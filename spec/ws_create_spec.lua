local ws = require("vscodews")
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
