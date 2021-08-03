--- This module handles all map operations, including altering the map (adding air, obstacles, unknowns, etc).
-- This module is not returned directly (or intended to be used directly) to the user.
-- Precreated map objects should be used from the pathfinder module.
-- @module map

local expect = require "cc.expect".expect
local abs = math.abs

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

  self.status.percent = 0
  self.status.state = "serialize"
  callback(self.status.state, self.status.percent, self.name)

  local max = self.loadedNodes

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
  Add(string.pack("<i3", self.offset[1])) -- offset y
  Add(string.pack("<i3", self.offset[1])) -- offset z

  for xIndex, YList in pairs(self.map) do
    for yIndex, ZList in pairs(YList) do
      self.status.percent = count / max
      callback(self.status.state, self.status.percent, self.name)

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
    Add(string.pack("<i1", run[1].x)) -- run x
    Add(string.pack("<i1", run[1].y)) -- run y
    Add(string.pack("<i1", run[1].z)) -- run z
    Add(string.pack("<i1", run[2].z)) -- run end z
    Add(string.pack("<i1", run[1].S)) -- run state
  end

  self.status.percent = 1
  self.status.state = "serialize-complete"
  callback(self.status.state, self.status.percent, self.name)

  return data
end

local directions = {
  { 1, 0, 0, "x" },
  {-1, 0, 0, "nx"},
  { 0, 1, 0, "y" },
  { 0,-1, 0, "ny"},
  { 0, 0, 1, "z" },
  { 0, 0,-1, "nz"}
}
function MapObject:GetNeighbors(x, y, z)
  CheckSelf(self)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, z, "number")

  local map = self.map

  local node = self:Get(x, y, z)
  node.neighbors = {}
  for i = 1, 6 do
    local _x, _y, _z, dirname = table.unpack(directions[i], 1, 4)
    _x = _x + x
    _y = _y + y
    _z = _z + z

    node.neighbors[dirname] = self:Get(_x, _y, _z) -- add neighbor to node
  end

  return node.neighbors
end

local function CreateNode(self, x, y, z, status)
  if not self.map[x] then
    self.map[x] = {}
  end
  if not self.map[x][y] then
    self.map[x][y] = {}
  end
  if not self.map[x][y][z] then
    self.map[x][y][z] = {
      x = x, y = y, z = z, -- Internal position for internal usage
      H = 0,  -- Distance to end node
      G = 0,  -- Distance to start node
      F = 0,  -- Combined values of H + G + P + TP
      S = status or 0   -- Node state -- 0 = unknown, 1 = blocked, 2 = air
    }
    self.loadedNodes = self.loadedNodes + 1
  end

  return self.map[x][y][z]
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

  -- ensure all numbers are in range
  local ns = {x, y, z}
  for i = 1, 3 do
    if not pcall(string.pack, "<i1", ns[i]) then
      error(string.format("Bad argument #%d: Expected number in signed 1-byte range.", i), 2)
    end
  end

  return CreateNode(self, x, y, z)
end

--- This function resizes the map object.
-- This function will delete all map data when called, be warned!
-- @tparam number minx The minimum x position.
-- @tparam number miny The minimum y position.
-- @tparam number minz The minimum z position.
-- @tparam number maxx The maximum x position.
-- @tparam number maxy The maximum y position.
-- @tparam number maxz The maximum z position.
-- @tparam number state the state of all nodes to be pregenned. Defaults to "unknown" state.
-- @tparam function callback The callback to be run while generating.
function MapObject:Pregen(minx, miny, minz, maxx, maxy, maxz, state, callback)
  CheckSelf(self)
  expect(1, minx, "number")
  expect(2, miny, "number")
  expect(3, minz, "number")
  expect(4, maxx, "number")
  expect(5, maxy, "number")
  expect(6, maxz, "number")
  expect(7, state, "number", "nil")
  expect(8, callback, "function", "nil")
  callback = callback or function() end
  state = state or 0

  -- ensure all numbers are in range
  local ns = {minx, miny, minz, maxx, maxy, maxz}
  for i = 1, 6 do
    if not pcall(string.pack, "<i1", ns[i]) then
      error(string.format("Bad argument #%d: Expected number in signed 1-byte range.", i), 2)
    end
  end

  self.status.state = "resize"
  self.status.percent = 0
  callback(self.status.state, self.status.percent, self.name)

  self.map = {}
  local map = self.map
  local max1 = maxx * maxy * maxz
  local max2 = minx * miny * minz
  local max = max2 > 0 or max1 < 0 and max1 - max2
           or max1 + abs(max2)
  local count = 0

  if max == 0 then
    self.map = {}
    self.status.percent = 1
    self.status.state = "resize-complete"
    callback(self.status.state, self.status.percent, self.name)
    return self
  end

  for x = minx, maxx do
    map[x] = {}
    local X = map[x]

    for y = miny, maxy do
      X[y] = {}
      local Y = X[y]
      self.status.percent = count / max
      callback(self.status.state, self.status.percent, self.name)

      for z = minz, maxz do
        yieldCheck()
        count = count + 1
        CreateNode(self, x, y, z, state)
      end
    end
  end

  self.status.percent = 1
  self.status.state = "resize-complete"
  callback(self.status.state, self.status.percent, self.name)

  return self
