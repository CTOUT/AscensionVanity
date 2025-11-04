# Database Pipeline Architecture

## Overview

The database update process is **intentionally separated** into discrete, independent steps rather than being a monolithic integrated process.

## Pipeline Stages

```
┌─────────────────────────────────────────────────────────────────┐
│                     DATABASE PIPELINE                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. [MANUAL] API Scan                                           │
│     └─ In-game: /avanity scanner → Export                      │
│     └─ Output: AscensionVanity_Fresh_Scan_*.lua                │
│                                                                  │
│  2. [SCRIPT] Import & Transform                                 │
│     └─ MasterAPIDumpImport.ps1                                 │
│     └─ Output: MasterFullValidated.json (raw)                  │
│                                                                  │
│  3. [SCRIPT] Normalize Descriptions                             │
│     └─ NormalizeDescriptions.ps1                               │
│     └─ Fixes: "with" → "within", add periods                   │
│                                                                  │
│  4. [SCRIPT] Enrich Zone Data                                   │
│     └─ EnrichZoneData.ps1                                      │
│     └─ Extracts zones from descriptions                        │
│                                                                  │
│  5. [SCRIPT] Generate Final Database                            │
│     └─ GenerateVanityDB_Master.ps1                            │
│     └─ Output: VanityDB.lua (deployable)                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Why Separate Steps?

### ✅ Advantages

1. **Reproducibility**
   - Can re-enrich without re-scanning (scans take time!)
   - Can re-normalize without re-enriching
   - Each step produces versioned output

2. **Debugging & Testing**
   - Test individual steps without running full pipeline
   - Isolate failures to specific stage
   - Easier to debug regex patterns, etc.

3. **Performance**
   - Only run what changed
   - Skip expensive steps when not needed
   - Parallel development (work on different stages)

4. **Caching**
   - Description enrichment results persist between scans
   - Zone mappings don't need regeneration
   - Manual research doesn't get lost

5. **Auditing**
   - Clear history of what was enriched when
   - Backup files at each stage
   - Can diff between versions

### ❌ Disadvantages of Integration

If we integrated everything into the scan process:

- ⏱️ **Slower**: Scans would take hours instead of seconds
- 🌐 **Fragile**: API downtime breaks entire scan
- 💥 **All-or-nothing**: One failure ruins entire batch
- 🔁 **Wasteful**: Re-enriches unchanged items every time
- 🐛 **Hard to debug**: Which step failed?

## Master Pipeline Script

For convenience, we provide `MasterDatabasePipeline.ps1` that chains all steps:

```powershell
# Full pipeline
.\utilities\MasterDatabasePipeline.ps1

# Skip certain steps
.\utilities\MasterDatabasePipeline.ps1 -SkipScan -SkipNormalization

# Test mode
.\utilities\MasterDatabasePipeline.ps1 -DryRun
```

**But remember:** Each step is still independent and can be run standalone!

## Individual Scripts

### 1. MasterAPIDumpImport.ps1
**Purpose:** Import fresh scan from game  
**Input:** `AscensionVanity_Fresh_Scan_*.lua`  
**Output:** `MasterFullValidated.json`  
**Runtime:** ~5 seconds  
**Frequency:** After each game scan

### 2. NormalizeDescriptions.ps1
**Purpose:** Standardize description formatting  
**Input:** `MasterFullValidated.json`  
**Output:** `MasterFullValidated.json` (updated)  
**Runtime:** ~2 seconds  
**Frequency:** After import or description changes

### 3. EnrichZoneData.ps1
**Purpose:** Extract zone/subzone from descriptions  
**Input:** `MasterFullValidated.json`  
**Output:** `MasterFullValidated_ZoneEnriched.json`  
**Runtime:** ~2 seconds  
**Frequency:** After description changes

### 4. GenerateVanityDB_Master.ps1
**Purpose:** Convert JSON to Lua database  
**Input:** `MasterFullValidated.json`  
**Output:** `VanityDB.lua`  
**Runtime:** ~3 seconds  
**Frequency:** After any data changes

## Data Flow

```
Game Scan (immutable)
    ↓
Raw JSON (immutable source)
    ↓
Normalized Descriptions (versioned)
    ↓
Zone Enriched (versioned)
    ↓
Final VanityDB.lua (deployable)
```

Each arrow is a **separate, testable, reproducible step**.

## When to Run What

**Scenario: New game scan**
```powershell
# Full pipeline
.\utilities\MasterDatabasePipeline.ps1
```

**Scenario: Fixed description formatting**
```powershell
# Just regenerate from existing data
.\utilities\NormalizeDescriptions.ps1
.\utilities\EnrichZoneData.ps1
.\utilities\GenerateVanityDB_Master.ps1
```

**Scenario: Updated zone parsing logic**
```powershell
# Skip scan and normalization
.\utilities\EnrichZoneData.ps1
.\utilities\GenerateVanityDB_Master.ps1
```

**Scenario: Quick test of database generation**
```powershell
# Just regenerate Lua
.\utilities\GenerateVanityDB_Master.ps1
```

## Design Philosophy

> **"Make each program do one thing well. To do a new job, build afresh rather than complicate old programs by adding new features."**  
> — Unix Philosophy

We follow this principle:
- Each script has **one clear purpose**
- Scripts are **composable** (can be chained)
- Pipeline is **optional convenience**, not requirement
- Each step produces **versioned, auditable output**

## Future Considerations

If we ever need to:
- Add AI-based description generation
- Integrate with external APIs for enrichment
- Add manual review workflows
- Support multiple languages

...we simply add new standalone scripts to the pipeline, without touching existing ones!

---

**See also:**
- `utilities/README.md` - Script documentation
- `docs/VANITYDB_GENERATION_WORKFLOW.md` - Detailed workflow
- `utilities/MasterDatabasePipeline.ps1` - Convenience wrapper
