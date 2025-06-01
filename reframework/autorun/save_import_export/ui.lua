local I18n = require("save_import_export.i18n")
local _t = I18n.t

-- 规则：
-- 1. 如果只有 children 而没有 category，则该子菜单仅起到显示归类作用，不会影响层级。
-- 2. 如果有 category 则该菜单会影响层级，children 的分类均在 category 下。
-- 3. match_remaining 匹配上方未登记的其他 category，因此必须要在最底部。
local g_import_options = {{
    name = "HunterId (!)",
    description = "Warning: don't check if you don't know what are you doing.\nMay break your save.",
    categories = {"HunterId", "HunterShortId"},
    enabled = false,
    default = false,
    no_auto_select = true
}, {
    name = "Basic Data",
    description = "Name, level, money, play time...",
    categories = {"Active", "LoadingPlLayout", "PlayStartDateTime", "PlayTime", "WorldTimeRealSecond", "_BasicData"},
    enabled = true,
    default = true
}, {
    name = "Character Appearance Edit",
    children = {{
        name = "Hunter",
        description = "Appearance of hunter.",
        categories = {"_CharacterEdit_Hunter"},
        enabled = true,
        default = true
    }, {
        name = "NPC",
        description = "Appearance of NPC.",
        categories = {"_CharacterEdit_NPC"},
        enabled = true,
        default = true
    }, {
        name = "Palico",
        description = "Appearance of palico.",
        categories = {"_CharacterEdit_Palico"},
        enabled = true,
        default = true
    }, {
        name = "Seikret",
        description = "Appearance of seikret.",
        categories = {"_CharacterEdit_Seikret"},
        enabled = true,
        default = true
    }}
}, {
    name = "Inventory",
    description = "Item box, shortcut set, item set and recipes.",
    categories = {"_CustomShortcutMySet", "_Item", "_ItemMySet", "_ItemRecipe"},
    enabled = true,
    default = true
}, {
    name = "Communication",
    description = "Auto-templates, stamps...",
    categories = {"_Communication"},
    enabled = true,
    default = true
}, {
    name = "Progress",
    description = "Game play progress. (A lot of data.)",
    categories = {"_Animal", "_Barter", "_Camp", "_Collection", "_DeliveryBounty", "_Discovery", "_Environment",
                  "_Environment_Other", "_Event", "_ExField", "_FieldIntro", "_InstantQuestHistory", "_LargeWorkshop",
                  "_Map", "_Mission", "_Otomo", "_Player", "_Pugee", "_Ship", "_Story"},
    enabled = true,
    default = true
}, {
    name = "Settings",
    description = "Menu settings and more.",
    categories = {"_LobbySearchSetting", "_SortModes", "_StartMenu", "_SubOrder", "_TempBanSessions", "_Tutorial"},
    enabled = true,
    default = true
}, {
    name = "Food Set",
    description = "Food skill set.",
    categories = {"_Dining"},
    enabled = true,
    default = true
}, {
    name = "Investigation Quest",
    description = "Saved investigation quests.",
    categories = {"_Quest"},
    enabled = true,
    default = true
}, {
    name = "Enemy Report",
    description = "Includes enemy kill count.",
    categories = {"_EnemyReport"},
    enabled = true,
    default = true
}, {
    name = "Records",
    description = "Quest records, ranking data.",
    categories = {"_RankingAnimalFish", "_RankingScore", "_QuestRecord"},
    enabled = false,
    default = false
}, {
    name = "Hunter Profile",
    category = "_HunterProfile",
    children = {{
        name = "Decorations",
        description = "Background, pose, title...",
        categories = {"CurrentBackground", "CurrentFacialExpression", "CurrentPose", "_Background", "_CameraOffset",
                      "_FacialExpression", "_Pose", "_Title"},
        enabled = true,
        default = true
    }, {
        name = "Quest and Weapon Clear Counter",
        categories = {"_QuestClearCounter"},
        enabled = true,
        default = true
    }, {
        name = "Other Counters",
        categories = {"ViewOtherProfileCounter", "_AnimalCapturePerStage", "_AnimalMiniGamePlayNum",
                      "_FacilityBoostCounter", "_FishCapturePerStage", "_FishMiniGamePlayNum"},
        enabled = true,
        default = true
    }, {
        name = "Medal",
        description = "Achivement medals.",
        categories = {"_Medal", "_MedalChecked"},
        enabled = true,
        default = true
    }, {
        name = "Name Plate",
        categories = {"_NamePlate"},
        enabled = true,
        default = true
    }, {
        name = "Profile Top (!)",
        description = "Warning: will cause your save to be unable to connect to the online server.",
        categories = {"_ProfileTop"},
        enabled = false,
        default = false,
        no_auto_select = true
    }, {
        name = "Others",
        categories = {},
        enabled = true,
        default = true,
        match_remaining = true
    }}
}, {
    name = "Equip",
    category = "_Equip",
    children = {{
        name = "Accessory",
        description = "Accessory box.",
        categories = {"_AccessoryBox", "_AccessoryCheckedFlag", "AccessoryFavoriteFlag"},
        enabled = true,
        default = true
    }, {
        name = "Appearance",
        description = "Appearance set.",
        categories = {"_AppearanceMySet", "_OuterArmorCurrent", "_OuterArmorFlags", "OuterMainWeaponCurrent",
                      "OuterReserveWeaponCurrent", "_OuterWeaponFlagParam"},
        enabled = true,
        default = true
    }, {
        name = "Equip Box",
        description = "Equip box, artian parts box.",
        categories = {"_ArmorFemaleFlagParam", "_ArmorMaleFlagParam", "_ArmorPigment", "_ArtianCreateCount",
                      "_ArtianPartsBox", "_CharmEquipped", "_EquipBox", "_EquipIndex", "_WeaponFlagParam"},
        enabled = true,
        default = true
    }, {
        name = "Equip Set",
        categories = {"_EquipMySet", "_EquipVisible"},
        enabled = true,
        default = true
    }, {
        name = "Cat",
        description = "All about cat.",
        categories = {"_OtAppearanceMySet", "_OtArmorPigment", "_OtBodyCheckedBit", "_OtEquipBox", "_OtEquipIndex",
                      "_OtEquipMyset", "_OtEquipVisible", "_OtHelmCheckedBit", "_OtOuterArmorCurrent",
                      "_OtOuterArmorFlags", "OtOuterWeaponCurrent", "_OtOuterWeaponFlags", "_OtWeaponCheckedBit"},
        enabled = true,
        default = true
    }, {
        name = "Others",
        categories = {},
        enabled = true,
        default = true,
        match_remaining = true
    }}
}, {
    name = "Others",
    categories = {},
    enabled = true,
    default = true,
    match_remaining = true
}}

