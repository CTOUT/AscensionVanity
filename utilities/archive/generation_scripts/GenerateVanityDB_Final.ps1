# GenerateVanityDB_Final.ps1
# Final optimized generation with correct Game Item IDs

param(
    [string]$SourceFile = "data\EmptyDescriptions_Validated.json",
    [string]$OutputDB = "AscensionVanity\VanityDB.lua"
)

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     VanityDB Final Generator - Correct IDs + Optimizations      ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Icon mapping
$iconMap = @{
    "Beastmaster's Whistle" = 1
    "Blood Soaked Vellum" = 2
    "Summoner's Stone" = 3
    "Draconic Warhorn" = 4
    "Elemental Lodestone" = 5
}

Write-Host "Loading validated item data..." -ForegroundColor Yellow
$items = Get-Content $SourceFile | ConvertFrom-Json

Write-Host "Processing $($items.Count) items..." -ForegroundColor Yellow

$processedItems = @()
$categoryStats = @{}

foreach ($item in $items) {
    # ONLY USE VALIDATED ITEMS with correct game IDs
    if (-not $item.Validated) {
        continue  # Skip unvalidated items
    }
    
    # Determine category
    $category = $null
    foreach ($cat in $iconMap.Keys) {
        if ($item.Name -like "$cat*") {
            $category = $cat
            if (-not $categoryStats.ContainsKey($category)) {
                $categoryStats[$category] = 0
            }
            $categoryStats[$category]++
            break
        }
    }
    
    if ($category) {
        $processedItems += [PSCustomObject]@{
            GameItemId = $item.DbItemId  # This is the CORRECT game item ID
            Name = $item.Name
            CreatureId = $item.CreatureId
            Description = $item.GeneratedDescription
            IconIndex = $iconMap[$category]
            Category = $category
        }
    }
}

Write-Host "`nCategory Breakdown:" -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
foreach ($cat in $categoryStats.Keys | Sort-Object) {
    Write-Host "  $cat : $($categoryStats[$cat]) items" -ForegroundColor White
}
Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  TOTAL: $($processedItems.Count) items`n" -ForegroundColor Yellow

# Generate database
Write-Host "Generating optimized database..." -ForegroundColor Yellow

$dbContent = @"
-- AscensionVanity Database - Combat Pets Only (Optimized & Corrected)
-- Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Uses CORRECT game Item IDs as primary keys
-- Total items: $($processedItems.Count)
-- Optimization: Icon indexing (~40KB saved)

-- Icon lookup table
AV_IconList = {
    [1] = "Ability_Hunter_BeastCall",      -- Beastmaster's Whistles (Hunter)
    [2] = "Ability_DK_RuneWeapon",         -- Blood Soaked Vellums (Death Knight)
    [3] = "Spell_Shadow_SummonFelGuard",   -- Summoner's Stones (Warlock)
    [4] = "Spell_Nature_WispSplode",       -- Draconic Warhorns (Mage)
    [5] = "Spell_Fire_SelfDestruct"        -- Elemental Lodestones (Shaman)
}

AV_VanityItems = {
"@

# Sort by Game Item ID
$sortedItems = $processedItems | Sort-Object GameItemId

foreach ($item in $sortedItems) {
    $safeName = $item.Name -replace '"', '\"'
    $safeDesc = $item.Description -replace '"', '\"'
    
    $dbContent += @"

    [$($item.GameItemId)] = {
        itemid = $($item.GameItemId),
        name = "$safeName",
        creaturePreview = $($item.CreatureId),
        description = "$safeDesc",
        icon = $($item.IconIndex)
    },
"@
}

$dbContent += @"

}
"@

# Write output
Write-Host "Writing to $OutputDB..." -ForegroundColor Yellow
$dbContent | Set-Content $OutputDB -Encoding UTF8

$fileSize = (Get-Item $OutputDB).Length / 1KB

Write-Host "`n✅ Generation complete!" -ForegroundColor Green
Write-Host "  Output: $OutputDB" -ForegroundColor Cyan
Write-Host "  Size: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Cyan
Write-Host "  Items: $($processedItems.Count)" -ForegroundColor Cyan
Write-Host "  Using CORRECT Game Item IDs as keys" -ForegroundColor Green
Write-Host ""
