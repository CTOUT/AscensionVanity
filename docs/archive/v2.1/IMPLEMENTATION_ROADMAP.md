# Quick Implementation Roadmap

## Summary of Recommendations

Based on analysis, all three proposals are APPROVED and RECOMMENDED:

1. ✅ **Switch to in-game API extraction** (10.2% more coverage, authoritative data)
2. ✅ **Separate files by purpose** (98.3% size reduction for users)
3. ✅ **Add region data** (separate lookup file, backward compatible)

---

## Implementation Order

### Phase 1: File Structure Separation (1-2 hours)
**Goal**: Split monolithic file into focused components

**Tasks**:
- [ ] Create `AscensionVanityConfig.lua` (user settings only)
- [ ] Create `VanityDB.lua` (current static database)
- [ ] Update `Core.lua` to load new files
- [ ] Add migration code for existing users
- [ ] Update `.toc` file with new dependencies
- [ ] Add to `.gitignore`:
  ```
  data/AscensionVanityDB_API.lua
  data/AscensionVanityExport.lua
  ```
- [ ] Test in-game

**Deliverables**:
- Clean file separation
- No functionality loss
- Backward compatible

---

### Phase 2: Enhanced API Extraction (2-3 hours)
**Goal**: Extract optimized database from API with region data

**Tasks**:
- [ ] Create `utilities/GenerateOptimizedDB.ps1`:
  - Read APIDump section
  - Filter to drops only (2,047 items)
  - Parse region from description
  - Generate VanityDB.lua format
  - Generate VanityDB_Regions.lua format
- [ ] Run extraction
- [ ] Validate output
- [ ] Compare with current database

**Deliverables**:
- VanityDB.lua with 2,047 items
- VanityDB_Regions.lua with location data
- Validation report

---

### Phase 3: Region Integration (1-2 hours)
**Goal**: Display location information in tooltips

**Tasks**:
- [ ] Update `Core.lua` tooltip handler:
  - Load VanityDB_Regions.lua (if enabled)
  - Display region in tooltip
  - Format nicely
- [ ] Add `showRegions` config option
- [ ] Test in-game with various items
- [ ] Screenshot examples for documentation

**Deliverables**:
- Working region tooltips
- Config option to toggle

---

### Phase 4: Documentation & Cleanup (1 hour)
**Goal**: Update all docs and guides

**Tasks**:
- [ ] Update `README.md`:
  - New file structure
  - Configuration instructions
  - Region feature
- [ ] Update `EXTRACTION_GUIDE.md`:
  - New extraction process
  - API-based workflow
- [ ] Update `DEPLOYMENT_GUIDE.md`:
  - New files to include
  - .gitignore setup
- [ ] Create `MIGRATION_GUIDE.md` for existing users
- [ ] Update `CHANGELOG.md`

**Deliverables**:
- Complete documentation
- Migration guide
- Updated changelog

---

## Timeline

**Total Estimated Time**: 5-8 hours

**Suggested Schedule**:
- **Day 1**: Phase 1 (file separation) + Phase 2 (extraction script)
- **Day 2**: Phase 3 (region integration) + Phase 4 (documentation)

---

## Testing Checklist

After each phase:
- [ ] Addon loads without errors
- [ ] Tooltips display correctly
- [ ] Database lookups work
- [ ] Config changes persist
- [ ] No Lua errors in-game
- [ ] Performance is acceptable

---

## Rollback Plan

If issues arise:
1. Keep old `AscensionVanity.lua` as backup
2. Revert `.toc` changes
3. Restore old file structure
4. Document issues for future attempts

---

## Questions Before Starting

1. **Approve file separation?** → Yes/No
2. **Approve region data?** → Yes/No
3. **Keep old web scraping?** → Deprecate/Keep as fallback
4. **Region file mandatory or optional?** → Include by default/Optional download

---

## Next Immediate Step

**Start with Phase 1**: Create the separate files and update Core.lua to load them.

Would you like me to:
A) Begin Phase 1 implementation now?
B) Create the extraction script first (Phase 2)?
C) Review the plan and adjust priorities?
