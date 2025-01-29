-- Define the WebSocket dissector
ocpp_proto = Proto("ocpp2.0.1", "Open Charge Point Protocol v2.0.1 Dissector")

-- Define fields for the protocol
local f_message_type = ProtoField.uint8("ocpp2.0.1.message_type", "Message Type", base.DEC)
local f_message_id = ProtoField.string("ocpp2.0.1.message_id", "Message ID")
local f_message_name = ProtoField.string("ocpp2.0.1.message_name", "Message Name")
local f_payload = ProtoField.string("ocpp2.0.1.payload", "Payload (JSON)")
local f_valid = ProtoField.bool("ocpp2.0.1.valid", "Valid?", base.NONE)
local f_ipv6 = ProtoField.bool("ocpp2.0.1.ipv6", "IPv6?", base.NONE)

ocpp_proto.fields = {f_message_type, f_message_id, f_message_name, f_payload, f_valid, f_ipv6}

local cjson = require("cjson")
local jsonschema = require("jsonschema")

local function remove_bom(content)
    local bom = "\239\187\191" -- EF BB BF in decimal
    if content:sub(1, 3) == bom then
        return content:sub(4) -- Remove the first three bytes
    end
    return content
end

local function remove_id_property(schema)
    if type(schema) == "table" then
        schema["$id"] = nil -- Remove the $id key
        for key, value in pairs(schema) do
            remove_id_property(value) -- Recursively remove $id in nested objects
        end
    end
end


-- Table to store loaded schemas
local schemas201 = {}

-- Helper to load schemas at startup
local function load_schemas(schema_dir)
    local files = io.popen('ls ' .. schema_dir):lines() -- List files in schema_dir
    for file in files do
        local schema_path = schema_dir .. "/" .. file
        local schema_file = io.open(schema_path, "r") -- Open the schema file
        if schema_file then
            local schema_content = schema_file:read("*all") -- Read schema content
            schema_content = remove_bom(schema_content)
            schema_file:close()
            local success, schema = pcall(cjson.decode, schema_content)
            if success then
                local success_validator, compiled_schema = pcall(jsonschema.generate_validator, schema)
                if success_validator then
                    -- Store the compiled schema
                    local schema_name = file:gsub("%.json$", ""):gsub("_v%d+p%d+$", "")
                    my_validator = jsonschema.generate_validator(schema)
                    schemas201[schema_name] = my_validator
                else
                    -- Retry after removing $id
                    print("Failed to compile schema for file: " .. file .. ". Retrying without $id...")
                    remove_id_property(schema)
                    success_validator, compiled_schema = pcall(jsonschema.generate_validator, schema)
                    if success_validator then
                        local schema_name = file:gsub("%.json$", ""):gsub("_v%d+p%d+$", "")
                        my_validator = jsonschema.generate_validator(schema)
                        schemas201[schema_name] = my_validator
                    else
                        print("Error compiling schema for file after removing $id: " .. file .. ": " .. compiled_schema)
                    end
                end
            else
                print("Error decoding schema for file: " .. file .. ": " .. schema)
            end
        else
            print("Error opening schema file: " .. schema_path)
        end
    end
end

function printTable(tbl, indent)
    indent = indent or 0
    local padding = string.rep("  ", indent)

    for key, value in pairs(tbl) do
        if type(value) == "table" then
            print(padding .. tostring(key) .. " => {")
            printTable(value, indent + 1)
            print(padding .. "}")
        else
            print(padding .. tostring(key) .. " => " .. tostring(value))
        end
    end
end

-- Call this function once during initialization
print('************************2.0.1************************')
load_schemas(os.getenv("HOME") .. "/Desktop/ocpp-simulator/venv/lib/python3.12/site-packages/ocpp/v201/schemas")
printTable(schemas201)
print('\n')


-- Function to validate JSON against a schema
local function validate_json(payload, schema_name)
    local function validate_schema(schema_group, schema_name_key)
        local schema = schema_group[schema_name_key]
        if not schema then
            return false, "Schema not found for: " .. tostring(schema_name_key)
        end
        
        -- Safely execute schema validation
        local success, err = schema(payload)
        if not success then
            return false, "Error during schema validation: " .. tostring(err)
        end
        return success, nil
    end

    local success201, err201

    -- Handle schema201 validation
    local status201, result201 = pcall(function()
        success201, err201 = validate_schema(schemas201, schema_name)
    end)
    if not status201 then
        print("Error in V201 validation: ", result201)
    end

    -- Decision logic remains the same
    if success201 then
        return success201, err201, '2.0.1'
    else
        return false, tostring(err201), 'None'
    end
end


function jsonToLua(jsonStr)
    -- Decode the JSON string into a Lua table
    local success, result = pcall(cjson.decode, jsonStr)
    if not success then
        error("Invalid JSON format: " .. tostring(result))
    end

    return result
end

function printLuaTable(tbl, indent)
    indent = indent or 0 -- Track the indentation level
    local padding = string.rep("  ", indent) -- Indent with spaces
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            -- Print the key and recurse into the nested table
            print(padding .. tostring(key) .. " => {")
            printLuaTable(value, indent + 1)
            print(padding .. "}")
        else
            -- Print the key-value pair
            print(padding .. tostring(key) .. " => " .. tostring(value))
        end
    end
end