end
MapObject.REESize = MapObject.Resize

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

  -- ensure all numbers are in range
  local ns = {x, y, z}
  for i = 1, 3 do
    if not pcall(string.pack, "<i1", ns[i]) then
      error(string.format("Bad argument #%d: Expected number in signed 1-byte range.", i), 2)
    end
  end

  CreateNode(self, x, y, z, 1)

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

  -- ensure all numbers are in range
  local ns = {x, y, z}
  for i = 1, 3 do
    if not pcall(string.pack, "<i1", ns[i]) then
      error(string.format("Bad argument #%d: Expected number in signed 1-byte range.", i), 2)
    end
  end

  CreateNode(self, x, y, z, 0)

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

  -- ensure all numbers are in range
  local ns = {x, y, z}
  for i = 1, 3 do
    if not pcall(string.pack, "<i1", ns[i]) then
      error(string.format("Bad argument #%d: Expected number in signed 1-byte range.", i), 2)
    end
  end

  CreateNode(self, x, y, z, 2)

  return self
end


function MapObject:CalculateHCost(node, endNode)
  CheckSelf(self)
  expect(1, node   , "table")
  expect(2, endNode, "table")

  return abs(node.x - endNode.x)
         + abs(node.y - endNode.y)
         + abs(node.z - endNode.z)
end

function MapObject:CalculateGCost(node, startNode)
  CheckSelf(self)
  expect(1, node   , "table")
  expect(2, endNode, "table")

  return CalculateHCost(node, startNode)
end

function MapObject:CalculateFCost(node, startNode, endNode)
  CheckSelf(self)
  expect(1, node     , "table")
  expect(1, startNode, "table")
  expect(1, endNode  , "table")

  local totalCost = 0

  -- Calculate if this node is facing a different direction than the parent node
  if node.Parent then
    -- Find ourself in parent's neighbors
    for dir, _node in pairs(node.Parent.Neighbors) do
      -- first node's facing will be nil,
      -- thus incrementing cost of all first moves by 1.
      -- though this shouldn't have consequences.
      if _node == node and dir ~= node.Parent.Facing then
        totalCost = 1
        node.Facing = dir
      end
    end
  end


  totalCost = totalCost + self:CalculateHCost(node, endNode) -- add H cost
            + self:CalculateGCost(node, startNode) -- add G cost
            + node.P -- Add penalty for unknown node.
  --

  return totalCost
end

--- This function clones the map.
-- @treturn mapobject
function MapObject:Clone()
  CheckSelf(self)

end

--- This function loads a map from a file, it determines the mode required while loading.
-- @tparam string filename The name of the file to be loaded.
-- @treturn mapobject
function map.FromFile(filename)

end

--- This function clones a map
-- @tparam mapobject the map to be cloned.
-- @treturn mapobject
function map.Clone(othermap)

end

--- Creates a new, blank map.
-- @treturn mapobject
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
    {
      _ISMAP = true,
      map = {},
      loadedNodes = 0,
      status = {
        state = "new",
        percent = 0
      },
      offset = {offsetX, offsetY, offsetZ},
      name = name or "Untitled"
    },
    mapmt
  )
end

return map
