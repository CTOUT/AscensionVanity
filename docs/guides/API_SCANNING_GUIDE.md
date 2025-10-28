# API Scanning Guide - In-Game Data Collection

## Overview

The AscensionVanity addon now includes **in-game API scanning** to capture fresh vanity item data directly from the game. This allows you to refresh your database when Ascension adds new items or makes changes.

## 🎯 When to Use API Scanning

**Use the API scan when:**
- 🆕 Ascension adds new vanity items to the game
- 🔄 Item data has been updated (names, descriptions, creature IDs)
- 🐛 You suspect the database has incorrect or outdated information
- ✨ You want a complete fresh dataset from the current game state

**Don't need scanning when:**
- ✅ You just want to use the addon's tooltip features
- ✅ The database is current and working well
- ✅ You're only making cosmetic changes to descriptions

## 📋 Complete Workflow

### Step 1: In-Game Scanning

1. **Launch Ascension WoW**
2. **Log in** to any character
3. **Open the scan UI** using one of these methods:

   **Method A: Slash Command**
   ```
   /avscan ui
   ```

   **Method B: Minimap Button** (if available)
   - Click the AscensionVanity minimap button
   - Select "Open API Scanner"

4. **Start the Scan**
   - Click "Start Full Scan" button
   - OR use command: `/avscan scan`

5. **Wait for Completion**
   - Watch the progress bar
   - Takes 2-5 minutes depending on server response
   - You'll see messages like:
     ```
     [AscensionVanity] Scanning vanity items...
     [AscensionVanity] Progress: 500/2500 items (20%)
     [AscensionVanity] Scan complete! Found 2,500 items.
     ```

6. **Exit WoW Completely**
   - This saves the data to `AscensionVanity_Dump.lua`
   - MUST exit fully (not just /reload)

### Step 2: Locate the Dump File

**File Location:**
```
D:\OneDrive\Warcraft\WTF\Account\<your-account>\SavedVariables\AscensionVanity_Dump.lua
```

**Example Path:**
```
D:\OneDrive\Warcraft\WTF\Account\CHRIS-TOUT@OUTLOOK.COM\SavedVariables\AscensionVanity_Dump.lua
```

**File Size:**
- Typically 6-8 MB
- Contains data for ~2,500 vanity items

### Step 3: Copy Dump to Repository

**Copy the file:**
```powershell
# Replace <your-account> with your actual account name
Copy-Item "D:\OneDrive\Warcraft\WTF\Account\<your-account>\SavedVariables\AscensionVanity_Dump.lua" `
          -Destination "D:\Repos\AscensionVanity\data\AscensionVanity_Dump.lua"
```

**Verify the copy:**
```powershell
Get-Item "data\AscensionVanity_Dump.lua" | Select-Object Name, Length, LastWriteTime
```

### Step 4: Process the Dump

**Run the processing script:**
```powershell
.\utilities\ProcessAPIDump.ps1
```

**What it does:**
- ✅ Validates the dump file
- ✅ Converts to standard format
- ✅ Creates `data\AscensionVanity.lua` (used by other utilities)
- ✅ Shows metadata (scan date, item count, version)

**Expected output:**
```
========================================
Process API Dump
========================================

Reading dump file: data\AscensionVanity_Dump.lua

Dump Metadata:
  Last Scan: 2025-10-28 10:45:32
  Total Items: 2,500
  Scan Version: 2.0.0

Transforming to standard format...
Writing to: data\AscensionVanity.lua

