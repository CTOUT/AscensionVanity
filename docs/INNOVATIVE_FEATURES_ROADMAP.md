# AscensionVanity - Innovative Display Features Inspired by Modern Addons

**Date:** November 3, 2025  
**Last Updated:** November 3, 2025  
**Research:** Rarity & PetTracker analysis  
**Purpose:** Feature ideas for minimap/world map integration + Quest-Locked NPCs

---

## 🆕 NEW FEATURE: Quest-Locked NPC Warnings ⭐⭐⭐

**Priority:** CRITICAL - Prevents permanent collection loss  
**Complexity:** Medium  
**Version Target:** v2.2  
**Status:** 🔨 Planning

### Problem Statement
Many vanity items drop from quest-spawned NPCs that become unavailable after quest completion. Players often complete quests **before** farming the item, losing access forever (or until reset). This is devastating for completionists.

### Solution: Quest Lock Warning System

**Tooltip Enhancement:**
```
[Creature Name]
  Combat Pet: Beastmaster's Whistle: Pet Name
  
  ⚠️ QUEST-LOCKED NPC!
  Quest: "Quest Name" (ID: 12345)
  Warning: This NPC disappears after quest completion!
  Don't turn in the quest until you get the drop!
```

**Features:**
- 🔴 High-visibility warning in tooltips
- ⚠️ Clear visual indicators (color + icon)
- 📜 Quest name and ID for easy reference
- ✅ Quest completion check (warn if already completed)
- 🟢 Active quest highlight (remind to farm before turning in)

**Data Structure:**
```lua
-- New field in VanityDB
questLock = {
    questId = 12345,
    questName = "The Quest Name",
    lockType = "completion",  -- "completion", "phase", "daily", "weekly"
    warning = "Don't complete quest until you get this item!"
}
```

**Configuration Options:**
- Toggle quest warnings (default: ON)
- Color customization for warning text
- Hide warnings for completed quests (optional)

**Implementation Strategy:**
1. **Phase 1:** Create `data/QuestLockedNPCs.json` with known cases ✅
2. **Phase 2:** Extend database schema and generation scripts
3. **Phase 3:** Implement tooltip warnings with quest status checks
4. **Phase 4:** Community contribution system (GitHub issues/PRs)

**Known Quest-Locked NPCs:**

