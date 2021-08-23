--- This module handles all map operations, including altering the map (adding air, obstacles, unknowns, etc).
-- This module is not returned directly (or intended to be used directly) to the user.
-- Precreated map objects should be used from the pathfinder module.
-- @module map

local expect = require "cc.expect".expect

-- set math functions as local
local abs, deg, atan2, min, sqrt = math.abs, math.deg, math.atan2, math.min, math.sqrt

local map = {}
local mapmt = {__index = {}}
local MapObject = mapmt.__index
local endTime = os.epoch("utc") + 3000
local function yieldCheck()
  if endTime < os.epoch("utc") then
    endTime = os.epoch("utc") + 3000
    os.queueEvent("pathfinder_dummy_event")
    os.pullEvent("pathfinder_dummy_event")
  end
end

-- @local
local function CheckSelf(self)
  if type(self) ~= "table" or not self._ISMAP then
    error("Expected ':' when calling method on MapObject.", 3)
  end
end

-- @type MapObject

--- This function serializes the table depending on the given mode argument.
-- Default mode will serialize to pure bytes, for large maps which take up a lot of storage space.
-- Passing true as the mode argument will serialize using what is essentially a modified textutils.serialize, for human readability.
-- @tparam boolean? mode The mode to be used.
-- @treturn string
function MapObject:Serialize(mode, callback)
  CheckSelf(self)
  expect(1, mode, "boolean", "nil")
  expect(2, callback, "function", "nil")
  callback = callback or function() end

  if name and #name > 256 then
    error("Name is too long! (Maximum 256 chars)", 2)
  end

  local percent = 0
  local state = "serialize"
  callback(state, percent, self.Name)

  local max = 0

  if mode then
    local output = {}
    local n = 0
    local function concat(s)
      n = n + 1
      output[n] = s .. "\n"
    end
    -- @todo This

    return {"Not yet implemented"}
  end

  local data = {"\179"}
  local n = 1
  local count = 0
  local noderuns = {}
  local runN = 0

  local function Add(d)
    n = n + 1
    data[n] = d
  end

  Add(string.pack("<i1", #self.name))     -- name length
  Add(self.name)                          -- name
  Add(string.pack("<i3", self.offset[1])) -- offset x
  Add(string.pack("<i3", self.offset[2])) -- offset y
  Add(string.pack("<i3", self.offset[3])) -- offset z

  for xIndex, YList in pairs(self.Map) do
    for yIndex, ZList in pairs(YList) do
      percent = count / max
      callback(state, percent, self.Name)

      local runsRemain = true
      local seen = {}
      while runsRemain do
        yieldCheck()
        -- Get the "minimum" node.
        local minIndex = math.huge
        for zIndex in pairs(ZList) do
          if zIndex < minIndex and not seen[zIndex] then
            minIndex = zIndex
          end
        end

        -- If we've claimed all the runs
        if minIndex == math.huge then
          runsRemain = false -- stop.
        else
          -- Otherwise, calculate when the run ends.
          local current = minIndex
          local nodeState = ZList[minIndex].S
          while ZList[current] and ZList[current].S == nodeState do
            current = current + 1
          end
          current = current - 1

          -- Put the run into the seen list
          for i = minIndex, current do
            seen[i] = true
          end
          count = count + abs(minIndex - current)

          -- Save the node run, if needed.
          if ZList[minIndex].S ~= 0 then -- If not unknown node...
            runN = runN + 1
            noderuns[runN] = {
              ZList[minIndex],
              ZList[current]
            }
          end
        end
      end
    end
  end

  -- Save the number of node runs.
  Add(string.pack("<i4", runN))

  -- Save each node run.
  for i = 1, runN do
    local run = noderuns[i]
    Add(string.pack("<i1", run[1].x - self.offset[1])) -- run x
    Add(string.pack("<i1", run[1].y - self.offset[2])) -- run y
    Add(string.pack("<i1", run[1].z - self.offset[3])) -- run z
    Add(string.pack("<i1", run[2].z - self.offset[3])) -- run end z
    Add(string.pack("<i1", run[1].S)) -- run state
  end

  callback("serialize-complete", percent, self.Name)

  return data
end

local directions = {
  { 1, 0, 0, 3 }, -- positive X
  {-1, 0, 0, 1 }, -- negative X
  { 0, 1, 0, 5 }, -- up
  { 0,-1, 0, 4 }, -- down
  { 0, 0, 1, 0 }, -- positive Z
  { 0, 0,-1, 2 }  -- negative Z
}

--- This method will populate a node's neighbors (if they haven't been populated already).
-- Directions 0-3 are along x/z axis, 4 and 5 are y axis.
-- @tparam Node node The node to populate.
-- @treturn {Node, Node, Node, Node, Node, Node} The neighbors of the node.
function MapObject:GetNeighbors(node)
  CheckSelf(self)
  expect(1, node, "table")

  if #node.Neighbors < 6 then
    node.Neighbors = {}
    for i = 1, 6 do
      local _x, _y, _z, dirname = table.unpack(directions[i], 1, 4)
      _x = _x + x
      _y = _y + y
      _z = _z + z

      node.Neighbors[dirname] = self:Get(_x, _y, _z) -- add neighbor to node
    end
  end

  return node.Neighbors
end

---
local function CreateNode(self, x, y, z, status, force)
  local lx = x - self.offset[1]
  local ly = y - self.offset[2]
  local lz = z - self.offset[3]

  if lx > 127 or lx < -128
    or ly > 127 or ly < -128
    or lz > 127 or lz < -128 then
    error("Bad arguments: Number not within signed 1-byte range.", 3)
  end
  if not self.Map[lx] then
    self.Map[lx] = {}
  end
  if not self.Map[lx][ly] then
    self.Map[lx][ly] = {}
  end
  if force then
    self.Map[lx][ly][lz] = {
      x = x,
      y = y,
      z = z,  -- Internal position for internal usage
      H = 0,  -- Distance to end node
      G = 0,  -- Cost from start node to this node.
      F = math.huge,  -- Combined values of H + G + P + TP
      S = status or 0   -- Node state -- 0 = unknown, 1 = blocked, 2 = air
    }
    -- Edges of range will reject pathfinding.
    if lx == 127 or lx == -128
      or ly == 127 or ly == -128
      or lz == 127 or lz == -128 then
      self.Map[lx][ly][lz].P2 = math.huge
    end
  else
    if not self.Map[lx][ly][lz] then
      self.Map[lx][ly][lz] = {
        x = x,
        y = y,
        z = z,  -- Internal position for internal usage
        H = 0,  -- Distance to end node
        G = 0,  -- Cost from start node to this node.
        F = math.huge,  -- Combined values of H + G + P + TP
        S = status or 0   -- Node state -- 0 = unknown, 1 = blocked, 2 = air
      }

      -- Edges of range will reject pathfinding.
      if lx == 127 or lx == -128
        or ly == 127 or ly == -128
        or lz == 127 or lz == -128 then
        self.Map[lx][ly][lz].P2 = math.huge
      end
    end
  end

  return self.Map[lx][ly][lz]
end

--- This function gets a node (and creates it if need be).
-- @tparam number x The x position of the node.
-- @tparam number y The y position of the node.
-- @tparam number z The z position of the node.
-- @treturn Node
function MapObject:Get(x, y, z)
  CheckSelf(self)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, z, "number")

  return CreateNode(self, x, y, z)
