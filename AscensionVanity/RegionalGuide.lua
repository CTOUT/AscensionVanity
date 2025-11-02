-- AscensionVanity - Regional Hunting Guide
-- Shows creatures in the player's current zone that drop unlearned vanity items

local AddonName = "AscensionVanity"

-- ============================================================================
-- Zone Index (Built on Load)
-- ============================================================================

-- Zone index: [zoneName] = { itemIds }
local zoneIndex = {}

-- Subzone index: [subzoneName] = { itemIds }
local subzoneIndex = {}

-- Build zone and subzone indexes from VanityDB
local function BuildZoneIndexes()
    wipe(zoneIndex)
    wipe(subzoneIndex)
    
    for itemId, data in pairs(AV_VanityItems) do
        -- Index by zone
        if data.zone and data.zone ~= "" then
            if not zoneIndex[data.zone] then
                zoneIndex[data.zone] = {}
            end
            table.insert(zoneIndex[data.zone], itemId)
        end
        
        -- Index by subzone
        if data.subzone and data.subzone ~= "" then
            if not subzoneIndex[data.subzone] then
                subzoneIndex[data.subzone] = {}
            end
            table.insert(subzoneIndex[data.subzone], itemId)
        end
    end
    
    -- Debug output
    local zoneCount = 0
    for _ in pairs(zoneIndex) do zoneCount = zoneCount + 1 end
    local subzoneCount = 0
    for _ in pairs(subzoneIndex) do subzoneCount = subzoneCount + 1 end
    
    print(AV_COLOR_GREEN .. "[AscensionVanity]" .. AV_COLOR_RESET .. " Regional Guide initialized: " .. zoneCount .. " zones, " .. subzoneCount .. " subzones")
end

-- ============================================================================
-- Zone Detection
-- ============================================================================

-- Get the player's current zone and subzone
local function GetCurrentLocation()
    local zone = GetZoneText() or ""
    local subzone = GetSubZoneText() or ""
    local minimap = GetMinimapZoneText() or ""
    
    return {
        zone = zone,
        subzone = subzone,
        minimap = minimap
    }
end

-- ============================================================================
-- Item Filtering
-- ============================================================================

-- Check if an item is learned using the C_VanityCollection API
local function IsItemLearned(itemId)
    if not C_VanityCollection then
        return false  -- API not available, assume not learned
    end
    
    if not C_VanityCollection.IsVanityItemCollected then
        return false  -- Function not available
    end
    
    return C_VanityCollection.IsVanityItemCollected(itemId) or false
end

-- Get unlearned items in the current zone
local function GetUnlearnedItemsInZone(zoneName)
    local items = {}
    
    if not zoneName or zoneName == "" then
        return items
    end
    
    -- Get items from zone index
    local zoneItems = zoneIndex[zoneName]
    if not zoneItems then
        return items
    end
    
    -- Filter to unlearned items
    for _, itemId in ipairs(zoneItems) do
        if not IsItemLearned(itemId) then
            local data = AV_VanityItems[itemId]
            if data then
                table.insert(items, {
                    itemId = itemId,
                    name = data.name,
                    creatureId = data.creatureId,
                    zone = data.zone,
                    subzone = data.subzone,
                    description = data.description
                })
            end
        end
    end
    
    return items
end

-- ============================================================================
-- Public API
-- ============================================================================

-- Initialize the regional guide (call on PLAYER_LOGIN)
function AscensionVanity_InitRegionalGuide()
    BuildZoneIndexes()
end

-- Get unlearned items in the player's current zone
function AscensionVanity_GetCurrentZoneItems()
    local location = GetCurrentLocation()
    return GetUnlearnedItemsInZone(location.zone)
end

-- Slash command to show current zone items
function AscensionVanity_ShowCurrentZoneItems()
    local location = GetCurrentLocation()
    local items = GetUnlearnedItemsInZone(location.zone)
    
    print(AV_COLOR_BLUE .. "════════════════════════════════════════" .. AV_COLOR_RESET)
    print(AV_COLOR_GREEN .. "[" .. (location.zone or "Unknown Zone") .. " - Unlearned Vanity Items]" .. AV_COLOR_RESET)
    print(AV_COLOR_BLUE .. "════════════════════════════════════════" .. AV_COLOR_RESET)
    
    if #items == 0 then
        print(AV_COLOR_YELLOW .. "No unlearned vanity items found in this zone." .. AV_COLOR_RESET)
        print(AV_COLOR_GRAY .. "Either you've learned everything here, or this zone has no vanity drops!" .. AV_COLOR_RESET)
    else
        -- Group by creature
        local creatureItems = {}
        for _, item in ipairs(items) do
            local creatureId = item.creatureId
            if not creatureItems[creatureId] then
                creatureItems[creatureId] = {}
            end
            table.insert(creatureItems[creatureId], item)
        end
        
        -- Display grouped by creature
        for creatureId, creatureItemList in pairs(creatureItems) do
            local firstItem = creatureItemList[1]
            
            -- Extract creature name from item name (remove prefix)
            local creatureName = firstItem.name:match(":%s*(.+)$") or firstItem.name
            
            print(AV_COLOR_ORANGE .. "• " .. creatureName .. AV_COLOR_GRAY .. " (ID: " .. creatureId .. ")" .. AV_COLOR_RESET)
            
            for _, item in ipairs(creatureItemList) do
                print("  " .. AV_COLOR_WHITE .. "→ " .. item.name .. AV_COLOR_RESET)
                if item.subzone and item.subzone ~= "" then
                    print("     " .. AV_COLOR_GRAY .. "Location: " .. item.subzone .. AV_COLOR_RESET)
                end
            end
            print("")  -- Blank line between creatures
        end
        
        print(AV_COLOR_BLUE .. "────────────────────────────────────────" .. AV_COLOR_RESET)
        print(AV_COLOR_YELLOW .. "(" .. #items .. " unlearned item(s) from " .. table.getn(creatureItems) .. " creature(s))" .. AV_COLOR_RESET)
    end
    
    print(AV_COLOR_BLUE .. "════════════════════════════════════════" .. AV_COLOR_RESET)
end

-- ============================================================================
-- Zone Change Detection
-- ============================================================================

-- Frame for zone change events
local zoneFrame = CreateFrame("Frame")
zoneFrame:RegisterEvent("ZONE_CHANGED")
zoneFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
zoneFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- Store last zone to detect changes
local lastZone = nil

zoneFrame:SetScript("OnEvent", function(self, event)
    local currentZone = GetZoneText()
    
    -- Only notify if zone actually changed
    if currentZone ~= lastZone then
        lastZone = currentZone
        
        -- Optional: Auto-show items in new zone
        -- (Disabled by default to avoid spam)
        -- AscensionVanity_ShowCurrentZoneItems()
    end
end)
