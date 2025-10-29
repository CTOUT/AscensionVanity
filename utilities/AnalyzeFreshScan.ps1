# Analyze Fresh API Scan Data
# Processes the AscensionVanity SavedVariables file and compares with current VanityDB

param(
    [string]$SavedVariablesPath = "d:\Program Files\Ascension Launcher\resources\client\WTF\Account\chris-tout@outlook.com\SavedVariables\AscensionVanity.lua",
    [string]$VanityDBPath = ".\AscensionVanity\VanityDB.lua",
    [switch]$Detailed
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fresh API Scan Analysis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if saved variables file exists
if (-not (Test-Path $SavedVariablesPath)) {
    Write-Host "ERROR: SavedVariables file not found at: $SavedVariablesPath" -ForegroundColor Red
    Write-Host "Please run /avscan scan in-game first, then /reload to save the data" -ForegroundColor Yellow
    exit 1
}

# Check if VanityDB exists
if (-not (Test-Path $VanityDBPath)) {
    Write-Host "ERROR: VanityDB.lua not found at: $VanityDBPath" -ForegroundColor Red
    exit 1
}

Write-Host "Reading saved variables..." -ForegroundColor Yellow
$savedVarsContent = Get-Content $SavedVariablesPath -Raw

# Extract the scan metadata
if ($savedVarsContent -match '\["TotalItems"\]\s*=\s*(\d+)') {
    $totalItems = $matches[1]
    Write-Host "Total items in scan: $totalItems" -ForegroundColor Green
}

if ($savedVarsContent -match '\["ScanVersion"\]\s*=\s*"([^"]+)"') {
    $scanVersion = $matches[1]
    Write-Host "Scan version: $scanVersion" -ForegroundColor Green
}

if ($savedVarsContent -match '\["LastScanDate"\]\s*=\s*"([^"]+)"') {
    $lastScan = $matches[1]
    Write-Host "Last scan: $lastScan" -ForegroundColor Green
}

Write-Host ""
Write-Host "Extracting API dump data..." -ForegroundColor Yellow

# Parse APIDump section - extract items with creature previews
$apiItems = @{}
$itemsWithoutCreatures = 0
$itemsWithCreatures = 0

# Find all items in APIDump with their creature IDs
$pattern = '\["itemId"\]\s*=\s*(\d+),.*?\["creaturePreview"\]\s*=\s*(\d+)'
$regexMatches = [regex]::Matches($savedVarsContent, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

foreach ($match in $regexMatches) {
    $itemId = [int]$match.Groups[1].Value
    $creatureId = [int]$match.Groups[2].Value
    
    if ($creatureId -gt 0) {
        if (-not $apiItems.ContainsKey($creatureId)) {
            $apiItems[$creatureId] = @()
        }
        $apiItems[$creatureId] += $itemId
        $itemsWithCreatures++
    } else {
        $itemsWithoutCreatures++
    }
}

Write-Host "Items with creature IDs: $itemsWithCreatures" -ForegroundColor Green
Write-Host "Items without creature IDs: $itemsWithoutCreatures" -ForegroundColor Yellow
Write-Host "Unique creatures: $($apiItems.Count)" -ForegroundColor Green
Write-Host ""

# Read current VanityDB
Write-Host "Reading current VanityDB..." -ForegroundColor Yellow
$vanityDBContent = Get-Content $VanityDBPath -Raw

# Parse current VanityDB - extract creature-to-item mappings
$dbItems = @{}

# Pattern to match: itemid = <number>, ... creaturePreview = <number>
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

Write-Host "Current DB entries: $($dbItems.Count)" -ForegroundColor Green
Write-Host ""

# Analysis
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "COMPARISON ANALYSIS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Find matches, mismatches, and missing items
$matchCount = 0
$mismatches = @()
$apiOnly = @()
$dbOnly = @()

# Check API items against DB
foreach ($creatureId in $apiItems.Keys) {
    if ($dbItems.ContainsKey($creatureId)) {
        $apiItemIds = $apiItems[$creatureId]
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
            Items = $apiItems[$creatureId]
        }
    }
}

# Check DB items not in API
foreach ($creatureId in $dbItems.Keys) {
    if (-not $apiItems.ContainsKey($creatureId)) {
        $dbOnly += @{
            CreatureId = $creatureId
            Items = $dbItems[$creatureId]
        }
    }
}

Write-Host "Exact matches: $matchCount" -ForegroundColor Green
Write-Host "Mismatches (different items): $($mismatches.Count)" -ForegroundColor Yellow
Write-Host "In API only (missing from DB): $($apiOnly.Count)" -ForegroundColor Cyan
Write-Host "In DB only (not in API): $($dbOnly.Count)" -ForegroundColor Magenta
Write-Host ""

# Show samples
if ($apiOnly.Count -gt 0) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "MISSING FROM DATABASE (First 10)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $count = 0
    foreach ($entry in $apiOnly) {
        if ($count -ge 10) { break }
        $itemsList = $entry.Items -join ', '
        Write-Host "Creature $($entry.CreatureId): Items [$itemsList]" -ForegroundColor Cyan
        $count++
    }
    
    if ($apiOnly.Count -gt 10) {
        Write-Host "... and $($apiOnly.Count - 10) more" -ForegroundColor Gray
    }
    Write-Host ""
}

