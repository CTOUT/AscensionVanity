# Analyze API Scan with Smart Drop Filtering
# Filters for drop-based items while preserving items with creatures but no description

param(
    [string]$SavedVariablesPath = "d:\Program Files\Ascension Launcher\resources\client\WTF\Account\chris-tout@outlook.com\SavedVariables\AscensionVanity.lua",
    [string]$VanityDBPath = ".\AscensionVanity\VanityDB.lua",
    [switch]$Detailed
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Drop-Based Filter Analysis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $SavedVariablesPath)) {
    Write-Host "ERROR: SavedVariables file not found" -ForegroundColor Red
    exit 1
}

Write-Host "Reading API scan data..." -ForegroundColor Yellow
$content = Get-Content $SavedVariablesPath -Raw

# Smart filtering categories
$stats = @{
    Total = 0
    ConfirmedDrops = 0
    PotentialDrops = 0
    ExplicitlyExcluded = 0
    NoCreature = 0
    Included = 0
}

$includedItems = @{}  # CreatureID -> @(ItemIDs)
$excludedItems = @()
$emptyDescriptionItems = @()

# Extract all items with their descriptions and creature IDs
$pattern = '\["itemId"\]\s*=\s*(\d+),.*?\["name"\]\s*=\s*"([^"]*)".*?\["description"\]\s*=\s*"([^"]*)".*?\["creaturePreview"\]\s*=\s*(\d+)'
$regexMatches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

Write-Host "Processing $($regexMatches.Count) items with smart filtering..." -ForegroundColor Yellow
Write-Host ""

