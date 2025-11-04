# Townlong Yak FrameXML Browser

**URL:** https://www.townlong-yak.com/framexml/builds

## What is it?

Townlong Yak hosts **complete FrameXML sources** for all WoW builds, including Classic, TBC, and WOTLK. This is the actual Blizzard UI code that runs in the game client.

## Why is this critical for addon development?

### 1. **Reference Implementation**
- See **exactly** how Blizzard implements UI features
- Study proven patterns and best practices
- Understand frame hierarchies and event flows
- Learn proper API usage directly from Blizzard

### 2. **Collection UI Inspiration**
For our vanity collection UI replacement (v2.3+), we can study:
- **PetJournal.lua** - Pet collection UI (Retail)
- **StableFrame.lua** - Hunter stable UI (Classic)
- **SpellBookFrame.lua** - Spell/talent UI patterns
- **CharacterFrame.lua** - Equipment/stats UI

### 3. **API Discovery**
- Find undocumented functions
- Understand event parameters
- See internal implementation details
- Discover hidden APIs not in documentation

### 4. **Version Comparison**
- Compare Classic vs TBC vs WOTLK implementations
- See how features evolved
- Understand API deprecations
- Find WOTLK-specific enhancements

## Relevant Builds for AscensionVanity

### WOTLK 3.3.5 (Project Ascension Base)
**Build:** 3.3.5 (12340)
**Link:** https://www.townlong-yak.com/framexml/3.3.5

**Key Files to Study:**

#### 1. PetStable.lua ⭐ PRIMARY REFERENCE
**URL:** https://www.townlong-yak.com/framexml/3.3.5/PetStable.lua  
**Size:** 239 lines  
**Purpose:** Hunter pet stable UI - **PERFECT template for vanity barn!**

**Key Functions:**
```lua
PetStable_OnLoad()     -- Initialization, event registration
PetStable_OnEvent()    -- Event handler (PET_STABLE_SHOW, UPDATE, etc.)
PetStable_Update()     -- UI refresh logic (icons, tooltips, selection)
  
  - SpellBookFrame.lua / SpellBook.xml
    Tab-based UI with categories
  
  - CharacterFrame.lua / CharacterFrame.xml
    Equipment slots and stats display
  
  - FriendsFrame.lua / FriendsFrame.xml
    Tab-based frame with lists
  
  - QuestLogFrame.lua / QuestLog.xml
    Scrollable list with filtering
```

### Retail (Latest) - For Modern Ideas
**Build:** 11.2.7 (Latest)
**Link:** https://www.townlong-yak.com/framexml/live

**Key Files:**
```
AddOns/Blizzard_Collections/
  - Blizzard_PetCollection.lua
    Modern pet collection UI
  
  - Blizzard_MountCollection.lua
    Mount journal (similar patterns)
  
  - Blizzard_Collections.lua
    Main collection frame
```

## How to Use for AscensionVanity Development

### Phase 1: Research (Current)
1. Browse WOTLK 3.3.5 build for `PetStableFrame.lua`
2. Study frame structure and layout
3. Note event handlers and API calls
4. Document UI patterns and conventions

### Phase 2: Adaptation Planning
1. Identify reusable components from Blizzard UI
2. Map Blizzard functions to our custom needs
3. Plan integration with existing AscensionVanity code
4. Design hybrid approach (Blizzard patterns + our data)

### Phase 3: Implementation
1. Create `VanityCollectionFrame.lua` based on Blizzard patterns
2. Adapt frame layouts for vanity items (not hunter pets)
3. Integrate with C_VanityCollection API
4. Add our custom features (filtering, zone info, etc.)

## Example: Studying PetStableFrame.lua

**What we can learn:**
- How to create scrollable pet lists
- Proper frame anchoring and positioning
- Category tabs (Active, Stable slots)
- Pet portrait rendering
- Tooltip integration
- Model frame setup (3D previews)

**Direct applications for us:**
- Replace hunter pets with vanity pets
- Adapt stable slots to vanity categories
- Reuse tooltip patterns for our data
- Apply same UI layout principles

## Comparison: IStableMaster vs Blizzard FrameXML

| Aspect | IStableMaster | Blizzard FrameXML |
|--------|---------------|-------------------|
| **Source** | Retail addon port | Official Blizzard code |
| **Target** | Retail WoW | WOTLK 3.3.5 |
| **Complexity** | High (modern APIs) | Moderate (WOTLK APIs) |
| **Adaptation** | Requires heavy changes | More compatible |
| **Patterns** | Retail-focused | WOTLK-native |

