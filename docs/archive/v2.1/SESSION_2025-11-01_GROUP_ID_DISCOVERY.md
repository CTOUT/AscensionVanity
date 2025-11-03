# Group ID Discovery Session - November 1, 2025

## Summary

Today we conducted a comprehensive analysis of the combat pet filtering system and made a critical discovery about Group IDs.

## Key Discovery: The 5 Primary Group IDs

**Finding**: ALL dropped combat pets use exactly 5 Group IDs with 98.5% accuracy.

### The 5 Group IDs:
1. **16777217** - Beastmaster's Whistle (910 items, 99.1% clean)
2. **16777220** - Blood Soaked Vellum (564 items, 96.6% clean)
3. **16777218** - Summoner's Stone (271 items, 98.5% clean)
4. **16777224** - Draconic Warhorn (315 items, 100% clean ✅)
5. **16777232** - Elemental Lodestone (283 items, 98.9% clean)

**Total**: 2,343 combat pet items

### Verification Process

1. **Description Analysis**: Analyzed all 2,343 items for suspicious keywords
   - 81 empty descriptions (3.5%)
   - 2,048 with "drop" keyword (87.4%)
   - 34 vendor/purchase items requiring exclusion (1.5%)

2. **Outlier Detection**: Found 10 seasonal reward pets with non-standard Group IDs
   - Groups: 553648129, 553648130, 553648136
   - All correctly excluded by keyword filters

3. **Comprehensive Verification**: Searched entire database for drops outside 5 groups
   - Found 1,015 items with "drop" keyword
   - ALL were non-combat-pet types (sigils, mounts, weapons, toys)
   - **Conclusion**: 100% coverage confirmed

## Documentation Updated

### 1. Main Project Instructions
**File**: `.github/copilot-instructions.md`
- Added "Combat Pet Group ID Discovery" section
- Documented the 5 primary Group IDs
- Noted outliers and verification status

### 2. Project-Specific Instructions
**File**: `.github/instructions/wow-addon-development.instructions.md`
- Added "Pattern: Group ID Based Filtering" to discovered patterns
- Added "Gotcha: Group ID Coverage Assumption" to project gotchas
- Cross-referenced with main documentation

### 3. Detailed Discovery Document
**File**: `docs/GROUP_ID_DISCOVERY.md`
- Comprehensive analysis and verification details
- Implementation examples for pipeline
- Breakdown of suspicious items by category
- Validation commands for future verification
- Performance and maintenance benefits

## Implementation Impact

### Primary Filter (Performance)
```powershell
# Fast integer comparison - O(1) lookup
if ($primaryGroupIds -contains $groupId) {
    # Item is valid
}
```

### Fallback Filter (Safety)
```powershell
# Keyword exclusion for the 34 vendor items
if ($desc -match 'purchase|vendor|seasonal|reward') {
    # Exclude from database
}
```

## Benefits

1. **Performance**: Integer comparison vs. string matching
2. **Accuracy**: 100% coverage, 98.5% clean rate
3. **Maintainability**: Simple rules, easy to validate
4. **Future-proof**: New drops automatically included

## Next Steps (When Data Available)

When you have access to the data files on the other computer:

1. **Generate Fresh VanityDB.lua**:
   ```powershell
   .\utilities\MasterVanityDBPipeline.ps1 -ScanFile "path\to\SavedVariables\AscensionVanity.lua"
   ```

2. **Validate Results**:
   - Check item counts match expected (2,343 total)
   - Verify all 5 categories are represented
   - Confirm vendor items are excluded

3. **Test In-Game**:
   - `/reload` to load new database
   - Verify tooltips show correct drop information
   - Check for any missing or incorrect items

## Files Modified Today

1. ✅ `.github/copilot-instructions.md` - Added Group ID discovery section
2. ✅ `.github/instructions/wow-addon-development.instructions.md` - Added pattern and gotcha
3. ✅ `docs/GROUP_ID_DISCOVERY.md` - Created comprehensive discovery document

## Verification Status

- ✅ **Analysis Complete**: All 2,343 items analyzed
- ✅ **100% Coverage Confirmed**: No dropped pets outside 5 Group IDs
- ✅ **Documentation Updated**: All project files updated with findings
- ⏳ **Database Generation**: Pending (requires access to data files)
- ⏳ **In-Game Testing**: Pending (after database generation)

## Historical Context

This discovery builds on previous work:
- **v2.0**: Basic name-based filtering with keyword exclusion
- **v2.1-dev**: Group ID analysis and verification
- **Today**: Comprehensive confirmation of 5 Group ID system

The Group ID approach is significantly more reliable and performant than name-based filtering.

---

**Session completed**: November 1, 2025  
**Documentation status**: ✅ Complete  
**Next action**: Generate fresh VanityDB.lua when data files are accessible
