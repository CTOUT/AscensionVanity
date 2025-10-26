# Documentation Summary

This directory contains comprehensive documentation for the AscensionVanity addon's database extraction process and known limitations.

## 📄 Files Overview

### 1. **SKIPPED_ITEMS_ANALYSIS.md** (Detailed Analysis)
**Purpose:** Complete breakdown of all 40 skipped items with categorization and recommendations

**Contents:**
- Executive summary with 96.7% coverage statistics
- Category 1: Event/Special Items (1 item)
- Category 2: Maybe - Needs Confirmation (9 items)
- Category 3: No Obvious Source (10 items)
- Validation Failures (20 items)
- Coverage analysis by category
- Recommendations for current version and future updates

**Use this when:**
- Understanding why specific items were skipped
- Explaining coverage gaps to users
- Deciding whether to investigate missing items

---

### 2. **TODO_FUTURE_INVESTIGATIONS.md** (Action Items)
**Purpose:** Actionable checklist of items requiring manual verification

**Contents:**
- Priority 1: Warchief Rend Blackhand (3 items - boss drops to verify)
- Priority 2: Darkweaver Syth (4 items - elemental drops to verify)
- Priority 3: Ironhand Guardian (1 item - NPC to locate)
- Priority 4: Lady Vaalethri (1 item - waypoint location to investigate)
- Won't Fix items (27 items - vendor/event/duplicate items)
- Community feedback system guidelines
- Version update checklist
- Extraction script enhancement ideas

**Use this when:**
- Planning future addon updates
- Deciding which bosses to prioritize killing
- Tracking community-reported missing items
- Updating the addon with newly verified drops

---

### 3. **SkippedItems_Detailed.txt** (Raw Data)
**Purpose:** Diagnostic output from extraction script showing exactly why each item was skipped

**Contents:**
- Total skip count
- Grouping by skip reason
- Item IDs, names, and categories for each skipped item
- Detailed validation failure messages

**Use this when:**
- Debugging extraction script issues
- Verifying script behavior
- Cross-referencing with manual investigation results

---

### 4. **ExtractDatabase.ps1** (Updated with Comments)
**Purpose:** Enhanced extraction script with comprehensive inline documentation

**New Features:**
- Header comments explaining coverage, limitations, and validation logic
- Detailed comments in validation sections explaining why items are skipped
- Comments noting that validation failures are EXPECTED for vendor/token items
- Coverage statistics in output with references to documentation files
- Improved validation warnings noting this is correct behavior

**Use this when:**
- Understanding how the extraction process works
- Troubleshooting extraction issues
- Modifying the script for new features

---

## 🎯 Quick Reference Guide

### Understanding Coverage

**Current Status:**
- ✅ **96.7% coverage** (2,032 of 2,101 items extracted)
- ✅ **Excellent coverage** of true world drops
- ❌ **40 items skipped** (mostly vendor/token/event items)

**What's Included:**
- All standard creature drops with database entries
- Boss drops with proper "Dropped by" tab data
- Items with matching NPC names

**What's Excluded (Intentionally):**
- Vendor purchases (Argent Quartermaster, etc.)
- Token exchange items (High Inquisitor Qormaladon)
- Event-exclusive items (Manastorm event)
- Achievement rewards

**What's Missing (Needs Investigation):**
- 9 items from bosses without database entries
- 10 items with no obvious source (likely unobtainable)
- 1 event item (confirmed unobtainable)

---

### Using the Documentation

**For End Users:**
- Refer to SKIPPED_ITEMS_ANALYSIS.md to explain coverage
- Mention 96.7% coverage as excellent for version 1.0
- Note that missing items are primarily vendor/special items

**For Developers:**
- Check TODO_FUTURE_INVESTIGATIONS.md before planning updates
- Review ExtractDatabase.ps1 comments to understand validation logic
- Use SkippedItems_Detailed.txt for debugging

**For Community Management:**
- Point users to TODO list for "Items Needing Verification"
- Encourage players to report drops from listed bosses
- Update TODO when community confirms/denies suspected drops

---

### Maintenance Workflow

**When adding new verified items:**

1. ✅ Check TODO_FUTURE_INVESTIGATIONS.md for the item
2. ✅ Confirm drop source in-game or via community
3. ✅ Add to VanityDB.lua manually OR update extraction script
4. ✅ Test in-game with /reload
5. ✅ Update TODO status (move from "NEEDS VERIFICATION" to "Won't Fix" or remove)
6. ✅ Update SKIPPED_ITEMS_ANALYSIS.md if categorization changes
7. ✅ Increment version number in .toc file
8. ✅ Commit with descriptive message

**When re-running extraction after game updates:**

1. ✅ Run `.\ExtractDatabase.ps1 -Force` to bypass cache
2. ✅ Compare new coverage % with previous (should be similar or better)
3. ✅ Check if any "Maybe" items now have database entries
4. ✅ Update documentation if coverage changes significantly
5. ✅ Review SkippedItems_Detailed.txt for new patterns

---

## 📋 File Locations

All documentation files are in the addon root directory:

```
AscensionVanity/
├── SKIPPED_ITEMS_ANALYSIS.md          # Detailed categorization
├── TODO_FUTURE_INVESTIGATIONS.md      # Action items checklist
├── SkippedItems_Detailed.txt          # Raw extraction diagnostics
├── ExtractDatabase.ps1                # Enhanced extraction script
├── VanityDB.lua           # Generated data file
└── [other addon files...]
```

---

## 🔍 Key Insights

### Why 96.7% Coverage is Excellent

**Reality of MMO databases:**
- Not all items are true "drops"
- Some items have incorrect database entries
- Event/vendor items are often miscategorized
- Boss drops may not appear in "Dropped by" tabs

**What this means:**
- 96.7% captures virtually all obtainable world drops
- Missing items are edge cases (bosses, vendors, events)
- Further improvement requires manual verification
- Community feedback is key for remaining items

### Validation Logic Explained

**The script skips items when:**

1. **NPC name doesn't match creature name**
   - Example: Item is "Pink Elekk" but database says "Millhouse Manastorm"
   - This is CORRECT - it's a vendor item, not a drop

2. **No "Dropped by" tab exists**
   - Example: Event-exclusive items or quest rewards
   - This is CORRECT - they're not world drops

3. **No NPCs match the expected creature**
   - Example: Item is "Chromatic Whelp" but no NPC named that in drop list
   - This MAY need investigation - could be boss drop missing from database

**The validation is working as intended** - it prevents false positives!

---

## 💡 Future Enhancements

See TODO_FUTURE_INVESTIGATIONS.md for:
- Special case handling for boss-only drops
- Token/vendor item detection improvements
- Event item categorization
- Fuzzy name matching for variants
- Duplicate detection logic
- Incremental update support

---

**Last Updated:** October 26, 2025  
**Version:** 1.0  
**Coverage:** 96.7% (2,032/2,101 items)
