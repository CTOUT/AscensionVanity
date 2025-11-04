# Blizzard Interface Resources

## Overview

Official Blizzard Interface AddOn Kit provides access to all the art, code, and XML templates used by the default WoW UI. This is essential for creating addons that match Blizzard's look and feel or for understanding how Blizzard implements various UI elements.

**Source:** https://wowpedia.fandom.com/wiki/Interface_AddOn_Kit  
**Version:** WOTLK 3.3.5 (Project Ascension compatible)  
**Extracted Date:** November 4, 2025

---

## Installation Locations

### 1. Blizzard Interface Art (enUS)
**Path:** `D:\Program Files\Ascension Launcher\resources\client\Blizzard Interface Art (enUS)`

**Contents:**
- All UI textures and graphics (.tga, .blp files)
- Button textures
- Background images
- Icons and border art
- Frame decorations
- Character portraits
- Spell/ability icons

**Use Cases:**
- Finding exact texture paths for custom UIs
- Matching Blizzard's visual style
- Reusing official artwork in addons
- Creating templates that look native

**Example Paths:**
```
Interface\Buttons\UI-Panel-Button-Up.blp
Interface\DialogFrame\UI-DialogBox-Background.blp
Interface\PaperDollInfoFrame\UI-Character-CharacterTab-L1.blp
```

### 2. Blizzard Interface Data (enUS)
**Path:** `D:\Program Files\Ascension Launcher\resources\client\Blizzard Interface Data (enUS)`

**Contents:**
- FrameXML source code (.lua files)
- XML template definitions (.xml files)
- TOC file showing load order
- Localization strings
- Default UI implementation

**Key Files:**
```
FrameXML/
├── UIParent.lua              # Root frame management
├── GameTooltip.lua           # Tooltip system
├── PetStable.lua             # Hunter pet stable UI
├── CharacterFrame.lua        # Character panel
├── CollectionsJournal.lua    # Collections UI (mounts, pets, etc.)
├── StaticPopup.lua           # Dialog boxes
└── [300+ other files]
```

**Use Cases:**
- Understanding Blizzard's UI architecture
- Learning how to use WoW APIs correctly
- Finding functions and event handlers
- Seeing best practices for frame management
- **Copying/adapting official UI elements**

**Extremely Useful For AscensionVanity:**
- `PetStable.lua` - Hunter pet stable implementation (model for vanity UI)
- `CollectionsJournal.lua` - Collections interface patterns
- `GameTooltip.lua` - Tooltip enhancement examples

### 3. Blizzard Interface Tutorial
**Path:** `D:\Program Files\Ascension Launcher\resources\client\Blizzard Interface Tutorial`

**Contents:**
- Tutorial documentation
- Examples and guides
- API reference materials
- Coding patterns and best practices

---

## How to Use These Resources

### Finding Texture Paths

**Problem:** "I need the texture path for the default button background"

**Solution:**
```powershell
# Search in Blizzard Interface Art folder
cd "D:\Program Files\Ascension Launcher\resources\client\Blizzard Interface Art (enUS)\Interface"
Get-ChildItem -Recurse -Filter "*Button*.blp" | Select-Object FullName

# Example result:
# Interface\Buttons\UI-Panel-Button-Up.blp
```

**In Lua:**
```lua
local button = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
button:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
```

### Studying Blizzard's Code

**Problem:** "How does Blizzard implement the pet stable UI?"

**Solution:**
```powershell
# Read the official implementation
notepad "D:\Program Files\Ascension Launcher\resources\client\Blizzard Interface Data (enUS)\FrameXML\PetStable.lua"
```

**Key Insights from PetStable.lua:**
- Uses secure templates for pet action buttons
- Implements drag-and-drop with `PickupStablePet()` API
- Model viewer with `SetCreature()` for 3D previews
- Grid layout with `PetStableSlotButton` template

### Adapting Blizzard Templates

**Problem:** "I want my vanity pet UI to look like Blizzard's pet stable"

**Solution:**
1. Copy `PetStable.xml` templates
2. Adapt for vanity items instead of hunter pets
3. Replace APIs:
   - `GetNumStablePets()` → `C_VanityCollection.GetNum()`
   - `GetStablePetInfo()` → `C_VanityCollection.GetItem()`
   - `PickupStablePet()` → Custom vanity item handling

