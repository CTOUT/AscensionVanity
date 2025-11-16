<#
.SYNOPSIS
    Validates VanityDB.lua before deployment - ensures data quality and detects regressions

.DESCRIPTION
    Compares old and new VanityDB.lua files to ensure:
    - Item counts are stable (no unexpected drops)
    - Enrichment coverage maintained or improved
    - No data quality issues (empty fields, invalid IDs)
    - Changes are documented (added/removed/modified items)
    
    Designed to catch issues BEFORE deployment to prevent bad data in production.

.PARAMETER OldDB
    Path to currently deployed VanityDB.lua (baseline)

.PARAMETER NewDB
    Path to newly generated VanityDB.lua (candidate for deployment)

.PARAMETER FailOnWarnings
    Treat warnings as errors (exit code 1)

.PARAMETER ShowDiff
    Display detailed diff of changes

.EXAMPLE
    .\utilities\ValidateVanityDB.ps1 -OldDB ".\AscensionVanity\VanityDB.lua" -NewDB ".\AscensionVanity\VanityDB_NEW.lua"
    
.EXAMPLE
    .\utilities\ValidateVanityDB.ps1 -OldDB ".\AscensionVanity\VanityDB.lua" -NewDB ".\AscensionVanity\VanityDB_NEW.lua" -ShowDiff

.NOTES
    Author: CMTout & GitHub Copilot
    Version: 1.0
    Last Updated: 2025-11-12
    Exit Codes:
      0 = Pass
      1 = Fail (critical issues)
      2 = Warning (non-critical issues)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$OldDB,
    
    [Parameter(Mandatory=$true)]
    [string]$NewDB,
    
    [switch]$FailOnWarnings,
    [switch]$ShowDiff
)

$ErrorActionPreference = "Stop"

# ============================================================================
# HELPERS
# ============================================================================

function Write-Header {
    param([string]$Text)
    $border = "=" * 80
    Write-Host ""
    Write-Host $border -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host $border -ForegroundColor Cyan
    Write-Host ""
}

function Write-Check {
    param([string]$Name, [string]$Status, [string]$Detail)
    
    $icon = switch ($Status) {
        "PASS" { "✓"; $color = "Green" }
        "WARN" { "⚠"; $color = "Yellow" }
        "FAIL" { "✗"; $color = "Red" }
        "INFO" { "ℹ"; $color = "Cyan" }
    }
    
    Write-Host "  $icon " -ForegroundColor $color -NoNewline
    Write-Host "$Name" -NoNewline
    if ($Detail) {
        Write-Host ": $Detail" -ForegroundColor Gray
    } else {
        Write-Host ""
    }
}

# ============================================================================
# PARSING
# ============================================================================

