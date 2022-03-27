--- Pathfinds using the Map.
-- This module is responsible for checking and pathfinding along the map passed to it.
-- @module[kind=pathfind] Path

-- cc module includes
local expect = require "cc.expect".expect

local Path = {}

--- Pathfind from one location to another, using the A* method.
-- @tparam Map map The map object to be used for pathfinding.
-- @tparam number x1 The source X position.
-- @tparam number y1 The source Y position.
-- @tparam number z1 The source Z position.
-- @tparam number x2 The destination X position.
-- @tparam number y2 The destination Y position.
-- @tparam number z2 The destination Z position.
-- @tparam number maxDepth The maximum cost-from-start-position before aborting.
-- @TODO Add a way to offset the costs so more efficient and slow/more sloppy but fast pathfinding can occur.
-- @treturn boolean,table? Whether the pathfinding was successful, and the path itself (if one was found).
function Path.astar(map, x1, y1, z1, x2, y2, z2, maxDepth)
  expect(1, map, "table")
  expect(2, x1, "number")
  expect(3, y1, "number")
  expect(4, z1, "number")
  expect(5, x2, "number")
  expect(6, y2, "number")
  expect(7, z2, "number")
  expect(8, maxDepth, "number", "nil")
end

--- Create an iterator that will move a turtle along a path.
-- This allows you to use a for loop and complete some action for every movement.
-- @tparam table path The path to follow.
-- @tparam table tu The turtle object to use. This expects a turtle object in the format of the TrackingTurtle, which has the extra methods '.getPosition()' and '.getFacing()'
-- @treturn function(boolean, boolean, boolean) Iterator which will move the turtle along the path, then return after each move.
function Path.iteratePath(path, tu)
  expect(1, path, "table")
  expect(2, tu, "table")
end

return Path
