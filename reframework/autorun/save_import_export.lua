local VERSION = "1.1.1-20250601"

local ser = require("save_import_export.ser")
local de = require("save_import_export.de")
local ui = require("save_import_export.ui")
local I18n = require("save_import_export.i18n")
local utils = require("save_import_export.utils")

-- local d_UserSaveParam = sdk.find_type_definition("app.savedata.cUserSaveParam")
local s_SaveDataManager = utils.LazyStatic.new(function()
    return sdk.get_managed_singleton("app.SaveDataManager")
end)

-- sdk.get_managed_singleton("app.SaveDataManager"):getCurrentUserSaveData()

local fs = nil
if eglib then
    fs = eglib.fs:new("save_import_export")
end

-- initialize i18n
I18n.init("save_import_export.language")
local _t = I18n.t

local g_selected_save_index = 0
local g_has_export_task = false
local g_has_import_task = false

-- utils

---@param str string
---@return boolean
local function is_guid(str)
    if str == nil then
        return false
    end
    return str:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

local function deepcopy(orig, seen)
    seen = seen or {}
    if seen[orig] then
        return seen[orig]
    end

    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        seen[orig] = copy
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key, seen)] = deepcopy(orig_value, seen)
        end
        setmetatable(copy, deepcopy(getmetatable(orig), seen))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

---@return app.savedata.cUserSaveParam
local function getUserSaveData(index)
    log.debug("Get user save data #" .. tostring(index))
    return s_SaveDataManager:value():getUserSaveData(index)
end

local function export_save_data()
    local current_save_data = getUserSaveData(g_selected_save_index)

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
    local current_save_data = getUserSaveData(g_selected_save_index)

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

local ui_save_combo = {"#0", "#1", "#2"}

local function draw_select_save_data()
    if imgui.button(_t("Refresh Saves List")) then
        ui_save_combo = {"#0", "#1", "#2"}
        for i = 0, 2 do
            local save_data = getUserSaveData(i)
            if save_data then
                ui_save_combo[i + 1] = string.format("%s: %s##%d", save_data["_BasicData"]["CharName"],
                    save_data["HunterShortId"], i)
            end
        end
    end

    local changed, value = imgui.combo("Select Save #" .. tostring(g_selected_save_index), g_selected_save_index + 1,
        ui_save_combo)
    if changed and ui_save_combo[value] ~= "" then
        g_selected_save_index = value - 1
    end
end

re.on_draw_ui(function()
    if not imgui.tree_node("Save Data Import/Export") then
        return
    end

    imgui.text("Author: Eigeen")
    imgui.text("Version: " .. VERSION)
    imgui.text("Any errors or suggestions,")
    imgui.text("check updates, or post in Nexus or GitHub.")
    imgui.text_colored(_t("Warning: Backup save data before importing!!!"), 0xff0080ff)

    imgui.text("-----")
    ui.draw_select_language()
    imgui.text("-----")
    draw_select_save_data()

    if imgui.button(_t("Export")) then
        -- run real export task in game logic thread, or some methods will throw exceptions.
        g_has_export_task = true
    end
    if imgui.button(_t("Import")) then
        -- run real import task in game logic thread, or some methods will throw exceptions.
        g_has_import_task = true
    end

    ui.draw_import_options()

    imgui.tree_pop()
end)

sdk.hook(sdk.find_type_definition("app.GUIManager"):get_method("update()"), function(args)
    if g_has_export_task then
        g_has_export_task = false
        export_save_data()
    end
    if g_has_import_task then
        g_has_import_task = false
        import_save_data(ui.import_options)
    end
end, function(retval)

end)
