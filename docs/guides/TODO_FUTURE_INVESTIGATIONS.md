# AscensionVanity - Future Investigations TODO List

**Last Updated:** October 26, 2025  
**Current Version Coverage:** 96.7% (2,032 / 2,101 items)

---

## Priority 1: Boss Drop Verification (3 items)

### Warchief Rend Blackhand (Upper Blackrock Spire)

**Status:** 🔴 NEEDS VERIFICATION  
**Required:** Defeat boss and check loot table

| Item ID | Item Name | Expected Drop |
|---------|-----------|---------------|
| 1180319 | Draconic Warhorn: Chromatic Dragonspawn | Warchief Rend Blackhand |
| 1180316 | Draconic Warhorn: Chromatic Whelp | Warchief Rend Blackhand |
| 1180308 | Draconic Warhorn: Gyth | Warchief Rend Blackhand |

**Action Required:**
- [ ] Defeat Warchief Rend Blackhand
- [ ] Check if any of these 3 items drop
- [ ] If confirmed, get NPC ID from database
- [ ] Add to VanityDB.lua as specific creature drops

**NPC Information:**
- Name: Warchief Rend Blackhand
- Location: Upper Blackrock Spire
- Database: https://db.ascension.gg/?npc=10429

**Code to Add (if confirmed):**
```lua
["Chromatic Dragonspawn"] = {
    itemID = 1180319,
    itemName = "Draconic Warhorn: Chromatic Dragonspawn",
    type = "Dragonkin",
    npcID = 10429  -- Warchief Rend Blackhand
},
["Chromatic Whelp"] = {
    itemID = 1180316,
    itemName = "Draconic Warhorn: Chromatic Whelp",
    type = "Dragonkin",
    npcID = 10429  -- Warchief Rend Blackhand
},
["Gyth"] = {
    itemID = 1180308,
    itemName = "Draconic Warhorn: Gyth",
    type = "Dragonkin",
    npcID = 10429  -- Warchief Rend Blackhand
},
```

---

## Priority 2: Darkweaver Syth Elemental Verification (4 items)

### Darkweaver Syth (Sethekk Halls)

**Status:** 🔴 NEEDS VERIFICATION  
**Required:** Defeat boss and check loot table

| Item ID | Item Name | Expected Drop |
|---------|-----------|---------------|
| 1777428 | Elemental Lodestone: Syth Arcane Elemental | Darkweaver Syth |
| 1777426 | Elemental Lodestone: Syth Fire Elemental | Darkweaver Syth |
| 600865 | Elemental Lodestone: Syth Frost Elemental | Darkweaver Syth |
| 600866 | Elemental Lodestone: Syth Shadow Elemental | Darkweaver Syth |

**Action Required:**
- [ ] Defeat Darkweaver Syth (Sethekk Halls)
- [ ] Check if any of these 4 elemental items drop
- [ ] If confirmed, get NPC ID from database
- [ ] Add to VanityDB.lua as specific creature drops

**NPC Information:**
- Name: Darkweaver Syth
- Location: Sethekk Halls (Terokkar Forest)
- Database: https://db.ascension.gg/?npc=18472

**Code to Add (if confirmed):**
```lua
["Syth Arcane Elemental"] = {
    itemID = 1777428,
    itemName = "Elemental Lodestone: Syth Arcane Elemental",
    type = "Elemental",
    npcID = 18472  -- Darkweaver Syth
},
["Syth Fire Elemental"] = {
    itemID = 1777426,
    itemName = "Elemental Lodestone: Syth Fire Elemental",
    type = "Elemental",
    npcID = 18472  -- Darkweaver Syth
},
["Syth Frost Elemental"] = {
    itemID = 600865,
    itemName = "Elemental Lodestone: Syth Frost Elemental",
    type = "Elemental",
    npcID = 18472  -- Darkweaver Syth
},
["Syth Shadow Elemental"] = {
    itemID = 600866,
    itemName = "Elemental Lodestone: Syth Shadow Elemental",
    type = "Elemental",
    npcID = 18472  -- Darkweaver Syth
},
```

---

## Priority 3: Named Creature Verification (1 item)

### Ironhand Guardian

**Status:** 🟡 NEEDS INVESTIGATION  
**Required:** Find and defeat creature

| Item ID | Item Name | Expected Drop |
|---------|-----------|---------------|
| 601687 | Elemental Lodestone: Ironhand Guardian | Ironhand Guardian |

**Action Required:**
- [ ] Search Ascension database for "Ironhand Guardian" NPC
- [ ] If exists, find location in game
- [ ] Defeat and check if item drops
- [ ] Add to VanityDB.lua if confirmed

**Investigation Steps:**
1. Check database: https://db.ascension.gg/?npcs&filter=na=Ironhand%20Guardian
2. If found, note NPC ID and location
3. Kill and verify drop
4. Add to addon data

