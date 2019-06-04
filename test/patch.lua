local jpatch = require "src/jsonpatch"
local json = require "json"

local obj = { test = { mypath = "", m = "0"} , arr = { sub = { 0, 1 ,2 ,3 }}}
local patch = {
    { op = "replace", path = "/test/mypath", value="aksdmakldsmaslkdtest"},
    { op = "replace", path = "/arr/sub/0", value=10},
    { op = "replace", path = "/arr/sub/1", value=20},
    --{ op = "add", path = "/arr/sub/-", value=100},
    { op = "remove", path = "/arr/sub/0", value=100},
    { op = "move", from = "/test/m", path="/arr"},
    { op = "cp", from = "/test/mypath", path="/arr"},
}

print(">>",json.encode(obj))
local err = jpatch.apply(obj,patch)
print(err)
print(">>",json.encode(obj))
