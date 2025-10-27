# API Export & Comparison Guide

This guide explains how to export vanity item data from the in-game API and compare it with the static database.

## Overview

The addon supports three data sources:
1. **Static Database** (`VanityDB.lua`) - Hardcoded creature → item mappings
2. **API Dump** - Raw in-game API data structure
3. **API Export** - API data formatted to match static database format

## Workflow

### Step 1: Capture API Data In-Game

```
/av apidump
/reload
```

This captures all vanity collection data from `C_VanityCollection.GetAllItems()` and saves it to `SavedVariables/AscensionVanity.lua`.

### Step 2: Export in VanityDB Format

```
/av export
/reload
```

This transforms the API dump into the exact same format as `VanityDB.lua`, making comparison trivial.

### Step 3: View Exported Data

```
/av showexport
```

This displays the first 50 entries in chat. Full data is in `SavedVariables/AscensionVanity.lua` under `AscensionVanityDB.ExportedData`.

### Step 4: Compare with Static Database

**Option A: PowerShell Script (Automated)**

```powershell
.\utilities\CompareAPIExport.ps1
```

This script:
- Parses both the exported API data and static database
- Identifies exact matches, mismatches, and unique entries
- Exports results to CSV files for analysis
- Shows summary statistics

**Option B: Manual Comparison**

1. Open `SavedVariables/AscensionVanity.lua`
2. Find `AscensionVanityDB.ExportedData.entries`
3. Copy the array contents
4. Compare line-by-line with `VanityDB.lua`

## Export Format

The export uses the exact same format as `VanityDB.lua`:

```lua
-- Single item
[7045] = 1180254, -- Draconic Warhorn: Scalding Drake

-- Multiple items
[7045] = {1180254, 1180256}, -- Draconic Warhorn: Scalding Drake (multiple drops: 2 items)
```

## Comparison Results

The PowerShell script produces three types of findings:

### 1. Exact Matches
Creatures where API and static DB have identical item mappings.

### 2. Mismatches
Creatures present in both sources but with different item IDs.

**Example:**
```
Creature 7045:
  API: {1180254, 1180256}
  DB:  1180253
```

**Action:** Investigate which is correct and update accordingly.

### 3. API Only
Creatures in the API but missing from the static database.

**Possible Reasons:**
- New items added to the game
- Items you haven't discovered yet
- Website extraction missed these items

**Action:** Add to `VanityDB.lua` if verified.

### 4. DB Only
Creatures in the static database but not in the API.

**Possible Reasons:**
- Removed from game
- You haven't unlocked these items yet
- API doesn't include all sources

**Action:** Verify on website database.

## Updating the Static Database

When you find discrepancies:

1. **Verify the correct data:**
   - Check https://db.ascension.gg/
   - Use `/av dumpitem <itemID>` in-game
   - Check if you own the item with `/av api`

2. **Update `VanityDB.lua`:**
   ```lua
   [creatureID] = itemID, -- Single item
   [creatureID] = {item1, item2}, -- Multiple items
   ```

3. **Test in-game:**
   ```
   /reload
   /av debug
   ```
   Target the creature and verify tooltip shows correct items.

## Data Quality Checks

### Verify Item Ownership
```
/av dumpitem <itemID>
```

Check if the item exists in your vanity collection.

### Verify Creature Source
Check the API dump:
```lua
AscensionVanityDB.APIDump.items[itemID].creaturePreview
```

### Cross-Reference Website
Visit: `https://db.ascension.gg/?npc=<creatureID>`

Check the "Drops" table for vanity items.

## Troubleshooting

### Export shows "No API dump found"
Run `/av apidump` first, then `/reload`.

### PowerShell script can't find files
Update the paths in the script:
```powershell
-SavedVariablesPath "C:\Path\To\SavedVariables\AscensionVanity.lua"
-VanityDBPath ".\AscensionVanity\VanityDB.lua"
```

### API export is empty
Make sure you:
1. Ran `/av apidump` in-game
2. Used `/reload` to save data
3. Ran `/av export` after data was saved

### Export format doesn't match
The export automatically handles:
- Single items (scalar values)
- Multiple items (arrays)
- Proper Lua syntax
- Item name comments

## Batch Processing

To update the entire database from API data:

1. **Export:**
   ```
   /av apidump
   /reload
   /av export
   /reload
   ```

2. **Compare:**
   ```powershell
   .\utilities\CompareAPIExport.ps1
   ```

3. **Review Results:**
   Check `utilities\comparison_results\` for CSV files

4. **Update Database:**
   Merge verified changes into `VanityDB.lua`

5. **Validate:**
   ```
   /av validate
   ```

## Best Practices

1. **Regular Syncs:** Run `/av apidump` weekly to catch new items
2. **Verify Before Updating:** Always cross-check with the website
3. **Document Changes:** Add comments for multiple drops or unusual cases
4. **Test After Updates:** Use `/av debug` and target creatures to verify
5. **Keep Backups:** Git commit before major database updates

## Future Improvements

Potential enhancements:
- Automatic database sync from API
- In-game diff viewer
- One-click update command
- Conflict resolution UI