1. **Demon Spirit** (Creature ID: 11876)
   - **Drops:** Summoner's Stone: Demon Spirit (Item ID: 82875)
   - **Quest:** Hand of Iruxos (Quest ID: 5381) - **Horde Only**
   - **Lock Type:** Completion (one-time quest)
   - **Warning:** ⚠️ NPC only spawns during quest! Don't complete until you get the drop!
   - **Summon Method:** Use Demon Pick (quest item) on Demon Box (drops from NPCs during quest)
   - **Verified:** 2025-11-03 by CTOUT
   - **References:** [Quest](https://db.ascension.gg/?quest=5381) | [NPC](https://db.ascension.gg/?npc=11876) | [Item](https://db.ascension.gg/?item=82875)

2. **Enraged Panther** (Creature ID: 10992)
   - **Drops:** Beastmaster's Whistle: Enraged Panther (Item ID: 80093)
   - **Quest:** Hypercapacitor Gizmo (Quest ID: 5151) - **Horde Only**
   - **Lock Type:** Completion (one-time quest)
   - **Warning:** ⚠️ Elite panther can only be freed during quest! Don't complete until you get the drop!
   - **Release Method:** Right-click cage with Panther Cage Key (quest item) to free Elite NPC
   - **Additional Notes:** Elite mob with long respawn timer - farm carefully before completing quest!
   - **Verified:** 2025-11-03 by CTOUT
   - **References:** [Quest](https://db.ascension.gg/?quest=5151) | [NPC](https://db.ascension.gg/?npc=10992) | [Item](https://db.ascension.gg/?item=80093)

---

## Research Summary

### Rarity Features Worth Learning From:
1. **LDB (LibDataBroker) Feed** - Minimap icon with expandable tooltip
2. **Progress Bars** - Visual representation of collection progress
3. **Statistics Integration** - Uses game statistics to track attempts
4. **Session/Day/Week/Month Breakdowns** - Farming analytics
5. **TomTom Waypoint Integration** - Automatic waypoint creation
6. **Holiday Reminders** - Context-aware notifications
7. **Instance Lock Awareness** - Knows what you've killed this week
8. **Automatic Screenshots** - Captures rare drops
9. **Tooltip Enhancements** - Shows drop info on NPC/item tooltips ✅ (we have this!)

### PetTracker Features Worth Learning From:
1. **Map Overlay Icons** - Shows pet locations directly on world map
2. **Zone Tracker Panel** - Progress display for current zone
3. **Magnifying Glass Filter** - Search/filter interface on map
4. **Species Filter** - Show/hide specific categories
5. **Breed/Rarity Display** - Enhanced information everywhere
6. **Enemy Ability Tracking** - In-battle information display
7. **History/Journal System** - Saves encounter history and loadouts

---

## Innovative Features for AscensionVanity (No Plagiarism)

### 1. **Minimap Integration** ⭐ High Priority

**Concept:** Minimap button that shows zone-specific vanity item status

**Implementation Ideas:**
```lua
-- Minimap icon using LibDBIcon (standard library)
local minimapButton = {
    icon = "Interface\\Icons\\ability_hunter_beastcall",
    tooltip = function()
        -- Show current zone items count
        local zone = GetZoneText()
        local unlearned = GetUnlearnedItemsInZone(zone)
        return string.format("%s\n%d unlearned items",
            zone, #unlearned)
    end,
    onClick = function()
        -- Toggle Regional Guide display
        AscensionVanity_ShowCurrentZoneItems()
    end
}
```

**Benefits:**
- ✅ Quick access to regional guide
- ✅ Visual indicator of items in current zone
- ✅ Color-coded: Green (all learned), Yellow (items available), Red (many items)
- ✅ Click to show full list

**Libraries Needed:**
- `LibDBIcon-1.0` (minimap button standard)
- `LibDataBroker-1.1` (data feed integration)

---

### 2. **World Map Overlay** ⭐⭐ Medium Priority

**Concept:** Show creature spawn locations on world map

**Implementation Ideas:**
```lua
-- Add map pins for creatures that drop unlearned items
for creatureId, items in pairs(zoneCreatures) do
    if HasUnlearnedItems(items) then
        local pin = CreateMapPin({
            x = creatureData.x,
            y = creatureData.y,
            icon = GetCategoryIcon(items[1].category),
            tooltip = function()
                return FormatCreatureTooltip(items)
            end
        })
    end
end
```

**Features:**
- Pin creatures with unlearned items
- Different icons per category (beast/demon/dragonkin etc)
- Filter by category (show only beasts, etc)
- Click pin to get detailed info
- Only show in zones with vanity drops

**Benefits:**
- ✅ Visual hunting guide
- ✅ See all targets at a glance
- ✅ Filter by what you're collecting
- ✅ Integrates with TomTom for waypoints

---

### 3. **Collection Progress Bar** ⭐ High Priority

**Concept:** Visual progress display in settings/scanner UI

**Implementation:**
```lua
-- Progress bar per category
local progress = {
    beast = { learned = 450, total = 910 },  -- 49.5%
    demon = { learned = 320, total = 564 },  -- 56.7%
    -- etc
}

-- Display as progress bars
for category, data in pairs(progress) do
    local percent = (data.learned / data.total) * 100
    local bar = CreateProgressBar({
        width = 300,
        height = 20,
        value = percent,
        text = string.format("%s: %d/%d (%.1f%%)",
            category, data.learned, data.total, percent)
    })
end
```

**Where to Show:**
- Settings UI - Overall collection progress
- Scanner UI - Per-category breakdown
- Minimap tooltip - Quick summary
- Regional Guide - Zone-specific progress

---

### 4. **Zone Tracker Frame** ⭐⭐ Low-Medium Priority

**Concept:** Moveable frame that shows current zone progress

**Implementation:**
```lua
-- Dockable frame similar to quest tracker
local tracker = CreateFrame("Frame", "AV_ZoneTracker", UIParent)
tracker:SetSize(200, 150)
tracker:SetPoint("TOPRIGHT", -50, -200)

-- Update on zone change
function UpdateZoneTracker()
    local zone = GetZoneText()
    local items = GetUnlearnedItemsInZone(zone)
    
    tracker.title:SetText(zone)
    tracker.count:SetText(#items .. " items available")
    -- List top 5 items
end
```

**Features:**
- Shows current zone
- Lists 3-5 most huntable items
- Click to expand full list
- Moveable/hideable
- Auto-hides when no items available

---

### 5. **Farming Session Statistics** ⭐ Low Priority

**Concept:** Track kills per session and show estimated farm time

**Implementation:**
```lua
-- Track kills this session
AV_SessionData = {
    sessionStart = time(),
    kills = {
        [creatureId] = {
            count = 15,
            firstKill = timestamp,
            lastKill = timestamp
        }
    }
}

-- Calculate average time between kills
function GetEstimatedTimeToComplete(creatureId)
    local kills = AV_SessionData.kills[creatureId]
    if kills and kills.count > 5 then
        local avgTime = (kills.lastKill - kills.firstKill) / kills.count
        local remainingKills = CalculateRemainingAttempts(creatureId)
        return avgTime * remainingKills
    end
end
```

**Benefits:**
- ✅ "~2 hours remaining at current rate"
- ✅ Motivational (progress feedback)
- ✅ Session/daily/weekly breakdowns
- ✅ Identifies best farming routes

---

### 6. **TomTom Waypoint Integration** ⭐⭐ Medium Priority

**Concept:** Auto-create waypoints for creatures with unlearned items

**Implementation:**
```lua
-- If TomTom is loaded, add waypoint command
if TomTom then
    function AV_AddWaypointForCreature(creatureId)
        local data = GetCreatureLocationData(creatureId)
        if data then
            TomTom:AddWaypoint(data.mapID, data.x, data.y, {
                title = data.name .. " (Vanity Drop)",
                persistent = false,
                minimap = true,
                world = true
            })
        end
    end
end
```

**Features:**
- `/avanity waypoint <creature>` - Add waypoint
- `/avanity nearme` - Waypoints for 3 nearest creatures
- Click map pin to add waypoint
- Auto-clear on item learned

---

### 7. **Smart Notifications** ⭐ Low Priority

**Concept:** Context-aware reminders

**Examples:**
- "You haven't farmed Molten Core this week" (if tracking raid pets)
- "New zone detected: 5 unlearned items available here!"
- "Congratulations! You've cleared all items in Durotar"
- "Item learned: Prairie Stalker (15/910 Beasts)"

**Implementation:**
```lua
-- Zone change detection
function OnZoneChanged(newZone)
    local items = GetUnlearnedItemsInZone(newZone)
    if #items > 0 and AV_Config.zoneNotifications then
        print(string.format(
            "|cFF00FF96AscensionVanity:|r %s has %d unlearned item(s)!",
            newZone, #items
        ))
    end
end
```

---

### 8. **Enhanced Tooltip Integration** ✅ (Already Implemented!)

**Current Status:** We already show vanity drops in creature tooltips!

**Potential Enhancements:**
- Show probability/rarity (if known)
- Show last seen/killed timestamp
- Show if you've killed this creature before
- Color-code by learned status

---

## 🆕 Advanced Farming Features (v2.4+)

### Instance/Phase Tracking ⭐⭐
**Priority:** Medium  
**Complexity:** Medium  
**Version Target:** v2.4

**Problem:** Realm hopping for rare spawns (e.g., Humar the Pridelord, Bayne) requires tracking which instances you've checked.

**Features:**
- Track current instance ID (realm/phase)
- History of instances checked in current session
- Timer since last instance hop
- Notification when entering new instance
- **Use Case:** Check rare spawn in Instance 1 → hop → check Instance 2 → track which you've already checked

**API Available:**
```lua
-- Get current instance ID
local name, type, difficultyIndex, difficultyName, maxPlayers, 
      dynamicDifficulty, isDynamic, instanceID = GetInstanceInfo()

-- Instance ID changes when you realm hop/phase change
-- Track: {instanceID: lastChecked, rareSpawned: bool}
```

**UI:**
```
[Instance Tracker]
Current: Instance #5 (3 min ago)
Checked this session:
  ✓ Instance #1 (Humar not found)
  ✓ Instance #3 (Humar not found)  
  ✓ Instance #5 (Currently here)
```

---

### Kill/Drop Tracking ⭐⭐⭐
**Priority:** High  
**Complexity:** Low  
**Version Target:** v2.3

**Problem:** Players want to know drop rates and how unlucky they are!

**Features:**
- Track kills per creature (lifetime + session)
- Track drops received (lifetime + session)
- Calculate drop percentage
- Compare to expected drop rate (if known)
- **Use Case:** "I've killed 47 Magram Bonepaws with 0 drops (0%)"

**Data Tracked:**
```lua
creatureStats = {
    [creatureId] = {
        totalKills = 47,
        sessionKills = 12,
        totalDrops = 0,
        sessionDrops = 0,
        dropRate = 0.00,  -- Calculated
        expectedRate = 0.05,  -- 5% (if known from db)
        unluckyStreak = 47,  -- Kills since last drop
        lastDropDate = nil
    }
}
```

**Tooltip Enhancement:**
```
[Creature Name]
  Drops: Beastmaster's Whistle: Pet Name
  
  📊 Your Stats:
  Kills: 47 (12 this session)
  Drops: 0 (0.0%)
  Expected: ~5%
  You're 9.4x over expected kills! 😢
```

**API Available:**
```lua
-- Track COMBAT_LOG_EVENT_UNFILTERED
-- Filter for PARTY_KILL events
-- Match creature ID from GUID
-- Increment counter in SavedVariables
```

---

### Auction House Price Integration ⭐
**Priority:** Low  
**Complexity:** High  
**Version Target:** v2.5+ (future)

**Problem:** Players want to know vendor/AH value of dropped items.

**Challenge:** Ascension doesn't have standard AH addons working (custom AH system). Would need custom implementation.

**If Implemented:**
```
[Item Tooltip]
  Beastmaster's Whistle: Pet Name
  
  💰 Auction House:
  Current: 50g (3 listings)
  Average: 75g (30 days)
  Lowest: 40g
  
  ⚠️ Note: Combat pets are usually soulbound!
```

**Status:** **Blocked** - Need to research Ascension's AH API first. May not be feasible.

---

### Creature Stats in Tooltip ⭐⭐
**Priority:** Medium  
**Complexity:** Low  
**Version Target:** v2.3

**Problem:** Players want to know creature attack speed for farming efficiency.

**Features:**
- Show attack speed in tooltip
- Show armor/level
- Show elite status
- Helpful for knowing if creature is fast-hitting (annoying to farm)

**Tooltip Enhancement:**
```
[Creature Name] (Level 40 Elite)
  Drops: Beastmaster's Whistle: Pet Name
  
  ⚔️ Combat Stats:
  Attack Speed: 2.0 sec
  Type: Humanoid
  Location: Desolace - Magram Village
```

**API Available:**
```lua
-- On mouseover unit
UnitAttackSpeed("mouseover")  -- Returns mainSpeed, offSpeed
UnitLevel("mouseover")        -- Creature level
UnitClassification("mouseover") -- "elite", "rare", "rareelite", etc.
UnitCreatureType("mouseover") -- "Humanoid", "Beast", etc.
```

**Implementation:** Hook `GameTooltip:SetUnit()` and append stats when mousing over creatures with vanity drops.

---

## Implementation Priority Roadmap

### Phase 1 (v2.2) - Core Integrations
1. ✅ **Minimap Button** - Quick access, visual indicator
2. ✅ **Progress Bars** - In Settings/Scanner UI
3. ✅ **TomTom Integration** - Basic waypoint commands

### Phase 2 (v2.3) - Visual Enhancements
1. ⏳ **World Map Overlay** - Pin creatures on map
2. ⏳ **Zone Tracker Frame** - Dockable progress tracker
3. ⏳ **Smart Notifications** - Context-aware alerts

### Phase 3 (v2.3) - Enhanced Farming
1. ⏳ **Kill/Drop Tracking** - Per-creature statistics
2. ⏳ **Creature Stats Tooltips** - Attack speed, elite status
3. ⏳ **Session Statistics** - Farming analytics

### Phase 4 (v2.4) - Advanced Tracking
1. ⏳ **Instance/Phase Tracking** - Realm hop helper
2. ⏳ **History System** - Track attempts over time
3. ⏳ **Achievement Integration** - Collection milestones

### Phase 5 (v2.5+) - Future Enhancements
1. 🔮 **Auction House Integration** - Price tracking (pending research)
2. 🔮 **Drop Rate Calculator** - Crowdsourced data
3. 🔮 **Farming Routes** - Optimized pathing

---

## Technical Requirements

### Libraries Needed:
- `LibStub` ✅ (common dependency manager)
- `LibDBIcon-1.0` (minimap button interface)
- `LibDataBroker-1.1` (data feed for Titan Panel/Chocolate Bar)
- `HereBeDragons` (map coordinate conversion)
- `AceGUI-3.0` (advanced UI elements)

### API Compatibility:
- All features use standard WoW API
- LibDBIcon works in WOTLK (tested)
- Map overlays use standard map pin API
- No breaking changes to existing code

---

## Design Philosophy: AscensionVanity Style

**What makes our approach unique:**

1. **Clean & Simple** - No clutter, clear information
2. **Category-Focused** - Beasts/Demons/Dragonkin organization
3. **Zone-Aware** - Shows what's relevant to current location
4. **Ascension-Specific** - Custom content, Group ID filtering
5. **Non-Intrusive** - Optional features, user configurable

**Not copying, but innovating:**
- Rarity tracks **all** collectibles (mounts, pets, toys)
- PetTracker is **battle pet focused** (breeds, battles, pvp)
- AscensionVanity is **vanity combat pets only** (simple, focused)

Our features complement rather than duplicate these addons!

---

## Next Steps

1. **User Feedback** - Which features sound most useful?
2. **Library Integration** - Add LibDBIcon for minimap button
3. **Prototype** - Build minimap button + progress bars first
4. **Test & Iterate** - Ensure performance is good
5. **Document** - Update user guide with new features

---

**Conclusion:** By learning from successful addons like Rarity and PetTracker, we can add powerful visual features while maintaining AscensionVanity's unique focus on Ascension's vanity combat pets. The key is innovation, not imitation!
