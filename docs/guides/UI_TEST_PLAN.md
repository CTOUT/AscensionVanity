# UI Test Plan - AscensionVanity v2.0

**Branch:** v2.0-dev  
**Test Date:** _____________  
**Tester:** _____________  
**Build Version:** 2.0.0

## Overview

This test plan covers the complete UI overhaul including:
- Standalone Settings UI with DialogBox styling
- Standalone Scanner UI with DialogBox styling
- Interface Options launcher panel
- Mutual exclusion between UIs
- Real-time slash command synchronization
- Debug Mode relocation to Scanner UI

---

## Pre-Test Setup

### Required Environment
- [ ] Fresh WoW client restart
- [ ] AscensionVanity v2.0 deployed to addons folder
- [ ] No other addons that might conflict with UI
- [ ] `/console reloadui` to ensure clean load

### Verification Steps
1. Type `/avanity help` - Should show all commands
2. Check Interface Options → AddOns list - "AscensionVanity" should be visible
3. Verify no Lua errors on load (check Lua Error addon or in-game error display)

---

## Test Suite 1: Interface Options Integration

### Test 1.1: Addon List Presence
**Expected:** AscensionVanity appears in Interface Options addon list

**Steps:**
1. Press `Esc` → Interface → AddOns
2. Look for "AscensionVanity" in the list

**Pass Criteria:**
- [ ] "AscensionVanity" is visible in addon list
- [ ] Appears alphabetically sorted (under "Ascension NamePlates", above "Auctionator")
- [ ] Has proper highlight on hover
- [ ] Clicking shows launcher panel

### Test 1.2: Launcher Panel Content
**Expected:** Simple launcher panel with two buttons

**Steps:**
1. Click "AscensionVanity" in addon list
2. Examine panel content

**Pass Criteria:**
- [ ] Title reads "AscensionVanity"
- [ ] Description text is present and readable
- [ ] "Open Settings" button visible
- [ ] "Open API Scanner" button visible
- [ ] Clean, professional layout

---

## Test Suite 2: Settings UI

### Test 2.1: Opening Settings UI
**Expected:** Settings UI opens as standalone draggable frame

**Access Methods:**
1. Method A: Type `/avanity`
2. Method B: Interface Options → AscensionVanity → "Open Settings"
3. Method C: From Scanner UI → "Open Settings" button

**Pass Criteria (for each method):**
- [ ] Settings UI opens in center of screen
- [ ] Frame has DialogBox styling (bordered frame)
- [ ] Title reads "AscensionVanity Settings"
- [ ] Version "2.0.0" displayed under title
- [ ] Description text visible
- [ ] All checkboxes visible and properly labeled

### Test 2.2: Settings UI Visual Layout
**Expected:** Clean, professional layout

**Pass Criteria:**
- [ ] Frame size: 600×430 pixels (comfortable, not cramped)
- [ ] Close button (X) in top-right corner
- [ ] All checkboxes properly aligned
- [ ] Separators between sections visible
- [ ] "Open API Scanner" button visible
- [ ] "Settings are saved automatically" text at bottom
- [ ] No text overlap or clipping
- [ ] All text readable (proper contrast)

### Test 2.3: Settings UI Interaction
**Expected:** All controls function correctly

**Steps:**
1. Click and drag title bar
2. Click checkboxes
3. Click "Open API Scanner" button
4. Click X button
5. Press ESC key

**Pass Criteria:**
- [ ] Frame is movable by dragging
- [ ] Frame stays within screen bounds (clamped)
- [ ] Checkboxes toggle on/off
- [ ] Clicking "Open API Scanner" closes Settings and opens Scanner
- [ ] X button closes Settings UI
- [ ] ESC key closes Settings UI

### Test 2.4: Checkbox States and Dependencies
**Expected:** Checkboxes show correct states and enforce dependencies

