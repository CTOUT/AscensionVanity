# AscensionVanity - Deployment Guide

**Last Updated:** October 26, 2025

---

## Overview

This guide explains how to deploy the AscensionVanity addon to your WoW AddOns folder for testing and development.

---

## Deployment Script

The `DeployAddon.ps1` script automatically copies the addon files from the repository to your WoW AddOns directory.

### Basic Usage

```powershell
# Deploy once (default location)
.\DeployAddon.ps1

# Deploy to custom location
.\DeployAddon.ps1 -WoWPath "C:\Games\WoW\Interface\AddOns"

# Force re-deploy all files (even if up-to-date)
.\DeployAddon.ps1 -Force
```

### Watch Mode (Auto-Deploy on Changes)

Watch mode automatically deploys the addon whenever you save changes to any file:

```powershell
# Start watching for changes
.\DeployAddon.ps1 -Watch

# Press Ctrl+C to stop watching
```

**Use Case:** Keep this running in a separate terminal while developing. Every time you save a `.lua` file, it automatically copies to WoW.

---

## Default Configuration

**Default WoW Path:** `D:\OneDrive\Warcraft`

To change the default path permanently:
1. Edit `DeployAddon.ps1`
2. Update the `$WoWPath` parameter default value
3. Save the file

---

## Deployment Process

The script performs these steps:

1. **Validates** source folder exists (`AscensionVanity/`)
2. **Validates** destination WoW AddOns folder exists
3. **Creates** destination folder if needed
4. **Copies** all addon files (`.toc`, `.lua`)
5. **Skips** files that are already up-to-date (unless `-Force` is used)
6. **Reports** summary of copied/skipped files

### Smart Copying

The script only copies files that have changed:
- Compares last modified timestamps
- Skips files that are already up-to-date
- Use `-Force` to override and copy everything

---

## Testing Workflow

### Initial Setup

1. Deploy the addon:
   ```powershell
   .\DeployAddon.ps1
   ```

2. Launch World of Warcraft

3. Verify addon loaded:
   ```
   /av help
   ```

### Development Cycle

**Option 1: Manual Deploy**
1. Edit code in VS Code
2. Save file
3. Run `.\DeployAddon.ps1`
4. In WoW, type `/reload`
5. Test changes

**Option 2: Watch Mode (Recommended)**
1. Open a PowerShell terminal
2. Run `.\DeployAddon.ps1 -Watch`
3. Leave it running
4. Edit and save code in VS Code
5. Script auto-deploys changes
6. In WoW, type `/reload`
7. Test changes

---

## Files Deployed

The script deploys these files from `AscensionVanity/`:

| File | Description | Size |
|------|-------------|------|
| `AscensionVanity.toc` | Addon manifest | ~215 bytes |
| `Core.lua` | Main addon logic | ~8 KB |
| `VanityDB.lua` | Database (auto-generated) | ~75 KB |

**Total Size:** ~83 KB

---

## Troubleshooting

### "WoW AddOns directory not found"

**Problem:** Script can't find the WoW AddOns folder

**Solution:**
```powershell
# Specify the correct path
.\DeployAddon.ps1 -WoWPath "C:\Your\WoW\Path\Interface\AddOns"
```

### "Source folder not found"

**Problem:** Script can't find the `AscensionVanity/` subfolder

**Solution:** 
- Ensure you're running the script from the repository root
- Check that `AscensionVanity/` folder exists

### Addon doesn't load in-game

**Checklist:**
1. ✅ All 3 files deployed (`.toc`, `Core.lua`, `VanityDB.lua`)
2. ✅ Files in correct location (`WoW\Interface\AddOns\AscensionVanity\`)
3. ✅ WoW reloaded after deployment (`/reload`)
4. ✅ No Lua errors in-game (check with `/console scriptErrors 1`)

### Changes not appearing in-game

**Common causes:**
1. Forgot to `/reload` in WoW
2. Edited wrong file (repo vs WoW folder)
3. Lua syntax error preventing addon load

**Solution:**
```powershell
# Force re-deploy
.\DeployAddon.ps1 -Force
```

Then in WoW:
```
/reload
/av help
```

---

## Advanced: Multiple WoW Installations

If you have multiple WoW installations (live, PTR, beta):

```powershell
# Deploy to live
.\DeployAddon.ps1 -WoWPath "D:\Games\WoW_Live\Interface\AddOns"

# Deploy to PTR
.\DeployAddon.ps1 -WoWPath "D:\Games\WoW_PTR\Interface\AddOns"
```

Or create separate deployment scripts:
- `DeployAddon_Live.ps1`
- `DeployAddon_PTR.ps1`

---

## Development Best Practices

### 1. Use Watch Mode for Active Development

```powershell
.\DeployAddon.ps1 -Watch
```

Saves time - no need to manually deploy after every change.

### 2. Test Incrementally

Don't make massive changes before testing. Deploy and test frequently.

### 3. Keep WoW Open During Development

Use `/reload` instead of restarting WoW each time.

### 4. Check for Lua Errors

Enable script errors in WoW:
```
/console scriptErrors 1
```

### 5. Use Git Before Major Changes

Commit working code before making risky changes:
```powershell
git add .
git commit -m "Working version before X change"
```

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `.\DeployAddon.ps1` | Deploy once to default location |
| `.\DeployAddon.ps1 -Watch` | Auto-deploy on file changes |
| `.\DeployAddon.ps1 -Force` | Force re-deploy all files |
| `.\DeployAddon.ps1 -WoWPath "..."` | Deploy to custom location |

**In-Game:**
- `/reload` - Reload UI after deployment
- `/av help` - Verify addon loaded
- `/console scriptErrors 1` - Enable error display

---

## See Also

- [README.md](../../README.md) - Project overview
- [EXTRACTION_GUIDE.md](EXTRACTION_GUIDE.md) - How to update the database
- [PROJECT_STRUCTURE.md](../../PROJECT_STRUCTURE.md) - File organization
