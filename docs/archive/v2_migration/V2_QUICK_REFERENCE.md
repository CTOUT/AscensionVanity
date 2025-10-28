# V2.0 Quick Reference

## What Changed?

### ✅ New Files
- `AscensionVanityConfig.lua` - User settings
- `VanityDB_Loader.lua` - Database access functions
- `VanityDB_Regions.lua` - Location data

### 🔄 Updated Files
- `VanityDB.lua` - Now uses rich data format
- `Core.lua` - Supports region display
- `AscensionVanity.toc` - New load order

### 📊 Coverage
- **Old**: 1,857 items
- **New**: 2,047 items (+10.2%)

## New Features

### Region Display
Tooltips now show where creatures spawn:
```
Vanity Items:
  ✓ Beastmaster's Whistle: Mine Spider
      Location: Jasperlode Mine
```

### Configuration Options
```lua
AscensionVanityDB = {
    enabled = true,              -- Enable addon
    colorCode = true,            -- Color tooltips
    showLearnedStatus = true,    -- Show ✓/✗ icons
    showRegions = true,          -- Show locations (NEW)
    debug = false                -- Debug logging
}
```

## File Structure
```
AscensionVanity/
  AscensionVanity.toc          -- Load order definition
  AscensionVanityConfig.lua    -- Settings initialization
  VanityDB.lua                 -- Item database (619 KB)
  VanityDB_Regions.lua         -- Region data (142 KB)
  VanityDB_Loader.lua          -- Access functions
  Core.lua                     -- Tooltip hooks
```

## Load Order
1. Config (sets defaults)
2. Database files (data)
3. Loader (functions)
4. Core (display logic)

## Testing Checklist
- [ ] Addon loads without errors
- [ ] Tooltips show vanity items
- [ ] Regions display correctly
- [ ] Icons appear
- [ ] Settings persist
- [ ] Performance is acceptable

## Deployment
```powershell
.\DeployAddon.ps1 -WoWPath "C:\Path\To\WoW"
```

Then in-game: `/reload`

---

**Version**: 2.0.0  
**Status**: Ready for testing  
**Date**: October 27, 2025
