local ser = require("save_import_export.ser")
local de = require("save_import_export.de")

local reffs = fs

-- local d_UserSaveParam = sdk.find_type_definition("app.savedata.cUserSaveParam")
local s_SaveDataManager = sdk.get_managed_singleton("app.SaveDataManager")

-- sdk.get_managed_singleton("app.SaveDataManager"):getCurrentUserSaveData()

local fs = nil
if eglib then
    fs = eglib.fs:new("save_import_export")
end

local DEFAULT_IMPORT_OPTIONS = {
    hunter_profile = false,
    basic_data = true,
    inventory = true,
    character_edit = true,
    communication = true,
    progress = true,
    records = true,
    animal = true,
    settings = true,
    ungrouped = true
}

local g_has_export_task = false
local g_has_import_task = false
local g_import_options = {
    basic_data = true,
    inventory = true,
    character_edit = true,
    communication = true,
    progress = true,
    records = true,
    animal = true,
    settings = true,
    ungrouped = true
}

-- utils

---@param str string
---@return boolean
local function is_guid(str)
    if str == nil then
        return false
    end
    return str:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

local function export_save_data()
    ---@type app.savedata.cUserSaveParam
    local current_save_data = s_SaveDataManager:getCurrentUserSaveData()

    local save_data_map = {}
    if current_save_data and is_guid(current_save_data["HunterId"]) then
        log.debug("----- saving data -----")
        save_data_map = ser.serialize_struct(current_save_data)
    else
        return
    end

    if fs then
        local paths = fs:request_access({
            permission = "w",
            directory = ".",
            save_file = true,
            file_name = "save_export.json",
            filters = {{
                name = "JSON",
                extensions = {"json"}
            }},
            title = "Export Save Data"
        })
        if #paths ~= 0 then
            log.debug("----- saving data to file -----")
            local json_str = json.dump_string(save_data_map, 2)
            local ok, err = pcall(function()
                fs:write_text_file(paths[1], json_str)
            end)
            if not ok then
                error(tostring(err))
            end
        end
    else
        json.dump_file("save_export.json", save_data_map, 2)
        re.msg("Save data exported to file reframework/data/save_export.json")
    end
end

local function import_save_data(import_options)
    ---@type app.savedata.cUserSaveParam
    local current_save_data = s_SaveDataManager:getCurrentUserSaveData()

    if fs then
        local paths = fs:request_access({
            permission = "r",
            filters = {{
                name = "JSON",
                extensions = {"json"}
            }},
            title = "Load Save Data"
        })
        if #paths ~= 0 then
            log.debug("----- loading data from file -----")
            local json_str = nil
            local ok, err = pcall(function()
                json_str = fs:read_text_file(paths[1])
            end)
            if not ok then
                error(tostring(err))
            end

            local save_data_map = json.load_string(json_str)
            de.deserialize_struct(current_save_data, save_data_map, import_options)
        end
    else
        local save_data_map = json.load_file("save_export.json")
        if not save_data_map then
            re.msg([[Failed to load save data from file reframework/data/save_export.json
Please install `eglib` plugin for file system access, or put file in target directory.]])
            return
        end

        de.deserialize_struct(current_save_data, save_data_map, import_options)
    end
end

re.on_draw_ui(function()
    if not imgui.tree_node("Save Data Import/Export") then
        return
    end

    imgui.text("Author: Eigeen")
    imgui.text("Version: 1.0.0")
    imgui.text("Any errors or suggestions,")
    imgui.text("check updates, or post in Nexus or GitHub.")
    imgui.text_colored("Warning: Backup save data before importing!!!", 0xff0080ff)

    if imgui.button("Export") then
        -- run real export task in game logic thread, or some methods will throw exceptions.
        g_has_export_task = true
    end
    if imgui.button("Import") then
        -- run real import task in game logic thread, or some methods will throw exceptions.
        g_has_import_task = true
    end

    local any_changed = false
    local function CheckBox(label, id)
        if g_import_options[id] ~= DEFAULT_IMPORT_OPTIONS[id] then
            label = "*" .. label
        end
        local changed, value = imgui.checkbox(label, g_import_options[id])
        if changed then
            any_changed = true
        end
        g_import_options[id] = value
    end
    local function WithTooltip(tooltip, func)
        imgui.begin_group()
        func()
        imgui.end_group()
        if imgui.is_item_hovered() then
            imgui.set_tooltip(tooltip)
        end
    end

    if imgui.tree_node("Import Options") then
        imgui.text("Import parts")
        imgui.text("See save_import_export/de.lua: IMPORT_OPTION_CATEGORIES for details")
        WithTooltip("Synchronizing the HunterProfile will cause your save to be unable to connect to the online server",
            function()
                imgui.begin_disabled()
                CheckBox("HunterProfile", false)
                imgui.end_disabled()
            end)
        WithTooltip("Hunter, seikret name, points, moneys, etc.", function()
            CheckBox("BasicData", "basic_data")
        end)
        WithTooltip("Items, shortcuts, etc.", function()
            CheckBox("Inventory", "inventory")
        end)
        WithTooltip("Character appearance", function()
            CheckBox("CharacterEdit", "character_edit")
        end)
        WithTooltip("Auto-templates, stamps", function()
            CheckBox("Communication", "communication")
        end)
        WithTooltip("Game play progress", function()
            CheckBox("Progress", "progress")
        end)
        WithTooltip("Ranking data", function()
            CheckBox("Records", "records")
        end)
        WithTooltip("Environment animals", function()
            CheckBox("Animal", "animal")
        end)
        CheckBox("Settings", "settings")
        CheckBox("Ungrouped", "ungrouped")

        imgui.tree_pop()
    end

    imgui.tree_pop()
end)

sdk.hook(sdk.find_type_definition("app.GUIManager"):get_method("update()"), function(args)
    if g_has_export_task then
        g_has_export_task = false
        export_save_data()
    end
    if g_has_import_task then
        g_has_import_task = false
        import_save_data(g_import_options)
    end
end, function(retval)

end)
