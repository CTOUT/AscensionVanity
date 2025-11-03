# AscensionVanity v2.1+ Feature Roadmap

**Date:** October 30, 2025  
**Last Updated:** November 3, 2025 (v2.2 Planning)  
**Current Version:** v2.1 (Complete)  
**Next Version:** v2.2 (Development Branch: v2.2-dev)  
**Status:** v2.2 Planning Phase

---

## Overview

This document captures planned features for future versions of AscensionVanity. These are ideas that extend beyond the core tooltip functionality to provide additional value to players collecting vanity items.

---

## v2.2 Planned Features (NEW)

### 0. Quest-Locked NPC Warnings ⚠️🔴
**Priority:** CRITICAL  
**Complexity:** Medium  
**Version Target:** v2.2  
**Status:** 🔨 Planning

**Description:**  
Warn players about vanity items that drop from quest-spawned NPCs which become unavailable after quest completion. This prevents players from losing permanent access to collectibles by completing quests too early.

**Core Features:**
- 🔴 High-visibility tooltip warnings for quest-locked NPCs
- ⚠️ Visual indicators (color + icon) for maximum awareness
- 📜 Quest name and ID display for easy reference
- ✅ Quest completion status check (warn if already completed)
- 🟢 Active quest detection (remind to farm before turning in)
- ⚙️ Configurable settings (toggle warnings, customize colors)

**Tooltip Example:**
```
[Creature Name]
  Combat Pet: Beastmaster's Whistle: Pet Name
  
  ⚠️ QUEST-LOCKED NPC!
  Quest: "Quest Name" (ID: 12345)
  Warning: This NPC disappears after quest completion!
  Don't turn in the quest until you get the drop!
```

**Data Structure:**
```lua
questLock = {
    questId = 12345,
    questName = "The Quest Name",
    lockType = "completion",  -- "completion", "phase", "daily", "weekly"
    warning = "Don't complete quest until you get this item!",
    notes = "Additional context for collectors"
}
```

**Implementation Plan:**
1. **Phase 1:** Create `data/QuestLockedNPCs.json` tracking file
2. **Phase 2:** Extend VanityDB schema with `questLock` field
3. **Phase 3:** Update generation scripts to merge quest lock data
4. **Phase 4:** Implement tooltip warnings with quest status API
5. **Phase 5:** Add settings UI for warning customization
6. **Phase 6:** Community contribution system (GitHub)

**Files to Create/Modify:**
- `data/QuestLockedNPCs.json` - Quest-locked NPC database (NEW)
- `VanityDB.lua` - Add questLock field to items
- `Core.lua` - Implement tooltip warning logic
- `GenerateVanityDB_Master.ps1` - Merge quest lock data
- `AscensionVanityConfig.lua` - Add quest warning settings
- `SettingsUI.lua` - Add warning configuration UI

**Benefits:**
- ✅ Prevents permanent collection loss
- ✅ Unique feature no other addon provides
- ✅ High value for completionist players
- ✅ Community-driven data collection
- ✅ Enhances addon reputation and utility

**Effort:** 3-5 days  
**Testing:** Verify warnings display, quest status checks work correctly

**Data Collection:**
- See `data/QuestLockedNPCs.json` for tracking
- Community contributions welcome via GitHub
- Manual research + db.ascension.gg queries

---

## v2.1 Completed Features

### 0a. Category Filtering 🔍
**Priority:** High  
**Complexity:** Low  
**Version Target:** v2.1  
**Status:** ✅ IMPLEMENTED

### 0b. Combat Tooltip Control ⚔️
**Priority:** High  
**Complexity:** Low  
**Version Target:** v2.1  
**Status:** ✅ IMPLEMENTED

**Description:**  
Allow players to filter which vanity item categories are displayed in tooltips. Players can enable/disable specific item types (Pets, Demons, Elementals, Dragonkin, Totems) based on their collection interests.

**Core Features:**
- Checkbox toggles in Settings UI for each category
- Real-time tooltip filtering based on selections
- Reduces tooltip clutter for specialized collectors
- Persistent settings saved to SavedVariables

**Categories:**
- ☑ **Beastmaster's Whistle** - Combat Pets (Beasts)
- ☑ **Blood Soaked Vellum** - Demons
- ☑ **Summoner's Stone** - Elementals/Satyrs
- ☑ **Draconic Warhorn** - Dragonkin
- ☑ **Elemental Lodestone** - Totems/Elementals

**UI Mockup:**
```
┌─────────────────────────────────────┐
│ AscensionVanity Settings            │
├─────────────────────────────────────┤
│ Show Tooltip Information:           │
│ ☑ Beastmaster's Whistle (Pets)     │
│ ☑ Blood Soaked Vellum (Demons)     │
│ ☑ Summoner's Stone (Elementals)    │
│ ☑ Draconic Warhorn (Dragonkin)     │
│ ☑ Elemental Lodestone (Totems)     │
├─────────────────────────────────────┤
│ Display Options:                    │
│ ☑ Show learned items                │
│ ☑ Show unlearned items              │
└─────────────────────────────────────┘
```

**Implementation:**
- Category detection via pattern matching on item names
- Filter logic in tooltip display function
- Settings UI checkboxes for each category
- Default: All categories enabled

**Benefits:**
- Reduces tooltip clutter for specialized collectors
- Pet collectors can hide demon/elemental/dragonkin items
- Warlock players can focus only on demons
- Improves user experience with personalization

**Files to Create/Modify:**
- `Core.lua` - Add category detection and filtering logic
- `AscensionVanityConfig.lua` - Add `categoryFilters` config
- `SettingsUI.lua` - Add category filter checkboxes
- No database changes required (uses existing item names)

**Effort:** 1-2 days  
**Testing:** Toggle categories and verify tooltip filtering

---

