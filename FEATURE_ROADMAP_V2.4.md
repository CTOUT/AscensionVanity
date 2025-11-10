# AscensionVanity v2.4 Feature Roadmap

**Date:** November 10, 2025  
**Last Updated:** November 10, 2025  
**Current Version:** v2.3-dev (Active Development)  
**Next Version:** v2.4 (Planning)  
**Development Branch:** TBD  
**Status:** 📋 Planning Phase

---

## Overview

Version 2.4 focuses on **Enhanced Zone/Dungeon Relationships** and **Data Quality Improvements** to solve issues with dungeon visibility and improve the overall data model for better filtering and discovery.

**Key Problem Solved:**  
Dungeons exist in a dual state - they are both **subzones of cities** (e.g., Ragefire Chasm is a subzone of Orgrimmar) AND **zones themselves** with their own internal areas. Current filtering doesn't handle this properly, causing items to disappear when you enter the dungeon.

**Design Philosophy:**
- Improve data model without breaking existing features
- Backwards compatible with v2.3 database
- Better support for complex zone hierarchies
- Foundation for future location-based features

---

## v2.4 Core Features

### 1. Dungeon Parent Zone Relationships 🗺️
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

### 2. Multi-Level Zone Hierarchies 🌳
**Priority:** ⭐⭐ Medium  
**Complexity:** Medium-High  
**Status:** 📋 Planned (Dependent on Feature #1)

**Problem:**  
Some locations have more complex hierarchies than just zone → subzone:
- Cities with districts that have subzones
- Dungeons with wings/levels/areas
- Outdoor zones with named landmarks inside subzones

**Examples:**
```
Stormwind City (Zone)
  ├─ Trade District (Subzone)
  │   ├─ The Stockade (Dungeon - also a Zone!)
  │   │   ├─ Cell Block (Subzone of Stockade)
  │   │   └─ Warden's Room (Subzone of Stockade)
  │   └─ Auction House (Landmark)
  └─ Cathedral Square (Subzone)
```

**Solution: Extend Parent Zone Model**

Allow multiple levels of parent zones:

```json
{
  "itemId": 79999,
  "zone": "Cell Block",
  "subzone": "East Wing",
  "parentZone": "The Stockade",
  "grandparentZone": "Stormwind City"  // NEW!
}
```

**Matching Logic:**
```lua
-- Check zone hierarchy from bottom to top
local currentZone = GetZoneText()
local matches = (currentZone == itemData.zone or
                 currentZone == itemData.parentZone or
                 currentZone == itemData.grandparentZone)
```

**Timeline:** 1 week (after Feature #1 is stable)

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

### 5. Data Quality: Zone Name Normalization 📝
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

**Total Estimated Time:** 3-4 weeks

**Week 1: Core Infrastructure**
- Feature #1: Parent Zone Implementation (data + code)
- Feature #3: Automated dungeon detection script

**Week 2: UI Integration**
- Feature #1: Update all UI components for parent zones
- Feature #4: Zone relationship viewer

**Week 3: Advanced Features**
- Feature #2: Multi-level hierarchy (if needed)
- Feature #5: Zone name normalization

**Week 4: Testing & Polish**
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

### Feature #4: Zone Viewer
- ✅ Clearly shows zone relationships
- ✅ Helpful for debugging filtering issues
- ✅ Accessible via slash command

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

Based on parent zone infrastructure:

1. **Nearby Dungeons**: Show dungeons in current zone
2. **Dungeon Progress**: Track completion per dungeon
3. **Breadcrumb Navigation**: "Items in Ragefire Chasm (from here)"
4. **Regional Collections**: Group by continent/region
5. **Instance Difficulty**: Normal/Heroic/Mythic tracking

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
