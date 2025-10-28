# Essential Files for v2.0-dev Branch

This document identifies the **essential files** for the v2.0-dev branch following DRY (Don't Repeat Yourself) and KISS (Keep It Simple, Stupid) principles.

## ✅ Core Addon Files (KEEP)

### Lua Code

```plaintext
AscensionVanity/
├── AscensionVanity.toc          # Addon manifest
├── Core.lua                     # Main addon initialization
├── VanityDB_Loader.lua          # Database loading logic
├── VanityDB_Regions.lua         # Icon region definitions
└── AscensionVanityConfig.lua    # Configuration defaults
```

### Data Files

```plaintext
AscensionVanity/
├── VanityDB.lua                 # Combat pet vanity item database
└── data/
    └── VanityDB.lua             # Source database (same content)
```

## ✅ PowerShell Utilities (KEEP)

### Essential Utilities

```plaintext
utilities/
├── GenerateVanityDB_V2.ps1              # Generate database from API dump
├── CompareGameExportToVanityDB.ps1      # Validate database accuracy
├── FilterTargetItems.ps1                # Filter combat pets from dumps
├── AnalyzeSourceCodes.ps1               # Analyze source code distribution
├── DeployAddon.ps1                      # Deploy addon to WoW
└── README.md                            # Utility documentation
```

### Supporting Scripts

```plaintext
utilities/
├── TransformApiToVanityDB.ps1           # Transform API data format
├── CompareAPIExport.ps1                 # Compare API exports
├── CompareDatabase.ps1                  # Compare database versions
└── UpdateDatabaseFromAPI.ps1            # Update from fresh API scan
```

## ✅ Documentation (KEEP)

### Root Documentation

```plaintext
/
├── README.md                    # Project overview and quick start
├── CHANGELOG.md                 # Version history
└── LICENSE                      # License information
```

### Essential Guides

```plaintext
docs/
├── PROJECT_STATUS.md                    # Current project status
├── QUICK_START.md                       # Getting started guide
├── API_SCANNER_REFINEMENTS.md           # API scanning refinements (latest)
└── guides/
    ├── API_SCANNING_GUIDE.md            # Complete API scanning workflow
    ├── API_QUICK_REFERENCE.md           # API reference (consolidated)
    ├── DEV_CONSOLE_REFERENCE.md         # Dev console guide (consolidated)
    ├── DEPLOYMENT_GUIDE.md              # Deployment instructions
    ├── CACHE_VERSIONING.md              # Cache versioning system
    └── TESTING_GUIDE.md                 # Testing procedures
```

### Technical Documentation

```plaintext
docs/
├── ENHANCED_DATA_MODEL.md               # V2 data model architecture
├── ARCHITECTURE_REFACTORING_PLAN.md     # Architecture overview
└── DATABASE_OPTIMIZATION_FINAL.md       # Database optimization summary
```

### Analysis Documentation

```plaintext
docs/analysis/
├── SKIPPED_ITEMS_ANALYSIS.md            # Analysis of excluded items
├── SPOT_CHECK_ANALYSIS.md               # Quality verification
└── VENDOR_ITEM_DISCOVERY.md             # Vendor item research
```

## ✅ Configuration Files (KEEP)

```plaintext
/
├── local.config.ps1             # Local deployment configuration
├── local.config.example.ps1     # Example configuration template
└── .gitignore                   # Git ignore rules
```

## ✅ Release Files (KEEP)

```plaintext
releases/
├── HOW_TO_RELEASE.md            # Release process documentation
└── RELEASE_NOTES_v1.0.0.md      # Version release notes
```

## ❌ Files Being Removed/Archived

### Archived to docs/archive/

- Session notes (dated development logs)
- V2 migration documentation (historical)
- Old changelog entries
- Temporary status files
- Previous archive folders

### Deleted (Redundant)

- Multiple API scanner quick-starts (consolidated)
- Redundant database comparison docs (consolidated)
- Duplicate developer console guides (consolidated)
- Duplicate API validation guides (consolidated)
- One-time operation documentation
- Obsolete TODO lists

## 📊 File Count Summary

| Category | Count | Description |
|----------|-------|-------------|
| **Addon Files** | 6 | Core Lua code and TOC |
| **Data Files** | 2 | VanityDB.lua (addon + source) |
| **Utilities** | 12 | PowerShell scripts |
| **Documentation** | 15 | Essential guides and references |
| **Configuration** | 3 | Config and examples |
| **Release** | 2 | Release documentation |
| **Total Essential** | **40** | Files to commit |

## 🎯 Consolidation Principles Applied

### DRY (Don't Repeat Yourself)

- ✅ Single source of truth for each topic
- ✅ API scanning consolidated into one comprehensive guide
- ✅ Developer console docs merged into single reference
- ✅ Database optimization combined into final summary

### KISS (Keep It Simple, Stupid)

- ✅ Clear file naming conventions
- ✅ Logical folder structure
- ✅ Removed historical/dated files
- ✅ Archived session notes (not needed in branch)
- ✅ Consolidated redundant guides

### Maintainability

- ✅ Each file has a clear, single purpose
- ✅ No duplicate information across files
- ✅ Easy to find what you need
- ✅ Minimal files to keep in sync

## 🚀 Next Steps

1. **Review this list** - Ensure no essential files are missing
2. **Run consolidation** - Execute `.\utilities\ConsolidateDocumentation.ps1`
3. **Update PROJECT_STATUS.md** - Reflect consolidated state
4. **Commit changes** - Clean branch ready for merge
5. **Prepare release** - Focus on essential features

## 📝 Notes

- **Archive folder** contains historical documentation for reference
- **Session notes** moved to archive (valuable for debugging but not for commits)
- **V2 migration docs** archived (historical context preserved)
- **All consolidation is reversible** (files archived, not deleted)
