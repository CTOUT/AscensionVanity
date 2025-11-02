-- AscensionVanity Configuration
-- User-editable settings for the addon

AscensionVanityDB = AscensionVanityDB or {}

-- Default configuration values (alphabetically ordered for code readability)
local defaults = {
    categoryFilters = {
        beast = true,            -- Beastmaster's Whistle (Group 16777217)
        demon = true,            -- Summoner's Stone (Group 16777218)
        dragonkin = true,        -- Draconic Warhorn (Group 16777224)
        elemental = true,        -- Elemental Lodestone (Group 16777232)
        undead = true            -- Blood Soaked Vellum (Group 16777220)
    },
    collectionFilter = "both",   -- "both", "known", "unknown" (default: both - show all)
    colorCode = true,            -- Color-code tooltip text based on learned status
    combatBehavior = "hide",     -- "normal", "minimal", "hide" (default: hide)
    debug = false,               -- Enable debug logging
    enabled = true,              -- Enable/disable the addon
    eventSpy = false,            -- Event spy (developer tool)
    showLearnedStatus = true,    -- Show "Learned" or "Not Learned" in tooltips
    showRegions = false          -- Show region/location information (not yet implemented)
}

-- Initialize configuration with defaults if not already set
function AscensionVanity_InitConfig()
    for key, value in pairs(defaults) do
        if AscensionVanityDB[key] == nil then
            if type(value) == "table" then
                -- Deep copy for nested tables (like categoryFilters)
                AscensionVanityDB[key] = {}
                for k, v in pairs(value) do
                    AscensionVanityDB[key][k] = v
                end
            else
                AscensionVanityDB[key] = value
            end
        end
    end
    
    -- Ensure categoryFilters exists and has all categories (for upgrades from older versions)
    if not AscensionVanityDB.categoryFilters then
        AscensionVanityDB.categoryFilters = {}
    end
    for category, enabled in pairs(defaults.categoryFilters) do
        if AscensionVanityDB.categoryFilters[category] == nil then
            AscensionVanityDB.categoryFilters[category] = enabled
        end
    end
end

-- Call initialization when file loads
AscensionVanity_InitConfig()

-- Note: Settings UI has been moved to SettingsUI.lua for better code organization
