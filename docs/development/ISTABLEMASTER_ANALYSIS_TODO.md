# IStableMaster Analysis Task List

**Goal:** Analyze IStableMaster addon and identify components we can adapt for AscensionVanity Stable Master

**Source:** D:\Repos\istablemaster (Retail WoW Hunter stable UI)  
**Target:** WOTLK 3.3.5 combat pet collection UI

---

## Analysis Checklist

### Phase 1: Initial Review (30 minutes)
- [ ] List all .lua files and their purposes
- [ ] List all .xml files and their UI layouts
- [ ] Identify main entry point (TOC file)
- [ ] Document addon structure and organization
- [ ] Note dependencies (Ace3, LibStub, etc.)

### Phase 2: UI Component Analysis (1 hour)
- [ ] **Grid View**
  - How does it render pet icons?
  - Pagination or virtual scrolling?
  - Performance considerations?
  
- [ ] **Filtering System**
  - How are filters implemented?
  - Search functionality?
  - Category/type filtering?
  
- [ ] **Detail Panel**
  - What information is displayed?
  - How is it updated?
  - Tooltip integration?

- [ ] **Frame Layout**
  - XML templates used?
  - Lua frame creation?
  - Anchoring and positioning?

### Phase 3: API Usage Analysis (1 hour)
- [ ] **Retail APIs Used**
  - Document all C_PetJournal calls
  - Document all C_Stable calls
  - Note any Retail-specific APIs
  
- [ ] **WOTLK Equivalents**
  - Map each Retail API to WOTLK equivalent
  - Identify APIs that don't exist in WOTLK
  - Plan workarounds for missing APIs

- [ ] **Data Structures**
  - How is pet data stored?
  - SavedVariables format?
  - In-memory caching?

### Phase 4: Portable Components (1 hour)
- [ ] **Reusable Code**
  - Utility functions
  - Helper libraries
  - UI templates
  
- [ ] **Adaptation Requirements**
  - What needs heavy modification?
  - What can be used as-is?
  - What should be rewritten from scratch?

### Phase 5: Integration Plan (30 minutes)
- [ ] **VanityDB Integration**
  - How to feed our data into the UI?
  - Data format conversions needed?
  
- [ ] **Blizzard UI Integration**
  - Replace Vanity tab vs standalone?
  - Hook into Collections frame?
  
- [ ] **Feature Mapping**
  - Which IStableMaster features apply?
  - Which features are hunter-specific?
  - What new features do we need?

---

## Key Files to Examine

### TOC File
```
- IStableMaster.toc
  → Load order
  → Dependencies
  → SavedVariables
```

### Core Files
```
- Core.lua or Main.lua
  → Initialization
  → Event handling
  → Main logic
```

### UI Files
```
- UI.lua or MainFrame.lua
  → Frame creation
  → Grid view implementation
  → Detail panel
```

### XML Files
```
- MainFrame.xml
  → UI layout templates
  → Button/icon definitions
```

### Data Files
```
- Database.lua or Data.lua
  → Pet data structure
  → How they store info
```

---

## API Mapping: Retail → WOTLK

### Pet Collection APIs

| Retail API | WOTLK Equivalent | Notes |
|------------|------------------|-------|
| `C_PetJournal.GetNumPets()` | `C_VanityCollection.GetNum()` | Count of pets |
| `C_PetJournal.GetPetInfoByIndex()` | `C_VanityCollection.GetItem(index)` | Get pet data |
| `C_PetJournal.GetOwnedBattlePetString()` | N/A | No battle pets in WOTLK |
| `C_StableInfo.GetStabledPetList()` | N/A | Hunter stable only |

### Frame/UI APIs

| Retail API | WOTLK Equivalent | Notes |
|------------|------------------|-------|
| `CreateFrame()` | `CreateFrame()` | ✅ Same |
| `SetBackdrop()` | `SetBackdrop()` | ✅ Same |
| `SetPoint()` | `SetPoint()` | ✅ Same |
| `Mixin()` | Manual mixin | Need helper function |

### Texture/Icon APIs

| Retail API | WOTLK Equivalent | Notes |
|------------|------------------|-------|
| `SetAtlas()` | `SetTexture()` | Use file paths, not atlas |
| `GetItemIcon()` | `GetItemIcon()` | ✅ Same |
| `CreateTexturePool()` | Manual pool | Need object pooling |

---

## Questions to Answer

### Technical
1. **Performance:** How many pets can the grid render smoothly?
2. **Scrolling:** Does it use virtual scrolling or load all at once?
3. **Caching:** How does it cache pet data for fast lookups?
4. **Updates:** How does it detect when collection changes?

### Design
1. **Layout:** Fixed grid size or responsive?
2. **Icons:** Icon size and quality?
3. **Spacing:** How much padding between elements?
4. **Colors:** Theme system or hardcoded colors?

### Integration
1. **Standalone:** Can it run independently of Blizzard UI?
2. **Hooks:** What Blizzard frames does it hook?
3. **Events:** What events does it listen to?
4. **Commands:** Slash commands structure?

---

## Deliverables

### Documentation
- `docs/ISTABLEMASTER_ANALYSIS.md` - Full source code analysis
- `docs/ISTABLEMASTER_API_MAPPING.md` - Retail → WOTLK API conversions
- `docs/ISTABLEMASTER_COMPONENTS.md` - Reusable component list

### Code Samples
- `prototypes/GridView.lua` - Portable grid view code
- `prototypes/PetDetail.lua` - Detail panel code
- `prototypes/FilterBar.lua` - Filter UI code

### Design Assets
- `docs/mockups/CollectionUI.png` - UI mockup based on IStableMaster
- `docs/mockups/DetailPanel.png` - Detail view mockup
- `docs/mockups/StatsBoard.png` - Statistics dashboard mockup

---

## Timeline

**Immediate (Today):**
- [ ] Download and extract IStableMaster source
- [ ] Initial file structure review
- [ ] Document TOC and load order

**This Week:**
- [ ] Complete Phase 1-3 analysis
- [ ] Create API mapping document
- [ ] Identify portable components

**Next Week:**
- [ ] Create prototypes of key components
- [ ] Test WOTLK compatibility
- [ ] Design AV Stable Master UI mockups

---

## Notes

**IStableMaster Features to Adapt:**
- Grid view with pet icons ✅
- Category filtering ✅
- Search functionality ✅
- Detail panel with stats ✅
- Stable/collection tracking ⚠️ (Hunter-specific, adapt for vanity)

**IStableMaster Features to Skip:**
- Hunter-specific abilities ❌
- Stable slot management ❌
- Pet talent trees ❌
- Call pet macros ❌

**New Features We Need:**
- Zone filtering ✨
- Drop source display ✨
- "Show on Map" button ✨
- Farm guide integration ✨
- Quest-locked warnings ✨

---

**Status:** Planning Phase  
**Next Action:** Begin Phase 1 analysis  
**Assigned To:** CMTout  
**Completion Target:** November 11, 2025