✅ Dump processing complete!
```

### Step 5: Analyze the Data

**Run detailed analysis:**
```powershell
.\utilities\AnalyzeAPIDump.ps1 -Detailed
```

**Review the results:**
- Total items by category
- Items with empty descriptions
- Validation status
- Potential issues

### Step 6: Enrich Empty Descriptions

**Run web scraping validation:**
```powershell
.\utilities\ValidateAndEnrichEmptyDescriptions.ps1 -DelayMs 2000
```

**What it does:**
- ✅ Finds items with empty descriptions
- ✅ Validates drop sources via Ascension DB
- ✅ Extracts creature names and regions
- ✅ Generates descriptive text
- ✅ Creates `data\EmptyDescriptions_Validated.json`

### Step 7: Generate Database

**Create the final database files:**
```powershell
.\utilities\GenerateVanityDB_V2.ps1
```

**What it creates:**
- ✅ `AscensionVanity\VanityDB.lua` - Main item database
- ✅ `AscensionVanity\VanityDB_Regions.lua` - Location data
- ✅ Includes validated descriptions from Step 6

### Step 8: Deploy & Test

**Deploy to WoW:**
```powershell
.\DeployAddon.ps1 -WoWPath 'D:\OneDrive\Warcraft'
```

**Test in-game:**
1. Launch WoW
2. Type `/reload` to reload UI
3. Hover over a vanity item
4. Verify tooltip shows correct information

## 🔧 Slash Commands Reference

### Scanning Commands

```lua
/avscan help              -- Show all available commands
/avscan ui                -- Open the scan UI panel
/avscan scan              -- Start full API scan
/avscan status            -- Show current scan progress
/avscan cancel            -- Cancel ongoing scan
```

### Data Management Commands

```lua
/avscan clear             -- Clear all scan data (with confirmation)
/avscan info              -- Show dump file information
/avscan export <filename> -- Export to custom filename
```

### Debug Commands

```lua
/avscan debug on          -- Enable debug logging
/avscan debug off         -- Disable debug logging
/avscan test              -- Test API access
```

## 🎛️ UI Panel Features

**Access the panel:**
- `/avscan ui`
- Or click minimap button → "Open API Scanner"

**Panel features:**
- 📊 **Progress Bar** - Visual scan progress
- 📈 **Statistics** - Items scanned, time elapsed
- 🎯 **Quick Actions**
  - Start Full Scan
  - Clear Data
  - Export Results
- ℹ️ **Status Display**
  - Current operation
  - Last scan date
  - Total items in database

## 🔍 Troubleshooting

### Scan Not Starting

**Problem**: Click "Start Scan" but nothing happens

**Solutions:**
1. Check for Lua errors: `/console scriptErrors 1`
2. Verify addon is loaded: `/av help`
3. Try command instead: `/avscan scan`
4. Reload UI: `/reload`

### Scan Freezing/Hanging

**Problem**: Progress bar stuck, game unresponsive

**Solutions:**
1. Wait 30 seconds (server may be slow)
2. Cancel scan: `/avscan cancel`
3. Check debug log: `/avscan debug on`
4. Restart scan with smaller batches

### Dump File Not Created

**Problem**: Exit WoW but no `AscensionVanity_Dump.lua` file

**Solutions:**
1. Verify you FULLY exited WoW (not just character select)
2. Check the correct SavedVariables folder
3. Look for errors in WoW error log
4. Verify addon has write permissions

### Dump File is Empty/Small

**Problem**: File exists but only a few KB

**Solutions:**
1. Scan may not have completed - check `/avscan status`
2. Re-run the scan: `/avscan clear` then `/avscan scan`
3. Check for Lua errors during scan

### ProcessAPIDump.ps1 Errors

**Problem**: Script can't find or process dump file

**Solutions:**
1. Verify file location: `Get-Item "data\AscensionVanity_Dump.lua"`
2. Check file isn't locked: Close WoW completely
3. Verify file format: Open in text editor, should start with `AscensionVanityDump = {`
4. Re-copy from SavedVariables folder

## 📊 Data File Structure

### AscensionVanity_Dump.lua Format

```lua
AscensionVanityDump = {
    ["Metadata"] = {
        ["LastScanDate"] = "2025-10-28 10:45:32",
        ["TotalItems"] = 2500,
        ["ScanVersion"] = "2.0.0",
        ["ScanDuration"] = 180,  -- seconds
    },
    ["APIDump"] = {
        -- Item data from API
        [1] = {
            ["itemId"] = 1843,
            ["name"] = "Strigid Owl (Beastmaster's Whistle)",
            ["description"] = "",
            ["creaturePreview"] = 7553,
            -- ... more fields
        },
        -- ... more items
    },
    ["ValidationResults"] = {
        -- API to DB item ID mappings
        [1] = {
            ["apiItem"] = 1843,
            ["dbItem"] = 79666,
            ["isValid"] = true,
        },
        -- ... more validations
    }
}
```

## 🎯 Best Practices

### When to Scan

✅ **DO scan when:**
- Ascension releases a major patch
- You notice missing items in tooltips
- Database generation reports missing data
- Every 2-3 months to stay current

❌ **DON'T scan when:**
- Making minor description tweaks
- Testing tooltip display changes
- Database is already current
- Just using the addon casually

### Scan Performance

**Optimize scan speed:**
- ✅ Scan during off-peak hours (less server load)
- ✅ Use wired connection (not WiFi)
- ✅ Close other programs (reduce system load)
- ✅ Stay in a quiet zone (no combat/distractions)

**Avoid issues:**
- ❌ Don't scan during peak raid times
- ❌ Don't alt-tab during scan
- ❌ Don't move/combat during scan
- ❌ Don't run multiple scans simultaneously

### Data Management

**Keep backups:**
```powershell
# Backup before processing
Copy-Item "data\AscensionVanity_Dump.lua" `
          -Destination "data\backups\AscensionVanity_Dump_$(Get-Date -Format 'yyyyMMdd').lua"
```

**Archive old scans:**
- Keep scans organized by date
- Compare scans to track changes
- Useful for debugging regressions

## 📈 Advanced Usage

### Custom Export Locations

**Export to specific file:**
```lua
/avscan export MyCustomDump
```

**Result:**
- Creates `AscensionVanity_MyCustomDump.lua`
- Same format as standard dump
- Useful for testing/comparison

### Incremental Scans (Future Feature)

**Scan only new/changed items:**
```lua
/avscan scan incremental
```

**Benefits:**
- Faster than full scan
- Less server load
- Only updates changed data

### Batch Processing

**Process multiple dumps:**
```powershell
# Process all dumps in data\dumps\ folder
Get-ChildItem "data\dumps\*.lua" | ForEach-Object {
    .\utilities\ProcessAPIDump.ps1 -DumpFile $_.FullName
}
```

## 🔗 Related Documentation

- [Database Generation Pipeline](./DATABASE_PIPELINE.md)
- [Validation Guide](./API_VALIDATION_GUIDE.md)
- [Deployment Guide](./DEPLOYMENT_GUIDE.md)
- [Dev Console Reference](./DEV_CONSOLE_REFERENCE.md)

## 📝 Quick Reference Card

```
┌─────────────────────────────────────────┐
│   AscensionVanity API Scanning          │
├─────────────────────────────────────────┤
│ IN-GAME:                                │
│  /avscan scan      → Start scan         │
│  /avscan ui        → Open UI            │
│  /avscan status    → Check progress     │
│  /avscan clear     → Clear data         │
├─────────────────────────────────────────┤
│ AFTER EXITING WOW:                      │
│  1. Copy AscensionVanity_Dump.lua       │
│  2. .\utilities\ProcessAPIDump.ps1      │
│  3. .\utilities\AnalyzeAPIDump.ps1      │
│  4. .\utilities\ValidateAndEnrich...    │
│  5. .\utilities\GenerateVanityDB_V2.ps1 │
│  6. .\DeployAddon.ps1                   │
├─────────────────────────────────────────┤
│ DUMP LOCATION:                          │
│  WTF\Account\<you>\SavedVariables\      │
│  AscensionVanity_Dump.lua               │
└─────────────────────────────────────────┘
```
