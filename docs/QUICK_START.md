# Quick Start Guide

## Installation

1. **Download** the AscensionVanity addon
2. **Extract** to your WoW Addons folder:
   ```
   <WoW Directory>\Interface\AddOns\AscensionVanity\
   ```
3. **Restart** World of Warcraft
4. **Enable** the addon in the addon list

## Basic Usage

### In-Game Commands

```
/av              - Show available vanity items in your bags
/av show         - Display main UI window
/av help         - Show command help
```

### Main Features

- **Bag Scanner**: Automatically detects vanity items in your inventory
- **Database**: Complete list of all vanity items and their drop sources
- **Visual Interface**: Browse items by category with detailed information

## First Time Setup

1. **Login** to your character
2. **Type** `/av` to scan your bags
3. **Click** items in the list to see drop information
4. **Use** `/av show` to browse all available vanity items

## Troubleshooting

### "No vanity items found"
- Make sure you have vanity items in your bags
- Items must be one of: Beastmaster's Whistle, Blood Soaked Vellum, Summoner's Stone, Draconic Warhorn, or Elemental Lodestone

### Database seems outdated
- Run the PowerShell extraction script to update:
  ```powershell
  .\ExtractDatabase.ps1
  ```
- This will fetch the latest data from Project Ascension database

### Addon not loading
- Check that the folder name is exactly `AscensionVanity`
- Verify all files are present (see FOLDER_STRUCTURE.md)
- Enable Lua errors to see any load issues

## Need Help?

- See **USAGE_GUIDE.md** for detailed feature documentation
- Check **FOLDER_STRUCTURE.md** to understand the project organization
- Review **CHANGELOG.md** for recent updates and known issues

## Contributing

Want to help improve AscensionVanity?
- Report bugs or suggest features
- Test the database extraction script
- Help verify drop sources (see TODO_FUTURE_INVESTIGATIONS.md)
