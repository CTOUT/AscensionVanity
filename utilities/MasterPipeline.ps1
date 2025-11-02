<#
.SYNOPSIS
    Master workflow for processing fresh scan to final VanityDB
.DESCRIPTION
    Orchestrates the complete data pipeline:
    1. Extract immutable source mapping from fresh scan
    2. Apply documented corrections
    3. Build validated dataset
    4. Enrich descriptions
    5. Generate final VanityDB.lua
    
    This ensures data integrity through layered, non-destructive processing.
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$FreshScanFile = ".\data\AscensionVanity.lua.bak",
    
    [switch]$SkipExtract,
    [switch]$SkipCorrections,
    [switch]$SkipEnrichment,
    [switch]$SkipGeneration
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          Master VanityDB Processing Pipeline                    ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$steps = @()
$stepNumber = 1

# Step 1: Extract mapping from fresh scan
if (-not $SkipExtract) {
    Write-Host "[$stepNumber] Extracting mapping from fresh scan..." -ForegroundColor Cyan
    Write-Host "    Source: $FreshScanFile" -ForegroundColor Gray
    Write-Host "    Output: data\sources\API_to_GameID_Mapping.json" -ForegroundColor Gray
    Write-Host ""
    
    & ".\utilities\ExtractMappingFast.ps1" -ScanFile $FreshScanFile
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Extraction failed"
    }
    $steps += "✓ Step $stepNumber`: Extracted mapping from fresh scan"
    $stepNumber++
}

# Step 2: Apply corrections
if (-not $SkipCorrections) {
    Write-Host "`n[$stepNumber] Applying documented corrections..." -ForegroundColor Cyan
    Write-Host "    Corrections: data\corrections\CreatureIdCorrections.json" -ForegroundColor Gray
    Write-Host "    Output: data\processed\Corrected_Mapping.json" -ForegroundColor Gray
    Write-Host ""
    
    & ".\utilities\ApplyCorrectionsToMapping.ps1"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Corrections failed"
    }
    $steps += "✓ Step $stepNumber`: Applied corrections"
    $stepNumber++
}

# Step 3: Build validated dataset
Write-Host "`n[$stepNumber] Building validated dataset..." -ForegroundColor Cyan
Write-Host "    Input: data\processed\Corrected_Mapping.json" -ForegroundColor Gray
Write-Host "    Output: data\MasterFullValidated.json" -ForegroundColor Gray
Write-Host ""

& ".\utilities\BuildMasterFullValidated.ps1" `
    -ScanFile $FreshScanFile `
    -MappingFile ".\data\processed\Corrected_Mapping.json"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
}
$steps += "✓ Step $stepNumber`: Built validated dataset"
$stepNumber++

# Step 4: Enrich descriptions
if (-not $SkipEnrichment) {
    Write-Host "`n[$stepNumber] Enriching descriptions..." -ForegroundColor Cyan
    Write-Host "    (This may take several minutes)" -ForegroundColor Gray
    Write-Host ""
    
    & ".\utilities\MasterDescriptionEnrichment.ps1"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Enrichment had issues - continuing anyway" -ForegroundColor Yellow
    }
    $steps += "✓ Step $stepNumber`: Enriched descriptions"
    $stepNumber++
}

# Step 5: Generate final VanityDB.lua
if (-not $SkipGeneration) {
    Write-Host "`n[$stepNumber] Generating final VanityDB.lua..." -ForegroundColor Cyan
    Write-Host "    Output: AscensionVanity\VanityDB.lua" -ForegroundColor Gray
    Write-Host ""
    
    & ".\utilities\GenerateVanityDB_Master.ps1"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Generation failed"
    }
    $steps += "✓ Step $stepNumber`: Generated VanityDB.lua"
    $stepNumber++
}

# Summary
Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                     Pipeline Complete!                           ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

foreach ($step in $steps) {
    Write-Host "  $step" -ForegroundColor Green
}

Write-Host "`nFinal output: AscensionVanity\VanityDB.lua" -ForegroundColor Cyan
Write-Host "`nNext: Test in-game with /reload" -ForegroundColor Yellow
