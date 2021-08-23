local expect = require "cc.expect".expect

local extras = {Scanners = {}}
local mt = {}
local index = mt.__index

local function CheckSelf(self)
  if type(self) ~= "table" or not self._ISMAPEXTRA then
    error("Expected ':' when calling method on MapExtra.", 3)
  end
end

local endTime = os.epoch("utc") + 3000
local function yieldCheck()
  if endTime < os.epoch("utc") then
    endTime = os.epoch("utc") + 3000
    os.queueEvent("p_d_e_me")
    os.pullEvent("p_d_e_me")
  end
end

function extras.Scanners.geoScanner(periphName, map, range, offsetx, offsety, offsetz)
  -- Scan the area.
  local scan, err = peripheral.call(periphName, "scan", range)

  if scan then
    -- Initialize every block in range as air.
    for x = -range, range do
      for y = -range, range do
        yieldCheck()
        for z = -range, range do
          map:AddAir(x + offsetx, y + offsety, z + offsetz)
        end
      end
    end

    -- For each block in the scan range, add it as an obstacle.
    for i, block in ipairs(scan) do
      map:AddObstacle(block.x + offsetx, block.y + offsety, block.z + offsetz)
    end
  end

  return scan, err
end


--- Depending on the mod of the scanner, will scan blocks around the scanner and add them to the map.
function index:ScanUsing(object, range, offsetx, offsety, offsetz)
  CheckSelf(self)
  expect(1, object, "table", "string")
  expect(2, range, "number")
  expect(3, offsetx, "number", "nil")
  expect(4, offsety, "number", "nil")
  expect(5, offsetz, "number", "nil")
  offsetx = offsetx or 0
  offsety = offsety or 0
  offsetz = offsetz or 0

  if type(object) == "table" then
    object = peripheral.getName(object)
  end

  if extras.Scanners[peripheral.getType(object)] then
    return extras.Scanners[peripheral.getType(object)]
           (object, self.Map, range, offsetx, offsety, offsetz)
  else
    error(string.format("Unsupported scanner: %s", peripheral.getType(object)), 2)
  end
end

-- Selects a scanner that is available, depending on what is attached, and scans using :ScanUsing
function index:Scan(range, offsetx, offsety, offsetz)
  CheckSelf(self)
  expect(1, range, "number")
  expect(2, offsetx, "number", "nil")
  expect(3, offsety, "number", "nil")
  expect(4, offsetz, "number", "nil")

  for periphType in pairs(validScanners) do
    local p = peripheral.find(periphType)
    if p then
      return self:ScanUsing(peripheral.getName(p), offsetx, offsety, offsetz)
    end
  end

  error("No valid scanners connected!")
end

function extras.New(map)
  return setmetatable(
    {
      Map = map
      _ISMAPEXTRA = true
    },
    mt
  )
end
