# Master Description Enrichment Workflow

## Overview

The `MasterDescriptionEnrichment.ps1` script is a comprehensive, single-pass automation that enriches VanityDB.lua descriptions by searching multiple data sources and applying updates automatically.

## Features

✅ **Fully Automated**: Single command to enrich all empty descriptions  
✅ **Multi-Source Search**: Queries db.ascension.gg → Wowhead WOTLK  
✅ **Intelligent Parsing**: Multiple regex patterns for maximum success  
✅ **Safe Updates**: Pattern matching prevents accidental overwrites  
✅ **Comprehensive Reporting**: CSV, JSON, and manual research lists  
✅ **Progress Tracking**: Real-time feedback with colored output  
✅ **Rate Limiting**: Respectful 2-second delays between requests  
✅ **Dry Run Mode**: Test without making changes (`-WhatIf`)

## Usage

### Basic Enrichment (Apply Changes)
```powershell
.\utilities\MasterDescriptionEnrichment.ps1
```

### Dry Run (Preview Only)
```powershell
.\utilities\MasterDescriptionEnrichment.ps1 -WhatIf
```

### Custom Rate Limiting
```powershell
.\utilities\MasterDescriptionEnrichment.ps1 -RateLimitSeconds 3
```

## Workflow Phases

### Phase 1: ANALYZE
- Scans `VanityDB.lua` for items with empty descriptions
- Extracts: Item ID, Full Name, NPC Name, Creature ID
- Reports count and preview of items to process

### Phase 2: SEARCH
**Strategy 1: db.ascension.gg (Primary)**
- Searches using Creature ID
- Pattern 1: "This NPC can be found in [Zone]"
- Pattern 2: Zone from creature drop tables (listview)
- Most reliable for Ascension-specific content

**Strategy 2: Wowhead WOTLK (Fallback)**
- Searches using Creature ID
- Pattern 1: JavaScript `WH.setSelectedLink` handlers
- Pattern 2: "This NPC can be found in" direct links
- Pattern 3: Plain text extraction
- Good for retail WoW content

### Phase 3: APPLY
- Generates description: `"Has a chance to drop from {NPC} within {Zone}"`
- Uses regex pattern matching to find exact item entries
- Safely updates only empty descriptions
- Validates each update before saving
- Optional dry-run mode for safety

### Phase 4: REPORT
**Generated Files:**
- `Enrichment_Results_{timestamp}.csv` - Full search results
- `Enrichment_Data_{timestamp}.json` - Successful enrichments
- `Manual_Research_Needed_{timestamp}.txt` - Items requiring manual work

**Console Output:**
- Real-time progress updates
- Color-coded status messages
- Final statistics and completion percentage
- Success celebration for 99%+ completion

## Output Files

### Enrichment_Results_{timestamp}.csv
Complete record of all searched items:
```csv
ItemId,FullName,NPCName,CreatureId,Zone,Source
80096,"Beastmaster's Whistle: Soulflayer",Soulflayer,11359,Zul'Gurub,db.ascension.gg
```

### Enrichment_Data_{timestamp}.json
Successful enrichments for documentation:
```json
[
  {
    "ItemId": "80096",
    "CreatureId": "11359",
    "NPCName": "Soulflayer",
    "Zone": "Zul'Gurub",
    "Source": "db.ascension.gg",
    "Description": "Has a chance to drop from Soulflayer within Zul'Gurub"
  }
]
```

### Manual_Research_Needed_{timestamp}.txt
Items that need manual investigation:
```
Items Needing Manual Research
Generated: 2025-10-29 12:00:00
Total: 1

These NPCs could not be found in db.ascension.gg or Wowhead WOTLK.
They may be:
- Ascension-specific NPCs
- Special spawn mechanics (prisons, events)
- Rewards/promos/not yet implemented
- Require in-game verification

Items:
  - Captain Claws (Creature 417217, Item 480382)
```

## Error Handling

The script gracefully handles:
- **404 Errors**: NPC doesn't exist in database
- **Timeouts**: 15-second timeout per request
- **Pattern Mismatches**: Continues to next pattern/source
- **Network Issues**: Reports error and continues
- **File Access**: Validates file paths before writing

## Success Rates

Based on our testing with 2,174 items:

| Source | Success Rate | Notes |
|--------|--------------|-------|
| db.ascension.gg | ~75% | Best for Ascension-specific content |
| Wowhead WOTLK | ~20% | Good for retail WoW NPCs |
| Manual Research | ~5% | Special spawns, custom content |

