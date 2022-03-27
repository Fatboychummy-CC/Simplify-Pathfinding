--- Pathfinds using the Map.
-- This module is responsible for checking and pathfinding along the map passed to it.
-- @module[kind=pathfind] Path

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

end

--- Create an iterator that will move a turtle along a path.
-- This allows you to use a for loop and complete some action for every movement.
-- @tparam table path The path to follow.
-- @tparam table turtle The turtle object to use. This expects a turtle object in the format of the TrackingTurtle, which has the extra methods '.getPosition()' and '.getFacing()'
function Path.iteratePath(path, turtle)

end

return Path
