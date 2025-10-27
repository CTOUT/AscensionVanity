# 🛠️ Developer Console Reference

**Tools Available**: Ascension UI Development Tools + Dev Console  
**Date**: October 27, 2025

---

## 🎯 Quick Command Reference

### Table Inspection
```lua
-- Inspect API structure
/tinspect C_VanityCollection

-- Inspect addon's saved variables
/tinspect AscensionVanityDB

-- Inspect current API dump data
/tinspect AscensionVanityDB.APIDump
```

### Table Dumping
```lua
-- Dump collected vanity data
/tdump C_VanityCollection.GetCollectedVanity()

-- Dump specific creature's items
/tdump C_VanityCollection.GetCollectedVanityForCreature(12345)

-- Dump validation results
/tdump AscensionVanityDB.ValidationResults
```

### Direct Console Commands
Open dev console and execute Lua directly:
```lua
-- Quick API test
local items = C_VanityCollection.GetCollectedVanity()
print("Total items:", #items)

-- Test specific creature
local creatureItems = C_VanityCollection.GetCollectedVanityForCreature(11440)
for _, item in ipairs(creatureItems) do
    print("Item:", item)
end

-- Check if API exists
print("API available:", C_VanityCollection ~= nil)
```

---

## 🔍 Debugging API Validation

### When `/av apidump` seems incomplete:

1. **Check API structure**:
   ```lua
   /tinspect C_VanityCollection
   ```
   Look for:
   - `GetCollectedVanity` function
   - `GetCollectedVanityForCreature` function
   - Any other available methods

2. **Test API response**:
   ```lua
   /tdump C_VanityCollection.GetCollectedVanity()
   ```
   Verify:
   - Data structure format
   - CreatureID presence
   - ItemID lists
   - Any missing fields

3. **Compare with database**:
   ```lua
   -- In dev console
   local apiData = C_VanityCollection.GetCollectedVanity()
   local dbData = AV_VanityDB
   
   print("API entries:", #apiData)
   print("DB entries:", AV_VanityDB and AV_CountEntries() or "DB not loaded")
   ```

### When validation shows unexpected results:

1. **Inspect validation data**:
   ```lua
   /tinspect AscensionVanityDB.ValidationResults
   ```

2. **Check specific mismatches**:
   ```lua
   /tdump AscensionVanityDB.ValidationResults.mismatches
   ```

3. **Verify missing items**:
   ```lua
   /tdump AscensionVanityDB.ValidationResults.apiOnly
   ```

---

## 📊 Advanced Analysis

### Count Items by Category

```lua
-- In dev console
local apiData = C_VanityCollection.GetCollectedVanity()
local counts = {}

for _, entry in ipairs(apiData) do
    local creatureID = entry.creatureID or entry[1]
    -- Categorize by creature ID range
    local category = math.floor(creatureID / 1000)
    counts[category] = (counts[category] or 0) + 1
end

for category, count in pairs(counts) do
    print(string.format("Range %d000s: %d items", category, count))
end
```

### Find Specific Items

```lua
-- Search for specific creature
local searchID = 11440
local apiData = C_VanityCollection.GetCollectedVanity()

for _, entry in ipairs(apiData) do
    if entry.creatureID == searchID or entry[1] == searchID then
        print("Found creature:", searchID)
        if type(entry.items) == "table" then
            for _, itemID in ipairs(entry.items) do
                print("  Item:", itemID)
            end
        elseif type(entry[2]) == "table" then
            for _, itemID in ipairs(entry[2]) do
                print("  Item:", itemID)
            end
        end
        break
    end
end
```

### Compare Specific Creature

```lua
-- Check creature in both API and DB
local creatureID = 11440

-- API data
local apiItems = C_VanityCollection.GetCollectedVanityForCreature(creatureID)
print("API items for", creatureID, ":", #apiItems)

-- DB data
local dbItems = AV_VanityDB and AV_VanityDB[creatureID]
if dbItems then
    print("DB items:", type(dbItems) == "table" and #dbItems or 1)
else
    print("Not in database")
end
```

---

## 🚀 Quick Testing Workflows

### Workflow 1: Verify API is Working
```lua
1. /tinspect C_VanityCollection
2. Check GetCollectedVanity exists
3. /tdump C_VanityCollection.GetCollectedVanity()
4. Verify data looks correct
```

### Workflow 2: Debug Missing Items
```lua
1. /av validate
2. Note missing count
3. /tinspect AscensionVanityDB.ValidationResults.apiOnly
4. Browse missing items
5. /tdump specific creature for details
```

### Workflow 3: Test New Database
```lua
1. Backup current DB
2. Load new VanityDB_Updated.lua
3. /reload
4. /av validate
5. Compare validation results
6. /tinspect AscensionVanityDB for verification
```

---

## 💡 Pro Tips

### Rapid Iteration
- Use dev console instead of `/reload` for quick tests
- Test API calls directly before updating addon code
- Inspect data structures before writing processing code

### Data Exploration
- Use `tinspect` for visual browsing
- Use `tdump` for detailed text output
- Combine both for comprehensive understanding

### Debugging
- Check `AscensionVanityDB` exists before validation
- Verify API functions are available
- Compare raw API vs processed results
- Watch for data format inconsistencies

### Performance Testing
```lua
-- Time API calls
local start = debugprofilestop()
local data = C_VanityCollection.GetCollectedVanity()
local elapsed = debugprofilestop() - start
print(string.format("API call took %.2f ms", elapsed))
```

---

## 📝 Common Issues & Solutions

### Issue: API returns nil
**Solution**: 
```lua
/tinspect C_VanityCollection
-- Check if API is loaded
-- Verify you're in Project Ascension
```

### Issue: Data structure unexpected
**Solution**:
```lua
/tdump C_VanityCollection.GetCollectedVanity()[1]
-- Examine first entry format
-- Update processing code accordingly
```

### Issue: Validation crashes
**Solution**:
```lua
-- Check data exists first
if AscensionVanityDB and AscensionVanityDB.APIDump then
    print("Dump exists:", AscensionVanityDB.APIDump.totalItems)
else
    print("Need to run /av apidump first")
end
```

---

## 🔗 Integration with AscensionVanity

### Enhanced Commands with Dev Console

Add these to your testing workflow:

**Before `/av apidump`**:
```lua
/tinspect C_VanityCollection  -- Verify API exists
```

**After `/av apidump`**:
```lua
/tinspect AscensionVanityDB.APIDump  -- Browse results
```

**Before `/av validate`**:
```lua
/tdump AV_VanityDB  -- Verify DB loaded
```

**After `/av validate`**:
```lua
/tinspect AscensionVanityDB.ValidationResults  -- Explore results
```

---

## 📚 Additional Resources

- **Ascension API Documentation**: In-game addon with full API reference
- **UI Dev Tools**: Table inspection and debugging utilities
- **Custom UI Resources**: Additional development helpers

---

**Happy Debugging! 🐛✨**
