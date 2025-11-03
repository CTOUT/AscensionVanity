# Description Enrichment Workflow - Future Consolidation Plan

## Current Status (2025-10-28)

### ✅ Completed Tonight:
1. **59 descriptions validated** and applied to VanityDB.lua
   - 28 Beastmaster's Whistle items
   - 16 Summoner's Stone items
   - 12 Blood Soaked Vellum items
   - 3 Elemental Lodestone items

2. **Icon optimization** completed
   - Created IconIndex.lua with 9 unique icons
   - Reduced VanityDB.lua size by ~10%

3. **Unicode fixes** applied
   - Fixed `Un'Goro Crater` and other special characters

### 📝 Remaining Work:
- **20 items** still need region enrichment from Wowhead WOTLK
- List saved in: `data\Items_Needing_Wowhead.csv`

## Workflow Scripts Created

### 1. **Initial Validation** (db.ascension.gg)
**Script:** `utilities\ValidateBlankDescriptions.ps1`
- Searches db.ascension.gg for creature drop information
- Extracts NPC name and region
- Generates descriptions: "Has a chance to drop from [NPC] within [Region]"

### 2. **Secondary Enrichment** (Wowhead WOTLK) - TO BE CONSOLIDATED
**Script:** `utilities\EnrichWithWowhead.ps1` (needs updating)
- Uses WOTLK-specific URLs: `https://www.wowhead.com/wotlk/npc=XXXX`
- Looks for pattern: "This NPC can be found in [Zone Name]"
- Fills in missing regions for validated items

### 3. **Apply Descriptions**
**Script:** `utilities\ApplyValidatedDescriptions.ps1`
- Reads `data\BlankDescriptions_Validated.json`
- Updates VanityDB.lua with validated descriptions
- Regex-based replacement

### 4. **Find Items Needing Enrichment**
**Script:** `utilities\FindItemsNeedingWowhead.ps1`
- Identifies items with `Validated: false` OR `Region: null`
- Generates list for Wowhead lookup
- Exports to CSV for reference

## Future Consolidation Plan

### Option A: Single Unified Script
Create: `utilities\EnrichAllBlankDescriptions.ps1`

```powershell
# Workflow:
1. Find all blank descriptions in VanityDB.lua
2. Try db.ascension.gg first (faster, more accurate)
3. For failures/partial matches, try Wowhead WOTLK
4. Apply all validated descriptions
5. Generate summary report
```

### Option B: Separate Scripts with Orchestrator
Keep existing scripts, create: `utilities\RunFullEnrichment.ps1`

```powershell
# Orchestrator that runs:
1. ValidateBlankDescriptions.ps1
2. EnrichWithWowhead.ps1 (for remaining items)
3. ApplyValidatedDescriptions.ps1
4. Generate final report
```

## Key Patterns Discovered

### db.ascension.gg
- **URL Format:** `https://db.ascension.gg/item/ITEMID`
- **Pattern:** Drop list with `<div class="listview-row">` containing creature name
- **Region:** Look for `<small>` tag with zone name

### Wowhead WOTLK
- **URL Format:** `https://www.wowhead.com/wotlk/npc=CREATUREID`
- **Pattern:** "This NPC can be found in [Zone Name]"
- **Fallback:** If no location, NPC is likely instance/raid boss (no region)

## Data Structure

### BlankDescriptions_Validated.json
```json
{
  "ItemId": "12345",
  "CreatureId": "6789",
  "Name": "Item Name",
  "Validated": true/false,
  "DropsFrom": "NPC Name" or null,
  "Region": "Zone Name" or null,
  "GeneratedDescription": "Full description" or null
}
```

### Decision Tree
1. If `Validated: true` AND `Region: not null` → Ready to apply
2. If `Validated: true` AND `Region: null` → Need Wowhead lookup
3. If `Validated: false` → Need full research (may not be a drop)

## Rate Limiting
- **db.ascension.gg:** 2 seconds between requests
- **Wowhead:** 2 seconds between requests
- **Batch size:** Process in chunks of 50 to avoid issues

## Files Involved
- **Input:** `AscensionVanity\VanityDB.lua`
- **Intermediate:** `data\BlankDescriptions_Validated.json`
- **Output:** Updated `AscensionVanity\VanityDB.lua`
- **Reference:** `data\Items_Needing_Wowhead.csv`

## Next Session TODO
1. Update `EnrichWithWowhead.ps1` to use WOTLK URLs and correct pattern
2. Test Wowhead enrichment on the 20 remaining items
3. Consider creating unified orchestrator script
4. Document the complete workflow in README.md
