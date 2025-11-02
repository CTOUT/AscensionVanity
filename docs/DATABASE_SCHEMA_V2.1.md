# Database Schema v2.1 - Enhanced Data Model

## Overview

Version 2.1 introduces an enhanced database schema that separates visual models from drop sources and adds location data. This enables future features like regional hunting guides and creature preview UI.

## Schema Changes

### Previous Schema (v2.0)

```lua
[79429] = {
    itemid = 79429,
    name = "Beastmaster's Whistle: Large Crag Boar",
    creaturePreview = 1126,  -- Mixed purpose: visual model AND drop source
    description = "Has a chance to drop from Large Crag Boar within Dun Morogh",
    icon = 1
}
```

### New Schema (v2.1)

```lua
[79429] = {
    itemid = 79429,
    name = "Beastmaster's Whistle: Large Crag Boar",
    creaturePreview = 1126,  -- Visual model (immutable from API)
    creatureId = 1126,       -- Drop source (corrected if needed)
    description = "Has a chance to drop from Large Crag Boar within Dun Morogh",
    zone = "Dun Morogh",     -- Primary zone
    subzone = nil,           -- Specific location (optional)
    icon = 1
}
```

## Field Definitions

### `itemid` (number, required)
Game item ID from Ascension API.

### `name` (string, required)
Full item name including prefix (e.g., "Beastmaster's Whistle: Large Crag Boar").

### `creaturePreview` (number, required)
Creature ID for visual model/preview. This is the **immutable** value from the game API representing what the pet looks like when summoned.

**Purpose:** Used for future creature preview UI features.

**Important:** Never modify this field - it represents the original API data.

### `creatureId` (number, required)
Creature ID of the NPC that drops this item. Can differ from `creaturePreview` when:
- Multiple NPCs drop the same visual model
- API returns incorrect/inflated IDs (98xxx, 400xxxx patterns)
- Item previews a specific color variant but drops from generic NPC

**Purpose:** Used for tooltip lookups and drop information.

**Defaults to:** `creaturePreview` if not explicitly set.

### `description` (string, required)
Full description text. In v2.1, this is kept for compatibility. Future versions may use templates.

### `zone` (string, optional)
Primary zone/region where the item drops.

**Examples:**
- "Elwynn Forest"
- "Durotar"
- "Un'Goro Crater"
- "Molten Core"

**Extraction:** Parsed from description pattern "within [zone]".

### `subzone` (string, optional)
Specific location within the zone.

