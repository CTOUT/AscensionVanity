# Family Filter Implementation - Work in Progress

**Status**: Planning Complete - Ready for Implementation  
**Date**: November 16, 2025  
**Target Version**: v2.3 or v2.4

## ✅ Completed Work

### Data Enrichment (100%)
- ✅ Pet family data enriched for 2,355 / 2,355 combat pets (100% coverage)
- ✅ 70 exotic pets identified and marked
- ✅ 152 unique pet families across 7 family types
- ✅ Database optimized (removed redundant isExotic = false entries, saved 67 KB)
- ✅ Manual mappings: 302 entries stored permanently

### Analysis Complete
- ✅ Verified no category/family mismatches (100% consistency)
- ✅ Confirmed exotic status not shown in db.ascension.gg tooltips
- ✅ Determined pet family info redundant in creature tooltips
- ✅ Identified high-value features: Database Browser, Regional Guide, Collection Progress

## 🎯 Next Steps: UI Integration

### Phase 1: Database Browser Family Filters (HIGH PRIORITY)

**Hierarchical Dropdown Structure:**
```
[Select Family Type ▼]
├─ All Families (default)
├─ ─────────────────
├─ Ferocity (~20 families)
│  ├─ Cat, Wolf, Raptor, Wasp, etc.
├─ Tenacity (~20 families)
│  ├─ Bear, Boar, Crab, Turtle, etc.
├─ Cunning (~20 families)
│  ├─ Spider, Serpent, Scorpid, Bat, etc.
├─ Demon (~15 families)
│  ├─ Satyr, Doomguard, Shivarra, etc.
├─ Undead
├─ Dragonkin
└─ Elemental
```

**Implementation Tasks:**

1. **Add to browserState** (DatabaseBrowser.lua ~line 147)
   - Add: `familyTypeFilter = "all"`
   - Add: `familyNameFilter = "all"`
   - Add: `exoticOnlyFilter = false`

2. **Create UI Controls** (DatabaseBrowser.lua ~line 140-145)
   - Family Type dropdown (below learned status filters)
   - Family Name dropdown (cascades from type selection)
   - "Exotic Only" checkbox
   - Layout: New row in filterSection, expand height to ~150px

3. **Helper Functions** (Add to DatabaseBrowser.lua)
   ```lua
   -- Extract unique family types and names from VanityDB
   function AV_GetFamilyHierarchy()
   
   -- Filter by family type
   function AV_DatabaseBrowser_FilterByFamilyType(familyType)
   
   -- Filter by specific family name
   function AV_DatabaseBrowser_FilterByFamilyName(familyName)
   
   -- Toggle exotic only filter
   function AV_DatabaseBrowser_ToggleExotic()
   ```

4. **Update Filtering Logic** (DatabaseBrowser.lua, AV_DatabaseBrowser_RefreshDisplay)
   - Add family type filtering
   - Add family name filtering
   - Add exotic only filtering
   - Combine with existing category/zone/learned filters

5. **Display Enhancement**
   - Add family info to item display (below creature name)
   - Format: `"Family: Wolf (Tenacity)"` or `"Family: Chimaera (Exotic)"`
   - Color code exotic pets (gold/orange)

### Phase 2: Regional Guide Family Filters (MEDIUM PRIORITY)

**Features:**
- Add same family type/name dropdowns
- Add exotic checkbox
- Filter "Show Chimaeras in current zone"

**Files:** RegionalGuide.lua

### Phase 3: Collection Progress Family Tracking (MEDIUM PRIORITY)

**Features:**
- Track collection by family type
- Track exotic pet collection (X/70)
- Display breakdown by family

**Files:** CollectionProgressFrame.lua

## 📊 Database Statistics

- **Total Items**: 2,957
- **Combat Pets**: 2,355 (79.6%)
- **Mounts**: 602 (20.4%)
- **Pet Families**: 152 unique
- **Exotic Pets**: 70 (3.0% of combat pets)

**Family Type Distribution:**
- Ferocity: ~20 families (Cat, Wolf, Raptor, etc.)
- Tenacity: ~20 families (Bear, Boar, Crab, etc.)
- Cunning: ~20 families (Spider, Serpent, Bat, etc.)
- Demon: ~15 families (Satyr, Doomguard, Shivarra, etc.)
- Undead: Multiple families
- Dragonkin: Multiple drakes
- Elemental: Multiple elementals

## 🔑 Key Decisions Made

1. **Skip creature tooltips** - Family info redundant (category already visible)
2. **Skip item tooltips** - Blizzard likely shows family (need to verify)
3. **Focus on filtering** - Real value is discovery/search, not display
4. **Hierarchical structure** - Match Ascension UI (Type → Family)
5. **Exotic indicator** - Show (Exotic) flag since not in db.ascension.gg

## 📁 Related Files

- **Database**: `AscensionVanity/VanityDB.lua` (1,355 KB, 2,355 items with petFamily)
- **Browser UI**: `AscensionVanity/DatabaseBrowser.lua` (648 lines)
- **Regional Guide**: `AscensionVanity/RegionalGuide.lua`
- **Progress Frame**: `AscensionVanity/CollectionProgressFrame.lua`
- **Enrichment Sources**:
  - `data/PetFamilyMapping.json` (9,292 creature mappings)
  - `data/MissingPetFamilies_Final_Enriched.json` (57 tooltip families)
  - `data/ManualPetFamilyMappings.json` (302 manual mappings)

## 🚀 Implementation Order

1. Database Browser family filters (highest impact)
2. Regional Guide family filters (useful for hunting)
3. Collection Progress family tracking (analytics/completionism)

## 💡 Future Enhancements (v2.4+)

- Search bar for family names
- "Similar families" suggestions
- Family icon display in dropdowns
- Export filtered results
- Family-based achievements/milestones

---

**Ready to implement when you return to this feature!**
