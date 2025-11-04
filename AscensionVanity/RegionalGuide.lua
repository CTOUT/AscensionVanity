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
    
    print(AV_COLOR_BLUE .. "══════════════════════════════" .. AV_COLOR_RESET)
    print(AV_COLOR_GREEN .. "[" .. (location.zone or "Unknown Zone") .. " - Unlearned Vanity Items]" .. AV_COLOR_RESET)
    print(AV_COLOR_BLUE .. "══════════════════════════════" .. AV_COLOR_RESET)
    
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
            
            print(AV_COLOR_ORANGE .. "- " .. creatureName .. AV_COLOR_GRAY .. " (ID: " .. creatureId .. ")" .. AV_COLOR_RESET)
            
            for _, item in ipairs(creatureItemList) do
                print("  " .. AV_COLOR_WHITE .. "→ " .. item.name .. AV_COLOR_RESET)
                if item.subzone and item.subzone ~= "" then
                    print("     " .. AV_COLOR_GRAY .. "Location: " .. item.subzone .. AV_COLOR_RESET)
                end
            end
            print("")  -- Blank line between creatures
        end
        
        print(AV_COLOR_BLUE .. "──────────────────────────────" .. AV_COLOR_RESET)
        
        -- Count creatures (can't use # on hash tables, need to iterate)
        local creatureCount = 0
        for _ in pairs(creatureItems) do
            creatureCount = creatureCount + 1
        end
        
        print(AV_COLOR_YELLOW .. "(" .. #items .. " unlearned item(s) from " .. creatureCount .. " creature(s))" .. AV_COLOR_RESET)
    end
    
    print(AV_COLOR_BLUE .. "══════════════════════════════" .. AV_COLOR_RESET)
end

-- ============================================================================
-- Zone-Based Collection Progress (for Progress Frame)
-- ============================================================================

-- Get collection progress for the current zone, grouped by category
function AV_GetZoneCollectionProgress()
    local location = GetCurrentLocation()
    local zoneName = location.zone
    
    -- Debug: Print what zone we're looking for
    print(AV_COLOR_YELLOW .. "[DEBUG] Looking for zone: '" .. tostring(zoneName) .. "'" .. AV_COLOR_RESET)
    
    -- If no zone data, return global progress
    if not zoneName or zoneName == "" then
        print(AV_COLOR_RED .. "[DEBUG] No zone name detected, using global" .. AV_COLOR_RESET)
        if AV_GetCollectionProgress then
            return AV_GetCollectionProgress()
        end
        return {}
    end
    
    -- Get ALL items from zone index (not just unlearned)
    local zoneItems = zoneIndex[zoneName]
    
    -- Debug: Print zone index info
    if not zoneItems then
        print(AV_COLOR_RED .. "[DEBUG] Zone not found in index!" .. AV_COLOR_RESET)
        -- Print first 10 zones we DO have
        local count = 0
        print(AV_COLOR_GRAY .. "[DEBUG] Available zones:" .. AV_COLOR_RESET)
        for zone, items in pairs(zoneIndex) do
            count = count + 1
            if count <= 10 then
                print(AV_COLOR_GRAY .. "  - '" .. zone .. "' (" .. #items .. " items)" .. AV_COLOR_RESET)
            end
        end
    else
        print(AV_COLOR_GREEN .. "[DEBUG] Found " .. #zoneItems .. " items in zone" .. AV_COLOR_RESET)
    end
    
    if not zoneItems or #zoneItems == 0 then
        -- No items in this zone, return empty progress
        return {
            overall = { learned = 0, total = 0 },
            beast = { learned = 0, total = 0 },
            demon = { learned = 0, total = 0 },
            undead = { learned = 0, total = 0 },
            dragonkin = { learned = 0, total = 0 },
            elemental = { learned = 0, total = 0 }
        }
    end
    
    -- Initialize progress counters
    local progress = {
        overall = { learned = 0, total = 0 },
        beast = { learned = 0, total = 0 },
        demon = { learned = 0, total = 0 },
        undead = { learned = 0, total = 0 },
        dragonkin = { learned = 0, total = 0 },
        elemental = { learned = 0, total = 0 }
    }
    
    -- Count ALL items in this zone by category
    for _, itemId in ipairs(zoneItems) do
        local data = AV_VanityItems[itemId]
        if data and data.category then
            local cat = data.category:lower()
            if progress[cat] then
                progress[cat].total = progress[cat].total + 1
                progress.overall.total = progress.overall.total + 1
                
                -- Check if learned
                if IsItemLearned(itemId) then
                    progress[cat].learned = progress[cat].learned + 1
                    progress.overall.learned = progress.overall.learned + 1
                end
            end
        end
    end
    
    return progress
end

-- Get detailed zone items grouped by creature and category (for expanded view)
function AV_GetZoneItemsByCategory()
    local location = GetCurrentLocation()
    local items = GetUnlearnedItemsInZone(location.zone)
    
    -- Group by category, then by creature
    local categoryGroups = {
        beast = {},
        demon = {},
        undead = {},
        dragonkin = {},
        elemental = {}
    }
    
    for _, item in ipairs(items) do
        local data = AV_VanityItems[item.itemId]
        if data and data.category then
            local cat = data.category:lower()
            if categoryGroups[cat] then
                local creatureId = item.creatureId
                if not categoryGroups[cat][creatureId] then
                    categoryGroups[cat][creatureId] = {
                        creatureId = creatureId,
                        items = {}
                    }
                end
                table.insert(categoryGroups[cat][creatureId].items, {
                    itemId = item.itemId,
                    name = item.name,
                    subzone = item.subzone
                })
            end
        end
    end
    
    return categoryGroups, location.zone
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
        
        -- Update progress frame if it's open and in zone view
        if _G.AV_UpdateProgressBars then
            _G.AV_UpdateProgressBars()
        end
        
        -- Optional: Auto-show items in new zone
        -- (Disabled by default to avoid spam)
        -- AscensionVanity_ShowCurrentZoneItems()
    end
end)
