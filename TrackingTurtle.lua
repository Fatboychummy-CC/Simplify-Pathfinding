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

return tTurtle
