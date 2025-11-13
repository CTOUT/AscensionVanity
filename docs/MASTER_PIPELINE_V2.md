# Master Pipeline V2 - Quick Reference

**Version:** 2.0  
**Created:** November 7, 2025  
**Location:** `utilities/MasterPipeline_V2.ps1`

## ✨ What's New?

### Improvements Over V1
- ✅ **All-in-one execution** - One command runs everything
- ✅ **Better error handling** - Validates output files, not just exit codes
- ✅ **Automatic zone data copy** - Handles the critical "apply enriched data" step
- ✅ **Progress tracking** - Visual indicators (✓, →, ⚠, ✗)
- ✅ **Comprehensive logging** - All output saved to timestamped log file
- ✅ **Flexible execution** - Skip any step with switches
- ✅ **Dry-run mode** - Test without making changes
- ✅ **Prerequisite validation** - Checks all requirements before starting

---

## 🚀 Usage

### Full Pipeline (Most Common)
```powershell
# With auto-detect and deployment
.\utilities\MasterPipeline_V2.ps1 -WoWPath "D:\OneDrive\Warcraft"

# Auto-detect scan, no deployment
.\utilities\MasterPipeline_V2.ps1
```

### Quick Regeneration (After Manual Edits)
```powershell
# Skip import, regenerate from existing data
.\utilities\MasterPipeline_V2.ps1 -SkipImport -WoWPath "D:\OneDrive\Warcraft"
```

### Test Mode
```powershell
# See what would happen without making changes
.\utilities\MasterPipeline_V2.ps1 -DryRun
```

### Custom Scan Location
```powershell
# Use specific scan file
.\utilities\MasterPipeline_V2.ps1 -SavedVariablesPath "D:\path\to\AscensionVanity.lua" -WoWPath "D:\OneDrive\Warcraft"
```

---

## 📋 Pipeline Steps

| Step | Name | Script | Auto-Skip If... |
|------|------|--------|----------------|
| 0 | Prerequisites | Built-in | Never |
| 1 | Import Scan | `MasterAPIDumpImport.ps1` | `-SkipImport` |
| 2 | Normalize | `NormalizeDescriptions.ps1` | `-SkipNormalize` |
| 3 | Enrich Zones | `EnrichZoneData.ps1` | `-SkipEnrich` |
| 4 | Generate DB | `GenerateVanityDB_Master.ps1` | Never |
| 4.5 | **Validate** | Manual comparison | **CRITICAL** |
| 5 | Deploy | `DeployAddon.ps1` | `-SkipDeploy` or no `-WoWPath` |

---

