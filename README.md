# SimplifyPathfinding
SimplifyPathfinding is yet another installment in the Simplify series.

## What is it?
This API is a fully-working A* pathfinder built with turtles in mind. Less turning, more moving straight forwards. It features RLE-enhanced binary saves to allow for more map and less bulky data.

The pathfinder will also prioritized premapped areas, but will attempt to pathfind through "unknown" areas if no path could be found.

## How does it work?
Magic. Just kidding, have a read through the code. There's no documentation currently, but I plan on adding some (and a registry for this project and documentation to madefor.cc) soon.

## Usage
```lua
local P = require "SimplifyPathfinding"
local pathfinder = P.New("mapname", 528, 32, 68) -- Assuming your device is at 528, 32, 68

pathfinder:AddAir(x, y, z) -- adds an air block (traversable block) at the position
pathfinder:AddObstacle(x, y, z) -- adds an obstacle (non-traversable block) at the position
pathfinder:AddUnknown(x, y, z) -- adds an unknown (possibly-traversable block) at the position
pathfinder:LoadMap(filename) -- Loads a map from a file.
pathfinder:GetMap() -- returns the Map object, but operations on the map object are not needed unless you're doing something weird.
pathfinder:SetMapOffset(x, y, z) -- sets the map's offset, useful for working with GPS, since the internal storage only allows values from -128 to 127.
pathfinderScanIntoMapUsing(object, range, offsetx, offsety, offsetz, callback) -- uses object to scan the area and loads all the data into the map.
  -- Currently supports following peripherals:
    -- geoScanner (Advanced Peripherals)
  -- Planned support for following peripherals:
    -- Block Scaner (Plethora)


local path = pathfinder:Pathfind(
  x, y, z,    -- The first position to pathfind from.
  x2, y2, z2, -- The second position to pathfind to.
  0,          -- The starting facing of the pathfinder. 0 = +z, 1 = -x, 2 = -z, 3 = +x
  500,        -- The maximum "budget" of the pathfinder.
              -- If the pathfinder exceeds this many iterations while searching for a path,
              -- the operation will fail.
  false       -- Debug mode. If run on a command computer and this is true,
              -- the computer will spawn blocks to visualize the pathfinding.
)
```

## Installation
```
wget run https://raw.githubusercontent.com/Fatboychummy-CC/SimplifyUpdate/master/Updater.lua https://raw.githubusercontent.com/Fatboychummy-CC/SimplifyPathfinding/master/Simplifile /SimplifyPathfinding
```

### Limits
* Internal map is limited to range -128 to 127 (signed 1-byte integer)
  * Because of this, you should use offsets if you wish to directly plug in GPS coordinates.
* There are currently no yield checks in the pathfinder, be careful with that!

## Screenshots
Adding these soon:tm:
