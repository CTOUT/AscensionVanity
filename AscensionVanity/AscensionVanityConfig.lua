-- AscensionVanity Configuration
-- User-editable settings for the addon

AscensionVanityDB = AscensionVanityDB or {}

-- Default configuration values
local defaults = {
    enabled = true,              -- Enable/disable the addon
    colorCode = true,            -- Color-code tooltip text based on learned status
    showLearnedStatus = true,    -- Show "Learned" or "Not Learned" in tooltips
    showRegions = false,         -- Show region/location information in tooltips (not yet implemented)
    debug = false                -- Enable debug logging
}

-- Initialize configuration with defaults if not already set
function AscensionVanity_InitConfig()
    for key, value in pairs(defaults) do
        if AscensionVanityDB[key] == nil then
            AscensionVanityDB[key] = value
        end
    end
end

-- Call initialization when file loads
AscensionVanity_InitConfig()

-- Note: Settings UI has been moved to SettingsUI.lua for better code organization