**Expected Automation:** 95-97% of items can be enriched automatically

## Manual Research Scenarios

Items requiring manual research typically fall into these categories:

1. **Special Spawn Mechanics**
   - Etherium Stasis Chamber prison mobs
   - Event-triggered NPCs
   - Quest summons

2. **Ascension-Specific Content**
   - Custom NPCs not in Wowhead
   - Require in-game verification or screenshots

3. **Rewards/Promos**
   - Shop purchases
   - Promotional items
   - Not yet implemented content

4. **Raid Bosses**
   - Sometimes need specific instance names
   - May require manual zone specification

## Maintenance

### When to Run
- After fresh VanityDB generation
- When new vanity items are added
- After major game updates
- Before releases to ensure completeness

### Updating the Script
- **Total Items**: Update `$totalItems` variable (line ~265)
- **Rate Limiting**: Adjust `$RateLimitSeconds` if needed
- **Patterns**: Add new regex patterns if database formats change
- **Sources**: Add new data sources to Phase 2 search

## Example Run

```powershell
PS> .\utilities\MasterDescriptionEnrichment.ps1

╔════════════════════════════════════════════════════════════════╗
║        Master Description Enrichment - VanityDB.lua           ║
╚════════════════════════════════════════════════════════════════╝

[PHASE 1] Analyzing VanityDB.lua for empty descriptions...
  Found 18 items with empty descriptions

[PHASE 2] Searching for zone locations...
  [1/18] Soulflayer (Creature 11359)
    → Checking db.ascension.gg...
    ✓ Found: Zul'Gurub
  ...

  Search Results:
    Found:     17 / 18
    Not Found: 1
    Errors:    0

[PHASE 3] Applying 17 enrichments to VanityDB.lua...
  ✓ Updated: Soulflayer → Zul'Gurub
  ...
  Applied: 17 / 17 enrichments
  Saving changes to AscensionVanity\VanityDB.lua...
  ✓ File saved successfully

[PHASE 4] Generating reports...
  ✓ Results exported to: data\Enrichment_Results_2025-10-29_120000.csv
  ✓ Enrichment data exported to: data\Enrichment_Data_2025-10-29_120000.json
  ✓ Manual research list: data\Manual_Research_Needed_2025-10-29_120000.txt

╔════════════════════════════════════════════════════════════════╗
║                      FINAL STATISTICS                          ║
╚════════════════════════════════════════════════════════════════╝

  Total Vanity Items:      2174
  Items with Descriptions: 2173 (99.95%)
  Empty Descriptions:      1

  This Run:
    Searched:              18
    Found Automatically:   17
    Applied to Database:   17
    Need Manual Research:  1

  ⭐ DATABASE 99.95% COMPLETE - EXCELLENT! ⭐

╔════════════════════════════════════════════════════════════════╗
║                    ENRICHMENT COMPLETE                         ║
╚════════════════════════════════════════════════════════════════╝
```

## Integration with Workflow

This script replaces the following individual scripts:
- ✅ `CompleteDescriptionEnrichment.ps1` (automated search)
- ✅ `SearchEmptyDescriptions_CORRECT.ps1` (creature ID search)
- ✅ `SearchFinalEmptyDescriptions.ps1` (final pass search)
- ✅ `FindEmptyDescriptions.ps1` (discovery)
- ✅ Manual pattern application scripts

**Result**: One command replaces 5+ separate workflows!

## Future Enhancements

Potential improvements for future versions:

- [ ] Support for batch processing with pause/resume
- [ ] Integration with in-game addon API for validation
- [ ] Automatic screenshot analysis for Ascension-specific NPCs
- [ ] Machine learning for zone prediction
- [ ] Real-time progress dashboard (HTML report)
- [ ] Integration with GitHub Actions for CI/CD

## Troubleshooting

**Problem**: Script reports "Pattern not found" errors  
**Solution**: VanityDB.lua format may have changed. Update regex patterns in Phase 3.

**Problem**: High "Not Found" count  
**Solution**: NPCs may be Ascension-specific. Check manual research list and verify in-game.

**Problem**: Timeouts or connection errors  
**Solution**: Increase rate limiting or check internet connection.

**Problem**: Changes not applied  
**Solution**: Check file permissions and ensure VanityDB.lua is not locked by another process.

---

**Version**: 1.0  
**Last Updated**: 2025-10-29  
**Maintained By**: AscensionVanity Development Team
