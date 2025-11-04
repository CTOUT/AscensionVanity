# Ascension Collections UI Analysis

**Date:** November 4, 2025  
**Source:** Ascension WoW Client (WOTLK 3.3.5 based)  
**Location:** `data/extracts/AscensionInterface/Ascension_Collections/`

---

## Overview

Ascension's Collections UI is a **tab-based system** that manages multiple collection types:
- Character Advancement (CoA Talents)
- Hero Architect (Build Creator)
- Skill Cards
- **Vanity Collection** (Combat Pets) ← Our focus
- Mystic Enchants
- Seasonal Collection
- Wardrobe (Transmog)

---

## Key Architecture Patterns

### 1. Tab System (CollectionsMixin)

**File:** `Collections.lua`

**Pattern:** Uses `TabSystemMixin` with lazy-loaded frames

```lua
function CollectionsMixin:SetupTabSystem()
    -- Vanity Tab Registration
    tab = self:AddTab(VANITY, "StoreCollectionFrame")
    tab:SetIcon("Interface\\icons\\INV_Chest_Awakening")
    tab:SetTooltip(VANITY, VANITY_TOOLTIP)
    self.Tabs.Vanity = tab:GetTabID()
end
```

**Key Features:**
- ✅ Lazy loading via `LoadOnDemand` (performance)
- ✅ Tab icons and tooltips
- ✅ Pre-click callbacks for loading UI
- ✅ Saved tab state (remembers last opened)
- ✅ Scale adjustment for different UI scales

