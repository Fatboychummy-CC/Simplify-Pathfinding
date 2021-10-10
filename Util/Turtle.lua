--- Turtle stoof
local expect = require "cc.expect".expect

local offsets = {
  [0] = { 0, 0,-1},
  [1] = { 1, 0, 0},
  [2] = { 0, 0, 1},
  [3] = {-1, 0, 0}
}

local function AddOffsets(position, facing)
  expect(1, position, "table")
  expect(2, facing, "number")
  return position[1] + offsets[facing][1],
         position[2] + offsets[facing][2],
         position[3] + offsets[facing][3]
end
local function SubOffsets(position, facing)
  expect(1, position, "table")
  expect(2, facing, "number")
  return position[1] - offsets[facing][1],
         position[2] - offsets[facing][2],
         position[3] - offsets[facing][3]
end
local function AddUp(position)
  expect(1, position, "table")
  return position[1], position[2] + 1, position[3]
end
local function AddDown(position)
  expect(1, position, "table")
  return position[1], position[2] - 1, position[3]
end

local module = {}
local mt = {__index = {}}
local index = mt.__index

local function CheckSelf(self)
  if type(self) ~= "table" or not self._ISTURTLEUTIL then
    error("Expected ':' when calling method on TurtleUtil.", 3)
  end
end

local floor = math.floor
local function floorLocate()
  local x, y, z = gps.locate()
  if x then
    return floor(x), floor(y), floor(z)
  end
end

function index:TurtleScan()
  CheckSelf(self)

  if turtle.detect() then
    self.Pathfinder:AddObstacle(AddOffsets(self.Position, self.Facing))
  else
    self.Pathfinder:AddAir(AddOffsets(self.Position, self.Facing))
  end
  if turtle.detectDown() then
    self.Pathfinder:AddObstacle(AddDown(self.Position))
  else
    self.Pathfinder:AddAir(AddDown(self.Position))
  end
  if turtle.detectUp() then
    self.Pathfinder:AddObstacle(AddUp(self.Position))
  else
    self.Pathfinder:AddAir(AddUp(self.Position))
  end
end

function index:Forward()
  CheckSelf(self)
  local ok, err = turtle.forward()
  if ok then
    self.Position = {AddOffsets(self.Position, self.Facing)}
  end

  self:TurtleScan()

  return ok, err
end

function index:Back()
  CheckSelf(self)
  local ok, err = turtle.back()
  if ok then
    self.Position = {SubOffsets(self.Position, self.Facing)}
  end

  self:TurtleScan()

  return ok, err
end

function index:Up()
  CheckSelf(self)
  local ok, err = turtle.up()
  if ok then
    self.Position = {AddUp(self.Position)}
  end

  self:TurtleScan()

  return ok, err
end

function index:Down()
  CheckSelf(self)
  local ok, err = turtle.down()
  if ok then
    self.Position = {AddDown(self.Position)}
  end

  self:TurtleScan()

  return ok, err
end

function index:TurnLeft()
  CheckSelf(self)
  local ok, err = turtle.turnLeft()
  if ok then
    self.Facing = (self.Facing - 1) % 4
  end

  self:TurtleScan()

  return ok, err
end

function index:TurnRight()
  CheckSelf(self)
  local ok, err = turtle.turnRight()
  if ok then
    self.Facing = (self.Facing + 1) % 4
  end

  self:TurtleScan()

  return ok, err
end

function index:Dig()
  CheckSelf(self)
  local ok, err = turtle.dig()
  if ok then
    self.Pathfinder:AddAir(AddOffsets(self.Position, self.Facing))
  end

  return ok, err
end

function index:DigDown()
  CheckSelf(self)
  local ok, err = turtle.digDown()
  if ok then
    self.Pathfinder:AddAir(AddDown(self.Position))
  end

  return ok, err
end

function index:DigUp()
  CheckSelf(self)
  local ok, err = turtle.digUp()
  if ok then
    self.Pathfinder:AddAir(AddUp(self.Position))
  end

  return ok, err
end

