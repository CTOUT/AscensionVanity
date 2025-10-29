# Apply Final Empty Description Enrichments
# Applies the 10 automatically found zones to VanityDB.lua

$ErrorActionPreference = 'Stop'

Write-Host "`n=== APPLYING FINAL ENRICHMENTS ===" -ForegroundColor Cyan
Write-Host "Enriching 10 items with zones found via search`n" -ForegroundColor Gray

# Load enrichment data
$enrichments = Get-Content "data\FinalEmptyDescriptions_Enrichment.json" | ConvertFrom-Json

# Read VanityDB.lua
$vanityDbPath = "AscensionVanity\VanityDB.lua"
$content = Get-Content $vanityDbPath -Raw -Encoding UTF8

Write-Host "Processing $($enrichments.Count) enrichments...`n" -ForegroundColor Yellow

$updatedCount = 0
$notFoundCount = 0

foreach ($item in $enrichments) {
    Write-Host "Processing: $($item.DropsFrom)" -ForegroundColor White
    Write-Host "  Item ID: $($item.ItemId)" -ForegroundColor Gray
    Write-Host "  Zone: $($item.Region)" -ForegroundColor Gray
    
    $description = $item.GeneratedDescription
    
    # Pattern to find this item entry with empty description
    $pattern = "(\[$($item.ItemId)\]\s*=\s*\{[^\}]*\[`"description`"\]\s*=\s*)`"`""
    
    if ($content -match $pattern) {
        # Replace empty description with the new one
        $content = $content -replace $pattern, "`$1`"$description`""
        $updatedCount++
        Write-Host "  ✓ Updated" -ForegroundColor Green
    } else {
        $notFoundCount++
        Write-Host "  ✗ Item entry not found in VanityDB.lua" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Write updated content back to file
if ($updatedCount -gt 0) {
    Write-Host "Saving changes to VanityDB.lua..." -ForegroundColor Cyan
    $content | Set-Content $vanityDbPath -Encoding UTF8 -NoNewline
    Write-Host "✓ Changes saved successfully" -ForegroundColor Green
}

# Summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Items updated: $updatedCount" -ForegroundColor Green
if ($notFoundCount -gt 0) {
    Write-Host "Items not found: $notFoundCount" -ForegroundColor Yellow
}

# Check remaining empty descriptions
Write-Host "`nChecking remaining empty descriptions..." -ForegroundColor Cyan
$remainingEmpty = (Select-String -Path $vanityDbPath -Pattern '\["description"\]\s*=\s*""').Count
Write-Host "Remaining empty: $remainingEmpty" -ForegroundColor $(if ($remainingEmpty -eq 0) { "Green" } else { "Yellow" })

Write-Host "`n=== FINAL ENRICHMENT APPLIED ===" -ForegroundColor Green
