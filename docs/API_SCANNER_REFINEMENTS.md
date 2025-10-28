# API Scanner Refinements - Smart Filtering

## ✅ Changes Implemented

### 1. **Combat Pet Filtering at Scan Time**

The API scanner now filters items DURING the scan instead of capturing everything and filtering later. This results in:

- **Much smaller dump files** (only ~2,000 combat pets instead of ~10,000 total items)
- **Cleaner data** (no mounts, toys, or other vanity items)
- **Faster processing** (less data to parse and validate)

### 2. **Dual Filter Criteria**

Items are included in the scan ONLY if they meet BOTH criteria:

**Criteria 1: Quality Filter**
```lua
quality == 6  -- Artifact/Legendary (vanity item quality)
```

**Criteria 2: Name Prefix Filter**
```lua
Name starts with one of:
- "Beastmaster"
- "Blood"
- "Summoner"
- "Draconic"
- "Elemental"
```

### 3. **Simplified Data Structure**

The dump now contains ONLY the 5 essential fields:

```lua
{
    itemid = 79317,                -- Game item ID (from API)
    name = "Beastmaster's Whistle: Forest Spider",
    description = "...",           -- Drop description (if available)
    icon = "Ability_Hunter_BeastCall",
    creaturePreview = 30           -- Creature ID for preview
}
```

No more confusion with:
- ❌ Multiple `itemid`/`itemId` fields
- ❌ Nested `rawData` structures
- ❌ Unnecessary metadata fields
- ❌ Validation arrays (handled separately)

## 🎯 How to Use the Refined Scanner

### In-Game

1. **Start the scan:**
   ```
   /avscan
   ```

2. **Wait for completion:**
   ```
   Combat pet vanity items found: ~2100
   Data saved to: AscensionVanity_Dump.lua
   ```

3. **Exit WoW** to save the dump file

### Processing the Dump

4. **Generate the database:**
   ```powershell
   .\utilities\GenerateVanityDB_FromSimplifiedDump.ps1
   ```

5. **Result:**
   - Clean VanityDB.lua with correct game item IDs
   - Icon indexing applied automatically
   - Only combat pet vanity items included

## 📊 Expected Results

### Before Refinement
- Total items scanned: ~9,679
- Dump file size: ~10 MB
- Combat pets: ~2,121 (mixed in with everything else)
- Processing time: Several minutes

### After Refinement
- Total items scanned: ~2,100
- Dump file size: ~300 KB
- Combat pets: 100% (filtered)
- Processing time: ~10 seconds

## 🔍 Verification

To verify the scanner is working correctly:

1. **Check the scan output message:**
   ```
   Filtered for Quality 6 items with names starting with:
   Beastmaster, Blood, Summoner, Draconic, Elemental
   ```

2. **Review the dump file:**
   - Should only contain combat pet items
   - Each item should have exactly 5 fields
   - No extra metadata or validation arrays

3. **Generate and check the database:**
   - All items should have correct game item IDs (79xxx, 80xxx, etc.)
   - Icon indexing should be applied
   - No filtering needed during generation

## 🎉 Benefits

✅ **Cleaner data** - Only what we need, nothing more  
✅ **Faster scans** - Filter during scan, not after  
✅ **Smaller files** - ~97% size reduction  
✅ **No confusion** - Single, clear itemid field  
✅ **Better performance** - Less data to process  
✅ **Easier maintenance** - Simpler data structure  

## 📝 Next Steps

With the refined scanner in place, the workflow is now:

1. Run `/avscan` in-game
2. Exit WoW
3. Run `GenerateVanityDB_FromSimplifiedDump.ps1`
4. Deploy the addon with clean, optimized data

No more manual filtering, no more ID confusion, no more bloated dumps!