**Test Sequence:**
1. Start with all enabled
2. Uncheck "Enable Tooltip Integration"
3. Check "Enable Tooltip Integration"
4. Uncheck "Show Learned Status"
5. Check "Show Learned Status"

**Pass Criteria:**
- [ ] Initial state matches saved settings
- [ ] Unchecking "Enable" disables all child checkboxes
- [ ] Unchecking "Enable" greys out child labels
- [ ] Checking "Enable" re-enables child checkboxes
- [ ] Unchecking "Show Learned Status" disables "Color Code Items"
- [ ] Checking "Show Learned Status" enables "Color Code Items"
- [ ] "Show Region Information" is disabled (coming soon)
- [ ] Changes save immediately (no "Apply" button needed)

### Test 2.5: Settings Persistence
**Expected:** Settings persist across sessions

**Steps:**
1. Change all settings to opposite of defaults
2. Close Settings UI
3. Type `/reload` or restart WoW
4. Open Settings UI

**Pass Criteria:**
- [ ] All checkbox states match what was set before reload
- [ ] No settings reset to defaults unexpectedly

---

## Test Suite 3: Scanner UI

### Test 3.1: Opening Scanner UI
**Expected:** Scanner UI opens as standalone draggable frame

**Access Methods:**
1. Method A: Type `/avanity scanner`
2. Method B: Settings UI → "Open API Scanner" button
3. Method C: Interface Options → AscensionVanity → "Open API Scanner"

**Pass Criteria (for each method):**
- [ ] Scanner UI opens in center of screen
- [ ] Frame has DialogBox styling (matches Settings UI)
- [ ] Title reads "AscensionVanity Scanner"
- [ ] Version "2.0.0" displayed under title
- [ ] All sections visible (Status, Actions, Developer Options, Instructions)

### Test 3.2: Scanner UI Visual Layout
**Expected:** Professional layout with all content visible

**Pass Criteria:**
- [ ] Frame size: 650×680 pixels (tall enough for all content)
- [ ] Close button (X) in top-right corner
- [ ] Current Status section displays scan info
- [ ] All 4 action buttons visible and properly labeled
- [ ] Debug Mode checkbox visible under "Developer Options"
- [ ] "How to Use" instructions fully visible
- [ ] "Slash Commands" section fully visible (no cutoff)
- [ ] No text overlap or clipping anywhere

### Test 3.3: Scanner UI Interaction
**Expected:** All controls function correctly

**Steps:**
1. Click and drag title bar
2. Click each action button
3. Toggle Debug Mode checkbox
4. Click "Open Settings" button
5. Click X button
6. Press ESC key

**Pass Criteria:**
- [ ] Frame is movable by dragging
- [ ] Frame stays within screen bounds (clamped)
- [ ] "Scan All Items" starts API scan (if not already running)
- [ ] "Clear Dump Data" shows confirmation dialog
- [ ] "Refresh Status" updates status display
- [ ] "Open Settings" closes Scanner and opens Settings
- [ ] Debug Mode checkbox toggles on/off
- [ ] X button closes Scanner UI
- [ ] ESC key closes Scanner UI

### Test 3.4: Debug Mode Checkbox
**Expected:** Debug checkbox syncs with setting and slash commands

**Test Sequence:**
1. Check Debug Mode checkbox
2. Close Scanner UI
3. Type `/avanity debug` (to toggle off)
4. Open Scanner UI
5. With Scanner open, type `/avanity debug` (to toggle on)

**Pass Criteria:**
- [ ] Checking box enables debug mode
- [ ] Unchecking box disables debug mode
- [ ] After step 4: Checkbox shows unchecked (synced on open)
- [ ] After step 5: Checkbox updates immediately while UI is open
- [ ] Chat shows debug mode status changes

---

## Test Suite 4: Mutual Exclusion

### Test 4.1: Settings Opens, Scanner Closes
**Expected:** Only Settings UI can be open at a time

