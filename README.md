lua-jsonpatch
=============

Supported Operations / TODO
---------------------------

- [x] replace / rp
- [x] add  / a 
- [x] remove / rm
- [x] move / mv
- [x] copy / cp
- [ ] test / t

Install
-------

```
    luarocks install lua-jsonpatch
```


Usage
-----

```
local jpatch = require "lua-jsonpatch"
local json = require "json"

local obj = { test = { mypath = "", m = "0"} , arr = { sub = { 0, 1 ,2 ,3 }}}
local patch = {
    { op = "replace", path = "/test/mypath", value="change it"},
    { op = "replace", path = "/arr/sub/0", value=10},
    { op = "rp", path = "/arr/sub/1", value=20},
    { op = "add", path = "/arr/sub/-", value=100},
    { op = "rm", path = "/arr/sub/0", value=100},
    { op = "move", from = "/test/m", path="/arr"},
    { op = "copy", from = "/test/mypath", path="/arr"},
}

local err = jpatch.apply(obj,patch)
if err then
    print(err)
end

-- possible to compress size of patches
local c_patch , err = jpatch.compress(patch)
if not err then
    print(json.encode(c_patch))
end

local d_patch , err = jpatch.decompress(c_patch)
if not err then
    print(json.encode(d_patch))
end
```
