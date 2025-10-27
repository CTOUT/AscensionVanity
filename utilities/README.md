# AscensionVanity Utility Scripts

This directory contains PowerShell utilities for database management, validation, and analysis.

## 🚀 **Primary Utilities**

### **AnalyzeAPIDump.ps1**
**Purpose**: Analyzes API dump from SavedVariables and generates validation reports

**Features**:
- Auto-detects SavedVariables path via registry or local.config.ps1
- Extracts validation statistics and category breakdowns
- Generates detailed analysis reports with -Detailed flag
- Compares API totals vs database totals

**Usage**:
```powershell
# Simple analysis
.\utilities\AnalyzeAPIDump.ps1

# Detailed reports
.\utilities\AnalyzeAPIDump.ps1 -Detailed

# Manual path (if auto-detection fails)
.\utilities\AnalyzeAPIDump.ps1 -SavedVariablesPath "C:\Path\To\AscensionVanity.lua"
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
1. Extract latest data: Run main `ExtractDatabase.ps1`
2. Validate API: `.\utilities\AnalyzeAPIDump.ps1 -Detailed`
3. Compare: `.\utilities\CompareGameExportToVanityDB.ps1`
4. Update: `.\utilities\UpdateDatabaseFromAPI.ps1`
5. Verify: `.\utilities\CountByCategory.ps1`

### **For Troubleshooting:**
1. Run diagnostics: `.\utilities\DiagnoseMissingItems.ps1`
2. Check sources: `.\utilities\AnalyzeSourceCodes.ps1`
3. Validate API dump: `.\utilities\AnalyzeAPIDump.ps1`

### **For Testing:**
1. Deploy addon: `..\DeployAddon.ps1`
2. Run in-game: `/av apidump` then `/reload`
3. Analyze: `.\utilities\AnalyzeAPIDump.ps1 -Detailed`

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

*Last updated: October 27, 2025*