function parseJSONArray(jsonStr)
    local parts = {}
    local in_quotes = false
    local escape = false
    local buffer = ""
    local bracket_count = 0

    for i = 2, #jsonStr - 1 do -- Ignore the outer square brackets
        local char = jsonStr:sub(i, i)

        if char == '"' and not escape then
            in_quotes = not in_quotes
        elseif char == "\\" and in_quotes then
            escape = not escape
        elseif char == "{" or char == "[" then
            if not in_quotes then
                bracket_count = bracket_count + 1
            end
        elseif char == "}" or char == "]" then
            if not in_quotes then
                bracket_count = bracket_count - 1
            end
        elseif char == "," and not in_quotes and bracket_count == 0 then
            -- Push completed element to parts
            parts[#parts + 1] = buffer:match("^%s*(.-)%s*$") -- Trim whitespace
            buffer = ""
        else
            escape = false
        end

        buffer = buffer .. char
    end

    -- Add the last element
    parts[#parts + 1] = buffer:match("^%s*(.-)%s*$") -- Trim whitespace
    return parts
end


local function cleanElement(str)
    return str:match("^%s*,?%s*(.-)%s*$") -- Remove leading comma and spaces
end

-- Dissector function
function ocpp_proto.dissector(buffer, pinfo, tree)
    local length = buffer:len()
    local ipv6 = false
    if length == 0 then return end

    print('New Packet!!!')
    print('\n')

    print(pinfo.src)
    if tostring(pinfo.src):match("^(%d+%.%d+%.%d+%.%d+)$") then
        ipv6 = false
    elseif tostring(pinfo.src):match("^([a-fA-F0-9:]+)$") then
        ipv6 = true
    end

    -- Convert buffer to a string
    local payload = buffer():string()

    -- Extract elements from the JSON array
    local elements = parseJSONArray(payload)

    -- Extract individual elements
    local message_type = tonumber(elements[1])
    print(string.format("Type: %s", tostring(message_type)))
    local message_id = cleanElement(elements[2]:gsub('^["\'](.-)["\']$', '%1'))
    print(string.format("ID: %s", tostring(message_id)))
    if not(message_type == 3) then
        message_name = cleanElement(elements[3]:gsub('^["\'](.-)["\']$', '%1'))
        print(string.format("Name: %s", tostring(message_name)))
        json_data_str = cleanElement(elements[4]) -- The JSON object string
    else
        json_data_str = cleanElement(elements[3]) -- The JSON object string
    end

    print(string.format("Data: %s", tostring(json_data_str)))
    print('\n')

    -- Parse and display JSON if possible
    local json_data = jsonToLua(json_data_str)
    print('LUA Table:')
    printLuaTable(json_data)
    print('\n\n')

    local full_message_name = "" -- Variable to hold the result

    if message_type == 2 then
        full_message_name = message_name:gsub('["]', '') .. "Request"
    elseif message_type == 3 then
        full_message_name = message_name:gsub('["]', '') .. "Response"
    end

    local is_valid, validation_error, version = validate_json(json_data, full_message_name)
    print(string.format("VALID?: %s", tostring(is_valid)))
    print(string.format("ERROR?: %s", tostring(validation_error)))
    print(string.format("VERSION?: %s", tostring(version)))
    print('\n')

    if is_valid then
        
        
        if version == 'All' then
            pinfo.cols.protocol = "OCPP"
        else
            pinfo.cols.protocol = "OCPP " .. version
        end

        -- Create the protocol tree
        local subtree = tree:add(ocpp_proto, buffer(), "OCPP Protocol Payload")

        
        -- Add elements to the tree
        subtree:add(f_valid, is_valid):set_hidden(true)
        subtree:add(f_ipv6, ipv6):set_hidden(true)
        subtree:add(f_message_type, buffer(1, 1), message_type):append_text(" (2=Request, 3=Response, 4=Error)")
        subtree:add(f_message_id, buffer(3, #message_id), message_id)
        if not(message_type == 3) then 
            subtree:add(f_message_name, buffer(#message_id + 4, #message_name), message_name)
        end

        

        if json_data then
            if not(message_type == 3) then 
                payload_tree = subtree:add(f_payload, buffer(3 + #message_id + #message_name +2, buffer:len()-(3 + #message_id + #message_name +2)-1), "Payload")
            else
                payload_tree = subtree:add(f_payload, buffer(3 + #message_id + 1, buffer:len()-(3 + #message_id)-2), "Payload")
            end

            -- Recursive function to add key-value pairs
            local function add_key_value_pairs(tree, data, prefix)
                for key, value in pairs(data) do
                    -- Ensure the key ends with ":"
                    local formatted_key = tostring(key):find(":$") and tostring(key) or (tostring(key) .. ":")
                    if type(value) == "table" then
                        -- If the value is a dictionary, create a new subtree and recurse
                        local nested_tree = tree:add(formatted_key, "Nested Data")
                        add_key_value_pairs(nested_tree, value, prefix .. "  ")
                    else
                        -- Otherwise, add the key-value pair
                        tree:add(formatted_key, tostring(value))
                    end
                end
            end

            -- Process the JSON data
            add_key_value_pairs(payload_tree, json_data, "")
        else
            subtree:add(f_payload, buffer(#message_name + 2), "Invalid JSON")
        end
    else
        pinfo.cols.protocol = "OCPP 2.0.1"
        -- Create the protocol tree
        local subtree = tree:add(ocpp_proto, buffer(), "OCPP Non-Compliant Packet")
        subtree:add(ProtoField.string("ocpp2.0.1.error", "Error"), buffer(), tostring(validation_error))
        subtree:add(f_valid, is_valid):set_hidden(true)
        subtree:add(f_ipv6, ipv6):set_hidden(true)
    end
end

-- Register the dissector
local ws_protocol_table = DissectorTable.get("ws.protocol")
ws_protocol_table:add("ocpp2.0.1", ocpp_proto)
