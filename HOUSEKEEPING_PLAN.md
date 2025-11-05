# Project Housekeeping Plan - November 5, 2025

## 📋 Overview
Consolidate documentation, archive old files, create shared script libraries, and implement caching for better performance.

---

## 1. Documentation Consolidation

### Archive Old Session Documents
**Action**: Move completed session docs to archive
```
docs/SESSION_2025-11-03_PROGRESS_TRACKER.md → docs/archive/sessions/
docs/SESSION_2025-11-04_DATABASE_BROWSER.md → docs/archive/sessions/
docs/SESSION_2025-11-04_PROGRESS_TRACKER.md → docs/archive/sessions/
```
**Keep**: `docs/SESSION_2025-11-05_FINAL_SUMMARY.md` (most recent)

### Consolidate Feature Roadmaps
**Action**: Archive old roadmaps, keep only current
```
FEATURE_ROADMAP_V2.1.md → docs/archive/
FEATURE_ROADMAP_V2.2.md → Keep (current version)
```

### Consolidate Test Checklists
**Action**: Archive old checklists
```
TEST_CHECKLIST_V2.1.md → docs/archive/
TEST_CHECKLIST_V2.2.md → Keep (current version)
```

### Update Main Documentation
**Files to Review**:
- `README.md` - Ensure up-to-date with v2.2 features
- `docs/PROJECT_STATUS.md` - Update with latest stats (2,351 items, 100% coverage)
- `docs/QUICK_START.md` - Verify instructions are current

---

## 2. Script Consolidation & Shared Libraries

### Create Shared Library Structure
```
utilities/lib/
├── WebCache.psm1          # HTTP caching (24-48hr TTL)
├── DbAscensionAPI.psm1    # db.ascension.gg wrapper functions
├── ZoneMapping.psm1       # Zone ID ↔ Name conversion
└── Common.psm1            # Shared utility functions
```

### Functions to Extract & Share

#### WebCache.psm1
- `Get-CachedWebRequest` - Cached HTTP GET with TTL
- `Clear-WebCache` - Manual cache cleanup
- `Get-CacheStats` - Show hit/miss rates

#### DbAscensionAPI.psm1
- `Get-AscensionItem` - Item lookup by ID
- `Get-AscensionCreature` - Creature lookup by ID
- `Search-AscensionCreatures` - Name search
- `Get-AscensionZoneMap` - Zone ID mapping (cached)

#### ZoneMapping.psm1
- `Get-ZoneName` - Convert zone ID to name
- `Get-ZoneId` - Convert zone name to ID
- `Import-ZoneMap` - Load zone mappings

#### Common.psm1
- `Write-ColorHost` - Colored console output
- `Get-ItemNameParts` - Parse "Category: Name" format
- `Test-VendorItem` - Check vendor exemption

### Scripts to Refactor
**High Priority**:
- `EnrichMissingDescriptions.ps1` - Use DbAscensionAPI + WebCache
- `ValidateHighCreatureIDs.ps1` - Use DbAscensionAPI + WebCache
- `EnrichZoneData.ps1` - Use ZoneMapping

**Medium Priority**:
- `MasterAPIDumpImport.ps1` - Use Common functions
- `GenerateVanityDB_Master.ps1` - Use ZoneMapping

---

## 3. Caching Strategy

### Cache Location
```
data/cache/
├── web/           # HTTP response cache
│   ├── db.ascension.gg/
│   └── wowhead.com/
├── zones/         # Zone mapping cache
└── metadata.json  # Cache metadata (TTL, stats)
```

### Cache Policy
- **Zone Mappings**: 7 days TTL (rarely changes)
- **Item/Creature Lookups**: 24 hours TTL
- **Search Results**: 12 hours TTL
- **Max Cache Size**: 100 MB (auto-cleanup oldest)

### Benefits
- ⚡ **10-20x faster** re-runs (no web requests)
- 🌐 **Reduced server load** on db.ascension.gg
- 🔄 **Reproducible builds** (same results for same day)
- 📊 **Better testing** (consistent data during development)

