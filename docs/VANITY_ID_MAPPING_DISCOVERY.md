# Vanity ID Mapping Discovery Commands

## Quick In-Game Test

Paste these commands one at a time in-game to discover the mapping:

### 1. Check Available Functions
```lua
/run for k,v in pairs(C_VanityCollection) do print(k, type(v)) end
```

### 2. Test GetAllItems (if it exists)
```lua
/run if C_VanityCollection.GetAllItems then local items = C_VanityCollection.GetAllItems(); if items then print("Total items:", #items); if items[1] then for k,v in pairs(items[1]) do print("  Field:", k, "=", v) end end end end
```

### 3. Test with Your Known IDs
```lua
/run local vanityID, itemID = 50807, 79465; print("Testing vanity ID:", vanityID); print("Testing item ID:", itemID)
```

### 4. Try GetItem with Both IDs
```lua
/run local v = C_VanityCollection.GetItem(50807); if v then print("VanityID 50807:"); for k,val in pairs(v) do print("  ", k, "=", val) end end
```

```lua
/run local v = C_VanityCollection.GetItem(79465); if v then print("ItemID 79465:"); for k,val in pairs(v) do print("  ", k, "=", val) end end
```

### 5. Search for "itemId" or "spellId" Fields
```lua
/run if C_VanityCollection.GetAllItems then local items = C_VanityCollection.GetAllItems(); for i=1,math.min(5, #items) do local item = items[i]; if type(item) == "table" then print("Item", i, ":"); for k,v in pairs(item) do if string.find(string.lower(k), "id") then print("  ", k, "=", v) end end end end end
```

### 6. Check for Type-Specific Functions
```lua
/run local funcs = {"GetItemsByType", "GetPetCollection", "GetCosmeticPets"}; for _,f in ipairs(funcs) do if C_VanityCollection[f] then print("FOUND:", f) else print("Not found:", f) end end
```

## What We're Looking For

The API function should return data like this:
```lua
{
    vanityId = 50807,        -- ID from APPEARANCE_COLLECTED
    itemId = 79465,          -- Game item ID we use
    spellId = <number>,      -- Spell that teaches it
    type = "COSMETIC_PET",   -- Type discovered in event trace
    name = "Beastmaster's Whistle: Young Scavenger"
}
```

## Building the Mapping

Once we find the right function/structure, we can build:
```lua
local vanityToItemMap = {}

-- Populate map from API
local allItems = C_VanityCollection.GetAllItems() -- or whatever the function is
for _, itemData in ipairs(allItems) do
    if itemData.vanityId and itemData.itemId then
        vanityToItemMap[itemData.vanityId] = itemData.itemId
    end
end

-- Then in APPEARANCE_COLLECTED handler:
local vanityID = 50807  -- from event
local itemID = vanityToItemMap[vanityID]  -- mapped!
if itemID then
    ClearCacheForItem(itemID)  -- Clear correct cache entry!
end
```

## Expected Outcome

If successful, we can:
1. Build a complete vanityID → itemID mapping table
2. Clear specific cache entries (targeted clearing!)
3. Keep the performance optimization
4. Get instant status updates

## Fallback

If no mapping is possible:
- Revert to full cache clear (simple, reliable)
- Still get instant updates via APPEARANCE_COLLECTED
- Still 90%+ performance gain from caching
