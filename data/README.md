# Data Folder Structure

This folder follows an **immutable source + layered corrections** pattern to maintain data integrity and prevent corruption.

## Directory Structure

```
data/
├── sources/              # IMMUTABLE: Never edit directly
│   ├── API_to_GameID_Mapping.json
│   └── *.validation.json (checksums)
│
├── corrections/          # VERSION CONTROLLED: Manual fixes
│   └── CreatureIdCorrections.json
│
├── processed/            # GENERATED: Intermediate files
│   ├── Corrected_Mapping.json
│   └── *_AppliedCorrections.json (logs)
│
├── backups/              # Historical snapshots
└── triage/               # Analysis and validation reports
```

## Principles

### 1. **Immutable Sources**
- Files in `sources/` are generated directly from the game
- **NEVER edit these files manually**
- Regenerate anytime without losing corrections
- Checksums verify integrity

### 2. **Documented Corrections**
- All manual fixes go in `corrections/` JSON files
- Each correction is documented with reason and verification
- Version controlled in git
- Auditable history of all changes

### 3. **Layered Processing**
- Source data → Apply corrections → Process → Enrich → Generate
- Non-destructive at each step
- Can regenerate any layer without losing work

## Workflow

### Initial Setup (One Time)
```powershell
# Extract mapping from fresh scan
.\utilities\ExtractMappingFast.ps1 -ScanFile ".\data\AscensionVanity.lua.bak"
```

### Full Pipeline (After Fresh Scan)
```powershell
# Run the master pipeline (includes validation)
.\utilities\MasterPipeline_V2.ps1
```

**Pipeline Steps:**
1. Import fresh scan from SavedVariables
2. Normalize descriptions (fix formatting)
3. Enrich zone data (extract from descriptions)
4. **Generate VanityDB.lua to temp location** (`data/VanityDB_NEW.lua`)
5. **Validate against deployed version** (comparison report)
6. **Deploy only if validation passes** (automatic copy to addon folder)

**Validation Safety:**
- ✅ Blocks deployment if critical issues detected (>10% item loss, missing fields)
- ⚠️ Prompts user for warnings (5-10% loss, minor issues)
- 📊 Detailed report showing changes (items added/removed, enrichment coverage)
- 💾 Preserves temp file on failure for manual review

### Adding a Correction
1. **Never edit** `sources/API_to_GameID_Mapping.json`
2. **Instead**, add to `corrections/CreatureIdCorrections.json`:
   ```json
   {
     "itemId": 79582,
     "itemName": "Beastmaster's Whistle: Prairie Stalker",
     "wrongCreatureId": 98766,
     "correctCreatureId": 2959,
     "reason": "High ID doesn't exist, verified via db.ascension.gg",
     "verifiedBy": "https://db.ascension.gg/?item=79582",
     "dateAdded": "2025-11-02"
   }
   ```
3. **Re-run** the pipeline: `.\utilities\MasterPipeline.ps1`

## Files Not in Git

The following are **ignored by git** (too large or generated):
- `sources/*.lua` - Fresh scan exports from game
- `sources/*.json` - Extracted mappings  
- `processed/*` - All intermediate files
- `backups/*` - Historical snapshots
- `triage/*` - Analysis reports

## Files IN Git

The following **are version controlled**:
- `corrections/*.json` - All manual corrections
- This README
- `.gitignore` configuration

## Integrity Checks

### Verify Source File Hasn't Been Tampered With
```powershell
$validation = Get-Content ".\data\sources\API_to_GameID_Mapping.json.validation.json" | ConvertFrom-Json
$currentHash = (Get-FileHash ".\data\sources\API_to_GameID_Mapping.json").Hash

if ($currentHash -eq $validation.ChecksumSHA256) {
    Write-Host "✓ Source file is pristine" -ForegroundColor Green
} else {
    Write-Host "⚠️  Source file has been modified!" -ForegroundColor Red
}
```

### View Applied Corrections
```powershell
Get-Content ".\data\processed\Corrected_Mapping_AppliedCorrections.json" | ConvertFrom-Json | Format-Table
```

## Benefits of This Approach

✅ **No Data Corruption**: Source files stay pristine  
✅ **Auditable**: All corrections are documented  
✅ **Reproducible**: Can regenerate from source anytime  
✅ **Version Controlled**: Corrections are in git  
✅ **Integrity Checks**: Checksums detect tampering  
✅ **Clear Separation**: Sources vs corrections vs processed  

## Troubleshooting

### "Source file has been modified"
- **Don't edit** `sources/` files directly
- Regenerate: `.\utilities\ExtractMappingFast.ps1`

### "Correction not applied"
- Check item ID matches exactly
- Verify corrections JSON is valid
- Re-run: `.\utilities\ApplyCorrectionsToMapping.ps1`

### "Lost my corrections"
- Corrections are in git! Check: `git status data/corrections/`
- If uncommitted: commit them to save

## Migration from Old Structure

Old files like `API_to_GameID_Mapping.json` in the root `data/` folder should be:
1. Moved to `backups/` for reference
2. Fresh mapping extracted to `sources/`
3. Any corrections documented in `corrections/`

---

**Key Takeaway**: Sources are read-only. Corrections are documented and versioned. Processing is layered and reproducible.
