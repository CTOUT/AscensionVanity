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

### Data Persistence Strategy

**CRITICAL:** All statistics MUST persist across sessions to provide accurate long-term data.

- **AV_CreatureStats**: Saved to disk (SavedVariablesPerCharacter) - **PERSISTS BETWEEN SESSIONS**
- **AV_SessionStats**: Runtime only - **RESETS ON /RELOAD** (by default)

This allows users to:
1. Track lifetime statistics (total kills/drops over weeks/months)
2. See accurate drop percentages based on their own data
3. Compare current session to historical performance

### TOC File Configuration

**REQUIRED: Add to AscensionVanity.toc**

```toc
## SavedVariablesPerCharacter: AV_CreatureStats
```

This tells WoW to save `AV_CreatureStats` to:
```
WTF/Account/[ACCOUNT]/[SERVER]/[CHARACTER]/SavedVariables/AscensionVanity.lua
```

**Note:** `AV_SessionStats` is NOT in SavedVariables - it's runtime only and resets each session.

### Why Per-Character? Research Benefits!

**Key Research Question:** Do drop rates vary by class/spec?
- Do Beastmaster's Whistles drop more for Hunters?
- Do Elemental Lodestones drop more for Shamans?
- Do Draconic Warhorns drop more for Paladins/Warriors?

**Per-character statistics enable this research:**
1. **Farm same creature on multiple characters** (Hunter, Shaman, Mage, etc.)
2. **Compare drop rates across characters**
3. **Detect class-specific biases** in drop chances
4. **Share findings with community**

**Example Research Process:**
```
Hunter:     100 kills, 5 drops = 5.0% (Beastmaster's Whistle)
Shaman:     100 kills, 2 drops = 2.0% (Beastmaster's Whistle)
Mage:       100 kills, 1 drop  = 1.0% (Beastmaster's Whistle)

Conclusion: Hunters may have 2-5x higher drop rate for Beast items!
```

**Why This Matters:**
- **Optimize farming routes** (farm with most efficient class)
- **Community knowledge** (share which class farms best)
- **Game mechanics insight** (does Ascension have class affinity?)

**Future Enhancement (v2.4):**
- Export statistics to CSV for analysis
- Compare stats across multiple characters on same account
- Community data aggregation (requires backend)

### SavedVariablesPerCharacter (PERSISTS TO DISK)

```lua
-- File: WTF/Account/[ACCOUNT]/[SERVER]/[CHARACTER]/SavedVariables/AscensionVanity.lua
AV_CreatureStats = {
    -- Character metadata (for research/export)
    _metadata = {
        characterName = "Huntard",
        className = "HUNTER",
        classDisplayName = "Hunter",
        realm = "Project Ascension",
        dataVersion = "2.3.0",  -- Track data structure version
    },
    
    -- PERSISTENT: Lifetime statistics (saved between sessions)
    [creatureId] = {
        -- Core data (saved to disk)
        totalKills = 147,           -- All-time kill count
        totalDrops = 3,             -- All-time vanity drops received
        firstKillDate = 1699564800, -- Unix timestamp of first kill
        lastKillDate = 1699651200,  -- Unix timestamp of most recent kill
        lastDropDate = 1699650000,  -- Unix timestamp of most recent drop
        
        -- Drop breakdown (for class affinity research)
        dropsByCategory = {
            ["Beastmaster's Whistle"] = 2,  -- Beast items
            ["Elemental Lodestone"] = 1,    -- Elemental items
            -- etc.
        },
        
        -- Calculated fields (computed on-the-fly, NOT saved)
        -- These are calculated from totalKills/totalDrops when needed
        dropRate = 0.0204,          -- 2.04% (calculated: totalDrops / totalKills)
        unluckyStreak = 45,         -- Kills since last drop (calculated)
    },
    -- ... more creatures (grows over time as you farm different mobs)
}

-- Runtime-only session tracking (NOT saved to disk by default)
AV_SessionStats = {
    -- RUNTIME: Current session only (resets on /reload or manual reset)
    sessionStart = 1699650000,  -- Unix timestamp when session started
    lastKillTime = 1699651200,  -- Most recent kill this session
    
    creatures = {
        [creatureId] = {
            sessionKills = 12,      -- Kills THIS SESSION only
            sessionDrops = 0,       -- Drops THIS SESSION only
            firstKillTime = 1699650100,
            lastKillTime = 1699651200,
            
            -- Calculated (runtime only)
            sessionDropRate = 0.00,      -- 0% (0/12 this session)
            killsPerHour = 5.2,          -- Based on session timestamps
            timeSinceLastKill = 120,     -- Seconds since last kill
        }
    },
    
    -- Session summary (all creatures combined)
    summary = {
        totalKills = 15,
        totalDrops = 0,
        uniqueCreatures = 2,
        longestStreak = 12,
        topCreature = 2959,
    }
}
```

---

## Drop Chance Calculation

### User-Generated Data Only

