-- AscensionVanity - Core Functionality
-- Hooks into tooltips to display vanity item information

local AddonName = "AscensionVanity"
local VERSION = "1.0.0"

-- Initialize saved variables
AscensionVanityDB = AscensionVanityDB or {
    enabled = true,
    showLearnedStatus = true,
    colorCode = true,
    debug = false,  -- Debug mode off by default
}

-- Color codes for tooltip text
local COLOR_VANITY_HEADER = "|cFF00FF96" -- Teal/cyan
local COLOR_VANITY_LEARNED = "|cFF00FF00" -- Green
local COLOR_VANITY_UNLEARNED = "|cFFFFFF00" -- Yellow
local COLOR_RESET = "|r"

-- Item type icons (icon IDs from Ascension database)
-- Icons verified from https://db.ascension.gg/?icon=<ID>
local ITEM_ICONS = {
    ["Beastmaster's Whistle"] = "|TInterface\\Icons\\ability_hunter_beastcall:16|t",  -- Icon 455
    ["Blood Soaked Vellum"] = "|TInterface\\Icons\\inv_glyph_primedeathknight:16|t",  -- Icon 13479
    ["Summoner's Stone"] = "|TInterface\\Icons\\inv_misc_uncutgemnormal1:16|t",  -- Icon 19474
    ["Draconic Warhorn"] = "|TInterface\\Icons\\inv_misc_horn_01:16|t",  -- Icon 1550
    ["Elemental Lodestone"] = "|TInterface\\Icons\\custom_t_nhance_rpg_icons_arcanestone_border:16|t",  -- Icon 62794
}

-- Local reference to GameTooltip
local tooltip = GameTooltip

-- Utility: Debug print (only prints if debug mode enabled)
local function DebugPrint(...)
    if AscensionVanityDB.debug then
        print("|cFF00FF96[AV Debug]|r", ...)
    end
end

-- Utility: Check if player has learned a vanity item
-- Uses Ascension's C_VanityCollection.IsCollectionItemOwned API
local function IsVanityItemLearned(itemID, itemName)
    if not itemID then
        return nil
    end
    
    -- Use Ascension's official vanity collection API
    if C_VanityCollection and C_VanityCollection.IsCollectionItemOwned then
        local isOwned = C_VanityCollection.IsCollectionItemOwned(itemID)
        DebugPrint("Item", itemID, "owned status:", isOwned)
        return isOwned
    end
    
    -- Fallback: API not available
    DebugPrint("C_VanityCollection.IsCollectionItemOwned not available")
    return nil
end