end

--- This function resizes the map object.
function MapObject:Pregen()
  CheckSelf(self)
end

--- This function adds an obstacle to the map.
-- When pathfinding with obstacles, the pathfinder will completely avoid these.
-- @tparam number x The x position of the obstacle.
-- @tparam number y The y position of the obstacle.
-- @tparam number z The z position of the obstacle.
function MapObject:AddObstacle(x, y, z)
  CheckSelf(self)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, z, "number")

  CreateNode(self, x, y, z, 1, true)

  return self
end

--- This function adds an unknown to the map.
-- When pathfinding, the pathfinder will attempt to ignore these unless no other path is available.
-- In code, H-Cost will be increased by 30.
-- @tparam number x The x position of the unknown.
-- @tparam number y The y position of the unknown.
-- @tparam number z The z position of the unknown.
function MapObject:AddUnknown(x, y, z)
  CheckSelf(self)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, z, "number")

  local node = CreateNode(self, x, y, z, 0, true)
  node.P = 10
  node.S = 0

  return self
end

--- This function adds an "air" to the map.
-- When pathfinding, "air" will be prioritized for the path.
-- @tparam number x The x position of the air.
-- @tparam number y The y position of the air.
-- @tparam number z The z position of the air.
function MapObject:AddAir(x, y, z)
  CheckSelf(self)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, z, "number")

  CreateNode(self, x, y, z, 2, true)

  return self
end

---
function MapObject:MakeStarterNode(node, originFacing)
  CheckSelf(self)
  expect(1, node, "table")
  expect(2, originFacing, "number")

  node.F = 0
  node.Facing = startFacing
  local fakeNode = {Neighbors = {}, Facing = startFacing, G = 0}
  fakeNode.Neighbors[(originFacing + 2) % 4] = node

  self:SetParent(node, fakeNode)
end

---
function MapObject:ClearStarterNode(node)
  node.F = math.huge
  node.Facing = nil
  node.ParentDir = nil
  node.Parent = nil
end

