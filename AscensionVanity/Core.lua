-- AscensionVanity - Core Functionality
-- Hooks into tooltips to display vanity item information

local AddonName = "AscensionVanity"
local VERSION = "1.0.0"

-- Initialize saved variables
AscensionVanityDB = AscensionVanityDB or {
    enabled = true,
    showLearnedStatus = true,
    colorCode = true,
}

-- Color codes for tooltip text
local COLOR_VANITY_HEADER = "|cFF00FF96" -- Teal/cyan
local COLOR_VANITY_LEARNED = "|cFF00FF00" -- Green
local COLOR_VANITY_UNLEARNED = "|cFFFFFF00" -- Yellow
local COLOR_RESET = "|r"

-- Local reference to GameTooltip
local tooltip = GameTooltip

-- Utility: Check if player has learned a vanity item
-- Note: This will need to be adapted to Project Ascension's specific API
local function IsVanityItemLearned(itemID, itemName)
    -- TODO: Replace with actual Ascension API call
    -- Possible approaches:
    -- 1. Check if item is in player's collection
    -- 2. Use custom Ascension API if available
    -- 3. Scan player's spellbook/pet journal
    
    -- For now, return nil (unknown status)
    -- When Ascension API is known, implement proper check here
    
    -- Example pattern for standard WoW (won't work on Ascension without modification):
    -- if itemID then
    --     return C_PetJournal.GetNumCollectedInfo(itemID) > 0
    -- end
    
    return nil -- Unknown status
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
    -- GUID format: Creature-0-[server]-[instance]-[counter]-[creatureID]-[spawnUID]
    local creatureID = tonumber(select(6, strsplit("-", guid)))
    if not creatureID then
        return
    end
    
    -- Check if this is an NPC (not a player, pet, etc.)
    if not UnitIsPlayer(unit) and UnitExists(unit) then
        -- Look up vanity items for this creature by ID
        local vanityItems = AV_GetVanityItemsForCreature(creatureID)
        
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
                
                local itemText = itemName
                
                -- Check if player has learned this item (optional feature)
                if AscensionVanityDB.showLearnedStatus then
                    local isLearned = IsVanityItemLearned(itemID, itemName)
                    
                    if isLearned == true then
                        if AscensionVanityDB.colorCode then
                            itemText = COLOR_VANITY_LEARNED .. "✓ " .. itemText .. COLOR_RESET
                        else
                            itemText = "✓ " .. itemText
                        end
                    elseif isLearned == false then
                        if AscensionVanityDB.colorCode then
                            itemText = COLOR_VANITY_UNLEARNED .. "✗ " .. itemText .. COLOR_RESET
                        else
                            itemText = "✗ " .. itemText
                        end
                    else
                        -- Unknown status, just show the item
                        itemText = "  " .. itemText
                    end
                else
                    itemText = "• " .. itemText
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
        
    elseif msg == "help" then
        print("|cFF00FF96AscensionVanity v" .. VERSION .. " Commands:|r")
        print("  |cFFFFFF00/av|r or |cFFFFFF00/av toggle|r - Toggle addon on/off")
        print("  |cFFFFFF00/av learned|r - Toggle learned status display")
        print("  |cFFFFFF00/av color|r - Toggle color coding")
        print("  |cFFFFFF00/av help|r - Show this help")
        
    else
        print("|cFF00FF96AscensionVanity:|r Unknown command. Type |cFFFFFF00/av help|r for help")
    end
end

-- Debug function (can be removed in production)
function AV_Debug(creatureName, creatureType)
    print("=== AscensionVanity Debug ===")
    print("Creature Name:", creatureName or "nil")
    print("Creature Type:", creatureType or "nil")
    
    local items = AV_GetVanityItemsForCreature(creatureName, creatureType)
    print("Found", #items, "vanity items")
    
    for i, item in ipairs(items) do
        print("  " .. i .. ":", item.itemName)
    end
end
