<#
.SYNOPSIS
    Apply corrections from corrections file to create corrected mapping
.DESCRIPTION
    Reads immutable source mapping and applies documented corrections
    from the corrections file, outputting a corrected mapping file.
    This keeps source data pristine while allowing manual fixes.
#>

param(
    [string]$SourceFile = ".\data\sources\API_to_GameID_Mapping.json",
    [string]$CorrectionsFile = ".\data\corrections\CreatureIdCorrections.json",
    [string]$OutputFile = ".\data\processed\Corrected_Mapping.json"
)

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Apply Corrections to Mapping (Non-Destructive)          ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Validate source file integrity
if (Test-Path "$SourceFile.validation.json") {
    $validation = Get-Content "$SourceFile.validation.json" -Raw | ConvertFrom-Json
    $currentHash = (Get-FileHash $SourceFile -Algorithm SHA256).Hash
    
    if ($currentHash -ne $validation.ChecksumSHA256) {
        Write-Host "⚠️  WARNING: Source file has been modified since generation!" -ForegroundColor Red
        Write-Host "   Expected: $($validation.ChecksumSHA256)" -ForegroundColor Gray
        Write-Host "   Current:  $currentHash" -ForegroundColor Gray
        Write-Host "`n   The source file should be IMMUTABLE. Please regenerate it." -ForegroundColor Yellow
        $response = Read-Host "Continue anyway? (y/N)"
        if ($response -ne 'y') { exit 1 }
    } else {
        Write-Host "✓ Source file integrity verified" -ForegroundColor Green
    }
}

Write-Host "Loading source mapping..." -ForegroundColor Yellow
$mapping = Get-Content $SourceFile -Raw | ConvertFrom-Json

Write-Host "Loading corrections..." -ForegroundColor Yellow
if (-not (Test-Path $CorrectionsFile)) {
    Write-Host "  No corrections file found - using source data as-is" -ForegroundColor Gray
    $corrections = @{ corrections = @() }
} else {
    $corrections = Get-Content $CorrectionsFile -Raw | ConvertFrom-Json
    Write-Host "  Found $($corrections.corrections.Count) correction(s)" -ForegroundColor Cyan
}

# Apply corrections
$correctionCount = 0
$correctionLog = @()

foreach ($correction in $corrections.corrections) {
    $item = $mapping | Where-Object { $_.GameItemId -eq $correction.itemId }
    
    if ($item) {
        $originalId = $item.CreatureId
        $item.CreatureId = $correction.correctCreatureId
        $correctionCount++
        
        $logEntry = @{
            ItemId = $correction.itemId
            ItemName = $item.Name
            OriginalCreatureId = $originalId
            CorrectedCreatureId = $correction.correctCreatureId
            Reason = $correction.reason
        }
        $correctionLog += $logEntry
        
        Write-Host "  ✓ Applied: $($item.Name)" -ForegroundColor Green
        Write-Host "    Creature ID: $originalId → $($correction.correctCreatureId)" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠️  Item $($correction.itemId) not found in mapping" -ForegroundColor Yellow
    }
}

Write-Host "`nWriting corrected mapping to $OutputFile..." -ForegroundColor Yellow
$mapping | ConvertTo-Json -Depth 4 | Out-File $OutputFile -Encoding UTF8

# Save correction log
$logFile = $OutputFile -replace '\.json$', '_AppliedCorrections.json'
$correctionLog | ConvertTo-Json -Depth 4 | Out-File $logFile -Encoding UTF8

Write-Host "`n✓ Corrections applied successfully!" -ForegroundColor Green
Write-Host "  Source items: $($mapping.Count)" -ForegroundColor Cyan
Write-Host "  Corrections applied: $correctionCount" -ForegroundColor Cyan
Write-Host "  Output file: $OutputFile" -ForegroundColor Cyan
Write-Host "  Correction log: $logFile" -ForegroundColor Gray

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Build validated dataset: .\utilities\BuildMasterFullValidated.ps1 -MappingFile '$OutputFile'" -ForegroundColor White
Write-Host "  2. Enrich descriptions: .\utilities\MasterDescriptionEnrichment.ps1" -ForegroundColor White
Write-Host "  3. Generate database: .\utilities\GenerateVanityDB_Master.ps1" -ForegroundColor White