local ISO_TO_LANG_INDEX = {
    en_US = 1,
    zh_CN = 2
}

local ui_save_combo = {"#0", "#1", "#2"}
local ui_language_iso = {"en_US", "zh_CN"}

local function draw_select_language()
    imgui.set_next_item_width(150)
    local changed, value = imgui.combo("Language", ISO_TO_LANG_INDEX[I18n.get_language_iso()] or 1, ui_language_iso)
    if changed then
        I18n.set_language(ui_language_iso[value])
    end
end

-- generate id for option tree
local function _generate_id(options, id)
    if not id then
        id = 1
    end
    for i, option in ipairs(options) do
        option.id = id
        id = id + 1
        if option.children then
            id = _generate_id(option.children, id)
        end
    end

    return id
end

_generate_id(g_import_options)

local function visit_options(options, visitor)
    local function _visit(options)
        for _, option in ipairs(options) do
            visitor(option)
            if option.children then
                _visit(option.children)
            end
        end
    end
    _visit(options)
end

local function draw_import_options()
    local function draw_option(option)
        local label = _t(option.name) .. "##" .. tostring(option.id)
        if option.enabled ~= option.default then
            label = "*" .. label
        end

        local changed, value = imgui.checkbox(label, option.enabled)
        if changed then
            option.enabled = value
        end

        if imgui.is_item_hovered() then
            local tooltip = nil
            if option.description then
                tooltip = _t(option.description)
            else
                tooltip = table.concat(option.categories, ", ")
            end
            imgui.set_tooltip(tooltip)
        end
    end

    local function draw_children_options(option)
        if imgui.tree_node(_t(option.name)) then
            for _, child_option in ipairs(option.children) do
                if child_option.children then
                    draw_children_options(child_option)
                else
                    draw_option(child_option)
                end
            end
            imgui.tree_pop()
        end
    end

    imgui.text(_t("Import Options"))

    if imgui.button(_t("Select All")) then
        visit_options(g_import_options, function(option)
            if type(option.enabled) == "boolean" and not option.no_auto_select then
                option.enabled = true
            end
        end)
    end
    imgui.same_line()
    if imgui.button(_t("Select None")) then
        visit_options(g_import_options, function(option)
            if type(option.enabled) == "boolean" and not option.no_auto_select then
                option.enabled = false
            end
        end)
    end
    imgui.same_line()
    if imgui.button(_t("Reset")) then
        visit_options(g_import_options, function(option)
            if type(option.enabled) == "boolean" and type(option.default) == "boolean" then
                option.enabled = option.default
            end
        end)
    end

    for _, option in ipairs(g_import_options) do
        if option.children then
            -- has children
            draw_children_options(option)
        else
            draw_option(option)
        end
    end
end

return {
    draw_select_language = draw_select_language,
    draw_import_options = draw_import_options,
    import_options = g_import_options
}