function index:Locate()
  CheckSelf(self)
  local pos = {floorLocate()}
  print("Initial given location:", pos[1], pos[2], pos[3])

  if not pos[1] then
    return false, "GPS failure."
  end

  self.Pathfinder:SetMapOffset(pos[1], pos[2], pos[3])
  self.Position = {pos[1], pos[2], pos[3]}

  -- "Main loop" for turtle movement
  -- Turtle will spin if block is in front
  -- After full 360* turn, will go up a block.
  -- Repeat above until block above, then turtle will go down instead of up.
  -- Repeat all of above until air in front of turtle.
  local function moveLoop()
    local i = -1
    local ud = self.Up
    while turtle.detect() do
      self:TurnLeft()
      i = i + 1
      if i % 4 == 0 and i ~= 0 then
        if not ud(self) then
          if ud == self.Down then
            return false
          end
          ud = self.down
          ud(self)
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
    if self:Forward() then
      -- get second position after movement
      local pos2 = {floorLocate()}
      if not pos2[1] then
        return false, "GPS failure."
      end

      self.Position = pos2 -- set current position

      -- Determine facing based off of what direction we moved.
      if pos2[1] > pos[1] then
        -- facing positive X
        self.Facing = 1
      elseif pos2[3] > pos[3] then
        -- facing positive Z
        self.Facing = 2
      elseif pos2[1] < pos[1] then
        -- facing negative X
        self.Facing = 3
      else
        -- facing negative Z
        self.Facing = 0
      end
      return true
    end
  end

  return false, "Unknown error occured."
end

function index:Face(direction)
  CheckSelf(self)
  expect(1, direction, "number")

  if direction < 0 or direction > 3 or direction % 1 ~= 0 then
    error("Bad argument #1: Expected integer in range 0-3", 2)
  end

  if self.Facing == direction then return end

  if (self.Facing + 1) % 4 == direction then
    self:TurnRight()
  else
    while self.Facing ~= direction do
      self:TurnLeft()
    end
  end
end

function index:MoveTo(x, y, z)
  CheckSelf(self)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, z, "number")
  print("GOTO:", x, y, z)
  print("FROM:", self.Position[1], self.Position[2], self.Position[3])

  -- This subfunction will attack and dig when movement fails, if allowed
  -- if neither are allowed, will error.
  local function ensure(movement, attack, dig)
    local ok, err = movement(self)
    if not ok then
      if movement == self.Back and (self.CanAttack or self.CanDig) then
        self:TurnRight()
        self:TurnRight()
      end

      if self.CanAttack then
        attack()
      end
      if self.CanDig then
        dig()
      end

      if movement == self.Back and (self.CanAttack or self.CanDig) then
        self:TurnRight()
        self:TurnRight()
      end
      if not canAttack and not canDig then
        return false,
               string.format(
                 "Failed to move, and not allowed to attack or dig: %s",
                 err
               )
      end
    end

    return ok, err
  end

  -- Align to X axis
  while self.Position[1] ~= x do
    local d = self.Forward
    if self.Position[1] > x then -- face -x
      if not self.ForceForward and self.Facing == 1 then
        d = self.Back
      else
        self:Face(3)
      end
    else -- face +x
      if not self.ForceForward and self.Facing == 3 then
        d = self.Back
      else
        self:Face(1)
      end
    end
    local ok, err = ensure(d, turtle.attack, turtle.dig)
    if not ok then return ok, err end
  end

  -- Align to Y axis
  while self.Position[2] ~= y do
    local ok, err
    if self.Position[2] > y then -- go down
      ok, err = ensure(self.Down, turtle.attackDown, turtle.digDown)
    else
      ok, err = ensure(self.Up, turtle.attackUp, turtle.digUp)
    end

    if not ok then return ok, err end
  end

  -- Align to Z axis
  while self.Position[3] ~= z do
    local ok, err
    local d = self.Forward
    if self.Position[3] > z then -- face -z
      if not self.ForceForward and self.Facing == 2 then
        d = self.Back
      else
        self:Face(0)
      end
    else -- face +z
      if not self.ForceForward and self.Facing == 0 then
        d = self.Back
      else
        self:Face(2)
      end
    end
    local ok, err = ensure(d, turtle.attack, turtle.dig)
    if not ok then return ok, err end
  end

  return true
end

function index:FollowPath(path)
  CheckSelf(self)
  expect(1, path, "table")
  local dh = io.open("debug.txt", 'w')
  dh:write(textutils.serialize(path)):close()

  for i = 1, #path do
    self:MoveTo(path[i].X, path[i].Y, path[i].Z)
  end
end

function index:GetPosition()
  CheckSelf(self)
  return self.Position[1], self.Position[2], self.Position[3]
end

function index:GetFacing()
  CheckSelf(self)
  return self.Facing
end

function module.new(Pathfinder)
  return setmetatable(
    {
      Pathfinder = Pathfinder,
      Position = {0, 0, 0},
      Facing = 0,
      CanAttack = false,
      CanDig = false,
      ForceForward = false,
      _ISTURTLEUTIL = true
    },
    mt
  )
end

return module
