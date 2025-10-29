# Master Description Enrichment Script
# Comprehensive automation for enriching VanityDB descriptions
# Combines all enrichment strategies into a single workflow

#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$WhatIf,
    
    [Parameter()]
    [int]$RateLimitSeconds = 2
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Web

# Configuration
$vanityDbPath = "AscensionVanity\VanityDB.lua"
$outputDir = "data"
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"

Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        Master Description Enrichment - VanityDB.lua           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# PHASE 1: ANALYZE - Find items needing enrichment
# ==============================================================================

Write-Host "[PHASE 1] Analyzing VanityDB.lua for empty descriptions..." -ForegroundColor Yellow
Write-Host ""

$content = Get-Content $vanityDbPath -Raw -Encoding UTF8

# Extract all items with empty descriptions
$pattern = '\[(\d+)\]\s*=\s*\{[^\}]*?\["name"\]\s*=\s*"([^"]+)"[^\}]*?\["creaturePreview"\]\s*=\s*(\d+)[^\}]*?\["description"\]\s*=\s*""'
$emptyItems = [regex]::Matches($content, $pattern)

Write-Host "  Found $($emptyItems.Count) items with empty descriptions" -ForegroundColor White
Write-Host ""

if ($emptyItems.Count -eq 0) {
    Write-Host "✓ All items already have descriptions!" -ForegroundColor Green
    Write-Host ""
    exit 0
}

# Parse items
$itemsToEnrich = @()
foreach ($match in $emptyItems) {
    $itemId = $match.Groups[1].Value
    $fullName = $match.Groups[2].Value
    $creatureId = $match.Groups[3].Value
    
    # Extract NPC name from full name (after the prefix)
    $npcName = if ($fullName -match ':\s*(.+)$') { $matches[1] } else { $fullName }
    
    $itemsToEnrich += [PSCustomObject]@{
        ItemId = $itemId
        FullName = $fullName
        NPCName = $npcName
        CreatureId = $creatureId
        Zone = $null
        Source = $null
    }
}

Write-Host "  Items to process:" -ForegroundColor Gray
$itemsToEnrich | Format-Table -Property ItemId, NPCName, CreatureId -AutoSize | Out-String | Write-Host -ForegroundColor DarkGray

# ==============================================================================
# PHASE 2: SEARCH - Query databases for zone information
# ==============================================================================

Write-Host "[PHASE 2] Searching for zone locations..." -ForegroundColor Yellow
Write-Host ""

$foundCount = 0
$notFoundCount = 0
$errorCount = 0

