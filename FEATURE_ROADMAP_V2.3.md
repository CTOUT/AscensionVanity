# AscensionVanity v2.3 Feature Roadmap

**Date:** November 9, 2025  
**Last Updated:** November 9, 2025  
**Current Version:** v2.2-beta (Released November 8, 2025)  
**Next Version:** v2.3 (Active Development)  
**Development Branch:** v2.3-dev  
**Status:** 🚀 Planning Phase

---

## Overview

Version 2.3 focuses on **Enhanced Farming Features** and **Kill/Drop Statistics** to help players track their farming progress and optimize their collection efforts. This release introduces comprehensive tracking systems and minimap integration while maintaining AscensionVanity's clean, focused approach.

**v2.2 Delivered More Than Expected!**  
Several features originally planned for v2.3 were already implemented in v2.2 (Database Browser pagination, Zone Tracker/Progress Frame). This allows v2.3 to focus on the most requested features: **statistics tracking** and **minimap integration**.

**Design Philosophy:**
- Clean & Simple - No clutter, clear information
- Performance-Conscious - Minimal overhead, smart caching
- User-Configurable - Every feature can be toggled
- Ascension-Specific - Leverage unique server features

**Revised Scope:**
- 5 new core features (down from 7)
- ~4-5 week timeline (reduced from 6 weeks)
- Focus on most-requested features first

---

## v2.3 Core Features

### 1. Kill/Drop Statistics Tracking 📊
**Priority:** ⭐⭐⭐ High  
**Complexity:** Low-Medium  
**Status:** 🔨 Planned

**Problem:**  
Players want to know how many times they've killed a creature and their actual drop rates to understand if they're just unlucky or if something is wrong.

**Features:**
- Track kills per creature (lifetime + session)
- Track drops received (lifetime + session)
- Calculate actual drop percentage
- Show "unlucky streak" counter (kills since last drop)
- Compare to expected drop rate (if known from community data)
- Per-character tracking via SavedVariablesPerCharacter

**Tooltip Enhancement:**
```
[Creature Name]
  Combat Pet: Beastmaster's Whistle: Pet Name
  
  📊 Your Stats:
  Kills: 47 (12 this session)
  Drops: 0 (0.0%)
  Unlucky Streak: 47 kills
```

**Technical Implementation:**
```lua
-- Track COMBAT_LOG_EVENT_UNFILTERED
-- Filter for PARTY_KILL events
-- Match creature ID from GUID
-- Store in SavedVariablesPerCharacter:
AV_CreatureStats = {
    [creatureId] = {
        totalKills = 47,
        sessionKills = 12,
        totalDrops = 0,
        sessionDrops = 0,
        lastDropDate = nil,
        unluckyStreak = 47
    }
}
```

**Configuration Options:**
- Toggle kill tracking (default: ON)
- Toggle session stats display (default: ON)
- Show/hide unlucky streak counter
- Reset statistics command

**Slash Commands:**
- `/avanity stats` - View overall statistics
- `/avanity stats reset` - Reset all statistics
- `/avanity stats [creature]` - View specific creature stats

**Estimated Effort:** 6-8 hours
- Event handler implementation: 2 hours
- SavedVariables structure: 1 hour
- Tooltip integration: 2 hours
- Stats UI/commands: 2 hours
- Testing and refinement: 1-2 hours

---

### 2. Creature Combat Stats in Tooltips ⚔️
**Priority:** ⭐⭐ Medium  
**Complexity:** Low  
**Status:** 🔨 Planned

**Problem:**  
Players want to know creature difficulty before farming (attack speed, elite status, level) to optimize their farming routes.

**Features:**
- Show attack speed (helps identify fast-hitting annoyances)
- Display creature level and elite/rare status
- Show creature family/type (Beast, Humanoid, etc.)
- Color-code by difficulty (gray/green/yellow/red)
- Only show for creatures with vanity drops

**Tooltip Enhancement:**
```
[Creature Name] (Level 40 Elite Beast)
  Combat Pet: Beastmaster's Whistle: Pet Name
  
  ⚔️ Combat Info:
  Attack Speed: 2.0 sec
  Location: Desolace - Magram Village
```

