# Kill/Drop Statistics System Design

**Version:** v2.3  
**Created:** November 9, 2025  
**Status:** Design Phase

---

## Overview

A comprehensive statistics tracking system that integrates across multiple UI components to provide players with detailed farming data and progress tracking.

**Inspiration:** FishingBuddy-style session tracker + integrated display in existing frames

---

## Core Data Structure

### SavedVariablesPerCharacter

```lua
AV_CreatureStats = {
    -- Global statistics (lifetime, all-time)
    [creatureId] = {
        -- Lifetime stats
        totalKills = 147,
        totalDrops = 3,
        firstKillDate = 1699564800,  -- Unix timestamp
        lastKillDate = 1699651200,
        lastDropDate = 1699650000,
        
        -- Calculated fields (not saved, computed on load)
        dropRate = 0.0204,  -- 2.04% (3/147)
        unluckyStreak = 45,  -- Kills since last drop
    },
    -- ... more creatures
}

AV_SessionStats = {
    -- Session-specific tracking (reset on /reload or manual reset)
    sessionStart = 1699650000,  -- Unix timestamp
    lastKillTime = 1699651200,
    
    creatures = {
        [creatureId] = {
            sessionKills = 12,
            sessionDrops = 0,
            firstKillTime = 1699650100,
            lastKillTime = 1699651200,
            
            -- Calculated
            sessionDropRate = 0.00,  -- 0% (0/12)
            killsPerHour = 5.2,  -- Calculated from timestamps
            timeSinceLastKill = 120,  -- Seconds
        }
    },
    
    -- Session summary (all creatures combined)
    summary = {
        totalKills = 15,
        totalDrops = 0,
        uniqueCreatures = 2,  -- Number of different creatures killed
        longestStreak = 12,  -- Most kills on single creature
        topCreature = 2959,  -- Creature ID with most kills
    }
}
```

---

## Integration Points

### 1. Tooltips (Core.lua Enhancement) 📊

**Where:** Creature tooltips on mouseover  
**Display:** Compact statistics below vanity item list

**Example:**
```
[Magram Bonepaw]
  Combat Pet: Beastmaster's Whistle: Magram Bonepaw
  
  📊 Your Stats:
  Lifetime: 47 kills, 0 drops (0.0%)
  Session: 12 kills, 0 drops (0.0%)
  Unlucky Streak: 47 kills
  
  ⏱️ Session: 2h 53m (5.2 kills/hour)
```

**Configuration:**
- Toggle stats display on/off
- Show/hide session stats
- Show/hide lifetime stats
- Show/hide unlucky streak

**Implementation:**
```lua
-- In Core.lua tooltip hook
if AV_Config.showKillStats and creatureData then
    local stats = AV_GetCreatureStats(creatureId)
    if stats then
        tooltip:AddLine(" ")  -- Spacer
        tooltip:AddLine(AV_COLOR_GOLD .. "📊 Your Stats:" .. AV_COLOR_RESET)
        
        -- Lifetime stats
        local lifetimeText = string.format("Lifetime: %d kills, %d drops (%.1f%%)",
            stats.totalKills, stats.totalDrops, stats.dropRate * 100)
        tooltip:AddLine(lifetimeText, 1, 1, 1)
        
        -- Session stats (if any)
        local sessionStats = AV_GetSessionStats(creatureId)
        if sessionStats and sessionStats.sessionKills > 0 then
            local sessionText = string.format("Session: %d kills, %d drops (%.1f%%)",
                sessionStats.sessionKills, sessionStats.sessionDrops,
                sessionStats.sessionDropRate * 100)
            tooltip:AddLine(sessionText, 0.8, 0.8, 1)
            
            -- Efficiency
            if sessionStats.killsPerHour > 0 then
                local elapsed = AV_FormatTime(time() - AV_SessionStats.sessionStart)
                local efficiencyText = string.format("⏱️ Session: %s (%.1f kills/hour)",
                    elapsed, sessionStats.killsPerHour)
                tooltip:AddLine(efficiencyText, 0.6, 0.8, 1)
            end
        end
        
        -- Unlucky streak warning
        if AV_Config.showUnluckyStreak and stats.unluckyStreak >= 20 then
            local streakColor = stats.unluckyStreak >= 50 and AV_COLOR_RED or AV_COLOR_GOLD
            tooltip:AddLine(streakColor .. "💀 Unlucky Streak: " .. stats.unluckyStreak .. " kills")
        end
    end
end
```