**Philosophy:** We only show drop chances based on the **user's own data**, not theoretical or crowd-sourced rates.

**Why this matters:**
- Accurate: Based on actual player experience
- Transparent: Player knows this is THEIR data, not game data
- Motivating: Seeing "0.0%" after 50 kills motivates continued farming
- Honest: We don't claim to know official drop rates

### Display Logic

```lua
function AV_CalculateDropChance(creatureId)
    local stats = AV_CreatureStats[creatureId]
    if not stats or stats.totalKills == 0 then
        return nil  -- No data available
    end
    
    local dropRate = (stats.totalDrops / stats.totalKills) * 100
    return dropRate  -- e.g., 2.04 for 2.04%
end

function AV_FormatDropChance(creatureId)
    local dropRate = AV_CalculateDropChance(creatureId)
    if not dropRate then
        return "No data"
    end
    
    local stats = AV_CreatureStats[creatureId]
    return string.format("%d kills, %d drops (%.1f%% drop chance)",
        stats.totalKills, stats.totalDrops, dropRate)
end
```

### Display Examples

**Example 1: Never killed**
```
📊 Your Stats: No data yet
```

**Example 2: Killed but no drops**
```
📊 Your Stats:
Lifetime: 47 kills, 0 drops (0.0% drop chance)
```

**Example 3: Some drops**
```
📊 Your Stats:
Lifetime: 147 kills, 3 drops (2.0% drop chance)
```

**Example 4: Many drops (lucky!)**
```
📊 Your Stats:
Lifetime: 20 kills, 5 drops (25.0% drop chance)
🍀 You're lucky! Above average drop rate
```

### Accuracy Disclaimer

**Add to tooltip (optional, configurable):**
```
💡 Tip: Drop chances shown are based on YOUR data only
```

Or in Settings UI:
```
ℹ️ Statistics are based on your personal farming data.
   These are not official drop rates.
```

---

## Class Affinity Research Feature

### Hypothesis Testing: Do Drop Rates Vary by Class?

**Research Question:** Does your character class affect vanity item drop rates?

**Hypotheses to Test:**
1. **Beast Affinity:** Hunters get more Beastmaster's Whistle drops (Beast pets)
2. **Elemental Affinity:** Shamans get more Elemental Lodestone drops (Elemental pets)
3. **Dragonkin Affinity:** Mages get more Draconic Warhorn drops (Dragonkin pets)
4. **Demon Affinity:** Warlocks get more Summoner's Stone drops (Demon pets)
5. **Undead Affinity:** Death Knights get more Blood Soaked Vellum drops (Undead pets)

### Data Collection Strategy

**Controlled Farming:**
1. **Pick a test creature** (e.g., Magram Bonepaw in Desolace)
2. **Farm with multiple characters** (100+ kills per character minimum)
3. **Record category-specific drops** (Beast, Elemental, Dragon, etc.)
4. **Compare drop rates** across characters

**Example Research Data:**

| Character | Class | Total Kills | Beast Drops | Elemental Drops | Dragon Drops | Demon Drops | Undead Drops | Overall Rate |
|-----------|-------|-------------|-------------|-----------------|--------------|-------------|--------------|--------------|
| Huntard | Hunter | 100 | **8** | 1 | 1 | 0 | 0 | 10.0% |
| Shamanator | Shaman | 100 | 2 | **6** | 0 | 1 | 0 | 9.0% |
| Mageface | Mage | 100 | 1 | 1 | **6** | 0 | 1 | 9.0% |
| Warlockula | Warlock | 100 | 0 | 1 | 1 | **5** | 1 | 8.0% |
| Dethknight | Death Knight | 100 | 1 | 0 | 0 | 1 | **6** | 8.0% |

**Analysis:** Each class gets 3-6x more drops for their thematic pet type!

### Implementation: Drop Category Tracking

**When recording a drop:**
```lua
function statsFrame:RecordDrop(creatureId, itemId)
    local stats = AV_CreatureStats[creatureId]
    stats.totalDrops = stats.totalDrops + 1
    stats.lastDropDate = time()
    
    -- Track by category for class affinity research
    local itemCategory = AV_GetItemCategory(itemId)  -- "Beast", "Elemental", etc.
    if itemCategory then
        stats.dropsByCategory = stats.dropsByCategory or {}
        stats.dropsByCategory[itemCategory] = (stats.dropsByCategory[itemCategory] or 0) + 1
    end
end
```

### Export for Analysis (Future: v2.4)

**CSV Export Command:** `/avanity export stats`

**Output Format:**
```csv
Character,Class,CreatureID,CreatureName,TotalKills,TotalDrops,BeastDrops,ElementalDrops,DragonDrops,DemonDrops,UndeadDrops,DropRate
Huntard,HUNTER,2959,Magram Bonepaw,100,9,8,1,0,0,0,9.0%
Shamanator,SHAMAN,2959,Magram Bonepaw,100,9,2,6,1,0,0,9.0%
```

