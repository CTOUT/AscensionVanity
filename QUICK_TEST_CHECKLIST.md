# Quick Test Checklist - AscensionVanity UI Changes

**Use this for rapid pre-push validation. Full test plan: UI_TEST_PLAN.md**

## Critical Path Tests (5 minutes)

### 1. Load Test
```
1. /reload
2. Check for Lua errors
3. Type /avanity help (verify commands work)
```
**Pass:** ☐ No errors, help displayed

### 2. Settings UI
```
1. /avanity
2. Toggle each checkbox
3. Click "Open API Scanner"
```
**Pass:** ☐ Settings opens, checkboxes work, Scanner opens (Settings closes)

### 3. Scanner UI
```
1. /avanity scanner
2. Toggle Debug Mode
3. Click "Open Settings"
```
**Pass:** ☐ Scanner opens, debug checkbox works, Settings opens (Scanner closes)

### 4. Interface Options
```
1. ESC → Interface → AddOns
2. Click "AscensionVanity"
3. Click "Open Settings"
4. Return to Interface Options
5. Click "Open API Scanner"
```
**Pass:** ☐ Addon visible in list, launcher works, mutual exclusion works

### 5. Slash Command Sync
```
With Scanner UI open:
1. /avanity debug
2. Verify checkbox toggles immediately

With Settings UI open:
3. /avanity toggle
4. Verify checkbox toggles immediately
```
**Pass:** ☐ Both checkboxes update in real-time

### 6. Mutual Exclusion Matrix
```
Test each combination:
- Settings open → /avanity scanner → Scanner opens, Settings closes
- Scanner open → /avanity → Settings opens, Scanner closes
- Both closed → Either command → Only one opens
```
**Pass:** ☐ Never see both UIs simultaneously

### 7. Visual Checks
```
1. Open Settings UI - verify no text overlap, all content visible
2. Open Scanner UI - verify slash commands section not cut off
3. Drag both UIs around screen - verify they stay within bounds
```
**Pass:** ☐ Clean layout, no clipping, draggable

### 8. Settings Persistence
```
1. Change all settings
2. /reload
3. Open Settings UI
4. Verify states match
```
**Pass:** ☐ Settings persisted correctly

## Smoke Tests (1 minute)

### Quick Validation Scripts
```lua
-- Test 1: Core loaded
/script if AscensionVanityDB then print("✓ DB loaded") end

-- Test 2: Functions exist  
/script if AscensionVanity_ShowSettings and AscensionVanity_ShowScanner then print("✓ Functions loaded") end

-- Test 3: UI frames exist
/script if AscensionVanitySettingsPanel and AscensionVanityScannerFrame then print("✓ UIs loaded") end

-- Test 4: Sync functions exist
/script if AscensionVanity_SyncDebugCheckbox and AscensionVanity_SyncSettingsUI then print("✓ Sync functions loaded") end
```

## Pre-Push Checklist

- [ ] All Critical Path Tests pass
- [ ] All Smoke Tests pass
- [ ] No Lua errors during testing
- [ ] Tested at native resolution
- [ ] Tested with /reload
- [ ] Settings persist correctly
- [ ] No visual glitches
- [ ] Memory usage acceptable (check with `/run print(GetAddOnMemoryUsage("AscensionVanity"))`)

## If Any Test Fails

1. **Note the specific test that failed**
2. **Document what went wrong**
3. **Fix the issue**
4. **Re-run all tests**
5. **Do not push until all pass**

## Sign-Off

**Tester:** _____________  
**Date:** _____________  
**Result:** ☐ PASS  ☐ FAIL  

**Notes:**
_______________________________
_______________________________
_______________________________