function Parse-VanityDB {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        throw "File not found: $Path"
    }
    
    $content = Get-Content -Path $Path -Raw
    
    # Extract AV_VanityItems table
    if ($content -match 'AV_VanityItems\s*=\s*\{([\s\S]*?)\n\}(?:\s*AV_IconList|\s*$)') {
        $itemsContent = $matches[1]
    } else {
        throw "Could not parse AV_VanityItems from $Path"
    }
    
    # Extract AV_IconList
    $iconCount = 0
    if ($content -match 'AV_IconList\s*=\s*\{([\s\S]*?)\n\}') {
        $iconListContent = $matches[1]
        $iconCount = ([regex]::Matches($iconListContent, '\[(\d+)\]')).Count
    }
    
    # Parse items (simple counting approach - not full Lua parsing)
    $items = @{}
    $categories = @{
        "Beastmaster's Whistle" = 0
        "Blood Soaked Vellum" = 0
        "Summoner's Stone" = 0
        "Draconic Warhorn" = 0
        "Elemental Lodestone" = 0
    }
    
    # Count items per creature
    $creatureMatches = [regex]::Matches($itemsContent, '\[(\d+)\]\s*=\s*\{')
    $totalItems = $creatureMatches.Count
    
    # Count categories (approximate by looking for category strings)
    $categoryKeys = @($categories.Keys)  # Create array copy to avoid modification during enumeration
    foreach ($cat in $categoryKeys) {
        $categories[$cat] = ([regex]::Matches($itemsContent, [regex]::Escape($cat))).Count
    }
    
    # Count enrichments (count items that have each field, not total field occurrences)
    $itemBlocks = [regex]::Matches($itemsContent, '\[(\d+)\]\s*=\s*\{([^}]+)\}')
    $descCount = 0
    $emptyDescCount = 0
    $zoneCount = 0
    $subzoneCount = 0
    $questLockCount = 0
    
    foreach ($block in $itemBlocks) {
        $blockContent = $block.Groups[2].Value
        # Count descriptions with content
        if ($blockContent -match 'description\s*=\s*"[^"]+') { $descCount++ }
        # Count empty descriptions (NEW - critical validation!)
        if ($blockContent -match 'description\s*=\s*""') { $emptyDescCount++ }
        if ($blockContent -match 'zone\s*=') { $zoneCount++ }
        if ($blockContent -match 'subzone\s*=') { $subzoneCount++ }
        if ($blockContent -match 'questLock\s*=') { $questLockCount++ }
    }
    
    return @{
        Path = $Path
        TotalItems = $totalItems
        Categories = $categories
        IconCount = $iconCount
        DescriptionCount = $descCount
        EmptyDescriptionCount = $emptyDescCount
        ZoneCount = $zoneCount
        SubzoneCount = $subzoneCount
        QuestLockCount = $questLockCount
        Content = $content
    }
}

# ============================================================================
# VALIDATION CHECKS
# ============================================================================

function Test-ItemCount {
    param($Old, $New)
    
    $diff = $New.TotalItems - $Old.TotalItems
    $diffPercent = if ($Old.TotalItems -gt 0) { ($diff / $Old.TotalItems) * 100 } else { 0 }
    
    if ($diff -eq 0) {
        Write-Check "Item Count" "PASS" "$($New.TotalItems) items (no change)"
        return "PASS"
    } elseif ($diff -gt 0) {
        Write-Check "Item Count" "INFO" "$($Old.TotalItems) → $($New.TotalItems) (+$diff items)"
        return "PASS"
    } elseif ($diffPercent -le -10) {
        Write-Check "Item Count" "FAIL" "$($Old.TotalItems) → $($New.TotalItems) ($diff items, $($diffPercent.ToString('0.0'))% drop)"
        return "FAIL"
    } elseif ($diffPercent -le -5) {
        Write-Check "Item Count" "WARN" "$($Old.TotalItems) → $($New.TotalItems) ($diff items, $($diffPercent.ToString('0.0'))% drop)"
        return "WARN"
    } else {
        Write-Check "Item Count" "INFO" "$($Old.TotalItems) → $($New.TotalItems) ($diff items)"
        return "PASS"
    }
}

function Test-Categories {
    param($Old, $New)
    
    $allGood = $true
    $categoryKeys = @($Old.Categories.Keys)  # Create array copy to avoid modification during enumeration
    foreach ($cat in $categoryKeys) {
        $oldCount = $Old.Categories[$cat]
        $newCount = $New.Categories[$cat]
        $diff = $newCount - $oldCount
        
        if ($diff -lt 0) {
            $diffPercent = ($diff / $oldCount) * 100
            if ($diffPercent -le -10) {
                Write-Check "Category: $cat" "FAIL" "$oldCount → $newCount ($diff items)"
                $allGood = $false
            } elseif ($diffPercent -le -5) {
                Write-Check "Category: $cat" "WARN" "$oldCount → $newCount ($diff items)"
            }
        }
    }
    
    if ($allGood) {
        Write-Check "Categories" "PASS" "All categories stable or growing"
        return "PASS"
    } else {
        return "FAIL"
    }
}