-- Utility: Get creature type from tooltip
local function GetCreatureTypeFromTooltip()
    -- Scan tooltip lines to find creature type
    -- Creature type typically appears on line 2 or 3
    for i = 2, tooltip:NumLines() do
        local line = _G["GameTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                -- Check if this line contains a known creature type
                for typeName, _ in pairs(AV_GenericDropsByType) do
                    if string.find(text, typeName) then
                        return typeName
                    end
                end
            end
        end
    end
    return nil
end

-- Core: Add vanity item information to tooltip
local function AddVanityInfoToTooltip(tooltip, unit)
    if not AscensionVanityDB.enabled then
        return
    end
    
    if not unit then
        return
    end
    
    -- Get creature ID from GUID (more reliable than name)
    local guid = UnitGUID(unit)
    if not guid then
        return
    end
    
    -- Extract creature ID from GUID
    -- Ascension uses hex GUID format: 0xF130001D0DC005B0F
    -- Creature ID is embedded in the hex value
    -- Format: 0x [F1] [3000] [1D0DC0] [05B0F]
    --            ^    ^      ^        ^
    --            |    |      |        spawn UID
    --            |    |      creature ID (middle 6 hex digits)
    --            |    type
    --            flags
    
    local creatureID = nil
    
    -- Convert hex GUID to number and extract creature ID
    if guid and type(guid) == "string" then
        DebugPrint("GUID:", guid)
        
        -- Remove 0x prefix if present
        local hexGuid = guid:gsub("^0x", "")
        
        -- Extract creature ID from hex GUID (bits 32-63, middle section)
        -- For 0xF130001D0DC005B0F, creature ID is 0x1D0DC0 = 1904064
        if #hexGuid >= 10 then
            local creatureIDHex = hexGuid:sub(5, 10)  -- Get middle 6 hex digits
            creatureID = tonumber(creatureIDHex, 16)  -- Convert from hex to decimal
            DebugPrint("Creature ID:", creatureID, "(hex:", creatureIDHex, ")")
        end
    end
    
    if not creatureID then
        return
    end
    
    -- Check if this is an NPC (not a player, pet, etc.)
    if not UnitIsPlayer(unit) and UnitExists(unit) then
        -- Look up vanity items for this creature by ID
        local vanityItems = AV_GetVanityItemsForCreature(creatureID)
        
        DebugPrint("Found", vanityItems and #vanityItems or 0, "items for creature", creatureID)
        
        if vanityItems and #vanityItems > 0 then
            -- Add separator line
            tooltip:AddLine(" ")
            
            -- Add header
            tooltip:AddLine(COLOR_VANITY_HEADER .. "Vanity Items:" .. COLOR_RESET)
            
            -- Add each vanity item
            for _, itemID in ipairs(vanityItems) do
                -- Fetch localized item name from game API (language-independent)
                local itemName = GetItemInfo(itemID)
                if not itemName then
                    -- Item not yet cached, skip for now
                    -- Game will cache it and show on next tooltip
                    itemName = "Loading..."
                end
                
                -- Extract item type from name to get the icon
                local itemIcon = ""
                for itemType, icon in pairs(ITEM_ICONS) do
                    if string.find(itemName, itemType, 1, true) then
                        itemIcon = icon .. " "
                        break
                    end
                end
                
                local itemText = itemIcon .. itemName
                
                -- Check if player has learned this item (optional feature)
                if AscensionVanityDB.showLearnedStatus then
                    local isLearned = IsVanityItemLearned(itemID, itemName)
                    
                    if isLearned == true then
                        -- Learned: Green with WoW checkmark icon
                        local checkmark = "|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t"
                        if AscensionVanityDB.colorCode then
                            itemText = COLOR_VANITY_LEARNED .. checkmark .. " " .. itemText .. COLOR_RESET
                        else
                            itemText = checkmark .. " " .. itemText
                        end
                    elseif isLearned == false then
                        -- Unlearned: Yellow, no indicator (just color difference)
                        if AscensionVanityDB.colorCode then
                            itemText = COLOR_VANITY_UNLEARNED .. "   " .. itemText .. COLOR_RESET
                        else
                            itemText = "   " .. itemText
                        end
                    else
                        -- Unknown status: Default color, no indicator
                        itemText = "   " .. itemText
                    end
                else
                    -- Learned status disabled: No indicator, default color
                    itemText = "   " .. itemText
                end
                
                tooltip:AddLine(itemText, 1, 1, 1, true) -- White text, word wrap enabled
            end
            
            -- Show tooltip updates
            tooltip:Show()
        end
    end
end

-- Hook into tooltip display
local function OnTooltipSetUnit(tooltip)
    local _, unit = tooltip:GetUnit()
    if unit then
        AddVanityInfoToTooltip(tooltip, unit)
    end
end

-- Event handler for addon initialization
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == AddonName then
        -- Addon loaded
        print("|cFF00FF96AscensionVanity|r v" .. VERSION .. " loaded!")
        print("Type |cFFFFFF00/av help|r for commands")
        
    elseif event == "PLAYER_LOGIN" then
        -- Hook into GameTooltip after player login
        GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
        
        -- Also hook into other tooltip types if needed
        -- GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
    end
end)

-- Slash commands
SLASH_ASCENSIONVANITY1 = "/av"
SLASH_ASCENSIONVANITY2 = "/ascensionvanity"

SlashCmdList["ASCENSIONVANITY"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "toggle" or msg == "" then
        AscensionVanityDB.enabled = not AscensionVanityDB.enabled
        if AscensionVanityDB.enabled then
            print("|cFF00FF96AscensionVanity:|r Enabled")
        else
            print("|cFF00FF96AscensionVanity:|r Disabled")
        end
        
    elseif msg == "learned" then
        AscensionVanityDB.showLearnedStatus = not AscensionVanityDB.showLearnedStatus
        if AscensionVanityDB.showLearnedStatus then
            print("|cFF00FF96AscensionVanity:|r Learned status display enabled")
        else
            print("|cFF00FF96AscensionVanity:|r Learned status display disabled")
        end
        
    elseif msg == "color" then
        AscensionVanityDB.colorCode = not AscensionVanityDB.colorCode
        if AscensionVanityDB.colorCode then
            print("|cFF00FF96AscensionVanity:|r Color coding enabled")
        else
            print("|cFF00FF96AscensionVanity:|r Color coding disabled")
        end
        
    elseif msg == "debug" then
        AscensionVanityDB.debug = not AscensionVanityDB.debug
        if AscensionVanityDB.debug then
            print("|cFF00FF96AscensionVanity:|r Debug mode enabled")
        else
            print("|cFF00FF96AscensionVanity:|r Debug mode disabled")
        end
        
    elseif msg == "api" then
        -- Scan for Ascension's vanity collection API
        print("|cFF00FF96AscensionVanity:|r Scanning for Ascension vanity APIs...")
        
        -- Check for C_VanityCollection
        if C_VanityCollection then
            print("  |cFF00FF00Found:|r C_VanityCollection")
            for k, v in pairs(C_VanityCollection) do
                print("    - C_VanityCollection." .. k .. " (" .. type(v) .. ")")
            end
        else
            print("  |cFFFF0000Not found:|r C_VanityCollection")
        end
        
        -- Check for common global functions
        local checkFunctions = {
            "IsVanityCollected",
            "HasVanityItem",
            "GetVanityItemInfo",
            "C_Vanity",
            "VanityCollection_IsCollected"
        }
        
        for _, funcName in ipairs(checkFunctions) do
            if _G[funcName] then
                print("  |cFF00FF00Found:|r " .. funcName .. " (" .. type(_G[funcName]) .. ")")
            end
        end
        
    elseif msg == "help" then
        print("|cFF00FF96AscensionVanity v" .. VERSION .. " Commands:|r")
        print("  |cFFFFFF00/av|r or |cFFFFFF00/av toggle|r - Toggle addon on/off")
        print("  |cFFFFFF00/av learned|r - Toggle learned status display")
        print("  |cFFFFFF00/av color|r - Toggle color coding")
        print("  |cFFFFFF00/av debug|r - Toggle debug mode")
        print("  |cFFFFFF00/av api|r - Scan for Ascension vanity APIs (debug)")
        print("  |cFFFFFF00/av help|r - Show this help")
        
    else
        print("|cFF00FF96AscensionVanity:|r Unknown command. Type |cFFFFFF00/av help|r for help")
    end
end