foreach ($match in $regexMatches) {
    $itemId = [int]$match.Groups[1].Value
    $itemName = $match.Groups[2].Value
    $description = $match.Groups[3].Value
    $creatureId = [int]$match.Groups[4].Value
    
    $stats.Total++
    
    # Determine if this item should be included
    $shouldInclude = $false
    $reason = ""
    
    # RULE 1: Confirmed drops (has "drop" or "chance" in description)
    if ($description -match "drop|drops|chance") {
        $shouldInclude = $true
        $stats.ConfirmedDrops++
        $reason = "Confirmed drop (description)"
    }
    # RULE 2: Explicit exclusions (even if they have creature IDs)
    elseif ($description -match "Webstore|webstore|purchase|Purchase|buy|vendor|Vendor|quest|Quest|achievement|Achievement") {
        $shouldInclude = $false
        $stats.ExplicitlyExcluded++
        $reason = "Excluded (vendor/webstore/quest/achievement)"
        
        $excludedItems += @{
            ItemId = $itemId
            Name = $itemName
            Description = $description
            CreatureId = $creatureId
            Reason = $reason
        }
    }
    # RULE 3: Has creature ID but no/minimal description (potential drop - needs web verification)
    elseif ($creatureId -gt 0 -and ($description -eq "" -or $description.Length -lt 20)) {
        $shouldInclude = $true
        $stats.PotentialDrops++
        $reason = "Potential drop (has creature, needs verification)"
        
        $emptyDescriptionItems += @{
            ItemId = $itemId
            Name = $itemName
            Description = $description
            CreatureId = $creatureId
        }
    }
    # RULE 4: Has creature ID with non-exclusion description (potential drop)
    elseif ($creatureId -gt 0) {
        $shouldInclude = $true
        $stats.PotentialDrops++
        $reason = "Potential drop (has creature)"
    }
    # RULE 5: No creature ID
    else {
        $shouldInclude = $false
        $stats.NoCreature++
        $reason = "No creature ID"
    }
    
    # Add to included items
    if ($shouldInclude) {
        if (-not $includedItems.ContainsKey($creatureId)) {
            $includedItems[$creatureId] = @()
        }
        $includedItems[$creatureId] += $itemId
        $stats.Included++
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FILTERING RESULTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Total items scanned: $($stats.Total)" -ForegroundColor White
Write-Host ""

Write-Host "INCLUDED ITEMS: $($stats.Included)" -ForegroundColor Green
Write-Host "  Confirmed drops (has 'drop'/'chance'): $($stats.ConfirmedDrops)" -ForegroundColor Cyan
Write-Host "  Potential drops (has creature, needs verification): $($stats.PotentialDrops)" -ForegroundColor Yellow
Write-Host ""

Write-Host "EXCLUDED ITEMS: $($stats.Total - $stats.Included)" -ForegroundColor Red
Write-Host "  Explicitly excluded (vendor/webstore/etc): $($stats.ExplicitlyExcluded)" -ForegroundColor Magenta
Write-Host "  No creature ID: $($stats.NoCreature)" -ForegroundColor Gray
Write-Host ""

$uniqueCreatures = $includedItems.Count
Write-Host "Unique creatures in filtered set: $uniqueCreatures" -ForegroundColor Green
Write-Host ""

# Compare with current VanityDB if it exists
if (Test-Path $VanityDBPath) {
    Write-Host "Comparing with current VanityDB..." -ForegroundColor Yellow
    $vanityDBContent = Get-Content $VanityDBPath -Raw
    
    # Parse current VanityDB - extract creature-to-item mappings
    $dbItems = @{}
    $dbPattern = 'itemid\s*=\s*(\d+),.*?creaturePreview\s*=\s*(\d+)'
    $dbMatches = [regex]::Matches($vanityDBContent, $dbPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    foreach ($match in $dbMatches) {
        $itemId = [int]$match.Groups[1].Value
        $creatureId = [int]$match.Groups[2].Value
        
        if ($creatureId -gt 0) {
            if (-not $dbItems.ContainsKey($creatureId)) {
                $dbItems[$creatureId] = @()
            }
            $dbItems[$creatureId] += $itemId
        }
    }
    
    Write-Host "Current DB entries: $($dbItems.Count) creatures" -ForegroundColor Green
    Write-Host ""
    
    # Analysis
    $matchCount = 0
    $mismatches = @()
    $apiOnly = @()
    $dbOnly = @()
    
    # Check API items against DB
    foreach ($creatureId in $includedItems.Keys) {
        if ($dbItems.ContainsKey($creatureId)) {
            $apiItemIds = $includedItems[$creatureId]
            $dbItemIds = $dbItems[$creatureId]
            
            # Check if there's any overlap
            $hasMatch = $false
            foreach ($apiItem in $apiItemIds) {
                if ($dbItemIds -contains $apiItem) {
                    $hasMatch = $true
                    break
                }
            }
            
            if ($hasMatch) {
                $matchCount++
            } else {
                $mismatches += @{
                    CreatureId = $creatureId
                    APIItems = $apiItemIds
                    DBItems = $dbItemIds
                }
            }
        } else {
            $apiOnly += @{
                CreatureId = $creatureId
                Items = $includedItems[$creatureId]
            }
        }
    }
    
    # Check DB items not in API
    foreach ($creatureId in $dbItems.Keys) {
        if (-not $includedItems.ContainsKey($creatureId)) {
            $dbOnly += @{
                CreatureId = $creatureId
                Items = $dbItems[$creatureId]
            }
        }
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "DATABASE COMPARISON" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Exact matches: $matchCount" -ForegroundColor Green
    Write-Host "Mismatches (different items): $($mismatches.Count)" -ForegroundColor Yellow
    Write-Host "In API only (NEW creatures): $($apiOnly.Count)" -ForegroundColor Cyan
    Write-Host "In DB only (NOT in filtered API): $($dbOnly.Count)" -ForegroundColor Magenta
    Write-Host ""
}

# Show items needing verification
if ($emptyDescriptionItems.Count -gt 0) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "ITEMS NEEDING WEB VERIFICATION (First 10)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "These items have creature IDs but no/minimal description." -ForegroundColor Yellow
    Write-Host "They may be drops that need manual verification." -ForegroundColor Yellow
    Write-Host ""
    
    $count = 0
    foreach ($item in $emptyDescriptionItems) {
        if ($count -ge 10) { break }
        Write-Host "Item $($item.ItemId) - '$($item.Name)'" -ForegroundColor Yellow
        Write-Host "  Creature: $($item.CreatureId)" -ForegroundColor Gray
        Write-Host "  Description: '$($item.Description)'" -ForegroundColor Gray
        Write-Host ""
        $count++
    }
    
    if ($emptyDescriptionItems.Count -gt 10) {
        Write-Host "... and $($emptyDescriptionItems.Count - 10) more items needing verification" -ForegroundColor Gray
    }
    Write-Host ""
}

# Generate detailed report if requested
if ($Detailed) {
    $reportPath = ".\API_Analysis\Filtered_Scan_Report_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').txt"
    
    Write-Host "Generating detailed report..." -ForegroundColor Yellow
    
    if (-not (Test-Path ".\API_Analysis")) {
        New-Item -ItemType Directory -Path ".\API_Analysis" | Out-Null
    }
    
    $report = @"
SMART DROP-BASED FILTER ANALYSIS
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================

FILTERING SUMMARY
- Total items scanned: $($stats.Total)
- Included items: $($stats.Included)
- Confirmed drops: $($stats.ConfirmedDrops)
- Potential drops: $($stats.PotentialDrops)
- Excluded items: $($stats.ExplicitlyExcluded)
- No creature ID: $($stats.NoCreature)
- Unique creatures: $uniqueCreatures

FILTERING RULES
1. Include if description contains "drop" or "chance"
2. Exclude if description contains webstore/vendor/quest/achievement
3. Include if has creature ID with empty/minimal description (needs verification)
4. Include if has creature ID with non-exclusion description
5. Exclude if no creature ID

========================================
DATABASE COMPARISON
========================================

"@
    
    if (Test-Path $VanityDBPath) {
        $report += @"
- Current DB entries: $($dbItems.Count)
- Exact matches: $matchCount
- Mismatches: $($mismatches.Count)
- NEW creatures (in API only): $($apiOnly.Count)
- Only in DB (not in filtered API): $($dbOnly.Count)

"@
        
        $report += @"
========================================
NEW CREATURES ($($apiOnly.Count) total)
========================================

"@
        foreach ($entry in $apiOnly) {
            $itemsList = $entry.Items -join ', '
            $report += "Creature $($entry.CreatureId): Items [$itemsList]`n"
        }
        
        $report += @"

========================================
MISMATCHES ($($mismatches.Count) total)
========================================

"@
        foreach ($entry in $mismatches) {
            $apiItemsList = $entry.APIItems -join ', '
            $dbItemsList = $entry.DBItems -join ', '
            $report += "Creature $($entry.CreatureId):`n"
            $report += "  API: [$apiItemsList]`n"
            $report += "  DB:  [$dbItemsList]`n`n"
        }
    }
    
    $report += @"

========================================
ITEMS NEEDING VERIFICATION ($($emptyDescriptionItems.Count) total)
========================================

"@
    foreach ($item in $emptyDescriptionItems) {
        $report += "Item $($item.ItemId) - '$($item.Name)'`n"
        $report += "  Creature: $($item.CreatureId)`n"
        $report += "  Description: '$($item.Description)'`n`n"
    }
    
    $report += @"

========================================
EXCLUDED ITEMS (First 100)
========================================

"@
    $count = 0
    foreach ($item in $excludedItems) {
        if ($count -ge 100) { break }
        $report += "Item $($item.ItemId) - '$($item.Name)'`n"
        $report += "  Reason: $($item.Reason)`n"
        $report += "  Description: $($item.Description)`n`n"
        $count++
    }
    
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host "Detailed report saved to: $reportPath" -ForegroundColor Green
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Review items needing verification above" -ForegroundColor White
Write-Host "2. Run with -Detailed for full report" -ForegroundColor White
Write-Host "3. Generate new VanityDB from filtered data" -ForegroundColor White
Write-Host "4. Use web lookup for items with empty descriptions" -ForegroundColor White
Write-Host ""
