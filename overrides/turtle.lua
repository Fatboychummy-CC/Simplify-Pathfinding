local expect = require "cc.expect".expect

local old = {}
local position = {0, 0, 0}
local facing = 0
local offsets = {
  [0] = { 0, 0, 1},
  [1] = {-1, 0, 0},
  [2] = { 0, 0,-1},
  [3] = { 1, 0, 0},
}

local function AddOffsets()
  return position[1] + offsets[facing][1],
         position[2] + offsets[facing][2],
         position[3] + offsets[facing][3]
end
local function SubOffsets()
  return position[1] - offsets[facing][1],
         position[2] - offsets[facing][2],
         position[3] - offsets[facing][3]
end
local function AddUp()
  return position[1], position[2] + 1, position[3]
end
local function AddDown()
  return position[1], position[2] - 1, position[3]
end

return function(pathfinderObj, override)
  if override then
    if not turtle._PATHFINDER_OVERRIDE then
      for k, v in pairs(turtle) do
        if type(v) == "function" then
          old[k] = v
        end
      end

      local function scan()
        if turtle.detect() then
          pathfinderObj:AddObstacle(AddOffsets())
        else
          pathfinderObj:AddAir(AddOffsets())
        end
        if turtle.detectDown() then
          pathfinderObj:AddObstacle(AddDown())
        else
          pathfinderObj:AddAir(AddDown())
        end
        if turtle.detectUp() then
          pathfinderObj:AddObstacle(AddUp())
        else
          pathfinderObj:AddAir(AddUp())
        end
      end

      local floor = math.floor
      local function floorLocate()
        local x, y, z = gps.locate()
        if x then
          return floor(x), floor(y), floor(z)
        end
      end

      -- Declare functions to be overridden.
      local overrides = {
        -- [[ DEFAULT MOVEMENT FUNCTIONS ]]
        forward = function()
          local ok, err = old.forward()
          if ok then
            position = {AddOffsets()}
          end

          scan()

          return ok, err
        end,
        back = function()
          local ok, err = old.back()
          if ok then
            position = {SubOffsets()}
          end

          scan()

          return ok, err
        end,
        turnRight = function()
          local ok, err = old.turnRight()
          if ok then
            facing = (facing + 1) % 4
          end

          scan()

          return ok, err
        end,
        turnLeft = function()
          local ok, err = old.turnLeft()
          if ok then
            facing = (facing - 1) % 4
          end

          scan()

          return ok, err
        end,
        up = function()
          local ok, err = old.up()
          if ok then
            position = {AddUp()}
          end

          scan()

          return ok, err
        end,
        down = function()
          local ok, err = old.down()
          if ok then
            position = {AddDown()}
          end

          scan()

          return ok, err
        end,
        dig = function()
          local ok, err = old.dig()
          if ok then
            pathfinderObj:AddAir(AddOffsets())
          end
          return ok, err
        end,
        digDown = function()
          local ok, err = old.digDown()
          if ok then
            pathfinderObj:AddAir(AddDown())
          end
          return ok, err
        end,
        digUp = function()
          local ok, err = old.digUp()
          if ok then
            pathfinderObj:AddAir(AddUp())
          end
          return ok, err
        end,
        -- [[ NEW TURTLE FUNCTIONS ]]

        -- This function attempts to locate the turtle using GPS
        locate = function()
          -- Get first position
          local tPos = {floorLocate()}

          -- Never assume it just magically works.
          if not tPos[1] then
            return false, "GPS failure."
          end
          pathfinderObj:SetMapOffset(tPos[1], tPos[2], tPos[3])
          position = {tPos[1], tPos[2], tPos[3]}

          -- "Main loop" for turtle movement
          -- Turtle will spin if block is in front
          -- After full 360* turn, will go up a block.
          -- Repeat above until block above, then turtle will go down instead of up.
          -- Repeat all of above until air in front of turtle.
          local function moveLoop()
            local i = -1
            local ud = turtle.up
            while turtle.detect() do
              turtle.turnLeft()
              i = i + 1
              if i % 4 == 0 and i ~= 0 then
                if not ud() then
                  if ud == turtle.down then
                    return false
                  end
                  ud = turtle.down
                  ud()
                end
              end
            end

            return true
          end

          while true do
            -- Check if we're stuck in some kinda area
            if not moveLoop() then
              return false, "Stuck."
            end

            -- Not stuck, lets move forward!
            if turtle.forward() then
              -- get second position after movement
              local tPos2 = {floorLocate()}
              if not tPos2[1] then
                return false, "GPS failure."
              end
              position = tPos2 -- set current position

              -- Determine facing based off of what direction we moved.
              if tPos2[1] > tPos[1] then
                -- facing positive X
                facing = 3
              elseif tPos2[3] > tPos[3] then
                -- facing positive Z
                facing = 0
              elseif tPos2[1] < tPos[1] then
                -- facing negative X
                facing = 1
              else
                -- facing negative Z
                facing = 2
              end
              return true
            end
          end
        end,

        -- This function will face the turtle in a specific direction.
        -- 0 = +Z, 1 = -X, 2 = -Z, 3 = +X
        face = function(direction)
          expect(1, direction, "number")
          if direction < 0 or direction > 3 or direction % 1 ~= 0 then
            error("Bad argument #1: Expected integer in range 0-3", 2)
          end

          if facing == direction then return end

          if (facing + 1) % 4 == direction then
            turtle.turnRight()
          else
            while facing ~= direction do
              turtle.turnLeft()
            end
          end
        end,

        -- Simple goto function that just attempts to move in a direction
        simpleGoTo = function(x, y, z, canAttack, canDig, forceForward)
          expect(1, x, "number")
          expect(2, y, "number")
          expect(3, z, "number")
          expect(4, canAttack   , "boolean", "nil")
          expect(5, canDig      , "boolean", "nil")
          expect(6, forceForward, "boolean", "nil")

          -- This subfunction will attack and dig when movement fails, if allowed
          -- if neither are allowed, will error.
          local function ensure(movement, attack, dig)
            local ok, err = movement()
            if not ok then
              if movement == turtle.back then
                turtle.turnRight()
                turtle.turnRight()
              end

              if canAttack then
                attack()
              end
              if canDig then
                dig()
              end

              if movement == turtle.back then
                turtle.turnRight()
                turtle.turnRight()
              end
              if not canAttack and not canDig then
                error(string.format(
                  "Failed to move, and is not allowed to attack or dig: %s",
                  err
                ), 3)
              end
            end
          end

          -- Align to X axis
          while position[1] ~= x do
            local d = turtle.forward
            if position[1] > x then -- face -x
              if forceForward or facing ~= 3 then
                turtle.face(1)
              else
                d = turtle.back
              end
            else -- face +x
              if forceForward or facing ~= 1 then
                turtle.face(3)
              else
                d = turtle.back
              end
            end
            ensure(d, turtle.attack, turtle.dig)
          end

          -- Align to Y axis
          while position[2] ~= y do
            if position[2] > y then -- go down
              ensure(turtle.down, turtle.attackDown, turtle.digDown)
            else -- go up
              ensure(turtle.up, turtle.attackUp, turtle.digUp)
            end
          end

          -- Align to Z axis
          while position[3] ~= z do
            local d = turtle.forward
            if position[3] > z then -- face -z
              if forceForward or facing ~= 0 then
                turtle.face(2)
              else
                d = turtle.back
              end
            else -- face +z
              if forceForward or facing ~= 2 then
                turtle.face(0)
              else
                d = turtle.back
              end
            end
            ensure(d, turtle.attack, turtle.dig)
          end
        end,

        -- Function that follows a path from pathfinder
        followPath = function(path, canAttack, canDig, forceForward)
          expect(1, path, "table")
          expect(2, canAttack   , "boolean", "nil")
          expect(3, canDig      , "boolean", "nil")
          expect(4, forceForward, "boolean", "nil")

          for i = 1, #path do
            turtle.simpleGoTo(path[i].X, path[i].Y, path[i].Z, canAttack, canDig, forceForward)
          end
        end,
        getPosition = function()
          return position[1], position[2], position[3]
        end,
        getFacing = function()
          return facing
        end
      }

      for k, v in pairs(overrides) do
        turtle[k] = v
      end
      turtle._PATHFINDER_OVERRIDE = true
    else
      error("Pathfinder has already overridden turtle functions.", 2)
    end
  else
    if turtle._PATHFINDER_OVERRIDE then
      for k, v in pairs(old) do
        turtle[k] = v
      end

      turtle.locate = nil
    else
      error("Pathfinder is not currently overriding any turtle functions.", 2)
    end
  end
end
