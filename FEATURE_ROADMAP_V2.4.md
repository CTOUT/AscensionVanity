# AscensionVanity v2.4 Feature Roadmap

**Date:** November 10, 2025  
**Last Updated:** November 15, 2025  
**Current Version:** v2.3-dev (Active Development)  
**Next Version:** v2.4 (Planning)  
**Development Branch:** TBD  
**Status:** 📋 Planning Phase

---

## Overview

Version 2.4 focuses on **Database Optimization**, **UI Integration**, and **Enhanced Geographic Hierarchies** to reduce database size and expose pet family data in-game.

**Key Problems Solved:**  
1. **Dungeon Visibility**: Dungeons are both subzones (Ragefire is in Orgrimmar) AND zones (Ragefire has internal areas). Items disappear when you enter.
2. **Geographic Grouping**: No way to filter by continent (e.g., "Show all Eastern Kingdoms items")
3. **Multi-ID Creatures**: Same creature name with different IDs = incomplete drop rate tracking

**Design Philosophy:**
- Improve data model without breaking existing features
- Backwards compatible with v2.3 database
- Better support for complex geographic hierarchies
- Scalable for future expansions (Cataclysm, etc.)
- Foundation for regional collection tracking

---

## v2.4 Core Features

### 1. Database Optimization & Indexing 🗜️
**Priority:** ⭐⭐⭐⭐ Critical  
**Complexity:** High  
**Status:** 📋 Planned  
**Impact:** Reduces VanityDB.lua from 1,370 KB → ~800-900 KB (35-40% reduction)

**Problem:**  
Current database (1,370 KB) has massive duplication:
- Pet family data copied for every creature (2,089 copies of ~40 unique families)
- Zone names repeated thousands of times ("Orgrimmar", "Stormwind", etc.)
- Subzone names repeated hundreds of times
- Description patterns repeated with minor variations

**Current Size Breakdown (estimated):**
```
Pet Family Data:  ~400 KB (2,089 items × ~200 bytes each)
Zone Strings:     ~150 KB (repeated ~2,000+ times)
Subzone Strings:  ~100 KB (repeated ~1,000+ times)
Descriptions:     ~300 KB (many similar patterns)
Other Data:       ~420 KB (names, IDs, icons, etc.)
= Total: 1,370 KB
```

**Solution: Index-Based Referencing**

Create lookup tables and use indices instead of copying strings:

```lua
-- NEW: Indexed lookup tables
AV_PetFamilies = {
    [1] = {id=1, name="Wolf", type="Ferocity", icon="...", isExotic=false},
    [2] = {id=2, name="Cat", type="Ferocity", icon="...", isExotic=false},
    [3] = {id=3, name="Spider", type="Cunning", icon="...", isExotic=false},
    -- ... 155 total families
}

AV_Zones = {
    [1] = "Orgrimmar",
    [2] = "Stormwind City",
    [3] = "Ironforge",
    -- ... ~200 unique zones
}

AV_Subzones = {
    [1] = "Valley of Strength",
    [2] = "The Drag",
    [3] = "Ragefire Chasm",
    -- ... ~1,000 unique subzones
}

-- Items reference indices instead of duplicating strings
AV_VanityItems = {
    [79256] = {
        itemid = 79256,
        name = "Beastmaster's Whistle: Felhound",
        creatureId = 79010,
        zone = 1,           -- INDEX into AV_Zones ("Orgrimmar")
        subzone = 127,      -- INDEX into AV_Subzones ("Valley of Trials")
        petFamily = 8,      -- INDEX into AV_PetFamilies (Demon family)
        icon = 1
    }
}
```

**Size Savings:**
- **Pet Families**: 400 KB → ~15 KB (indexed table) + ~40 KB (references) = **~345 KB saved**
- **Zones**: 150 KB → ~5 KB (indexed table) + ~10 KB (references) = **~135 KB saved**
- **Subzones**: 100 KB → ~20 KB (indexed table) + ~10 KB (references) = **~70 KB saved**
- **Total Reduction**: ~550 KB savings = **40% smaller database**

**Implementation:**

1. **Update GenerateVanityDB_Master.ps1:**
   - Build unique family/zone/subzone lists
   - Create indexed lookup tables
   - Convert item fields to indices
   - Generate optimized VanityDB.lua