### 0b. Combat Tooltip Control ⚔️
**Priority:** High  
**Complexity:** Low  
**Version Target:** v2.1  
**Status:** ✅ IMPLEMENTED

**Description:**  
Control how vanity item information is displayed in tooltips during combat. Players can choose between showing full details, minimal information (count only), or hiding completely to reduce tooltip clutter during fights.

**Combat Modes:**
- **Normal (Show All)** - Display full vanity item information during combat
- **Minimal (Count Only)** - Show only "Vanity Items: X available"
- **Hide Completely** - Hide all vanity information during combat (default)

**UI Implementation:**
````

### 0a. Category Filtering 🔍
**Priority:** High  
**Complexity:** Low  
**Version Target:** v2.1  
**Status:** ✅ IMPLEMENTED

### 0b. Combat Tooltip Control ⚔️
**Priority:** High  
**Complexity:** Low  
**Version Target:** v2.1  
**Status:** ✅ IMPLEMENTED

**Description:**  
Allow players to filter which vanity item categories are displayed in tooltips. Players can enable/disable specific item types (Pets, Demons, Elementals, Dragonkin, Totems) based on their collection interests.

**Core Features:**
- Checkbox toggles in Settings UI for each category
- Real-time tooltip filtering based on selections
- Reduces tooltip clutter for specialized collectors
- Persistent settings saved to SavedVariables

**Categories:**
- ☑ **Beastmaster's Whistle** - Combat Pets (Beasts)
- ☑ **Blood Soaked Vellum** - Demons
- ☑ **Summoner's Stone** - Elementals/Satyrs
- ☑ **Draconic Warhorn** - Dragonkin
- ☑ **Elemental Lodestone** - Totems/Elementals

**UI Mockup:**
```
┌─────────────────────────────────────┐
│ AscensionVanity Settings            │
├─────────────────────────────────────┤
│ Show Tooltip Information:           │
│ ☑ Beastmaster's Whistle (Pets)     │
│ ☑ Blood Soaked Vellum (Demons)     │
│ ☑ Summoner's Stone (Elementals)    │
│ ☑ Draconic Warhorn (Dragonkin)     │
│ ☑ Elemental Lodestone (Totems)     │
├─────────────────────────────────────┤
│ Display Options:                    │
│ ☑ Show learned items                │
│ ☑ Show unlearned items              │
└─────────────────────────────────────┘
```

**Implementation:**
- Category detection via pattern matching on item names
- Filter logic in tooltip display function
- Settings UI checkboxes for each category
- Default: All categories enabled

**Benefits:**
- Reduces tooltip clutter for specialized collectors
- Pet collectors can hide demon/elemental/dragonkin items
- Warlock players can focus only on demons
- Improves user experience with personalization

**Files to Create/Modify:**
- `Core.lua` - Add category detection and filtering logic
- `AscensionVanityConfig.lua` - Add `categoryFilters` config
- `SettingsUI.lua` - Add category filter checkboxes
- No database changes required (uses existing item names)

**Effort:** 1-2 days  
**Testing:** Toggle categories and verify tooltip filtering

---

### 0b. Combat Tooltip Control ⚔️
**Priority:** High  
**Complexity:** Low  
**Version Target:** v2.1  
**Status:** ✅ IMPLEMENTED

**Description:**  
Control how vanity item information is displayed in tooltips during combat. Players can choose between showing full details, minimal information (count only), or hiding completely to reduce tooltip clutter during fights.

**Combat Modes:**
- **Normal (Show All)** - Display full vanity item information during combat
- **Minimal (Count Only)** - Show only "Vanity Items: X available"
- **Hide Completely** - Hide all vanity information during combat (default)

**UI Implementation:**
```
Combat Behavior:
○ Normal (Show All)
○ Minimal (Count Only)
● Hide Completely (Default) ✓
```

**Example Behavior:**

**Normal Mode (Combat):**
```
[Duskbat]
Level 9-10 Beast

Vanity Items:
  ✗ Beastmaster's Whistle: Duskbat
  ✗ Blood Soaked Vellum: Duskbat Demon
```

**Minimal Mode (Combat):**
```
[Duskbat]
Level 9-10 Beast

Vanity Items: 2 available
```

**Hide Mode (Combat):**
```
[Duskbat]
Level 9-10 Beast
```

**Implementation:**
- Combat detection via `UnitAffectingCombat("player")`
- Radio button group in Settings UI
- Three distinct modes with different tooltip behavior
- Auto-save settings
- Default: Hide completely (clean combat tooltips)

**Benefits:**
- Reduces tooltip clutter during combat
- Allows quick item count check (minimal mode)
- Flexible for different playstyles
- Improves combat readability

**Files Modified:**
- `Core.lua` - Add combat detection and mode handling
- `AscensionVanityConfig.lua` - Add `combatBehavior` setting
- `SettingsUI.lua` - Add radio button group for modes

**Effort:** 2-3 hours  
**Testing:** Enter combat, toggle modes, verify tooltip behavior

---

### 1. Auction House Integration 💰
**Priority:** Medium  
**Complexity:** Medium  
**Version Target:** v2.1

**Description:**  
Display auction house pricing data for vanity items directly in tooltips and collection UI.

**Integration Options:**
- **Auctioneer** - Popular AH addon with price scanning and market data
- **Auctionator** - Streamlined AH addon with pricing APIs
- **TSM (TradeSkillMaster)** - Advanced AH addon with extensive pricing data

**Implementation Considerations:**
- Detect which AH addon(s) are installed
- Query their price APIs for vanity item IDs
- Display pricing in tooltips (e.g., "Market Price: 500g-750g")
- Optional: Show historical pricing trends
- Graceful degradation if no AH addon detected

**Mockup Example:**
```
Vanity Items:
  ✓ Beastmaster's Whistle: Young Scavenger
     Market Price: 450g (via Auctionator)
  ✗ Beastmaster's Whistle: Duskbat
     Market Price: 325g (via Auctionator)
```

