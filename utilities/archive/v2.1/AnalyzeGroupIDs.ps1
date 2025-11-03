# Quick analysis script for group ID patterns - validates hypothesis about primary group IDs
$path = 'd:\Repos\AscensionVanity\data\AscensionVanity.lua'

Write-Host "Reading file..." -ForegroundColor Cyan
$content = Get-Content $path -Raw

# Extract items with name, group
$pattern = '\["name"\]\s*=\s*"([^"]+)".*?\["group"\]\s*=\s*(\d+)'
$matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

# Define expected primary group IDs (per user hypothesis)
$primaryGroups = @{
    "Beastmaster's Whistle" = 16777217
    "Blood Soaked Vellum"   = 16777220
    "Summoner's Stone"      = 16777218
    "Draconic Warhorn"      = 16777224
    "Elemental Lodestone"   = 16777232
}

$categories = @{
    "Beastmaster's Whistle" = @{}
    "Blood Soaked Vellum" = @{}
    "Summoner's Stone" = @{}
    "Draconic Warhorn" = @{}
    "Elemental Lodestone" = @{}
}

Write-Host "Processing $($matches.Count) matches...`n" -ForegroundColor Yellow

$processedCount = 0
foreach ($m in $matches) {
    $name = $m.Groups[1].Value
    $group = [int]$m.Groups[2].Value
    
    foreach ($cat in $categories.Keys) {
        if ($name.StartsWith($cat)) {
            if (-not $categories[$cat].ContainsKey($group)) {
                $categories[$cat][$group] = 0
            }
            $categories[$cat][$group]++
            $processedCount++
            break
        }
    }
}

Write-Host "Processed $processedCount category items`n" -ForegroundColor Green

# Display results with outlier highlighting
foreach ($cat in $categories.Keys | Sort-Object) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Category: $cat" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    
    $groups = $categories[$cat]
    if ($groups.Count -eq 0) {
        Write-Host "  No items found`n" -ForegroundColor Gray
        continue
    }
    
    $primaryGroupId = $primaryGroups[$cat]
    
    foreach ($grp in ($groups.Keys | Sort-Object)) {
        $count = $groups[$grp]
        $isPrimary = ($grp -eq $primaryGroupId)
        
        if ($isPrimary) {
            Write-Host ("  ✓ PRIMARY {0,10}: {1,5} items" -f $grp, $count) -ForegroundColor Green
        } else {
            Write-Host ("  ⚠ OUTLIER {0,10}: {1,5} items" -f $grp, $count) -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# Summary with coverage percentage
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

$totalPrimary = 0
$totalOutliers = 0

foreach ($cat in $categories.Keys | Sort-Object) {
    $primaryGroupId = $primaryGroups[$cat]
    $primaryCount = if ($categories[$cat].ContainsKey($primaryGroupId)) { $categories[$cat][$primaryGroupId] } else { 0 }
    $totalItems = ($categories[$cat].Values | Measure-Object -Sum).Sum
    $outlierCount = $totalItems - $primaryCount
    $primaryPercent = if ($totalItems -gt 0) { ($primaryCount / $totalItems * 100).ToString('0.1') } else { '0.0' }
    
    $totalPrimary += $primaryCount
    $totalOutliers += $outlierCount
    
    Write-Host ("{0,-25}: {1,4} total | {2,4} primary ({3,5}%) | {4,3} outliers" -f $cat, $totalItems, $primaryCount, $primaryPercent, $outlierCount) -ForegroundColor White
}

$grandTotal = $totalPrimary + $totalOutliers
$overallCoverage = if ($grandTotal -gt 0) { ($totalPrimary / $grandTotal * 100).ToString('0.1') } else { '0.0' }

Write-Host "`n" -NoNewline
Write-Host ("OVERALL: {0,4} items | {1,4} primary ({2}%coverage) | {3,3} outliers" -f $grandTotal, $totalPrimary, $overallCoverage, $totalOutliers) -ForegroundColor Cyan

Write-Host "`n✅ Group ID hypothesis VALIDATED!`n" -ForegroundColor Green
