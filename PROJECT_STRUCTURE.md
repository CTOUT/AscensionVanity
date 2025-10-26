# AscensionVanity - Project Structure

## Overview

This document explains the organization of the AscensionVanity project files.

## Folder Structure

```
AscensionVanity/
├── AscensionVanity/              # ✅ ADDON FILES (Install this folder to WoW\Interface\AddOns\)
│   ├── AscensionVanity.toc       # Addon metadata and load order
│   ├── Core.lua                  # Main addon logic and tooltip hooks
│   └── VanityDB.lua  # Auto-generated database (2,032 items)
│
├── docs/                         # 📚 DOCUMENTATION
│   ├── analysis/                 # Data analysis and reports
│   │   ├── SKIPPED_ITEMS_ANALYSIS.md      # Breakdown of 69 skipped items
│   │   ├── SPOT_CHECK_ANALYSIS.md         # Manual verification results
│   │   └── VENDOR_ITEM_DISCOVERY.md       # How vendor items were found
│   │
│   ├── guides/                   # How-to guides and future work
│   │   ├── EXTRACTION_GUIDE.md            # How to update the database
│   │   ├── README_DOCUMENTATION.md        # Documentation overview
│   │   └── TODO_FUTURE_INVESTIGATIONS.md  # Items needing verification
│   │
│   └── archive/                  # Archived/historical documents
│       ├── ARCHITECTURE.md                # Original architecture notes
│       ├── INTEGRATION_COMPLETE.md        # Integration completion report
│       ├── PROJECT_SUMMARY.md             # Project summary
│       ├── TESTING_COMMANDS.txt           # Testing command reference
│       └── TODO.md                        # Original TODO (now outdated)
│
├── utilities/                    # 🔧 UTILITY SCRIPTS (Development tools)
│   ├── AnalyzeSourceCodes.ps1            # Analyzes source field codes
│   ├── CountByCategory.ps1               # Counts items by category
│   ├── DiagnoseMissingItems.ps1          # Diagnoses missing items
│   ├── DiagnoseSourcemore.ps1            # Analyzes sourcemore field
│   └── ExtractDatabaseVerbose.ps1        # Verbose extraction script
│
├── DeployAddon.ps1               # 🚀 DEPLOYMENT SCRIPT (Deploy addon to WoW for testing)
├── ExtractDatabase.ps1           # 🚀 MAIN EXTRACTION SCRIPT (Run this to update database)
├── README.md                     # 📖 PROJECT README (Start here!)
├── .gitignore                    # Git ignore rules
│
└── .cache/                       # ⚠️ CACHE (Auto-generated, ignored by git)
    ├── categories/               # Cached category page HTML
    ├── categories_filtered/      # Filtered category caches
    └── items/                    # Cached item page HTML
```

## File Descriptions

### Core Addon Files (Install these)

- **AscensionVanity/** - The actual WoW addon folder
  - Copy this entire folder to `World of Warcraft\Interface\AddOns\`
  - Contains the `.toc`, `.lua` files needed to run in-game

### Development Files (For updating/maintaining)

- **DeployAddon.ps1** - Deploy addon to WoW for testing
  - Run this to copy addon files to your WoW AddOns folder
  - Use `-Watch` to automatically deploy on file changes
  - Use `-Force` to re-deploy all files
  - Configurable WoW path with `-WoWPath` parameter

- **ExtractDatabase.ps1** - Main script to regenerate the database
  - Run this when you want to update `VanityDB.lua`
  - Use `-Force` to bypass cache and fetch fresh data
  - Use `-Verbose` for detailed output

- **utilities/** - Helper scripts for development
  - Not needed for normal addon use
  - Useful for troubleshooting or analyzing data

### Documentation Files

- **docs/analysis/** - Data analysis reports
  - Explains why certain items are missing
  - Shows coverage statistics
  - Documents edge cases

- **docs/guides/** - How-to documentation
  - Instructions for updating the database
  - Future work and items to investigate
  - Documentation overview

- **docs/archive/** - Historical documents
  - Old project notes
  - Completed milestones
  - Outdated TODOs

## Quick Start Guide

### For Users (Installing the Addon)

1. Copy the `AscensionVanity/` subfolder to your WoW AddOns directory
2. Restart WoW or `/reload`
3. Done!

### For Developers (Updating the Database)

1. Run `.\ExtractDatabase.ps1 -Force` to fetch fresh data
2. Review output for any errors or validation warnings
3. Test the updated addon in-game
4. Commit changes to git

### For Contributors (Understanding the Project)

1. Start with `README.md` (project overview)
2. Read `docs/guides/README_DOCUMENTATION.md` (documentation guide)
3. Check `docs/analysis/SKIPPED_ITEMS_ANALYSIS.md` (coverage details)
4. Review `docs/guides/TODO_FUTURE_INVESTIGATIONS.md` (what needs work)

## Version Control

### Ignored Files (.gitignore)

The following files/folders are automatically excluded from version control:

- `.cache/` - All cached HTML files
- `test_*.html`, `test_*.txt` - Test files
- `MissingItems_Report.txt` - Diagnostic output
- `SkippedItems_Detailed.txt` - Diagnostic output
- Editor/IDE files (`.vscode/`, `.vs/`)
- Backup files (`*.bak`, `*.backup`)

### Committed Files

Everything else is tracked in git:
- Addon files (`AscensionVanity/`)
- Documentation (`docs/`)
- Extraction script (`ExtractDatabase.ps1`)
- Utility scripts (`utilities/`)
- Project README

## Maintenance Workflow

1. **Update Database**: Run `ExtractDatabase.ps1 -Force`
2. **Review Changes**: Check `SkippedItems_Detailed.txt` for new issues
3. **Test In-Game**: Load addon and verify tooltips
4. **Update Docs**: Update relevant documentation if needed
5. **Commit**: Git commit with descriptive message
6. **Tag Version**: Create git tag for releases

## Current Statistics

- **Total Items**: 2,101
- **Successfully Extracted**: 2,032 (96.7%)
- **Skipped**: 69 items
- **Database Size**: ~150 KB (VanityDB.lua)
- **Documentation**: 10+ markdown files
- **Scripts**: 6 PowerShell scripts

---

**Last Updated**: October 26, 2025  
**Project Version**: 1.0.0
