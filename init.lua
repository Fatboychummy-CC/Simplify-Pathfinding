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

local placed = {n = 0}
local function PutBlock(enable, x, y, z, name, clearing)
  if enable then
    commands.exec(
      string.format(
        "setblock %d %d %d %s",
        x, y, z,
        name
      )
    )
    if not clearing then
      placed.n = placed.n + 1
      placed[placed.n] = {x,y,z}
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
-- Facings are: 0 = +z, 1 = -x, 2 = -z, 3 = +x
-- @tparam number x1 The first point position.
-- @tparam number y1 The first point position.
-- @tparam number z1 The first point position.
-- @tparam number x2 The second point position.
-- @tparam number y2 The second point position.
-- @tparam number z2 The second point position.
-- @tparam number startFacing The facing the turtle begins as.
-- @tparam number budget The loop budget to run with. If budget iterations have run, pathfinding will abort. Defaults to 10000.
-- @tparam boolean debug If enabled, assumes this is a command computer and places blocks along search path.
-- @treturn boolean If a valid path was found.
-- @treturn table? The path that was found.
function index:Pathfind(x1, y1, z1, x2, y2, z2, startFacing, budget, debug)
  CheckSelf(self)
  expect(1, x1, "number")
  expect(2, y1, "number")
  expect(3, z1, "number")
  expect(4, x2, "number")
  expect(5, y2, "number")
  expect(6, z2, "number")
  expect(7, startFacing, "number")
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
        {
          X = node.x,-- + map.offset[1],
          Y = node.y,-- + map.offset[2],
          Z = node.z,-- + map.offset[3]
        }
      )
      node = node.Parent
    end

    path.n = #path

    CleanNodes(CLOSED)
    CleanNodes(OPEN)
    CleanPlacements(debug)

    return path
  end

  Insert(OPEN, beginNode)
  PutBlock(debug, beginNode.x, beginNode.y, beginNode.z, "minecraft:white_stained_glass")
  beginNode.F = 0

  for i = 1, budget do
    local lowest = GetLowest(OPEN)
    if not lowest then
      return false, "All available nodes traversed, no path found."
    end
    local current = Remove(OPEN, lowest)
    Insert(CLOSED, current)
    PutBlock(debug, current.x, current.y, current.z, "minecraft:black_stained_glass")

    if current == endNode then
      return true, GetPath(endNode)
    end

    local neighbors = map:GetNeighbors(current.x, current.y, current.z)
    for facing = 0, 5 do
      local neighbor = neighbors[facing]
      if neighbor.S ~= 1 and not IsIn(CLOSED, neighbor) then
        local f, g, h = map:CalculateFGHCost(neighbor, beginNode, endNode)
        if f < neighbor.F then
          neighbor.F = f
          neighbor.G = g
          neighbor.H = h
          neighbor.Parent = current
          if not IsIn(OPEN, neighbor) then
            PutBlock(debug, neighbor.x, neighbor.y, neighbor.z, "minecraft:white_stained_glass")
            Insert(OPEN, neighbor)
          end
        end
      end
    end
  end

  return false, "Budget expended"
end
mt.__call = index.Pathfind -- Allow use of Pathfinder() as well as Pathfinder:Pathfind()

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
      local scan, err = peripheral.call(object, "scan", range)

      if scan then
        -- Initialize every block in range as air.
        for x = -range, range do
          for y = -range, range do
            for z = -range, range do
              self:AddAir(x + offsetx, y + offsety, z + offsetz)
            end
          end
        end

        -- For each block in the scan range, add it as an obstacle.
        for i, block in ipairs(scan) do
          self:AddObstacle(block.x + offsetx, block.y + offsety, block.z + offsetz)
        end
      end

      return scan, err
    end
  }

  if valid[peripheral.getType(object)] then
    return valid[peripheral.getType(object)]()
  else
    error(string.format("Unsupported scanner: %s", peripheral.getType(object)), 2)
  end
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
