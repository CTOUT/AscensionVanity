# AscensionVanity v2.1-dev Testing Checklist

**Date:** November 2, 2025  
**Tester:** Chris  
**Build:** Latest v2.1-dev branch

---

## ✅ Pre-Test Setup (2 min)

- [x] Addon deployed successfully (DeployAddon.ps1 ran)
- [x] Launch Project Ascension
- [x] Log in to character
- [x] Enable Lua errors: `/console scriptErrors 1`
- [x] Check for load errors (none expected)
- [x] Open settings: `/ascvan` or `/ascvan settings`

---

## 🎯 Priority 1: Core Functionality (5 min)

### Addon Loading
- [x] No Lua errors on login
- [x] Settings UI opens without errors

### Tooltip Display
- [x] Hover over beast creature → see vanity items
- [ ] Hover over demon creature → see vanity items
- [x] Icons display correctly next to item names
- [x] Learned items show with ✓ or green text (if any collected)

**Test Creatures to Find:**
- Any wolf/bear/cat (Beastmaster's Whistle items)
- Any demon (Blood Soaked Vellum items)
- Any elemental (Summoner's Stone/Elemental Lodestone items)

---

## 🆕 Priority 2: Category Filters (10 min)

### Open Settings UI: `/ascvan settings`

#### Test Each Category Toggle:
- [ ] **Uncheck "Beastmaster's Whistle"**
  - Hover over beast → verify NO pet items show
  - Hover over demon → verify demon items still show
  - ✅ Works | ❌ Issue: _______________

- [ ] **Uncheck "Blood Soaked Vellum"**
  - Hover over demon → verify NO demon items show
  - Hover over beast → verify pet items still show (if re-enabled above)
  - ✅ Works | ❌ Issue: _______________

- [ ] **Uncheck "Summoner's Stone"**
  - Hover over elemental/satyr → verify NO elemental items show
  - ✅ Works | ❌ Issue: _______________

- [ ] **Uncheck "Draconic Warhorn"**
  - Hover over dragonkin → verify NO dragonkin items show
  - ✅ Works | ❌ Issue: _______________

- [ ] **Uncheck "Elemental Lodestone"**
  - Hover over totem/elemental → verify NO totem items show
  - ✅ Works | ❌ Issue: _______________

#### Reset Test:
- [ ] **Check all categories again** → all items show normally

---

## ⚔️ Priority 3: Combat Tooltip Control (5 min)

### Test "Hide Completely" Mode:
- [ ] Set combat mode to "Hide Completely"
- [ ] Enter combat (attack any creature)
- [ ] Hover over creature → verify NO vanity info shows
- [ ] Exit combat
- [ ] Hover over same creature → verify vanity info DOES show
- [ ] ✅ Works | ❌ Issue: _______________

### Test "Count Only" Mode:
- [ ] Set combat mode to "Count Only"
- [ ] Enter combat
- [ ] Hover over creature with items → verify shows "Vanity Items: X available"
- [ ] Verify NO item details/names show (just count)
- [ ] Exit combat → verify full details return
- [ ] ✅ Works | ❌ Issue: _______________

### Test "Show All" Mode:
- [ ] Set combat mode to "Show All"
- [ ] Enter combat
- [ ] Hover over creature → verify full vanity info shows (like normal)
- [ ] ✅ Works | ❌ Issue: _______________

---

## 📊 Priority 4: Collection Status Filter (5 min)

### Test "Show Both" (Default):
- [ ] Set to "Show Both"
- [ ] Hover over creature → see all items (learned + unlearned)
- [ ] ✅ Works | ❌ Issue: _______________

### Test "Learned Only":
- [ ] Set to "Learned Only"
- [ ] Hover over creatures → **only shows items you've collected**
- [ ] If you haven't collected any, tooltips may be empty
- [ ] ✅ Works | ❌ Issue: _______________

### Test "Unlearned Only":
- [ ] Set to "Unlearned Only"
- [ ] Hover over creatures → **only shows items you haven't collected**
- [ ] This should be most/all items if you're a new collector
- [ ] ✅ Works | ❌ Issue: _______________

---

## 🗺️ Priority 5: Zone/Subzone Display ⏭️ FUTURE FEATURE

**Status:** ⚠️ Not implemented yet in v2.1-dev

The database (`VanityDB.lua`) contains zone/subzone data, but the tooltip display code (`Core.lua`) doesn't show it yet. This will be added in a future update.

**Skip this section for now.**

---

## 🔧 Priority 6: Corrected Creature IDs (Optional - 5 min)

These creatures had their IDs corrected. If you can find them, verify they work:

### 400xxxx Prefix Corrections:
- [ ] **Strigid Screecher** (Teldrassil) - was 4001996 → now 1996
- [ ] **Nightsaber Stalker** (Darkshore) - was 4002043 → now 2043
- [ ] **Adult Plainstrider** (The Barrens) - was 4002956 → now 2956

### 98xxx Range Corrections:
- [ ] **Prairie Stalker** (Mulgore) - was 98766 → now 2959
- [ ] **Ice Claw Bear** (Dun Morogh) - was 98767 → now 1196
- [ ] **Snow Leopard** (Dun Morogh) - was 98769 → now 1201

**Notes:**
- _______________________________________________
- _______________________________________________

---

## 🐛 Bug Reporting

### Any Lua Errors Encountered:
```
Error 1: _______________________________________________
When: _______________________________________________

Error 2: _______________________________________________
When: _______________________________________________
```

### Any Display Issues:
```
Issue 1: _______________________________________________
Expected: _______________________________________________
Actual: _______________________________________________

Issue 2: _______________________________________________
Expected: _______________________________________________
Actual: _______________________________________________
```

### Performance Issues:
- [ ] Tooltips feel slow/laggy: ☐ Yes ☐ No
- [ ] Settings UI sluggish: ☐ Yes ☐ No
- [ ] Framerate drops: ☐ Yes ☐ No

---

## 📝 Overall Assessment

**Total Test Time:** ~10 minutes

**Critical Issues Found:** 0 (none found so far)

**Minor Issues Found:** 0 (none found so far)

**Overall Status:**
- [ ] ✅ Ready for beta release (needs more comprehensive testing in mixed-NPC areas)
- [x] ⚠️ Partial testing complete - need access to diverse creature zones
- [ ] ❌ Major issues found

**Testing Completed:**
- ✅ Addon loads without errors
- ✅ Settings UI opens and functions
- ✅ Beast creature tooltips display correctly
- ✅ Icons render properly
- ✅ Core functionality verified

**Testing Pending (need mixed-NPC area access):**
- ⏸️ Category filters (demon, elemental, dragonkin)
- ⏸️ Combat tooltip control modes
- ⏸️ Collection status filtering
- ⏸️ Corrected creature ID verification

**Additional Notes:**
- No Lua errors encountered during initial testing
- Performance seems good (no lag or framerate issues)
- Can resume testing when access to diverse zones available

---

## ✅ Next Steps

After testing:
1. Report findings in chat
2. Fix any critical issues
3. Re-test if needed
4. Prepare for beta release!

**Thank you for testing! 🎉**