**Relevance to AscensionVanity:**
- We could adopt this pattern for multi-view UI (Progress, Regional Guide, etc.)
- Tab system allows clean separation of concerns
- Performance-friendly (only loads what's visible)

---

### 2. Tab Template (CollectionsTabMixin)

**File:** `CollectionsTabMixin.lua`

**Pattern:** Icon-based tabs with hover states

```lua
function CollectionsTabMixin:OnSelected()
    self.Icon:SetBorderColor(YELLOW_FONT_COLOR:GetRGB())
end

function CollectionsTabMixin:OnDeselected()
    self.Icon:SetBorderColor(GRAY_FONT_COLOR:GetRGB())
end
```

**Features:**
- Icon with colored border (changes on selection)
- Text padding for alignment
- Mouse down/up animation (icon shifts)
- Built on `TabSystemTabMixin` (Blizzard base)

**Relevance to AscensionVanity:**
- Professional-looking tab system
- Easy to extend with new tabs
- Consistent with Blizzard UI patterns

---

### 3. Frame Structure (Collections.xml)

**File:** `Collections.xml`

**Key Elements:**

```xml
<Frame name="Collections" frameStrata="DIALOG" movable="true">
    <Size x="784" y="512"/>
    <Backdrop bgFile="Interface\AddOns\AwAddons\Collections\StoreCollection">
        <BackgroundInsets left="-120" right="-120" top="-256" bottom="-256"/>
    </Backdrop>
</Frame>
```

**Features:**
- Fixed size: 784x512 (standard collection window size)
- Movable and draggable
- Custom backdrop texture
- Frame strata: DIALOG (above most UI)
- Clamped to screen (can't drag off-screen)

**Relevance to AscensionVanity:**
- We're using similar patterns already (movable frames)
- Standard size gives us a reference point
- Backdrop system for custom backgrounds

---

## Vanity Collection Integration

### Current Setup (from Collections.lua)

```lua
-- Vanity Tab
tab = self:AddTab(VANITY, "StoreCollectionFrame")
tab:SetIcon("Interface\\icons\\INV_Chest_Awakening")
tab:SetTooltip(VANITY, VANITY_TOOLTIP)
self.Tabs.Vanity = tab:GetTabID()
```

**Key Points:**
1. **Frame Name:** `StoreCollectionFrame` (not found in extracted files)
2. **Icon:** `INV_Chest_Awakening` (generic chest icon)
3. **Load Method:** On-demand (when tab clicked)
4. **No pre-click callback** = Already loaded or in main TOC

### Missing Pieces (Not Yet Found)

The actual `StoreCollectionFrame` implementation is **not in Ascension_Collections**. It's likely in:
- A separate addon (possibly server-side compiled)
- Embedded in game client (not extractable)
- Uses `C_VanityCollection` API calls (server-side)

**What We Know from Our Research:**
- `C_VanityCollection` API exists (we've used it)
- `C_VanityCollection.GetAllItems()` - Returns all vanity items
- `C_VanityCollection.IsCollectionItemOwned(itemID)` - Check learned status
- `C_VanityCollection.GetItem(itemID)` - Get item details

---

## Design Patterns We Can Adopt

### 1. Tab-Based Multi-View System

**Current AscensionVanity Structure:**
- Collection Progress Frame (standalone)
- Regional Guide (chat-based, future UI)
- Settings UI (standalone)

**Potential Unified System:**
```
AscensionVanity Frame (784x512)
├── Tab 1: Collection Progress (current standalone)
├── Tab 2: Regional Guide (browse by zone)
├── Tab 3: Creature Browser (browse by creature)
├── Tab 4: Settings
└── Tab 5: Scanner (developer tools)
```

**Benefits:**
- ✅ Single unified frame (less screen clutter)
- ✅ Professional integration with game UI
- ✅ Lazy loading (performance)
- ✅ Familiar UX for players (matches Blizzard pattern)

### 2. Icon Border System

**Pattern from CollectionsTabMixin:**
```lua
self.Icon:SetBorderTexture("Interface\\common\\WhiteIconFrame")
self.Icon:SetBorderColor(YELLOW_FONT_COLOR:GetRGB()) -- Selected
self.Icon:SetBorderColor(GRAY_FONT_COLOR:GetRGB())   -- Deselected
```

**Relevance:**
- We could use border colors to indicate learned status
- Yellow = current view, Green = learned, Red = unlearned, Gray = default
- Professional visual feedback

### 3. Scale Adjustment

**Pattern from CollectionsMixin:**
```lua
local uiScale = GetUIScale()
if uiScale > 0.9 then
    uiScale = uiScale - 0.9
    self:SetScale(1 - uiScale)
end
```

**Relevance:**
- Handles players with custom UI scales
- Ensures consistent sizing across different resolutions
- Professional touch (many addons ignore this)

---

## Comparison: Ascension vs IStableMaster vs Our Current System

| Feature | Ascension | IStableMaster | AscensionVanity v2.2 |
|---------|-----------|---------------|---------------------|
| **Pattern** | Tab system | Grid layout | Standalone frames |
| **Size** | 784x512 | Flexible | Varies by frame |
| **Integration** | Unified frame | Separate window | Multiple windows |
| **Lazy Loading** | ✅ Yes | ❌ No | ✅ Partial |
| **Performance** | High | Medium | High |
| **Extensibility** | High (add tabs) | Medium | Medium |
| **Familiarity** | Very High | High | High |

---

## Recommendations for v2.3+

### Option A: Standalone Enhanced (Low Risk)
**Keep current separate frames, enhance individually**

**Pros:**
- ✅ Less refactoring
- ✅ Maintain current functionality
- ✅ Easy to ship v2.2

**Cons:**
- ❌ Multiple windows on screen
- ❌ Feels less integrated
- ❌ Harder to discover features

### Option B: Unified Tab System (Medium Risk)
**Adopt Ascension's tab pattern, create unified frame**

**Pros:**
- ✅ Professional integration
- ✅ Single window, multiple views
- ✅ Lazy loading benefits
- ✅ Room for growth (add tabs easily)

**Cons:**
- ⚠️ Significant refactoring
- ⚠️ More testing required
- ⚠️ Delays v2.2 release

### Option C: Hybrid Approach (Recommended)
**Ship v2.2 as-is, plan unified frame for v2.3**

**Phase 1 (v2.2):**
- Keep current standalone frames
- Focus on functionality over integration
- Quick release, gather feedback

**Phase 2 (v2.3):**
- Adopt tab system pattern
- Migrate frames to unified window
- Add IStableMaster-inspired grid view
- Professional polish

**Benefits:**
- ✅ Ship v2.2 quickly
- ✅ Time to test tab system thoroughly
- ✅ Incorporate user feedback
- ✅ Professional v2.3 "UI overhaul" feature

---

## Technical Implementation Plan (v2.3)

### Step 1: Create Base Tab System
```lua
-- AscensionVanityFrame.lua
AscensionVanityMixin = CreateFromMixins(TabSystemMixin)

function AscensionVanityMixin:OnLoad()
    self:SetupTabSystem()
    -- Mirror Ascension's pattern
end
```

### Step 2: Migrate Existing Frames to Tabs
```lua
-- Tab 1: Collection Progress
tab = self:AddTab("Progress", "AV_CollectionProgressPanel")
tab:SetIcon("Interface\\Icons\\INV_Misc_Note_06")

-- Tab 2: Regional Guide
tab = self:AddTab("Regional", "AV_RegionalGuidePanel")
tab:SetIcon("Interface\\Icons\\Ability_Hunter_MasterMarksman")

-- Tab 3: Settings
tab = self:AddTab("Settings", "AV_SettingsPanel")
tab:SetIcon("Interface\\Icons\\Trade_Engineering")
```

### Step 3: Implement Grid View (IStableMaster-inspired)
```lua
-- AV_CreatureBrowser.lua
-- Grid of creature icons, filterable, sortable
-- Shows learned status with border colors
```

### Step 4: Professional Polish
- Custom backdrop textures
- Smooth tab transitions
- Keyboard shortcuts (1-5 for tabs)
- Minimap button integration

---

## Files to Study Further

### Priority 1: Vanity Collection Implementation
**Need to find:**
- `StoreCollectionFrame` (actual vanity UI)
- Grid/list view implementation
- Filter and search system
- `C_VanityCollection` API usage patterns

**Likely locations:**
- Separate client-side addon (not extracted yet)
- Server-side compiled code (not accessible)
- Embedded in game client

### Priority 2: UI Toolkit
**Already have:**
- ✅ Collections tab system (`Collections.lua`)
- ✅ Tab template (`CollectionsTabMixin.lua`)
- ✅ Blizzard FrameXML (via Interface Kit)

**Next steps:**
- Study Blizzard's `PetStable.lua` (similar pattern)
- Analyze IStableMaster's grid layout
- Create hybrid design

---

## Conclusion

**Key Findings:**
1. ✅ Ascension uses professional tab-based system
2. ✅ Lazy loading for performance
3. ✅ Standard Blizzard UI patterns
4. ⚠️ Actual vanity UI code not yet found (likely server-side)
5. ✅ We can adopt the framework without the implementation

**Recommendation:**
- **v2.2:** Ship current standalone frames (95% complete)
- **v2.3:** Adopt tab system, create unified professional UI
- **Study:** IStableMaster + Blizzard PetStable.lua for grid view patterns

**Next Actions:**
1. Complete v2.2 (Regional Guide UI + Quest Warnings)
2. Release v2.2 for feedback
3. Plan v2.3 unified frame architecture
4. Implement tab system with professional polish

---

**Last Updated:** November 4, 2025  
**Status:** Analysis Complete, Ready for v2.3 Planning