**Technical Implementation:**
```lua
-- On mouseover unit with vanity drop
local attackSpeed = UnitAttackSpeed("mouseover")
local level = UnitLevel("mouseover")
local classification = UnitClassification("mouseover")
local creatureType = UnitCreatureType("mouseover")

-- Format and append to tooltip
```

**Configuration Options:**
- Toggle combat stats display (default: ON)
- Show/hide attack speed
- Show/hide creature type

**Estimated Effort:** 3-4 hours
- API integration: 1 hour
- Tooltip formatting: 1 hour
- Configuration UI: 1 hour
- Testing: 1 hour

---

### 3. Minimap Button Integration 🗺️
**Priority:** ⭐⭐ Medium-High  
**Complexity:** Medium  
**Status:** 🔨 Planned

**Problem:**  
Players need quick access to addon features without memorizing slash commands. Visual indicator of items in current zone would improve user experience.

**Features:**
- Minimap button with LibDBIcon-1.0
- Tooltip shows current zone and unlearned item count
- Color-coded indicator (green/yellow/red based on items available)
- Left-click: Toggle Database Browser (filtered to current zone)
- Right-click: Open Settings UI
- Shift-click: Toggle Collection Progress Frame
- Draggable around minimap edge

**Minimap Tooltip:**
```
AscensionVanity
─────────────────
Desolace
11 unlearned items available

Left-Click: Show items
Right-Click: Settings
Shift-Click: Progress tracker
```

**Technical Implementation:**
```lua
-- Using LibDBIcon-1.0 (standard minimap button library)
local LDB = LibStub("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

local minimapButton = LDB:NewDataObject("AscensionVanity", {
    type = "launcher",
    icon = "Interface\\Icons\\ability_hunter_beastcall",
    OnClick = function(self, button)
        if button == "LeftButton" then
            -- Show Database Browser filtered to current zone
        elseif button == "RightButton" then
            -- Open Settings UI
        end
    end,
    OnTooltipShow = function(tooltip)
        -- Show current zone stats
    end
})
```

**Libraries Required:**
- LibStub (already in use)
- LibDataBroker-1.1 (standard data feed)
- LibDBIcon-1.0 (minimap button interface)

**Configuration Options:**
- Toggle minimap button visibility
- Lock/unlock minimap button position
- Customize click behaviors

**Estimated Effort:** 6-8 hours
- Library integration: 2 hours
- Button implementation: 2 hours
- Tooltip and click handlers: 2 hours
- Configuration UI: 1 hour
- Testing: 1-2 hours

---

### 4. Farming Session Analytics 📈
**Priority:** ⭐ Medium-Low  
**Complexity:** Medium  
**Status:** 🔨 Planned

**Problem:**  
Players want to know if their farming session is efficient and get motivational feedback on progress.

**Features:**
- Track session start time
- Calculate kills per hour
- Show time since first kill
- Estimate "time to next drop" based on average
- Session summary on logout or manual check
- Track multiple creatures simultaneously

**Display Formats:**

**In-Tooltip (compact):**
```
📊 Session: 15 kills (5.2/hour) - 2h 53m
```

**Full Session Report (`/avanity session`):**
```
╔══════════════════════════════════════╗
║    FARMING SESSION SUMMARY          ║
╠══════════════════════════════════════╣
║ Session Time: 2 hours 53 minutes    ║
║ Total Kills: 15                     ║
║ Total Drops: 0                      ║
║ Kills/Hour: 5.2                     ║
║ Time Since Last Kill: 8 minutes     ║
╠══════════════════════════════════════╣
║ Top Creatures This Session:         ║
║  • Magram Bonepaw: 12 kills         ║
║  • Magram Scout: 3 kills            ║
╚══════════════════════════════════════╝
```

