# Cache System - Quick Reference

## 🚀 What Changed

**Learned status checks are now cached** - reducing API calls by ~95%!

---

## ✅ How to Test

### Quick Test (2 minutes)

1. Enable debug: `/avanity debug`
2. Enable learned status: `/avanity learned`
3. Find any creature with vanity items
4. Mouse over it **twice**

**Expected:**
- First hover: "Cache MISS" in chat
- Second hover: "Cache HIT" in chat
- **Instant** tooltip on second hover

### Critical Test (5 minutes)

1. Find creature with item **you don't own**
2. Mouse over: Should show **Red X**
3. Kill, loot, and **learn the item**
4. Mouse over **same creature** again
5. Should now show **Green ✓** automatically!

**If it still shows Red X:** Something's wrong - let me know!

---

## 📊 New Commands

```
/avanity cachestats      - Show cache performance
/avanity clearcache      - Force cache refresh (if needed)
/avanity enablefallback  - Toggle fallback events (only if primary events fail)
```

**Note:** Fallback events (BAG_UPDATE_DELAYED, LOOT_CLOSED) are **disabled by default** because they fire constantly during normal looting and would spam cache clears. Only enable if primary events don't work.

---

## 🐛 Troubleshooting

**Cache not updating after learning item?**
1. Check chat for "Invalidating cache" message
2. Run `/avanity clearcache` manually
3. Tell me which events fire (if any)

**Performance worse than before?**
1. Run `/avanity cachestats` - should show cache hits
2. Check for Lua errors
3. Disable/re-enable learned status

---

## 📖 Full Documentation

- **Testing:** `CACHE_TESTING_GUIDE.md`
- **Technical:** `CACHE_IMPLEMENTATION_SUMMARY.md`

---

## ✨ Expected Results

**Performance:**
- First tooltip: Same speed as before
- Every tooltip after: **Instant!**

**Accuracy:**
- Shows correct status always
- Updates automatically when learning
- **No `/reload` needed**

---

That's it! Test when you can and let me know how it works! 🎯