---

## Priority 4: Location-Based Investigation (1 item)

### Lady Vaalethri

**Status:** 🟡 NEEDS INVESTIGATION  
**Required:** Community reports suggest specific waypoint location

| Item ID | Item Name | Notes |
|---------|-----------|-------|
| 254055 | Summoner's Stone: Lady Vaalethri | Database comments mention waypoint coordinates |

**Action Required:**
- [ ] Review database comments for waypoint information
- [ ] Visit suggested location
- [ ] Find and defeat creature if it exists
- [ ] Confirm drop and add to addon

**Database:** https://db.ascension.gg/?item=254055

---

## Won't Fix - Known Issues

### Event/Special Items (Exclude from addon)

| Item ID | Item Name | Reason |
|---------|-----------|--------|
| 1519393 | Beastmaster's Whistle: Arktos | Manastorm event cache reward |
| 532578 | Beastmaster's Whistle: Doberman MK III | Millhouse Manastorm vendor |
| 980060 | Beastmaster's Whistle: Pink Elekk | Millhouse Manastorm vendor |
| 532579 | Elemental Lodestone: Bound Water Elemental | Millhouse Manastorm vendor |
| 79263 | Beastmaster's Whistle: Skreeg | Lil' Al'ar special reward |

**Status:** ✅ INTENTIONALLY EXCLUDED - Not world drops

---

### Vendor/Token Items (Exclude from addon)

**Argent Quartermaster Vendor Items:**
- 400070, 400076, 400071, 400079, 400080
- 88978, 400075, 400072, 400078, 400074, 400077

**High Inquisitor Qormaladon Token Exchanges:**
- 79258, 601016, 79256, 79262, 79260

**Status:** ✅ INTENTIONALLY EXCLUDED - Purchased or token exchange, not drops

---

### Duplicates/Unobtainable (Low priority investigation)

| Item ID | Item Name | Status |
|---------|-----------|--------|
| 1180323 | Draconic Warhorn: Cobalt Whelp | Suspected duplicate |
| 1180481 | Draconic Warhorn: Dreadwing | Suspected duplicate |
| 1181505 | Draconic Warhorn: Chromatic Whelp (variant) | No source found |
| 1180318 | Draconic Warhorn: Chromatic Whelp (variant) | No source found |
| 1180402 | Draconic Warhorn: Bronze Drakonid | No source found |
| 1180701 | Draconic Warhorn: Ley-Guardian Eregos | No source found |
| 601862 | Elemental Lodestone: Outraged Raven's Wood Sapling | No source found |
| 601843 | Elemental Lodestone: Treant Ally | No source found |
| 139581 | Summoner's Stone: Apolyon (Hand of the Deceiver) | No source found |
| 254054 | Summoner's Stone: Sulkaia | No source found |

**Status:** 🟣 LOW PRIORITY - Likely database errors or removed content

---

## Community Feedback System

### How to Report Missing Items

If players report creatures that should show tooltips but don't:

1. **Get Item Information:**
   - Item ID
   - Item name
   - Source creature name
   - NPC ID (if known)

2. **Verify Drop:**
   - Check Ascension database
   - Confirm creature actually drops the item
   - Note any special conditions

3. **Update Process:**
   - Add to VanityDB.lua manually OR
   - Update extraction script with special case handling
   - Test in-game
   - Increment version number

### Version Update Checklist

When adding new verified items:

- [ ] Update TODO list with new information
- [ ] Add items to VanityDB.lua
- [ ] Update version number in .toc file
- [ ] Test in-game with /reload
- [ ] Update SKIPPED_ITEMS_ANALYSIS.md
- [ ] Commit changes with descriptive message

---

## Extraction Script Enhancement Ideas

### Future Improvements

**Special Case Handling:**
- [ ] Add flag for "boss-only drops" vs "world drops"
- [ ] Implement token/vendor item detection
- [ ] Add event item categorization

**Data Quality:**
- [ ] Implement fuzzy name matching for variants
- [ ] Add duplicate detection logic
- [ ] Create validation report for suspicious patterns

**Performance:**
- [ ] Optimize cache handling for large datasets
- [ ] Add incremental update support
- [ ] Implement parallel processing for faster extraction

---

## Notes for Future Maintainers

**Coverage Target:** 96-98% is realistic. Some items will always be:
- Event exclusive
- Vendor purchases  
- Token exchanges
- Database errors

**Update Schedule Recommendation:**
- Review TODO quarterly
- Check for new vanity items in patch notes
- Monitor community Discord/forums for drop reports
- Run extraction script after major game updates

**When Database Changes:**
If Ascension updates their database structure:
1. Check if HTML/CSS selectors still work
2. Update extraction script if needed
3. Re-run full extraction
4. Compare results with previous version
5. Investigate any significant changes in coverage

---

**End of TODO List**