function MapObject:SetParent(node, parentNode)
  CheckSelf(self)
  expect(1, node, "table")
  expect(2, parentNode, "table")

  -- Determine turtle facing based on where parent was at
  local found = false
  local n = parentNode.Neighbors
  for dir = 0, 3 do
    if n[dir] == node then
      n.ParentDir = dir
      found = true
      break
    end
  end

  -- If the turtle moved up or down, the turtle's facing has not changed
  -- Set facing of this node to same facing as parent is.
  if not found then
    node.ParentDir = parentNode.ParentDir
  end

  node.Parent = parentNode
end

---
function MapObject:CalculateHCost(node, endNode)
  CheckSelf(self)
  expect(1, node   , "table")
  expect(2, endNode, "table")

  return (abs(node.x - endNode.x)
       + abs(node.y - endNode.y)
       + abs(node.z - endNode.z))
       * self.HFavor
end

---
function MapObject:CalculateGCost(node, fromNeighbor)
  CheckSelf(self)
  expect(1, node, "table")
  expect(2, fromNeighbor, "table")

  local turn = 0
  local unknown = 0

  if node.S == 1 then -- unknown node
    unknown = 10
  end

  -- determine if the turtle has turned.
  if self.OptimizeTurns then
    for dir = 0, 3 do
      if testNode == node then
        if dir ~= fromNeighbor.ParentDir then
          turn = 1
          break
        end
      end
    end
  end

  return (fromNeighbor.G + turn + unknown + 1) * self.GFavor
end

---
function MapObject:CalculateFGHCost(node, fromNeighbor, endNode)
  CheckSelf(self)
  expect(1, node, "table")
  expect(2, fromNeighbor, "table")
  expect(3, endNode, "table")

  local HCost = self:CalculateHCost(node, endNode)
  local GCost = self:CalculateGCost(node, fromNeighbor)

  return GCost + HCost, GCost, HCost
end

--- This function loads a map from a file, it determines the mode required while loading.
-- Does not yet support overflow files.
-- Read specs/SaveSpec.md to understand this.
-- @tparam string filename The name of the file to be loaded.
-- @tparam function callback The callback to be called during stages of loading.
-- @treturn mapobject
function map.FromFile(filename, callback)
  expect(1, filename, "string")
  expect(2, callback, "function", "nil")

  local data = setmetatable({_ISMAP = true, Map = {}}, mapmt)
  local h = io.open(filename, 'rb')

  local ok, err = pcall(function()
    callback("loading", 0, filename)

    if not h then
      error("File failed to open for reading.", 2)
    end

    local header = string.byte(h:read(1))
    if header ~= 179 then
      error("File is not of correct format.", 2)
    end

    local function readNumber(len)
      return string.unpack(string.format("<i%d", len), h:read(len))
    end

    local namelen = readNumber(1)
    data.Name = h:read(namelen)

    data.Offset = {readNumber(3), readNumber(3), readNumber(3)}

    local numNodeRuns = readNumber(4)

    for i = 1, numNodeRuns do
      local nodeX, nodeY, nodeZ, nodeEnd, nodeState = readNumber(1), readNumber(1), readNumber(1), readNumber(1), readNumber(1)

      yieldCheck()
      if i % 10 == 0 then
        callback("loading", i / numNodeRuns, filename)
      end

      local len = nodeZ - nodeEnd

      -- Only node types saved are air and obstacle, no need for unknowns.
      -- Everything is unknown by default
      if nodeState == 2 then
        for z = nodeZ, nodeEnd do
          data:AddAir(nodeX, modeY, z)
        end
      else
        for z = nodeZ, nodeEnd do
          data:AddObstacle(nodeX, nodeY, z)
        end
      end
    end
  end)

  pcall(h.close, h)

  callback("loading-complete", 1, filename)

  if not ok then
    error("Failed to read file:\n" .. err, 2)
  end

  return data
end

--- Creates a new, blank map.
-- @tparam string name The name of this map.
-- @tparam number? offsetX The offset in X axis.
-- @tparam number? offsetY The offset in Y axis.
-- @tparam number? offsetZ The offset in Z axis.
-- @treturn MapObject
function map.New(name, offsetX, offsetY, offsetZ)
  expect(1, name, "string", "nil")
  if name and #name > 256 then
    error("Name is too long! (Maximum 256 chars)", 2)
  end
  expect(2, offsetX, "number", "nil")
  expect(3, offsetY, "number", "nil")
  expect(4, offsetZ, "number", "nil")
  offsetX = offsetX or 0
  offsetY = offsetY or 0
  offsetZ = offsetZ or 0

  return setmetatable(
    {,m
      _ISMAP = true,
      Map = {},
      Offset = {offsetX, offsetY, offsetZ},
      GFavor = 1,
      HFavor = 1,
      OptimizeTurns = true,
      Name = name or "Untitled"
    },
    mapmt
  )
end

return map
