# Ascension Client Code Analysis

**Location:** `D:\Tools\MPQEdit\export`  
**Source:** Ascension WoW Client MPQ Files  
**Extracted:** November 4, 2025  
**Purpose:** Reverse-engineer Ascension's custom vanity collection UI

---

## 🎯 What We Have

**The Keys to the Kingdom:**
- ✅ Complete Ascension AddOn code (extracted from MPQ archives)
- ✅ **AppearanceUI** - Ascension's custom vanity collection interface
- ✅ Custom Blizzard UI modifications
- ✅ All textures, XML, and Lua files

**This is invaluable because:**
1. We can see EXACTLY how Ascension's C_VanityCollection API is used
2. We can reverse-engineer their UI patterns and templates
3. We can discover undocumented APIs and features
4. We can build a compatible interface that feels native

---

## 📁 Key Files to Analyze

### Priority 1: AppearanceUI (CRITICAL)
**Location:** `D:\Tools\MPQEdit\export\Interface\AddOns\Blizzard_AppearanceUI\`

**Files to examine:**
```
AppearanceUI/
├── Blizzard_AppearanceUI.lua      # Main logic
├── Blizzard_AppearanceUI.xml      # Frame templates
├── Blizzard_ItemAppearance.lua    # Item appearance handling
├── Blizzard_ItemAppearance.xml    # Item UI templates
└── Textures/                      # UI graphics
```

**What to look for:**
- How they call `C_VanityCollection` APIs
- UI layout and frame hierarchy
- Button templates and styling
- Collection display patterns
- Filter implementation
- Search functionality
- Category organization
- Tooltip integration

### Priority 2: Collections Framework
**Location:** `D:\Tools\MPQEdit\export\Interface\AddOns\Blizzard_Collections\`

**Files to examine:**
```
Collections/
├── Blizzard_Collections.lua       # Collections system
├── Blizzard_Collections.xml       # Collections UI
├── Blizzard_PetCollection.lua     # Pet-specific logic
└── Blizzard_PetJournal.lua        # Pet journal (if exists)
```

**What to look for:**
- Base collection UI patterns
- Pet display logic
- Model viewer integration
- Sort/filter frameworks

### Priority 3: Wardrobe/Transmog System
**Location:** `D:\Tools\MPQEdit\export\Interface\AddOns\Blizzard_Wardrobe\`

**Relevance:** Similar collection UI patterns we can adapt

### Priority 4: Store UI
**Location:** `D:\Tools\MPQEdit\export\Interface\AddOns\Blizzard_StoreUI\`

**What to look for:**
- `ASCENSION_STORE_COLLECTION_ITEM_LEARNED` event usage
- How store items integrate with collection
- Purchase confirmation flows

---

## 🔍 Analysis Checklist

### Phase 1: API Discovery
- [ ] Find all `C_VanityCollection` function calls
- [ ] Document function signatures and return values
- [ ] Identify events fired (especially `ASCENSION_STORE_COLLECTION_ITEM_LEARNED`)
- [ ] Map item ID → unlock ID → index relationships
- [ ] Discover any undocumented APIs

### Phase 2: UI Pattern Analysis
- [ ] Extract frame templates (XML)
- [ ] Document UI hierarchy and layout
- [ ] Identify reusable components (buttons, scrollframes, etc.)
- [ ] Capture texture paths and artwork
- [ ] Note animation and transition patterns

### Phase 3: Data Flow
- [ ] How collection data is loaded on startup
- [ ] How items are displayed in list/grid views
- [ ] How filters are applied (category, learned status, etc.)
- [ ] How search works
- [ ] How sorting works

### Phase 4: Feature Discovery
- [ ] Hidden features we could expose
- [ ] Incomplete features we could complete
- [ ] Integration points for our addon
- [ ] Hooks we can leverage

---

## 🎨 UI Components to Extract

### Templates We Need
1. **Collection Item Button**
   - Icon display
   - Learned status indicator
   - Tooltip integration
   - Click handlers

2. **Category Filter Buttons**
   - Active/inactive states
   - Icon + text layout
   - Toggle behavior

3. **Search Box**
   - Text input styling
   - Clear button
   - Real-time filtering

4. **Scroll Frame**
   - Item layout (grid vs list)
   - Pagination
   - Performance optimization

5. **Progress Display**
   - Progress bar styling
   - Percentage calculation
   - Color coding

### Textures to Document
- Button backgrounds (normal, hover, pressed)
- Category icons (Beast, Demon, Undead, Dragonkin, Elemental)
- Frame borders and backgrounds
- Progress bar fills
- Status indicators (checkmark for learned, etc.)

---

## 📝 Code Extraction Tasks

### Task 1: C_VanityCollection API Documentation
**Goal:** Complete API reference with examples

**Create:** `docs/development/C_VANITY_COLLECTION_API.md`

**Contents:**
```lua
-- Document each function:
C_VanityCollection.GetAllItems()
C_VanityCollection.GetItem(index)
C_VanityCollection.IsCollectionItemOwned(itemID)
C_VanityCollection.GetNum()
-- etc.
```

### Task 2: Frame Template Library
**Goal:** Reusable XML templates for our addon

**Create:** `AscensionVanity/Templates.xml`

**Contents:**
- Button templates (adapted from AppearanceUI)
- Container templates (scroll frames, list views)
- Progress bar templates
- Tooltip templates

### Task 3: Texture Atlas
**Goal:** Document all UI textures we can reuse

**Create:** `docs/development/TEXTURE_REFERENCE.md`

**Contents:**
- Texture paths
- Dimensions
- Usage contexts
- Licensing notes (we can reuse Blizzard assets in WoW addons)

### Task 4: UI Pattern Cookbook
**Goal:** Code recipes for common UI tasks

**Create:** `docs/development/UI_PATTERNS.md`

**Contents:**
- How to create a collection grid
- How to implement category filtering
- How to add search functionality
- How to display progress bars
- How to integrate with native UI

---

## 🚀 Immediate Actions

### Step 1: Quick Survey (30 minutes)
```
1. Navigate to D:\Tools\MPQEdit\export\Interface\AddOns\
2. List all Blizzard_* folders
3. Check which ones exist:
   - Blizzard_AppearanceUI?
   - Blizzard_Collections?
   - Blizzard_Wardrobe?
   - Blizzard_StoreUI?
