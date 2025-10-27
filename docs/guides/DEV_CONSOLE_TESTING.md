# 🎮 Developer Console Testing Guide

**Purpose**: Leverage Ascension's developer tools for enhanced debugging and API exploration  
**Prerequisites**: Ascension API Documentation, UI Development Tools, and dev console enabled  
**Date**: October 27, 2025

---

## 🔧 Available Developer Tools

### 1. **Dev Console** (`/console` or bound hotkey)
- Execute Lua code directly in-game
- Real-time API testing
- Live debugging of addon functions
- Immediate feedback

### 2. **Ascension API Documentation Addon**
- Browse all available WoW APIs
- View method signatures
- Check parameter types
- Discover undocumented features

### 3. **Ascension UI Development Tools**
- Inspect UI frames and elements
- Monitor events
- Debug rendering issues
- Performance profiling

---

## 🚀 Quick Start: Essential Console Commands

### **API Exploration**

```lua
-- List all C_VanityCollection methods
for k,v in pairs(C_VanityCollection) do 
    print(k, type(v)) 
end

-- Dump entire API structure (LOTS of output!)
dump(C_VanityCollection)

-- Get all appearance sources (our main data source)
local data = C_VanityCollection.GetAllAppearanceSources()
print("Total categories:", #data)

-- Explore a specific category
local category1 = C_VanityCollection.GetAllAppearanceSources(1)
print("Category 1 items:", category1 and #category1 or 0)

-- Check if category structure matches expectations
if category1 and category1[1] then
    dump(category1[1]) -- First item in category
end
```

### **AscensionVanity Addon Testing**

```lua
-- Verify addon is loaded
if AscensionVanity then
    print("✅ AscensionVanity loaded!")
    print("Version:", AscensionVanity.VERSION or "Unknown")
else
    print("❌ AscensionVanity NOT loaded!")
end

-- Check database
if AscensionVanityDB then
    print("✅ Database loaded!")
    print("Total mappings:", AscensionVanityDB.CreatureToItemMap and 
          #AscensionVanityDB.CreatureToItemMap or 0)
else
    print("❌ Database NOT loaded!")
end

-- Test API dump manually
print("Running API dump...")
AV_PerformAPIDump()
print("✅ Dump complete!")

-- Check results
if AscensionVanityDB.APIDump then
    print("Total items:", AscensionVanityDB.APIDump.totalItems)
    print("Categories:", AscensionVanityDB.APIDump.categories and 
          #AscensionVanityDB.APIDump.categories or 0)
else
    print("❌ No dump data found!")
end

-- Run validation
print("Running validation...")
AV_ValidateDatabase()
print("✅ Validation complete!")

-- Check validation results
if AscensionVanityDB.ValidationResults then
    local vr = AscensionVanityDB.ValidationResults
    print("API Total:", vr.apiTotal)
    print("DB Total:", vr.dbTotal)
    print("Matches:", vr.matches)
    print("Missing:", vr.apiOnly and #vr.apiOnly or 0)
    print("Mismatches:", vr.mismatches and #vr.mismatches or 0)
else
    print("❌ No validation results!")
end
```

### **Deep Dive: API Structure Analysis**

```lua
-- Get all data at once
local allData = C_VanityCollection.GetAllAppearanceSources()

-- Analyze structure
if allData then
    print("=== API STRUCTURE ANALYSIS ===")
    print("Type:", type(allData))
    print("Is table:", type(allData) == "table")
    
    if type(allData) == "table" then
        print("Length:", #allData)
        print("Categories found:", #allData)
        
        -- Analyze first category
        if allData[1] then
            print("\n=== CATEGORY 1 STRUCTURE ===")
            print("Type:", type(allData[1]))
            print("Items:", #allData[1])
            
            -- Analyze first item
            if allData[1][1] then
                print("\n=== FIRST ITEM STRUCTURE ===")
                for k,v in pairs(allData[1][1]) do
                    print(k, "=", v, "("..type(v)..")")
                end
            end
        end
    end
else
    print("❌ GetAllAppearanceSources() returned nil!")
end
```

