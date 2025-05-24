local f_Guid_Parse = sdk.find_type_definition("System.Guid"):get_method("Parse(System.String)")
local f_Mandrake_encode = sdk.find_type_definition("via.rds.Mandrake"):get_method("encode(System.Int64)")

-- This classification might be very inaccurate
local IMPORT_OPTION_CATEGORIES = {
    basic_data = {"Active", "LoadingPlLayout", "PlayStartDateTime", "PlayTime", "WorldTimeRealSecond", "_BasicData"},
    inventory = {"_CustomShortcutMySet", "_Item", "_ItemMySet", "_ItemRecipe"},
    character_edit = {"_CharacterEdit_Hunter", "_CharacterEdit_NPC", "_CharacterEdit_Palico", "_CharacterEdit_Seikret"},
    communication = {"_Communication"},
    progress = {"_Barter", "_Camp", "_Collection", "_DeliveryBounty", "_Dining", "_Discovery", "_EnemyReport",
                "_Environment", "_Environment_Other", "_Equip", "_Event", "_ExField", "_FieldIntro",
                "_InstantQuestHistory", "_LargeWorkshop", "_Map", "_Mission", "_Otomo", "_Player", "_Pugee", "_Quest",
                "_Ship", "_Story"},
    records = {"_RankingAnimalFish", "_RankingScore"},
    animal = {"_Animal"},
    settings = {"_LobbySearchSetting", "_SortModes", "_StartMenu", "_SubOrder", "_TempBanSessions", "_Tutorial"}
}

local ValueWriters = {
    ["via.vec3"] = function(obj, field, value)
        obj[field].x = value.x
        obj[field].y = value.y
        obj[field].z = value.z
    end,
    ["via.vec4"] = function(obj, field, value)
        obj[field].x = value.x
        obj[field].y = value.y
        obj[field].z = value.z
        obj[field].w = value.w
    end,
    ["System.Guid"] = function(obj, field, value)
        obj[field] = f_Guid_Parse:call(nil, value)
    end,
    ["via.rds.Mandrake"] = function(obj, field, value)
        -- if decoded, encode it back.
        if type(value) == "number" or type(value) == "integer" then
            f_Mandrake_encode:call(obj[field], value)
        else
            obj[field].m = value.m
            obj[field].v = value.v
        end
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

        -- log.debug(string.format("field_name: %s, field_type: %s", field_name, field_type_name))

        if not data[field_name] then
            goto continue
        end

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

        ::continue::
    end
end

local function deserialize_struct(target, data, import_options)
    -- -- exclude fields
    data["HunterId"] = nil
    data["HunterShortId"] = nil

    if import_options.ungrouped then
        for category, ok in pairs(import_options) do
            if not ok then
                for _, field_name in ipairs(IMPORT_OPTION_CATEGORIES[category]) do
                    data[field_name] = nil
                end
            end
        end
    else
        local new_data = {}
        for category, ok in pairs(import_options) do
            if ok then
                for _, field_name in ipairs(IMPORT_OPTION_CATEGORIES[category]) do
                    new_data[field_name] = data[field_name]
                end
            end
        end
        data = new_data
    end

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

    local visited = {}
    return _deserialize_struct_recursive(target, data, visited)
end

return {
    deserialize_struct = deserialize_struct
}
