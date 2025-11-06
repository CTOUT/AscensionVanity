# Progress Tracker Expansion Feature

**Date**: 2025-11-06  
**Branch**: v2.2-dev  
**Status**: ✅ Implemented (Needs Testing)

## Overview

Enhanced the Collection Progress Frame with expand/collapse functionality that shows individual pet names, auto-resizes the frame based on content, and intelligently hides empty categories with dynamic repositioning.

## Features Implemented

### 1. ✅ Pet Name Expansion
- **Expand buttons** now show all pets in the expanded category
- **Color coding**: ✓ Green for learned pets, white for unlearned
- **Checkmarks**: Visual indicator for collected pets
- **Alphabetical sorting**: Pets listed A-Z for easy scanning

### 2. ✅ Dynamic Frame Resizing
- **Auto-resize**: Frame height adjusts based on visible content
- **Smart calculation**: Accounts for header, visible bars, expanded items, padding
- **Smooth updates**: Resizes on expand/collapse and zone changes

### 3. ✅ Empty Category Handling
- **Hide empty categories**: In zone view, categories with 0 items are hidden
- **Dynamic repositioning**: Remaining categories move up to fill gaps
- **Expand state management**: Expanding categories also auto-collapsed when hidden

## Technical Implementation

### New Functions

#### `GetCategoryItems(category)`
```lua
-- Gets all pets for a category from VanityDB
-- Filters by category prefix (e.g., "Beastmaster's Whistle:")
-- Returns sorted array of {id, name, learned} objects
```

#### `ClearExpandedItems(category)`
```lua
-- Hides and removes FontString widgets for expanded pet names
-- Cleans up progressFrame.expandedItems[category] table
```

#### `ShowExpandedItems(category, anchorBar, yOffset)`
```lua
-- Creates FontString widgets for each pet in category
-- Positions below category bar with indentation
-- Color codes: green (learned), white (unlearned)
-- Returns total height used by expanded items
```

#### `ResizeFrame()`
```lua
-- Calculates total frame height based on visible content
-- Accounts for: header, overall bar, visible category bars, expanded items
-- Updates progressFrame:SetHeight()
```

### Modified Functions

#### `UpdateProgressBars()`
Enhanced with:
- **Dynamic positioning**: Repositions category bars when some are hidden
- **Smart Y tracking**: Accounts for expanded item height in layout
- **Auto-cleanup**: Collapses expanded categories when they become hidden
- **Resize call**: Automatically resizes frame after layout changes

#### Category Expand Button OnClick
Updated to:
- Toggle expanded state
- Show/hide pet names via helper functions
- Call `UpdateProgressBars()` to handle repositioning and resizing

#### Overall Expand Button OnClick
Simplified to:
- Toggle overall expanded state
- Call `UpdateProgressBars()` to handle all show/hide logic

## Data Flow

```
User clicks category expand button
  ↓
expandedCategories[cat] = true
  ↓
ShowExpandedItems(cat)
  ↓
GetCategoryItems(cat) → Filters VanityDB by prefix
  ↓
Creates FontStrings with pet names (green/white)
  ↓
UpdateProgressBars()
  ↓
Repositions all visible bars (accounts for expanded items)
  ↓
ResizeFrame() → Calculates new height
  ↓
Frame resizes smoothly
```

## Category Prefix Mapping

```lua
local categoryPrefixes = {
    beast = "Beastmaster's Whistle:",
    undead = "Blood Soaked Vellum:",
    demon = "Summoner's Stone:",
    dragonkin = "Draconic Warhorn:",
    elemental = "Elemental Lodestone:"
}
```

## Testing Checklist

### Basic Functionality
- [ ] Open Progress Tracker (`/av progress`)
- [ ] Click category expand button (+)
  - [ ] Button changes to (-)
  - [ ] Pet names appear below category bar
  - [ ] Pets sorted alphabetically
  - [ ] Learned pets show green with ✓
  - [ ] Unlearned pets show white
- [ ] Click category collapse button (-)
  - [ ] Button changes to (+)
  - [ ] Pet names disappear
  - [ ] Frame resizes smaller

### Zone View Testing
- [ ] Switch to Zone view
- [ ] Expand a category with pets
  - [ ] Only zone-specific pets shown (once zone data available)
  - [ ] Correct pet count
- [ ] Enter zone with no pets of a category
  - [ ] Category bar hidden
  - [ ] Remaining categories move up (no gaps)
  - [ ] Frame resizes to fit

### Edge Cases
- [ ] Collapse overall bar (-)
  - [ ] All category bars hidden
  - [ ] All expanded items hidden
  - [ ] Frame resizes to minimal height
- [ ] Expand overall bar (+)
  - [ ] Category bars reappear
  - [ ] Previously expanded categories stay collapsed
  - [ ] Frame resizes correctly
- [ ] Expand multiple categories
  - [ ] All expanded categories show pet names
  - [ ] No overlapping text
  - [ ] Frame height accounts for all expanded items

### Performance
- [ ] Expand category with many pets (100+)
  - [ ] No lag or frame drops
  - [ ] Smooth scrolling (if scrollbar added)
- [ ] Switch zones frequently
  - [ ] Updates happen smoothly
  - [ ] No memory leaks

## Known Limitations

1. **Zone Filtering**: Currently shows ALL pets of a category regardless of zone. Will show zone-specific pets once database has zone/subzone fields (see `TODO_ZONE_FILTERING.md`).

2. **Scrolling**: If a category has many pets (100+), the frame may extend beyond screen height. Future enhancement: add scroll frame for expanded items.

3. **Zone Data**: The `GetCategoryItems()` function currently uses a prefix-based filter as a workaround. Once zone enrichment is complete, it can query by zone/subzone for more accurate results.

## File Changes

- **CollectionProgressFrame.lua**: 
  - Added 3 helper functions (GetCategoryItems, ClearExpandedItems, ShowExpandedItems)
  - Added ResizeFrame function
  - Enhanced UpdateProgressBars with dynamic positioning
  - Updated expand button OnClick handlers
  - Added expandedItems storage table
  - Lines changed: ~150 additions

## Related Work

- **Database Browser**: Recently simplified zone filter (commit 721e742)
- **Zone Enrichment**: Parked for PC session (see `TODO_ZONE_FILTERING.md`)
- **Data Pipeline**: Requires MasterAPIDumpImport.ps1 → EnrichZoneData.ps1 → GenerateVanityDB_Master.ps1

## Next Steps

1. **Test in-game** with `/reload` and `/av progress`
2. **Verify** expand/collapse functionality works correctly
3. **Check** frame resizing in different scenarios
4. **Validate** zone view behavior (empty category hiding)
5. **Consider** adding scroll frame if categories have many pets
6. **Complete** zone enrichment workflow on PC for accurate zone filtering

## Screenshots

*To be added after testing*

---

**Status**: Ready for testing. Deploy with `.\DeployAddon.ps1` and test in-game with `/av progress`.
