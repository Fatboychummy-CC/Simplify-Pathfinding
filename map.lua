--- This module handles all map operations, including altering the map (adding air, obstacles, unknowns, etc).
-- This module is not returned directly (or intended to be used directly) to the user.
-- Precreated map objects should be used from the pathfinder module.
-- @module map

local expect = require "cc.expect".expect

local map = {}
local mapmt = {__index = {}}
local MapObject = mapmt.__index

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
function MapObject:Serialize(mode)
  CheckSelf(self)
  expect(1, mode, "boolean", "nil")

  if mode then
    -- @todo Make this much more efficient than it is currently.
    local str = "{\n"

    local function concat(s)
      str = str .. s .. "\n"
    end

    for x = 1, self.x do
      local X = self.map[x]
      concat("  [" .. tostring(x) .. "] = {")
      for y = 1, self.y do
        local Y = X[y]
        concat("    [" .. tostring(y) .. "] = {")
        for z = 1, self.z do
          local node = Y[z]
          concat("      [" .. tostring(z) .. "] = {")
          concat("        neighbors = {")
          for dir, neighbor in pairs(node.neighbors) do
            concat(string.format("          %s = '%d|%d|%d',", dir, neighbor.x, neighbor.y, neighbor.z))
          end
          concat("        },")
          for k, v in pairs(node) do
            if k == "B" then
              concat(string.format("        b = %s,", v and "true" or "false"))
            elseif k ~= "neighbors" then
              concat(string.format("        %s = %d,", k, v))
            end
          end
          concat("      },")
        end
        concat("    },")
      end
      concat("  },")
    end
    concat("}")

    return str
  end

  return "Not yet implemented." -- @todo this
end

local directions = {
  { 1, 0, 0, "x" },
  {-1, 0, 0, "nx"},
  { 0, 1, 0, "y" },
  { 0,-1, 0, "ny"},
  { 0, 0, 1, "z" },
  { 0, 0,-1, "nz"}
}
local function GetNeighborinos(map, x, y, z)
  map[x][y][z].neighbors = {}
  for i = 1, 6 do
    local _x, _y, _z, dirname = table.unpack(directions[i], 1, 4)
    _x = _x + x
    _y = _y + y
    _z = _z + z

    if _x > 0 and _y > 0 and _z > 0 -- if xyz is non-negative (in bounds)
    and map[_x] and map[_x][_y] and map[_x][_y][_z] then -- and node exists
      map[x][y][z].neighbors[dirname] = map[_x][_y][_z] -- add neighbor to node
    end
  end
end

--- This function will connect nodes to neighbors.
function MapObject:PopulateNodes()
  CheckSelf(self)

  for x = 1, self.x do
    local X = self.map[x]
    for y = 1, self.y do
      local Y = X[y]
      for z = 1, self.z do
        local Z = Y[z]
        GetNeighborinos(self.map, x, y, z)
      end
    end
  end

  return self
end

local function CreateNode(x, y, z)
  return {
    x = x, y = y, z = z, -- Internal position for internal usage
    H = 0,  -- Distance to end node
    G = 0,  -- Distance to start node
    P = 0,  -- Penalty (For use with "unknown" nodes)
    TP = 0, -- Turn Penalty (when a turn is required)
    F = 0,  -- Combined values of H + G + P + TP
    B = false -- Blocked -> Cannot pathfind through this node.
  }
end

--- This function resizes the map object.
-- This function is not safe when used to resize to a smaller map, data *will* be lost.
-- @tparam number x The x position of the obstacle.
-- @tparam number y The y position of the obstacle.
-- @tparam number z The z position of the obstacle.
function MapObject:Resize(x, y, z)
  CheckSelf(self)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, z, "number")

  local map = self.map

  for ix = 1, map.x do
    if x < ix then
      -- Outside of new bounds, delete the entire X row/column/whatever
      map[ix] = nil
    else
      map[ix] = map[ix] or {}
      local X = map[ix]

      for iy = 1, map.y do
        if y < iy then
          -- Outside of new bounds, delete the entire Y row/column/whatever
          X[iy] = nil
        else
          X[iy] = X[iy] or {}
          local Y = X[iy]

          for iz = 1, map.z do
            if z < iz then
              -- Outside of new bounds, delete the node.
              Y[iz] = nil
            else
              -- create new node at ix,iy,iz (or keep the old one)
              Y[iz] = Y[iz] or CreateNode()
            end
          end
        end
      end
    end
  end

  self.x = x
  self.y = y
  self.z = z

  return self:PopulateNodes()
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

  return self
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
function map.New()
  return setmetatable(
    {
      _ISMAP = true,
      map = {},
      x = 0,
      y = 0,
      z = 0
    },
    mapmt
  )
end

return map