foreach ($item in $itemsToEnrich) {
    $index = $itemsToEnrich.IndexOf($item) + 1
    Write-Host "  [$index/$($itemsToEnrich.Count)] $($item.NPCName) (Creature $($item.CreatureId))" -ForegroundColor White
    
    $zone = $null
    $source = $null
    
    # Strategy 1: Try db.ascension.gg first (most reliable for Ascension)
    $ascensionUrl = "https://db.ascension.gg/?npc=$($item.CreatureId)"
    Write-Host "    → Checking db.ascension.gg..." -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $ascensionUrl -UseBasicParsing -TimeoutSec 15
        $pageContent = $response.Content
        
        # Pattern 1: "This NPC can be found in [Zone]"
        if ($pageContent -match 'This NPC can be found in\s+<a[^>]*>([^<]+)</a>') {
            $zone = $matches[1].Trim()
            $source = "db.ascension.gg"
        }
        # Pattern 2: Look for zone in listview (creature drops)
        elseif ($pageContent -match '<div class="listview-mode-default">.*?<a[^>]*zone=(\d+)[^>]*>([^<]+)</a>') {
            $zone = $matches[2].Trim()
            $source = "db.ascension.gg (drops)"
        }
        
        if ($zone) {
            Write-Host "    ✓ Found: $zone" -ForegroundColor Green
            $foundCount++
        }
    }
    catch {
        Write-Host "    ⚠ Error: $($_.Exception.Message)" -ForegroundColor DarkYellow
        $errorCount++
    }
    
    # Strategy 2: Fallback to Wowhead WOTLK if not found
    if (-not $zone) {
        $wowheadUrl = "https://www.wowhead.com/wotlk/npc=$($item.CreatureId)"
        Write-Host "    → Checking Wowhead WOTLK..." -ForegroundColor Gray
        
        try {
            $response = Invoke-WebRequest -Uri $wowheadUrl -UseBasicParsing -TimeoutSec 15
            $pageContent = $response.Content
            
            # Pattern 1: JavaScript WH.setSelectedLink (most common on WOTLK pages)
            if ($pageContent -match 'WH\.setSelectedLink[^>]*>([^<]+)</a>') {
                $zone = $matches[1].Trim()
                $source = "Wowhead WOTLK (JS)"
            }
            # Pattern 2: "This NPC can be found in" direct link
            elseif ($pageContent -match 'This NPC can be found in\s+<a[^>]*>([^<]+)</a>') {
                $zone = $matches[1].Trim()
                $source = "Wowhead WOTLK"
            }
            # Pattern 3: Plain text fallback
            elseif ($pageContent -match 'This NPC can be found in\s+([A-Z][^<\.\(]{2,}?)(?=\s*[\.<]|$)') {
                $zone = $matches[1].Trim()
                $source = "Wowhead WOTLK (text)"
            }
            
            if ($zone) {
                Write-Host "    ✓ Found: $zone" -ForegroundColor Green
                $foundCount++
            }
        }
        catch {
            Write-Host "    ⚠ Error: $($_.Exception.Message)" -ForegroundColor DarkYellow
            $errorCount++
        }
    }
    
    # Update item
    if ($zone) {
        $item.Zone = $zone
        $item.Source = $source
    } else {
        Write-Host "    ✗ NOT FOUND" -ForegroundColor Red
        $notFoundCount++
    }
    
    # Rate limiting
    if ($index -lt $itemsToEnrich.Count) {
        Start-Sleep -Seconds $RateLimitSeconds
    }
}

Write-Host ""
Write-Host "  Search Results:" -ForegroundColor White
Write-Host "    Found:     $foundCount / $($itemsToEnrich.Count)" -ForegroundColor Green
Write-Host "    Not Found: $notFoundCount" -ForegroundColor Yellow
Write-Host "    Errors:    $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Gray" })
Write-Host ""

# ==============================================================================
# PHASE 3: APPLY - Update VanityDB.lua with enrichments
# ==============================================================================

$successfulEnrichments = $itemsToEnrich | Where-Object { $_.Zone }

