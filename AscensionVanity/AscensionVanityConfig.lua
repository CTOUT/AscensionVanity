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
    -- showIDs removed - use built-in WoW option (Interface -> Display -> Show IDs in Tooltips)
    showLearnedStatus = true,    -- Show "Learned" or "Not Learned" in tooltips
    showQuestWarnings = true,    -- Show quest-locked NPC warnings (v2.2)
    showRegions = false,         -- Show region/location information (not yet implemented)
    
    -- Statistics Tracking (v2.3)
    enableKillTracking = true,   -- Track kills per creature
    showKillStats = true,        -- Show kill/drop stats in tooltips
    chatNotifyKills = false,     -- Print kill notifications to chat
    showDropRaidWarning = true,  -- Show big raid warning when item drops
    flashScreenOnDrop = true,    -- Flash screen when item drops (celebratory effect)
    showUnluckyStreak = true,    -- Warn about long streaks without drops
    unluckyStreakThreshold = 20, -- Number of kills before showing unlucky warning
    
    -- Creature Information (v2.3 Phase 2A)
    showCreatureInfo = true,     -- Show enhanced creature info in tooltips (master toggle)
    creatureInfoFilter = "vanity", -- When to show creature info: "all", "vanity", "tameable", "vanity_and_tameable"
    showCreatureType = true,     -- Show creature type/family (e.g., Beast (Wolf))
    showAttackSpeed = true,      -- Show creature attack speed
    showHealth = true,           -- Show creature max health
    showDamage = true,           -- Show creature damage range
    showArmor = false,           -- Show creature armor (disabled by default - can be noisy)
    
    -- Version tracking for migrations
    configVersion = 2            -- Increment when adding new settings that need migration
}

-- Initialize configuration with defaults if not already set
function AscensionVanity_InitConfig()
    -- Check version BEFORE applying defaults (so we can detect upgrades)
    local currentVersion = AscensionVanityDB.configVersion or 0
    
    -- First-time initialization: Apply all defaults (EXCEPT configVersion which we check separately)
    for key, value in pairs(defaults) do
        if key ~= "configVersion" and AscensionVanityDB[key] == nil then
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
    
    -- Migration System: Handle version upgrades
    if currentVersion < 2 then
        -- Migration to v2: Phase 2A Enhanced Creature Information
        -- Force-apply Phase 2A settings for users upgrading from pre-2.3 versions
        print(AV_COLOR_CYAN .. "[AscensionVanity] Upgrading config to v2 (Phase 2A features)..." .. AV_COLOR_RESET)
        
        -- Apply Phase 2A defaults if they don't exist
        local phase2ASettings = {
            "showCreatureInfo",
            "creatureInfoFilter", 
            "showCreatureType",
            "showAttackSpeed",
            "showHealth",
            "showDamage",
            "showArmor"
        }
        
        for _, setting in ipairs(phase2ASettings) do
            if AscensionVanityDB[setting] == nil then
                AscensionVanityDB[setting] = defaults[setting]
                print(AV_COLOR_GREEN .. "  ✓ Applied: " .. setting .. " = " .. tostring(defaults[setting]) .. AV_COLOR_RESET)
            end
        end
        
        AscensionVanityDB.configVersion = 2
        print(AV_COLOR_GREEN .. "[AscensionVanity] Config upgrade complete!" .. AV_COLOR_RESET)
    end
    
    -- Always ensure configVersion is set
    if not AscensionVanityDB.configVersion then
        AscensionVanityDB.configVersion = defaults.configVersion
    end
end

-- Call initialization when file loads
AscensionVanity_InitConfig()

-- Note: Settings UI has been moved to SettingsUI.lua for better code organization