### **Category Breakdown**

```lua
-- Count items in each category
local allData = C_VanityCollection.GetAllAppearanceSources()
if allData then
    print("=== CATEGORY BREAKDOWN ===")
    local total = 0
    for i = 1, #allData do
        local count = #allData[i]
        total = total + count
        print(string.format("Category %d: %d items", i, count))
    end
    print("TOTAL:", total)
end
```

---

## 🔍 Debugging Workflow

### **When Something Doesn't Work**

1. **Check addon loaded**:
   ```lua
   dump(AscensionVanity)
   ```

2. **Check database loaded**:
   ```lua
   dump(AscensionVanityDB)
   ```

3. **Check API available**:
   ```lua
   dump(C_VanityCollection)
   ```

4. **Test API directly**:
   ```lua
   local data = C_VanityCollection.GetAllAppearanceSources()
   print(type(data), data and #data or "nil")
   ```

5. **Check for errors**:
   ```lua
   -- Run this to see any errors
   errors
   ```

### **When Data Looks Wrong**

1. **Compare API vs Database**:
   ```lua
   -- Get API item
   local apiData = C_VanityCollection.GetAllAppearanceSources()
   local firstItem = apiData[1][1]
   
   -- Check against DB
   local dbItem = AscensionVanityDB.CreatureToItemMap[firstItem.creatureID]
   
   print("API creature:", firstItem.creatureID)
   print("API item:", firstItem.itemID)
   print("DB item:", dbItem)
   ```

2. **Dump specific item details**:
   ```lua
   local creatureID = 12345 -- Replace with actual ID
   local apiData = C_VanityCollection.GetAllAppearanceSources()
   
   -- Find in API
   for catIdx, category in ipairs(apiData) do
       for itemIdx, item in ipairs(category) do
           if item.creatureID == creatureID then
               print("Found in category", catIdx, "at index", itemIdx)
               dump(item)
               break
           end
       end
   end
   
   -- Check DB
   print("DB mapping:", AscensionVanityDB.CreatureToItemMap[creatureID])
   ```

---

## 📊 Data Extraction Commands

### **Export Category Data**

```lua
-- Export category 1 to chat (for manual review)
local cat1 = C_VanityCollection.GetAllAppearanceSources(1)
if cat1 then
    for i, item in ipairs(cat1) do
        print(string.format("[%d] Creature: %d, Item: %d", 
              i, item.creatureID, item.itemID))
    end
end
```

### **Find Missing Items**

```lua
-- Quick check: find items in API but not in DB
local apiData = C_VanityCollection.GetAllAppearanceSources()
local missing = 0

for catIdx, category in ipairs(apiData) do
    for itemIdx, item in ipairs(category) do
        if not AscensionVanityDB.CreatureToItemMap[item.creatureID] then
            missing = missing + 1
            if missing <= 10 then -- Show first 10
                print(string.format("Missing: Creature %d → Item %d", 
                      item.creatureID, item.itemID))
            end
        end
    end
end

print("Total missing:", missing)
```

### **Find Mismatches**

```lua
-- Find items where DB differs from API
local apiData = C_VanityCollection.GetAllAppearanceSources()
local mismatches = 0

for catIdx, category in ipairs(apiData) do
    for itemIdx, item in ipairs(category) do
        local dbItem = AscensionVanityDB.CreatureToItemMap[item.creatureID]
        if dbItem and dbItem ~= item.itemID then
            mismatches = mismatches + 1
            if mismatches <= 10 then -- Show first 10
                print(string.format("Mismatch: Creature %d - API: %d, DB: %d", 
                      item.creatureID, item.itemID, dbItem))
            end
        end
    end
end

print("Total mismatches:", mismatches)
```

---

## 🎯 Testing Scenarios

### **Scenario 1: Verify API Dump Works**