**API Research Needed:**
- Auctioneer API functions for price queries
- Auctionator API functions for price queries
- TSM API functions (if different)
- Item ID format compatibility

**Files to Create/Modify:**
- `AscensionVanity/AHIntegration.lua` - New module for AH addon integration
- `Core.lua` - Add AH price display to tooltips
- `SettingsUI.lua` - Add toggle for AH integration
- `AscensionVanityConfig.lua` - Add `showAHPrices` setting

---

### 2. Regional Hunting Guide 🗺️
**Priority:** High  
**Complexity:** Medium-High  
**Version Target:** v2.1  
**Status:** 🚧 IN PROGRESS (Phase 1 Complete)

**Description:**  
Provide a list of creatures in the player's current zone that drop vanity items the player hasn't learned yet. Helps players efficiently farm items in their current location.

**Phase 1 Complete (Nov 2, 2025):**
- ✅ Zone index builder (parses zone/subzone from VanityDB)
- ✅ Zone detection (GetZoneText, GetSubZoneText)
- ✅ Unlearned item filtering (C_VanityCollection integration)
- ✅ Slash commands: `/avanity zone`, `/avanity regional`, `/avanity guide`
- ✅ Chat-based output with grouped creatures

**Remaining Work:**
- 🔲 Visual UI panel (dedicated frame)
- 🔲 Minimap button for quick access
- 🔲 Auto-notifications on zone change (optional)
- 🔲 Distance/proximity sorting (if coordinate data available)

**Core Features:**
- Detect player's current zone/subzone
- Query database for creatures in that zone
- Filter to show only creatures dropping unlearned items
- Display in a dedicated UI panel or minimap tooltip

**UI Options:**

**Option A: Minimap Tooltip**
```
[Duskwood - Unlearned Items]
─────────────────────────────
Young Scavenger (1508)
  → Beastmaster's Whistle: Young Scavenger
  
Strigid Owl (1953)
  → Beastmaster's Whistle: Strigid Owl
  
(2 creatures with unlearned items)
```

**Option B: Dedicated Panel**
- Separate frame with scrollable list
- Click creature to show on map (if possible)
- Filter by distance (if coordinate data available)
- Sort by proximity, rarity, or item count

**Implementation Considerations:**
- Zone detection: `GetZoneText()`, `GetSubZoneText()`, `GetMinimapZoneText()`
- Database needs creature → zone mapping (already have descriptions!)
- Parse zone names from descriptions (e.g., "Has a chance to drop from Strigid Owl within Duskwood")
- Real-time zone change detection via `ZONE_CHANGED` event
- Cache zone-based queries for performance

**Database Enhancement:**
- Extract zone data from existing descriptions
- Create zone lookup table: `[zoneName] = { creatureIDs }`
- Index creature locations for fast lookups

**Files to Create/Modify:**
- `AscensionVanity/RegionalGuide.lua` - Zone-based hunting guide module
- `AscensionVanity/RegionalGuideUI.lua` - UI for displaying nearby creatures
- `VanityDB_Loader.lua` - Build zone index on load
- `Core.lua` - Register zone change events
- `SettingsUI.lua` - Add toggle for regional guide

**Data Structure Example:**
```lua
AV_ZoneIndex = {
    ["Duskwood"] = {
        [1508] = true,  -- Young Scavenger
        [1953] = true,  -- Strigid Owl
        -- ...
    },
    ["Elwynn Forest"] = {
        [478] = true,   -- Forest Spider
        -- ...
    }
}
```

---

### 3. Advanced Filtering System 🔍
**Priority:** High  
**Complexity:** Low-Medium  
**Version Target:** v2.1

**Description:**  
Allow players to filter vanity items by category and type to focus their collection efforts.

**Filter Dimensions:**

**By Category (Item Type):**
- Beastmaster's Whistle (Combat Pets)
- Blood Soaked Vellum (Demons)
- Summoner's Stone (Elementals)
- Draconic Warhorn (Dragonkin)
- Elemental Lodestone (Shaman totems?)

**By Creature Type:**
- Beast (Cat, Wolf, Bear, etc.)
- Demon (Imp, Felguard, etc.)
- Elemental (Fire, Water, Air, Earth)
- Dragonkin (Whelp, Drake, Dragon)
- Undead, Mechanical, Critter, etc.

**By Collection Status:**
- Learned Only
- Unlearned Only
- All Items

**By Region/Zone:**
- Eastern Kingdoms
- Kalimdor
- Outland
- Northrend
- Specific zones (dropdown)

**By Source:**
- World Drops
- Boss Drops
- Quest Rewards
- Vendor Items
- Event-Specific

**UI Mockup:**
```
┌─────────────────────────────────┐
│ Vanity Collection Browser       │
├─────────────────────────────────┤
│ Filters:                        │
│ Category: [All ▼]               │
│ Type: [Beast - Cat ▼]           │
│ Status: [Unlearned Only ▼]      │
│ Region: [Eastern Kingdoms ▼]    │
├─────────────────────────────────┤
│ Results: 23 items               │
│                                 │
│ ✗ Beastmaster's Whistle: ...   │
│ ✗ Beastmaster's Whistle: ...   │
│ ...                             │
└─────────────────────────────────┘
```

**Implementation:**
- Extend database to include metadata:
  - `category` (item type)
  - `creatureType` (Beast, Demon, etc.)
  - `creatureSubtype` (Cat, Wolf, etc.)
  - `zone` (parsed from description)
  - `source` (Drop, Quest, Vendor, etc.)
  
- Create filter UI with dropdown menus
- Implement filter logic with efficient indexing
- Save filter preferences to saved variables