function Test-EnrichmentCoverage {
    param($Old, $New)
    
    $results = @()
    
    # Description coverage
    $oldDescPercent = ($Old.DescriptionCount / $Old.TotalItems) * 100
    $newDescPercent = ($New.DescriptionCount / $New.TotalItems) * 100
    
    # Report empty descriptions (CRITICAL - catches missing enrichment)
    if ($New.EmptyDescriptionCount -gt 0) {
        $emptyPercent = ($New.EmptyDescriptionCount / $New.TotalItems) * 100
        if ($emptyPercent -le 1) {
            Write-Check "Empty Descriptions" "PASS" "$($New.EmptyDescriptionCount) items ($($emptyPercent.ToString('0.00'))%)"
            $results += "PASS"
        } elseif ($emptyPercent -le 5) {
            Write-Check "Empty Descriptions" "WARN" "$($New.EmptyDescriptionCount) items ($($emptyPercent.ToString('0.00'))%) - enrichment needed"
            $results += "WARN"
        } else {
            Write-Check "Empty Descriptions" "FAIL" "$($New.EmptyDescriptionCount) items ($($emptyPercent.ToString('0.00'))%) - critical enrichment gap!"
            $results += "FAIL"
        }
    } else {
        Write-Check "Empty Descriptions" "PASS" "None (100% coverage)"
        $results += "PASS"
    }
    
    # Overall description coverage percentage
    if ($newDescPercent -ge 99) {
        Write-Check "Description Coverage" "PASS" "$($newDescPercent.ToString('0.00'))% ($($New.DescriptionCount)/$($New.TotalItems))"
        $results += "PASS"
    } elseif ($newDescPercent -ge $oldDescPercent) {
        Write-Check "Description Coverage" "WARN" "$($newDescPercent.ToString('0.00'))% (was $($oldDescPercent.ToString('0.00'))%)"
        $results += "WARN"
    } else {
        Write-Check "Description Coverage" "FAIL" "$($newDescPercent.ToString('0.00'))% (regressed from $($oldDescPercent.ToString('0.00'))%)"
        $results += "FAIL"
    }
    
    # Zone coverage
    $oldZonePercent = ($Old.ZoneCount / $Old.TotalItems) * 100
    $newZonePercent = ($New.ZoneCount / $New.TotalItems) * 100
    
    if ($newZonePercent -ge $oldZonePercent) {
        Write-Check "Zone Enrichment" "PASS" "$($newZonePercent.ToString('0.0'))% ($($New.ZoneCount)/$($New.TotalItems))"
        $results += "PASS"
    } else {
        Write-Check "Zone Enrichment" "WARN" "$($newZonePercent.ToString('0.0'))% (was $($oldZonePercent.ToString('0.0'))%)"
        $results += "WARN"
    }
    
    # Quest locks
    if ($New.QuestLockCount -gt 0) {
        Write-Check "Quest Locks" "PASS" "$($New.QuestLockCount) items tracked"
        $results += "PASS"
    }
    
    # Overall
    if ($results -contains "FAIL") {
        return "FAIL"
    } elseif ($results -contains "WARN") {
        return "WARN"
    } else {
        return "PASS"
    }
}

function Test-DataQuality {
    param($New)
    
    # Check icon list size
    if ($New.IconCount -ge 14 -and $New.IconCount -le 20) {
        Write-Check "Icon List" "PASS" "$($New.IconCount) unique icons"
        $iconStatus = "PASS"
    } else {
        Write-Check "Icon List" "WARN" "$($New.IconCount) icons (expected 14-20)"
        $iconStatus = "WARN"
    }
    
    # Check for obvious syntax issues (very basic)
    if ($New.Content -match 'nil\s*=\s*nil' -or $New.Content -match '\[\s*\]') {
        Write-Check "Syntax" "FAIL" "Detected potential Lua syntax errors"
        return "FAIL"
    } else {
        Write-Check "Syntax" "PASS" "No obvious syntax errors detected"
    }
    
    return $iconStatus
}

