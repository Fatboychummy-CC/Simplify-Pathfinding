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
local DEBUG = true

local FLAGS = {
  NONE          = 0,
  MULTI_FILE    = 1,
  LAST_MAP      = 2,
  LARGE_MAP     = 4,
  HUGE_MAP      = 8,
  DETAILED_DATA = 16,
  SAVE_BLOCKED  = 32
}

local function debug(w, ...)
  if DEBUG then
    if type(w) == "number" then
      print("[DEBUG]", ...)
      os.sleep(w)
    else
      print("[DEBUG]", w, ...)
    end
  end
end

local Map = {}

--- Create a new Map object.
-- @treturn Map The map object
function Map.create()
  -- @type Map
  return {
    nodes = {},
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
  if not n then error("bruh", 2) end
  return string.pack("<B", n)
end
local function unpackUByte(s)
  if not n then error("bruh", 2) end
  return string.unpack("<B", s)
end

local function proxyUByteValue(v)
  return setmetatable(
    {v, Set = function(self, v) self[1] = v end, Get = function(self) return self[1] end},
    {__tostring = function(self) return packUByte(self[1]) end}
  )
end

--- Save a map object to a file.
-- @tparam Map map The map object that was created via either create or load.
-- @tparam function fileFunc This should be an iterator function which returns the next filename in the series to save.
-- @usage Map.save(map, function() return "map.data" end)
-- @usage local i = 0 local files = {"file1", "file2", ...} Map.save(map, function() i = i + 1 return files[i] end)
-- @treturn boolean Whether saving the file[s] was successful or not.
function Map.save(map, fileFunc)
  expect(1, map, "table")
  expect(2, fileFunc, "function")

  debug(1, "Begin map saving.")

  -- writing table ie: all bytes to be written.
  local writing = {{}}

  local function insert(i, v)
    debug("Insertion:", i, v)
    writing[i].n = writing[i].n + 1
    writing[i][writing[i].n] = v
  end

  local saveVersion = packUByte(VERSION)
  debug("VERSION:", saveVersion)
  local baseFlags = proxyUByteValue(0)
  debug("Base flags:", tostring(baseFlags))

  -- Preprocess the map. We need to know the following information:
  --   1. The largest value (positive or negative), so we can determine if we need to increase size of written numbers.
  --   2. How much of each type of node run there will be, so we can determine if we are saving blocked or unblocked nodes.
  --   3. How much space we are going to take up with this single map, so we can determine if we need to split (and how many files to split into).

  local minimum = math.huge
  local maximum = -math.huge
  local blocked = 0
  local blockedRuns = {}
  local unblocked = 0
  local unblockedRuns = {}
  local minIndex = math.huge
  local startZ = 0
  local last = false
  local minZ, maxZ = math.huge, -math.huge

  -- calculate mins and maximums
  for x, Y in pairs(map.nodes) do
    debug("Start new X")
    minimum = min(minimum, x)
    maximum = max(maximum, x)
    for y, Z in pairs(Y) do
      debug("Start new Y")
      minimum = min(minimum, y)
      maximum = max(maximum, y)
      minZ, maxZ = math.huge, -math.huge
      for z, node in pairs(Z) do
        debug("Node:", x, y, z)
        minimum = min(minimum, z)
        maximum = max(maximum, z)
        minZ = min(minZ, z)
        maxZ = max(maxZ, z)
      end

      -- we should now have the minimum and maximum values along the Z axis stored in minZ, maxZ
      -- lets use these to combine runs.

      debug("Determined minimum and maximums:")
      debug("Minimum:", minimum)
      debug("Maximum:", maximum)
      debug("MinZ   :", minZ)
      debug("MaxZ   :", maxZ)
      debug(0.25, "========")

      -- in theory, the minimum value should always be a filled node.
      local last = Z[minZ].blocked
      startZ = minZ

      debug(0.25, "Start isBlocked?:", last)
      for z = minZ + 1, maxZ do
        local node = Z[z]
        if node then
          if node.blocked ~= last then
            if node.blocked then -- store a blocked run
              blocked = blocked + 1
              blockedRuns[blocked] = {x, y, startZ, z - 1}
              debug(0.05, "Run end.", "blocked", startZ, z - 1)
            else -- store an unblocked run
              unblocked = unblocked + 1
              unblockedRuns[unblocked] = {x, y, startZ, z - 1}
              debug(0.05, "Run end.", "unblocked", startZ, z - 1)
            end

            last = node.blocked
            startZ = z
          end
        else -- "empty" nodes are treated as blocked.
          if not last then
            unblocked = unblocked + 1
            unblockedRuns[unblocked] = {x, y, startZ, z - 1}
            debug(0.05, "Run end.", "unblocked", startZ, z - 1)

            last = false
            startZ = z
          end -- end if
        end -- end else
      end -- end for z

      -- we hit the end of the line, we should save a node run.
      if Z[maxZ].blocked then -- store a blocked run
        blocked = blocked + 1
        blockedRuns[blocked] = {x, y, startZ, maxZ}
        debug(0.05, "Run end.", "blocked", startZ, maxZ)
      else -- store an unblocked run
        unblocked = unblocked + 1
        unblockedRuns[unblocked] = {x, y, startZ, maxZ}
        debug(0.05, "Run end.", "unblocked", startZ, maxZ)
      end
    end -- end for y
  end -- end for x

  -- determine the flags that we will be using.
  local intSize = 1
  debug("Total blocked  :", blocked)
  debug("Total unblocked:", unblocked)
  debug(5, "================")
  if blocked < unblocked then
    baseFlags:Set(baseFlags:Get() + FLAGS.SAVE_BLOCKED)
  end
  if minimum < -32768 then
    intSize = 3
    baseFlags:Set(baseFlags:Get() + FLAGS.HUGE_MAP)
  elseif maximum > 32767 then
    intSize = 3
    baseFlags:Set(baseFlags:Get() + FLAGS.HUGE_MAP)
  elseif minimum < -128 then
    intSize = 2
    baseFlags:Set(baseFlags:Get() + FLAGS.LARGE_MAP)
  elseif maximum > 127 then
    intSize = 2
    baseFlags:Set(baseFlags:Get() + FLAGS.LARGE_MAP)
  end

  if DEBUG then
    baseFlagss:Set(baseFlags:Get() + FLAGS.DETAILED_DATA)
  end

  debug("New flags:", baseFlags, "(", baseFlags:Get(), ")")

  -- Write the information we are choosing to save to a file.
  local packer = ("<I%d"):format(intSize)
  local function packInt(n)
    return string.pack(packer, n)
  end

  local function packData(filenumber, list, size, isBlocked)
    isBlocked = isBlocked and packInt(1) or packInt(0)
    -- Insert header things
    insert(filenumber, baseFlags)
    insert(filenumber, saveVersion)
    insert(filenumber, packInt(0))
    insert(filenumber, packInt(0))
    insert(filenumber, packint(0))

    -- for each run
    for i = 1, size do
      local run = list[i]

      -- and for each value within the run
      for j = 1, 4 do
        insert(filenumber, run[j])
      end

      -- insert whether the run is blocked or naw
      insert(filenumber, isBlocked)
    end
  end

  -- we'll just dump everything into one file for now.
  -- TODO: Make this dump to multiple files.
  if blocked < unblocked then
    packData(1, blockedRuns, blocked)
  else
    packData(1, unblockedRuns, unblocked)
  end

  local filesNeeded = 1 -- hardcoded for now.

  for i = 1, filesNeeded do
    -- get the next filename
    local filename = fileFunc()

    -- ensure we actually got one
    if not filename then
      error("Ran out of filenames while trying to save.", 2)
    end

    -- open the file
    local h, err = io.open(filename, 'wb')

    -- ensure it actually opened.
    if not h then
      error("Failed to open file " .. tostring(filename) .. " for writing: " .. err, 2)
    end

    -- write data yeet yeet.
    local toWrite = writing[i]
    for j = 1, toWrite.n do
      h:write(toWrite[j])
    end
    h:close()
  end
end

return Map
