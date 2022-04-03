--- Pathfinds using the Map.
-- This module is responsible for checking and pathfinding along the map passed to it.
-- @module Path

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
-- @tparam number start The index to start movement at. Useful if you need to continue following a path after aborting for whatever reason.
-- @treturn function(boolean, boolean, boolean) Iterator which will move the turtle along the path, then return after each move.
function Path.iteratePath(path, tu, start, canDig, canAttack, canGoBack)
  expect(1, path, "table")
  expect(2, tu, "table")
  expect(3, start, "number")

  local i = 0
  --- Iterator function
  -- @tparam canDig Whether the turtle can dig blocks.
  -- @tparam canAttack Whether the turtle can attack mobs in the way.
  -- @tparam canGoBack Whether to optimize movement so that the turtle can move backwards too.
  return function()
    i = i + 1
    if not path[i] then return end -- detect the end of the path.

    -- collect data about the turtle's current position and facing, as well as direction needed.
    local facing = tu.getFacing()
    local cX, cY, cZ = tu.getPosition()
    local nX, nY, nZ = table.unpack(path[i], 1, 3)
    local neededFacing = tu.getFacingToBlock(cX, cY, cZ, nX, nY, nZ)
    local movement = tu.forward

    -- if we can move backwards, do that.
    if canGoBack and facing == (neededFacing + 2) % 4 then
      movement = tu.back
    else
      -- if we can't go backwards or are not facing it properly, turn to it.
      tu.face(neededFacing)
    end

    for i = 1, 100 do
      -- Attempt to move.
      if movement() then
        return true, {nX, nY, nZ}
      end

      -- If we could not move, try attacking.
      if canAttack then
        -- if we were moving backwards along the path
        if canGoBack and facing == (neededFacing + 2) % 4 then
          -- Face the correct direction
          tu.face(neededFacing)
          facing = tu.getFacing()

          -- Set the new movement to be facing where we are going.
          movement = tu.forward
        end
        tu.attack()
      end

      -- If we could not move, also try digging.
      if canDig then
        -- if we were moving backwards along the path
        if canGoBack and facing == (neededFacing + 2) % 4 then
          -- Face the correct direction
          tu.face(neededFacing)
          facing = tu.getFacing()

          -- Set the new movement to be facing where we are going.
          movement = tu.forward
        end
        tu.dig()
      end

      -- hopefully we can just wait it out if something is blocking us... right?
      if not canAttack and not canDig then
        os.sleep(1)
      end
    end

    return false, "Failed to move."
  end
end

return Path
