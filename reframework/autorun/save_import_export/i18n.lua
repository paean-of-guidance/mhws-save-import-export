local LANGUAGE_ISO = {
    [0] = "ja_JP", -- Japanese
    [1] = "en_US", -- English
    [2] = "fr_FR", -- French
    [3] = "it_IT", -- Italian
    [4] = "de_DE", -- German
    [5] = "es_ES", -- Spanish
    [6] = "ru_RU", -- Russian
    [7] = "pl_PL", -- Polish
    [8] = "nl_NL", -- Dutch
    [9] = "pt_PT", -- Portuguese
    [10] = "pt_BR", -- PortugueseBr
    [11] = "ko_KR", -- Korean
    [12] = "zh_TW", -- TraditionalChinese
    [13] = "zh_CN", -- SimplifiedChinese
    [14] = "fi_FI", -- Finnish
    [15] = "sv_SE", -- Swedish
    [16] = "da_DK", -- Danish
    [17] = "no_NO", -- Norwegian
    [18] = "cs_CZ", -- Czech
    [19] = "hu_HU", -- Hungarian
    [20] = "sk_SK", -- Slovak
    [21] = "ar_SA", -- Arabic
    [22] = "tr_TR", -- Turkish
    [23] = "bg_BG", -- Bulgarian
    [24] = "el_GR", -- Greek
    [25] = "ro_RO", -- Romanian
    [26] = "th_TH", -- Thai
    [27] = "uk_UA", -- Ukrainian
    [28] = "vi_VN", -- Vietnamese
    [29] = "id_ID", -- Indonesian
    [30] = "lang_fiction", -- Fiction
    [31] = "hi_IN", -- Hindi
    [32] = "es_MX" -- LatinAmericanSpanish
}

---@return via.Language
local function get_current_language()
    local gui_manager = sdk.get_managed_singleton("app.GUIManager")
    if not gui_manager then -- dunno why but sometimes it returns nil
        return 1 -- English
    end
    return gui_manager:getSystemLanguageToApp()
end

local I18n = {
    root_path = nil,
    language = "en_US",
    lang_data = {}
}

--- Initialize the module.
--- Default language is followed by game's language.
---@param root_path string @ The root dir path of the required language files.
function I18n.init(root_path)
    I18n.root_path = root_path
    for _, lang_iso in pairs(LANGUAGE_ISO) do
        local ok, result = pcall(require, root_path .. "." .. lang_iso)
        if ok then
            I18n.lang_data[lang_iso] = result
        end
    end
    log.debug("Loaded languages: ")
    for k, _ in pairs(I18n.lang_data) do
        log.debug(k)
    end

    I18n.set_language(get_current_language())
end

--- Set the language.
---@param lang_id_or_iso string | number @ The language ID or ISO code to set.
function I18n.set_language(lang_id_or_iso)
    if not I18n.root_path then
        error("I18n module not initialized.")
    end

    local lang_iso = nil
    if type(lang_id_or_iso) == "string" then
        lang_iso = lang_id_or_iso
    else
        lang_iso = LANGUAGE_ISO[lang_id_or_iso]
        if not lang_iso then
            error("Invalid language ID: " .. lang_id_or_iso)
        end
    end

    if I18n.lang_data[lang_iso] then
        I18n.language = lang_iso
        log.debug("Set language to " .. lang_iso)
    else
        log.warn("Language data not found: " .. lang_iso .. ", using default language.")
        I18n.language = "en_US"
    end
end

--- Get the current language ISO.
---@return string @ The ISO code of the current language.
function I18n.get_language_iso()
    return I18n.language
end

--- Get the text.
--- If text not found, will return default language or the key.
---@param key string @ The key of the text.
---@return string @ The text.
function I18n.t(key)
    if not I18n.root_path then
        error("I18n module is not initialized.")
    end
    if not I18n.lang_data then
        error("I18n module lang data is not loaded.")
    end

    local text = I18n.lang_data[I18n.language][key]
    if not text then
        return key
    end

    return text
end

return I18n
