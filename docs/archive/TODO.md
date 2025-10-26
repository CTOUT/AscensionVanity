# AscensionVanity - TODO & Next Steps

## Critical Next Steps

### 1. Complete Database Extraction (HIGH PRIORITY)
**Status**: 🔴 INCOMPLETE - Only ~50 of 2471 items extracted

**Task**: Extract all vanity items from Project Ascension database
- **Source**: https://db.ascension.gg/?items=101
- **Total Items**: 2471
- **Current Progress**: ~50 items (2%)

**Approaches**:
1. **Manual Pagination**: 
   - Database shows 1000 items max per page
   - Navigate through pages: "Next ›", "Last »"
   - Copy item data from each page
   - Parse and format into Lua table structure

2. **Web Scraping** (Recommended):
   - Use PowerShell or Python to fetch all pages
   - Parse HTML tables to extract:
     - Item names ("Summoner's Stone: [Name]")
     - Creature types
     - Drop source (specific creature or "Drop")
     - Item IDs if available
   - Generate VanityData.lua automatically

3. **Database Export** (If Available):
   - Check if Ascension provides data export
   - Convert to Lua table format

**Data Format Needed**:
```lua
["Creature Name"] = {
    itemID = 12345,  -- Extract from database
    itemName = "Summoner's Stone: Creature Name",
    type = "Creature Type"
}
```

**Example PowerShell Scraper Structure**:
```powershell
# Fetch page data
$baseUrl = "https://db.ascension.gg/?items=101"
$page = 1
$allItems = @()

while ($page -le 50) {  # Adjust based on total pages
    $url = "$baseUrl&page=$page"
    $html = Invoke-WebRequest -Uri $url
    # Parse HTML and extract item data
    $page++
}

# Convert to Lua format
```

---

### 2. Implement Learned Status Detection (HIGH PRIORITY)
**Status**: 🟡 PLACEHOLDER - Function exists but returns `nil`

**Task**: Identify and implement Project Ascension's API for checking learned vanity items

**Current Code** (Core.lua line ~25):
```lua
local function IsVanityItemLearned(itemID, itemName)
    -- TODO: Replace with actual Ascension API call
    return nil -- Unknown status
end
```

**Research Needed**:
1. **Ascension API Documentation**:
   - Check Project Ascension addon development docs
   - Look for collection/companion APIs
   - Search for pet whistle/vanity item APIs

2. **Existing Addons**:
   - Examine other Ascension addons
   - Check if they track collections
   - Reverse engineer their methods

3. **Possible API Patterns**:
   ```lua
   -- Standard WoW pattern (may not work on Ascension):
   C_PetJournal.GetNumCollectedInfo(itemID)
   
   -- Possible Ascension patterns:
   AscensionAPI.HasLearnedVanityItem(itemID)
   IsSpellKnown(spellID)  -- If vanity items are spells
   
   -- Custom tracking:
   -- Check player's inventory/bank
   -- Scan combat log for learn events
   -- Track in saved variables
   ```

4. **Testing Methods**:
   - Learn a vanity item in-game
   - Use `/dump` commands to inspect player data
   - Check for collection-related variables
   - Monitor events: `COMPANION_LEARNED`, `SPELL_LEARNED`, etc.

**Implementation Steps**:
1. Identify correct API call
2. Update `IsVanityItemLearned()` function
3. Test with known learned/unlearned items
4. Handle edge cases (item not in game, etc.)

---

### 3. Populate Item IDs (MEDIUM PRIORITY)
**Status**: 🟡 INCOMPLETE - All `itemID = nil` currently

**Task**: Extract actual item IDs from database for each vanity item

**Why Needed**:
- Required for `IsVanityItemLearned()` API calls
- Enables item links in tooltips
- Allows for more precise tracking

**How to Extract**:
- Item IDs should be in the database URL structure
- Example: `https://db.ascension.gg/?item=12345`
- Parse from database pages during data extraction
- Add to VanityData.lua entries

---

### 4. Add NPC ID Mapping (OPTIONAL ENHANCEMENT)
**Status**: 🔵 OPTIONAL - Current name-based matching works

**Benefits**:
- More accurate creature identification
- Handles creatures with same names
- Faster lookups (numeric comparison)

**Implementation**:
```lua
AV_VanityItemsByNPCID = {
    [12345] = {  -- NPC ID
        itemID = 67890,
        itemName = "Summoner's Stone: Creature",
        type = "Terrorfiend"
    }
}

-- Get NPC ID in tooltip hook:
local guid = UnitGUID(unit)
local npcID = tonumber(guid:match("Creature%-.-%-.-%-.-%-.-%-(.-)%-"))
```

