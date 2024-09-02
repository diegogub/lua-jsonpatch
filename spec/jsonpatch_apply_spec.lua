local json = require "src/json"
local jpatch = require "src/jsonpatch"
local lfs = require "lfs"

local function read_json_file(file_path)
  local file = assert(io.open(file_path, "r"))
  local content = file:read("*all")
  file:close()
  return json.decode(content)
end

local function test_directory(path)
  for file in lfs.dir(path) do
    if file:match("%.json$") then
      local full_path = path .. "/" .. file
      local test_cases = read_json_file(full_path)

      describe("Testing JSON Patch cases from " .. file, function()
        for _, test_case in ipairs(test_cases) do
          it(test_case.comment or "Unnamed test case", function()
            local obj = test_case.doc
            local err = jpatch.apply(obj, test_case.patch)
            
            if test_case.error then
              assert.is_not_nil(err, "Expected an error but none occurred")
              assert.equals(test_case.error, err, "Error message mismatch")
            else
              assert.is_nil(err, "Unexpected error occurred: " .. (err or "nil"))
              assert.same(test_case.expected, obj)
            end
          end)
        end
      end)
    end
  end
end

test_directory("testdata/apply")
