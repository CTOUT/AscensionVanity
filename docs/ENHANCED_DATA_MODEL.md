# Enhanced Data Model - Expanded Field Extraction

## Overview
This document outlines the enhanced data model that stores additional fields from the API's `rawData` section to enable advanced features like item filtering, visual improvements, and 3D model previews.

## Data Model Evolution

### Current Model (V1)
```lua
{
    itemID = 12345,
    name = "Item Name",
    creatureID = 67890,
    sourcemore = "1.1" -- Category code
}
```

### Enhanced Model (V2)
```lua
{
    itemID = 12345,              -- Primary key for item identification
    name = "Item Name",          -- Item display name
    creatureID = 67890,          -- Creature/mount ID for spawning
    sourcemore = "1.1",          -- Category code for organization
    description = "...",         -- Item description text
    icon = "inv_mount_...",      -- Icon texture path
    creaturePreview = 12345      -- Optional: 3D model preview ID
}
```

## Field Specifications

### 1. itemID (number)
**Purpose**: Primary key for unique item identification
**Source**: `rawData.id`
**Usage**: 
- Database lookups
- Item matching and validation
- Cross-referencing with in-game APIs

**Example**: `47` (Winterspring Frostsaber)

---

### 2. name (string)
**Purpose**: Display name for tooltips and UI
**Source**: `rawData.name`
**Usage**:
- Tooltip display
- Search functionality
- User-facing item identification

**Example**: `"Reins of the Winterspring Frostsaber"`

---

### 3. creatureID (number)
**Purpose**: Creature/mount ID for spawning and preview
**Source**: `rawData.creaturePreview`
**Usage**:
- Mount spawning via `/way` command
- Reverse lookups (creature → item)
- 3D model preview in inventory tooltips

**Example**: `11021` (Winterspring Frostsaber mount)

---

### 4. sourcemore (string)
**Purpose**: Category classification code
**Source**: `rawData.sourcemore`
**Usage**:
- Item categorization (1.1 = Rare Drop, 2.5 = PvP Reward, etc.)
- Filtering and organization
- Source-based queries

**Example**: `"1.1"` (Rare Drop category)

**Category Reference**:
- `1.x` = Drop-based sources
- `2.x` = Achievement/PvP sources
- `3.x` = Vendor sources
- `4.x` = Profession sources
- `5.x` = Quest/Event sources

---

### 5. description (string) ⭐ NEW
**Purpose**: Full item description for filtering and context
**Source**: `rawData.description`

**Usage**:
- **Drop Filtering**: Identify "dropped" vs other acquisition methods
- **Region Extraction**: Parse location names from description text
- **Context Display**: Show full item details in extended tooltips
- **Quality Indicators**: Identify special items by description keywords

**Examples**:
```
"Dropped by: Lord Kazzak in Tainted Scar, Blasted Lands"
"This mount is a rare drop from Attumen the Huntsman in Karazhan"
"Reward from: The Keystone Master achievement"
```

**Filtering Patterns**:
- Contains "Dropped by:" → `isDrop = true`
- Contains location name → extract region
- Contains "Reward from:" → achievement/quest source
- Contains "Purchased from:" → vendor source

---

### 6. icon (string) ⭐ NEW
**Purpose**: Texture path for visual item representation
**Source**: `rawData.icon`

**Usage**:
- **In-Game Icons**: Display actual item icon in tooltips
- **Visual Search**: Browse items by icon similarity
- **Texture Indexing**: Reduce character count via icon ID lookup (optional optimization)
- **UI Enhancement**: Replace category-based icons with actual item icons

**Format**: `"Interface/Icons/inv_mount_tiger_white"`

