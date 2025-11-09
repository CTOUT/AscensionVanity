# AscensionVanity - GitHub Copilot Instructions

> **Note for Workspace Users**: If you're working in the full "World of Warcraft" workspace, shared Copilot instructions are maintained at `../../.github/copilot-instructions.md`. The `chatmodes/` and `instructions/` folders in this directory are junctions to the workspace-level files.

> **Note for Standalone Users**: If you cloned this repository individually, the junctions won't work. This file contains the essential information you need for development.

## Quick Start

**AscensionVanity** is a World of Warcraft addon for Project Ascension that displays vanity item (combat pet) drop information in creature tooltips with advanced collection tracking.

### Essential Information:

- **Language**: Lua 5.1 (WoW API)
- **Game Version**: WotLK 3.3.0 (Interface 30300)
- **Data Processing**: PowerShell 7+
- **Database**: 2,174+ combat pets

### Core Philosophy:

1. **Innovate, Don't Reinvent** - Consolidate over create
2. **DRY** - Eliminate code duplication
3. **KISS** - Prefer simple solutions
4. **Automation First** - Automate repetitive tasks

### Key Commands:

- `/avanity` or `/av` - Open settings
- `/avanity browser` - Database browser
- `/avanity progress` - Collection progress
- `/reload` - Reload UI after changes

### Development Workflow:

1. **In-game scan** → `/avanity scanner` → Export → Exit WoW
2. **Import** → `.\utilities\MasterAPIDumpImport.ps1`
3. **Enrich** → `.\utilities\EnrichZoneData.ps1`
4. **Generate** → `.\utilities\GenerateVanityDB_Master.ps1`
5. **Deploy** → `.\DeployAddon.ps1`

### File Structure:

- `AscensionVanity/` - Addon files (load order critical per TOC)
- `data/` - JSON databases and enrichment files
- `utilities/` - PowerShell automation scripts
- `docs/` - Documentation

### Critical Files:

- **VanityDB.lua** - Generated database (NEVER edit manually)
- **Core.lua** - Main tooltip logic
- **DatabaseBrowser.lua** - UI for browsing collection

## Full Documentation

For complete documentation, see:
- **README.md** - Features and usage
- **TESTING_QUICK_GUIDE.md** - Testing procedures
- **FEATURE_ROADMAP_V2.3.md** - Upcoming features
- **docs/** folder - Technical documentation

## Workspace Integration

This addon is part of a larger workspace with shared development standards. If you're contributing to multiple Project Ascension addons, consider cloning the full workspace at <https://github.com/CTOUT/> for shared tooling and instructions.
