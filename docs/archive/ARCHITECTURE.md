# AscensionVanity - Architecture Documentation

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     ASCENSIONVANITY ADDON                   │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
         ┌──────▼──────┐            ┌──────▼──────┐
         │ VanityData  │            │    Core     │
         │    .lua     │            │    .lua     │
         └──────┬──────┘            └──────┬──────┘
                │                           │
    ┌───────────┴───────────┐      ┌────────┴────────┐
    │                       │      │                 │
┌───▼────┐         ┌────────▼──┐   │   ┌──────────┐  │
│Specific│         │  Generic  │   │   │ Tooltip  │  │
│Creature│         │   Drops   │   │   │  Hooks   │  │
│Mapping │         │  by Type  │   │   └────┬─────┘  │
└────────┘         └───────────┘   │        │        │
                                   │   ┌────▼─────┐  │
                                   │   │Detection │  │
                                   │   │  Logic   │  │
                                   │   └────┬─────┘  │
                                   │        │        │
                                   │   ┌────▼─────┐  │
                                   │   │ Display  │  │
                                   │   │  Engine  │  │
                                   │   └──────────┘  │
                                   └─────────────────┘
```

## Component Details

### 1. VanityData.lua - Database Layer

**Purpose**: Storage of all vanity item mappings

**Data Structures**:

```lua
AV_VanityItems = {
    -- Specific creature → item mapping
    ["CreatureName"] = {
        itemID = number,
        itemName = string,
        type = string
    }
}

AV_GenericDropsByType = {
    -- Type → list of items mapping
    ["CreatureType"] = {
        "Item Name 1",
        "Item Name 2",
        ...
    }
}
```

**Key Function**:
- `AV_GetVanityItemsForCreature(name, type)` - Retrieves items for a creature

---

### 2. Core.lua - Logic Layer

**Purpose**: Main addon logic and WoW API integration

**Components**:

#### A. Configuration Management
```lua
AscensionVanityDB = {
    enabled = boolean,
    showLearnedStatus = boolean,
    colorCode = boolean
}
```

#### B. Tooltip Hooking System
```lua
GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
```

#### C. Detection Logic
- Extract creature name via `UnitName(unit)`
- Extract creature type from tooltip text
- Match against database

#### D. Display Engine
- Format vanity item information
- Apply color coding
- Add learned status indicators
- Inject into tooltip

#### E. Command Interface
- Slash commands (`/av`, `/ascensionvanity`)
- Configuration toggles
- Help system

---

## Data Flow Diagram

```
Player Action (Mouse Over Creature)
              │
              ▼
┌─────────────────────────┐
│   WoW Event System      │
│  OnTooltipSetUnit       │
└─────────────┬───────────┘
              │
              ▼
┌─────────────────────────┐
│   Get Unit Info         │
│  - UnitName(unit)       │
│  - UnitGUID(unit)       │
│  - UnitExists(unit)     │
└─────────────┬───────────┘
              │
              ▼
┌─────────────────────────┐
│  Extract Creature Type  │
│  (Scan tooltip lines)   │
└─────────────┬───────────┘
              │
              ▼
┌─────────────────────────┐
│  Query Database         │
│  AV_GetVanityItems...   │
└─────────────┬───────────┘
              │
         ┌────┴────┐
         │         │
         ▼         ▼
┌────────────┐  ┌─────────────┐
│  Specific  │  │   Generic   │
│  Creature  │  │  Type-Based │
│   Match    │  │    Match    │
└─────┬──────┘  └──────┬──────┘
      │                │
      └────────┬───────┘
               │
               ▼
     ┌──────────────────┐
     │  Format Results  │
     │  - Apply colors  │
     │  - Check learned │
     │  - Add symbols   │
     └────────┬─────────┘
              │
              ▼
     ┌──────────────────┐
     │  Add to Tooltip  │
     │  GameTooltip:    │
     │    AddLine()     │
     └────────┬─────────┘
              │
              ▼
     ┌──────────────────┐
     │  Display Updated │
     │     Tooltip      │
     └──────────────────┘
```

---

## Tooltip Display Format

```
┌────────────────────────────────────────┐
│  [Creature Portrait]  Creature Name    │
│  Level 70 Terrorfiend                  │
│  <Normal tooltip content...>           │
│                                        │
│  Vanity Items:                         │ ← COLOR_VANITY_HEADER
│  ✓ Summoner's Stone: Terrormaster     │ ← COLOR_VANITY_LEARNED
│  ✗ Summoner's Stone: Unleashed Hellion│ ← COLOR_VANITY_UNLEARNED
│    Summoner's Stone: Zarcsin          │ ← Unknown status
└────────────────────────────────────────┘
```

**Legend**:
- `✓` = Player has learned this item (Green)
- `✗` = Player has not learned this item (Yellow)
- ` ` (space) = Unknown status (White)

---

## Event Flow & Lifecycle

### 1. Addon Loading
```
ADDON_LOADED (AscensionVanity)
    │
    ├─→ Load saved variables (AscensionVanityDB)
    ├─→ Initialize data structures
    ├─→ Print welcome message
    └─→ Wait for PLAYER_LOGIN
```

### 2. Player Login
```
PLAYER_LOGIN
    │
    └─→ Hook GameTooltip events
        └─→ GameTooltip:HookScript("OnTooltipSetUnit", ...)
```

### 3. Runtime Operation
```
Player mouses over creature
    │
    ├─→ OnTooltipSetUnit triggered
    │     │
    │     ├─→ Check if addon enabled
    │     ├─→ Extract unit information
    │     ├─→ Query vanity database
    │     ├─→ Format and display results
    │     └─→ Update tooltip
    │
    └─→ Player sees enhanced tooltip
