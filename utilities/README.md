# AscensionVanity Utility Scripts

This directory contains PowerShell utilities for database management, validation, and analysis.

## � **Fresh Scan Workflow**

### **PrepareForFreshScan.ps1**
**Purpose**: Prepares for a complete fresh scan of all vanity items in-game

**Features**:
- Automatically backs up current SavedVariables with timestamp
- Safely clears existing scan data to ensure clean slate
- Provides step-by-step instructions for in-game scanning
- Preserves scan history in backups directory

**Usage**:
```powershell
# Standard fresh scan preparation (with backup)
.\utilities\PrepareForFreshScan.ps1

# Skip backup (not recommended)
.\utilities\PrepareForFreshScan.ps1 -NoBackup

# Force without confirmation prompt
.\utilities\PrepareForFreshScan.ps1 -Force
```

**When to use**:
- Missing DB item ID mappings for many items
- Want to ensure complete coverage of all in-game items
- After major game updates or patch changes
- Starting fresh database generation from scratch

**Workflow**:
1. Run `PrepareForFreshScan.ps1` (creates backup, clears data)
2. Launch WoW and run `/run AscensionVanity:ScanAllItems()`
3. Wait for scan completion message
4. Exit WoW to save the new data
5. Run `GenerateVanityDB_V2.ps1` to build database

---

## �🚀 **Primary Utilities**

### **MasterAPIDumpImport.ps1**
**Purpose**: Master workflow for importing, normalizing, and summarizing the AscensionVanity API dump.

**Features**:
- Resolves `AscensionVanity.lua` automatically (local.config.ps1 → registry → manual guidance)
- Emits timestamped fresh scan files in `data/` (with optional labels) plus a `…_LATEST.lua` convenience copy
- Generates `API_to_GameID_Mapping.json` alongside timestamped history snapshots
- Produces category, creature, and description coverage summaries for quick validation
- Consolidates the legacy scripts (`ProcessAPIDump`, `AnalyzeAPIDump`, `ExtractGameIDs*`, `ProcessFreshScan`) now archived under `utilities/archive/api-import/`

**Usage**:
```powershell
# Standard import using auto-detection
.\utilities\MasterAPIDumpImport.ps1

# Explicit SavedVariables path with a label and no summary file
.\utilities\MasterAPIDumpImport.ps1 -SavedVariablesPath "C:\Path\To\AscensionVanity.lua" -ScanLabel PREPATCH -SkipSummaryFile

# Parse mapping only (no fresh scan copy)
.\utilities\MasterAPIDumpImport.ps1 -NoScanCopy
```

---

### **CompareAPIExport.ps1**
**Purpose**: Compares in-game API export against static VanityDB.lua

**Usage**:
```powershell
.\utilities\CompareAPIExport.ps1
```

**What it does**:
- Reads both GameExport and VanityDB from SavedVariables
- Identifies items in API but not in database
- Highlights mismatches and missing entries

---

### **CompareGameExportToVanityDB.ps1**
**Purpose**: Advanced comparison tool for database validation

**Features**:
- Line-by-line comparison of API export vs static database
- Identifies missing items, extra items, and mismatches
- Generates detailed comparison reports

**Usage**:
```powershell
.\utilities\CompareGameExportToVanityDB.ps1
```

---

### **UpdateDatabaseFromAPI.ps1**
**Purpose**: Semi-automated database updates from API dump

**Features**:
- Merges new items from API into VanityDB.lua
- Handles multi-item creatures (arrays)
- Creates backup before making changes
- Validates data integrity

**Usage**:
```powershell
.\utilities\UpdateDatabaseFromAPI.ps1
```

---

## 📊 **Analysis & Diagnostics**

### **CountByCategory.ps1**
**Purpose**: Counts items by category in the database

**Usage**:
```powershell
.\utilities\CountByCategory.ps1
```

**Output**:
```
Whistle: 45 items
Vellum: 38 items
Stone: 12 items
...
```

---

### **DiagnoseMissingItems.ps1**
**Purpose**: Identifies and analyzes missing items from extraction

**Features**:
- Compares expected vs actual extraction counts
- Identifies skipped items and their reasons
- Generates diagnostic reports

**Usage**:
```powershell
.\utilities\DiagnoseMissingItems.ps1
```

---

### **AnalyzeSourceCodes.ps1**
**Purpose**: Analyzes source code distribution in database

**Usage**:
```powershell
.\utilities\AnalyzeSourceCodes.ps1
```

**What it shows**:
- Breakdown of items by source (Drop, Quest, Vendor, etc.)
- Distribution statistics
- Category-by-source matrix

---

### **CompareDatabase.ps1**
**Purpose**: Compares different versions of the database

**Usage**:
```powershell
.\utilities\CompareDatabase.ps1 -Version1 "path1" -Version2 "path2"
```

---

## 🔧 **Supporting Scripts**

### **ImportResults.ps1**
**Purpose**: Imports extraction results into database format

### **AnalyzeResults.ps1**
**Purpose**: Analyzes extraction results for quality and completeness

---

## 📋 **Workflow Recommendations**

### **For Database Updates:**
1. Import latest SavedVariables dump: `.\utilities\MasterAPIDumpImport.ps1`
2. Regenerate VanityDB.lua: `.\utilities\MasterVanityDBPipeline.ps1`
3. Compare current vs previous: `.\utilities\CompareGameExportToVanityDB.ps1`
4. Validate anomalies: `.\utilities\ValidateCreatureIds.ps1`
5. Spot-check counts: `.\utilities\CountByCategory.ps1`

### **For Troubleshooting:**
1. Run diagnostics: `.\utilities\DiagnoseMissingItems.ps1`
2. Check sources: `.\utilities\AnalyzeSourceCodes.ps1`
3. Validate API dump: `.\utilities\MasterAPIDumpImport.ps1 -SkipMappingExport -SkipSummaryFile`

### **For Testing:**
1. Deploy addon: `..\DeployAddon.ps1`
2. Run in-game: `/avanity apidump` then `/reload`
3. Analyze: `.\utilities\MasterAPIDumpImport.ps1 -SkipMappingExport`

---

## 💡 **Tips**

- Most scripts support `-WhatIf` for preview mode
- Use `-Verbose` for detailed logging
- Check script headers for additional parameters
- Always backup before running update scripts

---

## 📦 **Dependencies**

All scripts require:
- PowerShell 5.1 or later
- Access to AscensionVanity.lua SavedVariables file
- Optional: `local.config.ps1` for automatic path detection

---

*Last updated: November 1, 2025*
