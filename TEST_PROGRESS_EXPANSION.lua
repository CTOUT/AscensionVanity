-- Progress Tracker Expansion Test Script
-- Copy and paste into WoW chat to test functionality

-- 1. Test basic functionality
/av progress
-- Click + button on Beast category, verify pet names appear
-- Click - button to collapse, verify pets disappear

-- 2. Test multiple expansions
-- Expand Beast, Demon, and Undead categories
-- Verify frame resizes to accommodate all
-- Verify no overlapping text

-- 3. Test zone view
-- Switch to Zone view
-- Verify categories with 0 pets are hidden
-- Verify remaining categories move up (no gaps)
-- Expand a visible category
-- Verify only zone-appropriate pets show (once zone data available)

-- 4. Test overall collapse
-- Click overall - button
-- Verify all categories hide
-- Click overall + button
-- Verify categories reappear

-- 5. Check console for errors
/console scriptErrors 1
/reload

-- 6. Verify data structure
/dump AV_VanityItems
-- Should show 2,355 items with itemid, name, creaturePreview, description, icon

-- 7. Test learned status colors
-- Expand a category
-- Learned pets should show: ✓ |cFF00FF00PetName|r (green)
-- Unlearned pets should show:   |cFFCCCCCCPetName|r (white/gray)

-- 8. Test frame resize
-- Expand all categories
-- Frame should grow to show all content
-- Collapse all categories
-- Frame should shrink to minimal size

-- ============================================================================
-- Expected Behavior Summary
-- ============================================================================
-- ✅ + button shows pet names below category bar
-- ✅ - button hides pet names
-- ✅ Pet names sorted alphabetically
-- ✅ Learned pets show green with checkmark
-- ✅ Unlearned pets show white/gray
-- ✅ Frame resizes dynamically
-- ✅ Empty categories hidden in zone view
-- ✅ Remaining categories move up (no gaps)
-- ✅ Overall expand/collapse works correctly

-- ============================================================================
-- Known Issues to Watch For
-- ============================================================================
-- ⚠️ Zone filtering shows all pets (expected until zone data added)
-- ⚠️ Many pets (100+) may extend beyond screen (scrolling not yet implemented)
-- ⚠️ If errors occur, check /console scriptErrors 1 and report

-- ============================================================================
-- Debugging Commands
-- ============================================================================
-- Check if functions exist:
/dump AV_UpdateProgressBars
/dump AV_GetCollectionProgress

-- Check expanded state:
/run for cat, state in pairs(expandedCategories or {}) do print(cat, state) end

-- Force update:
/run AV_UpdateProgressBars()

-- Check frame size:
/run local f = CollectionProgressFrame; print("Width: " .. f:GetWidth(), "Height: " .. f:GetHeight())

-- Check visible bars:
/run for cat, bar in pairs(CollectionProgressFrame.progressBars or {}) do print(cat, bar.bg:IsShown()) end
