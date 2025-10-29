# Find items needing Wowhead enrichment
# Lists items that either failed validation OR have no region

param(
    [Parameter(Mandatory=$false)]
    [string]$InputFile = "data\BlankDescriptions_Validated.json"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Items Needing Wowhead Enrichment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$items = Get-Content $InputFile -Raw | ConvertFrom-Json

# Find items needing enrichment
$needsEnrichment = $items | Where-Object { 
    ($_.Validated -eq $false) -or 
    ($_.Validated -eq $true -and $_.Region -eq $null)
}

Write-Host "Total items: $($items.Count)" -ForegroundColor White
Write-Host "Items needing Wowhead enrichment: $($needsEnrichment.Count)" -ForegroundColor Yellow
Write-Host ""

Write-Host "📝 Items to lookup on Wowhead WOTLK:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

foreach ($item in $needsEnrichment) {
    $status = if ($_.Validated -eq $false) { "NOT VALIDATED" } else { "MISSING REGION" }
    Write-Host "`n[$($item.CreatureId)] $($item.Name)" -ForegroundColor Yellow
    Write-Host "  Status: $status" -ForegroundColor $(if ($_.Validated -eq $false) { "Red" } else { "Yellow" })
    Write-Host "  WOTLK URL: https://www.wowhead.com/wotlk/npc=$($item.CreatureId)" -ForegroundColor Cyan
    if ($item.DropsFrom) {
        Write-Host "  DropsFrom: $($item.DropsFrom)" -ForegroundColor Gray
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Total URLs to check: $($needsEnrichment.Count)" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Export list for batch processing
$needsEnrichment | Select-Object ItemId, CreatureId, Name, Validated, DropsFrom, Region | 
    Export-Csv "data\Items_Needing_Wowhead.csv" -NoTypeInformation

Write-Host "✓ Exported to: data\Items_Needing_Wowhead.csv" -ForegroundColor Green
Write-Host ""

return $needsEnrichment