### Finding API Usage Examples

**Problem:** "How do I use `SetTexCoord()` correctly?"

**Solution:**
```powershell
# Search all Lua files for the function
cd "D:\Program Files\Ascension Launcher\resources\client\Blizzard Interface Data (enUS)\FrameXML"
Select-String -Path "*.lua" -Pattern "SetTexCoord" | Select-Object -First 10
```

**Example from Blizzard code:**
```lua
-- From ActionButton.lua
icon:SetTexCoord(0.078, 0.922, 0.078, 0.922)  -- Crop texture edges
```

---

## Project Ascension Compatibility

### What Works Directly
✅ **Art Assets** - All textures work in Ascension (WOTLK 3.3.5 base)  
✅ **XML Templates** - Most templates compatible  
✅ **Basic Lua Code** - Core WoW API calls work  
✅ **Frame Patterns** - Layout and structure patterns apply  

### What Needs Adaptation
⚠️ **Collections API** - Ascension uses `C_VanityCollection` (custom)  
⚠️ **Some Retail Features** - If kit includes newer APIs (check version)  
⚠️ **Localization** - Ascension may have custom strings  

### Ascension-Specific Resources
For Ascension-specific APIs, also reference:
- **Townlong Yak FrameXML:** https://www.townlong-yak.com/framexml/3.3.5
- **Ascension Wiki:** https://ascension.fandom.com/wiki/
- **In-Game Testing:** `/dump C_VanityCollection` for real API behavior

---

## Quick Reference Commands

### Search for Textures
```powershell
# Find all button textures
cd "D:\Program Files\Ascension Launcher\resources\client\Blizzard Interface Art (enUS)"
Get-ChildItem -Recurse -Filter "*Button*.blp"

# Find dialog backgrounds
Get-ChildItem -Recurse -Filter "*Dialog*.blp"

# Find pet-related textures
Get-ChildItem -Recurse -Filter "*Pet*.blp"
```

### Search for Code Examples
```powershell
# Find API usage
cd "D:\Program Files\Ascension Launcher\resources\client\Blizzard Interface Data (enUS)\FrameXML"
Select-String -Path "*.lua" -Pattern "CreateFrame"
Select-String -Path "*.lua" -Pattern "C_VanityCollection"  # Won't find (Ascension custom)
Select-String -Path "*.lua" -Pattern "GameTooltip"
```

### Find XML Templates
```powershell
# Find template definitions
cd "D:\Program Files\Ascension Launcher\resources\client\Blizzard Interface Data (enUS)\FrameXML"
Select-String -Path "*.xml" -Pattern "PetStable"
Select-String -Path "*.xml" -Pattern "CollectionItem"
```

---

## Specific Use Cases for AscensionVanity

### 1. Vanity Pet UI (v2.3+ Feature)
**Reference Files:**
- `FrameXML/PetStable.lua` - Pet stable implementation
- `FrameXML/PetStable.xml` - Pet stable templates
- `FrameXML/CollectionsJournal.lua` - Modern collections UI

**Key Elements to Adapt:**
- Pet slot button templates
- Model viewer setup
- Grid layout system
- Drag-and-drop handlers

### 2. Tooltip Enhancements (Current)
**Reference Files:**
- `FrameXML/GameTooltip.lua` - Tooltip system
- `FrameXML/GameTooltip.xml` - Tooltip templates

**Learn:**
- How Blizzard adds custom tooltip lines
- Proper color formatting
- Icon integration in tooltips

### 3. Progress Tracker UI (v2.2)
**Reference Files:**
- `FrameXML/StatusBar.lua` - Progress bar implementation
- `FrameXML/ReputationFrame.lua` - Multi-bar progress display

**Learn:**
- Color-coded progress bars
- Expandable category sections
- Status text formatting

### 4. Map Integration (v2.3+)
**Reference Files:**
- `FrameXML/WorldMapFrame.lua` - World map system
- `FrameXML/Minimap.lua` - Minimap overlay

**Learn:**
- Adding custom map pins
- Map coordinate system
- Pin icon management

---

## Integration with Other Resources

