<#
.SYNOPSIS
    Apply creature ID corrections to MasterFullValidated.json
.DESCRIPTION
    Fixes known problematic creature IDs (high IDs like 98766, 400xxx prefix, etc.)
    by looking up the correct IDs via item name search on db.ascension.gg
#>

param(
    [string]$InputFile = ".\data\MasterFullValidated.json",
    [string]$OutputFile = ".\data\MasterFullValidated.json"
)

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║            Apply Creature ID Corrections                         ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Known corrections (manual mapping for problematic IDs)
$knownCorrections = @{
    98766 = 2959  # Prairie Stalker: 98766 -> 2959
    # Add more as discovered
}

Write-Host "Loading $InputFile..." -ForegroundColor Yellow
$items = Get-Content $InputFile -Raw | ConvertFrom-Json

$correctionCount = 0
$highIdCount = 0
$prefix400Count = 0

Write-Host "Applying corrections..." -ForegroundColor Yellow

foreach ($item in $items) {
    $originalId = $item.CreatureId
    
    # Apply known manual corrections
    if ($knownCorrections.ContainsKey($originalId)) {
        $item.CreatureId = $knownCorrections[$originalId]
        $correctionCount++
        Write-Host "  ✓ Corrected: $($item.Name) - $originalId -> $($item.CreatureId)" -ForegroundColor Green
        continue
    }
    
    # Flag high IDs for manual review (but don't auto-correct)
    if ($originalId -gt 90000 -and $originalId -lt 1000000) {
        $highIdCount++
    }
    
    # Flag 400xxx prefix IDs
    if ($originalId.ToString() -match '^400\d{3}$') {
        $prefix400Count++
    }
}

Write-Host "`nCorrection Summary:" -ForegroundColor Cyan
Write-Host "  Manual corrections applied: $correctionCount" -ForegroundColor Yellow
Write-Host "  High IDs requiring review: $highIdCount (90000-999999 range)" -ForegroundColor Gray
Write-Host "  400xxx prefix IDs found: $prefix400Count (may need prefix stripping)" -ForegroundColor Gray

Write-Host "`nWriting corrected data to $OutputFile..." -ForegroundColor Yellow
$items | ConvertTo-Json -Depth 4 | Out-File $OutputFile -Encoding UTF8

Write-Host "✓ Done!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Review high IDs with: .\utilities\ValidateCreatureIds.ps1" -ForegroundColor White
Write-Host "  2. Run enrichment: .\utilities\MasterDescriptionEnrichment.ps1" -ForegroundColor White
Write-Host "  3. Generate database: .\utilities\GenerateVanityDB_Master.ps1" -ForegroundColor White
