--- This module can be used to pathfind.
-- @module A*
-- @alias a

local prefix, pathToSelf = ...

-- Alter the package path so all submodules can require as needed.
local dir = "/" .. fs.getDir(pathToSelf)
local addon = string.format(";/%s/?.lua;/%s/?/init.lua", dir, dir)
if not string.find(package.path, addon, nil, 1) then
  package.path = package.path .. addon
end

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

local function CheckSelf(self)
  if type(self) ~= "table" or not self._ISPATHFINDER then
    error("Expected ':' when calling method on PathfinderObject.", 3)
  end
end
---
function index:Pathfind(x1, y1, z1, x2, y2, z2)

end

function index:SetMapSize(x, y, z)

end

--- Loads a map from a file.
-- @tparam string filename the absolute path to the file.
-- @tparam function? callback The callback to be used for loading.
function index:LoadMap(filename, callback)
  CheckSelf(self)
  expect(1, filename, "string")
  expect(2, callback, "function", "nil")

  if not fs.exists(filename) then
    error("That file does not exist.", 2)
  end

  self.map = map.FromFile(filename, callback)

  return self
end

function index:GetMap()
  return self.map
end

function index:AddObstacle(x, y, z)

end

function index:AddUnknown(x, y, z)

end


function index:AddAir(x, y, z)

end

function a.New()
  return setmetatable(
    {
      map = map.New(),
      _ISPATHFINDER = true
    },
    mt
  )
end

return a