```

### 4. Configuration Changes
```
Player types /av command
    │
    ├─→ Parse command
    ├─→ Update AscensionVanityDB
    ├─→ Print confirmation
    └─→ Effect applies to next tooltip
```

---

## Database Lookup Algorithm

```lua
function AV_GetVanityItemsForCreature(creatureName, creatureType)
    local results = {}
    
    -- Step 1: Check specific creature mapping
    if AV_VanityItems[creatureName] then
        table.insert(results, AV_VanityItems[creatureName])
    end
    
    -- Step 2: Check generic type-based drops
    if creatureType and AV_GenericDropsByType[creatureType] then
        for _, itemName in ipairs(AV_GenericDropsByType[creatureType]) do
            table.insert(results, {
                itemID = nil,
                itemName = itemName,
                type = creatureType
            })
        end
    end
    
    return results
end
```

**Complexity**: O(1) for specific lookup + O(n) for type-based lookup
- **Specific lookup**: Hash table lookup = O(1)
- **Type-based lookup**: Linear scan of type's item list = O(n)
- **n** = Number of items for that creature type (typically 1-10)

---

## Color Coding System

```lua
-- Header text (teal/cyan)
COLOR_VANITY_HEADER = "|cFF00FF96"

-- Learned item (green)
COLOR_VANITY_LEARNED = "|cFF00FF00"

-- Not learned item (yellow)
COLOR_VANITY_UNLEARNED = "|cFFFFFF00"

-- Reset to default
COLOR_RESET = "|r"
```

**Format**: `|cFFRRGGBB` where:
- `FF` = Alpha channel (fully opaque)
- `RR` = Red component (00-FF)
- `GG` = Green component (00-FF)
- `BB` = Blue component (00-FF)

---

## Configuration System

### Saved Variables Structure
```lua
AscensionVanityDB = {
    enabled = true,           -- Master on/off switch
    showLearnedStatus = true, -- Show ✓/✗ indicators
    colorCode = true,         -- Use color coding
}
```

### Persistence
- Saved to: `WTF/Account/[AccountName]/SavedVariables/AscensionVanity.lua`
- Auto-loaded on addon initialization
- Auto-saved on UI reload or logout

---

## Performance Considerations

### Optimization Strategies

1. **Lazy Evaluation**:
   - Only process tooltips when actually displayed
   - Skip processing if addon is disabled

2. **Efficient Lookups**:
   - Hash tables for O(1) creature name lookups
   - Pre-indexed data structures

3. **Minimal Tooltip Updates**:
   - Only add lines if vanity items found
   - Single tooltip:Show() call after all updates

4. **Cached Results** (Future Enhancement):
   ```lua
   local cache = {}
   if cache[creatureName] then
       return cache[creatureName]
   end
   -- ... perform lookup ...
   cache[creatureName] = results
   ```

### Performance Metrics

**Estimated Impact**:
- **Tooltip Hook Overhead**: ~0.1-0.5ms per tooltip display
- **Database Lookup**: O(1) + O(n), typically <1ms
- **Tooltip Rendering**: Negligible (native WoW function)
- **Memory Footprint**: ~50KB for 50 items, ~500KB estimated for 2471 items

---

## Error Handling

### Defensive Coding Patterns

```lua
-- Always check if unit exists
if not unit or not UnitExists(unit) then
    return
end

-- Verify tooltip lines exist
local line = _G["GameTooltipTextLeft" .. i]
if line then
    local text = line:GetText()
    if text then
        -- Safe to process
    end
end

-- Handle missing data gracefully
local items = AV_GetVanityItemsForCreature(name, type)
if items and #items > 0 then
    -- Display items
end
```

### Common Error Cases

1. **Unit doesn't exist**: Check `UnitExists(unit)`
2. **Tooltip lines missing**: Verify `_G["GameTooltipTextLeft" .. i]` exists
3. **Missing database entry**: Return empty table, don't error
4. **Invalid creature type**: Ignore, check only specific creature names

---

## Extension Points

### Future Enhancement Hooks

1. **Custom Item Filters**:
   ```lua
   AV_ItemFilter = function(item)
       -- Return true to display, false to hide
       return not IsVanityItemLearned(item.itemID, item.itemName)
   end
   ```

2. **Custom Formatters**:
   ```lua
   AV_FormatItem = function(item, isLearned)
       -- Custom formatting logic
       return formattedString
   end
   ```

3. **Event Callbacks**:
   ```lua
   AV_OnItemDisplayed = function(creatureName, items)
       -- Custom behavior when items are displayed
   end
   ```

---

## Testing Strategy

### Unit Testing Checklist

1. **Database Queries**:
   ```lua
   /run AV_Debug("Zarcsin", "Terrorfiend")
   /run AV_Debug("NonExistent", nil)
   ```

2. **Tooltip Display**:
   - Mouse over known creatures
   - Verify items appear
   - Check color coding
   - Verify learned status icons

3. **Configuration**:
   ```lua
   /av toggle
   /av learned
   /av color
   /dump AscensionVanityDB
   ```

4. **Edge Cases**:
   - Creatures with no vanity items
   - Creatures with multiple items
   - Generic drops (type-only matching)
   - Long item names (text wrapping)

---

## Deployment Checklist

- [ ] All files present (.toc, Core.lua, VanityData.lua, README.md)
- [ ] Database populated with all 2471 items
- [ ] Item IDs added where available
- [ ] Learned status function implemented
- [ ] In-game testing completed
- [ ] Performance validated (no lag)
- [ ] Error handling verified
- [ ] Slash commands tested
- [ ] Settings persistence verified
- [ ] Documentation reviewed

---

**Architecture Version**: 1.0
**Last Updated**: 2025
**Status**: Initial Implementation
