--- This module can be used to pathfind.
-- @module A*
-- @alias a

-- @TODO Once I'm settled, get Illuaminate running so I can actually generate docs (and confirm that the docs stuff I have actually works)

local prefix, pathToSelf = ...
if prefix:match("%.init$") then
  prefix = prefix:sub(1, -5) -- require "Pathfinder.init" for whatever reason
else
  prefix = prefix .. "." -- require "Pathfinder"
end
-- prefix is now "Path.To.Pathfinder."

local ok, expect = pcall(require, "cc.expect")
if ok then
  expect = expect.expect
else
  error("This module will only work on CC:Tweaked for minecraft 1.12.2+")
end

-- Combine prefix to library.
local function Combine(lib)
  return prefix .. lib
end

local map = require(Combine "Map")

local a = {YieldTime = 3000}
local mt = {__index = {}}
local index = mt.__index

-- Yield function to yield when needed.
local endTime = os.epoch("utc") + a.YieldTime
local function yieldCheck()
  if endTime < os.epoch("utc") then
    endTime = os.epoch("utc") + a.YieldTime
    os.queueEvent("pathfinder_dummy_event")
    os.pullEvent("pathfinder_dummy_event")
  end
end

local function CheckSelf(self)
  if type(self) ~= "table" or not self._ISPATHFINDER then
    error("Expected ':' when calling method on PathfinderObject.", 3)
  end
end

local placed = {n = 0}
local asyncCount = 0
local function PutBlock(enable, x, y, z, name, clearing)
  if enable then
    if not clearing then
      placed.n = placed.n + 1
      placed[placed.n] = {x,y,z}
    end
    local _ = commands.execAsync(
      string.format(
        "setblock %d %d %d %s",
        x, y, z,
        name
      )
    )
    asyncCount = asyncCount + 1
    if asyncCount >= (clearing and 50 or 10) then
      asyncCount = 0
      os.sleep()
    end
  end
end

local function CleanPlacements(enable)
  if enable then
    for i = 1, placed.n do
      PutBlock(true, placed[i][1], placed[i][2], placed[i][3], "minecraft:air", true)
    end
    placed = {n = 0}
  end
end

--- Pathfind from a given point, to a given point.
-- @tparam number x1 The X position of the start point.
-- @tparam number y1 The Y position of the start point.
-- @tparam number z1 The Z position of the start point.
-- @tparam number x2 The X position of the end point.
-- @tparam number y2 The Y position of the end point.
-- @tparam number z2 The Z position of the end point.
-- @tparam number? startFacing The way the first node is facing. Pathfinding will have slight priority in this direction.
-- @treturn boolean,table|string First value is if a valid path was found, second value is the path or a string error explaining what went wrong.
function index:Pathfind(x1, y1, z1, x2, y2, z2, startFacing)
  CheckSelf(self)
  expect(1, x1, "number")
  expect(2, y1, "number")
  expect(3, z1, "number")
  expect(4, x2, "number")
  expect(5, y2, "number")
  expect(6, z2, "number")
  expect(7, startFacing, "number")
  startFacing = startFacing or 0

  local map = self.Map
  local beginNode = map:Get(x1, y1, z1)
  local endNode = map:Get(x2, y2, z2)

  local OPEN = {n = 0}
  local CLOSED = {n = 0}

  -- Checks if a node is inside a table.
  local function IsIn(t, node)
    for i = 1, t.n do
      if t[i] == node then
        return true, i
      end
    end
    return false
  end

  -- Insert a node into a table.
  local function Insert(t, node)
    if not t.n then error("Insert given bad input, please report this.", 2) end
    t.n = t.n + 1
    t[t.n] = node
  end

  -- Removes a node from a table.
  -- takes a node or node index.
  local function Remove(t, node)
    -- If given a number index, remove it.
    if not t.n then error("Remove given bad input, please report this.", 2) end
    if t[node] then -- Table indices are numbers.
      t.n = t.n - 1
      return table.remove(t, node)
    end

    -- otherwise find the node, then remove it.
    local ok, idx = IsIn(t, node)
    if ok then
      t.n = t.n - 1
      return table.remove(t, idx)
    end
  end

  -- Gets the lowest fcost node from a list.
  local function GetLowest(t)
    local min = math.huge
    local minH = math.huge
    local minIndex = -1

    -- return nothing if failure.
    if t.n == 0 then
      return
    end

    for i = 1, t.n do
      if t[i].F < min then
        min = t[i].F
        minH = t[i].H
        minIndex = i
      elseif t[i].F == min then
        if t[i].H < minH then
          minIndex = i
          minH = t[i].H
        end
      end
    end

    if minIndex == -1 then
      error("Min index is still -1, this should not happen. Please report.", 2)
    end

    return minIndex
  end

  -- Cleans Fcost of nodes in table, to allow reuse of map.
  local function CleanNodes(t)
    for _, node in ipairs(t) do
      node.F = math.huge
    end
  end

  -- climbs backwards through parents to determine the path.
  local function GetPath(node)
    local path = {}

    while node.Parent do
      table.insert(
        path,
        1,
        {
          X = node.x,-- + map.offset[1],
          Y = node.y,-- + map.offset[2],
          Z = node.z,-- + map.offset[3]
        }
      )
      node = node.Parent
    end

    path.n = #path

    return path
  end

  local function main()
    Insert(OPEN, beginNode)
    PutBlock(self.Debug.PlaceBlocks, beginNode.x, beginNode.y, beginNode.z, "minecraft:white_stained_glass")
    map:MakeStarterNode(beginNode, startFacing)

    for i = 1, self.Budget do
      local lowest = GetLowest(OPEN)
      if not lowest then
        return false, "All available nodes traversed, no path found."
      end

      yieldCheck()

      local current = Remove(OPEN, lowest)
      Insert(CLOSED, current)
      PutBlock(self.Debug.PlaceBlocks, current.x, current.y, current.z, "minecraft:black_stained_glass")

      if current == endNode then
        return true, GetPath(endNode)
      end

      local neighbors = map:GetNeighbors(current)
      for facing = 0, 5 do
        local neighbor = neighbors[facing]
        if neighbor.S ~= 1 and not IsIn(CLOSED, neighbor) then
          local f, g, h = map:CalculateFGHCost(neighbor, current, endNode)
          if f < neighbor.F then
            neighbor.F = f
            neighbor.G = g
            neighbor.H = h
            map:SetParent(neighbor, current)
            if not IsIn(OPEN, neighbor) then
              PutBlock(self.Debug.PlaceBlocks, neighbor.x, neighbor.y, neighbor.z, "minecraft:white_stained_glass")
              Insert(OPEN, neighbor)
            end
          end
        end
      end
    end

    return false, "Budget expended"
  end

  local ok, val1, val2 = pcall(main)

  CleanNodes(CLOSED)
  CleanNodes(OPEN)
  CleanPlacements(debug)

  if not ok then
    return false, val1
  end
  return val1, val2
