# Regional Hunting Guide - Continuation Plan
**Date:** November 3, 2025 (Tomorrow)  
**Current Status:** Phase 1 Complete ✅  
**Next Steps:** Phase 2 - Visual UI Implementation

---

## 🎯 Quick Start for Tomorrow's Session

### Where We Left Off
- ✅ Phase 1 complete: Zone detection, filtering, slash commands working
- ✅ Chat-based output implemented and tested
- ✅ Code committed and pushed to GitHub (commit: 172d6ca)
- 🔲 Phase 2: Need to create visual UI panel

### Files to Work With Tomorrow

**Existing Files:**
- `AscensionVanity/RegionalGuide.lua` - Core logic (complete)
- `AscensionVanity/SettingsUI.lua` - Reference for UI patterns
- `AscensionVanity/ScannerUI.lua` - Reference for scrollable lists

**New File to Create:**
- `AscensionVanity/RegionalGuideUI.lua` - Visual panel for zone items

---

## 📋 Phase 2 Implementation Checklist

### Step 1: Create UI Frame
- [ ] Create main panel frame (similar to SettingsUI)
- [ ] Add title, close button, dragability
- [ ] Make ESC-closable
- [ ] Position at center or left side of screen

### Step 2: Add Zone Header
- [ ] Display current zone name dynamically
- [ ] Show item count (e.g., "3 unlearned items in this zone")
- [ ] Update on zone change

### Step 3: Create Scrollable List
- [ ] ScrollFrame for creature list
- [ ] Show creature name, ID, and icon
- [ ] List vanity items per creature
- [ ] Show subzone/location if available
- [ ] Color-code by learned status (green/yellow)

### Step 4: Add Utility Buttons
- [ ] "Refresh" button to manually update
- [ ] "Settings" button to open Settings UI
- [ ] Optional: "Export" button for text file

### Step 5: Integration
- [ ] Add button to Settings UI (next to Scanner button)
- [ ] Add slash command: `/avanity guide ui` or `/avanity guideui`
- [ ] Auto-update on zone change (optional setting)

### Step 6: Polish & Test
- [ ] Test across multiple zones
- [ ] Test with empty zones
- [ ] Test with all items learned
- [ ] Test UI responsiveness and layout

---

## 🎨 UI Design Mockup

```
┌─────────────────────────────────────────────────────┐
│ Regional Hunting Guide                          [X] │
├─────────────────────────────────────────────────────┤
│ Current Zone: Elwynn Forest                         │
│ Unlearned Items: 5 from 3 creatures                 │
├─────────────────────────────────────────────────────┤
│ ┌───────────────────────────────────────────────┐   │
│ │ [Icon] Mine Spider (ID: 43)                   │   │
│ │   → Beastmaster's Whistle: Mine Spider        │   │
│ │      Location: Jasperlode Mine                │   │
│ │                                               │   │
│ │ [Icon] Prowler (ID: 118)                      │   │
│ │   → Beastmaster's Whistle: Prowler           │   │
│ │      Location: Elwynn Forest                  │   │
│ │   → Blood Soaked Vellum: Prowler Demon       │   │
│ │                                               │   │
│ │ [Icon] Young Fleshripper (ID: 199)           │   │
│ │   → Beastmaster's Whistle: Young Fleshripper │   │
│ │      Location: Furlbrow's Pumpkin Farm        │   │
│ └───────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────┤
│ [Refresh]  [Settings]  [Close]                      │
└─────────────────────────────────────────────────────┘
```

---

## 💻 Code Structure (Reference)

