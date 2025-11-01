# Process Fresh Scan - Convert simplified dump to VanityDB.lua
# Filters out non-combat-pet items and generates clean database

param(
    [string]$ScanFile = "data\AscensionVanity_Fresh_Scan_2025-10-28_185408.lua",
    [string]$OutputFile = "AscensionVanity\VanityDB.lua",
    [switch]$ShowRogueItems  # Show items that shouldn't be there
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Processing Fresh API Scan" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$repoRoot = Split-Path $PSScriptRoot -Parent
$scanPath = Join-Path $repoRoot $ScanFile
$outputPath = Join-Path $repoRoot $OutputFile

if (-not (Test-Path $scanPath)) {
    Write-Host "ERROR: Scan file not found: $scanPath" -ForegroundColor Red
    exit 1
}

Write-Host "Reading scan file..." -ForegroundColor Yellow
$content = Get-Content $scanPath -Raw

# Extract total items
if ($content -match '\["TotalItems"\]\s*=\s*(\d+)') {
    $totalItems = [int]$matches[1]
    Write-Host "Total items scanned: $totalItems" -ForegroundColor White
}

# Define combat pet prefixes (items we WANT to keep)
$combatPetPrefixes = @(
    "Beastmaster's Whistle:",
    "Blood Soaked Vellum:",
    "Summoner's Crystal:",
    "Draconic Summoning Crystal:",
    "Elemental Summoning Crystal:"
)

# Define rogue prefixes (items we DON'T want)
$roguePatterns = @(
    "Blood Troll",
    "Bloodclaw",
    "Blood Knight",
    "Bloodfang",
    "Bloodmail",
    "Blood Guard's",
    "Summoner's Robes",
    "Summoner's Boots"
)

# Parse items from ValidationResults
$itemMatches = [regex]::Matches($content, '\[(\d+)\]\s*=\s*\{[^}]*\["name"\]\s*=\s*"([^"]+)"')

$validItems = @()
$rogueItems = @()

foreach ($match in $itemMatches) {
    $itemId = $match.Groups[1].Value
    $itemName = $match.Groups[2].Value
    
    # Check if it's a rogue item
    $isRogue = $false
    foreach ($pattern in $roguePatterns) {
        if ($itemName -like "*$pattern*") {
            $isRogue = $true
            $rogueItems += [PSCustomObject]@{
                ItemID = $itemId
                Name = $itemName
            }
            break
        }
    }
    
    if (-not $isRogue) {
        # Check if it matches combat pet prefixes
        $isCombatPet = $false
        foreach ($prefix in $combatPetPrefixes) {
            if ($itemName -like "$prefix*") {
                $isCombatPet = $true
                break
            }
        }
        
        if ($isCombatPet) {
            $validItems += [PSCustomObject]@{
                ItemID = $itemId
                Name = $itemName
            }
        }
    }
}

Write-Host "`nFiltering results:" -ForegroundColor Cyan
Write-Host "  Valid combat pets: $($validItems.Count)" -ForegroundColor Green
Write-Host "  Rogue items filtered: $($rogueItems.Count)" -ForegroundColor Red
Write-Host "  Reduction: $(($rogueItems.Count / $totalItems * 100).ToString('0.0'))%" -ForegroundColor Yellow

if ($ShowRogueItems -and $rogueItems.Count -gt 0) {
    Write-Host "`nRogue items found (filtered out):" -ForegroundColor Red
    $rogueItems | Sort-Object Name | ForEach-Object {
        Write-Host "  [$($_.ItemID)] $($_.Name)" -ForegroundColor Red
    }
}

# Now extract full item data for valid items
Write-Host "`nExtracting item data..." -ForegroundColor Yellow

$validItemIds = $validItems.ItemID
$itemDataPattern = '\[(\d+)\]\s*=\s*\{([^}]+)\}'
$allItemMatches = [regex]::Matches($content, $itemDataPattern)

$itemDatabase = @{}
foreach ($match in $allItemMatches) {
    $itemId = $match.Groups[1].Value
    if ($validItemIds -contains $itemId) {
        $itemData = $match.Groups[2].Value
        
        # Parse fields
        $name = if ($itemData -match '\["name"\]\s*=\s*"([^"]+)"') { $matches[1] } else { "" }
        $description = if ($itemData -match '\["description"\]\s*=\s*"([^"]+)"') { $matches[1] } else { "" }
        $icon = if ($itemData -match '\["icon"\]\s*=\s*"([^"]+)"') { $matches[1] } else { "" }
        $creaturePreview = if ($itemData -match '\["creaturePreview"\]\s*=\s*(\d+)') { $matches[1] } else { "0" }
        
        $itemDatabase[$itemId] = @{
            Name = $name
            Description = $description
            Icon = $icon
            CreaturePreview = $creaturePreview
        }
    }
}

Write-Host "Extracted data for $($itemDatabase.Count) items" -ForegroundColor Green

# Generate VanityDB.lua
Write-Host "`nGenerating VanityDB.lua..." -ForegroundColor Yellow

$output = @"
-- AscensionVanity Database
-- Auto-generated from fresh API scan
-- Scan date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Total combat pet items: $($itemDatabase.Count)

AscensionVanityDB_Items = {
"@

# Sort by item ID
$sortedIds = $itemDatabase.Keys | Sort-Object { [int]$_ }

foreach ($itemId in $sortedIds) {
    $item = $itemDatabase[$itemId]
    $escapedDesc = $item.Description -replace '"', '\"'
    
    $output += @"

    [$itemId] = {
        name = "$($item.Name)",
        description = "$escapedDesc",
        icon = "$($item.Icon)",
        creaturePreview = $($item.CreaturePreview),
    },
"@
}

$output += @"

}
"@

# Write output file
$output | Out-File -FilePath $outputPath -Encoding UTF8
Write-Host "✅ VanityDB.lua created: $outputPath" -ForegroundColor Green

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Input: $ScanFile" -ForegroundColor White
Write-Host "  Total items scanned: $totalItems" -ForegroundColor White
Write-Host "  Rogue items filtered: $($rogueItems.Count)" -ForegroundColor Red
Write-Host "  Valid combat pets: $($itemDatabase.Count)" -ForegroundColor Green
Write-Host "`nOutput: $OutputFile" -ForegroundColor White
Write-Host "  Items in database: $($itemDatabase.Count)" -ForegroundColor Green
Write-Host "  File size: $((Get-Item $outputPath).Length / 1KB | ForEach-Object { $_.ToString('0.0') }) KB" -ForegroundColor White

Write-Host "`n✅ Processing complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Review the generated VanityDB.lua" -ForegroundColor White
Write-Host "2. Test in-game with /avdebug commands" -ForegroundColor White
Write-Host "3. Compare with previous database" -ForegroundColor White
Write-Host ""
