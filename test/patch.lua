local jpatch = require "src/jsonpatch"
local json = require "json"

local obj = { test = { mypath = "", m = "0"} , arr = { sub = { 0, 1 ,2 ,3 }}}
local patch = {
    { op = "replace", path = "/test/mypath", value="aksdmakldsmaslkdtest"},
    { op = "replace", path = "/test/mypath", value=42},
    { op = "replace", path = "/test/mypath", value= {}},
    { op = "replace", path = "/arr/sub/0", value=10},
    { op = "replace", path = "/arr/sub/1", value=20},
    { op = "add", path = "/b", value= { a = 2 }},
    { op = "remove", path = "/arr/sub/0", value=100},
    { op = "move", from = "/test/m", path="/arr"},
    { op = "cp", from = "/test/mypath", path="/arr"},
}

print(">>",json.encode(obj))
local err = jpatch.apply(obj,patch)
print(err)
print(">>",json.encode(obj))

local c_patch , err = jpatch.compress(patch)
if not err then
    print(json.encode(c_patch))
end

local d_patch , err = jpatch.decompress(c_patch)
if not err then
    print(json.encode(d_patch))
end

print(jpatch.validate(d_patch))

local filters = {}
local fil, err = jpatch.Filter:new("/test/mypath",{"rp","a"},{"string","table"})
print("...",json.encode(fil))
if not err  then
    table.insert(filters,fil)
end

-- filter patches
local patches, errors = jpatch.filter(filters,patch)
print("...",json.encode(filters))
print("...Filtered num",#patches)
print("...Filtered num",#patch)
print("...",json.encode(errors))



