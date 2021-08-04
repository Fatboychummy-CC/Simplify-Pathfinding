--- This module can be used to pathfind.
-- @module A*
-- @alias a

local prefix, pathToSelf = ...

-- Alter the package path so all submodules can require as needed.
local dir = "/" .. fs.getDir(pathToSelf)
local addon = string.format(";/%s/?.lua;/%s/?/init.lua", dir, dir)
if not string.find(package.path, addon, nil, 1) then
  package.path = package.path .. addon
end

local ok, expect = pcall(require, "cc.expect")
if ok then
  expect = expect.expect
else
  error("This module will only work on CC:Tweaked for minecraft 1.12.2+")
end

local map = require("map")

local a = {}
local mt = {__index = {}}
local index = mt.__index

local function CheckSelf(self)
  if type(self) ~= "table" or not self._ISPATHFINDER then
    error("Expected ':' when calling method on PathfinderObject.", 3)
  end
end

--- Pathfind from a given point, to a given point.
-- Facings are: 0 = +z, 1 = -x, 2 = -z, 3 = +x
-- @tparam number x1 The first point position.
-- @tparam number y1 The first point position.
-- @tparam number z1 The first point position.
-- @tparam number x2 The second point position.
-- @tparam number y2 The second point position.
-- @tparam number z2 The second point position.
-- @tparam number startFacing The facing the turtle begins as.
-- @tparam number budget The loop budget to run with. If budget iterations have run, pathfinding will abort. Defaults to 10000.
-- @treturn boolean If a valid path was found.
-- @treturn table? The path that was found.
function index:Pathfind(x1, y1, z1, x2, y2, z2, startFacing, budget)
  CheckSelf(self)
  expect(1, x1, "number")
  expect(2, y1, "number")
  expect(3, z1, "number")
  expect(4, x2, "number")
  expect(5, y2, "number")
  expect(6, z2, "number")
  expect(7, startFacing, "string")
  expect(8, budget, "number", "nil")
  budget = budget or 10000

  local map = self.Map
  local beginNode = map:Get(x1, y1, z1)
  local endNode = map:Get(x2, y2, z2)
  local fakeParentNode = {Facing = startFacing}

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
    t.n = t.n + 1
    t[t.n] = node
  end

  -- Removes a node from a table.
  -- takes a node or node index.
  local function Remove(t, node)
    -- If given a number index, remove it.
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
    local minIndex = -1

    -- return nothing if failure.
    if t.n == 0 then
      return
    end

    for i = 1, t.n do
      if t[i].F < min then
        min = t[i].F
        minIndex = i
      end
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
        {
          X = node.x + map.offset[1],
          Y = node.y + map.offset[2],
          Z = node.z + map.offset[3]
        }
      )
      node = node.Parent
    end

    path.n = #path

    CleanNodes(CLOSED)
    CleanNodes(OPEN)

    return path
  end

  Insert(beginNode)

  for i = 1, budget do
    local lowest = GetLowest(OPEN)
    if not lowest then
      return false, "All available nodes traversed, no path found."
    end
    local current = Remove(OPEN, lowest)
    Insert(CLOSED, current)

    if current == endNode then
      return true, GetPath(endNode)
    end

    for facing, neighbor in ipairs(map:GetNeighbors(current.x, current.y, current.z)) do
      if neighbor.S ~= 1 and not IsIn(CLOSED, neighbor) then
        local f, g, h = map:CalculateFGHCost(neighbor, beginNode, endNode)
        if f < neighbor.F then
          neighbor.F = f
          neighbor.G = g
          neighbor.H = h
          neighbor.Parent = current
          if not IsIn(OPEN, neighbor) then
            Insert(OPEN, neighbor)
          end
        end
      end
    end
  end

  return false, "Budget expended"
end

--- Loads a map from a file.
-- @tparam string filename the absolute path to the file.
-- @tparam function? callback The callback to be used for loading.
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

function index:GetMap()
  CheckSelf(self)

  return self.Map
end


--- The below three functions are all passthroughs to MapObject:Add___
-- @see MapObject:AddObstacle
-- @tparam number x The x position to put the node.
-- @tparam number y The y position to put the node.
-- @tparam number z The z position to put the node.
-- @see Pathfinder:AddUnknown
-- @see Pathfinder:AddAir
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
-- @see Pathfinder:AddObstacle
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
-- @see Pathfinder:AddObstacle
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
function index:SetMapOffset(x, y, z)
  CheckSelf(self)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, z, "number")

  self.Map.offset[1] = x
  self.Map.offset[2] = y
  self.Map.offset[3] = z

  return self
end

--- Depending on the mod of the scanner, will scan blocks around the scanner and add them to the map.
-- @tparam string object The peripheral name to be used to scan.
-- @tparam number range The range to be used.
-- @tparam number? offsetx The offset x position, defaults to 0.
-- @tparam number? offsety The offset y position, defaults to 0.
-- @tparam number? offsetz The offset z position, defaults to 0.
-- @tparam function? callback The callback to be called while loading.
-- @return The result of the scan, to be used by user.
function index:ScanIntoMapUsing(object, range, offsetx, offsety, offsetz, callback)
  CheckSelf(self)
  expect(1, object, "string")
  expect(2, range, "number")
  expect(3, offsetx, "number", "nil")
  expect(4, offsety, "number", "nil")
  expect(5, offsetz, "number", "nil")
  expect(6, callback, "function", "nil")
  offsetx = offsetx or 0
  offsety = offsety or 0
  offsetz = offsetz or 0
  callback = callback or function() end

  local valid = {
    geoScanner = function()
      -- Scan
      local scan = peripheral.call(object, "scan", range)

      local obsLoc = {}

      -- For each block in the scan range, add it as an obstacle.
      for i, block in ipairs(scan) do
        self.Map:Get(block.x + offsetx, block.y + offsety, block.z + offsetz).S = 1
        obsLoc[string.format("%d|%d|%d", block.x, block.y, block.z)] = true
      end

      -- For each block ***not*** in scan range, add it as air.
      for x = -range, range do
        for y = -range, range do
          for z = -range, range do
            if not obsLoc[string.format("%d|%d|%d", x, y, z)] then
              self.Map:Get(x + offsetx, y + offsety, z + offsetz).S = 2
            end
          end
        end
      end

      return scan
    end
  }

  if valid[peripheral.getType(object)] then
    valid[peripheral.getType(object)]()
  else
    error(string.format("Unsupported scanner: %s", peripheral.getType(object)), 2)
  end

  return self
end

function a.New(name, offsetx, offsety, offsetz)
  return setmetatable(
    {
      Map = map.New(name, offsetx, offsety, offsetz),
      _ISPATHFINDER = true
    },
    mt
  )
end

return a
