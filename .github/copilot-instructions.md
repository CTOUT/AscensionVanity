# AscensionVanity - GitHub Copilot Instructions

## Project Overview

**AscensionVanity** is a World of Warcraft addon for Project Ascension that displays vanity item drop information (combat pets) in creature tooltips. The addon helps players discover and collect vanity items by showing which creatures drop them.

**Tech Stack:**
- **Language**: Lua 5.1 (World of Warcraft API)
- **Data Processing**: PowerShell 7+ (for data extraction and enrichment)
- **Data Sources**: db.ascension.gg + Wowhead WOTLK
- **Database**: 2,174 combat pets with 99.95% description coverage

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

## Copilot Behavioral Guidelines

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
- "What's our automation goal?" → **WRONG** - Check Core Philosophy #4

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
├── AscensionVanity.toc        # Addon manifest (load order critical!)
├── VanityDB.lua               # Database (2,174 items, icon list)
├── VanityDB_Loader.lua        # Database loading logic
├── Core.lua                   # Main addon logic
├── AscensionVanityConfig.lua  # Configuration and settings
├── APIScanner.lua             # In-game API scanner
└── ScannerUI.lua              # Scanner UI components
```

**Load Order (Critical):**
1. `VanityDB.lua` - Defines globals: `AV_VanityItems`, `AV_IconList`
2. `VanityDB_Loader.lua` - Loads and processes database
3. All other files can load in any order

### Data Processing Structure

```
utilities/
├── MasterDescriptionEnrichment.ps1  # MASTER: End-to-end enrichment
├── GenerateVanityDB.ps1             # Convert JSON to Lua database
├── CompareScans.ps1                 # Compare fresh vs existing data
└── archived/                        # Obsolete scripts (reference only)
```

**Key Pattern:** One master script per major workflow, not multiple fragmented scripts.

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

## Common Tasks

### Adding New Vanity Items

**DON'T:**
- Manually edit `VanityDB.lua` (it's generated!)
- Create new enrichment scripts
- Duplicate existing workflows

**DO:**
1. Add items to `data/API_to_GameID_Mapping.json`
2. Run `.\utilities\MasterDescriptionEnrichment.ps1` to enrich
3. Run `.\utilities\GenerateVanityDB.ps1` to regenerate database
4. Test in-game

### Updating Item Descriptions

**DON'T:**
- Manually edit descriptions in `VanityDB.lua`
- Create one-off scripts for specific items

**DO:**
1. Run `.\utilities\MasterDescriptionEnrichment.ps1`
2. Review `Manual_Research_Needed_*.txt` for items needing manual work
3. Update JSON source files with manual research results
4. Regenerate database with `GenerateVanityDB.ps1`

### Creating New Scripts

**Before creating a new script, ask:**
1. Can this be added to an existing master script?
2. Is there a similar script that can be extended?
3. Will this be used more than once?
4. Can this be a function instead of a script?

**Master Script Pattern:**
```powershell
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$OutputPath = ".\data"
)

# Validate parameters
# Define helper functions
# Main workflow with progress tracking
# Generate comprehensive reports
# Handle errors gracefully
```

## Testing Guidelines

### In-Game Testing
1. Test with `/reload` to verify addon loads
2. Mouse over various creature types (Beast, Demon, etc.)
3. Verify tooltip formatting and colors
4. Check edge cases (creatures with no items, multiple items)

### Data Validation
1. Run `.\utilities\GenerateVanityDB.ps1` with validation
2. Check output for warnings or errors
3. Verify database size and item counts
4. Compare with previous version for regressions

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
for i = 1, #items do
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
#>
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
- `main` - Stable releases
- `v2.0-dev` - Active development
- Feature branches: `feature/description-enrichment`, `fix/tooltip-formatting`

## Performance Considerations

### Lua Performance
- **Table lookups** are O(1) - use them liberally
- **Avoid** string concatenation in loops (use table.concat)
- **Cache** global lookups in local variables
- **Minimize** table creation in hot paths

### PowerShell Performance
- **Use** `-Filter` instead of `| Where-Object` for file operations
- **Batch** API calls with rate limiting
- **Process** items in chunks for large datasets
- **Use** `[System.Collections.ArrayList]` for large collections

## Current Project Status

**Database Coverage:**
- Total Combat Pets: 2,174
- With Descriptions: 2,173 (99.95%)
- Correctly Empty: 1 (Captain Claws - NPC doesn't exist)

**Automation:**
- Description Enrichment: 95-97% automated
- Database Generation: 100% automated
- Manual Research: 3-5% of items (edge cases)

**Active Development:**
- Version: 2.0-dev
- Focus: Description enrichment completion
- Next: Regional information, advanced filtering

## Questions to Ask

When you're unsure about implementation:
1. **Does this fit the existing pattern?** If not, should it?
2. **Can this be consolidated?** Don't create when you can extend.
3. **Is this the simplest solution?** KISS principle applies.
4. **Will this be automated?** If repeated, it should be.
5. **Is this documented?** Code should explain itself or be commented.

## Getting Help

When generating code or suggestions:
1. **Check existing patterns** first in similar files
2. **Follow naming conventions** consistently
3. **Consolidate** rather than create new files
4. **Automate** repetitive tasks
5. **Document** complex logic clearly

---

**Remember:** The goal is maintainable, automated, consolidated code that follows clear patterns and principles. When in doubt, prefer simplicity and consolidation over complexity and proliferation.