---

## 4. Archive Old Files

### Data Backups
**Action**: Keep only last 3 backups per type
```powershell
# Keep: Latest 3 of each pattern
# Remove: Older backups

data/backups/
├── Keep: MasterFullValidated.json.backup-YYYYMMDD (latest 3)
├── Keep: ZoneMappings_backup_YYYYMMDD (latest 3)
└── Remove: Older than 30 days
```

### Script Archive
**Action**: Move deprecated scripts to archive
```
utilities/archive/
└── (Keep existing archived scripts)
```

**Candidates for Archive**:
- None currently - all scripts are active or recently used

---

## 5. Code Quality Improvements

### Add Script Headers
**Standard Header Template**:
```powershell
<#
.SYNOPSIS
    Brief description

.DESCRIPTION
    Detailed description
    Dependencies: List any required modules

.PARAMETER Name
    Parameter description

.EXAMPLE
    .\ScriptName.ps1 -Parameter Value

.NOTES
    Author: CMTout
    Last Updated: YYYY-MM-DD
    Version: X.Y.Z
    Requires: PowerShell 7+
    Dependencies: Module1, Module2
#>
```

### Add Error Handling
**Pattern**:
```powershell
$ErrorActionPreference = 'Stop'

try {
    # Main logic
} catch {
    Write-Error "Script failed: $_"
    exit 1
}
```

### Add Progress Indicators
**For long-running operations**:
```powershell
Write-Progress -Activity "Processing items" -Status "$i of $total" -PercentComplete (($i/$total)*100)
```

---

## 6. Git Repository Cleanup

### .gitignore Updates
```gitignore
# Cache directories
data/cache/

# Temporary files
*.tmp
*.temp

# Large backup files (keep in local only)
data/backups/*.json.backup-*

# IDE files
.vscode/.history/
```

### Commit Structure
```
feat: Add Group ID validation and seasonal pet support
refactor: Create shared script libraries for web caching
docs: Consolidate and archive old documentation
chore: Clean up old backups and temporary files
```

---

## 7. Implementation Priority

### Phase 1: Immediate (Today)
1. ✅ Archive old session documents
2. ✅ Archive old roadmaps and checklists
3. ✅ Update PROJECT_STATUS.md with latest stats
4. ✅ Commit Group ID changes

### Phase 2: Short-term (This Week)
1. Create shared library structure (utilities/lib/)
2. Implement WebCache.psm1
3. Implement DbAscensionAPI.psm1
4. Refactor EnrichMissingDescriptions.ps1 to use libraries

### Phase 3: Medium-term (Next Week)
1. Implement ZoneMapping.psm1
2. Refactor all enrichment scripts
3. Add comprehensive script headers
4. Performance testing and optimization

---

## 8. Success Metrics

### Performance Improvements
- **Target**: 10-20x faster enrichment re-runs (with cache)
- **Target**: < 5 seconds for zone mapping lookups (cached)
- **Target**: < 2 seconds for validation checks (cached)

### Code Quality
- **Target**: All scripts have standardized headers
- **Target**: All scripts use shared libraries (DRY principle)
- **Target**: All scripts have error handling and progress indicators

### Documentation
- **Target**: All archived docs moved to docs/archive/
- **Target**: README.md and PROJECT_STATUS.md up-to-date
- **Target**: All shared libraries documented

---

## 9. Next Steps

**Immediate Actions**:
1. Run housekeeping scripts to archive old files
2. Update PROJECT_STATUS.md
3. Commit changes with structured commit messages
4. Begin Phase 2 (shared libraries)

**Future Considerations**:
- Automated backup rotation script
- Cache statistics and monitoring
- Performance benchmarking suite
- Integration tests for shared libraries

---

**Created**: November 5, 2025  
**Status**: Ready for implementation  
**Estimated Time**: Phase 1 (30 min), Phase 2 (2-3 hours), Phase 3 (3-4 hours)
