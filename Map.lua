--- 3D map of the environment.
-- This module is responsible for holding and manipulating a 3D map of the currently known environment.
-- @module Map

-- Get the prefix to be used for requiring submodules.
-- This allows this folder to be named anything.
local prefix = ... .. "."

-- Include CC modules
local expect = require "cc.expect".expect

-- Other needed modules
local Node = require(prefix .. "Node")

local Map = {}

--- Create a new Map object.
-- @treturn table The map object
function Map.create()

end

--- Load a map object from a file.
-- @tparam string filename The file to load from, in absolute form.
-- @treturn boolean,table Whether the file loading was successful, and the data as a map object.
function Map.load(filename)
  expect(1, filename, "string")
end

--- Save a map object to a file.
-- @tparam string filename The file to save to, in absolute form.
-- @tparam table map The map object that was created via either create or load.
-- @treturn boolean Whether saving the file[s] was successful or not.
function Map.save(filename, map)
  expect(1, filename, "string")
  expect(1, map, "table")
end

return Map
