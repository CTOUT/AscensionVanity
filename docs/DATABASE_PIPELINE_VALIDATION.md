# Database Pipeline Validation & Process Guide

**Last Updated:** November 7, 2025  
**Version:** 2.2-dev

## 📋 Complete Database Update Process

### Prerequisites

1. **Fresh Game Scan**
   - In-game: `/avanity scanner`
   - Click "Start Full Scan"
   - Exit WoW to save `AscensionVanity.lua` to SavedVariables
   - Copy to `data/AscensionVanity_Fresh_Scan_YYYYMMDD.lua`

2. **Required Data Files**
   - `data/ZoneMappings.json` - Zone reference data
   - `data/QuestLockedNPCs.json` - Quest-locked NPC definitions
   - `data/API_to_GameID_Mapping.json` - ID mapping corrections

---

## 🔄 Pipeline Steps (Detailed)

### Step 1: Import Fresh Scan
**Script:** `utilities/MasterAPIDumpImport.ps1`

**What it does:**
- Loads `AscensionVanity_Fresh_Scan_*.lua`
- Filters to 5 combat pet Group IDs (16777217, 16777220, 16777218, 16777224, 16777232)
- Applies ID corrections from `API_to_GameID_Mapping.json`
- Removes vendor items (keyword filtering)
- **Output:** `data/MasterFullValidated.json` (RAW DATA)

**Command:**
```powershell
.\utilities\MasterAPIDumpImport.ps1
```

**Expected Output:**
- `MasterFullValidated.json` (~2,174 items)
- Backup created: `MasterFullValidated.json.backup-TIMESTAMP`

---

### Step 2: Normalize Descriptions
**Script:** `utilities/NormalizeDescriptions.ps1`

**What it does:**
- Standardizes description formatting
- Fixes: "with" → "within"
- Adds periods to end of sentences
- Consistent capitalization
- **Updates:** `data/MasterFullValidated.json` (IN-PLACE)

**Command:**
```powershell
.\utilities\NormalizeDescriptions.ps1
```

**Expected Changes:**
```
Before: "Has a chance to drop from Wolf with Elwynn Forest"
After:  "Has a chance to drop from Wolf within Elwynn Forest."
```

---

### Step 3: Enrich Zone Data
**Script:** `utilities/EnrichZoneData.ps1`

**What it does:**
- Extracts zone/subzone from descriptions using regex patterns
- Validates zones against `ZoneMappings.json`
- Adds `zone` and `subzone` fields to each item
- **Output:** `data/MasterFullValidated_ZoneEnriched.json` (NEW FILE)

**Command:**
```powershell
.\utilities\EnrichZoneData.ps1
```

**Example Extraction:**
```
Description: "Has a chance to drop from Wolf within Elwynn Forest (Northshire Valley)"
  → zone: "Elwynn Forest"
  → subzone: "Northshire Valley"
```

**Expected Output:**
- `MasterFullValidated_ZoneEnriched.json` (~95%+ with zone data)
- Items WITH zone field added

**CRITICAL:** After this step, copy enriched data to main file:
```powershell
Copy-Item data\MasterFullValidated_ZoneEnriched.json data\MasterFullValidated.json -Force
```

---

### Step 4: Generate VanityDB.lua
**Script:** `utilities/GenerateVanityDB_Master.ps1`

**What it does:**
- Loads `MasterFullValidated.json` (should have zone data!)
- Merges quest-locked NPC data from `QuestLockedNPCs.json`
- Deduplicates icon paths (creates `AV_IconList`)
- Groups items by creature ID
- Generates Lua table format
- **Output:** `AscensionVanity/VanityDB.lua` (FINAL DATABASE)

**Command:**
```powershell
.\utilities\GenerateVanityDB_Master.ps1
```

