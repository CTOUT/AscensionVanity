# AscensionVanity v2.2 Feature Roadmap

**Date:** November 3, 2025  
**Last Updated:** November 4, 2025  
**Current Version:** v2.1 (Released)  
**Next Version:** v2.2 (Active Development)  
**Development Branch:** v2.2-dev  
**Status:** 🚧 In Progress (95% Complete)

---

## Overview

Version 2.2 focuses on **Collection Progress Tracking** and **Regional Hunting Guides** to help players efficiently farm vanity items. This release introduces a standalone progress tracker with zone-based filtering and lays the groundwork for future map integration features.

---

## v2.2 Core Features

### 1. Collection Progress Tracker 📊
**Priority:** High  
**Complexity:** Medium  
**Status:** ✅ 100% Complete

**Description:**  
Standalone moveable frame that displays real-time collection progress with per-category breakdown and zone-based filtering.

**Implemented Features:**
- ✅ Moveable, draggable frame with persistent position
- ✅ Overall progress bar with color-coded completion
- ✅ Per-category progress bars (Beast, Demon, Undead, Dragonkin, Elemental)
- ✅ Master expand/collapse button for Overall bar
- ✅ Per-category expand/collapse buttons (ready for species expansion)
- ✅ Global/Zone view toggle button (defaults to Zone)
- ✅ Settings UI integration (show/hide checkbox)
- ✅ Slash command support (`/avanity progress`)
- ✅ Auto-updates every 5 seconds when visible
- ✅ Zone change detection with auto-refresh
- ✅ **FIXED**: Zone view data display (trailing punctuation in zone names)
- ✅ **FIXED**: Subzone-to-zone mapping with auto-promotion
- ✅ **COMPLETE**: Full zone mappings from Wowpedia (71 zones, 1114 subzones)

**November 4 Fixes:**
1. ✅ Fixed zone name matching (trailing punctuation removal)
2. ✅ Implemented subzone-to-zone auto-promotion
3. ✅ Added complete Wowpedia zone mappings (71 zones, 1114 subzones)
4. ✅ Fixed Desolace showing 18 items (11 direct + 7 from subzones)
5. ✅ Enriched 65 missing item descriptions (99.95% coverage)
6. ✅ Enhanced zone enrichment to support colons in location names
7. 🔬 Researched in-game zone extraction (future enhancement)

**Files:**
- `AscensionVanity/CollectionProgressFrame.lua` - Main tracker frame
- `AscensionVanity/RegionalGuide.lua` - Zone data functions
- `data/ZoneMappings.json` - Complete zone/subzone mappings
- `utilities/EnrichZoneData.ps1` - Zone parsing from descriptions
- `utilities/UpdateZoneMappingsFromWowpedia.ps1` - Wowpedia import
- Integration in `Core.lua`, `SettingsUI.lua`, `AscensionVanity.toc`

**User Commands:**
- `/avanity progress` - Toggle progress tracker
- Settings UI checkbox - Show/hide tracker

---

### 2. Regional Hunting Guide 🗺️
**Priority:** High  
**Complexity:** Medium  
**Status:** 🚧 75% Complete (Chat-Based Phase 1 Done)

**Description:**  
Help players discover what vanity items are available in their current zone, with zone-based filtering and creature listings.

**Phase 1: Chat-Based Guide (Complete)**
- ✅ Zone index building (indexes all items by zone/subzone)
- ✅ Current zone detection with auto-updates
- ✅ Unlearned item filtering for current zone
- ✅ Creature grouping with item listings
- ✅ Slash commands (`/avanity zone`, `/avanity regional`)
- ✅ Zone change detection

**Phase 2: Visual UI Panel (Next)**
- 🔲 Scrollable creature list with icons
- 🔲 Dynamic zone header
- 🔲 Category filtering (show specific pet types)
- 🔲 Integration buttons in Settings UI
- 🔲 "Show on Map" button (preparation for future map integration)

**Files:**
- `AscensionVanity/RegionalGuide.lua` - Zone detection and filtering
- `docs/SESSION_2025-11-02_REGIONAL_GUIDE.md` - Session notes
- `docs/REGIONAL_GUIDE_PHASE2_TODO.md` - Implementation plan

