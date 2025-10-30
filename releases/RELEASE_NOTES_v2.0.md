# AscensionVanity v2.0 - Stable Release

**Release Date:** October 30, 2025  
**Version:** 2.0  
**Package:** AscensionVanity-v2.0.zip

---

## 🎉 What's New in v2.0

### Database Excellence
- **2,174 Combat Pets** tracked across all Ascension content
- **99.95% Description Coverage** (2,173/2,174 items with descriptions)
- **Comprehensive Location Data** for efficient farming
- **1 Correctly Empty Entry** (Captain Claws - creature doesn't exist)

### Performance & Optimization
- **Smart Caching System** for instant tooltip updates
- **Lazy Loading** for optimized memory usage
- **Consolidated Icon System** (15 unique icons)
- **Event-Driven Architecture** for minimal performance impact

### User Interface
- **Enhanced Tooltips** with better formatting and color coding
- **Settings Panel** for configuration (/av settings)
- **In-Game API Scanner** for data collection
- **Slash Commands** for quick access (/av)

### Developer Tools
- **95% Automated Workflow** for description enrichment
- **Master Enrichment Script** handles end-to-end processing
- **Database Generation** fully automated
- **Comprehensive Documentation** and guides

---

## 📥 Installation

### Fresh Installation
1. Download `AscensionVanity-v2.0.zip`
2. Extract to `World of Warcraft\_retail_\Interface\AddOns\`
3. You should have: `...\Interface\AddOns\AscensionVanity\`
4. Restart WoW or type `/reload`

### Upgrading from Previous Versions
1. **Delete** the old `AscensionVanity` folder
2. Follow fresh installation steps above
3. All learned items and settings will be preserved automatically

---

## 🎮 Usage

### Basic Commands
- `/av` or `/ascensionvanity` - Show help
- `/av toggle` - Enable/disable tooltips
- `/av settings` - Open settings panel

### Tooltip Display
Mouse over any creature to see:
- Combat pet items they can drop
- Item icons and names  
- Location/region information
- Collection status (learned/not learned)

---

## 📊 Statistics

| Metric | Value |
|--------|-------|
| Total Combat Pets | 2,174 |
| With Descriptions | 2,173 (99.95%) |
| Correctly Empty | 1 (0.05%) |
| Unique Icons | 15 |
| Automation Rate | 95% |

---

## 🔧 Technical Details

### Files Included
- `AscensionVanity.toc` - Addon manifest
- `Core.lua` - Main tooltip logic
- `VanityDB.lua` - Combat pets database (2,174 items)
- `VanityDB_Loader.lua` - Database loading & caching
- `AscensionVanityConfig.lua` - Configuration system
- `SettingsUI.lua` - In-game settings panel
- `APIScanner.lua` - API scanning functionality
- `ScannerUI.lua` - Scanner UI components

### Requirements
- World of Warcraft: Wrath of the Lich King (3.3.5)
- Project Ascension server

---

## 🐛 Known Issues

None reported. Please submit issues on GitHub if you encounter problems.

---

## 🙏 Acknowledgments

- **Data Sources:** db.ascension.gg, Wowhead WotLK
- **Project Ascension Team** for the amazing server
- **Community Members** who helped validate data
- **Beta Testers** who provided valuable feedback

---

## 🔗 Links

- **GitHub Repository:** https://github.com/CTOUT/AscensionVanity
- **Issue Tracker:** https://github.com/CTOUT/AscensionVanity/issues
- **Feature Roadmap:** See FEATURE_ROADMAP_V2.1.md in repository

---

## 📜 Changelog

See [CHANGELOG.md](https://github.com/CTOUT/AscensionVanity/blob/main/CHANGELOG.md) for detailed version history.

---

**Thank you for using AscensionVanity!** 🐾

For questions, suggestions, or issues, please visit our GitHub repository.
