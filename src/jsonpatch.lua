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

-- shorter version of actions
local ops_short = {
    replace = "rp",
    add     = "a",
    remove  = "rm",
    copy    = "cp",
    move    = "mv",
    test    = "t"
}

local ops_long = {
    rp = "replace",
    a = "add",
    rm = "remove",
    cp = "copy",
    mv = "move",
    t = "test"
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


local make_short_op = function(op) 
    local so = ops_short[op] 
    if so == nil then
        local exist = ops_long[op]
        if exist then
            return op,nil
        else
            return op,"Invalid op:" .. op
        end
    else
        return so,nil
    end
end

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
                    if exist then
                        return obj,"","Error, key should exist"
                    else
                        return obj,key,nil
                    end
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

        local err = do_op("remove",from,obj,"",true)
        if err  then
            return err
        end
    end
end

-- apply, applies a patch to a object, returning error status
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

_M.compress = function(patches)
    local compress_patches = {}
    for i,p in ipairs(patches) do
        local ok, clean_patch, err = _M.validate(p)
        if not ok then
            return {},"Invalid patch:" .. err
        end

        local short_op = make_short_op(p.op)
        local compressed = false

        if short_op == "rp" or short_op == "a" or short_op == "t" then
            local patch = {short_op,p.path,p.value}
            table.insert(compress_patches,patch)
            compressed = true
        end

        if short_op == "rm" then
            local patch = {short_op,p.path}
            table.insert(compress_patches,patch)
            compressed = true
        end

        if short_op == "cp"  or short_op == "mv" then
            local patch = {short_op,p.from,p.path}
            table.insert(compress_patches,patch)
            compressed = true
        end

        if not compressed then
            return {}, "failed to compress patchs, op not supported"
        end
    end

    return compress_patches,nil
end

_M.decompress = function(patches) 
    local d_patches = {}
    for i,p in ipairs(patches) do
        local patch = {}
        local op = p[1]
        local  decompressed = false
        if op == "rp" or op == "a" or op == "t" then
            patch["op"] = op
            patch["path"] = p[2]
            patch["value"] = p[3]
            table.insert(d_patches,patch)
            decompressed = true
        end

        if op == "rm" then
            patch["op"] = op
            patch["path"] = p[2]
            table.insert(d_patches,patch)
            decompressed = true
            decompressed = true
        end

        if op == "cp" or op == "mv" then
            patch["op"] = op
            patch["from"] = p[2]
            patch["path"] = p[3]
            table.insert(d_patches,patch)
            decompressed = true
        end

        if not decompressed then
            return {},"Failed to decompress patches"
        end
    end

    return d_patches,nil
end

-- filter to apply
local Filter = {
    -- path to filter
    path = "",
    -- operations
    ops = {},
    -- validation types or functions: type, val(value) -> err
    v = {},
}

function Filter:new(path,ops,validators) 
    local self = {}
    setmetatable(self, { __index = Filter })
    self.path = path
    self.v = {}

    for i,k in ipairs(ops) do
        local ok, err = check_op(k)
        if not ok then
            return nil, "invalid op to create filter"
        end
    end
    self.ops = ops

    for i,v in ipairs(validators) do
        if type(v) == "string" or type(v) == "function" then
            table.insert(self.v,v)
        else
            return nil, "Invalid validation rule"
        end
    end

    return self, nil
end

function Filter:validate(patch)
    local patch_op, _ = make_short_op(patch.op)
    local match_op = false
    local match_path = false
    local valid = false
    local errors = {}

    for i,v in ipairs(self.v) do
        if type(v) == "string" then
            if type(patch.value) == v then
                valid = true
                break
            else
                table.insert(errors,"Invalid type:" .. type(patch.value).." for path ".. patch.path)
            end
        else
            local err = v(patch.value)
            if err == nil then
                valid = true
                break
            else
                print("inserted",#errors)
                table.insert(errors,err)
            end
        end
    end

    if valid then
        return true,errors
    else
        return false,errors
    end
end


-- filter , filters group of patches.
_M.filter = function(filters,patches)
    local filtered = {}
    local errors = {}
    for i,p in ipairs(patches) do
        local valid = true
        for j,f in ipairs(filters) do
            if f.path == p.path then
                for k,o in ipairs(f.ops) do
                    local patch_op , _ = make_short_op(p.op)
                    local fil_op , _= make_short_op(o)
                    print(fil_op,">>",patch_op)
                    if patch_op == fil_op then
                        local ok ,errs = f:validate(p)
                        if ok then
                            valid = false
                        end
                        for i,e in ipairs(errs) do
                            table.insert(errors,e)
                        end
                    end
                end

            end


        end
        if valid then
            print(">>",valid)
            table.insert(filtered,p)
        end
    end

    return filtered, errors
end

_M.Filter = Filter

return _M