**Expected Output:**
```lua
AV_VanityItems = {
    [79001] = {
        name = "Beastmaster's Whistle: Wolf",
        creatureId = 1922,
        icon = "INV_Box_PetCarrier_01",
        description = "Has a chance to drop from Young Wolf within Elwynn Forest.",
        zone = "Elwynn Forest",      -- ← CRITICAL: Must be present!
        subzone = "",
        category = "Beastmaster's Whistle"
    },
    -- ... more items
}
```

---

### Step 5: Deploy & Test
**Script:** `DeployAddon.ps1`

**Command:**
```powershell
.\DeployAddon.ps1 -WoWPath "D:\OneDrive\Warcraft"
```

**In-Game Testing:**
1. `/reload`
2. Mouse over creatures - verify tooltips show zone data
3. `/avanity browser` - verify zone filter works
4. `/avanity guide` - verify regional guide shows current zone

---

## 🚀 Quick Start: Full Pipeline

### Option A: Manual Steps (Recommended for debugging)
```powershell
# 1. Import fresh scan
.\utilities\MasterAPIDumpImport.ps1

# 2. Normalize descriptions
.\utilities\NormalizeDescriptions.ps1

# 3. Enrich zone data
.\utilities\EnrichZoneData.ps1

# 4. Apply enriched data (CRITICAL!)
Copy-Item data\MasterFullValidated_ZoneEnriched.json data\MasterFullValidated.json -Force

# 5. Generate final database
.\utilities\GenerateVanityDB_Master.ps1

# 6. Deploy
.\DeployAddon.ps1 -WoWPath "D:\OneDrive\Warcraft"
```

### Option B: Automated Pipeline
```powershell
# Run full pipeline (interactive)
.\utilities\MasterDatabasePipeline.ps1

# Skip scan import (use existing data)
.\utilities\MasterDatabasePipeline.ps1 -SkipScan

# Test mode
.\utilities\MasterDatabasePipeline.ps1 -DryRun
```

---

## ✅ Validation Checklist

### After Each Step

#### Step 1: Import
- [ ] `MasterFullValidated.json` exists
- [ ] File size ~1-2 MB
- [ ] Item count ~2,174
- [ ] No `zone` field yet (raw data)

#### Step 2: Normalize
- [ ] Descriptions end with periods
- [ ] "with" replaced with "within"
- [ ] File modified timestamp updated

#### Step 3: Enrich
- [ ] `MasterFullValidated_ZoneEnriched.json` created
- [ ] 95%+ items have `zone` field
- [ ] Zone names match `ZoneMappings.json`
- [ ] **CRITICAL:** Enriched data copied to `MasterFullValidated.json`

#### Step 4: Generate
- [ ] `VanityDB.lua` exists in `AscensionVanity/` folder
- [ ] File contains `zone = "..."` entries
- [ ] File contains `AV_IconList` table
- [ ] File size ~400-600 KB

#### Step 5: Deploy & Test
- [ ] Tooltips show zone information
- [ ] Database browser zone filter works
- [ ] Regional guide displays current zone creatures
- [ ] No Lua errors

---

## 🔍 Troubleshooting

### Problem: VanityDB.lua missing zone data

**Symptom:** Tooltips/browser show "Unknown Zone"

**Cause:** Step 3 enriched data not copied to `MasterFullValidated.json`

**Fix:**
```powershell
# Copy enriched data
Copy-Item data\MasterFullValidated_ZoneEnriched.json data\MasterFullValidated.json -Force

# Regenerate database
.\utilities\GenerateVanityDB_Master.ps1

# Deploy
.\DeployAddon.ps1 -WoWPath "D:\OneDrive\Warcraft"
```

### Problem: Zone extraction failed

**Symptom:** `MasterFullValidated_ZoneEnriched.json` has 0% zone coverage

**Cause:** Descriptions not standardized or regex patterns incorrect

**Fix:**
```powershell
# Re-normalize descriptions
.\utilities\NormalizeDescriptions.ps1

# Try enrichment again
.\utilities\EnrichZoneData.ps1

# Check output
$data = Get-Content data\MasterFullValidated_ZoneEnriched.json -Raw | ConvertFrom-Json
$withZone = ($data | Where-Object { $_.zone }).Count
Write-Host "Items with zone: $withZone / $($data.Count)"
```

