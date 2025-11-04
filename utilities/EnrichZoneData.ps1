<#
.SYNOPSIS
    Extract zone/location data from existing item descriptions

.DESCRIPTION
    Parses descriptions like "Drops from X within Elwynn Forest" to extract
    zone and subzone information without requiring any API calls.
    
    WORKFLOW:
    1. Load MasterFullValidated.json (has descriptions)
    2. Parse descriptions for "within ZONE" or "in ZONE" patterns
    3. Populate zone/subzone fields
    4. Save enriched JSON
    
    NO API CALLS NEEDED: All data is already in descriptions!

.PARAMETER DryRun
    Test mode - show what would be done without making changes

.EXAMPLE
    .\EnrichZoneData.ps1
    Standard execution with rate limiting

.EXAMPLE
    .\EnrichZoneData.ps1 -DryRun
    Test mode (show changes without saving)

.NOTES
    Author: CMTout
    Last Updated: 2025-11-04
    Automation: 95% automated, 5% manual review for edge cases
#>

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Paths
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath
$dataPath = Join-Path $rootPath "data"
$masterJsonPath = Join-Path $dataPath "MasterFullValidated.json"
$outputPath = Join-Path $dataPath "MasterFullValidated_ZoneEnriched.json"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Zone Data Enrichment (from Descriptions)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN MODE] No changes will be saved" -ForegroundColor Yellow
    Write-Host ""
}

# Validate source file exists
if (-not (Test-Path $masterJsonPath)) {
    Write-Host "[ERROR] Source file not found: $masterJsonPath" -ForegroundColor Red
    exit 1
}

# Load source data
Write-Host "[1/3] Loading source data..." -ForegroundColor Green
$items = Get-Content $masterJsonPath -Raw | ConvertFrom-Json
Write-Host "  Loaded $($items.Count) items" -ForegroundColor Gray

# Parse descriptions for zone information
Write-Host ""
Write-Host "[2/3] Parsing descriptions for zone data..." -ForegroundColor Green

$enrichedCount = 0
$itemsProcessed = 0

foreach ($item in $items) {
    $itemsProcessed++
    
    # Progress
    if ($itemsProcessed % 100 -eq 0) {
        $percent = [math]::Round(($itemsProcessed / $items.Count) * 100, 1)
        Write-Progress -Activity "Parsing descriptions" -Status "Item $itemsProcessed/$($items.Count)" -PercentComplete $percent
    }
    
    if (-not $item.Description) {
        continue
    }
    
    $desc = $item.Description
    
    # Parse patterns:
    # "within Zone Name" or "in Zone Name" or "with Zone Name"
    # Examples:
    #   "Drops from X within Elwynn Forest"
    #   "Found in Desolace"
    #   "Spawns with Blackrock Depths"
    #   "within Sunwell Plateau." (with period)
    
    # Pattern 1: "within Zone" (handles periods, apostrophes, colons, etc.)
    if ($desc -match "within\s+([A-Za-z\s':` -]+?)[\.,!?]?\s*`$") {
        $location = $Matches[1].Trim()
        # Remove trailing punctuation that might have been captured
        $location = $location.TrimEnd('.', ',', '!', '?')
        
        # Check if it's a zone or subzone
        # Subzone indicators: Mine, Cave, Farm, Ruins, Den, Keep, Tower, Hold, Crater, Depths, Terrace, Plateau, Camp, Point, Base, Gate
        if ($location -match '(Mine|Cave|Farm|Ruins|Den|Keep|Tower|Hold|Crater|Depths|Terrace|Plateau|Camp|Point|Base|Gate)') {
            $item | Add-Member -NotePropertyName "subzone" -NotePropertyValue $location -Force
        } else {
            $item | Add-Member -NotePropertyName "zone" -NotePropertyValue $location -Force
        }
        
        $enrichedCount++
    }
    # Pattern 2: "with Zone" (for "with Blackrock Depths" style)
    elseif ($desc -match "\swith\s+([A-Za-z\s':` -]+?)[\.,!?]?\s*`$") {
        $location = $Matches[1].Trim()
        # Remove trailing punctuation that might have been captured
        $location = $location.TrimEnd('.', ',', '!', '?')
        
        if ($location -match '(Mine|Cave|Farm|Ruins|Den|Keep|Tower|Hold|Crater|Depths|Terrace|Plateau|Camp|Point|Base|Gate)') {
            $item | Add-Member -NotePropertyName "subzone" -NotePropertyValue $location -Force
        } else {
            $item | Add-Member -NotePropertyName "zone" -NotePropertyValue $location -Force
        }
        
        $enrichedCount++
    }
    # Pattern 3: "in Zone" (original pattern)
    elseif ($desc -match "\sin\s+([A-Za-z\s':` -]+?)[\.,!?]?\s*`$") {
        $location = $Matches[1].Trim()
        # Remove trailing punctuation that might have been captured
        $location = $location.TrimEnd('.', ',', '!', '?')
        
        if ($location -match '(Mine|Cave|Farm|Ruins|Den|Keep|Tower|Hold|Crater|Depths|Terrace|Plateau|Camp|Point|Base|Gate)') {
            $item | Add-Member -NotePropertyName "subzone" -NotePropertyValue $location -Force
        } else {
            $item | Add-Member -NotePropertyName "zone" -NotePropertyValue $location -Force
        }
        
        $enrichedCount++
    }
}

