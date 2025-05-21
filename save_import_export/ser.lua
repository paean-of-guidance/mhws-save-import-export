-- Serialize
local function value_direct_save(value)
    return value
end

local ValueSerializers = {
    ["via.vec3"] = function(value)
        return {
            x = value.x,
            y = value.y,
            z = value.z
        }
    end,
    ["via.vec4"] = function(value)
        return {
            x = value.x,
            y = value.y,
            z = value.z,
            w = value.w
        }
    end,
    ["System.Guid"] = function(value)
        return value:ToString()
    end,
    -- ["ace.Bitset"] = value_direct_save,
    ["via.rds.Mandrake"] = function(value)
        -- try to decode, if failed, use original value
        local ret = {
            m = value.m,
            v = value.v
        }
        pcall(function()
            ret = value:decode()
        end)
        return ret
    end
}

local function _dump_struct_recursive(object, visited)
    -- is primitive type
    if type(object) ~= "userdata" then
        -- a special case for empty string
        if object == "string.Empty" then
            return ""
        end
        return object
    end

    local result = {}

    -- filter values that already transformed to lua primitive type (not REManagedObject or other userdata)
    if not object.get_type_definition then
        return object
    end
    local struct_type = object:get_type_definition()
    -- iterate fields
    for _, field in ipairs(struct_type:get_fields()) do
        if field:is_static() then
            -- log.debug(string.format("static field %s (type %s), skipping", field:get_name(), field:get_type()))
            goto continue
        end

        local field_name = field:get_name()
        local field_type = field:get_type()
        local field_type_name = field_type:get_full_name()
        -- local is_value_type = field_type:is_value_type()
        local field_data = field:get_data(object)

        if type(field_data) == "userdata" and field_data.get_address then
            local field_address = field_data:get_address()
            if visited[field_address] then
                log.debug(string.format("type(%s) at 0x%x already visited, skipping", field_type_name, field_address))
                goto continue
            end
            visited[field_address] = true
        end

        local match = field_type_name:match('(.*)%[%]$')
        if match then
            -- is array
            local array_result = {}
            local length = field_data:get_Count()
            local arr_elem_type_name = match
            for i = 0, length - 1, 1 do
                local item = field_data:get_Item(i)
                local serializer = ValueSerializers[arr_elem_type_name]
                if serializer then
                    array_result[i + 1] = serializer(item)
                else
                    array_result[i + 1] = _dump_struct_recursive(item, visited)
                end
            end
            result[field_name] = array_result
        else
            local serializer = ValueSerializers[field_type_name]
            if serializer then
                result[field_name] = serializer(field_data)
            else
                result[field_name] = _dump_struct_recursive(field_data, visited)
            end
        end

        ::continue::
    end

    return result
end

local function serialize_struct(struct)
    local visited = {}
    return _dump_struct_recursive(struct, visited)
end

return {
    serialize_struct = serialize_struct
}
