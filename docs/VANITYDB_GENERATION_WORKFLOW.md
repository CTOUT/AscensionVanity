# VanityDB Generation Workflow

## Overview

The VanityDB.lua generation process has been streamlined into a reliable two-step workflow that handles escaping correctly and integrates manual research.

## Current Workflow (Nov 2025)

### Step 1: Convert Fresh Scan to Master JSON

**Script**: `utilities/ConvertScanToMasterJson.ps1`

```powershell
.\utilities\ConvertScanToMasterJson.ps1
```

**What it does:**
- Reads `data/AscensionVanity.lua` (symlink to WoW SavedVariables)
- Parses APIDump section line-by-line (fast, reliable)
- Filters to 5 combat pet Group IDs (16777217, 16777220, 16777218, 16777224, 16777232)
- **Properly unescapes Lua strings** (e.g., `\"` → `"`)
- Loads manual research from `data/corrections/ManualResearch.json`
- Outputs `data/MasterFullValidated.json`

**Input**: `data/AscensionVanity.lua` (fresh API dump from in-game scanner)
**Output**: `data/MasterFullValidated.json` (2343 combat pet items, properly escaped)

### Step 2: Generate VanityDB.lua

**Script**: `utilities/GenerateVanityDB_Master.ps1`

```powershell
.\utilities\GenerateVanityDB_Master.ps1
```

**What it does:**
- Reads `data/MasterFullValidated.json`
- Deduplicates icons across all items
- **Properly escapes for Lua output** (e.g., `"` → `\"`, `\` → `\\`)
- Sorts items numerically by item ID
- Outputs `AscensionVanity/VanityDB.lua`

**Input**: `data/MasterFullValidated.json`
**Output**: `AscensionVanity/VanityDB.lua` (ready for deployment)

## Complete End-to-End Process

### 1. Scan In-Game
```
/av scanner
[Click "Scan All Items"]
Wait for completion
Exit WoW (saves to AscensionVanity.lua)
```

### 2. Convert & Generate
```powershell
# Step 1: Convert scan to JSON
.\utilities\ConvertScanToMasterJson.ps1

# Step 2: Generate VanityDB.lua
.\utilities\GenerateVanityDB_Master.ps1
```

### 3. Deploy
```powershell
.\DeployAddon.ps1 -WoWPath "D:\OneDrive\Warcraft"
```

### 4. Test In-Game
```
/reload
Hover over creatures to verify items show correctly
```

## Key Features

### Proper String Escaping

**Problem Solved**: Special characters in item names (quotes, backslashes) caused Lua syntax errors.

**Solution**:
1. **ConvertScanToMasterJson.ps1**: Unescapes Lua strings when parsing
   - Lua: `\"Count\"` → Unescaped: `"Count"` → JSON: `\"Count\"`
2. **GenerateVanityDB_Master.ps1**: Escapes for Lua output
   - JSON: `\"Count\"` → Unescaped: `"Count"` → Lua: `\"Count\"`

**Example Item**:
- **Source**: `Beastmaster's Whistle: \"Count\" Ungula` (Lua escaped)
- **JSON**: `"Beastmaster's Whistle: \"Count\" Ungula"` (JSON escaped)
- **Output**: `name = "Beastmaster's Whistle: \"Count\" Ungula"` (Lua escaped)

### Manual Research Integration

**File**: `data/corrections/ManualResearch.json`

**Structure**:
```json
[
  {
    "DbItemId": 480382,
    "Description": "NPC doesn't exist. Possibly a reward, promo, purchase or not yet implemented.",
    "Validated": true
  }
]
```

**Automatically applied** during Step 1 (ConvertScanToMasterJson.ps1).

### Icon Deduplication

**Automatically extracts unique icons** from combat pet items in the fresh scan:
- Scans APIDump section in source file
- Filters by combat pet Group IDs
- Builds deduplicated icon list
- Emits `AV_IconList` with 14 unique icons

## Performance

- **Step 1**: ~2-3 seconds (line-by-line parsing, 9539 items → 2343 filtered)
- **Step 2**: ~1 second (JSON processing, icon dedup, Lua generation)
- **Total**: ~3-4 seconds for complete regeneration

## Legacy Scripts (Archived)

### ❌ MasterVanityDBPipeline.ps1
**Status**: Deprecated (hangs on large files)  
**Issue**: Complex regex on 76,000 lines too slow  
**Replacement**: ConvertScanToMasterJson.ps1

## Troubleshooting

### "Lua syntax error near 'X'"
- **Cause**: Improper string escaping
- **Fix**: Regenerate with latest scripts (escaping was fixed Nov 2025)

### "0 icons found"
- **Cause**: APIDump section not detected in scan file
- **Fix**: Ensure `data/AscensionVanity.lua` is a valid fresh scan

### Items missing descriptions
- **Cause**: Not yet enriched or researched
- **Fix**: Add to `data/corrections/ManualResearch.json` and regenerate

## Files Reference

### Source Data
- `data/AscensionVanity.lua` - Fresh scan from in-game (symlink to SavedVariables)
- `data/corrections/ManualResearch.json` - Manual research entries

### Generated Files
- `data/MasterFullValidated.json` - Intermediate: filtered, validated, enriched
- `AscensionVanity/VanityDB.lua` - Final: optimized for in-game use

### Scripts
- `utilities/ConvertScanToMasterJson.ps1` - Step 1: Scan → JSON
- `utilities/GenerateVanityDB_Master.ps1` - Step 2: JSON → VanityDB.lua
- `DeployAddon.ps1` - Deploy to WoW directory

## Version History

### 2025-11-02: Current Workflow
- ✅ Reliable line-by-line parsing (fast, no hangs)
- ✅ Proper string escaping (Lua ↔ JSON)
- ✅ Manual research integration
- ✅ Icon deduplication from fresh scan
- ✅ 2343 combat pets, 96.88% with descriptions

### Previous: MasterVanityDBPipeline.ps1
- ❌ Complex regex parsing (slow, error-prone)
- ❌ Escaping issues
- ❌ Hung on large files
