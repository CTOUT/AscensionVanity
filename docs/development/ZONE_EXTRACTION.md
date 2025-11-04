# Extracting Zone Data Directly from WoW

## Overview

Instead of manually maintaining zone/subzone mappings from Wowpedia, we can extract them **directly from the game client**. This provides several advantages:

### Benefits
- ✅ **Ascension-specific zones** (custom content not on Wowpedia)
- ✅ **Always up-to-date** (matches current game client)
- ✅ **Accurate zone IDs** (useful for advanced features)
- ✅ **Real player locations** (validates against actual gameplay)
- ✅ **Subzone discovery** (captures all subzones as players explore)

### Limitations
- ❌ **Requires in-game scanning** (not automated from external tools)
- ❌ **Classic API limitations** (pre-TBC has fewer zone APIs)
- ❌ **Player must visit zones** (to discover subzones dynamically)
- ❌ **Language dependent** (extracts in client's locale)

## Available WoW APIs

### Zone Information
```lua
-- Current location
GetZoneText()           -- "Elwynn Forest"
GetSubZoneText()        -- "Goldshire"
GetMinimapZoneText()    -- Usually matches subzone
GetRealZoneText()       -- Real zone name (ignores instances)

-- PVP info (shows zone type)
GetZonePVPInfo()        -- Returns: pvpType, isSubZone, factionName
```

### Zone Enumeration (Classic/TBC)
```lua
-- Get all continents
GetMapContinents()      -- Returns: id1, name1, id2, name2, ...

-- Get zones on a continent
GetMapZones(continentID) -- Returns: table of zone names

-- Example:
local zones = { GetMapZones(1) }  -- Kalimdor zones
-- zones = {"Durotar", "Mulgore", "The Barrens", ...}
```

### Modern API (TBC/WOTLK - C_Map)
```lua
-- Get current map ID
C_Map.GetBestMapForUnit("player")

-- Get map info
local mapInfo = C_Map.GetMapInfo(mapID)
-- mapInfo = { name, mapID, mapType, parentMapID, ... }
```

## Extraction Methods

### Method 1: Simple Zone Scanner (TestZoneAPIs.lua)

**Purpose**: Quick test of available APIs and current location

**Usage**:
```lua
-- Copy contents to in-game macro or paste into chat
/run <contents of TestZoneAPIs.lua>
```

**Output**: Prints available APIs and current location data

### Method 2: Full Zone Extractor (ZoneExtractor.lua)

**Purpose**: Comprehensive extraction of all zones/continents

**Setup**:
1. Copy `ZoneExtractor.lua` to WoW AddOns folder as standalone addon, OR
2. Load it via `/run` command (may hit character limit), OR
3. Integrate into AscensionVanity's APIScanner

**Usage**:
```lua
/extractzones              -- Extract and display summary
/extractzones export       -- Extract and save to SavedVariables
/extractzones location     -- Show current location
/extractzones help         -- Show commands
```

**Output**: Creates `AscensionVanity_ZoneData` in SavedVariables

### Method 3: Integration with APIScanner

**Best approach for AscensionVanity**

Add zone extraction to existing APIScanner workflow:
1. Scan items (already done)
2. **NEW**: Scan zones/subzones
3. Export everything together

**Benefits**:
- Single scan operation
- Matches item data with zone data
- Same SavedVariables export format
- Consistent with existing workflow

## Extraction Workflow

### Step 1: In-Game Extraction
```
1. Log into WoW (Project Ascension)
2. Run: /extractzones export
3. Output: "Data exported to: AscensionVanity_ZoneData"
4. Run: /reload
5. Zone data saved to SavedVariables
```

### Step 2: Convert to ZoneMappings.json
```powershell
# Parse SavedVariables and convert to our format
.\utilities\ConvertZoneDataToMappings.ps1 `
    -InputFile "WTF\Account\[ACCOUNT]\SavedVariables\AscensionVanity.lua" `
    -OutputFile "data\ZoneMappings.json"
```

### Step 3: Validate
```powershell
# Compare against Wowpedia (should match closely)
.\utilities\ValidateZoneMappings.ps1
```

## Comparison: Wowpedia vs In-Game

| Aspect | Wowpedia | In-Game Extraction |
|--------|----------|-------------------|
| **Coverage** | Complete (manually curated) | Depends on player exploration |
| **Accuracy** | High (canonical) | 100% (from game) |
| **Custom Content** | ❌ No Ascension zones | ✅ Includes custom zones |
| **Automation** | ✅ Script downloads | ⚠️ Requires player in-game |
| **Subzones** | ✅ All documented | ⚠️ Only visited areas |
| **Zone IDs** | ❌ Not available | ✅ Real game IDs |

## Recommended Approach

### Hybrid Strategy (Best of Both)

1. **Base mapping**: Use Wowpedia data (UpdateZoneMappingsFromWowpedia.ps1)
   - Covers all zones comprehensively
   - Includes zones players haven't visited
   - Canonical subzone lists

2. **Supplement with in-game data**:
   - Ascension-specific custom zones
   - Validate Wowpedia accuracy
   - Discover zone IDs for advanced features
   - Capture subzone spelling variations

3. **Merge strategy**:
   - Wowpedia as base (71 zones, 1114 subzones)
   - In-game adds custom Ascension zones
   - In-game validates existing mappings
   - Flag discrepancies for review

## Future Integration

### APIScanner Enhancement (v2.3?)

Add zone extraction to existing scanner:

```lua
-- In APIScanner.lua, add new tab:
"Zone Scanner" tab
  - Extract Current Location button
  - Extract All Zones button
  - Export Zone Data button
  - Progress: X zones, Y continents
```

**SavedVariables output**:
```lua
AscensionVanityDump = {
    -- Existing item data
    APIDump = { ... },
    
    -- NEW: Zone data
    ZoneData = {
        version = "1.0",
        extractedDate = "2025-11-04 12:30:00",
        playerLocation = { zone = "Desolace", subzone = "Magram Village" },
        continents = { ... },
        zones = { ... }
    }
}
```

## Next Steps

**Immediate** (for v2.2):
- Keep Wowpedia-based mappings (already complete)
- Use in-game extraction for validation only

**Future** (for v2.3):
- Integrate ZoneExtractor into APIScanner
- Add zone data to fresh scans
- Merge in-game + Wowpedia data
- Auto-detect Ascension custom zones
- Zone ID support for advanced features

## Questions to Consider

1. **Do we need subzone extraction?**
   - Current approach: Wowpedia has comprehensive subzone lists
   - In-game: Only captures visited subzones
   - Verdict: Wowpedia is better for comprehensive coverage

2. **What about Ascension custom zones?**
   - Wowpedia doesn't have these
   - In-game extraction would capture them
   - Could add manually as discovered

3. **Zone IDs - useful?**
   - Could enable map coordinates
   - Could link to minimap data
   - Future feature potential (e.g., show on map)

## Conclusion

**Current approach (Wowpedia) is sufficient for v2.2**:
- ✅ Complete coverage (71 zones, 1114 subzones)
- ✅ Comprehensive subzone lists
- ✅ No in-game requirement
- ✅ Already implemented and working

**In-game extraction is valuable for**:
- Future: Ascension custom content
- Future: Zone ID features
- Future: Validation/verification
- Future: Dynamic updates

**Recommendation**: Keep Wowpedia base, add in-game extraction as **optional enhancement** in v2.3+.