2. **Update VanityDB_Loader.lua:**
   - Add lookup functions: `AV_GetPetFamily(index)`, `AV_GetZone(index)`, `AV_GetSubzone(index)`
   - Update existing code to use indexed lookups
   - Backwards compatible fallback for old code

3. **Test Performance:**
   - Measure load time impact
   - Verify memory usage reduction
   - Ensure no lag when accessing indexed data

**Benefits:**
- ✅ 40% smaller addon download
- ✅ Faster addon load time
- ✅ Lower memory footprint in-game
- ✅ Foundation for future data expansion
- ✅ Easier to maintain (change family once, affects all items)

---

### 2. Pet Family UI Integration 🐾
**Priority:** ⭐⭐⭐⭐ Critical  
**Complexity:** Medium  
**Status:** 📋 Planned  
**Depends On:** Database Optimization (Feature #1)

**Problem:**  
Pet family data now exists in database but isn't displayed anywhere in-game. Players can't see:
- What family a pet belongs to (Wolf, Spider, Demon, etc.)
- What type the family is (Ferocity, Tenacity, Cunning, etc.)
- Whether a family is exotic (requires Beast Mastery spec)
- Family icon for visual identification

**Solution: Add Family Info to Multiple UIs**

**A) Tooltip Enhancement:**
```lua
-- Add after item name in tooltip
GameTooltip:AddLine("Family: Wolf (Ferocity)", 0.7, 0.7, 1.0)  -- Light blue
-- Or with icon:
GameTooltip:AddLine("|T" .. familyIcon .. ":16|t Wolf (Ferocity)", 0.7, 0.7, 1.0)
-- If exotic:
GameTooltip:AddLine("Requires: Beast Mastery", 1.0, 0.5, 0.0)  -- Orange warning
```

**B) Database Browser Enhancement:**
Add family column and filter:
```lua
-- Add column header
local familyHeader = browser:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
familyHeader:SetText("Family")

-- Add family filter dropdown
local familyFilter = CreateFrame("Frame", "AVDatabaseBrowserFamilyFilter", browser, "UIDropDownMenuTemplate")
-- Populate with: All Families, Ferocity, Tenacity, Cunning, Demon, Undead, Elemental, Dragonkin
```

**C) Collection Progress Frame Enhancement:**
Add family-based statistics:
```lua
-- Current: Shows progress by category (Beasts, Demons, etc.)
-- New: Show progress by FAMILY within category
-- Example:
--   Beasts (342/910)
--     ├─ Wolf: 23/45
--     ├─ Cat: 18/32
--     ├─ Spider: 15/28
--     └─ ...
```

**D) Regional Guide Enhancement:**
Show family distribution in current zone:
```lua
-- Add family summary section
"Available Families in Elwynn Forest:"
"  Wolf (12 items), Spider (8 items), Bear (3 items)"
```

**Implementation:**

1. **Update Core.lua (Tooltips):**
   - Add family display after item name
   - Show exotic requirement warning
   - Add family icon (optional, size permitting)

2. **Update DatabaseBrowser.lua:**
   - Add family column to item list
   - Add family filter dropdown
   - Update search to include family name
   - Add "Group by Family" toggle

3. **Update CollectionProgressFrame.lua:**
   - Add expandable family tree view
   - Show per-family progress bars
   - Add family icons to tree

4. **Update RegionalGuide.lua:**
   - Add family distribution summary
   - Add family filter to guide
   - Show family icons in item list

**Benefits:**
- ✅ Players can see family information at a glance
- ✅ Easy to filter by specific families they want
- ✅ Better understanding of pet diversity in each zone
- ✅ Helps hunters plan farming routes by family needs
- ✅ Visual feedback with family icons

---

### 3. Description Parameterization 📝
**Priority:** ⭐⭐⭐ High  
**Complexity:** Medium  
**Status:** 📋 Planned  
**Impact:** Additional 100-150 KB savings