Write-Progress -Activity "Parsing descriptions" -Completed

Write-Host "  Enriched $enrichedCount items with zone data" -ForegroundColor Gray

# Generate statistics
Write-Host ""
Write-Host "[3/3] Generating statistics..." -ForegroundColor Green

$zoneStats = @{}
$subzoneStats = @{}

foreach ($item in $items) {
    if ($item.zone) {
        if (-not $zoneStats.ContainsKey($item.zone)) {
            $zoneStats[$item.zone] = 0
        }
        $zoneStats[$item.zone]++
    }
    
    if ($item.subzone) {
        if (-not $subzoneStats.ContainsKey($item.subzone)) {
            $subzoneStats[$item.subzone] = 0
        }
        $subzoneStats[$item.subzone]++
    }
}

Write-Host "  Top Zones:" -ForegroundColor Cyan
$topZones = $zoneStats.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15
foreach ($zone in $topZones) {
    Write-Host "    $($zone.Key): $($zone.Value) items" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  Top Subzones:" -ForegroundColor Cyan
$topSubzones = $subzoneStats.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10
foreach ($subzone in $topSubzones) {
    Write-Host "    $($subzone.Key): $($subzone.Value) items" -ForegroundColor Gray
}

# Save enriched data
if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY RUN] Would save to: $outputPath" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Saving enriched data..." -ForegroundColor Green
    $items | ConvertTo-Json -Depth 10 | Set-Content $outputPath -Encoding UTF8
    Write-Host "  Saved to: $outputPath" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Zone Enrichment Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total Items: $($items.Count)" -ForegroundColor Gray
Write-Host "  Items with Descriptions: $($items | Where-Object { $_.Description } | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Gray
Write-Host "  Items Enriched: $enrichedCount ($([math]::Round($enrichedCount/$items.Count*100,1))%)" -ForegroundColor Green
Write-Host "  Unique Zones: $($zoneStats.Count)" -ForegroundColor Gray
Write-Host "  Unique Subzones: $($subzoneStats.Count)" -ForegroundColor Gray
Write-Host ""

if (-not $DryRun) {
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Review enriched data: $outputPath" -ForegroundColor Gray
    Write-Host "  2. Copy to MasterFullValidated.json if satisfied:" -ForegroundColor Gray
    Write-Host "     Copy-Item '$outputPath' '$masterJsonPath' -Force" -ForegroundColor White
    Write-Host "  3. Regenerate database:" -ForegroundColor Gray
    Write-Host "     .\utilities\GenerateVanityDB_Master.ps1" -ForegroundColor White
    Write-Host ""
}
