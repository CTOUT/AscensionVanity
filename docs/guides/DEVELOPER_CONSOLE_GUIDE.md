# 🛠️ Developer Console Integration Guide

**Status**: Active Development Tools Enabled  
**Date**: October 27, 2025  
**Purpose**: Leverage developer console for enhanced debugging and API exploration

---

## 🎮 Available Developer Tools

Based on your enabled addons:

### 1. Ascension API Documentation
- **Purpose**: Browse complete Ascension API reference
- **Access**: AddOns menu → "Ascension API Documentation"
- **Use Cases**: 
  - Verify C_VanityCollection API structure
  - Explore undocumented API functions
  - Check parameter types and return values

### 2. Ascension UI Development Tools
- **Purpose**: Inspect UI elements and frames
- **Access**: AddOns menu → "Ascension UI Development Tools"
- **Use Cases**:
  - Debug UI rendering issues
  - Inspect frame hierarchies
  - Monitor event firing

### 3. Ascension Resources for Custom UI
- **Purpose**: Browse available UI resources
- **Access**: AddOns menu → "Ascension Resources for Custom UI"
- **Use Cases**:
  - Find texture paths
  - Explore available fonts
  - Check UI templates

### 4. Dev Console
- **Access**: In-game console (likely bound to a key, typically `)
- **Commands**: Standard Lua console with full WoW API access

---

## 🔧 Developer Console Commands for AscensionVanity

### Testing C_VanityCollection API

```lua
-- Check if API exists
/run print(type(C_VanityCollection))

-- Get all collection sources (raw API call)
/run local sources = C_VanityCollection.GetAllCollectionSources(); print("Total sources:", #sources)

-- Inspect first source structure
/run local sources = C_VanityCollection.GetAllCollectionSources(); DevTools_Dump(sources[1])

-- Test specific category
/run local sources = C_VanityCollection.GetAllCollectionSources(); local count = 0; for _, src in ipairs(sources) do if src.categoryID == 1 then count = count + 1 end end; print("Category 1 count:", count)

-- Get item details for a specific creature
/run local info = C_VanityCollection.GetCollectionSourceInfo(12345); DevTools_Dump(info)
```

### Debugging AscensionVanity State

```lua
-- Check if addon is loaded
/run print(IsAddOnLoaded("AscensionVanity"))

-- Inspect AscensionVanity global namespace
/run DevTools_Dump(AscensionVanity)

-- Check database structure
/run print("DB entries:", AscensionVanity.db and #AscensionVanity.db or "nil")

-- Verify API dump data
/run print("API Dump:", AscensionVanityDB.APIDump and AscensionVanityDB.APIDump.totalItems or "Not dumped yet")

-- Check validation results
/run if AscensionVanityDB.ValidationResults then DevTools_Dump(AscensionVanityDB.ValidationResults.summary) end
```

### Live API Exploration

```lua
-- Count items by category
/run local sources = C_VanityCollection.GetAllCollectionSources(); local cats = {}; for _, src in ipairs(sources) do cats[src.categoryID] = (cats[src.categoryID] or 0) + 1 end; for cat, count in pairs(cats) do print("Category", cat, ":", count) end

-- Find items with specific properties
/run local sources = C_VanityCollection.GetAllCollectionSources(); for _, src in ipairs(sources) do if src.name and src.name:match("Dragon") then print(src.creatureDisplayInfoID, src.itemID, src.name) end end

-- Test specific creature ID
/run local info = C_VanityCollection.GetCollectionSourceInfo(28213); print("Creature 28213:", info and info.name or "Not found")

-- Dump large dataset to saved variables
/run AscensionVanity_DevDump = C_VanityCollection.GetAllCollectionSources(); print("Dumped", #AscensionVanity_DevDump, "sources")
```

---

## 🎯 Enhanced Testing Workflow

### Phase 1: Pre-Test Validation (Console)

Before running `/av apidump`:

```lua
-- 1. Verify API availability
/run print("API available:", type(C_VanityCollection) == "table")

-- 2. Quick count to verify API is responding
/run print("Quick count:", #C_VanityCollection.GetAllCollectionSources())

-- 3. Test a known creature ID from database
/run local info = C_VanityCollection.GetCollectionSourceInfo(28213); print(info and "API working" or "API issue")
```

### Phase 2: During Testing (Console + Commands)

```lua
-- Run the dump
/av apidump

-- While processing, monitor in console:
/run if AscensionVanityDB.APIDump then print("Processing... Current:", AscensionVanityDB.APIDump.totalItems or 0) end

-- After completion, verify in console:
/run print("Dump complete:", AscensionVanityDB.APIDump and AscensionVanityDB.APIDump.totalItems or "Failed")

-- Run validation
/av validate

-- Check validation details in console:
/run if AscensionVanityDB.ValidationResults then local r = AscensionVanityDB.ValidationResults.summary; print(string.format("API: %d, DB: %d, Missing: %d, Mismatch: %d", r.apiTotal, r.dbTotal, r.apiOnlyCount, r.mismatchCount)) end
```

### Phase 3: Deep Dive Analysis (Console)

```lua
-- Inspect specific missing items
/run if AscensionVanityDB.ValidationResults then for i, item in ipairs(AscensionVanityDB.ValidationResults.apiOnly) do if i <= 10 then print(i, "Creature:", item.creatureID, "Item:", item.itemID, item.name) end end end

-- Check mismatches
/run if AscensionVanityDB.ValidationResults then for i, item in ipairs(AscensionVanityDB.ValidationResults.mismatches) do if i <= 10 then print(i, "Creature:", item.creatureID, "API item:", item.apiItemID, "DB item:", item.dbItemID) end end end

-- Export problematic items to a simple list
/run local list = {}; for i, item in ipairs(AscensionVanityDB.ValidationResults.apiOnly) do if i <= 20 then table.insert(list, string.format("%d -> %d (%s)", item.creatureID, item.itemID, item.name or "unknown")) end end; AscensionVanity_MissingList = list; print("Exported", #list, "items")
```

---

## 🔍 Advanced Console Techniques

### API Exploration Patterns

```lua
-- Find all unique category IDs
/run local cats = {}; for _, src in ipairs(C_VanityCollection.GetAllCollectionSources()) do cats[src.categoryID] = true end; local count = 0; for cat in pairs(cats) do count = count + 1; print("Category:", cat) end; print("Total categories:", count)

-- Find items without names
/run local count = 0; for _, src in ipairs(C_VanityCollection.GetAllCollectionSources()) do if not src.name or src.name == "" then count = count + 1 end end; print("Items without names:", count)

-- Find duplicate creature IDs (data quality check)
/run local creatures = {}; local dupes = 0; for _, src in ipairs(C_VanityCollection.GetAllCollectionSources()) do if creatures[src.creatureDisplayInfoID] then dupes = dupes + 1 else creatures[src.creatureDisplayInfoID] = true end end; print("Duplicate creatures:", dupes)

-- Sample random items for spot-checking
/run local sources = C_VanityCollection.GetAllCollectionSources(); for i = 1, 5 do local idx = math.random(1, #sources); local src = sources[idx]; print(string.format("[%d] %s (Creature: %d, Item: %d)", idx, src.name or "Unknown", src.creatureDisplayInfoID, src.itemID)) end
```

### Performance Monitoring

```lua
-- Time the API call
/run local start = debugprofilestop(); local sources = C_VanityCollection.GetAllCollectionSources(); print("API call took:", debugprofilestop() - start, "ms for", #sources, "items")

-- Monitor memory usage
/run UpdateAddOnMemoryUsage(); print("AscensionVanity memory:", GetAddOnMemoryUsage("AscensionVanity"), "KB")

-- Profile dump operation
/run local start = debugprofilestop(); AV_DumpCollectionData(); print("Dump operation took:", debugprofilestop() - start, "ms")
```

---

## 🐛 Debugging Workflows

### Issue: API Dump Not Completing

```lua
-- 1. Check if API is accessible
/run print(type(C_VanityCollection), type(C_VanityCollection.GetAllCollectionSources))

-- 2. Try raw API call
/run local sources = C_VanityCollection.GetAllCollectionSources(); print(sources and #sources or "nil")

-- 3. Test with small batch
/run local sources = C_VanityCollection.GetAllCollectionSources(); for i = 1, math.min(10, #sources) do print(i, sources[i].creatureDisplayInfoID, sources[i].itemID) end

-- 4. Check for errors in saved variables
/run print("Saved data status:", AscensionVanityDB and "Exists" or "Missing")
```

### Issue: Validation Shows Unexpected Results

```lua
-- 1. Verify database loaded
/run print("DB loaded:", AscensionVanity.db and #AscensionVanity.db or "No DB")

-- 2. Spot-check a known mapping
/run local found = false; for _, entry in ipairs(AscensionVanity.db) do if entry[1] == 28213 then print("Found 28213 -> Item:", entry[2]); found = true; break end end; if not found then print("28213 not in DB") end

-- 3. Compare API vs DB for specific creature
/run local apiInfo = C_VanityCollection.GetCollectionSourceInfo(28213); local dbItem = nil; for _, entry in ipairs(AscensionVanity.db) do if entry[1] == 28213 then dbItem = entry[2]; break end end; print("API item:", apiInfo and apiInfo.itemID or "nil", "DB item:", dbItem or "nil")

-- 4. Count DB entries manually
/run local count = 0; for _ in pairs(AscensionVanity.db) do count = count + 1 end; print("Manual DB count:", count)
```

### Issue: Performance Problems

```lua
-- 1. Check addon CPU usage
/run UpdateAddOnCPUUsage(); print("CPU time:", GetAddOnCPUUsage("AscensionVanity"), "ms")

-- 2. Profile specific function
/run local start = debugprofilestop(); AV_GetVanityItemsForCreature(28213); print("Lookup took:", debugprofilestop() - start, "ms")

-- 3. Monitor frame rate during operation
/run print("FPS before:", GetFramerate()); C_Timer.After(0.1, function() local start = debugprofilestop(); AV_DumpCollectionData(); C_Timer.After(0.1, function() print("FPS after:", GetFramerate(), "Dump took:", debugprofilestop() - start, "ms") end) end)
```

---

## 📊 Console-Based Reporting

### Quick Statistics Report

```lua
/run local sources = C_VanityCollection.GetAllCollectionSources(); local stats = {total = #sources, withNames = 0, categories = {}}; for _, src in ipairs(sources) do if src.name and src.name ~= "" then stats.withNames = stats.withNames + 1 end; stats.categories[src.categoryID] = (stats.categories[src.categoryID] or 0) + 1 end; print("=== API Statistics ==="); print("Total items:", stats.total); print("Items with names:", stats.withNames); for cat, count in pairs(stats.categories) do print("Category", cat, ":", count) end
```

### Validation Summary

```lua
/run if AscensionVanityDB.ValidationResults then local r = AscensionVanityDB.ValidationResults.summary; print("=== Validation Results ==="); print("API Total:", r.apiTotal); print("Database Total:", r.dbTotal); print("Exact Matches:", r.exactMatches); print("Missing (API only):", r.apiOnlyCount); print("Mismatches:", r.mismatchCount); print("Match Rate:", string.format("%.1f%%", (r.exactMatches / r.apiTotal) * 100)) else print("No validation results. Run /av validate first.") end
```

### Export Results for Analysis

```lua
-- Create a formatted export
/run local export = {}; if AscensionVanityDB.ValidationResults then for i, item in ipairs(AscensionVanityDB.ValidationResults.apiOnly) do if i <= 50 then table.insert(export, string.format("Creature %d -> Item %d (%s)", item.creatureID, item.itemID, item.name or "Unknown")) end end; AscensionVanity_Export = table.concat(export, "\n"); print("Exported 50 items. Check AscensionVanity_Export in SavedVariables.") end
```

---

## 🎓 Best Practices

### Console Usage Guidelines

1. **Start Simple**: Test basic functionality before complex operations
2. **Incremental Testing**: Test small batches before full dumps
3. **Verify State**: Always check addon and API state before operations
4. **Performance Monitoring**: Profile operations that touch large datasets
5. **Save Often**: `/reload` after significant operations

### Integration with Addon Commands

**Recommended Workflow**:
1. Console: Verify API availability
2. Addon: `/av apidump` (let addon handle the heavy lifting)
3. Console: Spot-check results during processing
4. Addon: `/av validate` (structured validation)
5. Console: Deep-dive into specific issues
6. PowerShell: Comprehensive offline analysis

**Why This Works**:
- Console = Quick verification and exploration
- Addon commands = Structured, reliable operations
- PowerShell = Detailed analysis and reporting

---

## 🚀 Quick Reference Card

### Essential Console Commands

```lua
-- API Health Check
/run print(type(C_VanityCollection), #C_VanityCollection.GetAllCollectionSources())

-- Quick Dump Status
/run print(AscensionVanityDB.APIDump and AscensionVanityDB.APIDump.totalItems or "No dump")

-- Validation Summary
/run if AscensionVanityDB.ValidationResults then local r = AscensionVanityDB.ValidationResults.summary; print(r.apiTotal, r.dbTotal, r.apiOnlyCount, r.mismatchCount) end

-- DB Entry Count
/run print("DB entries:", AscensionVanity.db and #AscensionVanity.db or "nil")

-- Memory Check
/run UpdateAddOnMemoryUsage(); print(GetAddOnMemoryUsage("AscensionVanity"), "KB")

-- Random Sample
/run local s = C_VanityCollection.GetAllCollectionSources(); local r = s[math.random(#s)]; print(r.creatureDisplayInfoID, r.itemID, r.name)
```

---

## 📝 Console Testing Checklist

Add this to your testing workflow:

**Before `/av apidump`**:
- [ ] `/run print(type(C_VanityCollection))` → should print "table"
- [ ] `/run print(#C_VanityCollection.GetAllCollectionSources())` → should print ~2000

**After `/av apidump`**:
- [ ] `/run print(AscensionVanityDB.APIDump.totalItems)` → should match expected count
- [ ] `/run print(AscensionVanityDB.APIDump.timestamp)` → should be recent

**After `/av validate`**:
- [ ] `/run DevTools_Dump(AscensionVanityDB.ValidationResults.summary)` → inspect full results
- [ ] Check missing items list in console
- [ ] Spot-check a few mappings manually

---

## 🎯 Next Steps

1. **Test basic console commands** to verify API access
2. **Use console during testing** to monitor operations in real-time
3. **Leverage console for debugging** when issues arise
4. **Combine with PowerShell** for comprehensive analysis

**Ready to level up your debugging game! 🛠️**