4. Screenshot the folder structure
5. Count files in AppearanceUI folder
```

### Step 2: Open Key Files (1 hour)
```
1. Open Blizzard_AppearanceUI/Blizzard_AppearanceUI.lua
2. Search for "C_VanityCollection" - count occurrences
3. Search for "ASCENSION_STORE" - find event handlers
4. Open Blizzard_AppearanceUI.xml
5. Identify main frame names (we'll need to hook these)
```

### Step 3: Create Reference Copy (15 minutes)
```powershell
# Copy to AscensionVanity repo for analysis
New-Item -Path ".\docs\ascension_client_reference" -ItemType Directory
Copy-Item "D:\Tools\MPQEdit\export\Interface\AddOns\Blizzard_AppearanceUI" `
    -Destination ".\docs\ascension_client_reference\" -Recurse
```

**Why:** Keep a versioned copy in the repo for future reference

### Step 4: Initial Documentation (1 hour)
Create the following quick reference files:
- `API_FUNCTIONS_FOUND.md` - List all C_VanityCollection calls
- `UI_FRAMES_FOUND.md` - List all major frame names
- `EVENTS_FOUND.md` - List all ASCENSION_* events
- `TEXTURES_FOUND.md` - List texture paths we can use

---

## 🎯 v2.3+ Goals Using This Code

### Goal 1: Native-Looking Collection Browser
**Based on:** AppearanceUI templates and styling

**Features:**
- Grid/list view toggle
- Category filtering (Beast, Demon, etc.)
- Search by name
- Sort by: Name, Date Acquired, Rarity
- Learned status indicators
- 3D model preview (if possible)

### Goal 2: Enhanced Tooltip Integration
**Based on:** How AppearanceUI handles tooltips

**Features:**
- Show unlock requirements
- Show drop location
- Show alternate sources
- Link to collection browser

### Goal 3: In-Game Collection Manager
**Based on:** Collections framework patterns

**Features:**
- Track favorites
- Create wishlists
- Mark farming targets
- Progress tracking per zone

### Goal 4: Store Integration
**Based on:** StoreUI code

**Features:**
- Detect store purchases
- Auto-update cache
- Link to store page for purchasable items

---

## 📋 Comparison: What We Have vs What Blizzard Has

| Feature | Our Current Addon | Ascension's Native UI |
|---------|-------------------|----------------------|
| **Collection List** | ❌ None | ✅ Full grid/list view |
| **Category Filters** | ✅ Tooltip only | ✅ UI buttons |
| **Search** | ❌ None | ✅ Text search |
| **Learned Status** | ✅ Tooltip colors | ✅ Visual checkmarks |
| **Progress Tracking** | ✅ Custom frame | ✅ Native progress bars |
| **Drop Locations** | ✅ Tooltip text | ❌ Not shown |
| **Zone Filtering** | ✅ Custom frame | ❌ Not available |
| **Model Preview** | ❌ None | ✅ 3D viewer |
| **Favorites** | ❌ None | ❌ Not available |

**Our Advantage:**
- ✅ Drop location data (they don't show this!)
- ✅ Zone-based hunting guide
- ✅ Quest-locked warnings (planned)
- ✅ Regional filtering

**Their Advantage:**
- ✅ Native UI integration
- ✅ 3D model viewer
- ✅ Professional polish
- ✅ Search and sort

**v2.3 Goal:** Combine the best of both!

---

## 🔒 Legal/Ethical Notes

**Is this legal?**
- ✅ YES - Extracting client files for addon development is allowed
- ✅ YES - Studying Blizzard's code for educational purposes is fine
- ✅ YES - Using Blizzard's textures in WoW addons is permitted
- ⚠️ NO - Don't copy code verbatim (reverse-engineer patterns only)
- ⚠️ NO - Don't redistribute extracted MPQ contents

**Best Practices:**
1. Study the code, don't copy it
2. Re-implement patterns in your own style
3. Use textures directly (they're part of the client)
4. Give credit where due in documentation
5. Focus on interoperability, not replacement

---

## 📚 Additional Resources

**Ascension-Specific:**
- Ascension Wiki: https://ascension.gg/wiki
- Ascension Discord: Community for questions
- Project Ascension GitHub: Check for any open-source tools

**WoW UI Development:**
- Townlong Yak FrameXML: https://www.townlong-yak.com/framexml/3.3.5
- Wowpedia UI Documentation: https://wowpedia.fandom.com/wiki/UI_XML
- WoW Interface Forums: https://www.wowinterface.com/forums/

**Tools:**
- MPQ Editor: For extracting client files
- Blizzard Interface Data: Official reference
- AddOn Studio: Deprecated but has good docs
- VS Code + Extensions: Modern development setup

---

## ✅ Next Steps

**Immediate (Tonight):**
1. Survey the extracted files
2. Find AppearanceUI folder
3. Open main .lua file
4. Count C_VanityCollection references
5. Take notes on structure

**Tomorrow:**
1. Create API documentation
2. Extract key templates
3. Document texture paths
4. Plan v2.3 UI architecture

**This Week:**
1. Build prototype collection browser
2. Integrate with our existing addon
3. Test on live server
4. Get user feedback

---

**Created:** November 4, 2025  
**Last Updated:** November 4, 2025  
**Status:** 🔥 **READY TO ANALYZE!**

**This is the breakthrough we needed for v2.3+!** 🚀