if ($successfulEnrichments.Count -eq 0) {
    Write-Host "[PHASE 3] No enrichments to apply" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "[PHASE 3] Applying $($successfulEnrichments.Count) enrichments to VanityDB.lua..." -ForegroundColor Yellow
    Write-Host ""
    
    $updatedCount = 0
    $failedCount = 0
    $updatedContent = $content
    
    foreach ($item in $successfulEnrichments) {
        $description = "Has a chance to drop from $($item.NPCName) within $($item.Zone)"
        
        # Pattern to find and replace empty description
        $findPattern = "(\[$($item.ItemId)\]\s*=\s*\{[^\}]*\[`"description`"\]\s*=\s*)`"`""
        
        if ($updatedContent -match $findPattern) {
            $updatedContent = $updatedContent -replace $findPattern, "`$1`"$description`""
            $updatedCount++
            Write-Host "  ✓ Updated: $($item.NPCName) → $($item.Zone)" -ForegroundColor Green
        } else {
            $failedCount++
            Write-Host "  ✗ Failed: $($item.NPCName) (pattern not found)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "  Applied: $updatedCount / $($successfulEnrichments.Count) enrichments" -ForegroundColor Green
    
    if ($failedCount -gt 0) {
        Write-Host "  Failed:  $failedCount (pattern matching issues)" -ForegroundColor Yellow
    }
    
    # Save changes
    if ($updatedCount -gt 0 -and -not $WhatIf) {
        Write-Host ""
        Write-Host "  Saving changes to $vanityDbPath..." -ForegroundColor Cyan
        $updatedContent | Set-Content $vanityDbPath -Encoding UTF8 -NoNewline
        Write-Host "  ✓ File saved successfully" -ForegroundColor Green
    } elseif ($WhatIf) {
        Write-Host ""
        Write-Host "  [WHATIF] Changes not saved (dry run mode)" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# ==============================================================================
# PHASE 4: REPORT - Generate summary and export data
# ==============================================================================

Write-Host "[PHASE 4] Generating reports..." -ForegroundColor Yellow
Write-Host ""

# Export full results to CSV
$csvPath = Join-Path $outputDir "Enrichment_Results_$timestamp.csv"
$itemsToEnrich | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "  ✓ Results exported to: $csvPath" -ForegroundColor Cyan

# Export successful enrichments to JSON
if ($successfulEnrichments.Count -gt 0) {
    $enrichmentData = $successfulEnrichments | ForEach-Object {
        [PSCustomObject]@{
            ItemId = $_.ItemId
            CreatureId = $_.CreatureId
            NPCName = $_.NPCName
            Zone = $_.Zone
            Source = $_.Source
            Description = "Has a chance to drop from $($_.NPCName) within $($_.Zone)"
        }
    }
    
    $jsonPath = Join-Path $outputDir "Enrichment_Data_$timestamp.json"
    $enrichmentData | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8
    Write-Host "  ✓ Enrichment data exported to: $jsonPath" -ForegroundColor Cyan
}

# Items needing manual research
$needsManualResearch = $itemsToEnrich | Where-Object { -not $_.Zone }

if ($needsManualResearch.Count -gt 0) {
    $manualPath = Join-Path $outputDir "Manual_Research_Needed_$timestamp.txt"
    $manualReport = @"
Items Needing Manual Research
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Total: $($needsManualResearch.Count)

These NPCs could not be found in db.ascension.gg or Wowhead WOTLK.
They may be:
- Ascension-specific NPCs
- Special spawn mechanics (prisons, events)
- Rewards/promos/not yet implemented
- Require in-game verification

Items:
$(($needsManualResearch | ForEach-Object { "  - $($_.NPCName) (Creature $($_.CreatureId), Item $($_.ItemId))" }) -join "`n")
"@
    
    $manualReport | Set-Content -Path $manualPath -Encoding UTF8
    Write-Host "  ✓ Manual research list: $manualPath" -ForegroundColor Yellow
}

# Final statistics
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                      FINAL STATISTICS                          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$remainingEmpty = ([regex]::Matches($updatedContent, '\["description"\]\s*=\s*""')).Count
$totalItems = 2174  # Update this if total changes
$withDescriptions = $totalItems - $remainingEmpty
$completionPercent = [math]::Round(($withDescriptions / $totalItems) * 100, 2)

Write-Host "  Total Vanity Items:      $totalItems" -ForegroundColor White
Write-Host "  Items with Descriptions: $withDescriptions ($completionPercent%)" -ForegroundColor Green
Write-Host "  Empty Descriptions:      $remainingEmpty" -ForegroundColor $(if ($remainingEmpty -eq 0) { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "  This Run:" -ForegroundColor White
Write-Host "    Searched:              $($itemsToEnrich.Count)" -ForegroundColor Gray
Write-Host "    Found Automatically:   $foundCount" -ForegroundColor Green
Write-Host "    Applied to Database:   $updatedCount" -ForegroundColor Green
Write-Host "    Need Manual Research:  $($needsManualResearch.Count)" -ForegroundColor Yellow
Write-Host ""

if ($remainingEmpty -eq 0) {
    Write-Host "  🎉 DATABASE 100% COMPLETE! 🎉" -ForegroundColor Green
} elseif ($completionPercent -ge 99) {
    Write-Host "  ⭐ DATABASE $completionPercent% COMPLETE - EXCELLENT! ⭐" -ForegroundColor Green
} elseif ($completionPercent -ge 95) {
    Write-Host "  ✓ DATABASE $completionPercent% COMPLETE - GOOD PROGRESS" -ForegroundColor Cyan
} else {
    Write-Host "  → DATABASE $completionPercent% COMPLETE - MORE WORK NEEDED" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    ENRICHMENT COMPLETE                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
