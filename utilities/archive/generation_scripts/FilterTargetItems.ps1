# FilterTargetItems.ps1
# Filters API data to show only target item types from Drops

$apiFile = "data\AscensionVanity.lua"

if (-not (Test-Path $apiFile)) {
    Write-Host "Error: $apiFile not found!" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Filtering Target Items from Drops ===" -ForegroundColor Cyan

# Target item name patterns
$targetPatterns = @(
    "Beastmaster's Whistle",
    "Blood Soaked Vellum", 
    "Summoner's Stone",
    "Draconic Warhornlet",
    "Elemental Lodestone"
)

# Read the file
$content = Get-Content $apiFile -Raw

# Extract the data array
if ($content -match 'AscensionVanityDB\s*=\s*\{(.*?)\}') {
    $dataBlock = $matches[1]
    
    # Parse each item entry
    $pattern = '\{\s*name\s*=\s*"([^"]+)",\s*creatureID\s*=\s*(\d+),\s*itemID\s*=\s*(\d+)(?:,\s*source\s*=\s*"([^"]*)")?\s*\}'
    $matches = [regex]::Matches($dataBlock, $pattern)
    
    Write-Host "`nTotal items in API data: $($matches.Count)" -ForegroundColor Yellow
    
    # Filter for target items
    $targetItems = @()
    
    foreach ($match in $matches) {
        $itemName = $match.Groups[1].Value
        $creatureID = $match.Groups[2].Value
        $itemID = $match.Groups[3].Value
        $source = if ($match.Groups[4].Success) { $match.Groups[4].Value } else { "" }
        
        # Check if this is a target item
        $isTarget = $false
        foreach ($pattern in $targetPatterns) {
            if ($itemName -like "*$pattern*") {
                $isTarget = $true
                break
            }
        }
        
        if ($isTarget) {
            $targetItems += [PSCustomObject]@{
                Name = $itemName
                ItemID = $itemID
                CreatureID = $creatureID
                Source = $source
            }
        }
    }
    
    Write-Host "`nTarget Items Found: $($targetItems.Count)" -ForegroundColor Green
    
    # Filter for Drops only
    $dropItems = $targetItems | Where-Object { $_.Source -eq "Drop" }
    
    Write-Host "Target Items from Drops: $($dropItems.Count)" -ForegroundColor Cyan
    
    # Group by item type
    Write-Host "`n=== Breakdown by Item Type (Drops only) ===" -ForegroundColor Magenta
    
    foreach ($pattern in $targetPatterns) {
        $count = ($dropItems | Where-Object { $_.Name -like "*$pattern*" }).Count
        Write-Host "  $pattern : $count" -ForegroundColor White
    }
    
    # Show all sources for target items
    Write-Host "`n=== All Sources for Target Items ===" -ForegroundColor Yellow
    $sourceGroups = $targetItems | Group-Object Source | Sort-Object Count -Descending
    foreach ($group in $sourceGroups) {
        $sourceName = if ($group.Name) { $group.Name } else { "(No source specified)" }
        Write-Host "  $sourceName : $($group.Count)" -ForegroundColor White
    }
    
    # Display sample of Drop items
    if ($dropItems.Count -gt 0) {
        Write-Host "`n=== Sample Drop Items (first 10) ===" -ForegroundColor Cyan
        $dropItems | Select-Object -First 10 | ForEach-Object {
            Write-Host "  [$($_.ItemID)] $($_.Name) -> Creature $($_.CreatureID)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    
} else {
    Write-Host "Error: Could not parse AscensionVanityDB structure" -ForegroundColor Red
    exit 1
}