**Examples:**
- "Golakka Hot Springs" (within Un'Goro Crater)
- "Fire Plume Ridge" (within Un'Goro Crater)

**When used:** Description mentions a specific area instead of just the zone.

**Note:** If description only mentions zone, `subzone` is `nil`.

### `icon` (number, required)
Index into `AV_IconList` array for the item's icon texture.

## Data Flow

### 1. API Scan → Initial Data
```
Game API → AscensionVanity.lua (SavedVariables)
```
Captures raw data including `creaturePreview`.

### 2. Conversion → JSON
```
AscensionVanity.lua → ConvertScanToMasterJson.ps1 → MasterFullValidated.json
```
- Sets `creatureId = creaturePreview` (default)
- Applies corrections from `CreatureIdCorrections.json`
- Parses `zone` and `subzone` from descriptions

### 3. Generation → Lua Database
```
MasterFullValidated.json → GenerateVanityDB_Master.ps1 → VanityDB.lua
```
Outputs final Lua table with all fields.

### 4. Loading → In-Game
```
VanityDB.lua → VanityDB_Loader.lua → Core.lua
```
- Loads into `AV_VanityItems` table
- Core.lua uses `creatureId` for NPC lookups
- `creaturePreview` reserved for future preview features

## Creature ID Corrections

### How Corrections Work

Corrections are stored in `data/corrections/CreatureIdCorrections.json`:

```json
{
  "corrections": [
    {
      "itemId": 79429,
      "itemName": "Beastmaster's Whistle: Large Crag Boar",
      "wrongCreatureId": 98768,
      "correctCreatureId": 1126,
      "reason": "98xxx range outlier",
      "verifiedBy": "https://db.ascension.gg/?item=79429",
      "dateAdded": "2025-11-02"
    }
  ]
}
```

During conversion:
1. Load scan data (sets `creatureId = creaturePreview`)
2. Apply corrections (updates `creatureId` only)
3. Result: `creaturePreview` unchanged, `creatureId` corrected

### Why Separate Fields?

**Example: Whip Lasher Variants**

```lua
[601201] = {
    name = "Elemental Lodestone: Whip Lasher(Purple)",
    creaturePreview = 40553,  -- Purple model variant
    creatureId = 11464,       -- Generic Whip Lasher NPC
    zone = "Dire Maul"
}
```

The item summons a **purple visual model** (40553) but drops from **generic Whip Lasher** NPCs (11464).

Without separation:
- ❌ Lose visual model info when correcting drop source
- ❌ Can't implement creature preview feature
- ❌ Conflate two different concepts

With separation:
- ✅ Preserve visual model (40553)
- ✅ Track correct drop source (11464)
- ✅ Enable future preview UI
- ✅ Clean architecture

## Zone Extraction

### Standard Pattern

```
"Has a chance to drop from [NPC] within [Zone]"
```

**Result:**
- `zone = "Zone"`
- `subzone = nil`

### Subzone Pattern

```
"Has a chance to drop from [NPC] within [Subzone]"
```

Where Subzone is a known area within a larger zone.

**Result:**
- `zone = "Parent Zone"` (via mapping)
- `subzone = "Subzone"`

### Custom Descriptions

Items with non-standard descriptions:
- Manually set `zone` in `ManualResearch.json`
- Or left as `nil` if zone is unclear

## Usage Examples

### Core.lua - Tooltip Lookup

```lua
-- Use creatureId for NPC matching
local function AddVanityInfoToTooltip(tooltip, unit)
    local creatureID = ExtractCreatureID(unit)
    local items = AV_GetVanityItemsForCreature(creatureID)
    -- items now based on correct drop source
end
```

### Future: Regional Guide

```lua
-- Find items in player's current zone
function AV_GetItemsInCurrentZone()
    local currentZone = GetZoneText()
    local items = {}
    
    for itemId, data in pairs(AV_VanityItems) do
        if data.zone == currentZone then
            table.insert(items, data)
        end
    end
    
    return items
end
```

### Future: Creature Preview

```lua
-- Show 3D model using creaturePreview
function AV_ShowCreaturePreview(itemId)
    local item = AV_VanityItems[itemId]
    if item and item.creaturePreview then
        ShowCreatureModel(item.creaturePreview)
    end
end
```

## Migration Notes

### From v2.0 to v2.1

**Backward Compatible:** Yes

Existing code using `creaturePreview` will continue working because:
1. `creatureId` defaults to `creaturePreview` for unchanged items
2. Corrections applied automatically during regeneration
3. No breaking changes to existing functions

**Database File Size:** Increases by ~20% due to additional fields (500KB → 600KB estimated).

**Future Optimization:** v2.2 will introduce description templates to reduce size by 50%.

## Testing Checklist

- [ ] All items have `creatureId` field
- [ ] `creatureId` defaults to `creaturePreview` when no correction
- [ ] Corrections properly applied to `creatureId` only
- [ ] Zone extracted for 95%+ of items
- [ ] Subzone set for items with specific locations
- [ ] Core.lua uses `creatureId` for lookups
- [ ] Tooltips display correct information
- [ ] No regression in existing functionality

## Future Enhancements (v2.2+)

### Description Templates
Reduce file size by 50% using indexed templates:
```lua
descTemplate = 1,  -- "Has a chance to drop from %s within %s"
```

### Zone Index
Further reduce size by indexing zone names:
```lua
zone = 15,  -- References AV_Zones[15] = "Un'Goro Crater"
```

### Coordinates
Add approximate coordinates for map integration:
```lua
coords = {x = 45.2, y = 67.8}
```

### Drop Rates
Track empirical drop rates (requires kill tracking):
```lua
dropRate = 0.025,  -- 2.5% based on player data
```

## Related Files

- `VanityDB.lua` - Final database output
- `MasterFullValidated.json` - Intermediate JSON format
- `ConvertScanToMasterJson.ps1` - Conversion with zone extraction
- `GenerateVanityDB_Master.ps1` - Lua generation
- `CreatureIdCorrections.json` - Creature ID corrections
- `Core.lua` - Uses `creatureId` for lookups
- `VanityDB_Loader.lua` - Database initialization

## Version History

- **v2.1** (2025-11-02): Initial implementation of enhanced schema
  - Added `creatureId`, `zone`, `subzone` fields
  - Separated visual model from drop source
  - Zone extraction from descriptions
  
- **v2.0** (2025-10-31): Original schema
  - Single `creaturePreview` field for both purposes
  - Description-only location data
