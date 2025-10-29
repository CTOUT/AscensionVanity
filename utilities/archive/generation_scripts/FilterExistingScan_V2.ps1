# Filter Existing Scan - Remove promotional/event items
# Applies exclusion filters to already-scanned data

param(
    [Parameter(Mandatory=$false)]
    [string]$InputFile = "data\AscensionVanity_Fresh_Scan_2025-10-28_NEW.lua",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "AscensionVanity\VanityDB.lua"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Filter Existing Scan" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Exclusion keywords (must match APIScanner.lua)
$exclusionKeywords = @(
    "purchase",
    "website",
    "previously",
    "bazaar",
    "seasonal",
    "reward",
    "promotional",
    "promo",
    "event",
    "limited"
)

Write-Host "Reading scan file: $InputFile" -ForegroundColor Yellow
$content = Get-Content $InputFile -Raw

# Extract APIDump section
$apidumpStart = $content.IndexOf('["APIDump"] = {')
$apidumpEnd = $content.IndexOf('["LastScanDate"]', $apidumpStart)
$apidumpSection = $content.Substring($apidumpStart, $apidumpEnd - $apidumpStart)

Write-Host "✓ Found APIDump section" -ForegroundColor Green

# Parse items using regex
$itemPattern = '\[(\d+)\] = \{([^}]+(?:\{[^}]+\}[^}]*)?)\}'
$items = [regex]::Matches($apidumpSection, $itemPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

Write-Host "✓ Found $($items.Count) items in scan" -ForegroundColor Green

# Filter items
$excludedReasons = @{}
$excludedCount = 0
$itemObjects = @()  # Store items with their IDs for sorting

foreach ($match in $items) {
    $itemId = $match.Groups[1].Value
    $itemData = $match.Groups[2].Value
    
    # Extract name and description
    $name = ""
    $description = ""
    
    if ($itemData -match '\["name"\] = "([^"]+)"') {
        $name = $matches[1]
    }
    
    if ($itemData -match '\["description"\] = "([^"]+)"') {
        $description = $matches[1]
    }
    
    $nameLower = $name.ToLower()
    $descriptionLower = $description.ToLower()
    
    # Check exclusion keywords in both name AND description
    $excluded = $false
    $excludeReason = ""
    
    foreach ($keyword in $exclusionKeywords) {
        if ($nameLower -match $keyword -or $descriptionLower -match $keyword) {
            $excluded = $true
            $excludeReason = $keyword
            break
        }
    }
    
    if ($excluded) {
        if (-not $excludedReasons.ContainsKey($excludeReason)) {
            $excludedReasons[$excludeReason] = @()
        }
        $excludedReasons[$excludeReason] += $name
        $excludedCount++
    } else {
        # Store item with its ID for sorting
        $itemObjects += [PSCustomObject]@{
            ItemId = [int]$itemId
            ItemBlock = $match.Groups[0].Value
        }
    }
}

# Sort items by ItemId numerically
Write-Host "Sorting items by ID..." -ForegroundColor Yellow
$sortedItems = $itemObjects | Sort-Object ItemId | Select-Object -ExpandProperty ItemBlock

Write-Host "`n📊 Filtering Results:" -ForegroundColor Cyan
Write-Host "  Total items scanned: $($items.Count)" -ForegroundColor White
Write-Host "  Items kept: $($sortedItems.Count)" -ForegroundColor Green
Write-Host "  Items excluded: $excludedCount" -ForegroundColor Red

if ($excludedCount -gt 0) {
    Write-Host "`n🗑️ Exclusion Breakdown:" -ForegroundColor Yellow
    foreach ($reason in $excludedReasons.Keys | Sort-Object) {
        $count = $excludedReasons[$reason].Count
        Write-Host "  $reason`: $count items" -ForegroundColor White
    }
    
    Write-Host "`n📝 Sample excluded items:" -ForegroundColor Yellow
    $sample = $excludedReasons.GetEnumerator() | ForEach-Object {
        $_.Value | Select-Object -First 2
    } | Select-Object -First 10
    
    foreach ($itemName in $sample) {
        Write-Host "    - $itemName" -ForegroundColor DarkGray
    }
}

# Generate VanityDB.lua
Write-Host "`n📦 Generating VanityDB.lua..." -ForegroundColor Cyan

$header = @"
-- VanityDB.lua
-- Combat Pet Vanity Items Database
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Items: $($sortedItems.Count)
-- Filtered: Excluded promotional/event/reward items
-- Sorted: Items sorted numerically by itemid

VanityDB = {
"@

$footer = @"
}
"@

$itemsFormatted = $sortedItems -join ",`n`t"

$vanityDBContent = @"
$header
`t$itemsFormatted
$footer
"@

# Write output file
$vanityDBContent | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline

Write-Host "✓ Generated: $OutputFile" -ForegroundColor Green
Write-Host "  Total items: $($sortedItems.Count)" -ForegroundColor White
Write-Host "  Items sorted numerically by itemid" -ForegroundColor Cyan

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✅ Filtering Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
