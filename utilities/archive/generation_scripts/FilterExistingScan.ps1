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
$lines = Get-Content $InputFile

# Find APIDump section
$inAPIDump = $false
$itemLines = @()
$currentItem = @()

foreach ($line in $lines) {
    if ($line -match '\["APIDump"\] = \{') {
        $inAPIDump = $true
        continue
    }
    
    if ($inAPIDump) {
        if ($line -match '^\t\},\s*$' -and $currentItem.Count -gt 0) {
            # End of item
            $currentItem += $line
            $itemLines += ,@($currentItem)
            $currentItem = @()
        } elseif ($line -match '^\t\["LastScanDate"\]' -or $line -match '^\},\s*$') {
            # End of APIDump section
            break
        } else {
            $currentItem += $line
        }
    }
}

Write-Host "✓ Found $($itemLines.Count) items in APIDump" -ForegroundColor Green

# Filter items
$filteredItems = @()
$excludedItems = @()
$excludedReasons = @{}

foreach ($itemBlock in $itemLines) {
    $itemText = $itemBlock -join "`n"
    
    # Extract name
    if ($itemText -match '\["name"\] = "([^"]+)"') {
        $name = $matches[1]
        $nameLower = $name.ToLower()
        
        # Check exclusion keywords
        $excluded = $false
        $excludeReason = ""
        
        foreach ($keyword in $exclusionKeywords) {
            if ($nameLower -match $keyword) {
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
            $excludedItems += $itemText
        } else {
            $filteredItems += $itemBlock
        }
    }
}

Write-Host "`n📊 Filtering Results:" -ForegroundColor Cyan
Write-Host "  Total items scanned: $($itemLines.Count)" -ForegroundColor White
Write-Host "  Items kept: $($filteredItems.Count)" -ForegroundColor Green
Write-Host "  Items excluded: $($excludedItems.Count)" -ForegroundColor Red

if ($excludedItems.Count -gt 0) {
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
-- Items: $($filteredItems.Count)
-- Filtered: Excluded promotional/event/reward items

VanityDB = {
"@

$footer = @"
}
"@

# Format items
$formattedItems = foreach ($itemBlock in $filteredItems) {
    $itemBlock -join "`n"
}

$itemsFormatted = $formattedItems -join ",`n"

$vanityDBContent = @"
$header
$itemsFormatted
$footer
"@

# Write output file
$vanityDBContent | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline

Write-Host "✓ Generated: $OutputFile" -ForegroundColor Green
Write-Host "  Total items: $($filteredItems.Count)" -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✅ Filtering Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
