# AscensionVanity v2.0 Release Notes

**Release Date:** October 30, 2025  
**Version:** 2.0 (Stable)  
**Branch:** main

---

## 🎉 Overview

Version 2.0 represents the **stable release** of AscensionVanity with comprehensive combat pet tracking, exceptional description coverage, and a fully automated workflow for database maintenance.

---

## ✨ Key Achievements

### Database Excellence
- **2,174 Combat Pets** tracked across all Ascension content
- **99.95% Description Coverage** (2,173/2,174 items with descriptions)
- **1 Correctly Empty**: Captain Claws (creature doesn't exist in game)
- **Comprehensive Location Data**: Region information for efficient farming

### Automation Success
- **95% Automated Workflow** for description enrichment
- **Master Enrichment Script** handles end-to-end processing
- **Automated Database Generation** from JSON to Lua
- **Quality Validation** with comprehensive reporting

### Technical Foundation
- **Optimized Icon System**: Consolidated 15 unique icons with efficient indexing
- **Smart Caching**: Performance-optimized database loading
- **Event-Driven Architecture**: Efficient tooltip enhancement system
- **Clean Codebase**: Well-organized, documented, maintainable code

---

## 🔧 Features

### Core Functionality
✅ **Creature Tooltip Enhancement** - Shows vanity items when mousing over creatures  
✅ **Smart NPC Detection** - Accurate creature identification by NPC ID  
✅ **Location Information** - Region/zone data for efficient farming  
✅ **Visual Indicators** - Clean, informative tooltip display  
✅ **Toggleable Options** - Enable/disable via slash commands  
✅ **Lightweight Performance** - Minimal impact on game performance  

### Data Quality
✅ **99.95% Description Coverage** - Only 1 correctly empty entry  
✅ **Multi-Source Enrichment** - db.ascension.gg + Wowhead + manual research  
✅ **Validated Accuracy** - Comprehensive testing and verification  
✅ **Consistent Formatting** - Standardized location descriptions  

### Developer Tools
✅ **Automated Enrichment Pipeline** - Master script handles everything  
✅ **Database Generation** - JSON to Lua conversion with validation  
✅ **Comparison Tools** - Fresh scan vs. existing data analysis  
✅ **Documentation** - Comprehensive guides and references  

---

## 📊 Database Statistics

| Metric | Value |
|--------|-------|
| Total Combat Pets | 2,174 |
| With Descriptions | 2,173 (99.95%) |
| Correctly Empty | 1 (0.05%) |
| Unique Icons | 15 |
| Automation Rate | 95% |

---

## 🗂️ Project Structure

```
AscensionVanity/
├── AscensionVanity/          # Addon files
│   ├── Core.lua              # Main tooltip logic
│   ├── VanityDB.lua          # 2,174 combat pets database
│   ├── VanityDB_Loader.lua   # Database loading & caching
│   ├── AscensionVanityConfig.lua  # Configuration & defaults
│   ├── SettingsUI.lua        # In-game settings panel
│   ├── APIScanner.lua        # In-game creature scanning
│   └── ScannerUI.lua         # Scanner UI components
├── utilities/                 # Automation scripts
│   ├── MasterDescriptionEnrichment.ps1  # Master enrichment
│   ├── GenerateVanityDB.ps1  # Database generation
│   └── CompareScans.ps1      # Scan comparison
├── data/                      # Source data files
│   └── API_to_GameID_Mapping.json  # Master database
└── docs/                      # Documentation
```

---

## 🚀 Installation

1. Download `AscensionVanity.zip` from releases
2. Extract to `World of Warcraft\Interface\AddOns\`
3. Restart WoW or reload UI with `/reload`
4. Type `/av` or `/ascensionvanity` for help

---

## 🎯 Usage

### Basic Commands
- `/av` or `/ascensionvanity` - Show help
- `/av toggle` - Enable/disable tooltips
- `/av settings` - Open settings panel

### Tooltip Display
Mouse over any creature to see:
- Vanity items they can drop
- Item icons and names
- Location/region information (if available)
- Collection status (learned/not learned)

---

## 🛠️ Development Workflow

### Description Enrichment (95% Automated)
```powershell
# Single command handles everything:
.\utilities\MasterDescriptionEnrichment.ps1

# Outputs:
# - Updated JSON with descriptions
# - Comprehensive CSV reports
# - Manual research needed list
# - Validation results
```

### Database Generation (100% Automated)
```powershell
.\utilities\GenerateVanityDB.ps1

# Generates optimized VanityDB.lua with:
# - Consolidated icon index
# - Efficient data structures
# - Validation checks
```

---

## 📝 Known Issues

### Minor Issues
- **Captain Claws** - Correctly has no description (creature doesn't exist)

### Future Enhancements
- See [FEATURE_ROADMAP_V2.1.md](docs/archive/FEATURE_ROADMAP_V2.1.md) for planned features:
  - Auction House integration
  - Regional hunting guide
  - Advanced filtering system
  - Statistics & kill tracking
  - Phase & instance notifications
  - Pet abilities & stats viewer

---

## 🙏 Acknowledgments

### Data Sources
- **db.ascension.gg** - Primary source for item and creature data
- **Wowhead WotLK** - Fallback source for missing descriptions
- **Community** - Manual research and validation assistance

### Special Thanks
- Project Ascension team for the amazing server
- Community members who helped validate data
- Beta testers who provided feedback

---

## 📄 License

This addon is provided as-is for the Project Ascension community. Feel free to use, modify, and share.

---

## 🔗 Links

- **GitHub Repository**: https://github.com/CTOUT/AscensionVanity
- **Issue Tracker**: https://github.com/CTOUT/AscensionVanity/issues
- **Feature Requests**: https://github.com/CTOUT/AscensionVanity/discussions

---

## 🎊 What's Next?

Version 2.1 development begins with focus on:
- Advanced filtering and search capabilities
- Regional hunting guides
- Auction house integration
- Enhanced statistics tracking

See [FEATURE_ROADMAP_V2.1.md](docs/archive/FEATURE_ROADMAP_V2.1.md) for the complete roadmap.

---

**Thank you for using AscensionVanity!** 🐾