**Analysis Tools:**
- Import CSV into Excel/Google Sheets
- Calculate category-specific drop rates per class
- Statistical significance testing (Chi-square test)
- Visualize with charts

### Community Contribution

**Share Your Findings:**
1. Export your stats to CSV
2. Post to Discord/Reddit with sample size
3. Others validate with their own data
4. Build community drop rate database

**Expected Timeline:**
- **Week 1**: Basic tracking implemented (Phase 1)
- **Week 2**: CSV export added (Phase 2)
- **Month 1**: Community starts collecting data
- **Month 2**: Enough data for statistical significance
- **Month 3**: Publish findings!

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
  Lifetime: 47 kills, 0 drops (0.0% drop chance)
  Session: 12 kills, 0 drops
  Unlucky Streak: 47 kills since last drop
  
  ⏱️ Session: 2h 53m (5.2 kills/hour)
```

**Drop Chance Display Rules:**
- **0 drops**: Show "0.0% drop chance" (accurate, based on your data)
- **1+ drops**: Show "X.X% drop chance" (e.g., "3 drops / 147 kills = 2.0%")
- **Note to user**: "Based on your personal data - not official drop rates"

**Configuration:**
- Toggle stats display on/off
- Show/hide session stats
- Show/hide lifetime stats
- Show/hide unlucky streak

**Implementation:**
```lua
-- In Core.lua tooltip hook
if AV_Config.showKillStats and creatureData then
    local stats = AV_CreatureStats[creatureId]
    
    -- Only show if we have data
    if stats and stats.totalKills > 0 then
        tooltip:AddLine(" ")  -- Spacer
        tooltip:AddLine(AV_COLOR_GOLD .. "📊 Your Stats:" .. AV_COLOR_RESET)
        
        -- Calculate drop chance
        local dropChance = (stats.totalDrops / stats.totalKills) * 100
        
        -- Lifetime stats: X kills, Y drops (Z% drop chance)
        local lifetimeText = string.format("Lifetime: %d kills, %d drops (%.1f%% drop chance)",
            stats.totalKills, stats.totalDrops, dropChance)
        tooltip:AddLine(lifetimeText, 1, 1, 1)
        
        -- Session stats (if any kills this session)
        if AV_SessionStats.creatures[creatureId] then
            local sessionStats = AV_SessionStats.creatures[creatureId]
            if sessionStats.sessionKills > 0 then
                -- Session: X kills, Y drops (only if drops > 0)
                local sessionText = string.format("Session: %d kills, %d drops",
                    sessionStats.sessionKills, sessionStats.sessionDrops)
                tooltip:AddLine(sessionText, 0.8, 0.8, 1)
                
                -- Efficiency (kills per hour)
                local elapsed = time() - sessionStats.firstKillTime
                if elapsed > 60 then  -- At least 1 minute of data
                    local killsPerHour = (sessionStats.sessionKills / elapsed) * 3600
                    local hours = math.floor(elapsed / 3600)
                    local minutes = math.floor((elapsed % 3600) / 60)
                    
                    local timeText = hours > 0 
                        and string.format("%dh %dm", hours, minutes)
                        or string.format("%dm", minutes)
                    
                    local efficiencyText = string.format("⏱️ Session: %s (%.1f kills/hour)",
                        timeText, killsPerHour)
                    tooltip:AddLine(efficiencyText, 0.6, 0.8, 1)
                end
            end
        end
        
        -- Unlucky streak warning (kills since last drop)
        if AV_Config.showUnluckyStreak then
            local killsSinceLastDrop = stats.totalKills
            if stats.totalDrops > 0 and stats.lastDropDate > 0 then
                -- Calculate kills since last drop
                -- (This is simplified - actual implementation would track kill counter at drop time)
                local unluckyThreshold = AV_Config.unluckyStreakThreshold or 20
                if killsSinceLastDrop >= unluckyThreshold then
                    local streakColor = killsSinceLastDrop >= 50 and AV_COLOR_RED or AV_COLOR_GOLD
                    tooltip:AddLine(streakColor .. "💀 Unlucky Streak: " .. killsSinceLastDrop .. " kills since last drop")
                end
            elseif stats.totalKills >= 20 and stats.totalDrops == 0 then
                -- Never had a drop and high kill count
                tooltip:AddLine(AV_COLOR_RED .. "💀 No drops yet after " .. stats.totalKills .. " kills")
            end
        end
        
        -- Optional: Show when data is limited
        if AV_Config.showDataDisclaimer and stats.totalKills < 10 then
            tooltip:AddLine(AV_COLOR_GRAY .. "💡 Limited data - drop chance may not be accurate", 0.7, 0.7, 0.7)
        end
    end
end
```

**Key Points:**
1. **Always show "X kills, Y drops (Z% chance)"** for lifetime stats
2. **Session shows kills and drops** (no percentage - not enough data)
3. **Drop chance is calculated** from totalDrops / totalKills
4. **No data disclaimer** when kill count is low
5. **Unlucky streak** prominently displayed when threshold exceeded

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
