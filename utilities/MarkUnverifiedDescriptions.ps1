<#
.SYNOPSIS
    Mark descriptions that differ from original game data as [Unverified]

.DESCRIPTION
    Compares current MasterFullValidated.json descriptions against the original
    fresh scan from game data. Any description that has been modified, added, or
    differs from the original gets marked with "|cFFFF8800[Unverified]|r " prefix.

.EXAMPLE
    .\utilities\MarkUnverifiedDescriptions.ps1

.NOTES
    Author: GitHub Copilot
    Date: 2025-11-14
    This adds transparency about which drop locations are confirmed vs. inferred.
#>

[CmdletBinding()]
param(
    [string]$FreshScanPath = ".\data\archive\scans_2025-11-07\AscensionVanity_Fresh_Scan_2025-11-07_162557.lua",
    [string]$MasterJsonPath = ".\data\MasterFullValidated.json",
    [string]$OutputPath = ".\data\MasterFullValidated_Verified.json",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "Mark Unverified Descriptions" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan

# Load fresh scan and extract original descriptions
Write-Host "[1/4] Loading fresh scan..." -ForegroundColor Yellow
if (-not (Test-Path $FreshScanPath)) {
    throw "Fresh scan not found: $FreshScanPath"
}

$scanContent = Get-Content $FreshScanPath -Raw
$originalDescriptions = @{}

# Parse scan file for item descriptions
# Match format: [80834] = { ["itemid"] = 80834, ["description"] = "..." }
# Only match items that have a description field (not all fields)
$pattern = '\[(\d+)\]\s*=\s*\{[^\}]*?\["description"\]\s*=\s*"((?:[^"\\]|\\.)*)"'
$matches = [regex]::Matches($scanContent, $pattern)

foreach ($match in $matches) {
    $itemId = [int]$match.Groups[1].Value
    $description = $match.Groups[2].Value
    
    # Unescape Lua strings (quotes)
    $description = $description -replace '\\"', '"'
    
    $originalDescriptions[$itemId] = $description
}

Write-Host "  Found $($originalDescriptions.Count) original descriptions" -ForegroundColor Gray

# Load current master JSON
Write-Host "[2/4] Loading current master JSON..." -ForegroundColor Yellow
if (-not (Test-Path $MasterJsonPath)) {
    throw "Master JSON not found: $MasterJsonPath"
}

$masterData = Get-Content $MasterJsonPath -Raw | ConvertFrom-Json
Write-Host "  Loaded $($masterData.Count) items" -ForegroundColor Gray

# Compare and mark unverified
Write-Host "[3/4] Comparing descriptions..." -ForegroundColor Yellow

$verified = 0
$unverified = 0
$missing = 0
$minorEdit = 0
$alreadyMarked = 0

$itemNumber = 0
foreach ($item in $masterData) {
    $itemNumber++
    $itemId = [int]$item.DbItemId  # Cast to Int32 for hashtable lookup
    $currentDesc = $item.Description
    
    # Skip if already marked
    if ($currentDesc -match '^\|cFFFF8800\[Unverified\]') {
        $alreadyMarked++
        continue
    }
    
    $originalDesc = $originalDescriptions[$itemId]
    
    if (-not $originalDesc -or $originalDesc -eq '') {
        # Item not in original scan (manually added)
        $item.Description = "|cFFFF8800[Unverified]|r " + $currentDesc
        $unverified++
        Write-Verbose "  Item $itemId - Not in original scan (manually added)"
    }
    elseif ([string]::IsNullOrWhiteSpace($originalDesc)) {
        # Original description was empty - you added it
        $item.Description = "|cFFFF8800[Unverified]|r " + $currentDesc
        $unverified++
        Write-Verbose "  Item $itemId - Empty in original, description added"
    }
    elseif ($originalDesc -ne $currentDesc) {
        # Description was modified - determine if it's significant
        
        # Normalize both for comparison (remove punctuation, trim whitespace)
        $origNorm = $originalDesc.Trim().TrimEnd('.', '!', '?')
        $currNorm = $currentDesc.Trim().TrimEnd('.', '!', '?')
        
        if ($origNorm -eq $currNorm) {
            # Only punctuation changed - this is OK
            $verified++
            $minorEdit++
        }
        else {
            # Extract location names from both descriptions
            # Pattern: "from X within Y" or "from X in Y"
            $origLocation = ''
            $currLocation = ''
            
            if ($origNorm -match 'from\s+(.+?)\s+(?:within|in)\s+(.+?)$') {
                $origLocation = $Matches[2].Trim()
            }
            if ($currNorm -match 'from\s+(.+?)\s+(?:within|in)\s+(.+?)$') {
                $currLocation = $Matches[2].Trim()
            }
            
            # Check if locations are completely different (not just zone vs subzone)
            # Allow if one is a substring of the other (zone/subzone relationship)
            $locationChanged = ($origLocation -and $currLocation -and 
                                -not $origLocation.Contains($currLocation) -and 
                                -not $currLocation.Contains($origLocation))
            
            if ($locationChanged) {
                # Location completely changed - mark as unverified
                $item.Description = "|cFFFF8800[Unverified]|r " + $currentDesc
                $unverified++
                Write-Verbose "  Item $itemId - Location changed significantly"
                Write-Verbose "    Original: $originalDesc"
                Write-Verbose "    Current:  $currentDesc"
            }
            else {
                # Minor edit (zone/subzone swap or creature name fix) - OK
                $verified++
                $minorEdit++
            }
        }
    }
    else {
        # Description matches original scan exactly - verified!
        $verified++
    }
}

Write-Host "`n  Results:" -ForegroundColor Cyan
Write-Host "    Verified (match original):     $verified" -ForegroundColor Green
Write-Host "    Minor edits (punctuation/swap): $minorEdit" -ForegroundColor Cyan
Write-Host "    Unverified (modified/added):    $unverified" -ForegroundColor Yellow
Write-Host "    Already marked:                 $alreadyMarked" -ForegroundColor Gray

# Save output
if ($DryRun) {
    Write-Host "`n[DRY RUN] Would save to: $OutputPath" -ForegroundColor Yellow
} else {
    Write-Host "[4/4] Saving updated JSON..." -ForegroundColor Yellow
    $masterData | ConvertTo-Json -Depth 10 -Compress | Set-Content $OutputPath -Encoding UTF8
    Write-Host "  Saved to: $OutputPath" -ForegroundColor Green
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Review the marked items: $OutputPath" -ForegroundColor White
    Write-Host "  2. If satisfied, replace MasterFullValidated.json:" -ForegroundColor White
    Write-Host "     Copy-Item '$OutputPath' '$MasterJsonPath' -Force" -ForegroundColor Gray
    Write-Host "  3. Regenerate VanityDB.lua:" -ForegroundColor White
    Write-Host "     .\utilities\GenerateVanityDB_Master.ps1" -ForegroundColor Gray
    Write-Host "  4. Deploy to game:" -ForegroundColor White
    Write-Host "     .\DeployAddon.ps1" -ForegroundColor Gray
}

Write-Host "`nDone!" -ForegroundColor Green