**Database Schema Addition:**
```lua
AV_VanityItems = {
    [creatureID] = {
        items = {
            {
                id = 79465,
                name = "Beastmaster's Whistle: Duskbat",
                icon = "ability_hunter_beastcall",
                category = "Beastmaster's Whistle",
                creatureType = "Beast",
                creatureSubtype = "Bat",
                zone = "Duskwood",
                source = "Drop",
                description = "..."
            }
        }
    }
}
```

**Files to Create/Modify:**
- `AscensionVanity/FilterUI.lua` - Filter interface
- `AscensionVanity/CollectionBrowser.lua` - Browsable collection UI
- `VanityDB.lua` - Add metadata fields to database
- `utilities/EnrichMetadata.ps1` - Script to add metadata to database
- `SettingsUI.lua` - Add "Open Collection Browser" button

---

### 4. Statistics & Kill Tracking 📊
**Priority:** Medium  
**Complexity:** Low-Medium  
**Version Target:** v2.1

**Description:**  
Track player farming statistics including kills per creature and drop rates. Helps players understand their farming efficiency and provides satisfaction when drops finally happen.

**Core Features:**

**Kill Counter System:**
- Track kills per creature type/ID
- Persist data between sessions (saved variables)
- Display in tooltips with kill count AND drop rate percentage
- Show personal drop rate vs estimated drop rate
- Reset capability for fresh tracking

**Example Tooltip Display:**
```
[Duskbat]
Level 9-10 Beast

Vanity Items:
  ✗ Beastmaster's Whistle: Duskbat
     Your Stats: 47 kills, 0 drops (0.00%)
     Est. Drop Rate: ~2% (1 in 50)
     Luck Factor: Below average
```

**Drop Announcement:**
- Chat message when vanity item drops
- Optional sound notification
- Rarity indicator (if available)
- Direct link to learned item

**Example Announcements:**
```
[AscensionVanity] 🎉 Beastmaster's Whistle: Duskbat dropped!
[AscensionVanity] ⭐ New vanity item looted after 47 Duskbat kills!
[AscensionVanity] 💀 Rare drop: Blood Soaked Vellum: Felguard (1/234 kills)
```

**Tooltip Enhancement:**
```
[Duskbat]
Level 9-10 Beast

Vanity Items:
  ✗ Beastmaster's Whistle: Duskbat
     Farming Stats: 47 kills, 0 drops (0%)
     Average Drop Rate: ~2% (community data)
```

**Statistics Dashboard (Optional):**
```
┌──────────────────────────────────────┐
│ Vanity Farming Statistics           │
├──────────────────────────────────────┤
│ Most Killed: Duskbat (234 kills)    │
│ Luckiest Drop: Young Scavenger (1st)│
│ Unluckiest: Strigid Owl (167 kills) │
│                                      │
│ Recent Activity:                     │
│ • Duskbat: 47 kills (last 2 hours)  │
│ • Young Scavenger: 12 kills (today) │
└──────────────────────────────────────┘
```

**Implementation Considerations:**

**Data Tracking:**
- Use `COMBAT_LOG_EVENT_UNFILTERED` for kill detection
- Filter for `PARTY_KILL` or `UNIT_DIED` events
- Match creature GUID to database
- Increment kill counter in saved variables

**Drop Detection:**
- Use `LOOT_OPENED` + `CHAT_MSG_LOOT` events
- Parse loot messages for vanity item names
- Match item name/ID against database
- Record drop time, kill count, creature

**Saved Variables Structure:**
```lua
AscensionVanityDB.stats = {
    kills = {
        [creatureID] = {
            count = 47,
            firstKill = timestamp,
            lastKill = timestamp
        }
    },
    drops = {
        [itemID] = {
            dropTime = timestamp,
            killsBeforeDrop = 47,
            creatureID = 1508,
            creatureName = "Duskbat"
        }
    },
    session = {
        startTime = timestamp,
        kills = 0,
        drops = 0
    }
}
```

**Files to Create/Modify:**
- `AscensionVanity/Statistics.lua` - Kill tracking and drop detection
- `AscensionVanity/StatsUI.lua` - Statistics dashboard
- `Core.lua` - Integrate stats into tooltips
- `AscensionVanityConfig.lua` - Add stats settings
- `SettingsUI.lua` - Add stats toggles and reset button

---

### 5. Phase & Instance Notifications 🌍
**Priority:** Medium  
**Complexity:** Low  
**Version Target:** v2.1

**Description:**  
Alert players when changing phases or entering instances, particularly useful for rare creature farming on Ascension's dynamic realm system.

**Core Features:**

**Phase Change Detection:**
- Detect when player changes phase/layer
- Display notification with phase identifier
- Optional: Track rare spawns per phase
- Cooldown to prevent spam

**Instance Entry/Exit:**
- Notify on dungeon/raid entry
- Show available vanity creatures in instance
- Track instance-specific drops
- Reset notifications on exit

**Notification Examples:**
```
[AscensionVanity] ⚡ Phase changed! (Phase 2)
[AscensionVanity] 🏰 Entered: Deadmines - 3 vanity items available
[AscensionVanity] 🚪 Exited instance. Welcome back!
[AscensionVanity] 🎯 Rare spawn zone! Check for unlearned creatures.
```

**Advanced Features (Optional):**

**Rare Spawn Alerts:**
- Integration with rare spawn addons (RareScanner, etc.)
- Check if rare drops vanity items
- Announce when rare with vanity drops is nearby
- Map ping or waypoint (if coordinates available)

**Phase-Specific Tracking:**
- Record which phases have rare spawns
- Track kill attempts per phase
- Help players rotate through phases efficiently
- Export/import phase data between characters

**Implementation Considerations:**

**Phase Detection:**
- Ascension uses custom phase/layer system
- May need to detect via:
  - `PLAYER_DIFFICULTY_CHANGED` event
  - `PLAYER_ENTERING_WORLD` event
  - Chat message parsing for phase announcements
  - Custom Ascension API (if available)