```lua
-- Clear old data
AscensionVanityDB.APIDump = nil

-- Run dump
AV_PerformAPIDump()

-- Verify
if AscensionVanityDB.APIDump then
    print("✅ Dump successful!")
    print("Items:", AscensionVanityDB.APIDump.totalItems)
else
    print("❌ Dump failed!")
end
```

### **Scenario 2: Verify Validation Works**

```lua
-- Clear old results
AscensionVanityDB.ValidationResults = nil

-- Run validation
AV_ValidateDatabase()

-- Verify
if AscensionVanityDB.ValidationResults then
    local vr = AscensionVanityDB.ValidationResults
    print("✅ Validation successful!")
    print("Matches:", vr.matches)
    print("Missing:", #vr.apiOnly)
else
    print("❌ Validation failed!")
end
```

### **Scenario 3: Test Performance**

```lua
-- Time the API dump
local startTime = debugprofilestop()
AV_PerformAPIDump()
local endTime = debugprofilestop()

print("API Dump took:", (endTime - startTime), "ms")
```

---

## 🐛 Common Issues and Solutions

### **Issue: "attempt to index a nil value (global 'C_VanityCollection')"**

**Solution**: The API doesn't exist or isn't loaded yet
```lua
-- Check if API exists
if C_VanityCollection then
    print("✅ API available")
else
    print("❌ API not available - wrong WoW version?")
end
```

### **Issue: "AscensionVanity is nil"**

**Solution**: Addon not loaded
```lua
-- Check addon list
for i=1, GetNumAddOns() do
    local name = GetAddOnInfo(i)
    if name:find("Ascension") then
        print(name, IsAddOnLoaded(i))
    end
end
```

### **Issue: GetAllAppearanceSources() returns empty table**

**Solution**: API might need character to be logged in fully
```lua
-- Wait a moment after login, then try
C_Timer.After(3, function()
    local data = C_VanityCollection.GetAllAppearanceSources()
    print("Items after delay:", data and #data or "nil")
end)
```

---

## 📝 Saving Your Work

### **After Testing in Console**

1. **Save to SavedVariables**:
   ```
   /reload
   ```
   This writes `AscensionVanityDB` to disk

2. **Find the file**:
   ```
   D:\OneDrive\Warcraft\WTF\Account\CTOUT\SavedVariables\AscensionVanity.lua
   ```

3. **Analyze with PowerShell**:
   ```powershell
   .\utilities\AnalyzeAPIDump.ps1 -Detailed
   ```

---

## 🚀 Advanced: Live Code Injection

### **Test New Functions Without Reloading**

```lua
-- Define a test function in console
function TestNewFeature()
    print("Testing new feature...")
    -- Your test code here
end

-- Run it
TestNewFeature()

-- Modify it
function TestNewFeature()
    print("Modified version...")
    -- Different code
end

-- Run again
TestNewFeature()
```

### **Override Addon Functions Temporarily**

```lua
-- Save original function
local originalFunc = AV_PerformAPIDump

-- Replace with debug version
function AV_PerformAPIDump()
    print("DEBUG: Starting API dump...")
    originalFunc() -- Call original
    print("DEBUG: Dump completed!")
end

-- Test
AV_PerformAPIDump()

-- Restore original
AV_PerformAPIDump = originalFunc
```

---

## 📚 Resources

- **Ascension API Documentation Addon**: Browse in-game for all APIs
- **WoW API Documentation**: https://wowpedia.fandom.com/wiki/World_of_Warcraft_API
- **Lua Reference**: https://www.lua.org/manual/5.1/
- **AscensionVanity Commands**: Type `/av help` in-game

---

## 🎉 Next Steps

1. ✅ **Explore the API** using the commands above
2. ✅ **Test AscensionVanity functions** directly in console
3. ✅ **Document any findings** in issues or notes
4. ✅ **Use validation results** to improve the database

**Happy debugging! 🔧**