---

### 2. Collection Progress Frame Enhancement 📊

**Where:** Add "Statistics" tab/mode to existing progress frame  
**Display:** Show farming efficiency for current zone

**New UI Elements:**

**Stats Tab Button:**
```
[Overall] [Zone] [Statistics] ← New tab
```

**Statistics View Content:**
```
╔══════════════════════════════════════╗
║       FARMING STATISTICS            ║
╠══════════════════════════════════════╣
║ Session Time: 2h 53m                ║
║ Total Kills: 15 (5.2/hour)          ║
║ Total Drops: 0                      ║
╠══════════════════════════════════════╣
║ Zone: Desolace                      ║
║                                     ║
║ • Magram Bonepaw                    ║
║   12 kills, 0 drops (0.0%)          ║
║   Last kill: 2 minutes ago          ║
║                                     ║
║ • Magram Scout                      ║
║   3 kills, 0 drops (0.0%)           ║
║   Last kill: 15 minutes ago         ║
╠══════════════════════════════════════╣
║ [Reset Session] [View All Stats]   ║
╚══════════════════════════════════════╝
```

**Features:**
- Current session summary at top
- Per-creature breakdown for current zone
- Time since last kill for each creature
- Efficiency metrics (kills/hour)
- Quick reset button
- "View All Stats" opens full stats window

**Implementation:**
```lua
-- Add to CollectionProgressFrame.lua
local function ShowStatisticsView()
    -- Hide overall/zone progress bars
    -- Show session statistics
    
    -- Session header
    local sessionTime = time() - AV_SessionStats.sessionStart
    local summary = AV_SessionStats.summary
    
    -- Top creatures list (for current zone)
    local zone = GetZoneText()
    local zoneCreatures = {}
    
    for creatureId, stats in pairs(AV_SessionStats.creatures) do
        local creatureData = AV_VanityItems[creatureName]
        if creatureData and creatureData.zone == zone then
            table.insert(zoneCreatures, {
                id = creatureId,
                name = creatureName,
                kills = stats.sessionKills,
                drops = stats.sessionDrops,
                timeSinceKill = time() - stats.lastKillTime
            })
        end
    end
    
    -- Sort by kills (descending)
    table.sort(zoneCreatures, function(a, b) return a.kills > b.kills end)
    
    -- Display top 5-10
    for i, creature in ipairs(zoneCreatures) do
        if i > 10 then break end
        -- Render creature stats line
    end
end
```

---

### 3. Database Browser Enhancement 📊

**Where:** Add stats column to creature list  
**Display:** Show kill count next to creature names

**Example:**
```
[Database Browser]
─────────────────────────────────
Desolace - 11 creatures

Creature Name          Stats
─────────────────────────────────
▼ Magram Bonepaw       🎯 47 kills
  • Item 1             ✓ Learned
  • Item 2             ○ Unlearned
  
▼ Magram Scout         🎯 12 kills
  • Item 1             ✓ Learned

▼ Never Killed         🎯 0 kills
  • Item 1             ○ Unlearned
```

**Features:**
- Small kill counter icon next to creature name
- Tooltip on hover shows full stats
- Sort by kill count (optional)
- Color-code by farming priority:
  - 🟢 Green: Many kills, have drops
  - 🟡 Yellow: Some kills, no drops yet
  - 🔴 Red: Never killed