**Problem:**  
Descriptions have repeated patterns with minor variations:
- "Has a chance to drop from X within Y" (repeated 2,000+ times)
- "Available from Tiraxis' Ethereal Bazaar" (repeated 100+ times)
- "Seasonal Reward. Introduced in Season X, Chapter Y" (repeated 50+ times)
- "Can be purchased from X" (repeated 30+ times)

**Current Duplication:**
```lua
description = "Has a chance to drop from Timber Wolf within Elwynn Forest"
description = "Has a chance to drop from Mine Spider within Elwynn Forest"
description = "Has a chance to drop from Defias Bandit within Westfall"
-- 2,000+ variations of the same pattern!
```

**Solution: Template-Based Descriptions**

Create description templates with parameters:

```lua
-- NEW: Description templates
AV_DescriptionTemplates = {
    [1] = "Has a chance to drop from %s within %s",
    [2] = "Available from Tiraxis' Ethereal Bazaar",
    [3] = "Seasonal Reward. Introduced in Season %d, Chapter %d",
    [4] = "Can be purchased from %s",
    [5] = "Quest Reward",
    [6] = "Vendor Item",
    [7] = "%s",  -- Custom description (fallback)
}

-- Items reference template + parameters
AV_VanityItems = {
    [79256] = {
        itemid = 79256,
        name = "Beastmaster's Whistle: Felhound",
        descTemplate = 4,  -- "Can be purchased from %s"
        descParams = {"High Inquisitor Qormaladon"},
        -- Runtime: string.format(AV_DescriptionTemplates[4], "High Inquisitor Qormaladon")
        -- Result: "Can be purchased from High Inquisitor Qormaladon"
    }
}
```

**Implementation:**

1. **Analyze Description Patterns:**
   - Extract all unique description templates
   - Identify common parameters (creature names, zone names, season numbers)
   - Build template dictionary

2. **Update GenerateVanityDB_Master.ps1:**
   - Pattern matching to identify template + parameters
   - Generate template dictionary
   - Convert descriptions to template indices + params

3. **Update VanityDB_Loader.lua:**
   - Add `AV_GetDescription(item)` function
   - Format templates with parameters at runtime
   - Cache formatted strings for performance

**Size Savings:**
- **Templates**: ~50 templates × 50 bytes = ~2.5 KB
- **Parameters**: ~2,000 items × ~20 bytes = ~40 KB
- **vs Current**: ~300 KB raw descriptions
- **Savings**: ~257 KB = **86% reduction in description data**

**Benefits:**
- ✅ Massive size reduction
- ✅ Consistent description formatting
- ✅ Easy to update descriptions globally
- ✅ Localization-friendly (templates can be translated)

---

### 4. Dungeon Parent Zone Relationships 🗺️
**Priority:** ⭐⭐⭐ High  
**Complexity:** Medium  
**Status:** 📋 Planned

**Problem:**  
When you're in Orgrimmar, you can see "Ragefire Chasm" items in the subzone filter. But when you **enter** Ragefire Chasm, those items disappear because the zone changes from "Orgrimmar" to "Ragefire Chasm" - but items are tagged as `zone="Orgrimmar", subzone="Ragefire Chasm"`.

**Root Cause:**  
Dungeons have a dual identity:
- **As a subzone**: "Ragefire Chasm" is a subzone of "Orgrimmar"
- **As a zone**: "Ragefire Chasm" is its own zone with internal subzones

Current database structure doesn't capture this parent-child relationship.

**Solution: Parent Zone Field**

Add `parentZone` field to database:

```json
{
  "itemId": 79123,
  "name": "Beastmaster's Whistle: Ragefire Trogg",
  "zone": "Ragefire Chasm",
  "subzone": "Lava Pool",
  "parentZone": "Orgrimmar",  // NEW FIELD!
  "creatureId": 11671
}
```

**Matching Logic:**
```lua
-- Include item if current zone matches zone OR parentZone
if currentZone == itemData.zone or currentZone == itemData.parentZone then
    includeItem = true
end
```

**Benefits:**
- ✅ Items show when **inside dungeon** (zone match)
- ✅ Items show when **in parent city** (parentZone match)
- ✅ Works for all dungeon types (city dungeons, world dungeons)
- ✅ Foundation for "nearby dungeons" feature
- ✅ Backwards compatible (items without parentZone still work)

**Implementation Steps:**

