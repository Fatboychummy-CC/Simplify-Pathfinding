# SimplifyPathfinding
SimplifyPathfinding is yet another installment in the Simplify series.

## What is it?
This API is a fully-working A* pathfinder built with turtles in mind. Less turning, more moving straight forwards. It features RLE-enhanced binary saves to allow for more map and less bulky data.

The pathfinder will also prioritized premapped areas, but will attempt to pathfind through "unknown" areas if no path could be found.

## How does it work?
Magic. Just kidding, have a read through the code. There's no documentation currently, but I plan on adding some (and a registry for this project and documentation to madefor.cc) soon.

## Usage
```lua
-- Soon
```

## Installation
```
wget run https://raw.githubusercontent.com/Fatboychummy-CC/SimplifyUpdate/master/Updater.lua https://raw.githubusercontent.com/Fatboychummy-CC/SimplifyPathfinding/master/Simplifile
```

### Limits
* Internal map is limited to range -128 to 127 (signed 1-byte integer).
  * Because of this, you should use offsets if you wish to directly plug in GPS coordinates.
  * This will be changed in a future update.
* There are currently no yield checks in the pathfinder, be careful with that!

## Screenshots
Adding these soon:tm:
