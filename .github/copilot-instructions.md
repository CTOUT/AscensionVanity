# AscensionVanity - GitHub Copilot Instructions

**Version**: 2.2.0  
**Last Updated**: November 5, 2025  
**Branch**: v2.2-dev

## 📋 File Navigation Guide

This project uses three interconnected instruction files:

| File | Purpose | When to Use |
|------|---------|-------------|
| **This File** (`copilot-instructions.md`) | Project philosophy, architecture, and workflows | Project-level decisions, architecture questions, workflow guidance |
| **Chatmode** (`chatmodes/wow-addon-development.chatmode.md`) | General WoW API & Lua 5.1 knowledge | WoW API questions, Lua patterns, performance optimization, general addon development |
| **Project Instructions** (`instructions/wow-addon-development.instructions.md`) | AscensionVanity-specific patterns | File structure, project gotchas, AscensionVanity workflows, project discoveries |

**Reading Order for New Contributors:**
1. Start here (Main Instructions) - Understand project philosophy
2. Review Chatmode - Learn WoW development fundamentals  
3. Study Project Instructions - Master AscensionVanity specifics

---

## Project Overview

**AscensionVanity** is a World of Warcraft addon for Project Ascension that displays vanity item (combat pet) drop information in creature tooltips with advanced collection tracking and regional guides.

**Tech Stack:**
- **Language**: Lua 5.1 (World of Warcraft API)
- **Data Processing**: PowerShell 7+ (for data extraction and enrichment)
- **Data Sources**: In-game API scanner + db.ascension.gg + Wowhead WOTLK
- **Database**: 2,174 combat pets across 5 categories
  - Filtering via 5 Group IDs (16777217, 16777220, 16777218, 16777224, 16777232)
  - Zone/subzone enrichment for regional tracking
  - Quest-locked NPC detection system

**Current Status:**
- Version: 2.2-dev (active development)
- Features: Database browser, collection progress frame, quest-locked NPC warnings
- Database: 2,174 items with zone enrichment and pagination support
- Automation: Fully automated scan → enrich → generate pipeline

## Development Environment

**Required VS Code Extensions:**
See `docs/VSCODE_EXTENSIONS.md` for complete setup guide.

**Quick Install:**
```powershell
code --install-extension sumneko.lua
code --install-extension ketho.wow-api
code --install-extension septh.wow-bundle
code --install-extension stanzilla.vscode-wow-toc
```

**Configuration:** Workspace settings pre-configured in `.vscode/settings.json`

## Core Philosophy

### 1. **Innovate, Don't Reinvent**
- **Consolidate** over create new files
- **Extend** existing systems rather than duplicating them
- **Refactor** when patterns emerge, don't just add more
- **Single source of truth** wherever possible - Game Client, db.ascension.gg, wowhead/wotlk in that order.

### 2. **DRY (Don't Repeat Yourself)**
- Eliminate code duplication aggressively
- Consolidate similar scripts into master workflows
- Use shared functions and modules
- Abstract common patterns

### 3. **KISS (Keep It Simple, Stupid)**
- Prefer simple, obvious solutions
- Avoid over-engineering
- Write self-documenting code
- Minimal layers of abstraction

### 4. **Automation First**

- Automate repetitive tasks
- Create master workflows that handle end-to-end processes
- Build tools that reduce manual intervention
- Prefer 95%+ automation with manual fallback for edge cases

## AI Assistant Behavioral Guidelines

### Anti-Looping Protocol

**CRITICAL**: If you find yourself repeating the same action or suggestion multiple times without progress:

1. **STOP immediately** - Do not continue the loop
2. **Acknowledge the loop** - Explicitly state "I notice I'm repeating X action"
3. **Change approach** - Try a completely different strategy
4. **Ask for clarification** - Request specific user guidance on what's not working
5. **Escalate if needed** - Suggest the user try a different approach or manual intervention

**Loop Detection Triggers:**

- Suggesting the same file edit 3+ times
- Running the same command 3+ times with identical results
- Proposing the same solution after it was already rejected
- Repeating the same question without acknowledging the previous answer

**Example Response:**

> "I notice I'm in a loop - I've suggested editing VanityDB.lua three times. Let me try a different approach by examining the generation script instead. Could you confirm what specific outcome you're looking for?"

### Context Awareness Protocol

**CRITICAL**: This is an ONGOING conversation with established context. You must:

1. **Check conversation history** - Review previous messages before responding
2. **Reference prior work** - Acknowledge completed tasks and decisions
3. **Build on existing knowledge** - Don't ask for information already provided
4. **Maintain consistency** - Use the same terminology and patterns established earlier

**Context Check Triggers:**

If you start to ask questions like:

- "What is this project about?" → **WRONG** - Read the project overview above
- "What database are we using?" → **WRONG** - Check the Tech Stack section
- "How should I structure scripts?" → **WRONG** - Review Coding Standards section
- "What's our automation goal?" → **WRONG** - Check Core Philosophy 4 - Automation First

**Correct Behavior:**

- Reference specific previous work: "Based on the MasterDescriptionEnrichment.ps1 we created..."
- Build on established patterns: "Following the consolidation pattern we've been using..."
- Acknowledge project status: "Since we've already achieved 99.95% coverage..."

**If Context is Truly Lost:**

1. **Acknowledge the issue**: "I apologize, I seem to have lost context. Let me review..."
2. **Read this file completely** - All context is documented here
3. **Review recent file changes** - Check ACTION_PLAN and recent commits
4. **Ask targeted questions** - Only about specific unclear details, not general project info

### Session Continuity Rules

**Every response should demonstrate:**

- Awareness of project goals and current status
- Recognition of established patterns and conventions
- Understanding of completed work (check ACTION_PLAN files)
- Consistency with previous decisions and implementations

**Red Flags to Avoid:**

- ❌ "Let me help you set up this project" → We're at 99.95% completion!
- ❌ "First, we need to create a database structure" → Already exists and working!
- ❌ "What would you like to automate?" → We have master scripts already!
- ❌ "Shall we discuss coding standards?" → Already documented above!

## Project Architecture

### Addon Structure (`AscensionVanity/`)

```
AscensionVanity/
├── AscensionVanity.toc           # Addon manifest (load order critical!)
├── AscensionVanityConstants.lua  # Shared constants (colors, categories)
├── AscensionVanityConfig.lua     # Configuration defaults
├── VanityDB.lua                  # Generated database (NEVER edit manually)
├── VanityDB_Loader.lua           # Database loading/lookup functions
├── APIScanner.lua                # In-game API data export tool
├── SettingsUI.lua                # Settings interface
├── ScannerUI.lua                 # Scanner UI components
├── CollectionProgressFrame.lua   # Progress tracking display (v2.2)
├── RegionalGuide.lua             # Zone-based item finder (v2.1)
├── DatabaseBrowser.lua           # Database explorer with pagination (v2.2)
└── Core.lua                      # Main tooltip logic
```

**Load Order (Critical per TOC):**
1. `AscensionVanityConstants.lua` - Defines constants used by all files
2. `AscensionVanityConfig.lua` - Sets configuration defaults
3. `VanityDB.lua` - Database (defines `AV_VanityItems`, `AV_IconList`)
4. `VanityDB_Loader.lua` - Provides lookup functions
5. All other files, then `Core.lua` last

### Data Processing Pipeline

```
utilities/
├── MasterVanityDBPipeline.ps1     # MASTER: Complete scan → DB workflow
├── MasterAPIDumpImport.ps1        # Import and process fresh API scans
├── EnrichZoneData.ps1             # Add zone/subzone information
├── GenerateVanityDB_Master.ps1    # JSON → Lua with quest locks & zones
├── CompareGameExportToVanityDB.ps1 # Validation tool
└── archive/                       # Legacy scripts (reference only)
```

**Pipeline Flow:**
1. **Scan In-Game**: `/avanity scanner` → Export data → Saves to `AscensionVanity.lua`
2. **Import**: `MasterAPIDumpImport.ps1` → Creates `MasterFullValidated.json`
3. **Enrich**: `EnrichZoneData.ps1` → Adds zone data from descriptions
4. **Generate**: `GenerateVanityDB_Master.ps1` → Creates `VanityDB.lua`
5. **Deploy**: Copy to WoW AddOns folder → `/reload` in-game

## Coding Standards

### Lua (WoW Addon)

#### Variable Naming
```lua
-- Globals: PascalCase with AV_ prefix
AV_VanityItems = {}
AV_IconList = {}

-- Locals: camelCase
local vanityDB = AV_VanityItems
local itemCount = 0

-- Constants: UPPER_SNAKE_CASE
local MAX_TOOLTIP_LINES = 10
local DEFAULT_COLOR = "|cFF00FF00"
```

#### Function Naming
```lua
-- Global functions: AV_PascalCase
function AV_GetVanityItems(creatureName, creatureType)
    -- implementation
end

-- Local functions: camelCase
local function formatItemName(itemName)
    -- implementation
end
```

#### Code Organization
```lua
-- 1. File header with description
-- 2. Local variables and constants
-- 3. Local helper functions
-- 4. Global functions
-- 5. Event handlers
-- 6. Initialization code
```

#### Best Practices
- **Always** validate input parameters
- **Use** descriptive variable names (no single-letter vars)
- **Prefer** table lookups over if/else chains
- **Comment** complex logic, not obvious code
- **Handle** nil values explicitly

### PowerShell (Data Processing)

#### Script Structure
```powershell
# 1. Script header with description and parameters
# 2. Parameter validation
# 3. Helper functions
# 4. Main workflow
# 5. Error handling and cleanup
```

#### Naming Conventions
```powershell
# Functions: Verb-Noun (PascalCase)
function Get-VanityItems { }
function Update-ItemDescriptions { }

# Variables: camelCase
$itemList = @()
$enrichmentResults = @{}

# Constants: PascalCase
$ApiBaseUrl = "https://db.ascension.gg"
$MaxRetries = 3
```

#### Best Practices
- **Always** use `-ErrorAction Stop` for critical operations
- **Implement** progress bars for long-running operations
- **Use** try/catch for error handling
- **Rate limit** web requests (minimum 2 seconds between calls)
- **Validate** all file paths before operations
- **Create** comprehensive logs and reports

## Data Patterns

### Database Structure (`VanityDB.lua`)

```lua
-- Icon list (referenced by items)
AV_IconList = {
    [1] = "Interface\\Icons\\INV_Box_PetCarrier_01",
    [2] = "Interface\\Icons\\INV_Scroll_04",
    -- 15 total unique icons
}

-- Vanity items database
AV_VanityItems = {
    ["Creature Name"] = {
        type = "Beast",  -- Creature family
        items = {
            {
                name = "Item Name",
                pet = "Pet Name",
                icon = 1,  -- Reference to AV_IconList
                desc = "Location description"
            }
        }
    }
}
```

### Combat Pet Group ID Discovery (Nov 2025)

**Critical Finding:** All dropped combat pets use exactly 5 Group IDs:
- **16777217** - Beastmaster's Whistle (910 items, 99.1% clean)
- **16777220** - Blood Soaked Vellum (564 items, 96.6% clean)
- **16777218** - Summoner's Stone (271 items, 98.5% clean)
- **16777224** - Draconic Warhorn (315 items, 100% clean)
- **16777232** - Elemental Lodestone (283 items, 98.9% clean)
- **Total**: 2,343 items with 98.5% overall accuracy

**Outliers (Correctly Excluded):**
- 10 seasonal reward pets use Group IDs: 553648129, 553648130, 553648136
- 34 vendor/purchase items within the 5 groups (caught by keyword filter)
- Other dropped items (mounts, sigils, weapons, toys) use different Group IDs

**Verification:** 100% coverage confirmed - no dropped combat pets exist outside these 5 Group IDs.
- **16777220** - Blood Soaked Vellum (564 items, 96.6% clean)
- **16777218** - Summoner's Stone (271 items, 98.5% clean)
- **16777224** - Draconic Warhorn (315 items, 100% clean)
- **16777232** - Elemental Lodestone (283 items, 98.9% clean)
- **Total**: 2,343 items with 98.5% overall accuracy

**Outliers (Correctly Excluded):**
- 10 seasonal reward pets use Group IDs: 553648129, 553648130, 553648136
- 34 vendor/purchase items within the 5 groups (caught by keyword filter)
- Other dropped items (mounts, sigils, weapons, toys) use different Group IDs

**Verification:** 100% coverage confirmed - no dropped combat pets exist outside these 5 Group IDs.

### Data Enrichment Pattern

**Three-Tier Search Strategy:**
1. **db.ascension.gg** (Primary, 90%+ success rate)
2. **Wowhead WOTLK** (Fallback, 5-8% additional coverage)
3. **Manual Research** (Last resort, 2-5% edge cases)

**Automation Requirements:**
- Single-pass workflow (one command)
- Comprehensive reporting (CSV, JSON, manual research list)
- Safe pattern matching (verify before applying)
- Rate limiting (respect source websites)

### Quest-Locked NPC System (v2.2)

**Database**: `data/QuestLockedNPCs.json` - Tracks NPCs that only spawn during quests

**Features:**
- Real-time quest status detection (not started/active/completed)
- Color-coded warnings in tooltips (Red/Orange/Green)
- Quest details: name, ID, faction requirements
- Integrated into `GenerateVanityDB_Master.ps1` pipeline

**Example:**
```json
{
  "itemId": 80180,
  "questId": 4283,
  "questName": "Hand of Iruxos",
  "faction": "Horde",
  "warning": "🔴 Too late! NPC despawned after quest completion."
}
```

## Critical Developer Workflows

### Complete Database Rebuild (Fresh Scan)

**When to use:** After game updates or when many items are missing

```powershell
# 1. In-game: Open scanner and export fresh data
# /avanity scanner → Click "Scan All Items" → Exit WoW to save

# 2. Import fresh scan and build master JSON
.\utilities\MasterAPIDumpImport.ps1

# 3. Enrich with zone/subzone data from descriptions
.\utilities\EnrichZoneData.ps1

# 4. Generate VanityDB.lua with quest locks
.\utilities\GenerateVanityDB_Master.ps1

# 5. Deploy to WoW
.\DeployAddon.ps1
```

### Complete Pipeline (One Command)

```powershell
# Master pipeline: scan → filter → enrich → generate → validate
.\utilities\MasterVanityDBPipeline.ps1
```

**What it does:**
- Loads fresh scan from `data/AscensionVanity.lua` (symlink to SavedVariables)
- Filters to 5 combat pet Group IDs
- Merges enrichment data from JSON files
- Generates `MasterFullValidated.json` and `VanityDB.lua`
- Creates validation and triage reports

### Adding Quest-Locked NPCs

```powershell
# 1. Edit data/QuestLockedNPCs.json
# Add new entry with itemId, questId, questName, faction, warning

# 2. Regenerate database (merges quest lock data)
.\utilities\GenerateVanityDB_Master.ps1

# 3. Test in-game
.\DeployAddon.ps1
```

### Zone Data Enrichment

```powershell
# Extract zone/subzone from item descriptions
.\utilities\EnrichZoneData.ps1

# Validates against ZoneMappings.json
# Adds "zone" and "subzone" fields to MasterFullValidated_ZoneEnriched.json
```

## Testing Guidelines

### In-Game Testing
1. **Basic Functionality**
   - `/reload` to verify addon loads without errors
   - Check `/console scriptErrors 1` for Lua errors
   - Mouse over various creature types (Beast, Demon, Undead, Dragonkin, Elemental)
   - Verify tooltip formatting and colors

2. **UI Components**
   - `/avanity` - Settings UI opens, checkboxes functional
   - `/avanity scanner` - Scanner UI opens, scan completes successfully
   - `/avanity browser` - Database browser shows creatures, pagination works
   - `/avanity guide` - Regional guide filters to current zone
   - `/avanity progress` - Progress frame displays, updates correctly

3. **Quest-Locked NPCs**
   - Find NPCs with quest warnings (Demon Spirit, Enraged Panther)
   - Verify color coding: Red (completed), Orange (not started), Green (active)
   - Check quest information displays correctly

4. **Edge Cases**
   - Creatures with no items (should show nothing)
   - Creatures with multiple items (all should display)
   - Learned vs unlearned status (check green color for learned)
   - Zone filtering in browser (verify accuracy)

### Data Validation

1. **Pipeline Validation**
   ```powershell
   # Run full pipeline with validation
   .\utilities\MasterVanityDBPipeline.ps1
   
   # Check output files exist and are valid
   Test-Path data\MasterFullValidated.json
   Test-Path AscensionVanity\VanityDB.lua
   ```

2. **Database Integrity**
   ```powershell
   # Compare against previous version
   .\utilities\CompareGameExportToVanityDB.ps1
   
   # Verify item counts (should be 2,174)
   (Get-Content data\MasterFullValidated.json | ConvertFrom-Json).Count
   ```

3. **Quality Checks**
   - Check for empty descriptions (should only be Captain Claws)
   - Verify zone enrichment coverage (should be ~95%+)
   - Validate quest-locked NPC entries exist
   - Ensure no duplicate entries in database

### Testing Checklist
See `TEST_CHECKLIST_V2.2.md` for comprehensive v2.2 release testing procedures.

## Troubleshooting Common Issues

### Addon Won't Load
**Symptoms:** No tooltip enhancements, slash commands don't work

**Solutions:**
1. Check for Lua errors: `/console scriptErrors 1`
2. Verify load order in `AscensionVanity.toc`
3. Check SavedVariables corruption: Delete `AscensionVanityDB` from SavedVariables
4. Ensure all files exist (especially `AscensionVanityConstants.lua`)
5. `/reload` after any file changes

### Tooltip Not Showing Items
**Symptoms:** Tooltips appear but no vanity items listed

**Solutions:**
1. Verify creature has items: `/dump AV_VanityItems`
2. Check creature name matching (case-sensitive)
3. Ensure `VanityDB.lua` is current (not empty)
4. Test with known creatures (e.g., "Savannah Patriarch")
5. Check if tooltip toggle is enabled: `/avanity` → Enable Tooltip Display

### Database Generation Fails
**Symptoms:** Scripts error or produce empty output

**Solutions:**
1. Verify input files exist:
   - `data/AscensionVanity.lua` (fresh scan)
   - `data/API_to_GameID_Mapping.json`
   - `data/ZoneMappings.json`
2. Check PowerShell version: `$PSVersionTable.PSVersion` (need 5.1+)
3. Run with `-Verbose` flag for detailed output
4. Check for JSON syntax errors: `Get-Content file.json | ConvertFrom-Json`
5. Review error logs in script output

### Quest Warnings Not Appearing
**Symptoms:** Known quest-locked NPCs don't show warnings

**Solutions:**
1. Verify NPC in database: Check `data/QuestLockedNPCs.json`
2. Ensure database regenerated: `.\utilities\GenerateVanityDB_Master.ps1`
3. Check quest status in-game: `/dump C_QuestLog.IsQuestFlaggedCompleted(questId)`
4. Verify quest warnings enabled: `/avanity` → Show Quest-Locked NPC Warnings
5. `/reload` to refresh quest status cache

### Performance Issues
**Symptoms:** Game stutters when mousing over creatures

**Solutions:**
1. Check database size (should be ~2,174 items)
2. Disable debug mode if enabled
3. Ensure no infinite loops in tooltip code
4. Use `/framestack` to identify frame issues
5. Check addon memory usage: `/run UpdateAddOnMemoryUsage() print(GetAddOnMemoryUsage("AscensionVanity"))`

## Documentation Standards

### Code Comments
```lua
-- Good: Explains WHY
-- We need to check both name and type because some creatures share names
local function findCreature(name, type)
    -- implementation
end

-- Bad: Explains WHAT (code already shows this)
-- Loop through items
for i = 1, items do
    -- implementation
end
```

### Script Headers
```powershell
<#
.SYNOPSIS
    Brief one-line description

.DESCRIPTION
    Detailed description of what the script does
    Include workflow steps and automation percentage

.PARAMETER DryRun
    Test mode - show what would be done without making changes

.EXAMPLE
    .\ScriptName.ps1
    Standard execution

.EXAMPLE
    .\ScriptName.ps1 -DryRun
    Test mode execution

.NOTES
    Author: CMTout
    Last Updated: YYYY-MM-DD
    Automation: XX% automated, XX% manual fallback
>
```

## Common Pitfalls

### ❌ Don't Do This
```lua
-- Hardcoded values
local maxItems = 10

-- Magic numbers
if count > 5 then

-- Global variables without AV_ prefix
VanityItems = {}

-- Undocumented complex logic
local result = a and b or c and d or e
```

### ✅ Do This Instead
```lua
-- Named constants
local MAX_TOOLTIP_ITEMS = 10

-- Self-documenting code
local MAX_ITEMS_PER_CREATURE = 5
if itemCount > MAX_ITEMS_PER_CREATURE then

-- Proper global naming
AV_VanityItems = {}

-- Clear, commented logic
-- Return first truthy value in priority order: b > d > e
local result = (a and b) or (c and d) or e
```

## Version Control

### Commit Messages
```
Format: <type>(<scope>): <subject>

Types:
- feat: New feature
- fix: Bug fix
- refactor: Code restructuring
- docs: Documentation only
- chore: Maintenance tasks
- perf: Performance improvement

Examples:
feat(database): Add 50 new combat pets from fresh scan
fix(tooltip): Correct color coding for learned items
refactor(scripts): Consolidate enrichment scripts into MasterDescriptionEnrichment.ps1
docs(readme): Update coverage statistics to 99.95%
```

### Branch Strategy
- `main` - Stable releases (v2.1 and earlier)
- `v2.2-dev` - Active development (current, pre-release testing)
- Feature branches: `feature/description-enrichment`, `fix/tooltip-formatting`

**Workflow:**
- Develop new features in `v2.2-dev`
- Test thoroughly before merging to `main`
- Tag releases in `main` (v2.0, v2.1, v2.2, etc.)
- Keep `v2.2-dev` synchronized with `main` after releases

## Performance Considerations

### Lua Performance

**Critical Optimization Patterns:**

1. **Cache Global Lookups**
   ```lua
   -- Bad: Global lookup every iteration
   for i = 1, 1000 do
       local item = AV_VanityItems[creatureName]
   end
   
   -- Good: Cache in local variable
   local vanityDB = AV_VanityItems
   for i = 1, 1000 do
       local item = vanityDB[creatureName]
   end
   ```

2. **Use Table Lookups Over if/else**
   ```lua
   -- Bad: Sequential checks
   local icon
   if category == "Beastmaster's Whistle" then
       icon = 1
   elseif category == "Blood Soaked Vellum" then
       icon = 2
   end
   
   -- Good: O(1) table lookup
   local iconMap = {
       ["Beastmaster's Whistle"] = 1,
       ["Blood Soaked Vellum"] = 2
   }
   local icon = iconMap[category]
   ```

3. **Avoid String Concatenation in Loops**
   ```lua
   -- Bad: Creates new string each iteration
   local text = ""
   for i = 1, items do
       text = text .. items[i].name .. "\n"
   end
   
   -- Good: Build table, concatenate once
   local lines = {}
   for i = 1, items do
       table.insert(lines, items[i].name)
   end
   local text = table.concat(lines, "\n")
   ```

4. **Minimize Table Creation in Hot Paths**
   ```lua
   -- Bad: Creates new table every tooltip
   function AddTooltip()
       local items = {}  -- New allocation!
       -- process items
   end
   
   -- Good: Reuse table
   local itemCache = {}
   function AddTooltip()
       wipe(itemCache)  -- Clear existing table
       -- process items
   end
   ```

**WoW-Specific Optimizations:**
- **Tooltip callbacks** fire frequently - keep them fast
- **Use `OnUpdate` throttling** for expensive operations (limit to once per second)
- **Cache learned status** instead of calling `C_VanityCollection` every time
- **Pagination** for large lists (50 items/page max, as in DatabaseBrowser)

### PowerShell Performance

**Data Processing Optimizations:**

1. **Use -Filter Instead of Where-Object**
   ```powershell
   # Bad: Processes all files, then filters
   Get-ChildItem -Recurse | Where-Object { $_.Extension -eq '.json' }
   
   # Good: Filters during traversal
   Get-ChildItem -Recurse -Filter '*.json'
   ```

2. **Batch API Calls with Rate Limiting**
   ```powershell
   # Good: Rate-limited batch processing
   foreach ($item in $items) {
       $result = Invoke-WebRequest $url
       Start-Sleep -Seconds 2  # Respect rate limits
   }
   ```

3. **Process Large Datasets in Chunks**
   ```powershell
   # Good: Process 100 items at a time
   $batchSize = 100
   for ($i = 0; $i -lt $items.Count; $i += $batchSize) {
       $batch = $items[$i..($i + $batchSize - 1)]
       Process-Batch $batch
   }
   ```

4. **Use ArrayList for Large Collections**
   ```powershell
   # Bad: Array grows slowly with +=
   $results = @()
   foreach ($item in $items) {
       $results += $item  # Slow!
   }
   
   # Good: ArrayList for efficient growth
   $results = [System.Collections.ArrayList]::new()
   foreach ($item in $items) {
       [void]$results.Add($item)  # Fast!
   }
   ```

**Pipeline-Specific Tips:**
- **Cache web requests** (24-hour TTL for API data)
- **Use `-Raw` with Get-Content** for single-string reads
- **ConvertFrom-Json** once, index by key for lookups
- **Progress bars** for long operations (`Write-Progress`)

## Current Project Status (v2.2-dev)

**Features Complete:**
- ✅ Database Browser with pagination (50 items/page)
- ✅ Collection Progress Frame (draggable, per-category tracking)
- ✅ Quest-Locked NPC warnings (color-coded by status)
- ✅ Regional Guide (zone-filtered creature lists)
- ✅ Zone/subzone enrichment pipeline
- ✅ Modern Settings UI with Interface Options integration

**Database Statistics:**
- Total Combat Pets: 2,174
- With Descriptions: 2,173 (99.95%)
- Zone Enrichment: Complete
- Quest-Locked NPCs Tracked: 2+ (Demon Spirit, Enraged Panther)

**Pipeline Automation:**
- Fresh Scan Import: 100% automated
- Zone Enrichment: 100% automated  
- Quest Lock Merging: 100% automated
- Database Generation: 100% automated

**Active Development:**
- Branch: v2.2-dev
- Focus: Testing and refinement
- Next: v2.2 stable release

## Project-Wide Discoveries

**Scope**: High-level project insights and cross-cutting discoveries. Specific discoveries go in the appropriate file:
- WoW API discoveries → `chatmodes/wow-addon-development.chatmode.md`
- AscensionVanity discoveries → `instructions/wow-addon-development.instructions.md`

### [Discovery Title]
**Date**: [Date]
**Context**: [What triggered this insight]
**Impact**: [How it affects the project]
**Action**: [What should be done]

---

*Add project-wide discoveries above this line*

## Quick Reference for WoW Development

### When to Use What
- **VanityDB.lua**: Read-only, generated file - NEVER edit directly
- **MasterFullValidated.json**: Source of truth after scan import
- **MasterAPIDumpImport.ps1**: Import fresh in-game scans
- **EnrichZoneData.ps1**: Extract zone/subzone from descriptions
- **GenerateVanityDB_Master.ps1**: JSON → Lua with quest locks

### Common File Paths
- **Addon files**: `AscensionVanity/*.lua`
- **Fresh scans**: `data/AscensionVanity_Fresh_Scan_*.lua`
- **Master JSON**: `data/MasterFullValidated.json`
- **Zone enriched**: `data/MasterFullValidated_ZoneEnriched.json`
- **Generated DB**: `AscensionVanity/VanityDB.lua`
- **Scripts**: `utilities/*.ps1`

### Key Globals to Remember
- `AV_VanityItems` - Main database table
- `AV_IconList` - Deduplicated icon paths
- `AV_Config` - User configuration settings
- `AV_COLOR_*` - Color constants (red, gold, green, etc.)
- `AV_CATEGORY_PREFIXES` - Category name mappings

### Common Code Patterns

**Database Lookup Pattern:**
```lua
-- Look up items for a creature by name
local creatureData = AV_VanityItems[creatureName]
if creatureData then
    local creatureType = creatureData.type  -- "Beast", "Demon", etc.
    local items = creatureData.items        -- Array of item tables
    
    for _, item in ipairs(items) do
        local name = item.name    -- "Beastmaster's Whistle: Wolf"
        local pet = item.pet      -- "Wolf"
        local icon = AV_IconList[item.icon]  -- Icon path
        local desc = item.desc    -- "Found in Silverpine Forest"
        local zone = item.zone    -- "Silverpine Forest"
        local subzone = item.subzone  -- "The Decrepit Fields"
        
        -- Check if learned
        local learned = AV_IsVanityItemLearned(item.id, item.name)
        local color = learned and AV_COLOR_GREEN or AV_COLOR_WHITE
    end
end
```

**Quest Lock Detection Pattern:**
```lua
-- Check if item has quest lock and get status
if item.questLock then
    local questId = item.questLock.questId
    local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(questId)
    
    if isCompleted then
        -- Red warning: Quest completed, NPC despawned
        tooltip:AddLine(AV_COLOR_RED .. item.questLock.warning)
    elseif C_QuestLog.GetLogIndexForQuestID(questId) then
        -- Green: Quest active, farm now!
        tooltip:AddLine(AV_COLOR_GREEN .. "Quest active - farm now!")
    else
        -- Orange: Quest not started
        tooltip:AddLine(AV_COLOR_GOLD .. "Quest required: " .. item.questLock.questName)
    end
end
```

**Icon Region Setup Pattern:**
```lua
-- Set icon texture from database
local iconTexture = itemFrame.icon
local iconPath = AV_IconList[item.icon]
iconTexture:SetTexture(iconPath)

-- Optional: Set icon to cover full frame
iconTexture:SetAllPoints(itemFrame)
iconTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)  -- Crop edges
```

**Pagination Pattern (from DatabaseBrowser):**
```lua
-- Calculate pagination
local ITEMS_PER_PAGE = 50
local totalPages = math.ceil(#filteredCreatures / ITEMS_PER_PAGE)
local startIndex = (currentPage - 1) * ITEMS_PER_PAGE + 1
local endIndex = math.min(startIndex + ITEMS_PER_PAGE - 1, #filteredCreatures)

-- Display only current page
for i = startIndex, endIndex do
    local creature = filteredCreatures[i]
    -- Render creature
end

-- Update page counter
pageText:SetText(string.format("Page %d of %d", currentPage, totalPages))
```

### Critical Commands
- `/avanity` or `/av` - Open settings UI
- `/avanity scanner` - Open API scanner (for fresh scans)
- `/avanity browser` - Database browser with pagination
- `/avanity guide` - Regional guide (current zone)
- `/avanity progress` - Toggle collection progress frame
- `/reload` - Reload UI after addon changes
- `/console scriptErrors 1` - Enable Lua error display
- `/dump AV_VanityItems` - Inspect database in-game
- `/framestack` - Debug frame overlaps

## Questions to Ask

When you're unsure about implementation:
1. **Does this fit the existing pattern?** If not, should it?
2. **Can this be consolidated?** Don't create when you can extend.
3. **Is this the simplest solution?** KISS principle applies.
4. **Will this be automated?** If repeated, it should be.
5. **Is this documented?** Code should explain itself or be commented.

## 🚨 When Copilot Gets It Wrong

If I suggest something that contradicts these instructions:
1. **Point it out immediately** - "That contradicts the [section] rule"
2. **Reference the rule** - Quote the specific instruction I violated
3. **I will correct** - Acknowledge and provide the right approach
4. **Document it** - Add to chatmode "Lessons Learned" section for future

**Common mistakes to watch for:**
- Suggesting manual edits to VanityDB.lua (it's generated!)
- Creating new scripts instead of extending existing master scripts
- Searching for Azure/cloud docs for WoW addon projects
- Missing the load order dependencies in TOC files
- Proposing .NET/C# solutions instead of PowerShell
- Ignoring the consolidation philosophy

## Getting Help

When generating code or suggestions:
1. **Check existing patterns** first in similar files
2. **Follow naming conventions** consistently
3. **Consolidate** rather than create new files
4. **Automate** repetitive tasks
5. **Document** complex logic clearly

---

## 📜 Version History

### v2.2.0 - November 5, 2025 (Current)
**Comprehensive Update**: Reflects v2.2-dev branch state with all new features
- Updated version to 2.2.0 to match active branch
- Added Database Browser with pagination system (50 items/page)
- Added Collection Progress Frame documentation
- Added Quest-Locked NPC system with JSON database
- Updated architecture to show all new UI components
- Documented complete data pipeline (scan → import → enrich → generate)
- Updated file structure to reflect v2.2 additions (Constants, DatabaseBrowser, etc.)
- Added zone enrichment workflow documentation
- Updated project status to reflect feature completion
- Added critical developer workflows section
- Updated slash commands to include new v2.2 commands
- Corrected database statistics (2,174 items vs outdated 2,343)
- Added Group ID documentation for combat pet filtering

### v2.0.0 - November 5, 2025
**Major Reorganization**: Full documentation restructure for clarity and maintainability
- Added comprehensive file navigation guide at the top
- Added version tracking (was missing)
- Eliminated duplication across all three instruction files
- Consolidated VS Code extension details to single reference
- Established clear boundaries between files:
  - Main Instructions: Project philosophy, architecture, workflows
  - Chatmode: General WoW API and Lua 5.1 knowledge
  - Project Instructions: AscensionVanity-specific patterns
- Added "Project-Wide Discoveries" section for cross-cutting insights
- Updated all cross-references to point to correct files
- Improved context awareness protocols

### v1.x (Pre-2.0)
- Various additions and improvements
- VS Code extensions documentation
- Data integrity patterns
- Anti-looping protocols
- Context awareness rules

---

**Remember:** The goal is maintainable, automated, consolidated code that follows clear patterns and principles. When in doubt, prefer simplicity and consolidation over complexity and proliferation.
