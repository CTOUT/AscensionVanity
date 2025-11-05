# Combat Pet Group ID Reference

**Last Updated**: November 5, 2025  
**Total Group IDs**: 8

## Overview

Ascension uses Group IDs to categorize vanity items. Combat pets are identified by 8 specific Group IDs that correspond to drop sources and reward types.

---

## Group ID Definitions

### Dropped Combat Pets (5 Group IDs)

These items drop from NPCs in the game world:

| Group ID | Category | Description | Accuracy |
|----------|----------|-------------|----------|
| 16777217 | Beastmaster's Whistle | Beast-type combat pets | 99.1% (8 vendor outliers) |
| 16777220 | Blood Soaked Vellum | Undead-type combat pets | 96.6% (19 vendor outliers) |
| 16777218 | Summoner's Stone | Demon-type combat pets | 98.5% (4 vendor outliers) |
| 16777224 | Draconic Warhorn | Dragonkin-type combat pets | 100% (0 outliers) |
| 16777232 | Elemental Lodestone | Elemental-type combat pets | 98.9% (3 vendor outliers) |

**Total Dropped Pets**: 2,343 items (34 vendor outliers = 98.5% overall accuracy)

### Seasonal/Event Rewards (3 Group IDs)

These items are obtained through seasonal events or special promotions:

| Group ID | Description | Examples |
|----------|-------------|----------|
| 553648129 | Seasonal rewards | Winter Veil pets, holiday events |
| 553648130 | Seasonal rewards | Event-exclusive pets |
| 553648136 | Seasonal rewards | Promotional pets |

**Total Seasonal Pets**: 10 items (confirmed as of Nov 2025)

---

## Usage in Scripts

### Primary Filter (Most Reliable)

All scripts use Group ID filtering as the primary method:

```powershell
$primaryGroupIds = @(
    # Dropped combat pets (5 Group IDs)
    16777217, 16777220, 16777218, 16777224, 16777232,
    
    # Seasonal/Event rewards (3 Group IDs)
    553648129, 553648130, 553648136
)
```

### Scripts Using Group ID Filtering

1. **MasterVanityDBPipeline.ps1** - Main import pipeline
2. **GenerateVanityDB_Master.ps1** - Database generation
3. **ValidateHighCreatureIDs.ps1** - Creature ID validation

---

## Validation Protocol

### Automatic Validation

The `MasterVanityDBPipeline.ps1` script includes automatic validation:

```powershell
Test-UnknownGroupIDs -ScanContent $scanContent -KnownGroupIDs $primaryGroupIds
```

This function:
1. ✅ Scans for items with combat pet category names
2. ✅ Identifies items using unknown Group IDs
3. ✅ Alerts if new Group IDs are detected
4. ✅ Lists affected items for review

### When Validation Fails

If unknown Group IDs are detected:

1. **Review the Items** - Check if they're legitimate combat pets
2. **Verify on db.ascension.gg** - Confirm the Group ID is valid
3. **Update Scripts** - Add the new Group ID to `$primaryGroupIds` in:
   - `MasterVanityDBPipeline.ps1`
   - `GenerateVanityDB_Master.ps1`
4. **Document** - Update this file with the new Group ID details
5. **Re-run Pipeline** - Process the fresh scan with updated filters

---

## Historical Notes

### Discovery Timeline

- **November 1, 2025**: Initial 5 Group IDs discovered (dropped pets only)
  - Covered 2,343 items with 98.5% accuracy
  - 34 vendor items correctly flagged as outliers

- **November 5, 2025**: Seasonal reward Group IDs added
  - 3 additional Group IDs discovered: 553648129, 553648130, 553648136
  - 10 seasonal reward pets now included
  - Total coverage: 2,353 items (100% of known combat pets)

### Why Group IDs?

**Previous Approach (v1.0)**:
- Item name prefix filtering ("Beastmaster's Whistle:", etc.)
- Required manual keyword exclusions for vendors
- Prone to false positives

**Current Approach (v2.0+)**:
- Group ID filtering (90-99% accurate per category)
- Minimal keyword exclusions needed
- More reliable, faster processing

**Hybrid Approach**:
- Primary: Group ID filter (fast, accurate)
- Fallback: Name prefix + keyword exclusion (catches outliers)
- Validation: Alerts on unknown Group IDs (future-proof)

---

## Maintenance Checklist

When importing a fresh scan:

- [ ] Run `MasterVanityDBPipeline.ps1` (includes automatic validation)
- [ ] Check for validation warnings about unknown Group IDs
- [ ] If warnings appear:
  - [ ] Review affected items
  - [ ] Verify Group IDs on db.ascension.gg
  - [ ] Update `$primaryGroupIds` in scripts
  - [ ] Update this documentation file
  - [ ] Re-run pipeline with updated filters
- [ ] Confirm item count matches expected total

---

## Related Documentation

- **GROUP_FILTERING_IMPLEMENTATION.md** - Technical implementation details
- **GROUP_ID_DISCOVERY.md** - Discovery process and analysis
- **DATABASE_PIPELINE_ARCHITECTURE.md** - Overall pipeline design
- **SESSION_2025-11-05_FINAL_SUMMARY.md** - Recent updates and achievements

---

**Version**: 2.0  
**Status**: Active (8 Group IDs validated)  
**Next Review**: After next major game update or scan
