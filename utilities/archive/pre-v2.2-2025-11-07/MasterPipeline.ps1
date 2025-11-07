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

# === VALIDATION PHASE ===
Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    Validating Pipeline Output                    ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$validationErrors = @()
$validationWarnings = @()

# Validate Step 1: Source mapping exists and has data
if (Test-Path ".\data\sources\API_to_GameID_Mapping.json") {
    $sourceMapping = Get-Content ".\data\sources\API_to_GameID_Mapping.json" -Raw | ConvertFrom-Json
    if ($sourceMapping.Count -gt 0) {
        Write-Host "  ✓ Source mapping exists with $($sourceMapping.Count) items" -ForegroundColor Green
    } else {
        $validationErrors += "Source mapping is empty!"
    }
} else {
    $validationErrors += "Source mapping file not found!"
}

# Validate Step 2: Corrected mapping exists
if (Test-Path ".\data\processed\Corrected_Mapping.json") {
    $corrected = Get-Content ".\data\processed\Corrected_Mapping.json" -Raw | ConvertFrom-Json
    Write-Host "  ✓ Corrected mapping exists with $($corrected.Count) items" -ForegroundColor Green
    
    # Check correction log
    if (Test-Path ".\data\processed\Corrected_Mapping_AppliedCorrections.json") {
        $corrections = Get-Content ".\data\processed\Corrected_Mapping_AppliedCorrections.json" -Raw | ConvertFrom-Json
        Write-Host "    → $($corrections.Count) correction(s) applied" -ForegroundColor Gray
    }
} else {
    $validationErrors += "Corrected mapping not found!"
}

# Validate Step 3: Master validated dataset exists
if (Test-Path ".\data\MasterFullValidated.json") {
    $master = Get-Content ".\data\MasterFullValidated.json" -Raw | ConvertFrom-Json
    Write-Host "  ✓ Master validated dataset exists with $($master.Count) items" -ForegroundColor Green
} else {
    $validationErrors += "Master validated dataset not found!"
}

# Validate Step 4: Check for empty descriptions
if (Test-Path ".\data\MasterFullValidated.json") {
    $master = Get-Content ".\data\MasterFullValidated.json" -Raw | ConvertFrom-Json
    $emptyDescriptions = ($master | Where-Object { -not $_.Description -or $_.Description -eq "" }).Count
    if ($emptyDescriptions -eq 0) {
        Write-Host "  ✓ All items have descriptions" -ForegroundColor Green
    } else {
        $validationWarnings += "$emptyDescriptions items still have empty descriptions"
        Write-Host "  ⚠️  $emptyDescriptions items have empty descriptions" -ForegroundColor Yellow
    }
}

# Validate Step 5: Final VanityDB.lua exists and has data
if (Test-Path ".\AscensionVanity\VanityDB.lua") {
    $dbFile = Get-Item ".\AscensionVanity\VanityDB.lua"
    $dbContent = Get-Content ".\AscensionVanity\VanityDB.lua" -Raw
    
    # Check for metadata
    if ($dbContent -match '-- Generated: (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})') {
        $genDate = $matches[1]
        Write-Host "  ✓ VanityDB.lua generated at $genDate" -ForegroundColor Green
    } else {
        $validationWarnings += "VanityDB.lua missing generation timestamp"
    }
    
    # Check for data
    if ($dbContent -match 'AV_VanityItems = \{') {
        Write-Host "  ✓ VanityDB.lua contains data ($([math]::Round($dbFile.Length / 1KB, 2)) KB)" -ForegroundColor Green
    } else {
        $validationErrors += "VanityDB.lua missing AV_VanityItems table!"
    }
    
    # Check for icon list
    if ($dbContent -match 'AV_IconList = \{') {
        Write-Host "  ✓ VanityDB.lua contains icon list" -ForegroundColor Green
    } else {
        $validationErrors += "VanityDB.lua missing AV_IconList!"
    }
} else {
    $validationErrors += "VanityDB.lua not found!"
}

# Summary
Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                     Pipeline Complete!                           ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

foreach ($step in $steps) {
    Write-Host "  $step" -ForegroundColor Green
}

# Validation Summary
if ($validationErrors.Count -gt 0) {
    Write-Host "`n❌ VALIDATION ERRORS:" -ForegroundColor Red
    foreach ($err in $validationErrors) {
        Write-Host "  • $err" -ForegroundColor Red
    }
    Write-Error "Pipeline validation failed!"
}

if ($validationWarnings.Count -gt 0) {
    Write-Host "`n⚠️  VALIDATION WARNINGS:" -ForegroundColor Yellow
    foreach ($warn in $validationWarnings) {
        Write-Host "  • $warn" -ForegroundColor Yellow
    }
}

if ($validationErrors.Count -eq 0) {
    Write-Host "`n✓ All validation checks passed!" -ForegroundColor Green
}

Write-Host "`nFinal output: AscensionVanity\VanityDB.lua" -ForegroundColor Cyan
Write-Host "`nNext: Test in-game with /reload" -ForegroundColor Yellow