---

### 5. Testing & Validation (CRITICAL BEFORE RELEASE)
**Status**: 🔴 NOT STARTED - Needs in-game testing

**Test Checklist**:
- [ ] Addon loads without errors
- [ ] Tooltips display for known creatures
- [ ] Multiple vanity items show correctly
- [ ] Slash commands work (`/av`, `/av toggle`, etc.)
- [ ] Settings persist after `/reload`
- [ ] No conflicts with other addons
- [ ] Performance impact is minimal
- [ ] Works for all creature types
- [ ] Color coding displays correctly
- [ ] Learned status detection works (when implemented)

**Testing Locations** (Find creatures with vanity items):
- Outland zones (many demon types)
- Shadowmoon Valley (Terrorfiends, Pit Lords)
- Blade's Edge Mountains (Gan'arg, Mo'arg)
- Check database for specific creature locations

---

### 6. Performance Optimization (LOW PRIORITY)
**Status**: ⚪ NOT STARTED - Optimize if needed

**Potential Improvements**:
1. **Caching**:
   ```lua
   local creatureCache = {}
   -- Cache lookup results to avoid repeated searches
   ```

2. **Lazy Loading**:
   - Load database on first tooltip display
   - Split data into multiple files if very large

3. **Efficient Lookups**:
   - Use hash tables instead of linear searches
   - Index by NPC ID for O(1) lookups

---

## Quick Commands for Development

### Reload Addon After Changes
```lua
/reload
```

### Test Creature Lookup
```lua
/run AV_Debug("Zarcsin", "Terrorfiend")
```

### Check for Errors
```lua
/console scriptErrors 1
```

### Dump Current Settings
```lua
/dump AscensionVanityDB
```

### Test Tooltip Hook
```lua
-- Mouse over a creature and check tooltip
-- Should see "Vanity Items:" section if creature is in database
```

---

## Data Extraction Tools

### PowerShell Web Scraper Template
```powershell
# Fetch and parse Ascension database
$baseUrl = "https://db.ascension.gg/?items=101"

# Create output file
$output = "VanityDB.lua"
"-- Auto-generated vanity item database" | Out-File $output

# Fetch data and parse
# (Add actual HTML parsing logic here)
```

### Manual Extraction Format
When manually copying from database, use this format:
```
Item Name: Summoner's Stone: [Name]
Creature Type: [Type]
Drop Source: [Specific creature or "Drop"]
```

Convert to:
```lua
["[Name]"] = {
    itemID = nil,
    itemName = "Summoner's Stone: [Name]",
    type = "[Type]"
}
```

---

## Known Issues & Limitations

### Current Limitations
1. **Incomplete Database**: Only ~2% of items included
2. **No Learned Status**: Cannot detect if player owns item
3. **No Item IDs**: All itemID fields are `nil`
4. **Name-Based Matching Only**: Could have false positives with same-named NPCs
5. **No Item Links**: Cannot click items in tooltip

### Future Enhancements
- Clickable item links in tooltips
- Filter options (show only unlearned, by type, etc.)
- Import/export settings
- Multi-language support
- Integration with other collection addons
- Statistics (X/2471 collected)
- Progress tracking UI

---

## Resources

### Documentation
- WoW API: https://wowpedia.fandom.com/wiki/World_of_Warcraft_API
- Ascension Database: https://db.ascension.gg/?items=101
- Lua Reference: https://www.lua.org/manual/5.1/

### Community
- Project Ascension Forums: https://project-ascension.com/forum/
- Discord: (Add if available)

### Similar Addons (for reference)
- Rarity (retail WoW collection tracker)
- PetTracker (pet collection addon)
- AllTheThings (comprehensive collection addon)

---

## Success Metrics

### MVP Complete When:
- [ ] Full database of 2471 items extracted
- [ ] Addon loads without errors in-game
- [ ] Tooltips display correctly for all creature types
- [ ] At least basic functionality tested in-game

### Full Feature Complete When:
- [ ] Learned status detection working
- [ ] Item IDs populated
- [ ] All slash commands functional
- [ ] Comprehensive in-game testing completed
- [ ] Performance validated (no lag/stuttering)
- [ ] Documentation complete

---

**Last Updated**: 2025
**Version**: 1.0.0-dev
**Status**: Initial Implementation Complete, Database Extraction Needed
