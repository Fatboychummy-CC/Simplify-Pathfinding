--- 3D map of the environment.
-- This module is responsible for holding and manipulating a 3D map of the currently known environment.
-- WARNING: All map object methods do not check input types, as an optimization to make pathfinding faster.
-- @module Map

-- Get the prefix to be used for requiring submodules.
-- This allows this folder to be named anything.
local prefix = (...):match("(.+)%.") .. "."

-- Include CC modules
local expect = require "cc.expect".expect

-- Other needed modules
local Node = require(prefix .. "Node")

local Map = {}

--- Create a new Map object.
-- @treturn Map The map object
function Map.create()
  -- @type Map
  return {
    nodes = {}
    --- Get a node.
    -- Get a node at position x, y, z. If the node does not exist, a new one will be created.
    -- @tparam self Map The map object to operate on.
    -- @tparam x The X coordinate.
    -- @tparam y The Y coordinate.
    -- @tparam z The Z coordinate.
    -- @treturn Node The node grabbed.
    -- @usage local node = Map:Get(x, y, z)
    Get = function(self, x, y, z)
      -- check if X axis exists
      if not self.nodes[x] then self.nodes[x] = {} end
      local X = self.nodes[x]

      -- check if Y axis exists
      if not X[y] then X[y] = {} end
      local Y = X[y]

      -- check if the node exists
      if not Y[z] then Y[z] = Node.create(x, y, z) end

      -- return the node
      return Y[z]
    end,

    --- Mark a node as an obstacle.
    -- Marks a node as an obstacle. ie: A block the pathfinder will not try to go through.
    -- @tparam self Map The map object to operate on.
    -- @tparam x The X coordinate.
    -- @tparam y The Y coordinate.
    -- @tparam z The Z coordinate.
    -- @usage Map:MarkBlocked(x, y, z)
    MarkBlocked = function(self, x, y, z)
      self:Get(x, y, z).blocked = true
    end,

    --- Mark a node as cleared.
    -- Marks a node as an cleared. ie: A block the pathfinder will try to go through.
    -- @tparam self Map The map object to operate on.
    -- @tparam x The X coordinate.
    -- @tparam y The Y coordinate.
    -- @tparam z The Z coordinate.
    -- @usage Map:MarkUnblocked(x, y, z)
    MarkUnblocked = function(self, x, y, z)
      self:Get(x, y, z).blocked = false
    end,

    xOffset = 0,
    yOffset = 0,
    zOffset = 0
  }
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