### RegionalGuideUI.lua Template
```lua
-- AscensionVanity - Regional Hunting Guide UI
-- Visual panel for displaying zone-based vanity item drops

local AddonName = "AscensionVanity"

-- Create main panel frame
local guidePanel = CreateFrame("Frame", "AscensionVanityGuidePanel", UIParent)
guidePanel:SetSize(600, 500)
guidePanel:SetPoint("CENTER")
guidePanel:SetFrameStrata("DIALOG")
guidePanel:SetBackdrop({...})
guidePanel:SetMovable(true)
guidePanel:EnableMouse(true)
guidePanel:RegisterForDrag("LeftButton")
guidePanel:SetScript("OnDragStart", guidePanel.StartMoving)
guidePanel:SetScript("OnDragStop", guidePanel.StopMovingOrSizing)
guidePanel:Hide()

-- Make ESC-closable
tinsert(UISpecialFrames, "AscensionVanityGuidePanel")

-- Create title, close button, etc.
-- Create ScrollFrame for creature list
-- Create zone header with dynamic text
-- Create utility buttons

-- Update function
local function UpdateGuidePanel()
    -- Get current zone items
    local items = AscensionVanity_GetCurrentZoneItems()
    
    -- Clear existing list
    -- Populate ScrollFrame with items
    -- Update zone header text
end

-- Show panel function
function AscensionVanity_ShowGuide()
    UpdateGuidePanel()
    guidePanel:Show()
end

-- Zone change event handler
local zoneFrame = CreateFrame("Frame")
zoneFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneFrame:SetScript("OnEvent", function()
    if guidePanel:IsShown() then
        UpdateGuidePanel()
    end
end)
```

---

## 🧪 Testing Commands for Tomorrow

```lua
-- In-game testing sequence
/reload                         -- Load addon
/avanity zone                  -- Test chat output (Phase 1)
/avanity guide                 -- Same (alias)
/avanity guideui               -- Open UI panel (Phase 2 - new)

-- Move to different zones and test
-- Check empty zones (no items)
-- Check zones with multiple creatures
```

---

## 📦 Files to Update in TOC

```toc
# Add after RegionalGuide.lua:
RegionalGuide.lua
RegionalGuideUI.lua    <-- NEW FILE
```

---

## 🎯 Success Criteria for Phase 2

- [ ] Visual panel opens and displays correctly
- [ ] Shows current zone name dynamically
- [ ] Lists creatures and their vanity drops
- [ ] Scrollable for long lists
- [ ] Updates on zone change
- [ ] Easy to open (button in Settings + slash command)
- [ ] Looks consistent with SettingsUI/ScannerUI style

---

## 🚀 Optional Enhancements (If Time Permits)

- [ ] Filter buttons (show all vs unlearned only)
- [ ] Sort options (alphabetical, proximity)
- [ ] Click creature to show on map (if possible)
- [ ] Minimap button for quick access
- [ ] Auto-show on zone change (optional setting)
- [ ] Export to text file

---

## 📚 Reference Files for UI Patterns

**SettingsUI.lua:**
- Panel creation with backdrop
- Button creation (CreateFrame with UIPanelButtonTemplate)
- ESC-closable pattern (UISpecialFrames)
- Auto-save behavior

**ScannerUI.lua:**
- ScrollFrame implementation
- Progress bar updates
- Status text formatting
- Button event handlers

**Core.lua:**
- Slash command registration
- Function naming patterns
- Global function exports

---

## 🎬 Estimated Timeline

- **Setup & File Creation:** 15 minutes
- **UI Frame & Layout:** 30 minutes
- **ScrollFrame Implementation:** 45 minutes
- **Integration & Buttons:** 30 minutes
- **Testing & Polish:** 30 minutes

**Total Estimated Time:** ~2.5 hours

---

## 💡 Tips for Tomorrow

1. **Start with simplest version** - Get something on screen first
2. **Copy patterns from SettingsUI** - Consistent style and working code
3. **Test frequently** - `/reload` after each major change
4. **Handle empty states** - No items, all learned, etc.
5. **Keep it simple** - Can always add fancy features later

---

**Ready to Continue:** Yes ✅  
**Documentation:** Complete ✅  
**Code:** Committed & Synced ✅  
**Next Session:** November 3, 2025 🚀
