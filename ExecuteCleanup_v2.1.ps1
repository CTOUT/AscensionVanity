# AscensionVanity v2.1 Cleanup Script
# Consolidates and archives files before beta release

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "AscensionVanity v2.1 Cleanup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Create archive directories
Write-Host "`n[1/4] Creating archive folders..." -ForegroundColor Yellow
New-Item -Path "docs\archive\v2.1" -ItemType Directory -Force | Out-Null
New-Item -Path "utilities\archive\v2.1" -ItemType Directory -Force | Out-Null
New-Item -Path "data\archive\v2.1" -ItemType Directory -Force | Out-Null
Write-Host "  ✓ Archive folders created" -ForegroundColor Green

# Archive obsolete documentation
Write-Host "`n[2/4] Archiving completed documentation..." -ForegroundColor Yellow
$obsoleteDocs = @(
    "ARCHITECTURE_REFACTORING_PLAN.md",
    "BRANCH_CONSOLIDATION_SUMMARY.md",
    "CONSOLIDATION_SUMMARY.md",
    "DATABASE_OPTIMIZATION_FINAL.md",
    "DESCRIPTION_ENRICHMENT_WORKFLOW.md",
    "DOCUMENTATION_CONSOLIDATION_PLAN.md",
    "ENHANCED_DATA_MODEL.md",
    "ENRICHMENT_QUICK_START.md",
    "HYBRID_FILTERING_SUMMARY.md",
    "IMPLEMENTATION_ROADMAP.md",
    "REGIONAL_GUIDE_PHASE2_TODO.md",
    "SESSION_2025-11-01_CREATURE_ID_INVESTIGATION.md",
    "SESSION_2025-11-01_GROUP_ID_DISCOVERY.md",
    "SESSION_2025-11-02_REGIONAL_GUIDE.md",
    "V2_CONSOLIDATION_COMPLETE.md",
    "V2_IMPLEMENTATION_CHECKLIST.md"
)

$docsMoved = 0
foreach ($doc in $obsoleteDocs) {
    if (Test-Path "docs\$doc") {
        Move-Item "docs\$doc" "docs\archive\v2.1\" -Force
        $docsMoved++
    }
}
Write-Host "  ✓ Archived $docsMoved documentation files" -ForegroundColor Green

# Archive obsolete scripts
Write-Host "`n[3/4] Archiving one-time scripts..." -ForegroundColor Yellow
$obsoleteScripts = @(
    "AnalyzeFreshScan.ps1",
    "AnalyzeGroupIDs.ps1",
    "CompareAPIExport.ps1",
    "CompareDatabase.ps1",
    "ConvertScanToMasterJson.ps1",
    "DiagnoseMissingItems.ps1",
    "DiscoverVanityIDMapping.lua",
    "GenerateAnomalyTriage.ps1",
    "IdentifyVerificationNeeds.ps1",
    "InvestigateDBOnlyItems.ps1",
    "VerifyNPCNameMatches.ps1",
    "ConsolidateDocumentation.ps1"
)

$scriptsMoved = 0
foreach ($script in $obsoleteScripts) {
    if (Test-Path "utilities\$script") {
        Move-Item "utilities\$script" "utilities\archive\v2.1\" -Force
        $scriptsMoved++
    }
}
Write-Host "  ✓ Archived $scriptsMoved utility scripts" -ForegroundColor Green

# Archive analysis data files
Write-Host "`n[4/4] Archiving analysis data files..." -ForegroundColor Yellow
$analysisFiles = @(
    "BlankDescriptions_Analysis.json",
    "BlankDescriptions_ToSearch.csv",
    "BlankDescriptions_Validated.json",
    "DropsOnly_Analysis.json",
    "EmptyDescriptions_CreatureIds.csv",
    "EmptyDescriptions_Validated.json",
    "Enrichment_Results_2025-10-29_120332.csv",
    "FinalEmptyDescriptions_Enrichment.json",
    "FinalEmptyDescriptions_Results.csv",
    "Items_Needing_Wowhead.csv",
    "IconUsage_Analysis.json",
    "CreatureId_Anomalies_Report.csv",
    "CreatureId_Anomalies_Report.json",
    "CreatureId_Region_Triage.csv",
    "VanityDB_Discrepancies_20251102_123820.csv",
    "VanityDB_Regions.lua"
)

$dataFilesMoved = 0
foreach ($file in $analysisFiles) {
    if (Test-Path "data\$file") {
        Move-Item "data\$file" "data\archive\v2.1\" -Force
        $dataFilesMoved++
    }
}

# Delete temporary files
$tempFiles = @(
    "data\API_to_GameID_Mapping_2025-11-02_083242.json",
    "data\API_to_GameID_Mapping_2025-11-02_083329.json",
    "data\API_to_GameID_Mapping_2025-11-02_083418.json",
    "data\AscensionVanity OLD.lua",
    "data\AscensionVanity01112025.lua",
    "data\AscensionVanity_Fresh_Scan_2025-11-02_091121.lua",
    "data\AscensionVanity_Transformed.lua",
    "data\AscensionVanity.lua.bak"
)

$tempDeleted = 0
foreach ($file in $tempFiles) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        $tempDeleted++
    }
}

Write-Host "  ✓ Archived $dataFilesMoved analysis files" -ForegroundColor Green
Write-Host "  ✓ Deleted $tempDeleted temporary files" -ForegroundColor Green

# Summary
Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "Cleanup Complete!" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  Documentation: $docsMoved files archived" -ForegroundColor White
Write-Host "  Scripts:       $scriptsMoved files archived" -ForegroundColor White
Write-Host "  Data:          $dataFilesMoved files archived, $tempDeleted deleted" -ForegroundColor White
Write-Host "`n✓ Repository cleaned and ready for v2.1-beta!" -ForegroundColor Green
Write-Host ""
