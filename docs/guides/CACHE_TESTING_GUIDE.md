# Cache Testing Guide - Learned Status Optimization

**Version:** 2.1-beta  
**Feature:** Smart caching for learned status checks  
**Goal:** Verify cache invalidation works correctly when learning new items

---

## Overview

The learned status cache reduces API calls by ~90% by caching `C_VanityCollection.IsCollectionItemOwned()` results. The critical test is ensuring the cache refreshes immediately when you learn a new item.

---

## Test Scenario 1: Cache Performance (Baseline)

**Objective:** Verify cache is working and reducing API calls

### Steps:
1. Enable debug mode: `/avanity debug`
2. Enable learned status: `/avanity learned`
3. Find a creature that drops vanity items (e.g., Savannah Prowler in Barrens)
4. Mouse over the creature **once** - observe chat for debug messages
5. Mouse over the **same creature again** - observe chat

### Expected Results:
- **First hover:** Debug shows "Cache MISS for item XXXXX - querying API"
- **Second hover:** Debug shows "Cache HIT for item XXXXX (age: X.X sec)"
- **Performance:** Second hover should be instant (no API delay)

### Pass Criteria:
- ✅ Cache MISS on first hover
- ✅ Cache HIT on subsequent hovers
- ✅ No repeated API calls for same item

---

## Test Scenario 2: Cache Invalidation on Item Learn (CRITICAL)

**Objective:** Verify cache clears when you learn a new vanity item

### Setup:
1. Find a creature that drops a vanity item **you don't own**
2. Ensure learned status display is enabled: `/avanity learned`
3. Enable debug mode: `/avanity debug`

### Steps:
1. **Before Learning:**
   - Mouse over creature
   - Verify tooltip shows **Red X** (not learned)
   - Note debug: "Cache MISS" → "Item XXXXX owned status: false"

2. **Learn the Item:**
   - Kill creature and loot the vanity item
   - **Right-click to learn it** (Ascension: "Use" the item)
   - Watch chat for cache invalidation message

3. **After Learning:**
   - Mouse over **the same creature** again
   - Verify tooltip shows **Green ✓** (learned)
   - Note debug: "Cache MISS" (cache was cleared) → "Item XXXXX owned status: true"

### Expected Results:
- **After learning:** Debug shows "Event: COLLECTION_CHANGED - Invalidating learned status cache"
- **Next hover:** Cache rebuilds with new "true" status
- **Tooltip:** Red X → Green ✓ (status correctly updated)

### Pass Criteria:
- ✅ Tooltip shows correct status BEFORE learning (Red X)
- ✅ Cache invalidation message appears when item is learned
- ✅ Tooltip shows correct status AFTER learning (Green ✓)
- ✅ No manual `/reload` or cache clear needed

### Failure Indicators:
- ❌ Tooltip still shows Red X after learning (cache not cleared)
- ❌ No "Invalidating cache" message in chat
- ❌ Need to `/reload` to see updated status

---

## Test Scenario 3: Multiple Events Fallback

**Objective:** Verify fallback events work if primary event doesn't fire

### Steps:
1. Enable debug: `/avanity debug`
2. Learn a vanity item
3. Watch for debug messages showing which event triggered cache clear

### Expected Events (in order of priority):
1. `COLLECTION_CHANGED` (Ascension custom - best)
2. `NEW_TOY_ADDED` (Standard WoW)
3. `TRANSMOG_COLLECTION_UPDATED` (Standard WoW)
4. `BAG_UPDATE_DELAYED` (Fallback)
5. `LOOT_CLOSED` (Fallback)

### Pass Criteria:
- ✅ At least ONE event fires when item is learned
- ✅ Cache is cleared (any event is acceptable)

---

## Test Scenario 4: Cache Statistics

**Objective:** Verify cache stats command works

### Steps:
1. Enable learned status: `/avanity learned`
2. Mouse over several creatures with vanity items
3. Run: `/avanity cachestats`

### Expected Output:
```
AscensionVanity: Learned Status Cache Statistics
  Cache version: 1
  Cached items: 15
  Oldest entry: 45.3 seconds ago
  Newest entry: 2.1 seconds ago
  Cache TTL: 300 seconds

Performance: Cache reduces API calls by ~90%
Auto-refresh: Cache clears when you learn new items
```

### Pass Criteria:
- ✅ Shows number of cached items
- ✅ Shows cache age information
- ✅ No errors