### Problem: Import failed

**Symptom:** `MasterFullValidated.json` is empty or has wrong item count

**Cause:** Fresh scan not found or corrupted

**Fix:**
```powershell
# List available scans
Get-ChildItem data\AscensionVanity_Fresh_Scan_*.lua

# Try import again
.\utilities\MasterAPIDumpImport.ps1

# If still fails, check scan file manually
Get-Content data\AscensionVanity_Fresh_Scan_*.lua | Select-String "AV_" -Context 2
```

---

## 📊 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    DATABASE PIPELINE                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [GAME]                                                      │
│    └─ AscensionVanity.lua (SavedVariables)                 │
│                                                              │
│           ↓ [COPY TO]                                        │
│                                                              │
│  [DATA]                                                      │
│    └─ AscensionVanity_Fresh_Scan_YYYYMMDD.lua              │
│                                                              │
│           ↓ [MasterAPIDumpImport.ps1]                       │
│                                                              │
│  [DATA]                                                      │
│    └─ MasterFullValidated.json (RAW)                       │
│       • ~2,174 items                                        │
│       • NO zone data yet                                    │
│                                                              │
│           ↓ [NormalizeDescriptions.ps1]                     │
│                                                              │
│  [DATA]                                                      │
│    └─ MasterFullValidated.json (NORMALIZED)                │
│       • Standardized descriptions                           │
│       • Still NO zone data                                  │
│                                                              │
│           ↓ [EnrichZoneData.ps1]                            │
│                                                              │
│  [DATA]                                                      │
│    └─ MasterFullValidated_ZoneEnriched.json                │
│       • 95%+ with zone field ✓                             │
│       • 60%+ with subzone field ✓                          │
│                                                              │
│           ↓ [COPY ENRICHED → MASTER] ← CRITICAL STEP!      │
│                                                              │
│  [DATA]                                                      │
│    └─ MasterFullValidated.json (WITH ZONES)                │
│       • Now has zone data! ✓                               │
│                                                              │
│           ↓ [GenerateVanityDB_Master.ps1]                  │
│           + QuestLockedNPCs.json                            │
│                                                              │
│  [ADDON]                                                     │
│    └─ AscensionVanity/VanityDB.lua                         │
│       • Final deployable database                           │
│       • Lua table format                                    │
│       • Ready for in-game use ✓                            │
│                                                              │
│           ↓ [DeployAddon.ps1]                               │
│                                                              │
│  [GAME]                                                      │
│    └─ World of Warcraft/AddOns/AscensionVanity/            │
│       • Live in-game!                                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Key Takeaways

1. **Zone data comes from Step 3** (`EnrichZoneData.ps1`)
2. **MUST copy** `_ZoneEnriched.json` to `MasterFullValidated.json`
3. **Step 4** (`GenerateVanityDB_Master.ps1`) reads `MasterFullValidated.json`
4. **VanityDB.lua** is the FINAL output that goes into the game
5. **Each step is independent** - can be re-run without affecting others

---

## 📝 Quick Reference

| File | Purpose | Has Zone Data? |
|------|---------|---------------|
| `AscensionVanity_Fresh_Scan_*.lua` | Raw game export | ❌ No |
| `MasterFullValidated.json` | Working file | ⚠️ After Step 3 copy |
| `MasterFullValidated_ZoneEnriched.json` | Zone enriched | ✅ Yes |
| `VanityDB.lua` | Final database | ✅ Yes (if Step 3 ran) |

---

**See Also:**
- `docs/DATABASE_PIPELINE_ARCHITECTURE.md` - Design philosophy
- `docs/VANITYDB_GENERATION_WORKFLOW.md` - Detailed workflow
- `utilities/MasterDatabasePipeline.ps1` - Automated pipeline

