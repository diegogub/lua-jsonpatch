local json = require "json"
local obj = { a = { b = { c = { 1, 1}} } , b = { c = 2}}
local obj2 = {}

local val = 3
local arr = { "a", "b","c",-1 }



function replace(arr,obj,value)
    local key = ""
    for i,k in ipairs(arr) do
        key = k
        if type(key) == "number" then
            if key < 0 then
                key = #obj
                print(key)
            end
            print(key)

            local val = obj[key]
            print(obj[2])
            print(val)
            if type(val) == "table" then
                obj = val
            else
                if val == nil then
                    return "Error, key should exist"
                end
            end
        else
            local val = obj[key]
            if type(val) == "table" then
                obj = val
            else
                if val == nil then
                    return "Error, key should exist"
                end
            end
        end
    end
    obj[key] = value

    return nil
end
print(replace(arr,obj,2))

print(json.encode(obj))