**Verdict:** Study **both**:
- **IStableMaster** for UI ideas and modern features
- **Blizzard FrameXML** for WOTLK-compatible implementation

## Recommended Research Path

### Week 1: Blizzard Code Study
1. **Day 1**: Download WOTLK 3.3.5 FrameXML
2. **Day 2**: Study `PetStableFrame.lua` structure
3. **Day 3**: Analyze frame templates (`.xml` files)
4. **Day 4**: Document API patterns and conventions
5. **Day 5**: Create implementation plan

### Week 2: IStableMaster Analysis
1. **Day 1**: Review IStableMaster code structure
2. **Day 2**: Identify Retail-specific features
3. **Day 3**: Map features to WOTLK equivalents
4. **Day 4**: Plan adaptation strategy
5. **Day 5**: Create hybrid design document

### Week 3: Prototype
1. Create minimal viable collection frame
2. Test with AscensionVanity database
3. Integrate C_VanityCollection API
4. Validate frame performance
5. Gather user feedback

## Key Files to Download

### Must-Have (WOTLK 3.3.5)
- `Interface/FrameXML/PetStableFrame.lua`
- `Interface/FrameXML/PetStableFrame.xml`
- `Interface/FrameXML/UIPanelTemplates.lua`
- `Interface/FrameXML/UIPanelTemplates.xml`

### Nice-to-Have (WOTLK 3.3.5)
- `Interface/FrameXML/SpellBookFrame.lua`
- `Interface/FrameXML/CharacterFrame.lua`
- `Interface/FrameXML/QuestLogFrame.lua`
- `Interface/FrameXML/FriendsFrame.lua`

### Reference (Retail Latest)
- `AddOns/Blizzard_Collections/Blizzard_PetCollection.lua`
- `AddOns/Blizzard_Collections/Blizzard_MountCollection.lua`

## Integration with v2.3 Plans

### Scanner/Database Split (AVSM + AVDB)
**FrameXML helps with:**
- Understanding how Blizzard separates concerns
- Learning proper addon structure
- Seeing how multiple addons interact
- Frame communication patterns

### Vanity Collection UI Replacement
**FrameXML provides:**
- Proven UI layouts
- Tested event handlers
- Proper frame hierarchies
- Performance-optimized code

### IStableMaster Adaptation
**FrameXML bridges the gap:**
- Shows WOTLK equivalents for Retail APIs
- Provides fallback patterns
- Demonstrates proper WOTLK frame creation
- Offers simpler alternatives to modern code

## Action Items

### Immediate (This Week)
- [ ] Download WOTLK 3.3.5 FrameXML from Townlong Yak
- [ ] Extract and archive `PetStableFrame.*` files
- [ ] Create comparison document: Blizzard vs IStableMaster
- [ ] Document WOTLK frame creation patterns

### Short-term (Next Week)
- [ ] Create prototype collection frame
- [ ] Test frame integration with AscensionVanity
- [ ] Validate API compatibility
- [ ] Design final UI mockups

### Long-term (v2.3)
- [ ] Implement full collection UI
- [ ] Add category filtering
- [ ] Integrate zone information
- [ ] Add 3D model previews
- [ ] Community feedback and iteration

## Resources

**Primary:**
- Townlong Yak FrameXML: https://www.townlong-yak.com/framexml/builds
- WOTLK 3.3.5 Build: https://www.townlong-yak.com/framexml/3.3.5

**Secondary:**
- IStableMaster Source: `D:\Repos\istablemaster`
- Wowpedia FrameXML: https://wowpedia.fandom.com/wiki/FrameXML
- WoW API Docs: https://wowpedia.fandom.com/wiki/World_of_Warcraft_API

**Tools:**
- VS Code with Lua extensions
- WoW AddOn Studio (optional)
- Git for version control

## Conclusion

**Townlong Yak FrameXML browser is a game-changer for our v2.3 development.**

It provides:
✅ Official Blizzard implementation patterns  
✅ WOTLK-compatible code examples  
✅ Proven UI frameworks  
✅ API usage best practices  
✅ Version comparison capabilities  

**Next steps:**
1. Download WOTLK 3.3.5 FrameXML
2. Study PetStableFrame implementation
3. Compare with IStableMaster
4. Create hybrid implementation plan

**This solves our biggest challenge:** How to adapt modern UI patterns (IStableMaster) to WOTLK without breaking compatibility. Blizzard's own WOTLK code shows us exactly how!

---

**Created:** November 4, 2025  
**Purpose:** Research resource for v2.3 Collection UI development  
**Status:** Reference document - ongoing research
