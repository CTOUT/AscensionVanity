# Documentation Consolidation Plan - v2.0-dev Branch

## 🎯 Objective

Apply DRY and KISS principles to consolidate redundant documentation and keep only essential files for the v2.0 release.

## 📊 Current State Analysis

### Root Documentation (9 files)
- ✅ **KEEP**: README.md, CHANGELOG.md, LICENSE
- ✅ **KEEP**: CreateRelease.ps1, DeployAddon.ps1, ExecuteCleanup.ps1, ExtractDatabase.ps1
- ❌ **REMOVE**: API_VALIDATION_COMPLETE.md (redundant with guides)
- ❌ **REMOVE**: NEXT_STEPS.md (temporary planning doc)

### docs/ Folder (26 files)

#### 🔄 REDUNDANT - API Scanner Documentation (5 files saying same thing!)
- API_SCANNER_REFINED_SUMMARY.md
- API_SCANNER_REFINEMENTS.md ← **KEEP THIS ONE** (most comprehensive)
- API_SCANNER_SIMPLIFICATION.md
- API_SCANNING_QUICKSTART.md
- IN_GAME_SCANNING_WORKFLOW.md
- FRESH_SCAN_WORKFLOW.md

**Action**: Consolidate into ONE file: `guides/API_SCANNING_GUIDE.md`

#### 🔄 REDUNDANT - Quick Start Guides (3 files!)
- QUICK_START.md
- QUICK_START_NEW_WORKFLOW.md
- V2_QUICK_REFERENCE.md ← **KEEP THIS ONE**

**Action**: Consolidate into ONE file: `QUICK_START.md` in root

#### 🔄 REDUNDANT - Database Documentation (3 files!)
- DATABASE_COMPARISON_EXPLANATION.md
- DATABASE_OPTIMIZATION_COMPLETE.md
- DATABASE_OPTIMIZATION_FINAL.md ← **KEEP THIS ONE**

**Action**: Consolidate into ONE file: `guides/DATABASE_GUIDE.md`

#### 🔄 REDUNDANT - Project Status/Summary (4 files!)
- PROJECT_STATUS.md
- V2_BRANCH_SUMMARY.md
- V2_MIGRATION_COMPLETE.md
- V2_DATA_MODEL_SUMMARY.md

**Action**: Keep ONE in root: `PROJECT_STATUS.md` (updated with v2.0 info)

#### 📝 Session Notes (3 files - ARCHIVE)
- SESSION_NOTES_2025-01-26.md
- SESSION_NOTES_2025-10-27_API_VALIDATION.md
- SESSION_NOTES_2025-10-27_MULTIPLE_ITEMS.md
- TEST_RESULTS_2025-10-27.md

**Action**: Move to `docs/archive/session_notes/`

#### ✅ KEEP - Essential Documentation
- ARCHITECTURE_REFACTORING_PLAN.md (architecture reference)
- ENHANCED_DATA_MODEL.md (data model spec)
- IMPLEMENTATION_ROADMAP.md (development roadmap)
- LOCAL_CONFIG.md (configuration guide)
- TESTING_CHECKLIST.md (QA reference)
- V2_IMPLEMENTATION_CHECKLIST.md (dev checklist)

### docs/guides/ (13 files)

#### 🔄 REDUNDANT - Developer Console (3 files!)
- DEVELOPER_CONSOLE_GUIDE.md
- DEV_CONSOLE_REFERENCE.md ← **KEEP THIS ONE**
- DEV_CONSOLE_TESTING.md

**Action**: Consolidate into ONE: `guides/DEVELOPER_CONSOLE.md`

#### 🔄 REDUNDANT - API Documentation (3 files!)
- API_EXPORT_COMPARISON.md
- API_QUICK_REFERENCE.md ← **KEEP THIS ONE**
- API_VALIDATION_GUIDE.md

**Action**: Consolidate into ONE: `guides/API_REFERENCE.md`

#### ✅ KEEP - Essential Guides
- CACHE_VERSIONING.md
- DEPLOYMENT_GUIDE.md
- EXTRACTION_GUIDE.md
- README_DOCUMENTATION.md

#### ❌ REMOVE - Temporary/Obsolete
- FILE_RENAME_SUMMARY.md (one-time operation, done)
- TODO_FUTURE_INVESTIGATIONS.md (move to GitHub issues)

### docs/analysis/ (3 files - ARCHIVE)
- SKIPPED_ITEMS_ANALYSIS.md
- SPOT_CHECK_ANALYSIS.md
- VENDOR_ITEM_DISCOVERY.md

**Action**: Keep in archive for reference

### Archive Folders
- docs/archive/ (old files)
- docs/archive_20251027/ (recent cleanup)
- docs/changelog/ (PROJECT_STATUS_CORRECTIONS.md)

**Action**: Consolidate into ONE archive folder: `docs/archive/`

## 📋 Consolidation Actions

### Phase 1: Create Consolidated Files

1. **API_SCANNING_GUIDE.md** (consolidate 6 files)
   - Combines: API_SCANNER_REFINEMENTS.md + all workflow docs
   - Location: `docs/guides/API_SCANNING_GUIDE.md`

