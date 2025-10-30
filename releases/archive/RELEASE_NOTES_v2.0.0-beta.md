# AscensionVanity v2.0.0-beta - Tooltip Icon Fix & Repository Overhaul

**Release Date:** October 29, 2025  
**Status:** Pre-Release (Beta Testing)  
**Branch:** v2.0-dev

---

## 🎯 Highlights

### Database Excellence
- **99.95% Coverage:** 2,173 out of 2,174 combat pet vanity items
- **Complete Descriptions:** Automated enrichment with location data
- **Icon Optimization:** Reduced database size by ~140KB with indexed icons

### Critical Bug Fixes
- ✅ **Icon Display:** Fixed missing item icons in tooltips
- ✅ **Learned Status:** Fixed double tick/cross artifact bug
- ✅ **Color Coding:** Consistent learned status indicators

### Repository Improvements
- 📚 **68% Script Reduction:** Consolidated workflows from 63 to 20 active scripts
- 🤖 **GitHub Copilot Integration:** Repository-level AI instructions
- 📁 **Organized Archive:** 43 obsolete scripts properly documented and archived

---

## 📦 Installation

1. Download `AscensionVanity-v2.0.0-beta.zip`
2. Extract the ZIP file
3. Copy the `AscensionVanity` folder to your WoW AddOns directory:
   ```
   <WoW_Installation>\Interface\AddOns\AscensionVanity\
   ```
4. In-game: `/reload` or restart WoW

---

## ✨ Features

### Tooltip Integration
- **Automatic Display:** Shows vanity items when hovering over creatures
- **Icon Display:** Item type icons now display correctly in tooltips
- **Learned Status:** Green checkmark (✓) for owned, red cross (✗) for unowned
- **Color Coding:** Configurable color-coded tooltips

### Comprehensive Database
- **2,174 Combat Pets:** Complete vanity item database
- **9 Item Types:** Beastmaster's Whistles, Blood Soaked Vellums, Summoner's Stones, Draconic Warhorns, Elemental Lodestones
- **Location Data:** 99.95% of items include drop location information

### Configuration
All features toggle-able via slash commands:
```
/av toggle      - Enable/disable addon
/av learned     - Toggle learned status display
/av color       - Toggle color coding
/av debug       - Enable debug mode
/av help        - Show all commands
```

---

## 🔧 What's Fixed in v2.0.0-beta

### Tooltip Icon Display (Critical Fix)
**Problem:** Item icons (e.g., Ability_Hunter_BeastCall) were not showing in tooltips.

**Fix Applied:**
- Added proper `Interface\\Icons\\` path prefix to icon names
- Icons now display correctly for all item types
- Added debug logging to track icon resolution

**Testing:** ✅ Verified in-game with multiple creature types

### Learned Status Indicators (Critical Fix)
**Problem:** Double tick/cross artifacts appearing simultaneously.

**Root Cause:** Inconsistent spacing logic when color coding was disabled.

**Fix Applied:**
- Checkmark (✓) and cross (✗) now display consistently
- Color codes only wrap item names, not status icons  
- Proper 3-space alignment when no status shown
- Fixed bug where cross didn't show when colorCode=false

**Testing:** ✅ Both owned and unowned items display correctly

---

## 📊 Database Statistics

| Metric | Value |
|--------|-------|
| **Total Combat Pets** | 2,174 |
| **With Descriptions** | 2,173 (99.95%) |
| **Correctly Empty** | 1 (0.05%) |
| **Unique Icons** | 9 types |
| **Database Size** | ~3.9 MB (optimized) |

### Icon Coverage
1. Ability_Hunter_BeastCall - Beastmaster's Whistle (most common)
2. inv_glyph_primedeathknight - Blood Soaked Vellum
3. inv_misc_horn_01 - Draconic Warhorn
4. inv_misc_uncutgemnormal1 - Summoner's Stone
5. custom_T_Nhance_RPG_Icons_ArcaneStone_Border - Elemental Lodestone (Arcane)
6. custom_T_Nhance_RPG_Icons_IceStone_Border - Elemental Lodestone (Frost)
7. custom_T_Nhance_RPG_Icons_NatureStone_Border - Elemental Lodestone (Nature)
8. custom_T_Nhance_RPG_Icons_FireStone_Border - Elemental Lodestone (Fire)
9. custom_T_Nhance_RPG_Icons_GhostStone_Border - Elemental Lodestone (Shadow)

