# Subzone Grouping Implementation Progress

**Date**: November 8, 2025  
**Status**: IN PROGRESS

## ✅ Completed:

1. **View State Variables**
   - Changed `viewMode` from zone/subzone/global to zone/global
   - Added `groupMode` variable (creatures/subzones)
   - Added `expandedSubzones` tracking object

2. **Button Layout**
   - Updated View button (Zone ↔ Global toggle)
   - Added Group button (Creatures ↔ Subzones toggle)
   - Repositioned Learned button to make room
   - Disabled subzones button when in global view

3. **Helper Functions**
   - Added `GetSubzonesInZone()` - Returns subzones with progress data
   - Added `GetCreaturesInSubzone()` - Returns creatures for expansion
   - Updated `collapseAllCategories()` to handle both modes

4. **Cleanup**
   - Removed subzone view references from tooltips
   - Added storage for dynamic subzone bars

## ❌ TODO:

### 1. Update GetCategoryItems()
- Remove old subzone filtering logic
- Simplify to only handle zone filtering

### 2. Update ShowExpandedItems()
- Add mode detection (creatures vs subzones)
- When in subzone mode, show creatures instead of items
- Format: "Creature Name (X/Y items)"

### 3. Update CalculateProgress()
- Handle subzone mode progress calculation
- Return progress by subzone instead of by category

### 4. Update UpdateProgressBars() - MAJOR CHANGE
- Detect groupMode
- If creatures: Show category bars (current behavior)
- If subzones: 
  - Hide category bars
  - Create dynamic subzone bars
  - Position them dynamically
  - Add expand buttons
  - Handle expansion

### 5. Update Title Display
- Remove subzone mode title logic
- Keep zone/global only

### 6. Cleanup Dynamic Bars
- When switching from subzones → creatures, clean up dynamic bars
- Prevent memory leaks from unreleased frames

## Implementation Order:

1. Fix GetCategoryItems() to remove subzone references
2. Update CalculateProgress() to handle subzone mode
3. Update ShowExpandedItems() to show creatures when in subzone mode
4. Update UpdateProgressBars() to handle both display modes
5. Add dynamic bar creation/cleanup
6. Test thoroughly

## Files Modified:
- `AscensionVanity/CollectionProgressFrame.lua` (800+ lines, significant changes)