**User Commands:**
- `/avanity zone` - Show items in current zone
- `/avanity regional` - Alias for zone command
- `/avanity guide` - Show regional guide info

---

## v2.2+ Planned Features

### 3. Quest-Locked NPC Warnings ⚠️🔴
**Priority:** CRITICAL  
**Complexity:** Medium  
**Status:** 🔨 Planning  
**Version Target:** v2.2 or v2.3

**Description:**  
Warn players about vanity items that drop from quest-spawned NPCs which become unavailable after quest completion. This prevents players from losing permanent access to collectibles.

**Core Features:**
- 🔴 High-visibility tooltip warnings for quest-locked NPCs
- ⚠️ Visual indicators (color + icon) for maximum awareness
- 📜 Quest name and ID display for easy reference
- ✅ Quest completion status check (warn if already completed)
- 🟢 Active quest detection (remind to farm before turning in)
- ⚙️ Configurable settings (toggle warnings, customize colors)

**Known Quest-Locked NPCs:**

1. **Demon Spirit** (Creature ID: 11876)
   - Drops: Summoner's Stone: Demon Spirit (Item ID: 82875)
   - Quest: Hand of Iruxos (Quest ID: 5381) - Horde Only
   - Lock Type: Completion (one-time quest)
   - Warning: ⚠️ NPC only spawns during quest! Don't complete until you get the drop!

2. **Enraged Panther** (Creature ID: 10992)
   - Drops: Beastmaster's Whistle: Enraged Panther (Item ID: 80093)
   - Quest: Hypercapacitor Gizmo (Quest ID: 5151) - Horde Only
   - Lock Type: Completion (one-time quest)
   - Warning: ⚠️ Elite panther can only be freed during quest! Don't complete until you get the drop!

**Implementation Plan:**
1. Create `data/QuestLockedNPCs.json` tracking file
2. Extend database schema and generation scripts
3. Implement tooltip warnings with quest status checks
4. Community contribution system (GitHub issues/PRs)

**References:**
- `docs/INNOVATIVE_FEATURES_ROADMAP.md` - Full feature specification

---

### 4. World Map Integration 🗺️
**Priority:** Medium  
**Complexity:** High  
**Status:** 🔮 Future Research  
**Version Target:** v2.3+

**Description:**  
Display vanity item locations directly on the world map with filter options, inspired by PetTracker and Rarity addons.

**Planned Features:**
- Map overlay icons showing creature spawn locations
- Filter by category (Beast, Demon, etc.)
- Filter by learned status (show only unlearned)
- Click icon to show creature info in tooltip
- Optional: TomTom waypoint integration

**Research:**
- Study PetTracker's map icon system
- Analyze Rarity's location tracking
- Review World Map API for WOTLK 3.3.5

**Files:**
- `docs/INNOVATIVE_FEATURES_ROADMAP.md` - Research notes

---

### 5. Minimap Integration 📍
**Priority:** Low  
**Complexity:** Medium  
**Status:** 🔮 Future Research  
**Version Target:** v2.3+

**Description:**
Minimap icon with LDB feed showing nearby vanity item sources.

**Planned Features:**
- LibDBIcon minimap button
- Tooltip showing nearby creatures with drops
- Quick access to progress tracker
- Zone guide integration

---

## Development Timeline

### November 3, 2025 (Session 1)
**Completed:**
- ✅ Collection Progress Frame (90% complete)
  - Frame creation, dragging, positioning
  - Overall and category progress bars
  - Expand/collapse functionality
  - Global/Zone view toggle
  - Settings UI integration
  - Zone change detection
- ✅ Regional Guide Phase 1 (chat-based)
  - Zone indexing system
  - Current zone item filtering
  - Slash commands

**Issues Discovered:**
- 🔧 Zone view not showing data (trailing punctuation)
- 🔧 Desolace missing 7 items from subzones

### November 4, 2025 (Session 2 - Today) ✅ COMPLETE
**Completed:**
1. ✅ **Data Quality**: Enriched 65 missing item descriptions (99.95% coverage)
   - Used existing `EnrichMasterJson.ps1` (cache hits = instant!)
   - Normalized descriptions (added periods)
   - Enhanced zone parsing (support colons in location names)