**Instance Detection:**
- `PLAYER_ENTERING_WORLD` provides instance status
- `IsInInstance()` API function
- `GetInstanceInfo()` for instance details
- `ZONE_CHANGED_NEW_AREA` event

**Notification System:**
- Use `RaidNotice_AddMessage()` for center-screen alerts
- Or `UIErrorsFrame:AddMessage()` for subtle notifications
- Optional sound effects (configurable)
- Throttling to prevent spam (cooldown timers)

**Saved Variables:**
```lua
AscensionVanityDB.phaseTracking = {
    currentPhase = "Phase 2",
    phaseHistory = {
        ["Phase 1"] = {
            lastVisit = timestamp,
            raresFound = { [creatureID] = true },
            killsThisPhase = 12
        }
    },
    instanceHistory = {
        ["Deadmines"] = {
            runs = 5,
            drops = 2,
            lastRun = timestamp
        }
    }
}
```

**Files to Create/Modify:**
- `AscensionVanity/PhaseTracker.lua` - Phase/instance detection and notifications
- `Core.lua` - Register phase/instance events
- `AscensionVanityConfig.lua` - Add notification settings
- `SettingsUI.lua` - Add notification toggles

---

### 6. Pet Abilities & Stats Viewer 🐾
**Priority:** Medium-High  
**Complexity:** Medium  
**Version Target:** v2.1 or v2.2

**Description:**  
Display detailed information about combat pet abilities, stats, and characteristics when hovering over vanity items or viewing in the Vanity Wardrobe. Helps players make informed decisions about which pets to collect and use.

**Core Features:**

**Pet Information Display:**
- Show all pet abilities with levels (e.g., "Bite 2", "Growl 4")
- Display base stats (attack speed, armor, health, DPS)
- Show pet family and diet (if applicable)
- Display special abilities or unique traits
- Show attack type (Claw, Bite, Smack, etc.)

**Integration Points:**

**Option A: Enhanced Tooltip (Item Hover)**
```
[Beastmaster's Whistle: Duskbat]
Combat Pet

Pet Abilities:
  • Screech (Rank 1) - AOE attack reduction
  • Dive (Rank 2) - High damage attack

Pet Stats:
  Attack Speed: 1.0
  DPS: 45.2
  Armor: Medium
  Diet: Meat, Fish

Special: Can track hidden enemies
```

**Option B: Vanity Wardrobe Enhancement**
- Right-click pet in wardrobe → "View Pet Info"
- Dedicated panel showing full details
- Compare multiple pets side-by-side
- Filter pets by ability type

**Option C: In-Game Pet Preview**
- Button to "Preview Pet Abilities"
- Shows what the pet will look like and do
- Test abilities in a safe environment
- See ability animations

**Implementation Considerations:**

**Data Sources:**
- Pet ability data from game client API
- WoW creature database (family, diet, etc.)
- Ascension-specific pet modifications
- Community pet guides and databases

**API Functions:**
```lua
-- Get pet info from creature ID
local name, family, diet = GetCreatureInfo(creatureID)

-- Get pet abilities (if summoned)
local abilityID, abilityName, abilityIcon = GetPetActionInfo(slot)

-- Get pet stats
local healthPercent, attackSpeed = GetPetStats()
```

**Database Enhancement:**
```lua
AV_PetAbilities = {
    [1508] = {  -- Young Scavenger creature ID
        name = "Young Scavenger",
        family = "Carrion Bird",
        diet = {"Meat", "Fish"},
        attackSpeed = 2.0,
        attackType = "Claw",
        abilities = {
            {
                name = "Bite",
                rank = 1,
                level = 1,
                description = "Bite the enemy, causing damage"
            },
            {
                name = "Screech",
                rank = 1,
                level = 8,
                description = "Reduces enemy attack power"
            }
        },
        specialTraits = {
            "Can track hidden enemies"
        },
        armorType = "Medium",
        baseHealth = 450,
        baseDPS = 35.2
    }
}
```

**UI Mockup - Detailed View:**
```
┌────────────────────────────────────┐
│ Young Scavenger (Level 10 Pet)    │
├────────────────────────────────────┤
│ Family: Carrion Bird              │
│ Diet: Meat, Fish                   │
│ Attack Type: Claw                  │
│ Attack Speed: 2.0                  │
│                                    │
│ Base Stats:                        │
│ • Health: 450                      │
│ • DPS: 35.2                        │
│ • Armor: Medium                    │
│                                    │
│ Abilities:                         │
│ ┌──────────────────────────────┐  │
│ │ [Icon] Bite (Rank 1)         │  │
│ │ Level: 1                     │  │
│ │ Bites the enemy for damage   │  │
│ └──────────────────────────────┘  │
│ ┌──────────────────────────────┐  │
│ │ [Icon] Screech (Rank 1)      │  │
│ │ Level: 8                     │  │
│ │ Reduces enemy attack power   │  │
│ └──────────────────────────────┘  │
│                                    │
│ Special Traits:                    │
│ • Can track hidden enemies         │
│                                    │
│ [Compare] [Preview] [Close]        │
└────────────────────────────────────┘
```

**Advanced Features:**

**Pet Comparison Tool:**
- Select 2-4 pets to compare side-by-side
- Highlight differences in abilities and stats
- Show which pet is better for specific situations
- Export comparison as text for sharing

**Ability Progression:**
- Show how abilities improve with levels
- Display ability unlock levels
- Show training costs (if applicable)
- Suggest leveling priorities

**Build Recommendations:**
- Suggest best abilities for PvP vs PvE
- Recommend pet families for specific classes
- Show popular pet builds from community
- Link to detailed pet guides

**Data Collection Strategy:**