**Icon Storage Analysis** (from 3,038 items analyzed):
- **Total unique icons**: 68
- **Most categories use single icon** (Beastmaster's Whistle: 809 items, 1 icon)
- **Recommendation**: Store icon per-item (no indexing needed)
- **Memory overhead**: Negligible (~68 unique strings)

**Common Icon Patterns**:
- Mounts: `inv_mount_*`, `ability_mount_*`
- Pets: `inv_pet_*`, `ability_hunter_pet_*`
- Tabards: `inv_shirt_*`
- Toys: `inv_misc_*`, `inv_toy_*`

---

### 7. creaturePreview (number) ⭐ NEW
**Purpose**: 3D model ID for in-game preview
**Source**: `rawData.creaturePreview`

**Usage**:
- **Reverse Lookups**: Map creature → item (find item from creature ID)
- **3D Model Preview**: Show model when hovering over inventory item
- **Visual Validation**: Verify correct mount/pet appearance
- **Database Relationships**: Link items to creature database

**Examples**:
- `11021` → Winterspring Frostsaber (white tiger)
- `30542` → Deathcharger (undead horse)
- `11327` → Zergling (StarCraft pet)

**API Integration**:
```lua
-- In-game tooltip enhancement:
GameTooltip:SetHyperlink("item:" .. itemID)
-- Add model viewer:
ModelPreview:SetCreature(creaturePreview)
```

**Reverse Lookup Example**:
```lua
-- Find all items that spawn a specific creature
function FindItemsByCreature(creatureID)
    for itemID, data in pairs(AscensionVanityDB) do
        if data.creaturePreview == creatureID then
            print("Item:", data.name, "spawns", creatureID)
        end
    end
end
```

---

## Storage Impact Analysis

### Size Comparison

**Current Model (V1)**:
```lua
{
    itemID = 47,                    -- 4 bytes
    name = "Reins of the...",       -- ~40 bytes
    creatureID = 11021,             -- 4 bytes
    sourcemore = "1.1"              -- 3 bytes
}
-- Total: ~51 bytes per item
```

**Enhanced Model (V2)**:
```lua
{
    itemID = 47,                    -- 4 bytes
    name = "Reins of the...",       -- ~40 bytes
    creatureID = 11021,             -- 4 bytes
    sourcemore = "1.1",             -- 3 bytes
    description = "Dropped by...",  -- ~100 bytes (avg)
    icon = "Interface/Icons/...",   -- ~50 bytes
    creaturePreview = 11021         -- 4 bytes
}
-- Total: ~205 bytes per item
```

### Database Size Projections

**9,679 items** (current API total):

- **V1 Model**: ~493 KB
- **V2 Model**: ~1.98 MB (+300% increase)

**Trade-off**: Acceptable size increase for significantly enhanced functionality

---

## Implementation Strategy

### Phase 1: Core Fields (IMMEDIATE)
Extract and store:
- ✅ itemID
- ✅ name
- ✅ creatureID
- ✅ sourcemore
- ⭐ **description** (NEW)

### Phase 2: Visual Enhancement (NEXT)
Add:
- ⭐ **icon** (NEW)
- Implement tooltip icon display
- Enable icon-based filtering

### Phase 3: Advanced Features (FUTURE)
Add:
- ⭐ **creaturePreview** (NEW)
- Implement 3D model preview
- Build reverse lookup system
- Create creature-to-item mapping

---

## Feature Enablement

### Description Field Enables:

1. **Smart Filtering**
   ```lua
   -- Filter only dropped items
   function GetDroppedItems()
       return FilterByDescription("Dropped by:")
   end
   ```

2. **Region Extraction**
   ```lua
   -- Extract location from description
   "Dropped by: Lord Kazzak in Tainted Scar, Blasted Lands"
   -- Extracts: "Blasted Lands"
   ```

3. **Source Classification**
   ```lua
   -- Classify by description keywords
   if desc:match("Dropped by:") then source = "drop"
   elseif desc:match("Reward from:") then source = "achievement"
   elseif desc:match("Purchased from:") then source = "vendor"
   end
   ```

### Icon Field Enables:

1. **Visual Item Display**
   ```lua
   -- Show actual item icon in tooltip
   GameTooltip:AddLine("|T" .. icon .. ":16|t " .. name)
   ```

2. **Icon-Based Grouping**
   ```lua
   -- Group items by icon prefix
   local mounts = FilterByIconPrefix("inv_mount_")
   ```

3. **Visual Search**
   ```lua
   -- Find items with similar icons
   local similar = FindSimilarIcons("inv_mount_tiger")
   ```

### creaturePreview Field Enables:

1. **Reverse Lookups**
   ```lua
   -- Find item from creature ID
   function GetItemFromCreature(creatureID)
       return FindByCreaturePreview(creatureID)
   end
   ```

2. **3D Model Preview**
   ```lua
   -- Show 3D model on hover
   OnTooltipSetItem(tooltip, itemID)
       ModelPreview:SetCreature(data.creaturePreview)
   end
   ```

3. **Visual Validation**
   ```lua
   -- Verify mount appearance matches expected
   if creaturePreview == expectedID then
       return "Correct Model"
   end
   ```

---

## API Data Structure Reference

### Example Raw Data JSON
```json
{
    "id": 47,
    "name": "Reins of the Winterspring Frostsaber",
    "icon": "Interface/Icons/inv_mount_tiger_white",
    "description": "Dropped by: Shy-Rotam in Winterspring",
    "creaturePreview": 11021,
    "sourcemore": "1.1"
}
```

### Lua Extraction Pattern
```lua
-- Parse JSON rawData from API
local item = ParseJSON(rawData)

local dbEntry = {
    itemID = tonumber(item.id),
    name = item.name,
    creatureID = tonumber(item.creaturePreview),
    sourcemore = item.sourcemore,
    description = item.description,      -- NEW
    icon = item.icon,                    -- NEW
    creaturePreview = tonumber(item.creaturePreview)  -- NEW (explicit field)
}
```

---

## Testing & Validation

### Field Validation Checklist

- [ ] All itemIDs are unique and numeric
- [ ] All names are non-empty strings
- [ ] All creatureIDs are numeric (some may be 0)
- [ ] All sourcemore codes follow pattern (1-5.x)
- [ ] Descriptions contain meaningful text (not empty)
- [ ] Icons follow "Interface/Icons/" pattern
- [ ] creaturePreview matches creatureID (usually same)

### Sample Validation Queries

```lua
-- Check for missing descriptions
for id, data in pairs(AscensionVanityDB) do
    if not data.description or data.description == "" then
        print("Missing description:", id, data.name)
    end
end

-- Validate icon paths
for id, data in pairs(AscensionVanityDB) do
    if not data.icon:match("^Interface/Icons/") then
        print("Invalid icon path:", id, data.icon)
    end
end

-- Check creature ID consistency
for id, data in pairs(AscensionVanityDB) do
    if data.creatureID ~= data.creaturePreview then
        print("Creature mismatch:", id, data.creatureID, data.creaturePreview)
    end
end
```

---

## Migration Path

### Step 1: Update Extraction Script
Modify `ExtractDatabase.ps1` to extract new fields from API

### Step 2: Regenerate Database
Run extraction with new field mappings

### Step 3: Update Core.lua
Add support for new fields in tooltip display

### Step 4: Versioning
Increment database version to trigger cache refresh

---

## Benefits Summary

| Feature | Enabled By | Impact |
|---------|-----------|--------|
| Drop Filtering | description | Filter by acquisition method |
| Region Extraction | description | Parse location names |
| Visual Icons | icon | Show actual item icons |
| Icon Grouping | icon | Organize by visual similarity |
| Reverse Lookups | creaturePreview | Find item from creature |
| 3D Previews | creaturePreview | Show model on hover |
| Rich Tooltips | All fields | Complete item information |

---

## Next Steps

1. ✅ Document enhanced data model (THIS FILE)
2. ⏭️ Update extraction script to capture new fields
3. ⏭️ Modify database schema in VanityDB.lua
4. ⏭️ Implement tooltip enhancements to display icons
5. ⏭️ Build reverse lookup functions
6. ⏭️ Create 3D model preview system

---

**Status**: ✅ **APPROVED** - Ready for implementation
**Priority**: 🔥 **HIGH** - Significant feature enhancement
**Complexity**: ⚙️ **MEDIUM** - Straightforward extraction + new features


AV_VanityItems = {
    [79010] = 1678,  -- Beastmaster's Whistle: Felhound
    [79011] = 1679,  -- Beastmaster's Whistle: White Felbat
    ...
}
```
**Size**: ~2,500 lines (2,047 items)  
**Memory**: Minimal (2 integers per item)  
**Loading**: Always (core functionality)

---

#### **File 2: VanityDB_Icons.lua** (Metadata - Optional)
```lua
-- Icon texture paths for tooltip display
-- Format: [itemId] = "texture_path"

AV_Icons = {
    [1678] = "Ability_Hunter_BeastCall",
    [1679] = "Ability_Hunter_BeastCall",
    ...
}
```
**Size**: ~2,500 lines  
**Memory**: ~68 unique strings (shared references)  
**Loading**: Optional (if `showIcons` enabled)  
**Benefit**: Custom icons per item in tooltips

---

#### **File 3: VanityDB_Regions.lua** (Metadata - Optional)
```lua
-- Location information parsed from descriptions
-- Format: [creaturePreview] = "region_name"

AV_Regions = {
    [79010] = "Duskwood",
    [79011] = "Shadowmoon Valley",
    ...
}
```
**Size**: ~2,500 lines  
**Memory**: ~200-300 unique region strings (estimated)  
**Loading**: Optional (if `showRegions` enabled)  
**Benefit**: Location hints for farming

---

#### **File 4: VanityDB_Descriptions.lua** (Extended - Very Optional)
```lua
-- Full item descriptions for advanced features
-- Format: [itemId] = "full_description"

AV_Descriptions = {
    [1678] = "Has a chance to drop from Felhound within Duskwood",
    [1679] = "Has a chance to drop from White Felbat within Shadowmoon Valley",
    ...
}
```
**Size**: ~2,500 lines  
**Memory**: ~2,047 unique strings (largest file)  
**Loading**: VERY Optional (only for advanced tooltip/search features)  
**Benefit**: Full description display, searchability

---

## Reverse Lookup: Creature → Item

### Current Structure (Primary):
```lua
AV_VanityItems[creaturePreview] = itemId
```

### Reverse Lookup (Generated at Runtime):
```lua
-- Built on addon load from AV_VanityItems
AV_ReverseIndex = {}
for creatureId, itemId in pairs(AV_VanityItems) do
    AV_ReverseIndex[itemId] = creatureId
end

-- Usage: Find which creature drops item 1678
local creatureId = AV_ReverseIndex[1678]  -- Returns 79010
```

**Benefit**: No duplicate storage, built from primary DB

---

## Configuration System

### **AscensionVanityConfig.lua**
```lua
AscensionVanityConfig = {
    ["enabled"] = true,
    ["colorCode"] = true,
    ["debug"] = false,
    
    -- NEW: Feature toggles (control optional file loading)
    ["showIcons"] = true,        -- Load VanityDB_Icons.lua
    ["showRegions"] = true,      -- Load VanityDB_Regions.lua
    ["showDescriptions"] = false, -- Load VanityDB_Descriptions.lua (advanced)
    ["show3DPreview"] = true,    -- Enable creature 3D model preview
}
```

---

## Loading Strategy

### **Core.lua Load Sequence**
```lua
-- Phase 1: Core DB (always)
if not AV_VanityItems then
    error("VanityDB.lua not found!")
end

-- Phase 2: Optional metadata (based on config)
if AscensionVanityConfig.showIcons then
    -- Load VanityDB_Icons.lua if available
    if not AV_Icons then
        print("Warning: VanityDB_Icons.lua not found, using category defaults")
    end
end

if AscensionVanityConfig.showRegions then
    -- Load VanityDB_Regions.lua if available
    if not AV_Regions then
        print("Warning: VanityDB_Regions.lua not found, region display disabled")
    end
end

if AscensionVanityConfig.showDescriptions then
    -- Load VanityDB_Descriptions.lua if available
    if not AV_Descriptions then
        print("Warning: VanityDB_Descriptions.lua not found")
    end
end

-- Phase 3: Build reverse index
AV_ReverseIndex = {}
for creatureId, itemId in pairs(AV_VanityItems) do
    AV_ReverseIndex[itemId] = creatureId
end
```

---

## Tooltip Display Logic

### **Enhanced Tooltip Example**
```lua
function OnTooltipSetItem(tooltip, itemData)
    local itemId = itemData.id
    
    -- Find creature from reverse index
    local creatureId = AV_ReverseIndex[itemId]
    if not creatureId then return end
    
    -- Display icon (if enabled and available)
    if AscensionVanityConfig.showIcons and AV_Icons then
        local icon = AV_Icons[itemId]
        if icon then
            -- Use actual item icon in tooltip
            tooltip:SetItemIcon(icon)
        end
    end
    
    -- Display region (if enabled and available)
    if AscensionVanityConfig.showRegions and AV_Regions then
        local region = AV_Regions[creatureId]
        if region then
            tooltip:AddLine("Location: " .. region, 0.7, 0.7, 0.7)
        end
    end
    
    -- Display full description (if enabled)
    if AscensionVanityConfig.showDescriptions and AV_Descriptions then
        local desc = AV_Descriptions[itemId]
        if desc then
            tooltip:AddLine(desc, 0.8, 0.8, 0.8, true) -- wrapped text
        end
    end
    
    -- 3D creature preview (if enabled)
    if AscensionVanityConfig.show3DPreview then
        -- Use creatureId for 3D model preview
        tooltip:SetCreatureModel(creatureId)
    end
end
```

---

## Memory Footprint Analysis

### Estimated Memory Usage (2,047 items):

| File | Loaded When | Est. Memory |
|------|------------|-------------|
| VanityDB.lua | Always | ~20 KB (2 integers × 2,047) |
| VanityDB_Icons.lua | If enabled | ~15 KB (~68 unique strings) |
| VanityDB_Regions.lua | If enabled | ~25 KB (~300 unique strings) |
| VanityDB_Descriptions.lua | If enabled | ~150 KB (full strings) |
| Reverse Index | Always | ~20 KB (runtime generated) |
| **Total (all features)** | | **~230 KB** |
| **Total (core only)** | | **~40 KB** |

**Conclusion**: Even with all features enabled, total memory is negligible (<250 KB).

---

## Region Extraction Logic

### Parse Region from Description:
```powershell
# Input: "Has a chance to drop from Felhound within Duskwood"
# Output: "Duskwood"

if ($description -match "within (.+?)(?:\.|$)") {
    $region = $matches[1].Trim()
    # Clean up any trailing punctuation
    $region = $region -replace '[.\s]+$', ''
}
```

### Edge Cases:
```powershell
# Multiple regions: "within Duskwood and Deadwind Pass"
# Handle: Take first region or concatenate

# No region: "Has a chance to drop from Felhound"
# Handle: Set to "Unknown" or null

# Special format: "within The Underbog (Heroic)"
# Handle: Keep difficulty marker or extract dungeon name only
```

---

## Icon Indexing (Not Needed, But Documented)

### If Future Optimization Needed:
```lua
-- Icon index (shared references)
AV_IconIndex = {
    [1] = "Ability_Hunter_BeastCall",        -- Beastmaster's Whistle
    [2] = "inv_glyph_primedeathknight",      -- Blood Soaked Vellum
    [3] = "inv_misc_horn_01",                -- Draconic Warhorn
    [4] = "inv_misc_uncutgemnormal1",        -- Summoner's Stone
    [5] = "custom_T_Nhance_RPG_Icons_ArcaneStone_Border", -- Elemental (Arc)
    [6] = "custom_T_Nhance_RPG_Icons_IceStone_Border",    -- Elemental (Ice)
    -- ... 62 more
}

-- Per-item icon reference
AV_Icons = {
    [1678] = 1,  -- References AV_IconIndex[1]
    [1679] = 1,  -- References AV_IconIndex[1]
    ...
}

-- Memory savings: ~10 KB (strings → integers)
```
**Current Decision**: NOT implementing (negligible savings, adds complexity)

---

## Database Generation Script

### **utilities/GenerateOptimizedDB.ps1**
```powershell
# Enhanced version to extract all fields

$output = @"
-- VanityDB.lua (Core Database)
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Items: 2,047 drop-based pet taming items

AV_VanityItems = {
"@

foreach ($item in $dropsOnlyItems) {
    $output += "`n    [$($item.creaturePreview)] = $($item.itemId), -- $($item.name)"
}

$output += "`n}`n"

# Generate icons file
$iconsOutput = @"
-- VanityDB_Icons.lua (Icon Metadata)
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

AV_Icons = {
"@

foreach ($item in $dropsOnlyItems) {
    $icon = $item.rawData.icon
    $iconsOutput += "`n    [$($item.itemId)] = `"$icon`","
}

$iconsOutput += "`n}`n"

# Generate regions file (parse from description)
$regionsOutput = @"
-- VanityDB_Regions.lua (Location Metadata)
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

AV_Regions = {
"@

foreach ($item in $dropsOnlyItems) {
    if ($item.rawData.description -match "within (.+?)(?:\.|$)") {
        $region = $matches[1].Trim() -replace '[.\s]+$', ''
        $regionsOutput += "`n    [$($item.creaturePreview)] = `"$region`","
    }
}

$regionsOutput += "`n}`n"

# Save all files
$output | Out-File "AscensionVanity\VanityDB.lua"
$iconsOutput | Out-File "AscensionVanity\VanityDB_Icons.lua"
$regionsOutput | Out-File "AscensionVanity\VanityDB_Regions.lua"
```

---

## Migration Path

### Phase 1: Core DB
1. Generate `VanityDB.lua` (creaturePreview → itemId)
2. Update `Core.lua` to load it
3. Test core functionality

### Phase 2: Icons
1. Generate `VanityDB_Icons.lua`
2. Add icon display to tooltip logic
3. Add `showIcons` config option
4. Test icon display

### Phase 3: Regions
1. Generate `VanityDB_Regions.lua` (parse from descriptions)
2. Add region display to tooltip logic
3. Add `showRegions` config option
4. Test region display

### Phase 4: Optional Descriptions
1. Generate `VanityDB_Descriptions.lua` (full text)
2. Add description display (advanced feature)
3. Add `showDescriptions` config option
4. Test with all features enabled

---

## Summary

### Recommended Storage Strategy:

| Data | Storage | Loading | Reason |
|------|---------|---------|--------|
| **itemId** | Core DB | Always | Essential |
| **creaturePreview** | Core DB | Always | Primary key, reverse lookups |
| **icon** | Separate file | Optional | Per-item, no indexing needed |
| **region** | Separate file | Optional | Parsed from description |
| **description** | Separate file | Very Optional | Large, rarely needed fully |

### Benefits:
- ✅ **Backward compatible** (core DB unchanged structure)
- ✅ **Memory efficient** (load only what's needed)
- ✅ **Flexible** (users choose features)
- ✅ **Maintainable** (separate concerns)
- ✅ **Rich tooltips** (icons, regions, 3D previews)
- ✅ **Total memory**: <250 KB even with all features

---

## Next Steps
1. Review and approve enhanced data model
2. Update `GenerateOptimizedDB.ps1` to extract all fields
3. Generate all database files
4. Implement tooltip enhancements in `Core.lua`
5. Test in-game with all features enabled
