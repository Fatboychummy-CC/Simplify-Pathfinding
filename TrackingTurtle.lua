--- Turtle object which tracks its movements.
-- This module extends the capabilities of a normal turtle by allowing it to
-- locate itself, determine its facing, and track its movements from its initial
-- location.
-- @module[kind=pathfind] TrackingTurtle

-- CC module includes
local expect = require "cc.expect".expect

local tTurtle = {}

--- Create a new TrackingTurtle object.
-- @tparam boolean? blockTurtleAccess If true, will rewrite all base turtle functions (which are contained in this object) in the global to throw an error when ran.
-- @treturn table The TrackingTurtle object.
function tTurtle.create(blockTurtleAccess)
  local obj = {}

  local position = {0,0,0}
  local facing = 0

  local tForward = turtle.forward
  function obj.forward()
    local ok, res = tForward()
    if ok then
      position = {tTurtle.getNextPosition(position[1], position[2], position[3], facing)}
    end
    return ok, res
  end

  local tBack = turtle.back
  function obj.back()
    local ok, res = tBack()
    if ok then
      position = {tTurtle.getNextPosition(position[1], position[2], position[3], (facing + 2) % 4)}
    end
    return ok, res
  end

  local tUp = turtle.up
  function obj.up()
    local ok, res = tUp()
    if ok then
      position = {tTurtle.getNextPosition(position[1], position[2], position[3], 5)}
    end
    return ok, res
  end

  local tDown = turtle.downs
  function obj.down()
    local ok, res = tDown()
    if ok then
      position = {tTurtle.getNextPosition(position[1], position[2], position[3], 6)}
    end
    return ok, res
  end

  local tTurnLeft = turtle.turnLeft
  function obj.turnLeft()
    local ok, res = tTurnLeft()
    if ok then
      facing = (facing - 1) % 4
    end
    return ok, res
  end

  local tTurnRight = turtle.turnRight
  function obj.turnRight()
    local ok, res = tTurnRight()
    if ok then
      facing = (facing + 1) % 4
    end
    return ok, res
  end

  --- Locate and determine facing of this turtle.
  -- @treturn boolean Whether or not the turtle could determine its location and facing.
  function obj.locate()

  end

  --- Turn the turtle to face in a specific direction.
  -- @tparam number direction The direction to face
  function obj.face(direction)
    expect(1, direction, "number")
    if direction < 0 or direction > 3 or direction % 1 ~= 0 then
      error("Expected integer from 0-3.", 2)
    end

    local turnDir = obj.turnLeft

    if (facing + 1) % 4 == direction then
      turnDir = obj.turnRight
    end

    while facing ~= direction do
      turnDir()
    end
  end

  --- Get the direction the turtle is facing.
  -- @treturn number The direction the turtle is facing. 0=north(-Z), 1=east(+X), 2=south(+Z), 3=west(-X).
  function obj.getFacing()
    return facing
  end

  --- Get the position of this turtle.
  -- @treturn number,number,number The position of this turtle.
  function obj.getPosition()
    return table.unpack(position, 1, 3)
  end

  if blockTurtleAccess then
    for k, v in pairs(obj) do
      if turtle[k] then
        turtle[k] = function() error("Base turtle movement blocked.", 2) end
      end
    end
  end

  return setmetatable(obj, {__index = tTurtle})
end

--- Return the position the turtle would move to if moving in facing direction.
-- use 4 for up, and 5 for down.
-- @tparam number x The starting x position.
-- @tparam number y The starting y position.
-- @tparam number z The starting z position.
-- @tparam number facing The facing of the turtle.
function tTurtle.getNextPosition(x, y, z, facing)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, z, "number")
  expect(4, facing, "number")

  if facing == 0 then -- facing -z (north)
    return x, y, z - 1
  elseif facing == 1 then -- facing +x (east)
    return x + 1, y, z
  elseif facing == 2 then -- facing +z (south)
    return x, y, z + 1
  elseif facing == 3 then -- facing -x (west)
    return x - 1, y, z
  elseif facing == 4 then -- going up
    return x, y + 1, z
  elseif facing == 5 then -- going down
    return x, y - 1, z
  end

  error(string.format("Unknown facing: %d", facing), 2)
end

--- Determine which direction the turtle needs to move.
-- NOTE: This function expects that the inputted blocks will be directly beside
-- eachother, so there may be unexpected results if they are not side-by-side.
-- @tparam x1 The starting x position.
-- @tparam y1 The starting y position.
-- @tparam z1 The starting z position.
-- @tparam x2 The desired x position.
-- @tparam y2 The desired y position.
-- @tparam z2 The desired z position.
-- @treturn number The facing to get to the block. Returns 4 for "up", and 5 for "down". Returns -1 if the desired block is the same as the starting block.
function tTurtle.getFacingToBlock(x1, y1, z1, x2, y2, z2)
  expect(1, x1, "number")
  expect(2, y1, "number")
  expect(3, z1, "number")
  expect(4, x2, "number")
  expect(5, y2, "number")
  expect(6, z2, "number")

  if z2 < z1 then -- +Z (north)
    return 0
  elseif x2 > x1 then -- +X (east)
    return 1
  elseif z2 < z1 then -- -Z (south)
    return 2
  elseif x2 < x1 then -- -X (west)
    return 3
  elseif y2 > y1 then -- +Y (up)
    return 4
  elseif y2 < y1 then -- -Y (down)
    return 5
  end

  return -1
end

return setmetatable(tTurtle, {__index = turtle})