**Phase 1: Data Enrichment**
1. Create `DungeonParentZones.json` mapping file:
   ```json
   {
     "Ragefire Chasm": "Orgrimmar",
     "The Stockade": "Stormwind City",
     "Shadowfang Keep": "Silverpine Forest",
     "Wailing Caverns": "The Barrens",
     // etc.
   }
   ```

2. Update `EnrichZoneData.ps1` to add parentZone field
3. Regenerate database with parent zone relationships

**Phase 2: Filter Logic**
1. Update `GetCategoryItems()` in CollectionProgressFrame.lua
2. Update `GetSubzonesInZone()` for parent zone awareness
3. Update tooltip filtering in Core.lua

**Phase 3: UI Enhancement**
1. Show parent zone in tooltips (if different from current zone)
   - Example: "Found in Ragefire Chasm (from Orgrimmar)"
2. Database Browser: Show parent zone in zone column
3. Progress Frame: Option to include child dungeons

**Files to Update:**
- `data/DungeonParentZones.json` (NEW)
- `utilities/EnrichZoneData.ps1`
- `utilities/GenerateVanityDB_Master.ps1`
- `AscensionVanity/VanityDB_Loader.lua`
- `AscensionVanity/CollectionProgressFrame.lua`
- `AscensionVanity/Core.lua`
- `AscensionVanity/DatabaseBrowser.lua`

**Testing Scenarios:**
- ✅ In Orgrimmar → See Ragefire items in "Ragefire Chasm" subzone
- ✅ Enter Ragefire Chasm → Still see items (zone match)
- ✅ In Ragefire internal area → See items (zone match)
- ✅ Database Browser → Shows both zone and parent zone
- ✅ Backwards compatibility → Items without parentZone still work

**Timeline:** 1-2 weeks (data + code + testing)

---

### 2. Continent-Based Filtering �
**Priority:** ⭐⭐⭐ High  
**Complexity:** Low-Medium  
**Status:** 📋 Planned

**Problem:**  
No way to group or filter items by continent. Players want to:
- "Show me all items in Eastern Kingdoms"
- "Track my Kalimdor collection progress"
- "Filter to Outland content only"
- "See which continent has the most unlearned items"

**Why Continents (Not Planets)?**
- **Planets too broad**: Only Azeroth vs Outland distinction (90%+ is Azeroth)
- **Continents just right**: Eastern Kingdoms, Kalimdor, Northrend, Outland zones
- **Meaningful grouping**: Players actually think in continent terms
- **Future-proof**: Scales to Cataclysm+ with more zones per continent

**Solution: Add Continent Field**

```json
{
  "itemId": 79123,
  "zone": "Ragefire Chasm",
  "subzone": "Lava Pool",
  "parentZone": "Orgrimmar",
  "continent": "Kalimdor"  // NEW!
}
```

**WotLK Continents:**
- **Eastern Kingdoms**: Stormwind, Ironforge, Undercity, Stranglethorn, etc.
- **Kalimdor**: Orgrimmar, Thunder Bluff, Darnassus, Barrens, etc.
- **Northrend**: Dalaran, Icecrown, Borean Tundra, etc.
- **Outland**: Hellfire Peninsula, Zangarmarsh, Nagrand, etc.

**UI Enhancements:**

**Progress Frame:**
```
View: [Continent ▼] [Eastern Kingdoms ▼]

Overall: 234/500 (46.8%)
  Beast: 80/150 (53.3%)
  Demon: 45/100 (45.0%)
  ...
```

**Database Browser:**
- Continent filter dropdown
- "Show only Eastern Kingdoms creatures"

**Statistics:**
```
Collection by Continent:
  Eastern Kingdoms: 120/250 (48.0%)
  Kalimdor: 90/200 (45.0%)
  Northrend: 24/50 (48.0%)
  Outland: 0/0 (0.0%)
```

**Benefits:**
- ✅ Meaningful geographic grouping
- ✅ Progress tracking per continent
- ✅ Farming optimization ("Clear EK first")
- ✅ Simple UI addition (one dropdown)
- ✅ Scales to future expansions

**Timeline:** 1 week (data enrichment + UI integration)

---

