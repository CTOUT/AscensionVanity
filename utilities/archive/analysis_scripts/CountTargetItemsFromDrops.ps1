# CountTargetItemsFromDrops.ps1
# Counts how many of our target items (Beastmaster's Whistle, Blood Soaked Vellum, 
# Summoner's Stones, Draconic Warhorns, Elemental Lodestones) are from Drops

param(
    [string]$DataFile = "d:\Repos\AscensionVanity\data\AscensionVanity.lua"
)

Write-Host "`n=== Target Items from Drops Analysis ===" -ForegroundColor Cyan

# Target item names we're looking for
$targetPatterns = @(
    "Beastmaster's Whistle",
    "Blood Soaked Vellum", 
    "Summoner's Stone",
    "Draconic Warhorn",
    "Elemental Lodestone"
)

# Read the data file
$content = Get-Content $DataFile -Raw

# Extract all items from the array format
$items = [regex]::Matches($content, '\{\s*\["name"\]\s*=\s*"([^"]+)",\s*\["creatureID"\]\s*=\s*(\d+),\s*\["itemID"\]\s*=\s*(\d+),\s*\["source"\]\s*=\s*"([^"]+)"')

Write-Host "`nTotal items in database: $($items.Count)" -ForegroundColor Yellow

# Filter to target items
$targetItems = @()
foreach ($match in $items) {
    $name = $match.Groups[1].Value
    
    # Check if this name matches any of our target patterns
    $isTarget = $false
    foreach ($pattern in $targetPatterns) {
        if ($name -like "*$pattern*") {
            $isTarget = $true
            break
        }
    }
    
    if ($isTarget) {
        $targetItems += [PSCustomObject]@{
            Name = $name
            CreatureID = $match.Groups[2].Value
            ItemID = $match.Groups[3].Value
            Source = $match.Groups[4].Value
        }
    }
}

Write-Host "`nTarget items found (all sources): $($targetItems.Count)" -ForegroundColor Yellow

# Filter to only Drops source
$dropsItems = $targetItems | Where-Object { $_.Source -eq "Drops" }

Write-Host "Target items from Drops: $($dropsItems.Count)" -ForegroundColor Green

# Group by item type and show breakdown
Write-Host "`n=== Breakdown by Item Type ===" -ForegroundColor Cyan
foreach ($pattern in $targetPatterns) {
    $count = ($dropsItems | Where-Object { $_.Name -like "*$pattern*" }).Count
    Write-Host "  $pattern : $count" -ForegroundColor $(if ($count -gt 0) { "Green" } else { "Gray" })
}

# Show sample items
if ($dropsItems.Count -gt 0) {
    Write-Host "`n=== Sample Items (first 10) ===" -ForegroundColor Cyan
    $dropsItems | Select-Object -First 10 | Format-Table Name, ItemID, CreatureID -AutoSize
}

# Show all sources for target items
Write-Host "`n=== All Sources for Target Items ===" -ForegroundColor Cyan
$sourceCounts = $targetItems | Group-Object Source | Sort-Object Count -Descending
$sourceCounts | Format-Table Name, Count -AutoSize

Write-Host ""