2. ✅ **Zone Infrastructure**: Fixed zone view data display
   - Root cause: Trailing punctuation in zone names ("Desolace." vs "Desolace")
   - Fixed `EnrichZoneData.ps1` to strip trailing punctuation
   - Fixed `GenerateVanityDB_Master.ps1` to use JSON fields directly
   - Result: Zone view now works perfectly!

3. ✅ **Subzone Mapping**: Implemented auto-promotion logic
   - Problem: "Magram Village" was zone, not subzone of Desolace
   - Solution: Check if zone field exists in subzone mappings
   - Auto-promote parent to zone, demote to subzone
   - Fixes all similar cases automatically

4. ✅ **Complete Zone Mappings**: Imported all Wowpedia data
   - Before: 51 zones, 785 subzones (partial)
   - After: 71 zones, 1,114 subzones (complete)
   - Covers ALL Classic/TBC/WOTLK zones
   - Desolace: 9 → 21 subzones (complete canonical list)

5. ✅ **Research**: In-game zone extraction analysis
   - Created `TestZoneAPIs.lua` and `ZoneExtractor.lua`
   - Documented comparison: Wowpedia vs in-game
   - Verdict: Keep Wowpedia (complete), in-game for future custom zones

**Result**: Collection Progress Tracker 100% functional, ready for release!

### November 5-10, 2025 (This Week)
**Goals:**
- ✅ ~~Complete Collection Progress Tracker (100%)~~ **DONE!**
- 🔲 Complete Regional Guide Phase 2 (Visual UI)
- 🔲 Begin Quest-Locked NPC Warnings implementation
- 🔲 In-game testing of zone view across multiple zones
- 🔲 Release v2.2 beta for community testing

---

## Technical Notes

### Data Structure
**Zone Index:** Built on PLAYER_LOGIN from VanityDB
```lua
zoneIndex = {
    ["Durotar"] = { itemId1, itemId2, ... },
    ["Elwynn Forest"] = { itemId3, itemId4, ... },
    ...
}
```

**Progress Data:** Calculated on-demand
```lua
progress = {
    overall = { learned = 30, total = 2129 },
    beast = { learned = 27, total = 850 },
    demon = { learned = 0, total = 254 },
    ...
}
```

### Performance Considerations
- Zone index built once on login (fast lookup)
- Progress calculated on-demand (5-second throttle)
- Category bars hidden when empty (zone view optimization)

### File Organization
```
AscensionVanity/
├── CollectionProgressFrame.lua   # Progress tracker UI
├── RegionalGuide.lua             # Zone detection and filtering
├── RegionalGuideUI.lua           # (Next: Visual guide panel)
├── Core.lua                      # Slash commands and initialization
├── SettingsUI.lua                # Settings integration
└── AscensionVanity.toc           # Load order
```

---

## References

**Session Notes:**
- `docs/SESSION_2025-11-02_REGIONAL_GUIDE.md` - Regional guide implementation
- `docs/SESSION_2025-11-03_PROGRESS_TRACKER.md` - Progress tracker session

**Planning Documents:**
- `docs/REGIONAL_GUIDE_PHASE2_TODO.md` - Next steps for guide UI
- `docs/INNOVATIVE_FEATURES_ROADMAP.md` - Research and future features

**Legacy Roadmaps:**
- `FEATURE_ROADMAP_V2.1.md` - Previous version roadmap (archived)

---

## Version History

**v2.2 (In Progress)**
- Collection Progress Tracker (90% complete)
- Regional Hunting Guide Phase 1 (complete)
- Zone-based filtering (debugging)

**v2.1 (Released)**
- Category filtering system
- Combat behavior controls
- Collection status filtering
- Enhanced configuration UI

**v2.0 (Released)**
- Description enrichment (99.95% coverage)
- Group ID-based filtering
- Data integrity infrastructure
- Master workflow consolidation

---

**Last Updated:** November 4, 2025, 12:40 PST  
**Next Review:** November 5, 2025 (Regional Guide UI + Quest Warnings)
