local _M = {}
local json = require "json"


-- actions
local ops = {
    replace = {
        op = "",
        path = "",
        value = ""

    },
    add = {
        op = "",
        path = "",
        value = ""
    },
    remove = {
        op = "",
        path = ""
    },
    copy = {
        op = "",
        from = "",
        path = "",

    },
    move = {
        op = "",
        from = "",
        path = ""
    },
    test = {
        op = "",
        path = "",
        value = ""
    }
}

-- decode_token , decodes json token
local decode_token = function(token)
    local t = ""
    t = string.gsub(token,"~0","~")
    t = string.gsub(t,"~1","/")
    if tonumber(t) ~= nil then
        return tonumber(t) + 1
    else
        -- -1 will indicate last index of array
        if t == "-" then
            return -1
        end
        return t
    end
end

local split_path = function(path)
    local t = {}
    for p in string.gmatch(path,"([^/]*)") do 
        if p ~= "" then
            table.insert(t,decode_token(p))
        end
    end
    return t
end

-- set_path, creates path and puts value on it
_M.set_path = function(obj,path,value)
    if type(obj) ~= "table" then
        return false,nil,"Has to be a object to set value"
    end
    local parts = split_path(path)
    for i,k in ipairs(parts) do
    end
end

-- check_path, return if exist and value of path, and error
_M.check_path = function(obj,path) 
    if type(obj) ~= "table" then
        return false,nil,"Has to be a object to check path"
    end

    local parts = split_path(path)
    local exist = false
    local value = nil

    if #parts == 0 then
        return true,obj,nil
    end

    local cur = obj
    for i,k in ipairs(parts) do
        if type(k) == "number" then
            if k == -1 then
                k = #cur
            end
        end

        local val = cur[k]
        if val == nil and i ~= #parts then
            return false,nil,"Path does not exist"
        else
            if val ~= nil and i == #parts then
                return  true,val,nil
            end

            -- continue
            if val ~= nil and i ~= #parts then
                if type(val) == "table" then
                    cur = val
                else
                    return false,nil,"Path does not exist"
                end
            end
        end
    end

    return false, nil, "Path does not exist.."
end

-- build_path , returns a clean patch from any object and error
local build_patch = function(obj,spec)
    local patch = {}
    for k,v in pairs(spec) do
        local value = obj[k]
        if value == nil then
            return {},"Missing key in patch:" .. k
        else
            patch[k] = value
        end
    end
    return patch, nil
end

-- shorter version of actions
local ops_short = {
    replace = "rp",
    add     = "a",
    remove  = "rm",
    copy    = "cp",
    move    = "mv",
    test    = "t"
}

-- check_op checks is operation exist, returns boolean and the operation spec
local check_op = function(op) 
    for k,spec in pairs(ops) do
        if k == op then
            return true,spec
        else
            if ops_short[k] == op then
                return true,spec
            end
        end
    end

    return false,{}
end

_M.verbose = false


-- validate, validates json patch and it's format, returning flag, clean patch and error
_M.validate = function (patch) 
    if type(patch) ~= "table" then
        return false,{},"Patch must be array of operations"
    end
    local purged_patch = {}

    for i,p in ipairs(patch) do
        if type(p) ~= "table" then
            return false,{},"Each operation should be a Array."
        end

        if _M.verbose then
            print("patch action:",json.encode(p))
        end

        local op = p.op
        if type(op) ~=  "string" then
            return false,{},"Invalid operation. ["..i.."]"
        else
            local ok, spec = check_op(op)
            if not ok then
                return false, {},"Invalid operation:" .. op
            else
                local new_patch ,err = build_patch(p,spec)
                if err then
                    return false,{},err
                end
                table.insert(purged_patch,new_patch)
            end
        end
    end

    return true, purged_patch,nil
end

-- iterates over object until path found, return: obj location,
local follow_path = function(arr,obj,exist)
    local key = ""
    for i,k in ipairs(arr) do
        print("----",k)
        key = k
        if type(key) == "number" then
            if key < 0 then
                key = #obj
            end

            local val = obj[key]
            if type(val) == "table" then
                obj = val
            else
                if val == nil then
                    if exist then
                        return obj,"","Error, key should exist"
                    else
                        return obj,key,nil
                    end
                end
            end
        else
            local val = obj[key]
            if type(val) == "table" then
                obj = val
            else
                if val == nil then
                    return obj,"","Error, key should exist"
                end
            end
        end
    end

    return obj,key,nil
end


local do_op = function (op,arr,obj,value,exist)
    local obj ,key, err = follow_path(arr,obj,exist)
    if err then
        return err
    end

    if op ==  "replace" then
        obj[key] = value
    end

    if op == "remove"  then
        if type(key) == "number" then
            table.remove(obj,key)
        else
            obj[key] = nil
        end
    end

    if op ==  "add" then
        if type(key) == "number" then
            if key == #obj then
                table.insert(obj,key+1,value)
            else
                if key == 1 then
                    table.insert(obj,key,value)
                else
                    table.insert(obj,key-1,value)
                end
            end
        else
            obj[key] = value
        end
    end


    return nil
end

local do_mv = function(obj,from,to,copy)
    local obj1 ,key1, err = follow_path(from,obj,false)
    if err then
        return err
    end

    local obj2 ,key2, err = follow_path(to,obj,false)
    if err then
        return err
    end

    if copy then
        obj2[key1] = obj1[key1]
    else
        obj2[key1] = obj1[key1]

        print(">>>>>>",json.encode(obj),json.encode(from))
        local err = do_op("remove",from,obj,"",true)
        if err  then
            return err
        end
    end
end

-- apply, applies a patch to a object, returning new object , patch, and error status
_M.apply = function(obj,patches) 
    if type(obj) ~= "table" then
        return "Patchs can only be applied to tables"
    end

    local obj_copy = obj
    local err = nil

    -- validates patch and clear it
    local ok, cpatches, err = _M.validate(patches)
    if not ok then
        return err
    end

    -- execute all patches
    for num_patch,patch in ipairs(patches) do
        if patch.op == "replace" or patch.op == "rp" then
            local err = do_op("replace",split_path(patch.path),obj_copy,patch.value,true)
            if err  then
                return err
            end
        end

        if patch.op == "add" or patch.op == "a" then
            local err = do_op("add",split_path(patch.path),obj_copy,patch.value,false)
            if err  then
                return err
            end
        end

        if patch.op == "remove" or patch.op == "rm" then
            local err = do_op("remove",split_path(patch.path),obj_copy,patch.value,true)
            if err  then
                return err
            end
        end

        if patch.op == "move" or patch.op == "mv" then
            local err = do_mv(obj_copy,split_path(patch.from),split_path(patch.path),false)
            if err  then
                return err
            end
        end

        if patch.op == "copy" or patch.op == "cp" then
            local err = do_mv(obj_copy,split_path(patch.from),split_path(patch.path),true)
            if err  then
                return err
            end
        end
    end


    return err
end

return _M
