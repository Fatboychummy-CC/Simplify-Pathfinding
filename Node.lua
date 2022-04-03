--- A node of data.
-- A node contains all information needed to pathfind, and represents a single x,y,z position.
-- @module Node

-- Include CC modules
local expect = require "cc.expect".expect

-- Localized math functions
local abs = math.abs

local Node = {}

--- Create a new node.
-- @tparam number x The X coordinate.
-- @tparam number y The Y coordinate.
-- @tparam number z The Z coordinate.
-- @treturn Node The constructed node.
function Node.create(x, y, z)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, z, "number")

  -- @type Node
  return {
    x = x,
    y = y,
    z = z,
    gCost = 0,
    hCost = 0,
    fCost = 0,
    --- Calculate Manhattan distance to another position.
    -- @tparam Node self The current node to operate on.
    -- @tparam number x The X coordinate to get distance to.
    -- @tparam number y The Y coordinate to get distance to.
    -- @tparam number z The Z coordinate to get distance to.
    MHDistanceTo = function(self, x, y, z)
      return abs(self.x - x) + abs(self.y - y) + abs(self.z - z)
    end
  }
end

return Node