# ============================================================================
# DIFF DETECTION
# ============================================================================

function Show-DetailedDiff {
    param($Old, $New)
    
    Write-Header "Detailed Change Report"
    
    # Extract item IDs from both (very simplified)
    $oldIds = [regex]::Matches($Old.Content, '\[(\d+)\]\s*=\s*\{') | ForEach-Object { $_.Groups[1].Value }
    $newIds = [regex]::Matches($New.Content, '\[(\d+)\]\s*=\s*\{') | ForEach-Object { $_.Groups[1].Value }
    
    $added = $newIds | Where-Object { $_ -notin $oldIds }
    $removed = $oldIds | Where-Object { $_ -notin $newIds }
    
    if ($added.Count -gt 0) {
        Write-Host "Items Added ($($added.Count)):" -ForegroundColor Green
        $added | Select-Object -First 10 | ForEach-Object { Write-Host "  + Item ID: $_" -ForegroundColor Green }
        if ($added.Count -gt 10) { Write-Host "  ... and $($added.Count - 10) more" -ForegroundColor Gray }
        Write-Host ""
    }
    
    if ($removed.Count -gt 0) {
        Write-Host "Items Removed ($($removed.Count)):" -ForegroundColor Red
        $removed | Select-Object -First 10 | ForEach-Object { Write-Host "  - Item ID: $_" -ForegroundColor Red }
        if ($removed.Count -gt 10) { Write-Host "  ... and $($removed.Count - 10) more" -ForegroundColor Gray }
        Write-Host ""
    }
    
    if ($added.Count -eq 0 -and $removed.Count -eq 0) {
        Write-Host "No items added or removed" -ForegroundColor Gray
        Write-Host ""
    }
}

# ============================================================================
# MAIN
# ============================================================================

Write-Header "VanityDB Validation Report"

try {
    # Parse both files
    Write-Host "Parsing old VanityDB: $OldDB" -ForegroundColor Gray
    $oldData = Parse-VanityDB -Path $OldDB
    
    Write-Host "Parsing new VanityDB: $NewDB" -ForegroundColor Gray
    $newData = Parse-VanityDB -Path $NewDB
    Write-Host ""
    
    # Run checks
    $results = @()
    
    Write-Host "Running validation checks..." -ForegroundColor Cyan
    Write-Host ""
    
    $results += Test-ItemCount -Old $oldData -New $newData
    $results += Test-Categories -Old $oldData -New $newData
    $results += Test-EnrichmentCoverage -Old $oldData -New $newData
    $results += Test-DataQuality -New $newData
    
    Write-Host ""
    
    # Show diff if requested
    if ($ShowDiff) {
        Show-DetailedDiff -Old $oldData -New $newData
    }
    
    # Final verdict
    Write-Header "Validation Result"
    
    if ($results -contains "FAIL") {
        Write-Host "  ✗ FAILED - Critical issues detected" -ForegroundColor Red
        Write-Host ""
        Write-Host "Deployment blocked. Review errors above and fix issues." -ForegroundColor Yellow
        exit 1
    } elseif ($results -contains "WARN") {
        Write-Host "  ⚠ PASSED WITH WARNINGS" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Non-critical issues detected. Review warnings above." -ForegroundColor Yellow
        
        if ($FailOnWarnings) {
            Write-Host "Deployment blocked due to -FailOnWarnings flag." -ForegroundColor Red
            exit 2
        } else {
            Write-Host "Deployment allowed but proceed with caution." -ForegroundColor Yellow
            exit 0
        }
    } else {
        Write-Host "  ✓ PASSED - All checks passed!" -ForegroundColor Green
        Write-Host ""
        Write-Host "VanityDB is ready for deployment." -ForegroundColor Green
        exit 0
    }
    
} catch {
    Write-Host ""
    Write-Host "Validation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