**Implementation:**
```lua
-- In DatabaseBrowser.lua creature rendering
local stats = AV_CreatureStats[creatureId]
local killCount = stats and stats.totalKills or 0

if killCount > 0 then
    local statsText = string.format("🎯 %d kills", killCount)
    -- Add to creature name line
    
    -- Color code based on drops
    if stats.totalDrops > 0 then
        statsText = AV_COLOR_GREEN .. statsText
    elseif killCount >= 20 then
        statsText = AV_COLOR_RED .. statsText  -- High kill count, no drops
    else
        statsText = AV_COLOR_GOLD .. statsText
    end
end
```

---

### 4. Standalone Session Tracker Frame (FishingBuddy-style) 📈

**Where:** New moveable frame (optional, toggle via settings)  
**Display:** Real-time session tracking with live updates

**Purpose:** For players who want a dedicated farming tracker visible during sessions

**UI Layout:**
```
╔══════════════════════════════════════╗
║    FARMING SESSION TRACKER          ║
║           [Minimize] [X]            ║
╠══════════════════════════════════════╣
║ Session: 2h 53m                     ║
║ Total Kills: 15 (5.2/hour)          ║
║ Total Drops: 0 (0.0%)               ║
╠══════════════════════════════════════╣
║ Current Target:                     ║
║ Magram Bonepaw                      ║
║                                     ║
║ Session: 12 kills, 0 drops          ║
║ Lifetime: 47 kills, 0 drops         ║
║ Unlucky: 47 kill streak             ║
║                                     ║
║ Last Kill: 2 minutes ago            ║
║ Rate: 5.2 kills/hour                ║
╠══════════════════════════════════════╣
║ [Switch Target ▼] [Reset Session]  ║
╚══════════════════════════════════════╝
```

**Features:**
- **Compact Mode:** Just timer + kill count (minimized)
- **Full Mode:** All stats visible
- **Auto-Target:** Tracks most recently killed creature
- **Manual Target:** Dropdown to select specific creature
- **Live Updates:** Refreshes every kill
- **Persistent:** Stays on screen during farming
- **Moveable:** Drag to preferred position

**Toggle Modes:**
1. **Hidden** - Not visible (default)
2. **Compact** - Small, just essentials
3. **Full** - All details visible

**Slash Commands:**
- `/avanity tracker` - Toggle session tracker
- `/avanity tracker compact` - Switch to compact mode
- `/avanity tracker target <creature>` - Set target creature

**Implementation:**
```lua
-- New file: AscensionVanity/SessionTracker.lua

local trackerFrame = CreateFrame("Frame", "AV_SessionTracker", UIParent)
trackerFrame:SetSize(260, 220)
trackerFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -300, -200)
trackerFrame:SetMovable(true)
trackerFrame:SetClampedToScreen(true)
trackerFrame:Hide()  -- Hidden by default

-- Auto-update every 5 seconds
local updateTimer = 0
trackerFrame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer = updateTimer + elapsed
    if updateTimer >= 5 then
        updateTimer = 0
        AV_UpdateSessionTracker()
    end
end)

function AV_UpdateSessionTracker()
    -- Refresh display with latest stats
    local targetCreature = AV_SessionTrackerTarget or AV_GetMostRecentKill()
    if not targetCreature then return end
    
    local stats = AV_CreatureStats[targetCreature]
    local sessionStats = AV_SessionStats.creatures[targetCreature]
    
    -- Update all text elements
    -- ...
end
```

---

## Event Handler Implementation

### Combat Log Tracking