**Test Sequence:**
1. Open Scanner UI
2. Verify Scanner is visible
3. Click "Open Settings" button in Scanner
4. Verify Settings opens and Scanner closes
5. Try `/avanity` command
6. Verify Settings is still open (not duplicated)

**Pass Criteria:**
- [ ] After step 3: Scanner closes automatically
- [ ] After step 3: Settings opens
- [ ] After step 5: Only one Settings frame (no duplicate)
- [ ] No UI overlap or z-fighting

### Test 4.2: Scanner Opens, Settings Closes
**Expected:** Only Scanner UI can be open at a time

**Test Sequence:**
1. Open Settings UI
2. Verify Settings is visible
3. Click "Open API Scanner" button in Settings
4. Verify Scanner opens and Settings closes
5. Try `/avanity scanner` command
6. Verify Scanner is still open (not duplicated)

**Pass Criteria:**
- [ ] After step 3: Settings closes automatically
- [ ] After step 3: Scanner opens
- [ ] After step 5: Only one Scanner frame (no duplicate)
- [ ] No UI overlap or z-fighting

### Test 4.3: Interface Options Launcher Mutual Exclusion
**Expected:** Launcher buttons enforce mutual exclusion

**Test Sequence:**
1. Open Interface Options → AscensionVanity
2. Click "Open Settings" → Verify Settings opens
3. Return to Interface Options → AscensionVanity
4. Click "Open API Scanner" → Verify Settings closes, Scanner opens
5. Return to Interface Options → AscensionVanity
6. Click "Open Settings" → Verify Scanner closes, Settings opens

**Pass Criteria:**
- [ ] After step 2: Only Settings visible
- [ ] After step 4: Settings closed, only Scanner visible
- [ ] After step 6: Scanner closed, only Settings visible
- [ ] No instances where both UIs are visible simultaneously

### Test 4.4: All Access Points Mutual Exclusion Matrix
**Expected:** Complete mutual exclusion from all access points

**Test Matrix:**

| Scenario | Action | Expected Result | Pass |
|----------|--------|----------------|------|
| Both closed | `/avanity` | Settings opens | ☐ |
| Both closed | `/avanity scanner` | Scanner opens | ☐ |
| Both closed | Launcher → Open Settings | Settings opens | ☐ |
| Both closed | Launcher → Open Scanner | Scanner opens | ☐ |
| Settings open | `/avanity scanner` | Settings closes, Scanner opens | ☐ |
| Settings open | Settings button → Open Scanner | Settings closes, Scanner opens | ☐ |
| Settings open | Launcher → Open Scanner | Settings closes, Scanner opens | ☐ |
| Scanner open | `/avanity` | Scanner closes, Settings opens | ☐ |
| Scanner open | Scanner button → Open Settings | Scanner closes, Settings opens | ☐ |
| Scanner open | Launcher → Open Settings | Scanner closes, Settings opens | ☐ |

---

## Test Suite 5: Slash Command Synchronization

### Test 5.1: Debug Command Sync with Scanner UI
**Expected:** Debug checkbox updates in real-time

**Test Sequence:**
1. Open Scanner UI
2. Verify Debug Mode checkbox state
3. Type `/avanity debug` (toggle on)
4. Observe checkbox (should check immediately)
5. Type `/avanity debug` (toggle off)
6. Observe checkbox (should uncheck immediately)
7. Close Scanner, toggle debug via command
8. Open Scanner
9. Verify checkbox matches current debug state

**Pass Criteria:**
- [ ] Step 4: Checkbox checks immediately (real-time update)
- [ ] Step 6: Checkbox unchecks immediately (real-time update)
- [ ] Step 9: Checkbox syncs on open (OnShow update)
- [ ] Chat shows debug mode status messages
- [ ] No delay or need to close/reopen UI

### Test 5.2: Settings Commands Sync with Settings UI
**Expected:** All settings checkboxes update in real-time

**Test for each command:**
- `/avanity toggle` (Enable Tooltip Integration)
- `/avanity learned` (Show Learned Status)
- `/avanity color` (Color Code Items)

