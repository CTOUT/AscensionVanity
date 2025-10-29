# AscensionVanity - Combat Pet Tracker

[![Coverage](https://img.shields.io/badge/Description_Coverage-99.95%25-brightgreen)](DESCRIPTION_ENRICHMENT_FINAL_REPORT.md)
[![Items](https://img.shields.io/badge/Combat_Pets-2,174-blue)](AscensionVanity/VanityDB.lua)
[![Version](https://img.shields.io/badge/Version-2.0--dev-orange)](AscensionVanity/AscensionVanity.toc)
[![Automation](https://img.shields.io/badge/Workflow-95%25_Automated-success)](utilities/MasterDescriptionEnrichment.ps1)

## Overview

AscensionVanity is a World of Warcraft addon for **Project Ascension** that helps players track **combat pet taming items** by enhancing creature tooltips to display which vanity items they can drop.

**Primary Focus**: 🐾 **Combat Pet Items** - All 2,174 combat pets available in Ascension  
**Vanity Types**: Beastmaster's Whistle, Blood Soaked Vellum, Summoner's Stone, Draconic Warhorn, Elemental Lodestone

**Current Status**: ✅ **99.95% Complete** - 2,173 items with descriptions (1 correctly blank)  
**Workflow**: 🤖 **95% Automated** - Master enrichment script handles everything

## Features

### ✨ Current Features

- **Creature Tooltip Enhancement**: Shows vanity items when mousing over creatures
- **Smart Detection**: Identifies creatures by NPC ID with location descriptions
- **Comprehensive Database**: 2,174 combat pets with 99.95% description coverage
- **Visual Indicators**: Clean, informative tooltip display
- **Toggleable Options**: Enable/disable via slash commands
- **Lightweight**: Minimal performance impact

### � Database Quality

| Metric | Status | Notes |
|--------|--------|-------|
| **Total Combat Pets** | 2,174 | Complete Ascension database |
| **With Descriptions** | 2,173 (99.95%) | Excellent coverage |
| **Empty (Correct)** | 1 (0.05%) | Captain Claws (NPC doesn't exist) |
| **Description Sources** | db.ascension.gg + Wowhead WOTLK | Multi-source validation |

### 🤖 Automated Workflow

The project includes a fully automated enrichment workflow:

**Master Script**: `utilities/MasterDescriptionEnrichment.ps1`

- **95-97% Automation**: Only 3-5% need manual research
- **Multi-Source Search**: db.ascension.gg (primary) + Wowhead WOTLK (fallback)
- **Safe Updates**: Pattern matching + dry-run mode
- **Comprehensive Reporting**: CSV, JSON, and manual research lists

**Run anytime**: Simply execute the master script to find and enrich any empty descriptions automatically.

See [Master Enrichment Workflow](docs/MASTER_ENRICHMENT_WORKFLOW.md) for complete documentation.

## Installation

1. **Download** or clone this repository
2. **Copy** the `AscensionVanity` folder to:

   ```text
   World of Warcraft\Interface\AddOns\AscensionVanity\
   ```

3. **Restart** WoW or reload UI (`/reload`)
4. The addon loads automatically

## Usage

### Basic Usage

Mouse over any creature in-game. If it drops combat pet vanity items, you'll see:

```text
[Creature Name]
Level XX Type

Vanity Items:
• Beastmaster's Whistle: Savannah Patriarch
• Summoner's Stone: Savannah Prowler
  Found in Barrens (Southern Barrens)
```

### Slash Commands

#### Basic Commands

- `/av` or `/av toggle` - Enable/disable addon
- `/av status` - Show current addon status
- `/av help` - Display help information
- `/av help` - Show help menu

#### Database Validation (NEW in v2.1)
- `/av apidump` - Extract complete API data to SavedVariables
- `/av validate` - Compare API data vs static database
- `/av api` - Scan for available Ascension vanity APIs
- `/av dump` - Dump vanity collection data structure
- `/av dumpitem <itemID>` - Search for specific item in API data

See [API Validation Guide](docs/guides/API_VALIDATION_GUIDE.md) for complete validation workflow.

### Database Validation System (v2.1)

The addon now includes a comprehensive validation system using Ascension's official `C_VanityCollection` API:

**Quick Validation Workflow**:
1. In-game: `/av apidump` → Wait for completion
2. Type: `/reload` → Save data
3. Type: `/av validate` → Review results
4. PowerShell: `.\utilities\AnalyzeAPIDump.ps1` → Detailed analysis

**Purpose**: 
- ✅ Validate static database against official API
- ✅ Find missing items (the 144 items not in our database)
- ✅ Fix incorrect mappings inherited from web scraping
- ✅ Generate automated database updates

**Documentation**:
- [API Validation Guide](docs/guides/API_VALIDATION_GUIDE.md) - Complete step-by-step process
- [Quick Reference](docs/guides/API_QUICK_REFERENCE.md) - Command cheat sheet
- [Testing Checklist](docs/TESTING_CHECKLIST.md) - First-time testing guide

## Project Structure

```
AscensionVanity/
├── AscensionVanity/          # Addon files (install this folder)
│   ├── AscensionVanity.toc   # Addon metadata
│   ├── Core.lua              # Main addon logic
│   └── VanityDB.lua  # Auto-generated database
├── docs/                     # Documentation
│   ├── analysis/             # Data analysis reports
│   │   ├── SKIPPED_ITEMS_ANALYSIS.md
│   │   ├── SPOT_CHECK_ANALYSIS.md
│   │   └── VENDOR_ITEM_DISCOVERY.md
│   ├── guides/               # User guides
│   │   ├── EXTRACTION_GUIDE.md
│   │   ├── README_DOCUMENTATION.md
│   │   └── TODO_FUTURE_INVESTIGATIONS.md
│   └── archive/              # Archived project documents
├── utilities/                # Development scripts
│   ├── AnalyzeSourceCodes.ps1
│   ├── CountByCategory.ps1
│   ├── DiagnoseMissingItems.ps1
│   ├── DiagnoseSourcemore.ps1
│   └── ExtractDatabaseVerbose.ps1
├── ExtractDatabase.ps1       # Main extraction script
└── README.md                 # This file
```

## Development

### Testing the Addon

Deploy the addon to your WoW AddOns folder for in-game testing:

```powershell
# Deploy once (copies files to WoW)
.\DeployAddon.ps1

# Deploy and watch for changes (auto-deploys on file save)
.\DeployAddon.ps1 -Watch

# Force re-deploy all files
.\DeployAddon.ps1 -Force

# Deploy to custom WoW path
.\DeployAddon.ps1 -WoWPath "C:\Games\WoW\Interface\AddOns"
```

After deployment:
1. Launch World of Warcraft
2. Type `/reload` to reload UI
3. Type `/av help` to verify addon loaded

### Database Extraction

The database is automatically generated from the Project Ascension database:

```powershell
# Extract fresh data (bypasses cache)
.\ExtractDatabase.ps1 -Force

# Use cached data (default)
.\ExtractDatabase.ps1

# Verbose output
.\ExtractDatabase.ps1 -Verbose
```

**Data Source**: https://db.ascension.gg/?items=101

### Key Features of Extraction Script

✅ **Intelligent Validation**: Only includes items with verified drop sources  
✅ **Caching System**: Reduces API calls and speeds up re-runs  
✅ **Comprehensive Comments**: Explains edge cases and known limitations  
✅ **Error Reporting**: Detailed validation error tracking  

### Known Limitations

The 69 skipped items fall into these categories:

1. **Vendor Items** (20 items) - Purchased from NPCs, not dropped
2. **Token Exchange** (Not counted separately) - Exchanged for tokens
3. **Event Exclusive** (1 item) - Manastorm event reward
4. **Boss Drops Needing Verification** (9 items) - Need manual confirmation
5. **Duplicates/Unobtainable** (10 items) - Database inconsistencies

See [TODO: Future Investigations](docs/guides/TODO_FUTURE_INVESTIGATIONS.md) for items needing verification.

## Documentation

### For Users
- **[README (this file)](README.md)** - Quick start guide
- **[Documentation Guide](docs/guides/README_DOCUMENTATION.md)** - Complete documentation overview

### For Developers
- **[Extraction Guide](docs/guides/EXTRACTION_GUIDE.md)** - How to update the database
- **[Skipped Items Analysis](docs/analysis/SKIPPED_ITEMS_ANALYSIS.md)** - Why items are missing
- **[Future Investigations](docs/guides/TODO_FUTURE_INVESTIGATIONS.md)** - Items to verify
- **[Vendor Discovery](docs/analysis/VENDOR_ITEM_DISCOVERY.md)** - How vendor items were identified

### Analysis Reports
- **[Spot Check Analysis](docs/analysis/SPOT_CHECK_ANALYSIS.md)** - Manual verification results
- **Coverage Statistics**: 96.7% (2,032/2,101 items) ✅ Excellent

## Pending Features

### ⏳ Learned Status Detection
- **Status**: Placeholder implemented
- **Blocker**: Need Project Ascension API for checking learned vanity items
- **Current**: `IsVanityItemLearned()` returns `nil` (unknown status)
- **Next Steps**: Research Ascension's collection API or addon communication methods

## Contributing

Found a combat pet vanity item that's missing or has incorrect information?

1. Check the [Issue Tracker](https://github.com/CTOUT/AscensionVanity/issues) to see if it's already documented
2. Verify the creature and drop in-game
3. Report it with:
   - NPC ID and name
   - Item name and type
   - Location/zone information
   - Screenshot of drop or loot table

## Credits

- **Author**: CMTout
- **Data Source**: [Project Ascension Database](https://db.ascension.gg) + Wowhead WOTLK
- **Extraction Tool**: PowerShell with automated enrichment workflow
- **Database Coverage**: 99.95% (2,173/2,174 combat pets with descriptions)

## License

This addon is provided as-is for use with Project Ascension.

---

**Last Updated**: October 29, 2025  
**Version**: 2.0-dev  
**Database**: 2,174 combat pets | 99.95% description coverage  
**Automation**: Master enrichment workflow with 95-97% automation
- Observer
- Doomguard
- Nathrezim (Dreadlord)
- Mo'arg Engineer
- Void Terror
- Abyssal
- Gan'arg
- Fel Beast

## Troubleshooting

### Addon doesn't load
- Check that all three files (.toc, VanityData.lua, Core.lua) are present
- Verify the folder name is exactly `AscensionVanity`
- Check for Lua errors using `/console scriptErrors 1`

### No vanity items showing in tooltips
- Verify addon is enabled with `/av`
- Check if the creature is in the database (currently limited dataset)
- Try the debug function: `/run AV_Debug("CreatureName", "CreatureType")`

### Learned status not showing
- This feature requires Ascension-specific API implementation
- Currently displays all items as unknown status (no checkmark)

## Contributing

### Adding More Vanity Items
To expand the database:

1. Extract items from https://db.ascension.gg/?items=101
2. Add entries to `VanityData.lua`:
   ```lua
   ["Creature Name"] = {
       itemID = 12345,  -- If known
       itemName = "Summoner's Stone: Creature Name",
       type = "Creature Type"
   }
   ```
3. For generic drops, add to type-based lists:
   ```lua
   AV_GenericDropsByType["Creature Type"] = {
       "Summoner's Stone: Item1",
       "Summoner's Stone: Item2",
   }
   ```

### Implementing Learned Status
If you know the Ascension API for checking learned vanity items:

1. Edit `Core.lua`
2. Find the `IsVanityItemLearned()` function
3. Replace the TODO comment with actual API calls
4. Return `true` if learned, `false` if not learned, `nil` if unknown

Example pattern:
```lua
local function IsVanityItemLearned(itemID, itemName)
    -- Replace with actual Ascension API
    if itemID then
        return AscensionAPI.HasLearnedVanityItem(itemID)
    end
    return nil
end
```

## API Reference

### Public Functions

#### `AV_GetVanityItemsForCreature(creatureName, creatureType)`
Returns a table of vanity items for a given creature.

**Parameters:**
- `creatureName` (string): The creature's name
- `creatureType` (string): The creature's type (e.g., "Terrorfiend")

**Returns:**
- Table of items, each containing:
  - `itemID` (number|nil): Item ID if known
  - `itemName` (string): Full item name
  - `type` (string): Creature type

**Example:**
```lua
local items = AV_GetVanityItemsForCreature("Zarcsin", "Terrorfiend")
for _, item in ipairs(items) do
    print(item.itemName)
end
```

#### `AV_Debug(creatureName, creatureType)`
Debug function to test creature/item lookups.

**Parameters:**
- `creatureName` (string): Creature name to test
- `creatureType` (string): Creature type to test

**Example:**
```lua
/run AV_Debug("Zarcsin", "Terrorfiend")
```

### Saved Variables

The addon stores configuration in `AscensionVanityDB`:
```lua
AscensionVanityDB = {
    enabled = true,              -- Addon enabled/disabled
    showLearnedStatus = true,    -- Show learned status indicators
    colorCode = true,            -- Use color coding
}
```

## Version History

### v1.0.0 (Current)
- Initial release
- Basic tooltip enhancement functionality
- Creature name and type detection
- Sample database with ~50 vanity items
- Slash command interface
- Configuration persistence
- Color-coded display

## Credits

- **Database Source**: Project Ascension (https://db.ascension.gg/)
- **WoW API**: Wowpedia community documentation
- **Development**: Created for Project Ascension community

## License

This addon is provided as-is for the Project Ascension community. Feel free to modify and distribute.

## Support

For issues, suggestions, or contributions:
- Check the Project Ascension forums
- Report bugs with detailed steps to reproduce
- Include your WoW version and addon version

---

**Note**: This addon is specifically designed for Project Ascension and may not work on retail WoW or other private servers without modification.
