# World of Warcraft API Resources

**Date:** November 3, 2025  
**Purpose:** Reference documentation for WoW addon development

---

## Official & Community Documentation

### Classic/WOTLK API Documentation

**Primary Resources:**
1. **Warcraft Wiki (Modern)** - https://warcraft.wiki.gg/wiki/World_of_Warcraft_API/Classic
   - Comprehensive Classic/WOTLK API documentation
   - Active community maintenance
   - Includes Classic, TBC, and WOTLK APIs
   - **Best for:** Current Classic development

2. **Vanilla WoW Archive (Legacy)** - https://vanilla-wow-archive.fandom.com/wiki/World_of_Warcraft_API
   - Original Vanilla (1.12) API documentation
   - Historical reference
   - Pre-WOTLK functions and behavior
   - **Best for:** Understanding API evolution

### Project Ascension Specific

**Custom APIs:**
- `C_VanityCollection` - Ascension's custom vanity collection system
  - `.GetAllItems()` - Get all vanity items
  - `.IsCollectionItemOwned(itemId)` - Check if item is learned
  - Custom events: `ASCENSION_STORE_COLLECTION_ITEM_LEARNED`

**Resources:**
- db.ascension.gg - Item/creature database
- Ascension Discord - Community support and API discussions

---

## VS Code Extensions for WoW Development

### Installed Extensions

1. **Lua Language Server** (`sumneko.lua`)
   - IntelliSense and type checking for Lua 5.1
   - Configuration: `.vscode/settings.json`

2. **WoW API Annotations** (`ketho.wow-api`)
   - WOTLK 3.3.5 API definitions
   - FrameXML annotations
   - Auto-completion for WoW functions
   - Configuration: `wowAPI.luals.*` settings

3. **WoW Bundle** (`septh.wow-bundle`)
   - TOC file syntax support
   - Additional WoW development utilities

4. **TOC File Support** (`stanzilla.vscode-wow-toc`)
   - Syntax highlighting for `.toc` files

### Configuration

See `.vscode/settings.json` for workspace-specific Lua configuration:
- Lua 5.1 runtime
- WoW API library paths
- Custom globals definitions
- Diagnostic settings

---

## Common WoW API Functions (WOTLK 3.3.5)

### Unit Functions
```lua
UnitName(unit)              -- Get unit name
UnitGUID(unit)              -- Get unit GUID
UnitClass(unit)             -- Get unit class
UnitLevel(unit)             -- Get unit level
UnitHealth(unit)            -- Get current health
UnitHealthMax(unit)         -- Get max health
UnitIsPlayer(unit)          -- Check if player
UnitExists(unit)            -- Check if unit exists
UnitAffectingCombat(unit)   -- Check combat status
```

### Item Functions
```lua
GetItemInfo(itemId)         -- Get item details (name, link, quality, etc.)
GetItemIcon(itemId)         -- Get item icon texture path
GetItemSpell(itemId)        -- Get item spell info
```

### UI Functions
```lua
CreateFrame(type, name, parent, template)  -- Create UI frame
GameTooltip:SetUnit(unit)                  -- Set tooltip to unit
GameTooltip:AddLine(text, r, g, b)         -- Add line to tooltip
GameTooltip:Show()                         -- Display tooltip
GameTooltip:Hide()                         -- Hide tooltip
```

### Zone/Location Functions
```lua
GetZoneText()               -- Get current zone name
GetSubZoneText()            -- Get current subzone name
GetMinimapZoneText()        -- Get minimap zone text
```

### Quest Functions
```lua
-- Classic/WOTLK variants:
IsQuestComplete(questId)                          -- Check if quest is complete (Classic)
C_QuestLog.IsQuestFlaggedCompleted(questId)       -- Check if quest is complete (Retail backport)
GetQuestLogTitle(questIndex)                      -- Get quest log entry
IsQuestInLog(questId)                             -- Check if quest is in log (custom function)
```

### Time Functions
```lua
time()                      -- Get current timestamp (seconds since epoch)
date(format, time)          -- Format timestamp
GetTime()                   -- Get time since client start (high precision)
GetBuildInfo()              -- Get client version info
```

### System Functions
```lua
print(msg)                  -- Print to chat
wipe(table)                 -- Clear table contents
GetAddOnMetadata(name, key) -- Get TOC file metadata
```

---

## Custom Functions (AscensionVanity)

### Global Functions (Defined in addon)

**Database Access:**
```lua
AV_GetVanityItemsForCreature(creatureId)  -- Get items for creature
AV_GetItemData(itemId)                    -- Get item details
AV_GetItemName(itemId)                    -- Get item name
AV_GetItemCreature(itemId)                -- Get creature for item
AV_GetItemRegion(itemId)                  -- Get item region/location
AV_GetTotalItems()                        -- Get total item count
AV_GetDatabaseStats()                     -- Get database statistics
```

**Scanner Functions:**
```lua
AV_ScanAllItems()           -- Scan all vanity items via API
AV_ClearDumpData()          -- Clear scan data
```

**UI Functions:**
```lua
AscensionVanity_ShowSettings()            -- Open settings UI
AscensionVanity_HideSettings()            -- Close settings UI
AscensionVanity_ToggleSettings()          -- Toggle settings UI
AscensionVanity_SyncSettingsUI()          -- Sync UI with config

AscensionVanity_ShowScanner()             -- Open scanner UI
AscensionVanity_HideScanner()             -- Close scanner UI
AscensionVanity_ToggleScanner()           -- Toggle scanner UI

AscensionVanity_InitRegionalGuide()       -- Initialize regional guide
AscensionVanity_GetCurrentZoneItems()     -- Get items in current zone
AscensionVanity_ShowCurrentZoneItems()    -- Display zone items
```

---

## Best Practices

### Performance
- Cache global function lookups as locals
- Avoid table creation in hot paths (OnUpdate, etc.)
- Use `wipe()` instead of creating new tables
- Minimize event registrations
- Throttle OnUpdate handlers

### Code Style
- Local by default (global only when needed)
- PascalCase for globals with `AV_` prefix
- camelCase for local variables
- UPPER_SNAKE_CASE for constants
- Descriptive variable names (no single letters)

### Error Handling
- Validate all input parameters
- Check for nil values explicitly
- Use `pcall()` for risky operations
- Provide user-friendly error messages

---

## Additional Resources

**Community:**
- WoW Addon Discord servers
- Project Ascension Discord
- GitHub repositories for open-source addons

**Tools:**
- WoW AddOn Studio (legacy, not required with VS Code)
- BugGrabber + BugSack (in-game error tracking)
- `/framestack` - Debug UI overlaps
- `/console scriptErrors 1` - Enable error display

---

**Last Updated:** November 3, 2025
