# GenerateVanityDB_V2.ps1
# Generates VanityDB.lua and VanityDB_Regions.lua from DropsOnly_Analysis.json
# New format: Full data structure with itemid, name, creaturePreview, description, icon

param(
    [string]$InputFile = "data\DropsOnly_Analysis.json",
    [string]$OutputDB = "data\VanityDB.lua",
    [string]$OutputRegions = "data\VanityDB_Regions.lua"
)

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           VanityDB V2 Generator - API to LUA Database           ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Input:  $InputFile" -ForegroundColor Gray
Write-Host "  Output: $OutputDB" -ForegroundColor Gray
Write-Host "  Output: $OutputRegions`n" -ForegroundColor Gray

# Read input JSON file
Write-Host "Reading DropsOnly_Analysis.json..." -ForegroundColor Yellow
$jsonData = Get-Content $InputFile -Encoding UTF8 | ConvertFrom-Json

$items = @()
$categoryCount = @{}

# Process each category
Write-Host "Parsing items..." -ForegroundColor Yellow
foreach ($category in $jsonData.PSObject.Properties) {
    $categoryName = $category.Name
    $categoryItems = $category.Value
    
    Write-Host "  Processing $categoryName ($($categoryItems.Count) items)..." -ForegroundColor Gray
    $categoryCount[$categoryName] = $categoryItems.Count
    
    foreach ($item in $categoryItems) {
        # Extract region from description
        $region = ""
        if ($item.Description -match "within (.+)$") {
            $region = $matches[1] -replace '\.$', ''
        }
        
        # Add to items collection
        $items += [PSCustomObject]@{
            itemId = $item.ItemId
            name = $item.Name
            creaturePreview = $item.CreatureId
            description = $item.Description
            icon = "Interface/Icons/Ability_Hunter_BeastCall" # Default icon, we'll need to get actual icons from API
            region = $region
            category = $categoryName
        }
    }
}

Write-Host "`nExtraction Results:" -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
foreach ($cat in $categoryCount.Keys | Sort-Object) {
    Write-Host "  $cat : $($categoryCount[$cat]) items" -ForegroundColor White
}
Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  TOTAL: $($items.Count) items`n" -ForegroundColor Yellow

# Generate VanityDB.lua
Write-Host "Generating VanityDB.lua..." -ForegroundColor Yellow

$dbContent = @"
-- AscensionVanity Database V2.0
-- Generated from API dump on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
-- Pet Taming Items: $($items.Count) drop-based items
-- Source: In-game API extraction

AV_VanityItems = {
"@

# Sort by itemId for consistency
$sortedItems = $items | Sort-Object { [int]$_.itemId }

foreach ($item in $sortedItems) {
    # The JSON input already contains Lua-escaped strings (e.g., \" for quotes)
    # We can use them directly without re-escaping
    # Note: If future sources have unescaped quotes, add .Replace('"', '\"') here
    $safeName = $item.name
    $safeDesc = $item.description
    
    $dbContent += @"

    [$($item.itemId)] = {
        itemid = $($item.itemId),
        name = "$safeName",
        creaturePreview = $($item.creaturePreview),
        description = "$safeDesc",
        icon = "$($item.icon)"
    }, -- $($item.category)
"@
}

$dbContent += @"

}
"@

$dbContent | Out-File $OutputDB -Encoding UTF8
Write-Host "  ✓ Created: $OutputDB ($($items.Count) items)" -ForegroundColor Green

# Generate VanityDB_Regions.lua
Write-Host "Generating VanityDB_Regions.lua..." -ForegroundColor Yellow

$regionsContent = @"
-- AscensionVanity Regions Lookup V2.0
-- Generated from API dump on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
-- Maps itemId to region/location
-- Optional: Only load if showRegions config enabled

AV_Regions = {
"@

foreach ($item in $sortedItems) {
    if ($item.region) {
        $safeRegion = $item.region -replace '"', '\"'
        $regionsContent += "`n    [$($item.itemId)] = `"$safeRegion`", -- $($item.name)"
    }
}

$regionsContent += @"

}
"@

$regionsContent | Out-File $OutputRegions -Encoding UTF8
$regionCount = ($items | Where-Object { $_.region }).Count
Write-Host "  ✓ Created: $OutputRegions ($regionCount regions)" -ForegroundColor Green

# Generate statistics
Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                      Generation Complete                        ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`nStatistics:" -ForegroundColor Yellow
Write-Host "  Total Items:        $($items.Count)" -ForegroundColor White
Write-Host "  With Regions:       $regionCount" -ForegroundColor White
Write-Host "  With Icons:         $(($items | Where-Object { $_.icon }).Count)" -ForegroundColor White
Write-Host "  Categories:         $($categoryCount.Count)" -ForegroundColor White

Write-Host "`nFile Sizes:" -ForegroundColor Yellow
$dbSize = (Get-Item $OutputDB).Length / 1KB
$regionsSize = (Get-Item $OutputRegions).Length / 1KB
Write-Host "  VanityDB.lua:       $([math]::Round($dbSize, 2)) KB" -ForegroundColor White
Write-Host "  VanityDB_Regions.lua: $([math]::Round($regionsSize, 2)) KB" -ForegroundColor White
Write-Host "  Total:              $([math]::Round($dbSize + $regionsSize, 2)) KB`n" -ForegroundColor White

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review generated files" -ForegroundColor Gray
Write-Host "  2. Update Core.lua to load new database format" -ForegroundColor Gray
Write-Host "  3. Test in-game" -ForegroundColor Gray
Write-Host "  4. Update .toc file if needed`n" -ForegroundColor Gray
