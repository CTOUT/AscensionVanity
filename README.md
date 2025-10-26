# AscensionVanity - Vanity Item Tracker

[![Coverage](https://img.shields.io/badge/Coverage-96.7%25-brightgreen)](docs/analysis/SKIPPED_ITEMS_ANALYSIS.md)
[![Items](https://img.shields.io/badge/Items-2032%2F2101-blue)](docs/analysis/SKIPPED_ITEMS_ANALYSIS.md)
[![Version](https://img.shields.io/badge/Version-1.0.0-orange)](AscensionVanity/AscensionVanity.toc)

## Overview

AscensionVanity is a World of Warcraft addon for **Project Ascension** that enhances creature tooltips by displaying which vanity items (Beastmaster Whistles, Summoner Stones, etc.) they can drop.

**Current Status**: ✅ **Production Ready** - 96.7% database coverage (2,032 of 2,101 items)

## Features

### ✨ Current Features
- **Creature Tooltip Enhancement**: Shows vanity items when mousing over creatures
- **Smart Detection**: Identifies creatures by name and validates drop sources
- **Comprehensive Database**: 2,032 vanity items from all 5 categories
- **Visual Indicators**: Color-coded display (when learned status detection is available)
- **Toggleable Options**: Enable/disable via slash commands
- **Lightweight**: Minimal performance impact

### � Database Coverage

| Category | Coverage | Notes |
|----------|----------|-------|
| **Beastmaster's Whistle** | 97.8% | Excellent |
| **Blood Soaked Vellum** | 96.4% | Excellent |
| **Summoner's Stones** | 96.3% | Excellent |
| **Draconic Warhorns** | 96.0% | Excellent |
| **Elemental Lodestones** | 96.3% | Excellent |

See [Coverage Analysis](docs/analysis/SKIPPED_ITEMS_ANALYSIS.md) for details on the 69 skipped items.

## Installation

1. **Download** or clone this repository
2. **Copy** the `AscensionVanity` folder to:
   ```
   World of Warcraft\Interface\AddOns\AscensionVanity\
   ```
3. **Restart** WoW or reload UI (`/reload`)
4. The addon loads automatically

## Usage

### Basic Usage

Mouse over any creature in-game. If it drops vanity items, you'll see:

```
[Creature Name]
Level XX Type

Vanity Items:
• Beastmaster's Whistle: Savannah Patriarch
• Blood Soaked Vellum: Savannah Prowler
```

### Slash Commands

- `/av` or `/av toggle` - Enable/disable addon
- `/av learned` - Toggle learned status display (requires API detection)
- `/av color` - Toggle color coding
- `/av help` - Show help menu

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

Found a boss that drops a vanity item but it's not showing in tooltips?

1. Check [TODO: Future Investigations](docs/guides/TODO_FUTURE_INVESTIGATIONS.md) to see if it's already documented
2. Defeat the boss and verify the drop
3. Report it with:
   - Boss name and location
   - Item name
   - Screenshot of drop or loot table

## Credits

- **Author**: CMTout
- **Data Source**: [Project Ascension Database](https://db.ascension.gg)
- **Extraction Tool**: PowerShell with intelligent validation
- **Coverage**: 96.7% (2,032 items)

## License

This addon is provided as-is for use with Project Ascension.

---

**Last Updated**: October 26, 2025  
**Database Version**: 1.0.0  
**Coverage**: 96.7% (2,032/2,101 items)
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
