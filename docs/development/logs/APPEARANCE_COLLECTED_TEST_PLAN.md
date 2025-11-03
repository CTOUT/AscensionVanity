# APPEARANCE_COLLECTED Event Testing Plan

**Date:** October 30, 2025  
**Status:** Ready for In-Game Testing  
**Goal:** Validate APPEARANCE_COLLECTED event triggers cache invalidation

---

## 🎯 Test Objective

Verify that learning a vanity item triggers:
1. `APPEARANCE_COLLECTED` event fires
2. Cache invalidates immediately
3. Next tooltip shows updated "✓ Learned" status
4. Event spy logs the event (if enabled)

---

## 📋 Test Steps

### **Pre-Test Setup**

1. **Deploy Updated Addon** ✅
   ```
   Already completed - addon deployed to <WoW-Install-Path>\Interface\AddOns\AscensionVanity
   ```

2. **Launch Game**
   - Start World of Warcraft
   - Log in to character

3. **Reload UI**
   ```
   /reload
   ```

4. **Verify Addon Loaded**
   ```
   Expected output: "AscensionVanity v2.0.0 loaded!"
   ```

### **Test 1: Cache Invalidation on Learning**

1. **Enable Debug Mode**
   ```
   /avanity debug
   ```

2. **Enable Event Spy** (Optional)
   ```
   /avanity eventspy
   ```

3. **Find Unlearned Vanity Item**
   - Check your inventory or buy one from vendor
   - Example: Any combat pet you don't have yet

4. **Mouse Over Creature That Drops It** (Before Learning)
   ```
   Expected: "○ Not learned" status in yellow
   ```

5. **Learn the Vanity Item**
   - Right-click the item
   - Use it to add to collection

6. **Watch Chat for Event**
   ```
   Expected output (if event spy enabled):
   "[Event Spy] APPEARANCE_COLLECTED - Learned item(s): <itemID>"
   ```

7. **Watch Chat for Cache Invalidation**
   ```
   Expected output (if debug enabled):
   "Event: APPEARANCE_COLLECTED - Item(s) learned: <itemID> - Invalidating cache"
   "ClearLearnedStatusCache: Cache cleared (X items removed)"
   ```

8. **Mouse Over Same Creature Again** (After Learning)
   ```
   Expected: "✓ Learned" status in green
   Timing: Should update IMMEDIATELY (within 1 second)
   ```

### **Test 2: Multiple Items at Once**

Some scenarios might learn multiple items:

1. **Learn Multiple Vanity Items**
   - If you have several unlearned items
   - Use them all quickly

2. **Verify Event Args**
   ```
   Expected event format: APPEARANCE_COLLECTED itemId1,itemId2,...
   ```

3. **Check Cache Cleared Once**
   ```
   Should see single cache clear, not multiple
   ```

### **Test 3: TTL Backup Still Works**

Test that TTL-based expiration works as backup:

1. **Disable Event Spy** (to hide event)
   ```
   /avanity eventspy
   ```

2. **Clear Cache Manually**
   ```
   /avanity clearcache
   ```

3. **Mouse Over Creature** (to populate cache)

4. **Wait 2+ Minutes** (cache TTL)

5. **Mouse Over Same Creature**
   ```
   Expected: Cache expired, re-queries API
   Expected output: "IsItemLearnedCached: Cache expired..."
   ```

### **Test 4: Fallback Events Disabled by Default**

Verify BAG_UPDATE fallback is off unless explicitly enabled:

1. **Pick Up Items from Bags**
   - Move items around
   - Loot random items

2. **Check Cache NOT Cleared**
   ```
   Should NOT see cache clears on every inventory change
   ```

3. **Enable Fallback** (optional test)
   ```
   /avanity enablefallback
   ```

4. **Pick Up Items Again**
   ```
   NOW should see cache clears (with debouncing)
   ```

---

## ✅ Expected Results

### **Successful Test Indicators**

✅ **Event Fires:**
```
[Event Spy] APPEARANCE_COLLECTED - Learned item(s): 80171
```

✅ **Cache Clears:**
```
[Debug] Event: APPEARANCE_COLLECTED - Item(s) learned: 80171 - Invalidating cache
[Debug] ClearLearnedStatusCache: Cache cleared (5 items removed)
```