end
mt.__call = index.Pathfind -- Allow use of Pathfinder() as well as Pathfinder:Pathfind()

--- Loads a map from a file.
-- @tparam string filename the absolute path to the file.
-- @tparam function? callback The callback to be used for loading.
-- @treturn PathfinderObject Self.
function index:LoadMap(filename, callback)
  CheckSelf(self)
  expect(1, filename, "string")
  expect(2, callback, "function", "nil")

  if not fs.exists(filename) then
    error("That file does not exist.", 2)
  end

  self.Map = map.FromFile(filename, callback)

  return self
end

--- Gets the map object. Can also be grabbed via PathfinderObject.Map.
-- @treturn table The MapObject associated with this PathfinderObject.
function index:GetMap()
  CheckSelf(self)

  return self.Map
end


--- Passthrough
-- @see MapObject:AddObstacle
-- @tparam number x The x position to put the node.
-- @tparam number y The y position to put the node.
-- @tparam number z The z position to put the node.
function index:AddObstacle(x, y, z)
  CheckSelf(self)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, z, "number")

  self.Map:AddObstacle(x, y, z)

  return self
end

--- Passthrough
-- @see MapObject:AddUnknown
-- @tparam number x The x position to put the node.
-- @tparam number y The y position to put the node.
-- @tparam number z The z position to put the node.
function index:AddUnknown(x, y, z)
  CheckSelf(self)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, z, "number")

  self.Map:AddUnknown(x, y, z)

  return self
end

--- Passthrough
-- @see MapObject:AddAir
-- @tparam number x The x position to put the node.
-- @tparam number y The y position to put the node.
-- @tparam number z The z position to put the node.
function index:AddAir(x, y, z)
  CheckSelf(self)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, z, "number")

  self.Map:AddAir(x, y, z)

  return self
end

--- Sets the map's internal offset.
-- When getting node information, this offset is subtracted from the input.
-- @tparam number x The X offset.
-- @tparam number y The Y offset.
-- @tparam number z The Z offset.
-- @treturn PathfinderObject Self.
function index:SetMapOffset(x, y, z)
  CheckSelf(self)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, z, "number")

  self.Map.Offset[1] = x
  self.Map.Offset[2] = y
  self.Map.Offset[3] = z

  return self
end

--- Creates a new PathfinderObject.
-- @tparam string name The name of this pathfinder (forwarded to the map).
-- @tparam number? offsetx The offset on the X axis.
-- @tparam number? offsety The offset on the Y axis.
-- @tparam number? offsetz The offset on the Z axis.
-- @treturn PathfinderObject The newly created object.
function a.New(name, offsetx, offsety, offsetz)
  return setmetatable(
    {
      Map = map.New(name, offsetx, offsety, offsetz),
      _ISPATHFINDER = true,
      Debug = {
        PlaceBlocks = false
      },
      Budget = 3000
    },
    mt
  )
end

return a
