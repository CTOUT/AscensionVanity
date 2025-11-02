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

| Item ID | Item Name | Wrong Creature ID | Description Says | Correct Creature ID | Should Say | Verified |
|---------|-----------|-------------------|------------------|---------------------|------------|----------|
| **79581** | Beastmaster's Whistle: Prairie Stalker | 2958 | "Prairie Wolf" | **2959** | "Prairie Stalker" | Item 79582 |
| **79583** | Beastmaster's Whistle: Mountain Cougar | 2960 | "Prairie Wolf Alpha" | **2961** | "Mountain Cougar" | [db.ascension.gg](https://db.ascension.gg/?item=79584#dropped-by) |
| **79585** | Beastmaster's Whistle: Wiry Swoop | 2966 | "Battleboar" | **2969** | "Wiry Swoop" | Item 79586 |

**Note:** Each of these items has a duplicate entry with the **correct** creature ID already in the database (items 79582, 79584, and 79586 respectively).

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

**Root Cause: Game Data Has Wrong Creature Preview IDs**

The issue originates from **Ascension's game data itself**:

1. **Game Database Error**: Items 79581, 79583, and 79585 have incorrect `creaturePreview` IDs stored in Ascension's database
2. **Item Names Are Dynamic**: The game generates item names like "Beastmaster's Whistle: [Creature Name]" by looking up the `creaturePreview` ID
3. **Wrong ID = Wrong Name**: When the preview ID is wrong, the game displays the wrong creature name in the item
4. **Visual Similarity**: The wrong creatures often look similar (e.g., different wolf NPCs, different boar NPCs) but are actually different entities with different names and drop locations
5. **Processing Is Correct**: Our enrichment scripts correctly fetch descriptions for the creature IDs provided - the IDs themselves are just wrong

**Evidence:**
- Fresh scans from October 28 (FINAL) and November 1 (01112025) consistently show the same wrong creature IDs
- Item names in the game exactly match the creature preview IDs, confirming dynamic naming
- Duplicate items exist with correct creature IDs (79582, 79584, 79586)

**The enrichment process is working correctly** - it's faithfully processing the incorrect data from the game.

## Resolution Strategy

### Option 1: Creature ID Correction System (Future Enhancement)
Create a correction/mapping system:

1. **Create corrections file**: `data/CreatureIdCorrections.json`
   ```json
   {
     "79581": {
       "correctCreatureId": 2959,
       "originalCreatureId": 2958,
       "reason": "Item is Prairie Stalker, not Prairie Wolf",
       "verifiedBy": "Duplicate item 79582 has correct ID"
     },
     "79583": {
       "correctCreatureId": 2961,
       "originalCreatureId": 2960,
       "reason": "Item is Mountain Cougar, not Prairie Wolf Alpha",
       "verifiedBy": "https://db.ascension.gg/?item=79584#dropped-by"
     },
     "79585": {
       "correctCreatureId": 2969,
       "originalCreatureId": 2966,
       "reason": "Item is Wiry Swoop, not Battleboar",
       "verifiedBy": "Duplicate item 79586 has correct ID"
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
For the 3 known issues with verified correct IDs:

**Simple Approach: Remove Duplicates**
Since correct versions exist (79582, 79584, 79586), simply remove the bad entries:
- Remove item 79581 from database (duplicate of 79582)
- Remove item 79583 from database (duplicate of 79584)
- Remove item 79585 from database (duplicate of 79586)

**OR Correction Approach:**
1. Update `data/MasterFullValidated.json`:
   - Change item 79581: `"CreatureId": 2958` → `"CreatureId": 2959`
   - Change item 79583: `"CreatureId": 2960` → `"CreatureId": 2961`
   - Change item 79585: `"CreatureId": 2966` → `"CreatureId": 2969`

2. Re-run enrichment:
   ```powershell
   .\utilities\MasterDescriptionEnrichment.ps1
   .\utilities\GenerateVanityDB.ps1
   ```

3. Verify corrections with validation script

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

## Resolution Status

### ✅ RESOLVED (November 2, 2025)

**Root Cause Identified**: The issue was not in the game data itself, but in our processing pipeline. The mapping file was being manually edited to fix creature IDs, which led to accidental corruption of item names.

**Solution Implemented**: Data Integrity Infrastructure

1. **Immutable Source Files**: Source data from game is never edited
2. **Separate Corrections File**: `data/corrections/CreatureIdCorrections.json` 
3. **Layered Processing**: Source → Corrections → Processing → Output
4. **Validation Checksums**: Detect file tampering automatically
5. **Version Control**: Corrections tracked in git with full audit trail

See `docs/DATA_INTEGRITY_IMPLEMENTATION.md` for complete details.

### Items Resolved
- **79582**: Prairie Stalker - Corrected from creature 98766 → 2959 ✓
- **79581, 79583, 79585**: Were NOT duplicates - names were corrupted during processing
  - All now have correct, unique names from fresh scan data

### New Workflow
```powershell
# Run complete pipeline with integrity checks
.\utilities\MasterPipeline.ps1
```

This issue is now resolved and prevented from recurring through the new data integrity infrastructure.

## Processing Workflow Recommendations

### When Processing Fresh Scans
The `MasterAPIDumpImport.ps1` script correctly extracts item names and creature IDs directly from fresh scan files. However, to ensure data integrity:

1. **Always regenerate `API_to_GameID_Mapping.json` from the most recent fresh scan**
   - The script at `utilities\MasterAPIDumpImport.ps1` handles this
   - It parses the `["name"]` and `["creaturePreview"]` fields directly from the Lua table
   - Use the `-SavedVariablesPath` parameter to specify which scan file to use

2. **Implement validation during import**
   - Add a step to check if item name matches the creature name from db.ascension.gg
   - Flag mismatches for manual review before processing
   - This catches game data errors early in the pipeline

3. **Document the source scan used**
   - The script already timestamps the output files
   - Consider adding a manifest file tracking which scan generated which mapping

**Example workflow:**
```powershell
# 1. Import from fresh scan (generates API_to_GameID_Mapping.json)
.\utilities\MasterAPIDumpImport.ps1 -SavedVariablesPath ".\data\AscensionVanity_Fresh_Scan_LATEST.lua"

# 2. Validate creature mappings (optional, but recommended)
.\utilities\ValidateCreatureIds.ps1

# 3. Apply manual corrections if needed
# Edit: data\CreatureIdCorrections.json

# 4. Build master validated dataset
.\utilities\BuildMasterFullValidated.ps1

# 5. Enrich descriptions
.\utilities\MasterDescriptionEnrichment.ps1

# 6. Generate final database
.\utilities\GenerateVanityDB.ps1
```
