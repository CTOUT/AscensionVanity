-- AscensionVanity - Database Loader V2
-- Provides access functions for the vanity items database
-- Database files: VanityDB.lua, VanityDB_Regions.lua (optional)

-- Forward declarations (actual data loaded from separate files)
AV_VanityItems = AV_VanityItems or {}
AV_Regions = AV_Regions or {}
AV_IconList = AV_IconList or {}  -- Icon lookup table

-- Build reverse lookup: creatureID -> itemIDs
-- This is generated on-demand for performance
local creatureLookup = nil

local function BuildCreatureLookup()
    if creatureLookup then
        return  -- Already built
    end
    
    creatureLookup = {}
    
    for itemId, itemData in pairs(AV_VanityItems) do
        local creatureId = itemData.creaturePreview
        if creatureId and creatureId > 0 then
            if not creatureLookup[creatureId] then
                creatureLookup[creatureId] = {}
            end
            table.insert(creatureLookup[creatureId], itemId)
        end
    end
end

-- Get all vanity items dropped by a specific creature
-- Returns: array of itemIDs, or nil if creature drops nothing
function AV_GetVanityItemsForCreature(creatureID)
    if not creatureID or creatureID == 0 then
        return nil
    end
    
    -- Build lookup table on first use
    BuildCreatureLookup()
    
    return creatureLookup[creatureID]
end

-- Get full item data by itemID
-- Returns: table with { itemid, name, creaturePreview, description, icon }
-- Note: icon is resolved from AV_IconList if it's a number
function AV_GetItemData(itemID)
    if not itemID then
        return nil
    end
    
    local itemData = AV_VanityItems[itemID]
    if not itemData then
        return nil
    end
    
    -- Create a copy to avoid modifying the original
    local result = {}
    for k, v in pairs(itemData) do
        result[k] = v
    end
    
    -- Resolve icon if it's an index
    if result.icon and type(result.icon) == "number" then
        result.icon = AV_IconList[result.icon] or result.icon
    end
    
    return result
end

-- Get item name by itemID
function AV_GetItemName(itemID)
    local itemData = AV_GetItemData(itemID)
    return itemData and itemData.name or nil
end

-- Get creature ID for an item
function AV_GetItemCreature(itemID)
    local itemData = AV_GetItemData(itemID)
    return itemData and itemData.creaturePreview or nil
end

-- Get region/location for an item (optional, requires VanityDB_Regions.lua)
function AV_GetItemRegion(itemID)
    if not itemID then
        return nil
    end
    
    return AV_Regions[itemID]
end

-- Get total count of vanity items in database
function AV_GetTotalItems()
    local count = 0
    for _ in pairs(AV_VanityItems) do
        count = count + 1
    end
    return count
end

-- Database statistics (for debugging)
function AV_GetDatabaseStats()
    local itemCount = AV_GetTotalItems()
    local regionCount = 0
    for _ in pairs(AV_Regions) do
        regionCount = regionCount + 1
    end
    
    BuildCreatureLookup()
    local creatureCount = 0
    for _ in pairs(creatureLookup) do
        creatureCount = creatureCount + 1
    end
    
    return {
        items = itemCount,
        regions = regionCount,
        creatures = creatureCount
    }
end