✅ **Status Updates Instantly:**
```
Before learning: "○ Not learned" (yellow)
After learning:  "✓ Learned" (green)
Delay: <1 second
```

✅ **TTL Backup Works:**
```
After 2 minutes: Cache expires automatically
Next tooltip: Re-queries API, updates from fresh data
```

### **Failure Indicators**

❌ **Event Doesn't Fire:**
```
No event spy message when learning item
Cache doesn't clear automatically
Status stays "Not learned" after learning
```

**If This Happens:**
- Verify event name is spelled correctly in code
- Check Event Trace tool shows APPEARANCE_COLLECTED
- Confirm item is actually a vanity item (not regular item)

❌ **Cache Doesn't Clear:**
```
Event fires but cache stays populated
Status doesn't update even after event
```

**If This Happens:**
- Check event handler is calling ClearLearnedStatusCache()
- Verify cache clear function is working
- Test manual `/avanity clearcache` command

❌ **Wrong Event Args:**
```
Event fires but arg1 is nil or wrong format
Can't parse item IDs from event
```

**If This Happens:**
- Log actual arg1 value in debug output
- Adjust parsing logic if needed
- May need to handle different arg formats

---

## 🐛 Troubleshooting

### **Problem: Event Spy Shows Nothing**

**Check:**
1. Event spy actually enabled? (`/avanity eventspy` twice to toggle)
2. Debug mode on? (`/avanity debug`)
3. Addon actually loaded? (`/avanity` to open settings)

### **Problem: Cache Doesn't Clear**

**Check:**
1. Look for error messages in chat
2. Check Lua errors with `/luaerror on`
3. Verify ClearLearnedStatusCache() function exists
4. Test manual clear: `/avanity clearcache`

### **Problem: Status Doesn't Update**

**Check:**
1. Did cache actually clear? (check debug output)
2. Is API returning correct status? (test with `/avanity apitest`)
3. Mouse over different creature to eliminate tooltip caching

### **Problem: Event Fires Too Often**

**Check:**
1. Fallback events enabled? (disable with `/avanity disablefallback`)
2. Debouncing working? (should see delays between cache clears)
3. Event firing on non-vanity items?

---

## 📊 Success Criteria

**Test Passes If:**
- ✅ APPEARANCE_COLLECTED event fires when learning vanity items
- ✅ Cache clears immediately upon event
- ✅ Tooltip status updates to "✓ Learned" within 1 second
- ✅ Event spy logs event with correct item ID(s)
- ✅ No false positives (event only fires for vanity items)
- ✅ TTL backup still works as safety net

**Test Fails If:**
- ❌ Event doesn't fire when learning items
- ❌ Cache doesn't clear on event
- ❌ Status stays "Not learned" after learning
- ❌ Event fires for non-vanity items
- ❌ Causes errors or crashes

---

## 📝 Test Report Template

After testing, document results:

```markdown
## APPEARANCE_COLLECTED Event Test Results

**Date:** [Date]
**Tester:** [Your Name]
**Game Version:** Ascension [Version]

### Test 1: Cache Invalidation
- [ ] Event fired: YES / NO
- [ ] Cache cleared: YES / NO  
- [ ] Status updated: YES / NO
- [ ] Timing: [X] seconds
- **Result:** PASS / FAIL

### Test 2: Multiple Items
- [ ] Event args format: [format]
- [ ] Single cache clear: YES / NO
- **Result:** PASS / FAIL

### Test 3: TTL Backup
- [ ] Cache expired after 2 min: YES / NO
- [ ] Re-queried API: YES / NO
- **Result:** PASS / FAIL

### Test 4: Fallback Disabled
- [ ] No spam from inventory: YES / NO
- [ ] Fallback toggle works: YES / NO
- **Result:** PASS / FAIL

### Overall Result: PASS / FAIL

**Notes:**
[Any additional observations, issues, or recommendations]
```

---

## 🚀 After Testing

### **If All Tests Pass:**
1. Mark EVENT_VALIDATION_TEST.md as ✅ CONFIRMED
2. Update README with instant cache refresh info
3. Remove "manual refresh required" warnings
4. Celebrate! 🎉

### **If Tests Fail:**
1. Document exact failure mode
2. Gather debug logs
3. Test with different items/scenarios
4. Adjust code based on findings
5. Repeat testing

---

**Status:** Ready for In-Game Testing  
**Next Step:** Launch game, run tests, report results!
