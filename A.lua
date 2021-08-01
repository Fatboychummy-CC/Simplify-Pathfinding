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

function a.new(map)
  expect(1, map, "table", "nil")
end

return a
