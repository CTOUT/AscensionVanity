# Local Configuration Setup

This document explains how to set up local configuration for the AscensionVanity development environment.

## Overview

To keep personal file paths and system-specific information out of version control, we use a local configuration file that is gitignored.

## Quick Setup

1. **Copy the example configuration:**
   ```powershell
   Copy-Item local.config.example.ps1 local.config.ps1
   ```

2. **Edit `local.config.ps1` with your paths:**
   - Update `$script:AscensionPath` to your Ascension installation location
   - Update `$script:AccountName` to your account email
   - Optionally update other paths as needed

3. **Test the configuration:**
   ```powershell
   . .\local.config.ps1
   Test-LocalConfig
   ```

## Configuration Variables

### Required

- **`AscensionPath`**: Root directory of your Ascension WoW client
  - Example: `D:\Program Files\Ascension Launcher\resources\client`

- **`AccountName`**: Your account email used in SavedVariables path
  - Example: `your-email@example.com`

### Automatically Derived

These are calculated from the required variables:

- **`SavedVariablesPath`**: Full path to AscensionVanity.lua SavedVariables
- **`ScreenshotsPath`**: Where WoW stores screenshots
- **`AddOnsPath`**: Where the addon is installed

### Optional

- **`RepoPath`**: Location of this repository
- **`OneDriveWoWPath`**: Backup location if using OneDrive

## Security

**Important**: `local.config.ps1` is gitignored and **will never be committed** to the repository.

This ensures your personal file paths and account information remain private.

## Scripts That Use Local Config

- `ImportResults.ps1` - Imports SavedVariables from game to workspace
- `AnalyzeResults.ps1` - Analyzes test results
- `DeployAddon.ps1` - Deploys addon to WoW directory (will be updated)

## Troubleshooting

### "Local configuration not found"
You need to create `local.config.ps1` from the example file.

### "SavedVariables file not found"
- Make sure you've run `/av apidump` and `/reload` in-game
- Check that your `AscensionPath` and `AccountName` are correct
- Verify the path exists: Test-Path on the SavedVariablesPath

### "Export-ModuleMember" error
This is a harmless warning that can be ignored. The configuration still works correctly.

## For Other Developers

If you're setting up this project:

1. Never commit `local.config.ps1`
2. Always use `local.config.example.ps1` as a template
3. Update example file if new configuration variables are added
4. Document any new variables in this README