**Technical Implementation:**
```lua
AV_SessionData = {
    sessionStart = time(),
    lastKill = time(),
    creatures = {
        [creatureId] = {
            kills = 15,
            drops = 0,
            firstKill = timestamp,
            lastKill = timestamp
        }
    }
}

-- Calculate efficiency
function GetKillsPerHour(creatureId)
    local data = AV_SessionData.creatures[creatureId]
    local elapsed = time() - data.firstKill
    return (data.kills / elapsed) * 3600
end
```

**Configuration Options:**
- Toggle session tracking (default: ON)
- Show/hide session stats in tooltips
- Auto-reset session on logout (configurable)

**Slash Commands:**
- `/avanity session` - Show session summary
- `/avanity session reset` - Reset session data

**Estimated Effort:** 5-6 hours
- Session tracking implementation: 2 hours
- Statistics calculations: 1 hour
- Report formatting: 1 hour
- Configuration UI: 1 hour
- Testing: 1 hour

---

## v2.3 Quality of Life Improvements

### 5. ~~Pagination for Database Browser~~ ✅ COMPLETED IN v2.2
**Status:** ✅ Already Implemented

**What was delivered in v2.2:**
- ✅ Pagination system with 18 creatures per page (currently)
- ✅ Previous/Next navigation buttons
- ✅ Page counter showing current/total pages
- ✅ Auto-reset to page 1 when filters change
- ✅ Smooth performance even with 2,126+ creatures

**Possible v2.3 Enhancement:**
- Increase page size from 18 to 50 items per page
- Add "Jump to Page" input box
- Add configurable items-per-page setting

**Estimated Effort (if enhancing):** 2-3 hours
- Increase page size: 30 minutes
- Jump to page UI: 1 hour
- Configuration option: 1 hour
- Testing: 30 minutes

---

### 6. Smart Zone/Subzone Standardization 🗺️
**Priority:** ⭐ Medium  
**Complexity:** Medium  
**Status:** 🔨 Planned (from Feature Backlog)

**Problem:**  
Descriptions inconsistently reference zones vs subzones, making it harder for players to find locations.

**Current State:**
- "within Dustfire Valley" (subzone) vs "within Searing Gorge" (zone)
- "within Wyrmskull Village" (subzone) vs "within Howling Fjord" (zone)
- Database has both `zone` and `subzone` fields but descriptions are inconsistent

**Solution:**
Standardize all descriptions to use **ZONE names only**, while preserving subzone data in structured fields.

**Example:**
```json
{
  "description": "Has a chance to drop from Tempered War Golem within Searing Gorge",
  "zone": "Searing Gorge",
  "subzone": "Dustfire Valley"
}
```

**Benefits:**
- ✅ Consistent player experience (always reference main zones)
- ✅ Easier navigation (zones are more recognizable than subzones)
- ✅ Preserves detailed location data in structured fields
- ✅ Regional Guide can still filter by zone OR subzone
- ✅ Database Browser can show both zone and subzone

**Implementation Steps:**
1. Create complete subzone → zone mapping
2. Update `EnrichZoneData.ps1` to populate both fields correctly
3. Update `GenerateVanityDB_Master.ps1` description generation
4. Ensure `zone` field = parent zone, `subzone` field = specific location
5. Test Regional Guide filtering with new structure

**Estimated Effort:** 3-4 hours
- Zone mapping creation: 1 hour
- Script updates: 2 hours
- Testing and validation: 1 hour

---

## v2.3 Bug Fixes & Data Quality

### 7. Creature ID Corrections System 🔧
**Priority:** ⭐⭐ Medium  
**Complexity:** Medium  
**Status:** 🔨 Planned (from Known Issues)

**Problem:**  
Several items have incorrect creature IDs that cause descriptions to reference wrong creatures. Root cause is incorrect data in Ascension's game database.

**Known Mismatches:**

| Item ID | Item Name | Wrong Creature | Should Be |
|---------|-----------|----------------|-----------|
| 79581 | Beastmaster's Whistle: Prairie Stalker | Prairie Wolf (2958) | Prairie Stalker (2959) |
| 79583 | Beastmaster's Whistle: Mountain Cougar | Prairie Wolf Alpha (2960) | Mountain Cougar (2961) |
| 79585 | Beastmaster's Whistle: Wiry Swoop | Battleboar (2966) | Wiry Swoop (2969) |

