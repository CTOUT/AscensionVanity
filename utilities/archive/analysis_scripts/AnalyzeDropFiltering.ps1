# Analyze Drop-Based Filtering
# Shows how many items in the API scan are drop-based vs vendor/webstore

param(
    [string]$SavedVariablesPath = "d:\Program Files\Ascension Launcher\resources\client\WTF\Account\chris-tout@outlook.com\SavedVariables\AscensionVanity.lua"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Drop-Based Item Analysis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $SavedVariablesPath)) {
    Write-Host "ERROR: SavedVariables file not found" -ForegroundColor Red
    exit 1
}

Write-Host "Reading API scan data..." -ForegroundColor Yellow
$content = Get-Content $SavedVariablesPath -Raw

# Categories for filtering
$categories = @{
    "HasDrop" = 0
    "HasChance" = 0
    "Webstore" = 0
    "Purchase" = 0
    "Vendor" = 0
    "Quest" = 0
    "Achievement" = 0
    "NoCreature" = 0
    "HasCreature" = 0
    "Other" = 0
}

$dropItems = @()
$nonDropItems = @()
$totalItems = 0

# Extract all items with their descriptions and creature IDs
$pattern = '\["itemId"\]\s*=\s*(\d+),.*?\["description"\]\s*=\s*"([^"]*)".*?\["creaturePreview"\]\s*=\s*(\d+)'
$regexMatches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

foreach ($match in $regexMatches) {
    $itemId = [int]$match.Groups[1].Value
    $description = $match.Groups[2].Value
    $creatureId = [int]$match.Groups[3].Value
    
    $totalItems++
    
    # Categorize
    $isDrop = $false
    
    if ($description -match "drop|drops") {
        $categories["HasDrop"]++
        $isDrop = $true
    }
    if ($description -match "chance") {
        $categories["HasChance"]++
        $isDrop = $true
    }
    if ($description -match "Webstore|webstore") {
        $categories["Webstore"]++
    }
    if ($description -match "purchase|Purchase|buy") {
        $categories["Purchase"]++
    }
    if ($description -match "vendor|Vendor") {
        $categories["Vendor"]++
    }
    if ($description -match "quest|Quest") {
        $categories["Quest"]++
    }
    if ($description -match "achievement|Achievement") {
        $categories["Achievement"]++
    }
    
    if ($creatureId -eq 0) {
        $categories["NoCreature"]++
    } else {
        $categories["HasCreature"]++
    }
    
    # Store items
    if ($isDrop) {
        $dropItems += @{
            ItemId = $itemId
            Description = $description
            CreatureId = $creatureId
        }
    } else {
        $nonDropItems += @{
            ItemId = $itemId
            Description = $description
            CreatureId = $creatureId
        }
    }
}

Write-Host "Total items analyzed: $totalItems" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CATEGORIZATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Drop-Based Indicators:" -ForegroundColor Yellow
Write-Host "  Contains 'drop': $($categories['HasDrop'])" -ForegroundColor Cyan
Write-Host "  Contains 'chance': $($categories['HasChance'])" -ForegroundColor Cyan
Write-Host ""

Write-Host "Non-Drop Sources:" -ForegroundColor Yellow
Write-Host "  Webstore: $($categories['Webstore'])" -ForegroundColor Magenta
Write-Host "  Purchase/Vendor: $($categories['Purchase']) / $($categories['Vendor'])" -ForegroundColor Magenta
Write-Host "  Quest: $($categories['Quest'])" -ForegroundColor Magenta
Write-Host "  Achievement: $($categories['Achievement'])" -ForegroundColor Magenta
Write-Host ""

Write-Host "Creature Association:" -ForegroundColor Yellow
Write-Host "  Has creature ID: $($categories['HasCreature'])" -ForegroundColor Green
Write-Host "  No creature ID: $($categories['NoCreature'])" -ForegroundColor Red
Write-Host ""

# Calculate drop-based items
$dropBasedCount = $dropItems.Count
$nonDropCount = $nonDropItems.Count

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DROP-BASED FILTERING" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Items with drop indicators: $dropBasedCount" -ForegroundColor Green
Write-Host "Items without drop indicators: $nonDropCount" -ForegroundColor Yellow
Write-Host ""

$percentage = [math]::Round(($dropBasedCount / $totalItems) * 100, 2)
Write-Host "Drop-based percentage: $percentage%" -ForegroundColor Cyan
Write-Host ""

# Show samples
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SAMPLE DROP-BASED ITEMS (First 5)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$count = 0
foreach ($item in $dropItems) {
    if ($count -ge 5) { break }
    Write-Host "Item $($item.ItemId) (Creature: $($item.CreatureId)):" -ForegroundColor Green
    Write-Host "  $($item.Description)" -ForegroundColor Gray
    Write-Host ""
    $count++
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SAMPLE NON-DROP ITEMS (First 5)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$count = 0
foreach ($item in $nonDropItems) {
    if ($count -ge 5) { break }
    Write-Host "Item $($item.ItemId) (Creature: $($item.CreatureId)):" -ForegroundColor Yellow
    Write-Host "  $($item.Description)" -ForegroundColor Gray
    Write-Host ""
    $count++
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RECOMMENDATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($dropBasedCount -gt 0) {
    Write-Host "✓ Found $dropBasedCount drop-based items" -ForegroundColor Green
    Write-Host ""
    Write-Host "To filter for drops only:" -ForegroundColor Yellow
    Write-Host "  Filter where description contains 'drop' OR 'chance'" -ForegroundColor White
    Write-Host "  This will give you tameable/collectable creatures" -ForegroundColor White
} else {
    Write-Host "⚠ No drop-based items found" -ForegroundColor Red
}
Write-Host ""
