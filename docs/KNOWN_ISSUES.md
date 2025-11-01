# Known Issues

**Last Updated**: November 1, 2025  
**Status**: Documented for Future Resolution

## Creature ID Mismatches

### Overview
Several items in VanityDB.lua have **incorrect creature IDs** that cause their descriptions to reference the wrong creatures. This occurs because the creature IDs in the source data (from fresh scans) are incorrect, and the description enrichment process faithfully fetches data for those incorrect IDs.

### Impact
- **User Experience**: Players see misleading tooltip information
- **Data Quality**: ~3-5 items have wrong creature names in descriptions
- **Root Cause**: Source data has incorrect creature IDs, not an enrichment bug

### Confirmed Mismatches

| Item ID | Item Name | Creature ID | Description Says | Should Say |
|---------|-----------|-------------|------------------|------------|
| **79585** | Beastmaster's Whistle: Wiry Swoop | 2966 | "Battleboar" | "Wiry Swoop" |
| **79581** | Beastmaster's Whistle: Prairie Stalker | 2958 | "Prairie Wolf" | "Prairie Stalker" |
| **79583** | Beastmaster's Whistle: Mountain Cougar | 2960 | "Prairie Wolf Alpha" | "Mountain Cougar" |

### Example of the Problem

```lua
[79585] = {
    itemid = 79585,
    name = "Beastmaster's Whistle: Wiry Swoop",  -- Item is for Wiry Swoop
    creaturePreview = 2966,                       -- BUT creature ID 2966 is Battleboar!
    description = "Has a chance to drop from Battleboar within Red Cloud Mesa",  -- Wrong creature!
    icon = 1
}
```

### Why This Happens

1. **Fresh Scan Export** contains item with incorrect creature ID mapping
2. **Description Enrichment** queries db.ascension.gg for creature ID 2966
3. **Database Returns** "Battleboar" (which IS creature 2966)
4. **Result**: Correct query, wrong initial data

**The enrichment process is working correctly** - it's just fetching data for the wrong creature IDs.

## Resolution Strategy

### Option 1: Creature ID Correction System (Future Enhancement)
Create a correction/mapping system:

1. **Create corrections file**: `data/CreatureIdCorrections.json`
   ```json
   {
     "79585": {
       "correctCreatureId": 2969,
       "originalCreatureId": 2966,
       "reason": "Item is Wiry Swoop, not Battleboar",
       "verifiedBy": "Manual research"
     }
   }
   ```

2. **Apply corrections** before description enrichment
3. **Re-enrich** descriptions with correct creature IDs
4. **Validate** that names now match

### Option 2: Wait for Fresh Scan Processing (Recommended)
When processing the next fresh scan export from the game:

1. **Validate creature IDs** during import
2. **Cross-reference** item names with creature names from db.ascension.gg
3. **Flag mismatches** for manual review
4. **Correct before enrichment** to prevent propagation

### Option 3: Manual Fixes (Quick Win)
For the 3-5 known issues:

1. Research correct creature IDs manually
2. Update VanityDB.lua directly with corrections
3. Document corrections in this file
4. Re-run validation to confirm fixes

## Impact Assessment

### Severity: **Low**
- Only ~3-5 items affected out of 2,102 (0.2%)
- Descriptions still contain valid drop location information
- Item names are correct (players know what pet they're getting)
- Tooltip shows item name prominently

### Priority: **Medium**
- Not blocking for v2.1 release
- Should be fixed in v2.2 or when processing fresh scan
- Can be addressed alongside the 207 missing items

## Related Documentation
- **Description Enrichment**: `docs/MASTER_ENRICHMENT_WORKFLOW.md`
- **Database Status**: `docs/GROUP_ID_DISCOVERY.md`
- **Fresh Scan Process**: `utilities/PrepareForFreshScan.ps1`

## Validation Commands

### Find all mismatches
```powershell
# Check where item name doesn't match description creature
$content = Get-Content ".\AscensionVanity\VanityDB.lua" -Raw
$items = [regex]::Matches($content, '\[(\d+)\] = \{[^}]*?name = "Beastmaster''s Whistle: ([^"]+)"[^}]*?description = "Has a chance to drop from ([^"]+?) within')

foreach ($match in $items) {
    $itemCreature = $match.Groups[2].Value
    $descCreature = $match.Groups[3].Value
    if ($itemCreature -ne $descCreature) {
        Write-Host "Mismatch: Item=$itemCreature, Desc=$descCreature"
    }
}
```

### Verify a specific item
```powershell
# Check item 79585
$content = Get-Content ".\AscensionVanity\VanityDB.lua" -Raw
if ($content -match '\[79585\][^}]+name = "([^"]*)"[^}]+creaturePreview = (\d+)[^}]+description = "([^"]*)"') {
    Write-Host "Name: $($matches[1])"
    Write-Host "Creature ID: $($matches[2])"
    Write-Host "Description: $($matches[3])"
}
```

## Notes for Tomorrow
- Consider implementing Option 2 (validate during fresh scan import)
- May want to build validation into `MasterVanityDBPipeline.ps1`
- Could create a `ValidateCreatureMapping.ps1` script
- Research correct creature IDs for the 3 confirmed mismatches
