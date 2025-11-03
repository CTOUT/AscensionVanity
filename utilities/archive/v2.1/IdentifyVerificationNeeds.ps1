# Identify Items Needing Web Verification
# Finds items with creature IDs but empty/minimal descriptions

param(
    [string]$NewDBPath = ".\AscensionVanity\VanityDB_New.lua",
    [string]$OutputPath = ".\API_Analysis\Items_Needing_Verification.txt"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Items Needing Web Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Reading VanityDB_New.lua..." -ForegroundColor Yellow
$content = Get-Content $NewDBPath -Raw

$needsVerification = @()

# Find all items marked with NEEDS VERIFICATION
$pattern = '\[(\d+)\]\s*=\s*\{[^}]*itemid\s*=\s*(\d+)[^}]*name\s*=\s*"([^"]*)"[^}]*creaturePreview\s*=\s*(\d+)[^}]*description\s*=\s*"([^"]*)"[^}]*\}\s*,?\s*--\s*NEEDS VERIFICATION'
$regexMatches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

foreach ($match in $regexMatches) {
    $itemId = [int]$match.Groups[2].Value
    $name = $match.Groups[3].Value
    $creatureId = [int]$match.Groups[4].Value
    $description = $match.Groups[5].Value
    
    $needsVerification += @{
        ItemId = $itemId
        Name = $name
        CreatureId = $creatureId
        Description = $description
    }
}

Write-Host "Found $($needsVerification.Count) items needing web verification" -ForegroundColor Yellow
Write-Host ""

# Categorize by pattern
$categories = @{
    BeastmastersWhistle = @()
    EmptyDescription = @()
    ShortDescription = @()
    Other = @()
}

foreach ($item in $needsVerification) {
    if ($item.Name -match "Beastmaster's Whistle") {
        $categories.BeastmastersWhistle += $item
    }
    elseif ($item.Description -eq "") {
        $categories.EmptyDescription += $item
    }
    elseif ($item.Description.Length -lt 20) {
        $categories.ShortDescription += $item
    }
    else {
        $categories.Other += $item
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CATEGORIZATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Beastmaster's Whistle items: $($categories.BeastmastersWhistle.Count)" -ForegroundColor Cyan
Write-Host "Empty descriptions: $($categories.EmptyDescription.Count)" -ForegroundColor Yellow
Write-Host "Short descriptions (<20 chars): $($categories.ShortDescription.Count)" -ForegroundColor Yellow
Write-Host "Other: $($categories.Other.Count)" -ForegroundColor Gray
Write-Host ""

# Show samples from each category
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BEASTMASTER'S WHISTLE ITEMS (First 5)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
$count = 0
foreach ($item in $categories.BeastmastersWhistle) {
    if ($count -ge 5) { break }
    Write-Host "Item $($item.ItemId) - $($item.Name)" -ForegroundColor Cyan
    Write-Host "  Creature: $($item.CreatureId)" -ForegroundColor Gray
    Write-Host "  Web lookup: https://db.ascension.gg/?item=$($item.ItemId)" -ForegroundColor Green
    Write-Host ""
    $count++
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "EMPTY DESCRIPTION ITEMS (First 5)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
$count = 0
foreach ($item in $categories.EmptyDescription) {
    if ($count -ge 5) { break }
    if ($item.Name -notmatch "Beastmaster") {
        Write-Host "Item $($item.ItemId) - $($item.Name)" -ForegroundColor Yellow
        Write-Host "  Creature: $($item.CreatureId)" -ForegroundColor Gray
        Write-Host "  Web lookup: https://db.ascension.gg/?item=$($item.ItemId)" -ForegroundColor Green
        Write-Host ""
        $count++
    }
}

# Generate detailed report
Write-Host "Generating detailed report..." -ForegroundColor Yellow

if (-not (Test-Path ".\API_Analysis")) {
    New-Item -ItemType Directory -Path ".\API_Analysis" | Out-Null
}

$report = @"
ITEMS NEEDING WEB VERIFICATION
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================

Total items needing verification: $($needsVerification.Count)

CATEGORIZATION
- Beastmaster's Whistle: $($categories.BeastmastersWhistle.Count)
- Empty descriptions: $($categories.EmptyDescription.Count)
- Short descriptions: $($categories.ShortDescription.Count)
- Other: $($categories.Other.Count)

========================================
ALL ITEMS NEEDING VERIFICATION
========================================

Format: ItemID | Name | CreatureID | Description | Web Lookup URL

"@

foreach ($item in $needsVerification) {
    $report += "$($item.ItemId) | $($item.Name) | $($item.CreatureId) | $($item.Description) | https://db.ascension.gg/?item=$($item.ItemId)`n"
}

$report += @"

========================================
VERIFICATION INSTRUCTIONS
========================================

For each item:
1. Visit the web lookup URL
2. Check if it's a drop-based item
3. Verify the creature ID is correct
4. Update the description if needed
5. If NOT a drop, remove from VanityDB

Beastmaster's Whistle items are typically tame-able creatures
and should be kept in the database.

"@

$report | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "Detailed report saved to: $OutputPath" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "QUICK STATS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Most items ($($categories.BeastmastersWhistle.Count)) are Beastmaster's Whistle" -ForegroundColor Green
Write-Host "  These are confirmed tameable creatures" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠ $($categories.EmptyDescription.Count + $categories.ShortDescription.Count) items have empty/short descriptions" -ForegroundColor Yellow
Write-Host "  These may need manual verification" -ForegroundColor Gray
Write-Host ""
Write-Host "See full list in: $OutputPath" -ForegroundColor Cyan
Write-Host ""
