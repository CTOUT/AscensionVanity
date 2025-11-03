# Hybrid Filtering Approach - Implementation Summary

**Date**: November 1, 2025  
**Version**: 2.1  
**Status**: ✅ Ready for Testing

## Decision: Hybrid Filtering

After discussion, we chose **hybrid filtering** over pure in-game filtering:

### In-Game (APIScanner.lua)
- **Minimal filter**: Quality 6 only
- **Export**: ~9,600+ vanity items
- **Why**: Preserves all data, no accidental filtering

### PowerShell (MasterVanityDBPipeline.ps1)
- **Primary filter**: Group ID whitelist (90-99% coverage)
- **Fallback filter**: Name prefix + keyword exclusion (outliers)
- **Output**: ~2,100-2,200 combat pet items

## Key Changes

### APIScanner.lua

**Simplified filtering function:**
```lua
local function ShouldExportItem(itemData)
    if not itemData then return false end
    if itemData.quality ~= VANITY_QUALITY then return false end
    return true
end
```

**Updated scan output:**
- Reports "Quality-6 vanity items exported: ~9,600+"
- Shows "HYBRID MODE" in messages
- Directs user to run PowerShell pipeline next

**Constants marked as reference only:**
- `PRIMARY_GROUP_IDS` - kept for documentation
- `EXCLUSION_KEYWORDS` - kept for documentation
- Actual filtering done in PowerShell

### PowerShell Processing (No Changes Needed)

`MasterVanityDBPipeline.ps1` already has:
- ✅ Group ID filtering logic
- ✅ Name prefix fallback
- ✅ Keyword exclusions
- ✅ Comprehensive reporting

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. In-Game: Run /avanity scan all                          │
│    → Exports ALL quality-6 items (~9,600+)                 │
│    → Includes group field for filtering                     │
│    → Captures game version metadata                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Exit WoW: Data saved to AscensionVanity_Dump.lua        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. PowerShell: Run MasterVanityDBPipeline.ps1              │
│    → Filters by group ID (primary)                          │
│    → Filters by name/keywords (fallback)                    │
│    → Outputs ~2,100-2,200 combat pet items                  │
│    → Generates VanityDB.lua                                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Deploy: VanityDB.lua → Game client                      │
│    → Test in-game tooltips                                  │
│    → Verify no webstore items                               │
└─────────────────────────────────────────────────────────────┘
```

## Trade-offs Analysis

### ✅ Advantages

| Aspect | Benefit |
|--------|---------|
| **Data Preservation** | All quality-6 items saved, nothing lost |
| **Flexibility** | Change filters without re-scanning |
| **Debugging** | Full audit trail of what was filtered |
| **Speed** | PowerShell processes 9,600+ items in seconds |
| **Maintainability** | Filter logic in version-controlled scripts |
| **Testing** | Can validate filters against full dataset |

### ⚠️ Disadvantages (Accepted)

| Aspect | Trade-off |
|--------|-----------|
| **SavedVariables Size** | ~3-4x larger (~8MB vs ~2MB) |
| **Game Exit Time** | Takes longer to save on exit |
| **Initial Processing** | PowerShell must process more items |

**Verdict**: Advantages far outweigh disadvantages. File size and processing time are negligible compared to flexibility gains.

## Testing Checklist

### Phase 1: In-Game Export
- [ ] Deploy updated `APIScanner.lua` to game
- [ ] Run `/avanity scan all`
- [ ] Verify output shows "HYBRID MODE"
- [ ] Confirm ~9,600+ items exported message
- [ ] Check metadata captured (game version, build)
- [ ] Exit WoW successfully (SavedVariables saved)

### Phase 2: PowerShell Processing
- [ ] Locate `AscensionVanity_Dump.lua` in SavedVariables
- [ ] Run `MasterVanityDBPipeline.ps1`
- [ ] Verify ~9,600+ items input
- [ ] Confirm ~2,100-2,200 items after filtering
- [ ] Check exclusion summary (group-based filtering)
- [ ] Inspect generated `VanityDB.lua`

### Phase 3: In-Game Validation
- [ ] Deploy generated `VanityDB.lua`
- [ ] Test tooltips on known creatures
- [ ] Verify combat pets display correctly
- [ ] Confirm NO webstore/seasonal items
- [ ] Check performance (no lag on tooltips)

### Phase 4: Audit Trail Validation
- [ ] Review PowerShell filtering logs
- [ ] Verify group ID filtering stats
- [ ] Check fallback filter usage
- [ ] Confirm expected item counts per category

## Success Criteria

✅ **Export completes** with ~9,600+ quality-6 items  
✅ **Pipeline filters** down to ~2,100-2,200 combat pets  
✅ **Group ID filtering** handles 90-99% of items  
✅ **No webstore items** in final output  
✅ **Metadata captured** (game version, build, addon version)  
✅ **Tooltips work** in-game without errors  

## Rollback Plan

If issues arise:

1. **Export too large?**
   - File size acceptable (8MB is manageable)
   - Game exit time slightly longer but acceptable
   - No action needed

2. **Filtering issues in PowerShell?**
   - Adjust group ID whitelist
   - Tweak exclusion keywords
   - Re-run pipeline (no game re-scan needed!)

3. **Complete rollback needed?**
   - Revert `APIScanner.lua` to previous version
   - Use old filtering logic
   - Keep group field in export (doesn't hurt)

## Files Modified

- ✅ `AscensionVanity/APIScanner.lua` - Simplified to quality-only filtering
- ✅ `docs/GROUP_FILTERING_IMPLEMENTATION.md` - Updated with hybrid approach details
- ✅ `docs/HYBRID_FILTERING_SUMMARY.md` - This file (new)

## Next Actions

1. **Deploy** updated `APIScanner.lua` to WoW client
2. **Run fresh scan** in-game
3. **Process with pipeline** to validate filtering
4. **Test in-game** to confirm everything works
5. **Document results** - update coverage statistics if needed

---

**Ready for testing!** 🚀

The hybrid approach gives us the best of both worlds:
- Simple, reliable in-game export
- Powerful, flexible PowerShell filtering
- Complete data preservation
- Full audit trail
