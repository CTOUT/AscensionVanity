-- TEST SCRIPT: Dump ALL fields from C_VanityCollection API
-- Purpose: Discover if pet family/type information is available
--
-- USAGE:
--   1. Copy this file to WoW AddOns folder
--   2. In-game: /run LoadAddOn("TEST_API_Fields")
--   3. Look in SavedVariables/TEST_API_Fields.lua for full field dump

TEST_API_FieldDump = {}

local function DumpAPIFields()
    print("Dumping C_VanityCollection API fields...")
    
    local allItems = C_VanityCollection.GetAllItems() or {}
    local sampleSize = math.min(10, #allItems)  -- Sample first 10 items
    
    print("Found " .. #allItems .. " total items")
    print("Sampling first " .. sampleSize .. " items...")
    
    for i = 1, sampleSize do
        local itemData = allItems[i]
        if type(itemData) == "table" then
            -- Dump ALL fields from this item
            local fields = {}
            for key, value in pairs(itemData) do
                fields[key] = {
                    type = type(value),
                    value = tostring(value)
                }
            end
            
            table.insert(TEST_API_FieldDump, {
                index = i,
                itemName = itemData.name or "Unknown",
                itemId = itemData.itemid or 0,
                allFields = fields
            })
        end
    end
end
    
    print("Sample dump complete! Check SavedVariables/TEST_API_Fields.lua")
    print("Fields found in first item:")
    if TEST_API_FieldDump[1] then
        for fieldName, fieldData in pairs(TEST_API_FieldDump[1].allFields) do
            print("  - " .. fieldName .. " (" .. fieldData.type .. "): " .. fieldData.value)
        end
    end
end

-- Auto-run on load
C_Timer.After(1, DumpAPIFields)
