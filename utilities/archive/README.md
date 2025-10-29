# Archived Scripts

This directory contains scripts that have been superseded, consolidated, or are no longer actively used. They are preserved for historical reference and potential future needs.

## Archive Date
**October 29, 2025**

---

## Directory Structure

### `enrichment_scripts/` (16 scripts)
**Purpose:** Description enrichment workflows that have been consolidated into `MasterDescriptionEnrichment.ps1`

**Superseded by:** `utilities/MasterDescriptionEnrichment.ps1`

**Key Scripts:**
- `CompleteDescriptionEnrichment.ps1` - Multi-step enrichment workflow
- `SearchEmptyDescriptions_CORRECT.ps1` - db.ascension.gg search
- `SearchFinalEmptyDescriptions.ps1` - Wowhead WOTLK search
- `ApplyValidatedDescriptions.ps1` - Pattern matching updates
- `FindEmptyDescriptions.ps1` - Empty description scanner

**Why Archived:**
All functionality has been consolidated into a single master script that provides:
- 95-97% automation (vs. manual multi-step workflow)
- Multi-source search (db.ascension.gg + Wowhead WOTLK)
- Safe pattern-matching updates
- Comprehensive reporting (CSV, JSON, TXT)
- Dry-run mode for testing

**Historical Value:**
- Shows evolution of enrichment workflow
- Contains original search patterns
- Documents manual validation approaches

---

### `analysis_scripts/` (13 scripts)
**Purpose:** One-off analysis and debugging tools used during development

**Key Scripts:**
- `AnalyzeBlankDescriptions.ps1` - Initial blank description analysis
- `AnalyzeIconUsage.ps1` - Icon optimization analysis
- `TestWowheadPattern.ps1` - Pattern matching tests
- `FixJsonUnicodeEscapes.ps1` - Unicode issue debugging

**Why Archived:**
- One-off debugging/analysis tasks
- Issues have been resolved
- Functionality integrated into master scripts where needed

**Historical Value:**
- Documents debugging approaches
- Shows problem-solving evolution
- Contains useful analysis patterns

---

### `generation_scripts/` (14 scripts)
**Purpose:** Database generation iterations and experimental approaches

**Key Scripts:**
- `GenerateVanityDB_Complete.ps1` - Earlier generation approach
- `GenerateVanityDB_Final.ps1` - Pre-consolidation generator
- `TransformApiToVanityDB.ps1` - API transformation logic
- `FilterCombatPetsOnly.ps1` - Combat pet filtering

**Why Archived:**
- Superseded by current generation workflow
- Experimental approaches that didn't pan out
- Functionality integrated into active scripts

**Historical Value:**
- Shows database structure evolution
- Documents filtering approaches
- Contains alternative generation logic

---

## Active Scripts Remaining

After consolidation, the following **core scripts** remain active in `utilities/`:

### Primary Workflows:
1. `MasterDescriptionEnrichment.ps1` - **MASTER ENRICHMENT AUTOMATION**
   - Consolidates 5+ enrichment workflows
   - 95-97% automation rate
   - Multi-source search capability

2. `AnalyzeFreshScan.ps1` - Fresh API scan analysis
3. `ProcessFreshScan.ps1` - API scan processing

### Database Management:
4. `CompareAPIExport.ps1` - API export comparison
5. `CompareDatabase.ps1` - Database comparison
6. `CompareGameExportToVanityDB.ps1` - Game export validation
7. `DiagnoseMissingItems.ps1` - Missing item diagnostics
8. `InvestigateDBOnlyItems.ps1` - Database-only item investigation
9. `OptimizeVanityDB.ps1` - Database optimization
10. `UpdateDatabaseFromAPI.ps1` - API update workflow

### API Processing:
11. `AnalyzeAPIDump.ps1` - API dump analysis
12. `ExtractGameIDs.ps1` - Game ID extraction
13. `ExtractGameIDs_V2.ps1` - Game ID extraction (v2)
14. `IdentifyVerificationNeeds.ps1` - Verification identification
15. `PrepareForFreshScan.ps1` - Fresh scan preparation
16. `ProcessAPIDump.ps1` - API dump processing

### Testing:
17. `TestVanityDB.ps1` - VanityDB validation
18. `ImportResults.ps1` - Result import utility

### Documentation:
19. `ConsolidateDocumentation.ps1` - Documentation consolidation
20. `README.md` - Utilities documentation

---

## Restoration Instructions

If you need to restore an archived script:

1. **Locate the script** in the appropriate archive subdirectory
2. **Copy (don't move)** to `utilities/` directory
3. **Review and update** for current codebase compatibility
4. **Test thoroughly** before using in production
5. **Document why** it was restored in commit message

---

## Consolidation Impact

**Before Archival:**
- **Total Scripts:** 63 files in `utilities/`
- **Workflow Complexity:** Multi-step manual processes
- **Maintenance Burden:** High (many similar scripts)

**After Archival:**
- **Active Scripts:** 20 core utilities
- **Archived Scripts:** 43 superseded/one-off tools
- **Workflow Complexity:** Streamlined automation
- **Maintenance Burden:** Low (consolidated workflows)

**Result:** 68% reduction in active scripts, dramatically simplified workflows

---

## Notes

- **Do not delete** archived scripts - they contain valuable historical context
- **Reference archived scripts** when troubleshooting similar issues
- **Learn from evolution** shown in archived script progression
- **Consider patterns** used in archived scripts for future development

---

**Archive Maintained By:** AscensionVanity Development Team  
**Last Updated:** October 29, 2025