### Combined Workflow

1. **Townlong Yak** - Browse code online, search across files
   - https://www.townlong-yak.com/framexml/3.3.5

2. **Local FrameXML** - Deep dive into specific files, test locally
   - `D:\Program Files\Ascension Launcher\resources\client\Blizzard Interface Data (enUS)\FrameXML\`

3. **Art Assets** - Find exact texture paths for UI elements
   - `D:\Program Files\Ascension Launcher\resources\client\Blizzard Interface Art (enUS)\Interface\`

4. **IStableMaster** - Modern addon implementation example
   - `D:\Repos\istablemaster\`

5. **AscensionVanity** - Our own implementation and patterns
   - `D:\Repos\AscensionVanity\`

---

## Advantages Over Online Resources

| Feature | Townlong Yak (Online) | Local Interface Kit |
|---------|----------------------|-------------------|
| **Search Speed** | Fast (web search) | Very fast (local grep) |
| **Offline Access** | ❌ No | ✅ Yes |
| **Full File Context** | Limited (snippets) | ✅ Complete files |
| **Art Assets** | ❌ Not available | ✅ All textures included |
| **XML Templates** | ✅ Yes | ✅ Yes + easier to copy |
| **Custom Searches** | Limited | ✅ PowerShell/grep power |
| **Version Control** | One version | ✅ Can keep multiple versions |

---

## Best Practices

### When Adapting Blizzard Code

1. **Don't Copy Blindly** - Understand what the code does
2. **Check API Availability** - Test in Ascension before assuming it works
3. **Simplify** - Blizzard's code handles many edge cases you may not need
4. **Credit** - Comment where code is adapted from Blizzard UI
5. **Test** - Blizzard's code assumes certain load order and globals

### Example: Proper Attribution
```lua
-- Adapted from Blizzard's PetStable.lua (WOTLK 3.3.5)
-- Modified to use C_VanityCollection API instead of pet stable API
function AV_VanityStable_Initialize()
    -- Original: for i = 1, NUM_PET_STABLE_SLOTS do
    local numSlots = C_VanityCollection.GetNum()
    for i = 1, numSlots do
        -- Adapted implementation
    end
end
```

---

## Quick Start Checklist

For new developers working on AscensionVanity:

- [ ] Browse `PetStable.lua` to understand Blizzard's pet UI
- [ ] Check `CollectionsJournal.lua` for modern UI patterns
- [ ] Search `GameTooltip.lua` for tooltip best practices
- [ ] Find textures in Art folder for consistent styling
- [ ] Compare IStableMaster (`D:\Repos\istablemaster\`) with Blizzard's approach
- [ ] Reference Townlong Yak for cross-file searches
- [ ] Test all adapted code in Ascension (API differences!)

---

## Future Enhancements

### Documentation We Should Create

1. **API Compatibility Matrix** - Which Blizzard APIs work in Ascension
2. **Texture Catalog** - Screenshots of common UI elements with paths
3. **Template Library** - Pre-adapted XML templates for vanity items
4. **Migration Guide** - PetStable → VanityStable conversion guide

### Tools We Could Build

1. **Texture Browser** - GUI app to preview all Blizzard textures
2. **API Tester** - In-game tool to test Blizzard functions in Ascension
3. **Template Generator** - Convert Blizzard templates to vanity item versions

---

## Summary

**You now have:**
- ✅ Complete Blizzard UI source code (300+ files)
- ✅ All official UI textures and art assets
- ✅ XML templates for every default UI element
- ✅ Reference implementations of complex UI systems
- ✅ Local, offline access for fast development

**This enables:**
- 🚀 Faster UI development (copy and adapt patterns)
- 🎨 Consistent visual design (use official textures)
- 📚 Better understanding of WoW API usage
- 🔧 Professional-quality addon interfaces
- 💡 Learning from Blizzard's best practices

**Next steps for AscensionVanity v2.3+:**
1. Study `PetStable.lua` for vanity UI design
2. Adapt pet stable templates for vanity items
3. Use official textures for native look and feel
4. Reference `CollectionsJournal.lua` for modern patterns

---

**Last Updated:** November 4, 2025  
**Maintained By:** AscensionVanity Development Team