**Test Sequence (repeat for each command):**
1. Open Settings UI
2. Note current checkbox state
3. Type command
4. Observe checkbox (should toggle immediately)
5. Type command again
6. Observe checkbox (should toggle back immediately)

**Pass Criteria (for each command):**
- [ ] Checkbox updates immediately while UI is open
- [ ] Chat shows status change message
- [ ] Dependent checkboxes update (e.g., color requires learned)
- [ ] No delay or flicker

### Test 5.3: Settings Sync When UI Closed
**Expected:** Settings sync when UI is reopened

**Test Sequence:**
1. Close all UIs
2. Type `/avanity toggle` (or any setting command)
3. Type `/avanity learned`
4. Type `/avanity color`
5. Open Settings UI
6. Verify all checkbox states

**Pass Criteria:**
- [ ] All checkboxes show correct states on open
- [ ] States match what slash commands set
- [ ] Dependencies correctly reflected (e.g., color disabled if learned off)

---

## Test Suite 6: Frame Layering and Strata

### Test 6.1: Dialog Strata Verification
**Expected:** Both UIs render at DIALOG strata above game world

**Test Sequence:**
1. Open Settings UI
2. Mouse over game world elements (NPCs, objects)
3. Open Scanner UI (Settings should close)
4. Mouse over game world elements
5. Open both UIs sequentially and verify no overlap

**Pass Criteria:**
- [ ] Settings UI renders above game world
- [ ] Settings UI renders above tooltips
- [ ] Scanner UI renders above game world
- [ ] Scanner UI renders above tooltips
- [ ] No z-fighting or rendering artifacts
- [ ] Text is always readable (not occluded)

### Test 6.2: No UI Overlap
**Expected:** UIs don't overlap each other due to mutual exclusion

**Pass Criteria:**
- [ ] Cannot open both Settings and Scanner simultaneously
- [ ] When one opens, the other automatically closes
- [ ] No visual clipping or overlap at any point

---

## Test Suite 7: Accessibility and Edge Cases

### Test 7.1: Resolution Compatibility
**Expected:** UIs work at different resolutions

**Test at multiple resolutions:**
- 1920×1080 (common)
- 1280×720 (lower)
- 2560×1440 (higher)

**Pass Criteria:**
- [ ] UIs are centered at all resolutions
- [ ] All content is visible (no cutoff)
- [ ] Text is readable at all resolutions
- [ ] Frames stay within screen bounds when moved

### Test 7.2: UI Scale Compatibility
**Expected:** UIs work at different UI scales

**Test at different UI scales:**
- 1.0 (default)
- 0.8 (smaller)
- 1.2 (larger)

**Pass Criteria:**
- [ ] UIs scale appropriately
- [ ] All content remains visible
- [ ] No text overlap or cutoff
- [ ] Buttons remain clickable

### Test 7.3: Rapid Open/Close
**Expected:** No errors or glitches with rapid toggling

**Test Sequence:**
1. Rapidly type `/avanity` 5 times
2. Rapidly type `/avanity scanner` 5 times
3. Rapidly alternate between Settings and Scanner
4. Check for Lua errors

**Pass Criteria:**
- [ ] No Lua errors
- [ ] UIs respond correctly each time
- [ ] No orphaned frames or duplicates
- [ ] No performance degradation

### Test 7.4: /reload While UI Open
**Expected:** UIs close gracefully on reload

**Test Sequence:**
1. Open Settings UI
2. Type `/reload`
3. After reload, verify no orphaned frames
4. Open Scanner UI
5. Type `/reload`
6. After reload, verify no orphaned frames

**Pass Criteria:**
- [ ] No Lua errors on reload
- [ ] No orphaned frames after reload
- [ ] UIs can be opened normally after reload
- [ ] Settings persist correctly

---

## Test Suite 8: Integration with Core Addon Features

### Test 8.1: Tooltip Integration Still Works
**Expected:** UI changes don't break core tooltip functionality

