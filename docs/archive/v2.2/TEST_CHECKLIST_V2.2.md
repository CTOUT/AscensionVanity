# AscensionVanity v2.2 Testing Checklist

**Version:** 2.2-dev  
**Test Date:** November 4, 2025  
**Status:** Ready for Testing

---

## Pre-Testing Setup

- [ ] Clean installation (remove old SavedVariables)
- [ ] `/reload` after installation
- [ ] Verify addon loads without errors (`/console scriptErrors 1`)

---

## Feature 1: Collection Progress Tracker

### Basic Functionality
- [ ] `/avanity progress` - Opens progress tracker
- [ ] Frame is moveable via dragging
- [ ] Frame position persists after `/reload`
- [ ] Close button works (X in top-right)
- [ ] ESC key closes the frame

### Progress Display
- [ ] Overall progress bar shows correct percentage
- [ ] Overall bar color codes: Red (<50%), Yellow (50-80%), Green (>80%)
- [ ] Per-category bars show correct counts (Beast, Demon, Undead, Dragonkin, Elemental)
- [ ] Learned items show in green, total items in white

### View Modes
- [ ] **Zone View (Default)**:
  - [ ] Shows items available in current zone
  - [ ] Changes when you move to different zones
  - [ ] Empty categories are hidden
  - [ ] Zone name updates in real-time
- [ ] **Global View**:
  - [ ] Click "Zone" button switches to "Global"
  - [ ] Shows all items across all zones
  - [ ] All categories visible (even if 0 learned)
  - [ ] Switching back to Zone view works

### Expand/Collapse
- [ ] Overall bar has expand/collapse button (▼/▶)
- [ ] Clicking overall button shows/hides all category bars
- [ ] Each category has expand/collapse button (ready for future species breakdown)
- [ ] State persists during session

### Refresh Button
- [ ] Manual refresh button (⟳) updates progress
- [ ] Auto-refresh works every 5 seconds when visible
- [ ] Tooltip explains refresh function

### Details Button
- [ ] "Details" button visible in header
- [ ] Click opens Database Browser
- [ ] **In Zone View**: Opens browser filtered to current zone
- [ ] **In Global View**: Opens browser showing all zones

### Settings Integration
- [ ] Checkbox in Settings UI to show/hide progress frame
- [ ] "Collection Progress" button in Settings opens the frame
- [ ] Settings change takes effect immediately

---

## Feature 2: Database Browser / Regional Guide

### Basic Functionality
- [ ] `/avanity browser` - Opens database browser
- [ ] `/avanity db` - Alias works
- [ ] `/avanity database` - Alias works
- [ ] Frame is moveable via dragging
- [ ] Frame position persists after `/reload`
- [ ] Close button works (X in top-right)
- [ ] ESC key closes the frame

### Zone Filtering
- [ ] **Current Zone Button**:
  - [ ] Filters to current zone
  - [ ] Title shows "Regional Guide - [Zone Name]"
  - [ ] Results count shows creatures in zone
  - [ ] Auto-updates when changing zones
- [ ] **All Zones Button**:
  - [ ] Shows all creatures from all zones
  - [ ] Title shows "Database Browser"
  - [ ] Results count shows total creatures

### Category Filtering
- [ ] All categories button shows all creature types
- [ ] Beast button filters to Beast category only
- [ ] Demon button filters to Demon category only
- [ ] Undead button filters to Undead category only
- [ ] Dragonkin button filters to Dragonkin category only
- [ ] Elemental button filters to Elemental category only
- [ ] Category filter works with zone filter (combined filtering)

### Learned Status Filtering
- [ ] "All Items" shows everything
- [ ] "Unlearned Only" shows creatures with unlearned items
- [ ] "Learned Only" shows creatures with learned items
- [ ] Status filter works with zone and category filters

### Display & Results
- [ ] Creatures listed alphabetically
- [ ] Each entry shows:
  - [ ] Creature name
  - [ ] Zone and subzone (if available)
  - [ ] All items dropped by creature
  - [ ] Learned items marked in green with ✓
  - [ ] Unlearned items in white
- [ ] Results count updates with filters
- [ ] Scroll bar works for long lists
- [ ] Multiple items per creature display correctly

### Integration Points
- [ ] "Details" button in Progress Tracker opens browser
- [ ] "Database Browser" button in Settings UI works
- [ ] Opening from Progress Tracker respects current view mode
- [ ] `/avanity help` lists browser commands

---

## Feature 3: Legacy Chat-Based Regional Guide

- [ ] `/avanity zone` - Shows zone items in chat
- [ ] `/avanity regional` - Alias works
- [ ] `/avanity guide` - Alias works
- [ ] Chat output lists creatures and items
- [ ] Only shows unlearned items
- [ ] Works alongside new Database Browser

---

## Cross-Feature Testing

### Zone Changes
- [ ] Progress Tracker (Zone View) updates on zone change
- [ ] Database Browser (Current Zone) updates on zone change
- [ ] No lag or performance issues during zone transitions

### Learning Items
- [ ] Learn a vanity item in-game
- [ ] Progress Tracker updates (within 5 seconds or on manual refresh)
- [ ] Database Browser updates (green checkmark appears)
- [ ] Percentage calculations update correctly

### Multiple Features Open
- [ ] Can have Progress Tracker + Database Browser open simultaneously
- [ ] Both update independently
- [ ] No conflicts or frame overlaps
- [ ] Both draggable without issues

### Settings Persistence
- [ ] Progress Tracker position saves
- [ ] Database Browser position saves
- [ ] Show/hide preference for Progress Tracker saves
- [ ] All settings persist after `/reload`

---

## Performance Testing

- [ ] No noticeable FPS drops with frames open
- [ ] Zone changes are smooth (no stuttering)
- [ ] Filtering in Database Browser is instant
- [ ] No memory leaks (check with `/run collectgarbage("collect") print(gcinfo())` before/after)

---

## Error Testing

- [ ] Open frames before VanityDB loads (should not error)
- [ ] Spam refresh button (should not error)
- [ ] Rapid zone changes (should not error)
- [ ] Toggle filters rapidly (should not error)
- [ ] Open/close frames rapidly (should not error)

---

## User Experience

### Discoverability
- [ ] Help command lists all new features
- [ ] Settings UI buttons are clearly labeled
- [ ] Tooltips explain button functions

### Intuitive Usage
- [ ] Zone filtering is obvious (button labels clear)
- [ ] Category icons/colors match addon theme
- [ ] Results count helps orient the user
- [ ] Scroll behavior is smooth and expected

### Accessibility
- [ ] All text is readable (size and contrast)
- [ ] Buttons are large enough to click
- [ ] Tooltips provide helpful context
- [ ] No critical information hidden

---

## Known Issues / Future Enhancements

Document any issues found during testing:

**Issues:**
- [ ] None yet (to be discovered during testing)

**Future Enhancements (v2.3+):**
- [ ] Quest-Locked NPC warnings
- [ ] World map integration
- [ ] Minimap integration
- [ ] Search box in Database Browser
- [ ] Species-level breakdown in Progress Tracker

---

## Sign-Off

**Tester:** _______________  
**Date:** _______________  
**Build Tested:** v2.2-dev  
**Overall Status:** ⬜ Pass | ⬜ Pass with Minor Issues | ⬜ Fail  

**Notes:**
```
[Add testing notes here]
```

---

**Ready for Release Criteria:**
- All core features tested and working
- No critical bugs
- Performance is acceptable
- User experience is smooth
- Documentation updated
