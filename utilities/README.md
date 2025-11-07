# AscensionVanity Utilities

**Version:** 2.2-dev | **Last Updated:** November 7, 2025

## 🚀 Quick Start

### One-Command Pipeline
```powershell
# Full pipeline with deployment  
.\utilities\MasterPipeline_V2.ps1 -WoWPath "D:\OneDrive\Warcraft"

# Quick regeneration (skip import)
.\utilities\MasterPipeline_V2.ps1 -SkipImport -WoWPath "D:\OneDrive\Warcraft"
```

## 📋 Active Scripts

### **MasterPipeline_V2.ps1** ⭐ USE THIS!
All-in-one pipeline that runs everything automatically.

See: [docs/MASTER_PIPELINE_V2.md](../docs/MASTER_PIPELINE_V2.md)

### Core Pipeline Scripts
- `MasterAPIDumpImport.ps1` - Import game scans
- `NormalizeDescriptions.ps1` - Fix formatting
- `EnrichZoneData.ps1` - Extract zone data  
- `GenerateVanityDB_Master.ps1` - Create VanityDB.lua

### Utility Scripts
- `CompareGameExportToVanityDB.ps1` - Validation
- `MasterDescriptionEnrichment.ps1` - Web enrichment
- `ValidateCreatureIds.ps1` - ID checks
- `TestVanityDB.ps1` - Lua syntax validation

## 🗂️ Archived (v2.2)
Old pipeline scripts moved to: `utilities/archive/pre-v2.2-2025-11-07/`

## 📚 Documentation
- [MASTER_PIPELINE_V2.md](../docs/MASTER_PIPELINE_V2.md) - Quick reference
- [DATABASE_PIPELINE_VALIDATION.md](../docs/DATABASE_PIPELINE_VALIDATION.md) - Full guide
