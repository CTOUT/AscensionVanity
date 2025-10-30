-- ============================================================================
-- Vanity Collection ID Mapping Discovery Script
-- ============================================================================
-- 
-- PURPOSE: Discover how to map between:
--   - Vanity Collection IDs (from APPEARANCE_COLLECTED event)
--   - Game Item IDs (used by tooltips and our cache)
--
-- DISCOVERED: APPEARANCE_TYPE_COSMETIC_PET in event trace
-- This suggests there's a type system we can use!
--
-- RUN THIS IN-GAME: /run dofile("path/to/DiscoverVanityIDMapping.lua")
-- ============================================================================

print("=== Vanity Collection API Discovery ===")
print(" ")

-- Check what's available in C_VanityCollection
if not C_VanityCollection then
    print("ERROR: C_VanityCollection not found!")
    return
end

print("Available C_VanityCollection functions:")
for funcName, func in pairs(C_VanityCollection) do
    print("  - " .. funcName .. " (" .. type(func) .. ")")
end
print(" ")

-- Test cases using known IDs
local knownVanityID = 50807  -- From APPEARANCE_COLLECTED event
local knownItemID = 79465    -- Young Scavenger whistle

print("=== Testing with Known IDs ===")
print("Vanity ID:", knownVanityID)
print("Item ID:", knownItemID)
print(" ")

-- Try GetAllItems (if it exists)
if C_VanityCollection.GetAllItems then
    print("GetAllItems() exists! Trying to call it...")
    local success, result = pcall(C_VanityCollection.GetAllItems)
    
    if success and result then
        print("GetAllItems() returned:", type(result))
        
        if type(result) == "table" then
            print("Table size:", #result, "entries")
            
            -- Look for our known IDs in the results
            for i = 1, math.min(10, #result) do
                local item = result[i]
                if type(item) == "table" then
                    print("  Item", i, ":")
                    for k, v in pairs(item) do
                        print("    ", k, "=", v, "(" .. type(v) .. ")")
                        
                        -- Check if this matches our known IDs
                        if v == knownVanityID then
                            print("      *** FOUND vanityID", knownVanityID, "in field:", k)
                        end
                        if v == knownItemID then
                            print("      *** FOUND itemID", knownItemID, "in field:", k)
                        end
                    end
                end
            end
        end
    else
        print("GetAllItems() failed:", result)
    end
    print(" ")
end

-- Try GetItem with both IDs
if C_VanityCollection.GetItem then
    print("=== Testing GetItem() ===")
    
    -- Try vanity ID
    print("GetItem(", knownVanityID, ") - vanity ID:")
    local success, result = pcall(C_VanityCollection.GetItem, knownVanityID)
    if success and result then
        if type(result) == "table" then
            for k, v in pairs(result) do
                print("  ", k, "=", v)
            end
        else
            print("  Result:", result)
        end
    else
        print("  Failed or nil")
    end
    print(" ")
    
    -- Try item ID
    print("GetItem(", knownItemID, ") - item ID:")
    success, result = pcall(C_VanityCollection.GetItem, knownItemID)
    if success and result then
        if type(result) == "table" then
            for k, v in pairs(result) do
                print("  ", k, "=", v)
            end
        else
            print("  Result:", result)
        end
    else
        print("  Failed or nil")
    end
    print(" ")
end

-- Try GetItemInfo (if it exists)
if C_VanityCollection.GetItemInfo then
    print("=== Testing GetItemInfo() ===")
    
    print("GetItemInfo(", knownVanityID, "):")
    local success, result = pcall(C_VanityCollection.GetItemInfo, knownVanityID)
    if success and result then
        if type(result) == "table" then
            for k, v in pairs(result) do
                print("  ", k, "=", v)
            end
        else
            print("  Result:", result)
        end
    else
        print("  Failed or nil")
    end
    print(" ")
end

-- Try IsCollectionItemOwned with both IDs
print("=== Testing IsCollectionItemOwned() ===")
print("IsCollectionItemOwned(", knownVanityID, "):", C_VanityCollection.IsCollectionItemOwned(knownVanityID))
print("IsCollectionItemOwned(", knownItemID, "):", C_VanityCollection.IsCollectionItemOwned(knownItemID))
print(" ")

-- Look for type-related functions
print("=== Looking for Type/Category Functions ===")
local typeFunctions = {
    "GetItemsByType",
    "GetCollectionByType",
    "GetPetCollection",
    "GetMountCollection",
    "GetCosmeticPets",
    "GetAppearancesByType",
    "GetVanityByType"
}

for _, funcName in ipairs(typeFunctions) do
    if C_VanityCollection[funcName] then
        print("  FOUND:", funcName)
    end
end
print(" ")

print("=== Discovery Complete ===")
print("Review the output above to find mapping fields!")
