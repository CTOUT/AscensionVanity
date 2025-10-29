# GenerateVanityDB_FromSimplifiedScan.ps1
# Generates VanityDB.lua from the NEW simplified API scan format
# Input: Simplified scan with ONLY 5 fields (itemid, name, description, icon, creaturePreview)
# Output: Optimized VanityDB.lua with icon indexing

param(
    [string]$ScanFile = "data\AscensionVanity_SimplifiedScan.lua",
    [string]$OutputDB = "AscensionVanity\VanityDB.lua"
)

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        VanityDB Generator - From Simplified API Scan            ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Combat pet categories and their icons
$categoryPatterns = @{
    "Beastmaster's Whistle" = "Ability_Hunter_BeastCall"
    "Blood Soaked Vellum" = "Ability_DK_RuneWeapon"
    "Summoner's Stone" = "Spell_Shadow_SummonFelGuard"
    "Draconic Warhorn" = "Spell_Nature_WispSplode"
    "Elemental Lodestone" = "Spell_Fire_SelfDestruct"
}

# Icon index mapping
$iconList = @(
    "Ability_Hunter_BeastCall",      # 1
    "Ability_DK_RuneWeapon",         # 2
    "Spell_Shadow_SummonFelGuard",   # 3
    "Spell_Nature_WispSplode",       # 4
    "Spell_Fire_SelfDestruct"        # 5
)

$iconIndex = @{}
for ($i = 0; $i -lt $iconList.Count; $i++) {
    $iconIndex[$iconList[$i]] = $i + 1
}

if (-not (Test-Path $ScanFile)) {
    Write-Host "❌ Error: Scan file not found: $ScanFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "This script expects the NEW simplified scan format." -ForegroundColor Yellow
    Write-Host "Please run a fresh scan in-game with the updated APIScanner.lua" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "Loading simplified scan data..." -ForegroundColor Yellow
$scanContent = Get-Content $ScanFile -Raw

# Parse the APIDump section
Write-Host "Parsing APIDump..." -ForegroundColor Yellow
$items = @()

# Match each item entry
$itemMatches = [regex]::Matches($scanContent, '\[(\d+)\]\s*=\s*\{([^}]+)\}')

foreach ($match in $itemMatches) {
    $itemId = [int]$match.Groups[1].Value
    $itemContent = $match.Groups[2].Value
    
    # Extract fields
    $name = if ($itemContent -match 'name\s*=\s*"([^"]+)"') { $matches[1] } else { "" }
    $description = if ($itemContent -match 'description\s*=\s*"([^"]*)"') { $matches[1] } else { "" }
    $icon = if ($itemContent -match 'icon\s*=\s*"([^"]+)"') { $matches[1] } else { "" }
    $creaturePreview = if ($itemContent -match 'creaturePreview\s*=\s*(\d+)') { [int]$matches[1] } else { 0 }
    
    # Check if this is a combat pet item
    $category = $null
    foreach ($catName in $categoryPatterns.Keys) {
        if ($name -like "$catName*") {
            $category = $catName
            break
        }
    }
    
    if ($category) {
        $items += [PSCustomObject]@{
            ItemId = $itemId
            Name = $name
            Description = $description
            Icon = $icon
            CreaturePreview = $creaturePreview
            Category = $category
        }
    }
}

Write-Host "`nFiltered Results:" -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$categoryStats = $items | Group-Object Category | Sort-Object Name
foreach ($cat in $categoryStats) {
    Write-Host "  $($cat.Name): $($cat.Count) items" -ForegroundColor White
}

Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  TOTAL: $($items.Count) combat pet items`n" -ForegroundColor Yellow

# Generate optimized database
Write-Host "Generating optimized VanityDB.lua..." -ForegroundColor Yellow

$dbContent = @"
-- AscensionVanity Database - Combat Pets Only
-- Generated from simplified API scan on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Contains ONLY the 5 combat pet vanity item categories
-- Total items: $($items.Count)
-- All item IDs are GAME item IDs (what the API returns)

-- Icon lookup table (for space optimization)
AV_IconList = {
    [1] = "Ability_Hunter_BeastCall",      -- Beastmaster's Whistles (Hunter)
    [2] = "Ability_DK_RuneWeapon",         -- Blood Soaked Vellums (Death Knight)
    [3] = "Spell_Shadow_SummonFelGuard",   -- Summoner's Stones (Warlock)
    [4] = "Spell_Nature_WispSplode",       -- Draconic Warhorns (Mage)
    [5] = "Spell_Fire_SelfDestruct"        -- Elemental Lodestones (Shaman)
}

AV_VanityItems = {
"@

# Sort by ItemId
$sortedItems = $items | Sort-Object ItemId

foreach ($item in $sortedItems) {
    $safeName = $item.Name -replace '"', '\"'
    $safeDesc = $item.Description -replace '"', '\"'
    
    # Get icon index
    $expectedIcon = $categoryPatterns[$item.Category]
    $iconIdx = $iconIndex[$expectedIcon]
    
    $dbContent += @"

    [$($item.ItemId)] = {
        itemid = $($item.ItemId),
        name = "$safeName",
        creaturePreview = $($item.CreaturePreview),
        description = "$safeDesc",
        icon = $iconIdx
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
Write-Host "  Items: $($items.Count)" -ForegroundColor Cyan
Write-Host "  All IDs are GAME item IDs (correct!)" -ForegroundColor Green
Write-Host ""
