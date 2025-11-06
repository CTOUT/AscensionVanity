# Testing Session - November 6, 2025
## Companion Pet Fix & UI Improvements

### 🎯 Testing Goals
1. Verify companion pet filter works correctly
2. Identify tooltip overlap issues
3. Test creature ID corrections
4. Check UI element positioning

---

## ✅ Test 1: Companion Pet Filter

**Test Cases:**
- [ ] Mouse over another player's companion pet → Should NOT show vanity drops
- [ ] Mouse over hunter pet → Should NOT show vanity drops
- [ ] Mouse over warlock demon → Should NOT show vanity drops
- [ ] Mouse over wild NPC with same creature ID → SHOULD show vanity drops

**Expected Behavior:**
- Player-owned units filtered out using UnitPlayerControlled()
- Wild NPCs with matching creature IDs still work correctly

**Test Results:**
```
Date/Time:
Result:
Notes:
```

---

## 🔍 Test 2: UI Overlap Detection

**Areas to Check:**
- [ ] Tooltip positioning (too close to screen edges?)
- [ ] Multiple items per creature (vertical spacing)
- [ ] Long item names (text truncation/wrapping)
- [ ] Quest warnings (overlapping with item list?)
- [ ] Learned status icons (overlapping with text?)

**Screenshot Locations:**
- Issues found:

**Notes:**
```
Describe overlap issues here with screenshots
```

---

## 📊 Test 3: Creature ID Corrections

**Test Specific Creatures:**
- [ ] Crazed Dragonhawk (was 4015650, now 15650) - Eversong Woods
- [ ] Drakkari Scytheclaw (was 4026628, now 26628) - Drak'Tharon Keep
- [ ] Bloodthirsty Worg (was 4024475, now 24475) - Howling Fjord

**Expected:**
- Tooltips appear on correct NPCs
- No false positives on wrong creatures

**Test Results:**
```
Date/Time:
Results:
```

---

## 🎨 Test 4: UI Element Review

**Check Each Element:**
- [ ] Category icons (Beastmaster, Blood Soaked, etc.)
- [ ] Item name colors (learned = green, unlearned = gold)
- [ ] Zone information formatting
- [ ] Quest warning text (color coding: red/orange/green)
- [ ] Progress frame (draggable, not blocking gameplay)

**Issues Found:**
```
Element | Issue | Severity
--------|-------|----------
        |       |
```

---

## 🐛 Bugs/Issues to Fix

**Priority: High**
- 

**Priority: Medium**
- 

**Priority: Low**
- 

---

## 💡 UI Improvement Ideas

**From Testing:**
1. 
2. 
3. 

**Future Enhancements:**
- 

---

## 📝 Notes

```
Add any additional observations here
```

---

**Tester:** CMTout  
**Date:** November 6, 2025  
**Version:** v2.2-dev (post-companion-pet-fix)  
**Status:** In Progress