## ⚙️ Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-SavedVariablesPath` | String | Path to scan file (auto-detects if omitted) |
| `-WoWPath` | String | WoW installation path for deployment |
| `-SkipImport` | Switch | Skip Step 1 (use existing data) |
| `-SkipNormalize` | Switch | Skip Step 2 (already normalized) |
| `-SkipEnrich` | Switch | Skip Step 3 (already enriched) |
| `-SkipDeploy` | Switch | Skip Step 5 (don't copy to WoW) |
| `-DryRun` | Switch | Test mode - no changes made |

---

## 🎯 Common Scenarios

### Scenario 1: Fresh Game Scan
```powershell
# Place AscensionVanity.lua in data folder, then:
.\utilities\MasterPipeline_V2.ps1 -WoWPath "D:\OneDrive\Warcraft"
```

### Scenario 2: Fixed Descriptions Manually
```powershell
# Skip import & normalize, regenerate zones
.\utilities\MasterPipeline_V2.ps1 -SkipImport -SkipNormalize -WoWPath "D:\OneDrive\Warcraft"
```

### Scenario 3: Testing Zone Parsing Logic
```powershell
# Dry run to see what would happen
.\utilities\MasterPipeline_V2.ps1 -SkipImport -DryRun
```

### Scenario 4: Quick Test Without Deployment
```powershell
# Generate database but don't deploy
.\utilities\MasterPipeline_V2.ps1 -SkipImport
```

---

## ⚠️ CRITICAL: Manual Validation Step (Step 4.5)

**ALWAYS validate before deploying!** After Step 4 (Generate DB), the new `VanityDB.lua` is created but **NOT YET committed**. You MUST:

### Validation Workflow

```powershell
# 1. Save new VanityDB as temporary file
Copy-Item "AscensionVanity\VanityDB.lua" "AscensionVanity\VanityDB_NEW.lua" -Force

# 2. Restore old VanityDB from git
git restore "AscensionVanity\VanityDB.lua"

# 3. Compare item counts
$old = (Get-Content "AscensionVanity\VanityDB.lua" -Raw | Select-String -Pattern '\[\d+\]\s*=\s*\{' -AllMatches).Matches.Count
$new = (Get-Content "AscensionVanity\VanityDB_NEW.lua" -Raw | Select-String -Pattern '\[\d+\]\s*=\s*\{' -AllMatches).Matches.Count
Write-Host "Old VanityDB: $old items"
Write-Host "New VanityDB: $new items"
Write-Host "Difference: $($new - $old) items"

# 4. Run validation script
.\utilities\ValidateCreatureIds.ps1 -All

# 5. Review anomaly report
# Check: data\CreatureId_Anomalies_Report.csv
# Look for unexpected increases in extreme/highRange counts

# 6. If happy, replace old with new
Copy-Item "AscensionVanity\VanityDB_NEW.lua" "AscensionVanity\VanityDB.lua" -Force
Remove-Item "AscensionVanity\VanityDB_NEW.lua"

# 7. Commit changes
git add -A
git commit -m "data: Update VanityDB with fresh scan (YYYY-MM-DD, X items, no drift)"
```

### What to Check

- **Item count drift**: Should be minimal (±10 items is normal)
- **Large drops**: If count drops >100, investigate missing items
- **Large increases**: If count increases >100, verify new items are legitimate
- **Anomaly trends**: Check if extreme/highRange counts increased significantly

### Red Flags 🚩

- ❌ Item count dropped by >100
- ❌ Extreme anomalies increased by >50
- ❌ Many items have `creatureId = 0` or null descriptions
- ❌ Quest-locked NPC count changed unexpectedly

---

## 📊 Output

### Console Output
- **✓** Green checkmark = Success
- **→** Gray arrow = Info
- **⚠** Yellow warning = Non-critical issue
- **✗** Red X = Error/Failure

### Log File
- **Location:** `logs/Pipeline_YYYY-MM-DD_HHMMSS.log`
- **Contents:** Complete timestamped record of execution
- **Useful for:** Debugging, auditing, troubleshooting

### Generated Files
1. `data/MasterFullValidated.json` - Normalized & enriched data
2. `data/MasterFullValidated_ZoneEnriched.json` - Zone-only enrichment
3. `AscensionVanity/VanityDB.lua` - Final database
4. `D:\OneDrive\Warcraft/AscensionVanity/VanityDB.lua` - Deployed copy

---

## 🔍 Troubleshooting

### Pipeline Fails at Step X
1. Check the log file: `logs/Pipeline_YYYY-MM-DD_HHMMSS.log`
2. Run that step manually: `.\utilities\[Script].ps1`
3. Review error message for specific issue

### "Prerequisites not met"
- Ensure `data/ZoneMappings.json` exists
- Ensure `data/QuestLockedNPCs.json` exists
- Ensure `data/API_to_GameID_Mapping.json` exists

### "No scan file found"
- Place `AscensionVanity.lua` in `data/` folder
- OR use `-SavedVariablesPath` parameter

### VanityDB.lua missing zone data
- Check Step 3 output - should show high enrichment %
- Verify `MasterFullValidated.json` has zone fields
- Re-run: `.\utilities\MasterPipeline_V2.ps1 -SkipImport`

---

## 🆚 V1 vs V2 Comparison

| Feature | V1 (MasterDatabasePipeline.ps1) | V2 (MasterPipeline_V2.ps1) |
|---------|----------------------------------|----------------------------|
| Steps | Manual copy enriched data | Automatic |
| Error Handling | Exit codes only | File validation + exit codes |
| Logging | Console only | Console + log file |
| Progress | Basic | Visual indicators |
| Validation | None | Prerequisite checks |
| Dry Run | No | Yes |
| Skip Options | Limited | Full control |

---

## 💡 Tips

1. **Use `-SkipImport`** frequently - importing takes time, use existing data when possible
2. **Check logs** if something fails - they have full details
3. **Use `-DryRun`** first when testing changes
4. **Deploy automatically** with `-WoWPath` to save steps
5. **Read the console output** - it tells you exactly what happened

---

## 📚 See Also

- `docs/DATABASE_PIPELINE_VALIDATION.md` - Detailed process documentation
- `docs/DATABASE_PIPELINE_ARCHITECTURE.md` - Design philosophy
- `utilities/MasterDatabasePipeline.ps1` - Original V1 script (deprecated)

---

**Quick Start:**
```powershell
.\utilities\MasterPipeline_V2.ps1 -WoWPath "D:\OneDrive\Warcraft"
```

That's it! One command, complete pipeline. ✨