**Solution:**
Create correction/override system:

**Steps:**

1. Create corrections file: `data/CreatureIdCorrections.json`

```json
{
  "79581": {
    "correctCreatureId": 2959,
    "originalCreatureId": 2958,
    "reason": "Item is Prairie Stalker, not Prairie Wolf",
    "verifiedBy": "Duplicate item 79582 has correct ID"
  }
}
```

2. Apply corrections during database generation
3. Re-enrich descriptions with correct creature IDs
4. Validate that names now match
5. Flag for future fresh scan validation

**Implementation Steps:**
- Create CreatureIdCorrections.json with verified fixes
- Modify `GenerateVanityDB_Master.ps1` to apply corrections
- Add validation step to detect future mismatches
- Document correction process for community contributions

**Estimated Effort:** 4-5 hours
- Corrections file creation: 1 hour
- Script integration: 2 hours
- Validation logic: 1 hour
- Testing: 1 hour

---

## Deferred to v2.4+ (Future Enhancements)

### World Map Overlay 🗺️
**Priority:** ⭐⭐ Medium (v2.4)  
**Complexity:** High  
**Deferred Reason:** Requires HereBeDragons library and complex map API integration

**Features:**
- Pin creatures on world map with unlearned items
- Different icons per category (beast/demon/dragonkin)
- Filter by category
- Click pin for detailed info
- TomTom waypoint integration

**Libraries Required:**
- HereBeDragons (map coordinate conversion)
- LibMapPinMixin (map overlay framework)

---

### ~~Zone Tracker Frame~~ ✅ COMPLETED IN v2.2
**Status:** ✅ Already Implemented as Collection Progress Frame

**What was delivered in v2.2:**
- ✅ Standalone moveable progress display
- ✅ Zone/Global view toggle button
- ✅ Shows current zone items with filtering
- ✅ Per-category progress bars
- ✅ Draggable frame with saved position
- ✅ Toggle via `/avanity progress` or Settings button

**No additional work needed** - The Collection Progress Frame with its zone view mode provides all the functionality originally envisioned for this feature.

---

### Instance/Phase Tracking 🔄
**Priority:** ⭐⭐ Medium (v2.4)  
**Complexity:** Medium  
**Deferred Reason:** Advanced feature for rare spawn farming, not core need

**Features:**
- Track which instances/phases you've checked
- History of realm hops in current session
- Timer since last instance hop
- Useful for farming rare spawns (Humar, Bayne, etc.)

---

### Drop Rate Calculator 📊
**Priority:** ⭐ Low (v2.5+)  
**Complexity:** High  
**Deferred Reason:** Requires community crowdsourcing system

**Features:**
- Collect anonymous drop rate data
- Calculate community averages
- Compare personal luck to community
- Requires server/API backend for data aggregation

---

## Technical Debt & Maintenance

### Code Quality
- [ ] Refactor tooltip hooks for better performance
- [ ] Optimize database lookups with indexed caching
- [ ] Consolidate duplicate zone mapping logic
- [ ] Add unit tests for statistics calculations

### Documentation
- [ ] Update user guide with v2.3 features
- [ ] Create video tutorial for new tracking features
- [ ] Document LibDBIcon integration patterns
- [ ] Update API reference documentation

### Performance
- [ ] Profile combat log event handler overhead
- [ ] Optimize session data storage (limit history depth)
- [ ] Lazy-load minimap button (only when needed)
- [ ] Cache creature stats to reduce API calls

---

## Implementation Timeline

### Phase 1: Core Statistics (Weeks 1-2) - PRIMARY FOCUS
- 🔨 Kill/Drop Statistics Tracking (Feature 1)
- 🔨 Creature Combat Stats (Feature 2)
- 🔨 Session Analytics (Feature 4)

**Deliverable:** Players can track kills, drops, and session efficiency

---