```lua
-- New file: AscensionVanity/StatisticsTracker.lua

local statsFrame = CreateFrame("Frame")
statsFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
statsFrame:RegisterEvent("PLAYER_LOGIN")
statsFrame:RegisterEvent("PLAYER_LOGOUT")

function statsFrame:OnEvent(event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:OnCombatLog(...)
    elseif event == "PLAYER_LOGIN" then
        self:InitializeSession()
    elseif event == "PLAYER_LOGOUT" then
        self:SaveSession()
    end
end

function statsFrame:OnCombatLog(...)
    local timestamp, subevent, _, sourceGUID, sourceName, _, _, 
          destGUID, destName, destFlags = CombatLogGetCurrentEventInfo()
    
    -- Check for PARTY_KILL (we or our group killed something)
    if subevent == "PARTY_KILL" then
        local creatureId = AV_ExtractCreatureID(destGUID)
        if creatureId then
            self:RecordKill(creatureId, destName)
        end
    end
end

function statsFrame:RecordKill(creatureId, creatureName)
    -- Initialize if first kill
    AV_CreatureStats[creatureId] = AV_CreatureStats[creatureId] or {
        totalKills = 0,
        totalDrops = 0,
        firstKillDate = time(),
        lastKillDate = 0,
        lastDropDate = 0,
    }
    
    -- Update lifetime stats
    local stats = AV_CreatureStats[creatureId]
    stats.totalKills = stats.totalKills + 1
    stats.lastKillDate = time()
    
    -- Update session stats
    AV_SessionStats.creatures[creatureId] = AV_SessionStats.creatures[creatureId] or {
        sessionKills = 0,
        sessionDrops = 0,
        firstKillTime = time(),
        lastKillTime = 0,
    }
    
    local sessionStats = AV_SessionStats.creatures[creatureId]
    sessionStats.sessionKills = sessionStats.sessionKills + 1
    sessionStats.lastKillTime = time()
    
    -- Update session summary
    AV_SessionStats.summary.totalKills = AV_SessionStats.summary.totalKills + 1
    AV_SessionStats.lastKillTime = time()
    
    -- Track unique creatures
    local uniqueCount = 0
    for _ in pairs(AV_SessionStats.creatures) do uniqueCount = uniqueCount + 1 end
    AV_SessionStats.summary.uniqueCreatures = uniqueCount
    
    -- Determine top creature
    local topKills = 0
    local topCreature = nil
    for cid, cstats in pairs(AV_SessionStats.creatures) do
        if cstats.sessionKills > topKills then
            topKills = cstats.sessionKills
            topCreature = cid
        end
    end
    AV_SessionStats.summary.topCreature = topCreature
    AV_SessionStats.summary.longestStreak = topKills
    
    -- Notify session tracker if visible
    if AV_SessionTracker and AV_SessionTracker:IsVisible() then
        AV_UpdateSessionTracker()
    end
    
    -- Optional: Print to chat if configured
    if AV_Config.chatNotifyKills then
        print(string.format("|cFF00FF96AscensionVanity:|r Kill #%d: %s",
            stats.totalKills, creatureName or "Unknown"))
    end
end

function statsFrame:InitializeSession()
    -- Reset session data on login
    if not AV_Config.persistSessionAcrossLogins then
        AV_SessionStats = {
            sessionStart = time(),
            lastKillTime = 0,
            creatures = {},
            summary = {
                totalKills = 0,
                totalDrops = 0,
                uniqueCreatures = 0,
                longestStreak = 0,
                topCreature = nil,
            }
        }
    end
end

statsFrame:SetScript("OnEvent", function(self, event, ...)
    self:OnEvent(event, ...)
end)
```

---

## Drop Detection

**Challenge:** WoW doesn't have a direct "you got a drop" event.

**Solutions:**

### Option 1: Loot Event (Most Reliable)
```lua
-- Register loot events
statsFrame:RegisterEvent("LOOT_READY")
statsFrame:RegisterEvent("LOOT_CLOSED")

function statsFrame:OnLootReady()
    -- Get currently targeted creature
    local guid = UnitGUID("target")
    if not guid then return end
    
    local creatureId = AV_ExtractCreatureID(guid)
    if not creatureId then return end
    
    -- Check loot slots for vanity items
    for slot = 1, GetNumLootItems() do
        local itemLink = GetLootSlotLink(slot)
        if itemLink then
            local itemId = tonumber(itemLink:match("item:(%d+)"))
            if AV_IsVanityItem(itemId) then
                self:RecordDrop(creatureId, itemId)
            end
        end
    end
end
```

### Option 2: Bag Scan (Backup)
```lua
-- Scan bags periodically after kills
function AV_ScanBagsForNewItems()
    -- Compare current bag contents to saved snapshot
    -- Detect newly added vanity items
    -- Cross-reference with recent kills
end
```

