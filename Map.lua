--- 3D map of the environment.
-- This module is responsible for holding and manipulating a 3D map of the currently known environment.
-- WARNING: All map object methods do not check input types, as an optimization to make pathfinding faster.
-- @module Map

-- Get the prefix to be used for requiring submodules.
-- This allows this folder to be named anything.
local prefix = (...):match("(.+)%.") .. "."

-- Include CC modules
local expect = require "cc.expect".expect

-- Other needed modules
local Node = require(prefix .. "Node")

-- localized math functions
local min = math.min
local max = math.max

-- "Globals"
local VERSION = 1

local FLAGS = {
  NONE          = 0,
  MULTI_FILE    = 1,
  LAST_MAP      = 2,
  LARGE_MAP     = 4,
  HUGE_MAP      = 8,
  DETAILED_DATA = 16,
  SAVE_BLOCKED  = 32
}

local Map = {}

--- Create a new Map object.
-- @treturn Map The map object
function Map.create()
  -- @type Map
  return {
    nodes = {}
    --- Get a node.
    -- Get a node at position x, y, z. If the node does not exist, a new one will be created.
    -- @tparam self Map The map object to operate on.
    -- @tparam x The X coordinate.
    -- @tparam y The Y coordinate.
    -- @tparam z The Z coordinate.
    -- @treturn Node The node grabbed.
    -- @usage local node = Map:Get(x, y, z)
    Get = function(self, x, y, z)
      -- check if X axis exists
      if not self.nodes[x] then self.nodes[x] = {} end
      local X = self.nodes[x]

      -- check if Y axis exists
      if not X[y] then X[y] = {} end
      local Y = X[y]

      -- check if the node exists
      if not Y[z] then Y[z] = Node.create(x, y, z) end

      -- return the node
      return Y[z]
    end,

    --- Mark a node as an obstacle.
    -- Marks a node as an obstacle. ie: A block the pathfinder will not try to go through.
    -- @tparam self Map The map object to operate on.
    -- @tparam x The X coordinate.
    -- @tparam y The Y coordinate.
    -- @tparam z The Z coordinate.
    -- @usage Map:MarkBlocked(x, y, z)
    MarkBlocked = function(self, x, y, z)
      self:Get(x, y, z).blocked = true
    end,

    --- Mark a node as cleared.
    -- Marks a node as an cleared. ie: A block the pathfinder will try to go through.
    -- @tparam self Map The map object to operate on.
    -- @tparam x The X coordinate.
    -- @tparam y The Y coordinate.
    -- @tparam z The Z coordinate.
    -- @usage Map:MarkUnblocked(x, y, z)
    MarkUnblocked = function(self, x, y, z)
      self:Get(x, y, z).blocked = false
    end,

    xOffset = 0,
    yOffset = 0,
    zOffset = 0
  }
end

--- Load a map object from a file.
-- @tparam string filename The file to load from, in absolute form.
-- @treturn boolean,table Whether the file loading was successful, and the data as a map object.
function Map.load(filename)
  expect(1, filename, "string")
end

local function packUByte(n)
  return string.pack("<B", n)
end
local function unpackUByte(s)
  return string.unpack("<B", s)
end

local function proxyUByteValue(v)
  return setmetatable(
    {v, Set = function(self, v) self.v = v end, Get = function(self) return self.v end},
    {__tostring = function(self) return packUByte(self.v) end}
  )
end

--- Save a map object to a file.
-- @tparam string filename The file to save to, in absolute form.
-- @tparam table map The map object that was created via either create or load.
-- @tparam function multifileFunc If the map becomes too large, it may need to save to a disk drive. If this is the case, supply a function which will determine the next location to save to.
-- @treturn boolean Whether saving the file[s] was successful or not.
function Map.save(filename, map, multifileFunc)
  expect(1, filename, "string")
  expect(1, map, "table")

  -- writing table ie: all bytes to be written.
  local writing = {}

  local function insert(i, v)
    writing[i].n = writing[i].n + 1
    writing[i][writing[i].n] = v
  end

  local saveVersion = packUByte(VERSION)
  local baseFlags = proxyUByteValue(0)

  -- Preprocess the map. We need to know the following information:
  --   1. The largest value (positive or negative), so we can determine if we need to increase size of written numbers.
  --   2. How much of each type of node run there will be, so we can determine if we are saving blocked or unblocked nodes.
  --   3. How much space we are going to take up with this single map, so we can determine if we need to split (and how many files to split into).

  local minimum = 0
  local maximum = 0
  local totalBlockedNodeRuns = 0
  local totalUnblockedNodeRuns = 0
  local last = false
  local first = true
  for x, Y in pairs(map.nodes) do
    minimum = min(minimum, x)
    maximum = max(maximum, x)
    for y, Z in pairs(Y) do
      minimum = min(minimum, y)
      maximum = max(maximum, y)
      for z, node in pairs(Z) do
        minimum = min(minimum, z)
        maximum = max(maximum, z)
        -- if node type changed...
        if last ~= node.blocked then
          -- and this is not the first check
          if not first then
            -- increment the corresponding node run type.
            if last then
              totalBlockedNodeRuns = totalBlockedNodeRuns + 1
            else
              totalUnblockedNodeRuns = totalUnblockedNodeRuns + 1
            end
          end

          -- change the last node to the current node.
          last = node.blocked
        end

        -- note that the first node has been checked.
        first = false
      end
    end
  end

  -- determine the flags that we will be using.
  if totalBlockedNodeRuns < totalUnblockedNodeRuns then
    baseFlags:Set(baseFlags:Get() + FLAGS.SAVE_BLOCKED)
  end
  if minimum < -32768 then
    baseFlags:Set(baseFlags:Get() + FLAGS.HUGE_MAP)
  elseif maximum > 32767 then
    baseFlags:Set(baseFlags:Get() + FLAGS.HUGE_MAP)
  elseif minimum < -128 then
    baseFlags:Set(baseFlags:Get() + FLAGS.LARGE_MAP)
  elseif maximum > 127 then
    baseFlags:Set(baseFlags:Get() + FLAGS.LARGE_MAP)
  end
end

return Map
