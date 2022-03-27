--- Turtle object which tracks its movements.
-- This module extends the capabilities of a normal turtle by allowing it to
-- locate itself, determine its facing, and track its movements from its initial
-- location.
-- @module[kind=pathfind] TrackingTurtle

local tTurtle = {}

--- Create a new TrackingTurtle object.
-- @tparam boolean? blockTurtleAccess If true, will rewrite all base turtle functions (which are contained in this object) in the global to throw an error when ran.
-- @treturn table The TrackingTurtle object.
function tTurtle.create(blockTurtleAccess)
  local obj = {}

  local tForward = turtle.forward
  function obj.forward()

  end

  local tBack = turtle.back
  function obj.back()

  end

  local tUp = turtle.up
  function obj.up()

  end

  local tDown = turtle.down
  function obj.down()

  end

  local tTurnLeft = turtle.turnLeft
  function obj.turnLeft()

  end

  local tTurnRight = turtle.turnRight
  function obj.turnRight()

  end

  --- Locate and determine facing of this turtle.
  -- @treturn boolean Whether or not the turtle could determine its location and facing.
  function obj.locate()

  end

  --- Turn the turtle to face in a specific direction.
  -- @tparam number direction The direction to face
  function obj.face(direction)

  end

  --- Get the direction the turtle is facing.
  -- @treturn number The direction the turtle is facing. 0=north(-Z), 1=east(+X), 2=south(+Z), 3=west(-X).
  function obj.getFacing()

  end

  --- Get the position of this turtle.
  -- @treturn number,number,number The position of this turtle.
  function obj.getPosition()

  end

  if blockTurtleAccess then
    for k, v in pairs(obj) do
      if turtle[k] then
        turtle[k] = function() error("Base turtle movement blocked.", 2) end
      end
    end
  end

  return obj
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

return tTurtle
