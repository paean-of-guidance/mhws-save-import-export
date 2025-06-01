local f_Guid_Parse = sdk.find_type_definition("System.Guid"):get_method("Parse(System.String)")
local f_Mandrake_encode = sdk.find_type_definition("via.rds.Mandrake"):get_method("encode(System.Int64)")

local g_path_stack = {}

local ValueWriters = {
    ["via.vec3"] = function(obj, field, value)
        local vec3_obj = obj[field]
        vec3_obj.x = value.x
        vec3_obj.y = value.y
        vec3_obj.z = value.z
        obj[field] = vec3_obj
    end,
    ["via.vec4"] = function(obj, field, value)
        local vec4_obj = obj[field]
        vec4_obj.x = value.x
        vec4_obj.y = value.y
        vec4_obj.z = value.z
        vec4_obj.w = value.w
        obj[field] = vec4_obj
    end,
    ["System.Guid"] = function(obj, field, value)
        obj[field] = f_Guid_Parse:call(nil, value)
    end,
    ["via.rds.Mandrake"] = function(obj, field, value)
        local mandrake_obj = obj[field]
        if type(value) == "number" then
            mandrake_obj:set_field("v", math.floor(obj[field].m * value))
        else
            mandrake_obj:set_field("m", value.m)
            mandrake_obj:set_field("v", value.v)
        end
        -- ValueType, write the copy back
        obj[field] = mandrake_obj
    end
}

local function _deserialize_struct_recursive(object, data, visited)
    if not object.get_type_definition then
        return
    end
    local struct_type = object:get_type_definition()
    -- iterate fields
    for _, field in ipairs(struct_type:get_fields()) do
        if field:is_static() then
            goto continue
        end
        local field_name = field:get_name()
        local field_type = field:get_type()
        local field_type_name = field_type:get_full_name()
        local field_data = field:get_data(object)
        table.insert(g_path_stack, field_name)

        -- log.debug(string.format("field_name: %s, field_type: %s", field_name, field_type_name))

        if not data[field_name] then
            table.remove(g_path_stack)
            goto continue
        end

        if type(field_data) == "userdata" and field_data.get_address then
            local field_address = field_data:get_address()
            if visited[field_address] then
                log.debug(string.format("type(%s) at 0x%x already visited, skipping", field_type_name, field_address))
                table.remove(g_path_stack)
                goto continue
            end
            visited[field_address] = true
        end

        local match = field_type_name:match('(.*)%[%]$')
        if match then
            -- is array
            local length = field_data:get_Count()
            local arr_elem_type_name = match
            for i = 0, length - 1, 1 do
                local writer = ValueWriters[arr_elem_type_name]
                if writer then
                    writer(field_data, i, data[field_name][i + 1])
                else
                    local item = field_data:get_Item(i)
                    if type(item) ~= "userdata" then
                        local ok, _ = pcall(function()
                            field_data[i] = data[field_name][i + 1]
                        end)
                        if not ok then
                            log.debug(string.format("failed to set array element %d of type %s", i, arr_elem_type_name))
                            log.debug(string.format("data: %s", tostring(data[field_name][i + 1])))
                        end
                    else
                        _deserialize_struct_recursive(item, data[field_name][i + 1], visited)
                    end
                end
            end
        else
            local writer = ValueWriters[field_type_name]
            if writer then
                writer(object, field_name, data[field_name])
            else
                if type(field_data) ~= "userdata" then
                    object[field_name] = data[field_name]
                else
                    _deserialize_struct_recursive(field_data, data[field_name], visited)
                end
            end
        end

        table.remove(g_path_stack)
        ::continue::
    end
end

local function Array_Difference(a, b)
    local res = {}
    local b_values = {}

    -- Create a lookup table for values in b
    for _, v in ipairs(b) do
        b_values[v] = true
    end

    -- Check values in a that aren't in b
    for _, v in ipairs(a) do
        if not b_values[v] then
            table.insert(res, v)
        end
    end

    return res
end

local function apply_options(data, options)

    local function process_options(options, data, categories)
        local new_data = {}
        -- 用于后续处理Others选项
        local all_categories = categories

        for _, option in ipairs(options) do
            if option.categories then
                for _, category in ipairs(option.categories) do
                    table.insert(all_categories, category)
                end
            elseif option.category then
                table.insert(all_categories, option.category)
            end

            if option.enabled then
                -- others option
                if option.match_remaining then
                    local all_keys = {}
                    for k, _ in pairs(data) do
                        table.insert(all_keys, k)
                    end
                    local remaining = Array_Difference(all_keys, all_categories)
                    for _, field in ipairs(remaining) do
                        log.debug("apply remaining field: " .. field)
                        new_data[field] = data[field]
                    end
                elseif option.categories then
                    -- common option
                    for _, category in ipairs(option.categories) do
                        log.debug("apply selected field: " .. category)
                        new_data[category] = data[category]
                    end
                end
            elseif option.children then
                -- sub options
                if option.category then
                    new_data[option.category] = process_options(option.children, data[option.category], {})
                else
                    -- 不支持Others，否则会出现意外问题
                    -- 修复：all_categoriesx向下传递，以收集同级的分类
                    local tmp = process_options(option.children, data, all_categories)
                    for k, v in pairs(tmp) do
                        new_data[k] = v
                    end
                end
            end
        end

        -- clear empty data
        for k, v in pairs(new_data) do
            if type(v) == "table" and next(v) == nil then
                new_data[k] = nil
            end
        end

        return new_data
    end

    -- 处理所有顶层选项
    local new_data = process_options(options, data, {})

    return new_data
end

local function deserialize_struct(target, data, import_options)
    -- 应用options过滤
    data = apply_options(data, import_options)

    -- just for debugging
    local keys = {}
    for k in pairs(data) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    log.debug("Selected fields: ")
    for _, k in ipairs(keys) do
        log.debug(k)
    end

    log.debug(json.dump_string(data))

    g_path_stack = {}

    local result = {}
    local ok, msg = pcall(function()
        local visited = {}
        result = _deserialize_struct_recursive(target, data, visited)
    end)
    if not ok then
        re.msg("Failed to deserialize struct: " .. tostring(msg) .. "\nPath: " .. table.concat(g_path_stack, "."))
        error("Failed to deserialize struct: " .. tostring(msg) .. "\nPath: " .. table.concat(g_path_stack, "."))
    end

    return result
end

return {
    deserialize_struct = deserialize_struct
}