### 3. Smart Dungeon Detection 🤖
**Priority:** ⭐⭐ Medium  
**Complexity:** Low-Medium  
**Status:** 📋 Planned

**Problem:**  
Manually maintaining `DungeonParentZones.json` is error-prone and requires updates when new content is added.

**Solution: Automated Detection**

Script to automatically detect dungeons and their parent zones:

```powershell
# AnalyzeDungeonHierarchy.ps1

# Analyze all items to find zones that are BOTH:
# 1. A subzone of another zone
# 2. A zone with their own subzones

$dungeonCandidates = @{}

# Find zones that appear as subzones of other zones
foreach ($item in $items) {
    if ($item.zone -and $item.subzone) {
        $dungeonCandidates[$item.subzone] = $item.zone
    }
}

# Verify they also exist as primary zones
$confirmedDungeons = @{}
foreach ($item in $items) {
    if ($dungeonCandidates.ContainsKey($item.zone)) {
        $confirmedDungeons[$item.zone] = $dungeonCandidates[$item.zone]
    }
}

# Output DungeonParentZones.json
```

**Benefits:**
- ✅ Automatic dungeon detection
- ✅ Catches new content automatically
- ✅ Validates existing mappings
- ✅ Suggests corrections for data errors

**Timeline:** 2-3 days

---

### 4. Zone Relationship Viewer 👁️
**Priority:** ⭐ Low  
**Complexity:** Low  
**Status:** 📋 Planned

**Problem:**  
Users and developers need to understand zone relationships for debugging and exploration.

**Solution: Debug UI**

Add `/avanity zones` command to show zone hierarchy:

```
Current Zone: Ragefire Chasm
Parent Zone: Orgrimmar
Subzones:
  - Lava Pool (3 items)
  - Molten Core Entrance (1 item)
  - Earthborer Tunnels (2 items)

Items in this zone: 6 total (2 learned, 4 unlearned)
```

**Features:**
- Show current zone hierarchy
- List subzones with item counts
- Show parent zones (if any)
- Link to Database Browser for detailed view

