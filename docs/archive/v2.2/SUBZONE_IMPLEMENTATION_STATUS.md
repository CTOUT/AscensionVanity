# Subzone Grouping - Implementation Status

**Date**: November 8, 2025  
**Session**: In Progress

## ✅ COMPLETED (90%):

1. **State Management** - Done
   - Added `groupMode` variable (creatures/subzones)
   - Added `expandedSubzones` tracking
   - Cleaned up old subzone view code

2. **Button Layout** - Done
   - Zone/Global toggle working
   - Creatures/Subzones toggle added
   - Subzones button disabled in global view
   - Tooltips updated

3. **Helper Functions** - Done
   - `GetSubzonesInZone()` - Gets subzones with progress ✅
   - `GetCreaturesInSubzone()` - Gets creatures for expansion ✅
   - `collapseAllCategories()` - Updated for both modes ✅

4. **Data Functions** - Done
   - `GetCategoryItems()` - Simplified, removed old subzone filtering ✅
   - `CalculateProgress()` - Handles subzone progress calculation ✅
   - `ShowExpandedItems()` - Shows creatures OR items based on mode ✅

5. **UI Updates** - Done
   - Title display simplified (Zone/Global only) ✅

## ❌ TODO (10% remaining):

### Critical: UpdateProgressBars() Function

This is the ONLY remaining piece. It needs to:

1. **Detect groupMode at start**
```lua
local groupMode = progressFrame.getGroupMode()
```

2. **Branch into two display modes:**

**Mode A: Creatures (existing)**
- Show category bars (current behavior)
- Works as-is

**Mode B: Subzones (NEW)**
- Hide all category bars
- Get subzones: `local subzones = GetSubzonesInZone()`
- Create/reuse dynamic bars for each subzone:
  ```lua
  for subzoneName, data in pairs(subzones) do
      local bar = progressFrame.subzoneBars[subzoneName]
      if not bar then
          -- Create new bar (use CreateProgressBar helper)
          bar = CreateProgressBar(progressFrame, subzoneName, progressFrame.progressBars.overall.bg, currentY)
          -- Add expand button
          -- Store in progressFrame.subzoneBars
      end
      -- Update progress
      bar:SetProgress(data.learned, data.total)
      -- Show at currentY position
      -- Add expand button click handler
  end
  ```

3. **Cleanup hidden bars**
- When switching modes, hide bars from other mode
- Prevent memory leaks

### Implementation Approach:

Add this section to `UpdateProgressBars()` right after getting progress:

```lua
local progress = CalculateProgress()

-- NEW: Branch based on group mode
if viewMode == "zone" and groupMode == "subzones" then
    -- SUBZONE MODE
    -- Hide category bars
    for _, cat in ipairs(categoryOrder) do
        local bar = progressFrame.progressBars[cat]
        bar.bg:Hide()
        bar.fill:Hide()
        bar.text:Hide()
        if bar.expandBtn then bar.expandBtn:Hide() end
    end
    
    -- Show/create subzone bars
    local currentY = -80
    local subzones = GetSubzonesInZone()
    
    for subzoneName, data in pairs(subzones) do
        -- Create or get existing bar
        -- Position it
        -- Set progress
        -- Add expand button if needed
        -- Show it
        currentY = currentY - 25
    end
else
    -- CREATURE MODE (existing code continues)
    -- ... existing category bar code ...
end
```

## Files Modified:
- `AscensionVanity/CollectionProgressFrame.lua`

## Next Steps:
1. Implement the UpdateProgressBars() branching logic
2. Test in-game
3. Fix any bugs
4. Polish and deploy

**Estimated Time**: 15-20 minutes of focused work
