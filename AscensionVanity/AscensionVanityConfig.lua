-- AscensionVanity Configuration
-- User-editable settings for the addon

AscensionVanityDB = AscensionVanityDB or {}

-- Default configuration values (alphabetically ordered for clean SavedVariables output)
local defaults = {
    categoryFilters = {
        beast = true,            -- Beastmaster's Whistle (Group 16777217)
        demon = true,            -- Summoner's Stone (Group 16777218)
        dragonkin = true,        -- Draconic Warhorn (Group 16777224)
        elemental = true,        -- Elemental Lodestone (Group 16777232)
        undead = true            -- Blood Soaked Vellum (Group 16777220)
    },
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
    -- Preserve existing values or use defaults
    local existingDB = AscensionVanityDB or {}
    
    -- Build categoryFilters in alphabetical order
    local categoryFilters = existingDB.categoryFilters or {}
    local orderedCategoryFilters = {
        beast = (categoryFilters.beast ~= nil) and categoryFilters.beast or defaults.categoryFilters.beast,
        demon = (categoryFilters.demon ~= nil) and categoryFilters.demon or defaults.categoryFilters.demon,
        dragonkin = (categoryFilters.dragonkin ~= nil) and categoryFilters.dragonkin or defaults.categoryFilters.dragonkin,
        elemental = (categoryFilters.elemental ~= nil) and categoryFilters.elemental or defaults.categoryFilters.elemental,
        undead = (categoryFilters.undead ~= nil) and categoryFilters.undead or defaults.categoryFilters.undead
    }
    
    -- Rebuild entire table in alphabetical order to ensure clean SavedVariables output
    AscensionVanityDB = {
        categoryFilters = orderedCategoryFilters,
        colorCode = (existingDB.colorCode ~= nil) and existingDB.colorCode or defaults.colorCode,
        combatBehavior = existingDB.combatBehavior or defaults.combatBehavior,
        debug = (existingDB.debug ~= nil) and existingDB.debug or defaults.debug,
        enabled = (existingDB.enabled ~= nil) and existingDB.enabled or defaults.enabled,
        eventSpy = (existingDB.eventSpy ~= nil) and existingDB.eventSpy or defaults.eventSpy,
        showLearnedStatus = (existingDB.showLearnedStatus ~= nil) and existingDB.showLearnedStatus or defaults.showLearnedStatus,
        showRegions = (existingDB.showRegions ~= nil) and existingDB.showRegions or defaults.showRegions
    }
end

-- Call initialization when file loads
AscensionVanity_InitConfig()

-- Note: Settings UI has been moved to SettingsUI.lua for better code organization
