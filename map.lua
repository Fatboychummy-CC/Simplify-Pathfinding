--- This module handles all map operations, including altering the map (adding air, obstacles, unknowns, etc).
-- This module is not returned directly (or intended to be used directly) to the user.
-- Precreated map objects should be used from the pathfinder module.
-- @module map

local map = {}
local mapmt = {__index = {}}
local index = mapmt.__index

--- This function serializes the table depending on the given mode argument.
-- Default mode will serialize to pure bytes, for large maps which take up a lot of storage space.
-- Passing true as the mode argument will serialize using what is essentially a modified textutils.serialize, for human readability.
-- @tparam boolean? mode The mode to be used.
-- @treturn string
function index:Serialize(mode)

end

--- This function adds an obstacle to the map.
-- When pathfinding with obstacles, the pathfinder will completely avoid these.
-- @tparam number x The x position of the obstacle.
-- @tparam number y The y position of the obstacle.
-- @tparam number z The z position of the obstacle.
function index:AddObstacle(x, y, z)

end

--- This function adds an unknown to the map.
-- When pathfinding, the pathfinder will attempt to ignore these unless no other path is available.
-- In code, H-Cost will be increased by 30.
-- @tparam number x The x position of the unknown.
-- @tparam number y The y position of the unknown.
-- @tparam number z The z position of the unknown.
function index:AddUnknown(x, y, z)

end

--- This function adds an "air" to the map.
-- When pathfinding, "air" will be prioritized for the path.
-- @tparam number x The x position of the air.
-- @tparam number y The y position of the air.
-- @tparam number z The z position of the air.
function index:AddAir(x, y, z)

end

--- This function clones the map.
-- @treturn mapobject
function index:Clone()

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
  return setmetatable({}, mapmt)
end

return map