### Option 3: Manual Tracking
```lua
-- Slash command for manual recording
-- /avanity drop <item> <creature>
-- Useful if automatic detection fails
```

---

## Configuration Options

### Settings UI Additions

**New Section: "Kill/Drop Statistics"**

```lua
☑ Enable Kill Tracking
☑ Enable Session Tracking
☑ Show Stats in Tooltips
☑ Show Unlucky Streak Warning
☑ Show Session Tracker Frame
☐ Notify Kills in Chat
☐ Persist Session Across Logins

Unlucky Streak Threshold: [20] kills

Session Tracker Position: [Reset]
Session Tracker Mode: [Hidden ▼]
  - Hidden
  - Compact
  - Full
```

---

## Slash Commands

```lua
/avanity stats                    -- Overall statistics summary
/avanity stats <creature>         -- Specific creature stats
/avanity stats reset              -- Reset all lifetime stats (with confirmation)
/avanity stats reset session      -- Reset session stats only

/avanity session                  -- Session summary
/avanity session reset            -- Reset session data

/avanity tracker                  -- Toggle session tracker frame
/avanity tracker show             -- Show tracker
/avanity tracker hide             -- Hide tracker
/avanity tracker compact          -- Switch to compact mode
/avanity tracker full             -- Switch to full mode
/avanity tracker target <name>    -- Set target creature

/avanity drop <item> <creature>   -- Manually record drop (backup)
```

---

## Performance Considerations

### Optimization Strategies:

1. **Event Throttling:**
   - Combat log can fire hundreds of times per second
   - Only process PARTY_KILL events
   - Cache creature ID extractions

2. **Lazy Calculation:**
   - Don't calculate dropRate/killsPerHour on every kill
   - Calculate when displaying UI
   - Cache calculations for 5 seconds

3. **Memory Management:**
   - Limit session history (don't store every kill timestamp)
   - Only keep last 100 creatures in session data
   - Prune old lifetime data (creatures not killed in 6+ months)

4. **UI Updates:**
   - Throttle session tracker updates to 5-second intervals
   - Only update visible UI elements
   - Batch multiple kill notifications

---

## Testing Plan

### Unit Tests:
- Kill recording (various GUIDs)
- Drop detection (loot event parsing)
- Session calculations (kills/hour, elapsed time)
- Streak calculations

### Integration Tests:
- Tooltip display (various creatures)
- Progress frame stats tab
- Database browser stats column
- Session tracker auto-targeting

### Performance Tests:
- Combat log overhead (raid environment)
- Memory footprint (100+ creatures tracked)
- UI render time (session tracker updates)

---

## Future Enhancements (v2.4+)

1. **Historical Data:**
   - Track stats per day/week/month
   - "Best farming day" statistics
   - Trends over time

2. **Comparative Analytics:**
   - Compare your dropRate to community average
   - "You're 3x more unlucky than average"
   - Requires backend API

3. **Goals System:**
   - Set farming goals (e.g., "Kill 100 Bonepaws")
   - Progress bars toward goals
   - Notifications on goal completion

4. **Export/Import:**
   - Export stats to CSV
   - Share with guildmates
   - Import community data

---

## Implementation Priority

**Phase 1 (Week 1):**
1. StatisticsTracker.lua - Core event handler ✅
2. Data structures and kill recording ✅
3. Basic tooltip integration ✅

**Phase 2 (Week 2):**
4. Session tracking and calculations ✅
5. Progress frame stats tab ✅
6. Slash commands ✅

**Phase 3 (Week 3):**
7. Database browser stats column ✅
8. Session tracker frame (optional) ⚠️
9. Settings UI integration ✅

**Phase 4 (Week 4):**
10. Drop detection system ✅
11. Performance optimization ✅
12. Testing and polish ✅

---

**Status:** Ready for implementation  
**Next Step:** Create StatisticsTracker.lua and begin kill tracking
