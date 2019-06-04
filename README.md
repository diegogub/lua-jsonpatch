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


Usage
-----

```
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



```
