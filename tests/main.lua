package.path = package.path .. ";/?/init.lua;/?.lua"

_G.cctest = require "Framework"

require "TestInit"
require "TestMap"
require "TestNode"
require "TestPath"
require "TestTrackingTurtle"

cctest.runAllTests(...)