**Phase 1: Basic Data (Automated)**
- Extract pet family from creature type
- Get attack speed from creature template
- Pull base stats from database
- Map creature ID to pet abilities

**Phase 2: Ability Mapping (Semi-Automated)**
- Cross-reference with WoW pet ability database
- Verify against Ascension's pet system
- Map abilities to creature families
- Test in-game for accuracy

**Phase 3: Community Data (Manual)**
- Collect special traits from players
- Document Ascension-specific modifications
- Build ability progression tables
- Verify diet and training requirements

**Implementation Challenges:**

**Data Accuracy:**
- Ascension may have custom pet modifications
- Abilities might differ from retail WoW
- Need to verify all data in-game
- Community contributions for accuracy

**Performance:**
- Pet data can be large (2000+ creatures)
- Need efficient lookup tables
- Cache frequently accessed data
- Lazy-load detailed ability info

**UI Complexity:**
- Don't overwhelm users with information
- Progressive disclosure (basic → detailed)
- Consistent with WoW's pet UI style
- Responsive to different screen sizes

**Files to Create/Modify:**
- `AscensionVanity/PetAbilityDB.lua` - Pet ability and stats database
- `AscensionVanity/PetViewer.lua` - Pet information display module
- `AscensionVanity/PetViewerUI.lua` - Detailed pet info UI
- `AscensionVanity/PetComparison.lua` - Pet comparison tool
- `Core.lua` - Add pet info to tooltips (if enabled)
- `SettingsUI.lua` - Add toggles for pet info features
- `utilities/ExtractPetData.ps1` - Script to extract pet data from game/db

**Research Needed:**
- [ ] What pet API functions are available in WotLK?
- [ ] Does Ascension have custom pet ability modifications?
- [ ] Can we extract pet data from the game client directly?
- [ ] Are there existing pet databases we can reference?
- [ ] How do other pet addons (PetJournal Enhanced, etc.) get this data?
- [ ] Can we detect when a player summons a pet to learn abilities?
- [ ] What's the best way to display ability tooltips?

---

## Technical Considerations

### Performance
- All features should maintain <5ms query time for real-time updates
- Use indexed lookups (tables) instead of iterations
- Cache expensive operations (zone queries, price lookups)
- Lazy-load UIs (only create frames when needed)

### Compatibility
- Test with Auctioneer, Auctionator, TSM
- Graceful degradation if addons not present
- Don't break core functionality if features fail
- Support Ascension-specific APIs and quirks

### User Experience
- All features should be optional (toggle in settings)
- Default to OFF for new installations (opt-in)
- Clear documentation for each feature
- Intuitive UI design following WoW conventions

### Data Requirements
- Zone extraction from descriptions (automated)
- Creature type/subtype classification (semi-automated)
- Source classification (manual/automated hybrid)
- Price data integration (real-time from AH addons)

---

## Implementation Priority (Complexity-Based)

### 🟢 **TIER 1: Quick Wins** (1-2 days each)
*Minimal dependencies, straightforward implementation, immediate value*

#### **0. Category Filtering** 🔍
**Effort:** Very Low (1 day) | **Dependencies:** None | **UI:** Settings checkboxes only
- **Why Quickest:** Pure filtering logic, no database changes, no new events
- **Implementation:**
  - Pattern matching on item names (already in database)
  - Add 5 boolean flags to config
  - Filter in existing tooltip display loop
  - Add checkboxes to existing settings UI
- **Files:** Config update, tooltip filter logic, settings UI checkboxes
- **Testing:** Toggle each category, verify tooltips update
- **Value:** Immediate UX improvement for specialized collectors
- **Status:** 🚧 IN PROGRESS

#### **1. Phase & Instance Notifications** 🌍
**Effort:** Low | **Dependencies:** None | **UI:** Toast notifications only
- **Why Quick:** Uses existing WoW events, no database changes needed
- **Implementation:** 
  - Listen to `PLAYER_ENTERING_WORLD` event
  - Check `IsInInstance()` and `GetZoneText()`
  - Display toast notifications
  - Save phase/instance history to SavedVariables
- **Files:** 1 new module (`PhaseTracker.lua`), minor Core.lua changes
- **Testing:** Easy to verify by entering/exiting instances
- **Value:** High for Ascension players farming rare spawns

#### **2. Statistics & Kill Tracking** 📊
**Effort:** Low-Medium | **Dependencies:** None | **UI:** Tooltip text additions only
- **Why Quick:** Event-driven, no complex UI needed for basic version
- **Implementation:**
  - Listen to `COMBAT_LOG_EVENT_UNFILTERED` for kills
  - Track in SavedVariables: `stats.kills[creatureID] = count`
  - Add kill count to existing tooltips
  - Optional: Chat announcements on drops
- **Files:** 1 new module (`Statistics.lua`), tooltip additions in Core.lua
- **Testing:** Kill a few creatures and check tooltip updates
- **Value:** High engagement, players love seeing progress
- **Phased Approach:**
  - **v1 (Quick):** Kill counters only
  - **v2 (Later):** Drop rate calculations and luck indicators

---

### 🟡 **TIER 2: Moderate Effort** (3-5 days each)
*Some dependencies, moderate complexity, requires new UI or data work*

#### **3. Database Metadata Enrichment** 🔧
**Effort:** Medium | **Dependencies:** None | **UI:** None (backend only)
- **Why Medium:** Data processing, not coding complexity
- **Implementation:**
  - **Phase 1 (Automated):** Parse existing descriptions for zones
    - Regex patterns: `"within ([A-Z][a-z\s]+)"`, `"found in ([A-Z][a-z\s]+)"`
    - Extract zone names → create zone index
  - **Phase 2 (Semi-Automated):** Creature type classification
    - Map creature IDs to creature types using Ascension API
    - Manual review for edge cases
  - **Phase 3 (Manual):** Source categorization
    - World drops, boss drops, quest rewards
    - Requires manual research for ~200 items