---

## 🎮 Usage Examples

### Basic Usage
Simply mouse over any creature that drops vanity items:

```
Deepmoss Venomsplitter
Level 19 Beast
Blood Feeders
- Deepmoss Venomsplitter slain: 7/7

Vanity Items:
✓  [Whistle Icon] Beastmaster's Whistle: Deepmoss Venomsplitter
```

### Configuration
```bash
/av learned     # Toggle owned/unowned indicators
/av color       # Toggle green/yellow color coding
/av debug       # Enable detailed logging
```

---

## 🐛 Known Issues

### Current Limitations
- ❌ **Regional information:** VanityDB_Regions.lua removed (will be re-implemented in v2.1)
- ℹ️ **API dependency:** Learned status requires Ascension's C_VanityCollection API
- ℹ️ **Custom icons:** Some Ascension-specific icons may not display on all clients

### Reporting Issues
Please report bugs on GitHub: https://github.com/CTOUT/AscensionVanity/issues

Include:
- WoW version and Ascension launcher version
- Addon version (v2.0.0-beta)
- Steps to reproduce
- Screenshots if visual bug
- Any error messages from `/console scriptErrors 1`

---

## 📝 Full Changelog

### Added
- ✨ Icon display in creature tooltips
- ✨ Learned status tracking with visual indicators (✓/✗)
- ✨ Color-coded tooltip text (green=owned, yellow=unowned)
- ✨ Debug mode for diagnostics (`/av debug`)
- ✨ GitHub Copilot repository instructions
- ✨ Comprehensive testing documentation

### Fixed
- 🐛 Icons not displaying in tooltips (missing Interface\\Icons\\ path)
- 🐛 Double tick/cross artifact bug
- 🐛 Inconsistent learned status display
- 🐛 Color coding not wrapping properly
- 🐛 Unicode character handling in descriptions

### Changed
- ♻️ Consolidated icon index into VanityDB.lua (removed IconIndex.lua)
- ♻️ Optimized database structure (saved ~140KB)
- ♻️ Reorganized repository (68% script reduction)
- ♻️ Archived 43 obsolete/superseded scripts
- ♻️ Updated documentation structure

### Removed
- 🗑️ IconIndex.lua (consolidated into VanityDB.lua)
- 🗑️ VanityDB_Regions.lua (temporarily removed, will return in v2.1)
- 🗑️ 43 obsolete scripts (moved to utilities/archive/)

---

## 🔮 Coming in v2.1

### Planned Features
- 🗺️ **Regional Information:** Re-implement zone/location display
- 🔍 **Search Functionality:** Find items by name or creature
- ⚙️ **Configuration UI:** In-game settings panel
- 📊 **Collection Statistics:** Track your collection progress
- 🎨 **Custom Themes:** Configurable tooltip colors and styles

### Under Consideration
- 🏆 **Achievement Integration:** Track collection milestones
- 📱 **Export Functionality:** Share your collection
- 🔔 **Drop Notifications:** Alert when you get a new vanity item
- 📈 **Analytics:** Most common drops, rarest items, etc.

---

## 🙏 Credits

### Development
- **CMTout** - Project lead, database curation, automation

### Data Sources
- **db.ascension.gg** - Primary creature and item data
- **Wowhead WOTLK** - Fallback location information
- **Ascension Community** - Testing and feedback

### Special Thanks
- GitHub Copilot - AI-assisted development
- Project Ascension - Awesome custom content
- WoW Modding Community - Inspiration and tools

---

## 📄 License

MIT License - See [LICENSE](https://github.com/CTOUT/AscensionVanity/blob/main/LICENSE) file for details.

---

## 🔗 Links

- **GitHub Repository:** https://github.com/CTOUT/AscensionVanity
- **Issue Tracker:** https://github.com/CTOUT/AscensionVanity/issues
- **Latest Releases:** https://github.com/CTOUT/AscensionVanity/releases
- **Changelog:** https://github.com/CTOUT/AscensionVanity/blob/main/CHANGELOG.md

---

**Thank you for beta testing AscensionVanity v2.0!** 🚀

Your feedback helps make this addon better for everyone. If you encounter any issues or have suggestions, please open an issue on GitHub.

Happy collecting! ✨
