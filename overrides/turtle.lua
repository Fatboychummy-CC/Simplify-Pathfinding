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
  return position[1] + offsets[facing][1]
       + position[2] + offsets[facing][2]
       + position[3] + offsets[facing][3]
end
local function SubOffsets()
  return position[1] - offsets[facing][1]
       + position[2] - offsets[facing][2]
       + position[3] - offsets[facing][3]
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
        if type(k) == "function" then
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

      local overrides = {
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
        end
        locate = function()
          local tPos = {gps.locate()}

          if not tPos[1] then error("GPS failure.", 2) end

          local function moveLoop()
            local i = -1
            local ud = turtle.up
            while turtle.detect() do
              turtle.turnLeft()
              i = i + 1
              if i % 4 == 0 and i ~= 0 then
                if not ud() then
                  ud = ud == turtle.up and turtle.down or turtle.up
                  ud()
                end
              end
            end
          end

          local determined = false
          while not determined do
            moveLoop()
            if turtle.forward() then
              local tPos2 = {gps.locate()}
              if not tPos2[1] then error("GPS failure.", 2) end
              position = tPos2
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
              return
            end
          end
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