- **Files:** Database structure changes, new utility scripts
- **Output:** Enhanced `VanityDB.lua` with metadata fields
- **Value:** Unlocks Regional Guide and Advanced Filtering
- **Note:** This is foundational - do early to unblock other features

#### **4. Auction House Integration** 💰
**Effort:** Medium | **Dependencies:** AH addon installed (external) | **UI:** Tooltip additions
- **Why Medium:** API integration complexity, multiple addons to support
- **Implementation:**
  - Detect which AH addon is loaded: `IsAddOnLoaded("Auctioneer")`, etc.
  - Query price APIs per addon:
    - Auctioneer: `AucAdvanced.API.GetMarketValue(itemID)`
    - Auctionator: `Atr_GetAuctionBuyout(itemID)`
    - TSM: `TSMAPI_FOUR.CustomPrice.GetItemPrice(itemID, "DBMarket")`
  - Cache prices (avoid repeated queries)
  - Display in tooltips: "Market Price: 500g (Auctioneer)"
- **Files:** 1 new module (`AHIntegration.lua`), tooltip additions
- **Testing:** Requires testing with each AH addon
- **Value:** Helps players decide farm vs buy
- **Graceful Degradation:** Works without AH addon (just doesn't show prices)

---

### 🟠 **TIER 3: Significant Work** (5-10 days each)
*Multiple dependencies, complex UI, or extensive data requirements*

#### **5. Advanced Filtering System** 🔍
**Effort:** Medium-High | **Dependencies:** Database Metadata Enrichment | **UI:** New filter panel
- **Why Complex:** Requires UI framework, depends on metadata enrichment
- **Implementation:**
  - **Backend:** Filter logic with indexed lookups
  - **Frontend:** Dropdown menus, checkboxes, filter state management
  - **Features:**
    - Filter by: Category, Type, Status, Zone, Source
    - Combine multiple filters (AND/OR logic)
    - Save filter preferences
  - **Performance:** Pre-index database for fast filtering
- **Files:** 2 new modules (`FilterUI.lua`, filter logic), database queries
- **Testing:** Requires comprehensive filter combination testing
- **Value:** Improves collection browsing dramatically
- **Dependencies:** Must complete Metadata Enrichment first (Tier 2 #3)

#### **6. Regional Hunting Guide** 🗺️
**Effort:** Medium-High | **Dependencies:** Database Metadata Enrichment | **UI:** New panel or minimap tooltip
- **Why Complex:** Zone detection, real-time updates, UI presentation
- **Implementation:**
  - **Backend:** Zone-based creature lookup using metadata
  - **Zone Index:** `AV_ZoneIndex["Duskwood"] = {creatureIDs}`
  - **Real-time:** Listen to `ZONE_CHANGED` events
  - **UI Options:**
    - **Simple:** Minimap tooltip with list
    - **Advanced:** Dedicated scrollable frame
  - **Filtering:** Show only unlearned items
- **Files:** 2 new modules (`RegionalGuide.lua`, `RegionalGuideUI.lua`)
- **Testing:** Travel to different zones, verify creature lists
- **Value:** High - helps players farm efficiently
- **Dependencies:** Requires zone metadata from Tier 2 #3

---

### 🔴 **TIER 4: Major Features** (10-20 days each)
*Extensive UI work, large data requirements, multiple integrations*

#### **7. Pet Abilities & Stats Viewer** 🐾
**Effort:** High | **Dependencies:** External pet data collection | **UI:** Complex multi-panel interface
- **Why Complex:** Large database creation, data accuracy verification, sophisticated UI
- **Implementation Phases:**
  - **Phase 1 (Research - 3 days):**
    - Research WotLK pet APIs: `GetPetActionInfo()`, `GetCreatureInfo()`
    - Test Ascension's pet system for custom modifications
    - Identify data sources (Petopia, WoWHead, manual testing)
  - **Phase 2 (Data Collection - 5-7 days):**
    - Build pet ability database (2000+ creatures)
    - Map creature IDs → families → abilities → stats
    - Verify in-game for accuracy (sample testing)
    - Community contributions for special traits
  - **Phase 3 (Basic UI - 3-4 days):**
    - Tooltip enhancements (show abilities)
    - Simple stats display
  - **Phase 4 (Advanced UI - 5-7 days):**
    - Detailed pet info viewer
    - Pet comparison tool (side-by-side)
    - Ability progression display
- **Files:** 4+ new modules, large database file (`PetAbilityDB.lua`)
- **Testing:** Extensive per-pet verification needed
- **Value:** Very high - unique feature, no other addon does this
- **Risk:** Data accuracy is challenging, Ascension customizations unknown

#### **8. Enhanced Collection Browser** 📚
**Effort:** Very High | **Dependencies:** ALL Tier 2-3 features | **UI:** Full-featured frame
- **Why Very Complex:** Combines all other features into one comprehensive UI
- **Implementation:**
  - **Filtering:** Integrates Tier 3 #5 (Advanced Filtering)
  - **Statistics Dashboard:** Integrates Tier 1 #2 (Kill Tracking)
  - **Regional Info:** Integrates Tier 3 #6 (Regional Guide)
  - **Pricing:** Integrates Tier 2 #4 (AH Integration)
  - **Pet Info:** Integrates Tier 4 #7 (Pet Abilities)
  - **UI Framework:** Tabs, scrolling, sorting, search
  - **Export/Import:** SavedVariables serialization
- **Files:** 5+ new modules, extensive UI code
- **Testing:** Every feature must be tested in combination
- **Value:** Ultimate collection management tool
- **Dependencies:** Cannot start until most other features are complete
- **Note:** This is the "capstone" feature - save for last

---

## Recommended Implementation Order

### **Sprint 1: Quick Wins** (Week 1)
0a. Category Filtering ✅ (1 day) - **IMPLEMENTED**
0b. Combat Tooltip Control ✅ (0.5 days) - **IMPLEMENTED**
1. Phase & Instance Notifications ⏭️ (2 days) - **NEXT**
2. Statistics & Kill Tracking (v1: counters only) ✅ (2 days)
3. **Deploy v2.1-alpha for testing**

### **Sprint 2: Foundation** (Week 2)
4. Database Metadata Enrichment ✅ (5 days)
   - Zone parsing
   - Type classification
   - Manual source categorization
5. **Deploy v2.1-beta with metadata**

### **Sprint 3: Integrations** (Week 3)
6. Auction House Integration ✅ (3 days)
7. Statistics & Kill Tracking (v2: drop rates) ✅ (2 days)
8. **Deploy v2.1-rc1**

### **Sprint 4: Advanced Features** (Weeks 4-5)
9. Advanced Filtering System ✅ (5-7 days)
10. Regional Hunting Guide ✅ (5-7 days)
11. **Deploy v2.2-beta**

### **Sprint 5: Major Features** (Weeks 6-8)
12. Pet Abilities & Stats Viewer ✅ (15-20 days)
    - Research: 3 days
    - Data collection: 7 days
    - Basic implementation: 4 days
    - Advanced features: 6 days
13. **Deploy v2.3-beta**

### **Sprint 6: Capstone** (Weeks 9-11)
14. Enhanced Collection Browser ✅ (20+ days)
    - Integration of all features
    - Comprehensive UI
    - Testing and polish
15. **Deploy v2.4 - Full Suite**

---

## Effort Summary

| Tier | Features | Total Effort | Parallelizable? |
|------|----------|--------------|-----------------|
| 🟢 Tier 1 | 2 features | 3-4 days | ✅ Yes |
| 🟡 Tier 2 | 2 features | 8-10 days | ⚠️ Partial |
| 🟠 Tier 3 | 2 features | 12-18 days | ❌ Sequential |
| 🔴 Tier 4 | 2 features | 30-40 days | ❌ Sequential |
| **TOTAL** | **8 features** | **53-72 days** | *~3 months solo dev* |

**Notes:**
- Tier 1 features can be developed in parallel (no dependencies)
- Tier 2 #3 (Metadata) should be done first to unblock Tier 3
- Tier 3 features depend on Tier 2 #3 completion
- Tier 4 #7 (Pet Abilities) is independent but data-intensive
- Tier 4 #8 (Collection Browser) is the final integration piece

**Recommendation:** Start with Tier 1 for immediate value, then Tier 2 #3 to unlock Tier 3 features. Save Tier 4 for last when all dependencies are ready.

---

## Questions to Research

### Auction House Integration
- [ ] What are the exact API functions for Auctioneer?
- [ ] What are the exact API functions for Auctionator?
- [ ] Do these addons provide server-wide pricing or personal scan data?
- [ ] How frequently should we query prices? (cache invalidation)
- [ ] Can we detect when AH addons update their data?

### Regional Guide
- [ ] Can we detect subzones accurately? (e.g., "Raven Hill" in Duskwood)
- [ ] Are there existing coordinate databases we can use?
- [ ] Can we integrate with TomTom or HandyNotes for waypoints?
- [ ] How to handle creatures with multiple spawn locations?

### Advanced Filtering
- [ ] How to classify creature subtypes? (automated or manual?)
- [ ] Are there creature family APIs in Ascension?
- [ ] How to detect quest rewards vs drops automatically?
- [ ] Can we parse item source from db.ascension.gg?

### Statistics & Kill Tracking
- [ ] Does `COMBAT_LOG_EVENT_UNFILTERED` work reliably on Ascension?
- [ ] What's the best event for detecting player kills vs party kills?
- [ ] How to match loot events to specific creatures?
- [ ] Can we detect when items are learned automatically from bags?
- [ ] What's the storage limit for saved variables? (kill data can grow large)

### Phase & Instance Notifications
- [ ] Does Ascension expose phase/layer information via API?
- [ ] What events fire on phase changes?
- [ ] Can we parse phase IDs from chat messages?
- [ ] Is there integration with RareScanner or SilverDragon addons?
- [ ] How to detect rare spawns specific to Ascension's system?

### Pet Abilities & Stats Viewer
- [ ] What pet API functions are available in WotLK? (`GetPetActionInfo`, etc.)
- [ ] Does Ascension have custom pet ability modifications vs retail?
- [ ] Can we extract pet data from the game client directly?
- [ ] Are there existing pet databases we can reference? (Petopia, etc.)
- [ ] How do other pet addons get ability data? (PetJournal Enhanced, etc.)
- [ ] Can we detect when a player summons a pet to learn abilities dynamically?
- [ ] What's the format for storing pet ability tooltips?
- [ ] Can we access creature spell data from the game database?
- [ ] How to map creature IDs to pet families and stats?
- [ ] Does Ascension's API provide pet DPS/attack speed calculations?

---

## User Feedback

**Requested Features from Community:**
- (Placeholder for future community requests)

**Known Pain Points:**
- Hard to find specific unlearned items
- No way to compare AH prices before farming
- Difficult to know what to hunt in current zone

---

## Success Metrics

**For v2.1:**
- Regional Guide used by 50%+ of users
- Filter system reduces collection time by 20%
- No performance degradation in tooltips

**For v2.2:**
- AH integration improves farming decisions
- User retention increases
- Positive community feedback

---

## Notes

- All features should align with core philosophy: **Help players collect vanity items efficiently**
- Prioritize features that provide immediate, measurable value
- Don't over-engineer - start simple and iterate based on feedback
- Document everything for future maintainers

---

**Last Updated:** October 30, 2025  
**Next Review:** Before starting v2.1 development
