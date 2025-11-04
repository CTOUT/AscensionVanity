<#
.SYNOPSIS
    Master pipeline for full database update workflow

.DESCRIPTION
    Runs the complete workflow from API scan to final database generation.
    Steps:
    1. (Manual) Export fresh scan from game
    2. Normalize descriptions
    3. Enrich zone data from descriptions
    4. Generate final VanityDB.lua
    
    This is a CONVENIENCE script that chains existing tools.
    Each step can still be run independently for debugging/testing.

.PARAMETER SkipScan
    Skip the scan import step (use existing data)

.PARAMETER SkipNormalization
    Skip description normalization

.PARAMETER SkipZoneEnrichment
    Skip zone data extraction

.PARAMETER DryRun
    Test mode - show what would be done without making changes

.EXAMPLE
    .\MasterDatabasePipeline.ps1
    Full pipeline execution

.EXAMPLE
    .\MasterDatabasePipeline.ps1 -SkipScan
    Update existing data without importing new scan

.NOTES
    Author: CMTout
    Last Updated: 2025-11-04
    
    DESIGN PHILOSOPHY:
    - Each step is a separate script (modularity)
    - Pipeline is just a convenience wrapper
    - Individual steps can be run standalone
    - Failures in one step don't corrupt others
#>

[CmdletBinding()]
param(
    [switch]$SkipScan,
    [switch]$SkipNormalization,
    [switch]$SkipZoneEnrichment,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Master Database Pipeline" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN MODE] No changes will be saved" -ForegroundColor Yellow
    Write-Host ""
}

# Paths
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath

# Step 1: Import fresh scan (manual - user must export from game first)
if (-not $SkipScan) {
    Write-Host "[1/5] Import Fresh Scan" -ForegroundColor Green
    Write-Host "  This step is MANUAL:" -ForegroundColor Yellow
    Write-Host "  1. In-game: /avanity scanner" -ForegroundColor Gray
    Write-Host "  2. Click 'Start Full Scan'" -ForegroundColor Gray
    Write-Host "  3. Export results to data/ folder" -ForegroundColor Gray
    Write-Host "  4. Run: .\utilities\MasterAPIDumpImport.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Press Enter when scan is imported, or Ctrl+C to cancel..." -ForegroundColor Yellow
    Read-Host
} else {
    Write-Host "[1/5] Import Fresh Scan - SKIPPED" -ForegroundColor Gray
    Write-Host ""
}

# Step 2: Normalize descriptions
if (-not $SkipNormalization) {
    Write-Host "[2/5] Normalize Descriptions" -ForegroundColor Green
    if ($DryRun) {
        & "$scriptPath\NormalizeDescriptions.ps1" -DryRun
    } else {
        & "$scriptPath\NormalizeDescriptions.ps1"
    }
    Write-Host ""
} else {
    Write-Host "[2/5] Normalize Descriptions - SKIPPED" -ForegroundColor Gray
    Write-Host ""
}

# Step 3: Enrich zone data
if (-not $SkipZoneEnrichment) {
    Write-Host "[3/5] Enrich Zone Data" -ForegroundColor Green
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would run: .\utilities\EnrichZoneData.ps1" -ForegroundColor Yellow
    } else {
        & "$scriptPath\EnrichZoneData.ps1"
        
        # Apply enriched data
        Write-Host ""
        Write-Host "  Applying enriched zone data..." -ForegroundColor Gray
        Copy-Item "$rootPath\data\MasterFullValidated_ZoneEnriched.json" "$rootPath\data\MasterFullValidated.json" -Force
        Write-Host "  Zone data applied!" -ForegroundColor Green
    }
    Write-Host ""
} else {
    Write-Host "[3/5] Enrich Zone Data - SKIPPED" -ForegroundColor Gray
    Write-Host ""
}

# Step 4: Generate final database
Write-Host "[4/5] Generate VanityDB" -ForegroundColor Green
if ($DryRun) {
    Write-Host "  [DRY RUN] Would run: .\utilities\GenerateVanityDB_Master.ps1" -ForegroundColor Yellow
} else {
    & "$scriptPath\GenerateVanityDB_Master.ps1"
}
Write-Host ""

# Step 5: Summary
Write-Host "[5/5] Summary" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Pipeline Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not $DryRun) {
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Deploy addon: .\DeployAddon.ps1" -ForegroundColor Gray
    Write-Host "  2. Test in-game: /reload" -ForegroundColor Gray
    Write-Host "  3. Verify tooltips and progress frame" -ForegroundColor Gray
    Write-Host ""
}