### Phase 2: UI Enhancements (Weeks 3-4)
- 🔨 Minimap Button Integration (Feature 3)
- ⚠️ Database Browser Pagination Enhancement (Feature 5) - *Optional: Already exists, just enhance*
- 🔨 Settings UI updates for new features

**Deliverable:** Improved navigation and discoverability

---

### Phase 3: Data Quality (Week 5)
- 🔨 Zone/Subzone Standardization (Feature 6)
- 🔨 Creature ID Corrections (Feature 7)
- 🔨 Database validation and cleanup

**Deliverable:** Consistent, accurate location data

---

### Phase 4: Testing & Release (Week 6)
- 🔨 Comprehensive testing (see TEST_CHECKLIST_V2.3.md)
- 🔨 Performance profiling
- 🔨 Bug fixes and polish
- 🔨 Documentation updates
- 🔨 Beta release preparation

**Deliverable:** v2.3 stable release

---

## v2.2 Features Already Delivered ✅

The following features were originally planned for v2.3 but were already implemented in v2.2:

1. **Database Browser Pagination** ✅
   - 18 creatures per page with Previous/Next buttons
   - Page counter and auto-reset on filter changes
   - *Could enhance to 50 items/page in v2.3 if desired*

2. **Zone Tracker Frame** ✅
   - Implemented as Collection Progress Frame with zone/global toggle
   - Shows zone-specific items with filtering
   - Moveable, draggable with saved position

**Impact on v2.3:** Reduced scope! We can focus on statistics tracking and minimap integration.

---

## Success Metrics

**Feature Adoption:**
- 70%+ of users enable kill tracking
- Minimap button click rate > 5 interactions/session
- Session stats viewed at least once by 50%+ of users

**Performance:**
- Combat log processing < 5ms per event
- Tooltip render time < 10ms
- Memory footprint increase < 1MB

**Data Quality:**
- 100% description accuracy (no wrong creatures)
- 95%+ zone/subzone coverage
- Zero lua errors from statistics tracking

---

## User Feedback Integration

**How to Contribute:**
1. **Bug Reports:** GitHub Issues with [v2.3] tag
2. **Feature Requests:** Add to FEATURE_BACKLOG.md
3. **Data Corrections:** Submit to data/CreatureIdCorrections.json
4. **Testing:** Join v2.3-beta testing program (Discord)

**Community Priorities:**
- Poll users on most-wanted features
- Beta test with power users first
- Iterate based on feedback before stable release

---

## Version Strategy

**v2.3-dev Branch:**
- Active development branch
- Frequent commits and iterations
- May contain breaking changes

**v2.3-beta Release:**
- Feature-complete but needs testing
- Community beta testing phase (1-2 weeks)
- Bug fixes and polish only

**v2.3 Stable Release:**
- Merge to main branch
- Tagged release on GitHub
- Update CurseForge/WoWInterface
- Begin v2.4 planning

---

## Questions & Decisions Needed

1. **LibDBIcon Integration:** Bundle library or require separate install?
   - **Recommendation:** Bundle (most addons do this)

2. **Statistics Storage:** Per-character or account-wide?
   - **Recommendation:** Per-character (more accurate for farming)

3. **Session Reset:** Automatic on logout or manual only?
   - **Recommendation:** Configurable with default = manual

4. **Pagination Default:** 25, 50, or 100 items per page?
   - **Recommendation:** 50 (good balance of scrolling vs clicks)

5. **Minimap Button:** Always visible or hideable by default?
   - **Recommendation:** Visible by default, easily hideable in settings

---

## Related Documentation

- `FEATURE_BACKLOG.md` - Long-term feature ideas
- `docs/INNOVATIVE_FEATURES_ROADMAP.md` - Future advanced features
- `docs/KNOWN_ISSUES.md` - Bug tracking and data quality issues
- `TEST_CHECKLIST_V2.3.md` - Testing procedures (to be created)
- `CHANGELOG.md` - Version history

---

**Last Updated:** November 9, 2025  
**Status:** Ready for Development  
**Next Steps:** Begin Phase 1 implementation (Kill/Drop Statistics)