2. **DEVELOPER_CONSOLE.md** (consolidate 3 files)
   - Combines: All dev console guides
   - Location: `docs/guides/DEVELOPER_CONSOLE.md`

3. **API_REFERENCE.md** (consolidate 3 files)
   - Combines: All API documentation
   - Location: `docs/guides/API_REFERENCE.md`

4. **DATABASE_GUIDE.md** (consolidate 3 files)
   - Combines: All database documentation
   - Location: `docs/guides/DATABASE_GUIDE.md`

5. **QUICK_START.md** (consolidate 3 files)
   - Combines: All quick start guides
   - Location: `docs/QUICK_START.md` (root docs)

6. **PROJECT_STATUS.md** (consolidate 4 files)
   - Combines: All status/summary docs
   - Location: `docs/PROJECT_STATUS.md`

### Phase 2: Archive Session Notes

Move to: `docs/archive/session_notes/`
- SESSION_NOTES_2025-01-26.md
- SESSION_NOTES_2025-10-27_API_VALIDATION.md
- SESSION_NOTES_2025-10-27_MULTIPLE_ITEMS.md
- TEST_RESULTS_2025-10-27.md

### Phase 3: Clean Up Root

Remove from root:
- API_VALIDATION_COMPLETE.md
- NEXT_STEPS.md

### Phase 4: Remove Redundant Files

After consolidation, delete source files:
- All redundant API scanner docs (5 files)
- All redundant quick start docs (2 files)
- All redundant database docs (2 files)
- All redundant status docs (3 files)
- All redundant dev console docs (2 files)
- All redundant API docs (2 files)
- FILE_RENAME_SUMMARY.md
- TODO_FUTURE_INVESTIGATIONS.md

### Phase 5: Consolidate Archives

Merge `docs/archive_20251027/` into `docs/archive/`
Merge `docs/changelog/` into `docs/archive/`

## 🎯 Final Documentation Structure

```
AscensionVanity/
├── README.md                          # Main readme
├── CHANGELOG.md                       # Version history
├── LICENSE                            # Legal
├── *.ps1                             # Utility scripts (7 files)
│
├── docs/
│   ├── QUICK_START.md                # User guide (consolidated)
│   ├── PROJECT_STATUS.md             # Current status (consolidated)
│   ├── ARCHITECTURE_REFACTORING_PLAN.md
│   ├── ENHANCED_DATA_MODEL.md
│   ├── IMPLEMENTATION_ROADMAP.md
│   ├── LOCAL_CONFIG.md
│   ├── TESTING_CHECKLIST.md
│   ├── V2_IMPLEMENTATION_CHECKLIST.md
│   │
│   ├── guides/
│   │   ├── API_SCANNING_GUIDE.md     # Consolidated (6→1)
│   │   ├── API_REFERENCE.md          # Consolidated (3→1)
│   │   ├── DATABASE_GUIDE.md         # Consolidated (3→1)
│   │   ├── DEVELOPER_CONSOLE.md      # Consolidated (3→1)
│   │   ├── CACHE_VERSIONING.md
│   │   ├── DEPLOYMENT_GUIDE.md
│   │   ├── EXTRACTION_GUIDE.md
│   │   └── README_DOCUMENTATION.md
│   │
│   ├── analysis/                     # Keep for reference
│   │   ├── SKIPPED_ITEMS_ANALYSIS.md
│   │   ├── SPOT_CHECK_ANALYSIS.md
│   │   └── VENDOR_ITEM_DISCOVERY.md
│   │
│   └── archive/                      # Historical reference
│       ├── session_notes/
│       │   ├── SESSION_NOTES_2025-01-26.md
│       │   ├── SESSION_NOTES_2025-10-27_API_VALIDATION.md
│       │   ├── SESSION_NOTES_2025-10-27_MULTIPLE_ITEMS.md
│       │   └── TEST_RESULTS_2025-10-27.md
│       └── [old consolidated archives]
│
└── utilities/                        # Keep all (needed for workflow)
```

## 📊 Impact Summary

### Before Consolidation
- Root: 11 files
- docs/: 26 files
- docs/guides/: 13 files
- **Total: 50 files**

### After Consolidation
- Root: 9 files (-2)
- docs/: 8 files (-18)
- docs/guides/: 8 files (-5)
- docs/analysis/: 3 files (kept)
- docs/archive/: ~10 files (moved)
- **Total: 28 active files (-22 = 44% reduction)**

## ✅ Benefits

- **DRY**: No duplicate information across multiple files
- **KISS**: Simple, clear structure - one topic per file
- **Maintainable**: Fewer files to keep updated
- **Discoverable**: Clear naming, logical organization
- **Clean**: Historical/temporary files properly archived

## 🚀 Execution Order

1. Create consolidated files (Phase 1)
2. Verify content completeness
3. Archive session notes (Phase 2)
4. Clean up root (Phase 3)
5. Delete redundant files (Phase 4)
6. Merge archive folders (Phase 5)
7. Update README.md to reference new structure
8. Commit with message: "docs: Consolidate documentation following DRY/KISS principles"
