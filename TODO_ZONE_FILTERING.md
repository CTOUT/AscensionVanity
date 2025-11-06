# TODO: Add Zone Filtering to Database Browser

**Status**: Parked for PC session  
**Date**: November 6, 2025  
**Branch**: v2.2-dev

## Current State

### What Works ✅
- Database Browser opens and displays all items
- Grid layout (3×5) working
- Category filters (Beast, Demon, etc.) working
- Learned status filters working
- Multi-Drop checkbox working
- Radio buttons for "All Zones" vs "Current Zone"

### What's Missing ⚠️
- **Zone data not in VanityDB.lua**: Database doesn't have `zone` and `subzone` fields
- **Current Zone filter doesn't work**: Shows all items regardless of zone (same as "All Zones")
- **No geographic filtering**: Can't filter by continent/zone/subzone

## Root Cause

The current `VanityDB.lua` was generated **without running the zone enrichment pipeline**. It only has:
- `itemid`
- `name`
- `creaturePreview`
- `description`
- `icon`

It's **missing**:
- `zone` (e.g., "Elwynn Forest")
- `subzone` (e.g., "Jasperlode Mine")

## How to Fix (When on PC)

### Step 1: Verify Data Source
```powershell
# Check if we have the SavedVariables file
Test-Path "data\AscensionVanity.lua"
```

### Step 2: Run Master Import Pipeline
```powershell
# This creates MasterFullValidated.json with proper structure
.\utilities\MasterAPIDumpImport.ps1

# Alternative if symlink exists:
.\utilities\MasterVanityDBPipeline.ps1 -ScanFile "data\AscensionVanity.lua"
```

### Step 3: Enrich with Zone Data
```powershell
# Extract zone/subzone from descriptions (e.g., "Drops from X within Elwynn Forest")
.\utilities\EnrichZoneData.ps1

# Output: data\MasterFullValidated_ZoneEnriched.json
```

### Step 4: Regenerate VanityDB.lua
```powershell
# Generate with zone fields included
.\utilities\GenerateVanityDB_Master.ps1

# Output: AscensionVanity\VanityDB.lua (with zone data!)
```

### Step 5: Deploy & Test
```powershell
.\DeployAddon.ps1
```

In-game:
```
/reload
/avanity browser
Select "Current Zone" radio button
- Should now filter to current zone items only
```

## Expected Database Structure (After Fix)

```lua
AV_VanityItems = {
    [79346] = {
        itemid = 79346,
        name = "Beastmaster's Whistle: Prowler",
        creaturePreview = 118,
        description = "Has a chance to drop from Prowler within Elwynn Forest",
        icon = 1,
        zone = "Elwynn Forest",        -- ← MISSING NOW
        subzone = ""                    -- ← MISSING NOW
    },
    [79349] = {
        itemid = 79349,
        name = "Beastmaster's Whistle: Goretusk",
        creaturePreview = 157,
        description = "Has a chance to drop from Goretusk within Alexston Farmstead",
        icon = 1,
        zone = "Westfall",              -- ← MISSING NOW
        subzone = "Alexston Farmstead"  -- ← MISSING NOW
    }
}
```

## UI Changes Already Made

### Simplified Filter UI
- Removed complex 3-tier dropdown system (Continent → Zone → Subzone)
- Simplified to just radio buttons: "All Zones" / "Current Zone"
- Once zone data exists, "Current Zone" will automatically filter items

### Code Location
- **File**: `AscensionVanity/DatabaseBrowser.lua`
- **Filter Logic**: `ApplyFilters()` function (lines ~320-370)
- **Currently**: Treats both modes the same (shows all)
- **After fix**: "Current Zone" will filter by `GetZoneText()`

## Why This Happened

The zone enrichment step was **skipped** in the last database generation. The workflow should be:

1. ✅ Scan in-game → `AscensionVanity.lua` (raw API data)
2. ❌ Import → `MasterFullValidated.json` (SKIPPED)
3. ❌ Enrich → Add zone fields (SKIPPED)
4. ✅ Generate → `VanityDB.lua` (generated without zones)

## Files to Check

### Input Files Needed
- `data/AscensionVanity.lua` - Fresh scan from in-game
- `data/ZoneMappings.json` - Zone hierarchy (parent zones for subzones)

### Scripts Involved
- `utilities/MasterAPIDumpImport.ps1` - Import and normalize scan
- `utilities/EnrichZoneData.ps1` - Extract zones from descriptions
- `utilities/GenerateVanityDB_Master.ps1` - Generate final Lua file

### Output Files
- `data/MasterFullValidated.json` - Intermediate JSON
- `data/MasterFullValidated_ZoneEnriched.json` - JSON with zones
- `AscensionVanity/VanityDB.lua` - Final database (needs zones!)

## Documentation References

See these docs for more details:
- `docs/VANITYDB_GENERATION_WORKFLOW.md` - Full workflow explanation
- `docs/DATABASE_PIPELINE_ARCHITECTURE.md` - Pipeline design
- `utilities/README.md` - Script usage guide

## Testing After Fix

1. **All Zones Mode**: Should show all 2,355 items (same as now)
2. **Current Zone Mode**: Should filter to only items from current zone
3. **Zone Changes**: Moving zones should update the filter automatically
4. **Edge Cases**: 
   - Items with no zone data → Show in "All Zones" only
   - Items with subzone but no parent zone → Use ZoneMappings.json to resolve

## Estimated Time

- 5-10 minutes on PC (if data files exist)
- 30 minutes if need to rescan in-game

---

**Next Session**: Run the pipeline on PC to add zone data to database! 🎮
