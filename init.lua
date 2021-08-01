--- This module can be used to pathfind.
-- @module A*
-- @alias a

local ok, expect = pcall(require, "cc.expect")
if ok then
  expect = expect.expect
else
  error("This module will only work on CC:Tweaked for minecraft 1.12.2+")
end

local map = require("map")

local a = {}
local mt = {__index = {}}
local index = mt.__index

---
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

function a.New()
end

return a