---

## Test Scenario 5: Manual Cache Clear

**Objective:** Verify manual cache clear command

### Steps:
1. Enable debug: `/avanity debug`
2. Mouse over creatures to populate cache
3. Run: `/avanity cachestats` - note cache size
4. Run: `/avanity clearcache`
5. Run: `/avanity cachestats` - verify cache is empty
6. Mouse over creature again - should be Cache MISS

### Pass Criteria:
- ✅ Cache size drops to 0 after clear
- ✅ Next tooltip hover is Cache MISS
- ✅ Cache rebuilds correctly

---

## Test Scenario 6: Cache TTL Expiry

**Objective:** Verify cache expires after 5 minutes (optional test)

### Steps:
1. Enable learned status and debug
2. Mouse over a creature (cache populated)
3. **Wait 6 minutes** (cache TTL = 300 seconds)
4. Mouse over same creature again

### Expected Results:
- Debug shows "Cache EXPIRED for item XXXXX (age: XXX.X sec)"
- API is re-queried
- Cache is refreshed

### Pass Criteria:
- ✅ Cache expires after TTL
- ✅ API is re-queried automatically

---

## Debugging Commands

If tests fail, use these commands to investigate:

```lua
/avanity debug              -- Enable debug logging
/avanity cachestats         -- Show cache statistics
/avanity clearcache         -- Force cache clear
/avanity learned            -- Toggle learned status display

-- Advanced debugging
/dump C_VanityCollection    -- Check if API exists
/avanity api                -- Scan for Ascension APIs
```

---

## Common Issues & Solutions

### Issue 1: Cache not clearing when item learned
**Symptoms:** Tooltip shows Red X after learning item  
**Diagnosis:** No cache invalidation event fired  
**Solution:** 
1. Check if any event fires with `/avanity debug`
2. If no event: Use `/avanity clearcache` as workaround
3. Report which events DO fire for investigation

### Issue 2: No cache hits
**Symptoms:** Every hover shows "Cache MISS"  
**Diagnosis:** Cache not persisting between hovers  
**Solution:**
1. Verify learned status is enabled: `/avanity learned`
2. Check for Lua errors (may be clearing cache on error)
3. Run `/avanity cachestats` to verify cache population

### Issue 3: False cache entries
**Symptoms:** Tooltip shows wrong learned status  
**Diagnosis:** Cache out of sync with API  
**Solution:**
1. Clear cache: `/avanity clearcache`
2. Verify status updates correctly
3. Check which events are registered

---

## Success Criteria Summary

**Must Pass:**
- ✅ Cache reduces API calls (Test 1)
- ✅ Cache clears when item learned (Test 2) - **CRITICAL**
- ✅ Correct status displayed after learning (Test 2)
- ✅ At least one invalidation event fires (Test 3)

**Nice to Have:**
- ✅ Cache stats command works (Test 4)
- ✅ Manual clear command works (Test 5)
- ✅ TTL expiry works (Test 6)

---

## Performance Metrics

**Expected Performance Gains:**

| Scenario | Without Cache | With Cache | Improvement |
|----------|--------------|------------|-------------|
| First hover | 2-3 API calls | 2-3 API calls | 0% (cache miss) |
| Subsequent hovers | 2-3 API calls | 0 API calls | **100%** |
| 100 creature hovers | 200-300 API calls | 2-6 API calls | **95-97%** |

**Expected Behavior:**
- Cache hit rate: **90-95%** after initial population
- Cache invalidation latency: **<1 second** after learning item
- Memory footprint: **Negligible** (~100 bytes per cached item)

---

## Reporting Results

When reporting test results, include:

1. **Which events fired** when learning items (from debug log)
2. **Cache hit/miss ratio** (from debug log)
3. **Any failures** in Test 2 (critical cache invalidation)
4. **Debug logs** for failed scenarios

**Format:**
```
Test 2 Results:
- Event fired: COLLECTION_CHANGED ✅
- Cache cleared: Yes ✅
- Tooltip updated: Yes ✅
- Status: PASS ✅
```

---

## Next Steps

After successful testing:
1. Disable debug mode: `/avanity debug`
2. Continue normal gameplay
3. Cache will work silently in background
4. Use `/avanity cachestats` anytime to verify performance

**Enjoy your 90% performance boost!** 🚀
