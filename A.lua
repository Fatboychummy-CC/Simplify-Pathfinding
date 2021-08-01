---

-- This block should allow this api to work on all versions of minecraft, regardless of expect existing.
local ok, expect = pcall(require, "cc.expect")
if ok then
  expect = expect.expect
else
  expect = function(argn, arg, ...)
    local types = table.pack(...)
    local argtype = type(arg)
    for i = 1, types.n do
      if types[i] == argtype then
        return
      end
    end
    error(string.format("Bad argument #%d: Expected %s, got %s.", argn, table.concat(types, "/"), argtype), 3)
  end
end

local a = {}
local mt = {__index = {}}
local index = mt.__index

function index:Pathfind(x1, y1, z1, x2, y2, z2)

end

function index:SetMapSize(x, y, z)

end

function index:LoadMap(map)

end

function index:GetMap()

end

function index:AddObstacle(x, y, z)

end

function index:AddUnknown(x, y, z)

end

function index:AddAir(x, y, z)

end

function a.new(map)
  expect(1, map, "table", "nil")
end

return a
