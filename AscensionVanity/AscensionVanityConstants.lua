-- AscensionVanity - Shared Constants
-- Icons, colors, version info, and other constants used across multiple files

-- ============================================================================
-- Version Information
-- ============================================================================

AV_VERSION = "2.2"
AV_RELEASE_TYPE = "dev"  -- "prd", "tst", "dev"

-- Get current Ascension build version string
-- Returns: version string like "2025-11-02 @ 22:44:06 GMT Not Available"
-- Used by: APIScanner (for scan metadata), Core (for version check)
function AV_GetCurrentAscensionVersion()
    if not GetClientVersion then
        return "Unknown"
    end
    
    local success, dateStr, timeStr, branch = pcall(GetClientVersion)
    if not success or not dateStr then
        return "Unknown"
    end
    
    local version = tostring(dateStr) .. " @ " .. tostring(timeStr)
    if branch and branch ~= "" and branch ~= "nil" then
        version = version .. " " .. tostring(branch)
    end
    
    return version
end

-- ============================================================================
-- Color Codes
-- ============================================================================

-- Addon branding color
AV_COLOR_ADDON = "|cFF00FF96"  -- Teal/cyan (addon name in messages)

-- Tooltip colors
AV_COLOR_HEADER = "|cFF00FF96"     -- Teal/cyan (section headers)
AV_COLOR_LEARNED = "|cFF00FF00"    -- Green (learned items)
AV_COLOR_UNLEARNED = "|cFFFFFF00"  -- Yellow (unlearned items)

-- UI text colors
AV_COLOR_GRAY = "|cFF888888"       -- Gray (descriptive text)
AV_COLOR_ORANGE = "|cFFFFAA00"     -- Orange (warnings/notes)
AV_COLOR_YELLOW = "|cFFFFFF00"     -- Yellow (highlights/alerts)
AV_COLOR_GREEN = "|cFF00FF00"      -- Green (success/recommendations)
AV_COLOR_BLUE = "|cFF0099FF"       -- Blue (informational text)
AV_COLOR_WHITE = "|cFFFFFFFF"      -- White (standard text)

-- Color reset
AV_COLOR_RESET = "|r"

-- ============================================================================
-- Category Icons
-- ============================================================================

-- Category icons for visual identification
-- Icons verified from https://db.ascension.gg/?icon=<ID>
-- Format: |TTexture:size:size:xoffset:yoffset:texwidth:texheight:left:right:top:bottom|t
AV_CATEGORY_ICONS = {
    beast = "Interface\\Icons\\ability_hunter_beastcall",       -- Icon 455
    demon = "Interface\\Icons\\inv_misc_uncutgemnormal1",       -- Icon 19474
    dragonkin = "Interface\\Icons\\inv_misc_horn_01",           -- Icon 1550
    elemental = "Interface\\Icons\\custom_t_nhance_rpg_icons_arcanestone_border",  -- Icon 62794
    undead = "Interface\\Icons\\inv_glyph_primedeathknight"     -- Icon 13479
}

-- Category display names (for UI labels)
AV_CATEGORY_NAMES = {
    beast = "Beastmaster's Whistle - Beasts",
    demon = "Summoner's Stone - Demons",
    dragonkin = "Draconic Warhorn - Dragonkin",
    elemental = "Elemental Lodestone - Elementals",
    undead = "Blood Soaked Vellum - Undead"
}

-- Helper function to format icon texture with specified size
function AV_FormatIcon(iconPath, size)
    size = size or 14  -- Default to 14px (tooltip size)
    -- Using proper texture coordinates to prevent bleeding: 4:60 on both axes
    return string.format("|T%s:%d:%d:0:0:64:64:4:60:4:60|t", iconPath, size, size)
end

-- Helper function to get category icon (formatted for display)
function AV_GetCategoryIcon(category, size)
    local iconPath = AV_CATEGORY_ICONS[category]
    if iconPath then
        return AV_FormatIcon(iconPath, size)
    end
    return ""
end

-- Helper function to get category name with icon
function AV_GetCategoryLabel(category, size)
    local icon = AV_GetCategoryIcon(category, size)
    local name = AV_CATEGORY_NAMES[category]
    if icon ~= "" and name then
        return icon .. "  " .. name
    end
    return name or ""
end
