local expect = require "cc.expect".expect

local extras = {Scanners = {}}
local mt = {__index = {}}
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

  local ok = (not scan) and true or false
  local value = err and err or scan

  return ok, value
end


--- Scans data into the map using given scanner.
-- @tparam table|string object The peripheral (name or object) to scan with.
-- @tparam number range The range of the scanner.
-- @tparam number? offsetx The offset of the scanner from the map's 0,0,0 position on the X axis.
-- @tparam number? offsety The offset of the scanner from the map's 0,0,0 position on the Y axis.
-- @tparam number? offsetz The offset of the scanner from the map's 0,0,0 position on the Z axis.
-- @treturn boolean,table|string Regardless of the type of scanner used, this method normalizes the output to [true/false, {scandata}|"string error"].
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

  local t = peripheral.getType(object)
  if extras.Scanners[t] then
    return extras.Scanners[t](object, self.Map, range, offsetx, offsety, offsetz)
  else
    error(string.format("Unsupported scanner: %s", peripheral.getType(object)), 2)
  end
end

-- Selects a scanner that is available, depending on what is attached, and scans using :ScanUsing
-- @tparam number? range The range wanted. Will default to 8.
-- @tparam number? offsetx The offset of the scanner from the map's 0,0,0 position on the X axis.
-- @tparam number? offsety The offset of the scanner from the map's 0,0,0 position on the Y axis.
-- @tparam number? offsetz The offset of the scanner from the map's 0,0,0 position on the Z axis.
-- @treturn boolean,table|string Regardless of the type of scanner used, this method normalizes the output to [true/false, {scandata}|"string error"].
function index:Scan(range, offsetx, offsety, offsetz)
  CheckSelf(self)
  expect(1, range, "number")
  expect(2, offsetx, "number", "nil")
  expect(3, offsety, "number", "nil")
  expect(4, offsetz, "number", "nil")
  range = range or 8

  for periphType in pairs(extras.Scanners) do
    local p = peripheral.find(periphType)
    if p then
      return self:ScanUsing(peripheral.getName(p), range, offsetx, offsety, offsetz)
    end
  end

  error("No valid scanners connected!")
end

function extras.New(map)
  return setmetatable(
    {
      Map = map,
      _ISMAPEXTRA = true
    },
    mt
  )
end

return extras