**Test Sequence:**
1. Enable addon via Settings UI
2. Mouse over a creature that drops vanity items
3. Verify tooltip shows vanity item information
4. Disable addon via Settings UI
5. Mouse over same creature
6. Verify tooltip doesn't show vanity items

**Pass Criteria:**
- [ ] Tooltips work with addon enabled
- [ ] Tooltips respect enabled/disabled state
- [ ] Color coding works if enabled
- [ ] Learned status shows if enabled

### Test 8.2: Debug Mode Functionality
**Expected:** Debug mode works from new Scanner UI location

**Test Sequence:**
1. Enable Debug Mode via Scanner UI checkbox
2. Trigger some addon activity (mouse over creatures)
3. Check chat for debug messages
4. Disable Debug Mode via `/avanity debug`
5. Trigger addon activity
6. Verify no debug messages

**Pass Criteria:**
- [ ] Debug messages appear when enabled
- [ ] Debug messages stop when disabled
- [ ] Works from checkbox and slash command
- [ ] No errors in debug output

---

## Test Suite 9: Performance and Stability

### Test 9.1: Memory Usage
**Expected:** UI additions don't significantly increase memory usage

**Test Sequence:**
1. Note addon memory before opening UIs (`/run print(GetAddOnMemoryUsage("AscensionVanity"))`)
2. Open Settings UI
3. Note memory increase
4. Close Settings, open Scanner
5. Note memory increase
6. Close all, check for memory leaks

**Pass Criteria:**
- [ ] Memory increase is reasonable (<500 KB for UIs)
- [ ] Memory doesn't continuously grow with open/close cycles
- [ ] No significant memory leaks detected

### Test 9.2: No Lua Errors
**Expected:** Zero Lua errors during all operations

**Pass Criteria:**
- [ ] No errors on addon load
- [ ] No errors opening Settings UI
- [ ] No errors opening Scanner UI
- [ ] No errors clicking any buttons
- [ ] No errors with slash commands
- [ ] No errors on /reload

---

## Regression Testing

### Must Still Work:
- [ ] Database loads correctly (VanityDB)
- [ ] Tooltips show vanity item drops
- [ ] Color coding works (green/yellow)
- [ ] Learned status detection works
- [ ] All slash commands function
- [ ] Scanner can perform API scans
- [ ] Data export to dump file works

---

## Sign-Off

### Test Summary
- **Total Tests:** _____
- **Passed:** _____
- **Failed:** _____
- **Blocked:** _____

### Critical Issues Found
1. _____________________________________________
2. _____________________________________________
3. _____________________________________________

### Non-Critical Issues Found
1. _____________________________________________
2. _____________________________________________
3. _____________________________________________

### Overall Assessment
☐ **PASS** - Ready for merge to main  
☐ **PASS WITH ISSUES** - Minor issues, acceptable for merge  
☐ **FAIL** - Critical issues, requires fixes before merge

### Tester Sign-Off
**Name:** _____________  
**Date:** _____________  
**Signature:** _____________

---

## Notes for Testers

### How to Test Efficiently
1. Start with fresh `/reload` before each major test suite
2. Use `/console scriptErrors 1` to ensure Lua errors are visible
3. Keep a separate text file for notes during testing
4. Screenshot any visual glitches or unexpected behavior
5. Test in both windowed and fullscreen modes

### Common Issues to Watch For
- Text overlap or clipping
- Lua errors (watch chat)
- Memory leaks (repeated open/close cycles)
- Checkbox states not syncing
- UIs not closing when they should
- Frame rendering issues (z-fighting)
- Performance degradation

### Reporting Issues
For each issue found, document:
- **Test Suite & Number:** (e.g., "Test Suite 4.2")
- **Expected Behavior:** What should happen
- **Actual Behavior:** What actually happened
- **Steps to Reproduce:** Exact steps taken
- **Screenshot/Video:** If applicable
- **Lua Error:** Full error text if any
