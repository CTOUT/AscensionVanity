-- AscensionVanity - Titan Scroll Filter Demo
-- Demonstrates filtering Titan Scroll announcements
-- This is a proof-of-concept for XanAscTweaks integration

-- Filter function for Titan Scroll messages
local function FilterTitanScrollMessages(self, event, msg, author, ...)
    -- Pattern matches: "[Titan Scroll] USER has blessed the world with Titan Scroll: Aggramar"
    if msg:find("%[.-Titan Scroll.-%]") then
        -- Check if filtering is enabled (use AV config for demo)
        if AscensionVanityDB.filterTitanScrolls then
            print("|cFFFF6B6B[FILTERED]|r " .. msg)  -- Show what we filtered in red
            return true  -- Filter out the message
        end
    end
    
    return false  -- Don't filter
end

-- Add filter to all relevant chat frames
local function SetupTitanScrollFilter()
    -- Filter system messages (where Titan Scroll announcements appear)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", FilterTitanScrollMessages)
    
    print("|cFF00FF96AscensionVanity:|r Titan Scroll filter demo loaded")
    print("  Use '/av titanscroll' to toggle filtering")
end

-- Wait for addon to load
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "AscensionVanity" then
        -- Initialize config if not exists
        if not AscensionVanityDB.filterTitanScrolls then
            AscensionVanityDB.filterTitanScrolls = false  -- Default: disabled
        end
        
        SetupTitanScrollFilter()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Add slash command for testing
SLASH_AVTITANSCROLL1 = "/avtitanscroll"
SlashCmdList["AVTITANSCROLL"] = function()
    AscensionVanityDB.filterTitanScrolls = not AscensionVanityDB.filterTitanScrolls
    
    local status = AscensionVanityDB.filterTitanScrolls and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
    print(string.format("|cFF00FF96AscensionVanity:|r Titan Scroll filtering: %s", status))
    
    if AscensionVanityDB.filterTitanScrolls then
        print("  Titan Scroll announcements will be filtered from chat")
    else
        print("  Titan Scroll announcements will appear normally")
    end
end

-- Test command to simulate a Titan Scroll message
SLASH_AVTITANTEST1 = "/avtitantest"
SlashCmdList["AVTITANTEST"] = function()
    local testMessage = "[Titan Scroll] TestPlayer has blessed the world with Titan Scroll: Aggramar"
    print("|cFF00FF96AscensionVanity:|r Simulating Titan Scroll message...")
    
    -- Send to the filter function manually for testing
    local filtered = FilterTitanScrollMessages(nil, "CHAT_MSG_SYSTEM", testMessage, "TestPlayer")
    
    if not filtered then
        print(testMessage)  -- Show normal message if not filtered
    end
end