**Timeline:** 1-2 days (after Feature #1)

---

### 5. Multi-ID Creature Tracking 🔍
**Priority:** ⭐⭐ Medium  
**Complexity:** Medium  
**Status:** 📋 Planned

**Problem:**  
Same creature name can have multiple creature IDs that all drop the same vanity items. This affects:
- Drop rate accuracy (tracking only one ID gives incomplete stats)
- Farming guides (players might farm wrong version)
- Data completeness (missing duplicate IDs means missing drops)

**Example Found:**
- **Zelemar the Wrathful (Creature ID 17830)** drops Item 83115
- **Zelemar the Wrathful (Unknown ID)** drops Item 141150
- Same creature, different IDs, potentially same drops!

**Root Cause:**
- Project Ascension content patches add new versions
- Difficulty scaling creates multiple IDs
- Item updates/replacements create duplicates
- Current database only tracks ONE creature ID per item

**Solution: Creature ID Aliases**

Add `creatureIdAliases` field to track all known IDs:

```json
{
  "itemId": 83115,
  "name": "Summoner's Stone: Zelemar the Wrathful",
  "creatureId": 17830,
  "creatureIdAliases": [17830, 141150],  // NEW FIELD!
  "zone": "Ragefire Chasm"
}
```

**Benefits:**
- ✅ Track kills/loots across ALL versions of a creature
- ✅ Show comprehensive drop rates
- ✅ Warn players about multiple versions
- ✅ Detect missing item IDs automatically
- ✅ Better farming recommendations

**Implementation:**

**Phase 1: Detection Script**
```powershell
# FindDuplicateCreatures.ps1

# Find creatures with same name but different IDs
$creatureNames = @{}
foreach ($item in $items) {
    $creatureName = $item.creatureName
    if (!$creatureNames.ContainsKey($creatureName)) {
        $creatureNames[$creatureName] = @()
    }
    $creatureNames[$creatureName] += $item.creatureId
}

# Report duplicates
$duplicates = $creatureNames.Where({ $_.Value.Count -gt 1 })
foreach ($dup in $duplicates) {
    Write-Host "$($dup.Key): IDs $($dup.Value -join ', ')"
}
```

**Phase 2: Database Enhancement**
1. Add `creatureIdAliases` array to VanityDB
2. Update stats tracking to check ALL aliases
3. Update tooltips to show "Multiple versions" warning

**Phase 3: UI Enhancements**
1. Tooltip: "(Creature has multiple versions - stats combined)"
2. Database Browser: Show all known IDs
3. Statistics: Aggregate across all aliases

**Tooltip Example:**
```
Zelemar the Wrathful (Boss) Doomguard
Has a chance to drop from Zelemar the Wrathful.

⚠️ Multiple Versions: This creature has 2 known IDs
   Stats combined across all versions

[Stats] Your Farming Stats:
Lifetime K5|L5|D2 (40.0%)  Session K2|L2|D1 (50.0%)
```

**Statistics Tracking:**
```lua
-- Check all aliases when recording kills
local function RecordCreatureKill(creatureId)
    local item = GetItemByCreatureId(creatureId)
    if item and item.creatureIdAliases then
        -- This is an alias - use primary ID for tracking
        creatureId = item.creatureIdAliases[1]  -- Primary ID is first
    end
    
    -- Record stats under primary ID
    IncrementKillCount(creatureId)
end
```

**Files to Update:**
- `utilities/FindDuplicateCreatures.ps1` (NEW)
- `utilities/GenerateVanityDB_Master.ps1`
- `AscensionVanity/StatisticsTracker.lua`
- `AscensionVanity/Core.lua` (tooltip warnings)
- `AscensionVanity/DatabaseBrowser.lua`

**Timeline:** 1-2 weeks

---

### 6. Data Quality: Zone Name Normalization 📝
**Priority:** ⭐ Low  
**Complexity:** Low  
**Status:** 📋 Planned

**Problem:**  
Inconsistent zone/subzone names cause filtering issues:
- "The Barrens" vs "Barrens"
- "Stormwind City" vs "Stormwind"
- Typos and variations

**Solution: Name Normalization**

Create `ZoneNameMappings.json` to standardize names:

```json
{
  "aliases": {
    "Barrens": "The Barrens",
    "Stormwind": "Stormwind City",
    "SW": "Stormwind City"
  },
  "corrections": {
    "Orgrimmar ": "Orgrimmar",  // trailing space
    "Thunder bluff": "Thunder Bluff"  // capitalization
  }
}
```

**Apply during enrichment:**
```powershell
# Normalize zone names
if ($ZoneNameMappings.aliases.ContainsKey($item.zone)) {
    $item.zone = $ZoneNameMappings.aliases[$item.zone]
}
```

**Timeline:** 1 day

---

## Development Timeline

**Total Estimated Time:** 4-5 weeks

**Week 1: Core Infrastructure**
- Feature #1: Parent Zone Implementation (data + code)
- Feature #2: Continent field enrichment
- Feature #3: Automated dungeon detection script
- Feature #5: Multi-ID creature detection script

**Week 2: UI Integration**
- Feature #1: Update all UI components for parent zones
- Feature #2: Continent filtering in Progress Frame & Browser
- Feature #4: Zone relationship viewer

**Week 3: Advanced Features**
- Feature #5: Multi-ID creature tracking implementation
- Feature #6: Zone name normalization
- Feature #2: Continent-based statistics

**Week 4: Stats & Tracking**
- Feature #5: Update StatisticsTracker for creature aliases
- Feature #5: Tooltip warnings for multiple versions
- Feature #5: Database Browser enhancements

**Week 5: Testing & Polish**
- Comprehensive testing of all zone filtering
- Edge case handling
- Performance optimization
- Documentation updates

---

## Success Criteria

### Feature #1: Dungeon Parent Zones
- ✅ Items appear in both parent city and dungeon
- ✅ No duplicate item listings
- ✅ Backwards compatible with v2.3 database
- ✅ Performance: No noticeable slowdown
- ✅ All existing dungeons mapped correctly

### Feature #3: Smart Detection
- ✅ Detects 95%+ of dungeons automatically
- ✅ Generates accurate parent zone mappings
- ✅ Flags conflicts/ambiguities for manual review

### Feature #2: Continent Filtering
- ✅ All items have continent field assigned
- ✅ Progress frame shows continent-based filtering
- ✅ Database Browser filters by continent
- ✅ Statistics show per-continent progress
- ✅ UI handles missing/unknown continents gracefully
- ✅ Outland items correctly grouped separately from Azeroth

### Feature #4: Zone Viewer
- ✅ Clearly shows zone relationships
- ✅ Helpful for debugging filtering issues
- ✅ Accessible via slash command

### Feature #5: Multi-ID Creature Tracking
- ✅ Detects all duplicate creature IDs automatically
- ✅ Stats aggregate across all versions
- ✅ Tooltips show warning when multiple IDs exist
- ✅ Drop rates combine data from all aliases
- ✅ Database shows all known IDs per creature
- ✅ No data loss when tracking merged IDs

---

## Testing Plan

### Manual Testing Scenarios

**Dungeon Entry/Exit:**
1. Stand in Orgrimmar → Open progress frame → See Ragefire items
2. Enter Ragefire Chasm → Progress frame updates → Still see items
3. Move to different subzone in dungeon → Items remain visible
4. Exit dungeon → Back in Orgrimmar → Items still visible

**Edge Cases:**
- Dungeons with no parent zone (open world dungeons)
- Items with zone but no subzone
- Items with parentZone but no current zone match
- Multiple characters in different zones

**Performance:**
- Large databases (2000+ items) filter quickly
- No lag when changing zones
- Memory usage remains stable

### Automated Testing
- Unit tests for zone matching logic
- Data integrity tests (no orphaned parent zones)
- Backwards compatibility tests

---

## Migration Path

### From v2.3 to v2.4

**Database:**
- Add `parentZone` field (optional, backwards compatible)
- Regenerate with `GenerateVanityDB_Master.ps1`
- Old databases still work (parentZone defaults to nil)

**User Settings:**
- No settings changes required
- No saved variables migration needed

**Performance:**
- Additional field adds ~50KB to database (negligible)
- Matching logic adds ~0.1ms per filter operation (unnoticeable)

---

## Future Considerations (v2.5+)

### Deferred Features (Not in v2.4)

**Planet-Level Hierarchy** 🌌
- **Why Deferred**: Too broad for current use cases
- **Value**: Only Azeroth vs Outland distinction (90%+ is Azeroth)
- **Decision**: Continents provide better granularity
- **Revisit When**: User demand for "Show Outland only" filtering
- **Implementation**: Simple `planet` field, only show in UI if multiple planets exist

**Multi-Level Zone Hierarchies** 🏰
- **Why Deferred**: Rare edge cases, adds complexity
- **Example**: City → District → Dungeon → Wing → Room
- **Decision**: parentZone covers 99% of cases
- **Revisit When**: Encounter 3+ level hierarchies in practice
- **Implementation**: `grandparentZone` field if needed

### Planned for v2.5+

Based on v2.4 infrastructure:

1. **Nearby Dungeons**: Show dungeons in current continent/zone
2. **Dungeon Progress**: Track completion per dungeon
3. **Breadcrumb Navigation**: "Items in Ragefire Chasm (from here)"
4. **Cross-Continent Comparison**: "You've cleared 60% of EK but only 20% of Kalimdor"
5. **Instance Difficulty**: Normal/Heroic/Mythic tracking (Project Ascension specific)

---

## Risks & Mitigation

**Risk:** Parent zone mapping errors
- **Mitigation:** Automated detection + manual review + community feedback

**Risk:** Performance impact on large databases
- **Mitigation:** Benchmark before/after, optimize if needed

**Risk:** UI clutter from showing parent zones
- **Mitigation:** Compact display, tooltips only when relevant

**Risk:** Breaking backwards compatibility
- **Mitigation:** Extensive testing with v2.3 databases

---

## Community Feedback Integration

**Feedback Welcome On:**
- Which dungeons to prioritize for parent zone mapping
- UI display preferences for zone hierarchies
- Edge cases we haven't considered
- Performance concerns with large databases

**Feedback Channels:**
- GitHub Issues
- Discord #ascension-vanity
- In-game /avanity feedback command

---

**Last Updated:** November 10, 2025  
**Status:** 📋 Planning - Ready for implementation after v2.3 release