if ($mismatches.Count -gt 0) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "MISMATCHES (First 10)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $count = 0
    foreach ($entry in $mismatches) {
        if ($count -ge 10) { break }
        $apiItemsList = $entry.APIItems -join ', '
        $dbItemsList = $entry.DBItems -join ', '
        Write-Host "Creature $($entry.CreatureId):" -ForegroundColor Yellow
        Write-Host "  API has: [$apiItemsList]" -ForegroundColor Cyan
        Write-Host "  DB has:  [$dbItemsList]" -ForegroundColor Magenta
        $count++
    }
    
    if ($mismatches.Count -gt 10) {
        Write-Host "... and $($mismatches.Count - 10) more" -ForegroundColor Gray
    }
    Write-Host ""
}

# Generate detailed report if requested
if ($Detailed) {
    $reportPath = ".\API_Analysis\Fresh_Scan_Report_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').txt"
    
    Write-Host "Generating detailed report..." -ForegroundColor Yellow
    
    # Create directory if needed
    if (-not (Test-Path ".\API_Analysis")) {
        New-Item -ItemType Directory -Path ".\API_Analysis" | Out-Null
    }
    
    $report = @"
API SCAN ANALYSIS REPORT
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================

SCAN METADATA
- Total items scanned: $totalItems
- Items with creatures: $itemsWithCreatures
- Items without creatures: $itemsWithoutCreatures
- Unique creatures: $($apiItems.Count)
- Scan version: $scanVersion
- Last scan: $lastScan

DATABASE COMPARISON
- Current DB entries: $($dbItems.Count)
- Exact matches: $matchCount
- Mismatches: $($mismatches.Count)
- Missing from DB: $($apiOnly.Count)
- Only in DB: $($dbOnly.Count)

========================================
MISSING FROM DATABASE ($($apiOnly.Count) total)
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
    
    $report += @"

========================================
ONLY IN DATABASE ($($dbOnly.Count) total)
========================================

"@
    
    foreach ($entry in $dbOnly) {
        $itemsList = $entry.Items -join ', '
        $report += "Creature $($entry.CreatureId): Items [$itemsList]`n"
    }
    
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host "Detailed report saved to: $reportPath" -ForegroundColor Green
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ANALYSIS COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review the missing items and mismatches above" -ForegroundColor White
Write-Host "2. Run with -Detailed flag for full report" -ForegroundColor White
Write-Host "3. Use utilities\UpdateDatabaseFromAPI.ps1 to generate updated VanityDB" -ForegroundColor White
Write-Host ""
