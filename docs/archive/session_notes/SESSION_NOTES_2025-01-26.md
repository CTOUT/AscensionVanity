# Session Notes - January 26, 2025

## API Discovery & Performance Analysis

### Key Discoveries

1. **`C_VanityCollection.GetAllItems()`**
   - Returns ALL vanity items in the game (not just owned items)
   - Contains ~9000+ items total
   - Each item includes `creaturePreview` field with NPC source ID

2. **`C_VanityCollection.GetItem(itemID)`**
   - Direct O(1) lookup by item ID
   - Returns full item data including `creaturePreview`
   - Excellent for validation and forward lookups (item→creature)

3. **`C_VanityCollection.GetNum()`**
   - Returns `nil` (not implemented or not accessible)

### Performance Analysis Conclusion

**Static Database Approach (Current) vs API-Based Approach:**

| Aspect | Static DB (Current) | API on-demand |
|--------|---------------------|---------------|
| File Size | 50KB (negligible) | 0KB |
| Lookup Speed | O(1) - instant | O(n) - must scan 9000+ items |
| Memory Impact | One-time load | Repeated allocations + GC pressure |
| CPU Usage | Negligible | High (scan on every tooltip) |
| Reliability | Independent of API | Dependent on API availability |

**Verdict:** Static database remains the optimal architecture.

### Why Static Database Wins

1. **No Reverse Lookup API** - Need creature→items mapping, but API only provides item→creature
2. **Tooltip Performance** - Users hover over NPCs constantly; can't afford O(n) scans
3. **GC Pressure** - Repeated GetAllItems() calls create 9000+ temp objects
4. **Combat Responsiveness** - Static DB has zero runtime cost

### Potential Future Uses for API

The API could be valuable for:
- **Database Validation Tool** - Verify our static DB against live API data
- **Auto-Update System** - Detect when new vanity items are added
- **Item Info Enrichment** - Get additional metadata beyond creature source

### Commands Added

- `/av api` - Enhanced with GetNum() and GetItem() testing
- Shows detailed API function signatures and test results
- Validates known item IDs against API

## Next Steps (For Tomorrow)

1. Consider adding database validation command using GetItem()
2. Explore potential for auto-update detection
3. Test tooltip performance in high-NPC-density areas
4. Consider adding more diagnostic commands

## Files Modified

- `AscensionVanity/Core.lua` - Added comprehensive API exploration tools

## Commits

- `e507ed2` - feat: Improve dumpitem command with deep recursive search
- `6c76ce6` - feat: Add comprehensive API exploration tools
