<#
.SYNOPSIS
    Build MasterFullValidated.json from fresh scan filtered by Group IDs

.DESCRIPTION
    Reads the latest fresh scan and filters items by Group ID to create MasterFullValidated.json.
    Uses direct Group ID filtering for 100% accuracy - no name-based pattern matching needed.
    
    Automatically loads and applies creature ID corrections from data/corrections/CreatureIdCorrections.json.
    Preserves both CreaturePreview (original from scan) and CreatureId (corrected value).
    
    Group IDs (10 groups, 4,221 total items):
    - Combat Pets (Dropped): 16777217, 16777220, 16777218, 16777224, 16777232 (2,345 items)
    - Combat Pets (Seasonal): 553648129, 553648130, 553648136 (10 items)
    - Non-Combat Companions: 134217728 - Sigils, Calves, Cubs, etc. (1,249 items)
    - Mounts (Regular): 67108864 (548 items)
    - Mounts (Seasonal): 671088640 (56 items)
    - Books of Ascension: 167772160 (13 items)
    
    Drop Coverage: 3,016 items (71.4%) start with "Has a chance to drop from..."

.PARAMETER FreshScanPath
    Path to the fresh scan file. If not provided, uses latest in data folder.

.PARAMETER OutputPath
    Path for output file. Default: data/MasterFullValidated.json

.EXAMPLE
    .\utilities\BuildMasterFromGroupIDs.ps1
    
    Builds database from latest scan with all corrections applied.

.NOTES
    Author: CMTout & GitHub Copilot
    Date: 2025-11-14
    Version: 1.1
    
    Changes in v1.1:
    - Added automatic creature ID correction loading
    - Preserves both CreaturePreview and CreatureId fields
    - Renamed "Cosmetic Abilities" to "Non-Combat Companions"
    - Added comprehensive statistics to documentation
#>

[CmdletBinding()]
param(
    [string]$FreshScanPath,
    [string]$OutputPath = "data/MasterFullValidated.json"
)

$ErrorActionPreference = "Stop"

# Define collectible Group IDs
$combatPetGroups = @(16777217, 16777220, 16777218, 16777224, 16777232, 553648129, 553648130, 553648136)
$nonCombatCompanionGroups = @(134217728)  # Sigils, Calves, Cubs, etc.
$mountGroups = @(67108864, 671088640)  # Regular + Seasonal mounts
$bookGroups = @(167772160)  # Books of Ascension
$allCollectibleGroups = $combatPetGroups + $nonCombatCompanionGroups + $mountGroups + $bookGroups

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Build MasterFullValidated.json from Group IDs" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Find latest fresh scan if not provided
if (-not $FreshScanPath) {
    $dataFolder = "data"
    $latestScan = Get-ChildItem "$dataFolder\AscensionVanity_Fresh_Scan_*.lua" | 
                  Sort-Object LastWriteTime -Descending | 
                  Select-Object -First 1
    
    if (-not $latestScan) {
        throw "No fresh scan found in $dataFolder"
    }
    
    $FreshScanPath = $latestScan.FullName
    Write-Host "[INFO] Using latest scan: $($latestScan.Name)" -ForegroundColor Gray
}

if (-not (Test-Path $FreshScanPath)) {
    throw "Fresh scan not found: $FreshScanPath"
}

Write-Host "[1/5] Loading fresh scan..." -ForegroundColor Yellow
$scanContent = Get-Content $FreshScanPath -Raw

# Find APIDump section
if ($scanContent -notmatch '\["APIDump"\]\s*=\s*\{([\s\S]*)\}') {
    throw "Could not find APIDump section in scan file"
}

$apiDumpContent = $Matches[1]
Write-Host "  Found APIDump section" -ForegroundColor Gray

Write-Host "[2/5] Loading creature ID corrections..." -ForegroundColor Yellow
$corrections = @{}
$correctionsPath = "data/corrections/CreatureIdCorrections.json"
if (Test-Path $correctionsPath) {
    $correctionsData = Get-Content $correctionsPath -Raw | ConvertFrom-Json
    foreach ($correction in $correctionsData.corrections) {
        $corrections[[int]$correction.itemId] = [int]$correction.correctCreatureId
    }
    Write-Host "  Loaded $($corrections.Count) creature ID corrections" -ForegroundColor Gray
} else {
    Write-Host "  No corrections file found - skipping" -ForegroundColor DarkGray
}

Write-Host "[3/5] Parsing items and filtering by Group ID..." -ForegroundColor Yellow

# Parse item blocks - use [\s\S] to match across newlines
$itemPattern = '\[(\d+)\]\s*=\s*\{([\s\S]*?)\}'
$itemMatches = [regex]::Matches($apiDumpContent, $itemPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

Write-Host "  Found $($itemMatches.Count) total items in scan" -ForegroundColor Gray

$results = @()
$dupeCheck = @{}
$groupCounts = @{}
$mountsSeenBeforeFilter = 0
$mountsPassedFilter = 0

foreach ($match in $itemMatches) {
    $itemId = [int]$match.Groups[1].Value
    $block = $match.Groups[2].Value
    
    # Extract Group ID early for debug
    $groupId = $null
    if ($block -match '\["group"\]\s*=\s*(\d+)') {
        $groupId = [int]$Matches[1]
        # Debug: Count mounts BEFORE any filtering
        if ($groupId -eq 67108864) {
            $mountsSeenBeforeFilter++
        }
    }
    
    # Skip duplicates
    if ($dupeCheck.ContainsKey($itemId)) {
        # Debug: Check if duplicate is a mount
        if ($groupId -eq 67108864) {
            Write-Warning "Duplicate mount ID: $itemId"
        }
        continue
    }
    $dupeCheck[$itemId] = $true
    
    # Extract Group ID (again, for the actual logic)
    if ($block -notmatch '\["group"\]\s*=\s*(\d+)') {
        continue
    }
    $groupId = [int]$Matches[1]
    
    # Filter by Group ID
    if ($allCollectibleGroups -notcontains $groupId) {
        continue
    }
    
    # Debug: Count mounts after filter
    if ($groupId -eq 67108864) {
        $mountsPassedFilter++
    }
    
    # Track group counts
    if (-not $groupCounts.ContainsKey($groupId)) {
        $groupCounts[$groupId] = 0
    }
    $groupCounts[$groupId]++
    
    # Extract other fields
    $name = ''
    $creatureId = 0
    $creaturePreview = 0
    $description = ''
    $icon = ''
    
    if ($block -match '\["name"\]\s*=\s*"((?:[^"\\]|\\.)*)"') {
        $name = $Matches[1] -replace '\\"', '"'
    }
    if ($block -match '\["creaturePreview"\]\s*=\s*(\d+)') {
        $creaturePreview = [int]$Matches[1]
        $creatureId = $creaturePreview  # Start with original value
    }
    if ($block -match '\["description"\]\s*=\s*"((?:[^"\\]|\\.)*)"') {
        $description = $Matches[1] -replace '\\"', '"'
    }
    if ($block -match '\["icon"\]\s*=\s*"([^"]+)"') {
        $icon = $Matches[1]
    }
    
    # Determine category
    $category = $null
    if ($name -like "Beastmaster's Whistle:*") {
        $category = "Beastmaster's Whistle"
    } elseif ($name -like "Blood Soaked Vellum:*") {
        $category = "Blood Soaked Vellum"
    } elseif ($name -like "Summoner's Stone:*") {
        $category = "Summoner's Stone"
    } elseif ($name -like "Draconic Warhorn:*") {
        $category = "Draconic Warhorn"
    } elseif ($name -like "Elemental Lodestone:*") {
        $category = "Elemental Lodestone"
    } elseif ($groupId -eq 134217728) {
        $category = "Non-Combat Companion"
    } elseif ($groupId -eq 67108864 -or $groupId -eq 671088640) {
        $category = "Mount"
    } elseif ($groupId -eq 167772160) {
        $category = "Book of Ascension"
    }
    
    # Check for vendor exemption
    $vendorExempt = $false
    if ($description -match 'purchase|vendor|buy|sold by|Can be purchased|Requires Exalted|Obtained from.*Quartermaster') {
        $vendorExempt = $true
    }
    
    # Apply creature ID correction if exists (original stays in creaturePreview)
    if ($corrections.ContainsKey($itemId)) {
        $creatureId = $corrections[$itemId]
    }
    
    $results += [PSCustomObject]@{
        DbItemId = $itemId
        ItemName = $name
        Name = $name
        CreatureId = $creatureId
        CreaturePreview = $creaturePreview
        Description = $description
        Category = $category
        Icon = $icon
        GroupId = $groupId
        VendorExempt = $vendorExempt
    }
}

Write-Host "  Filtered to $($results.Count) collectible items" -ForegroundColor Green
Write-Host "  DEBUG: Mounts seen before filter: $mountsSeenBeforeFilter" -ForegroundColor Magenta
Write-Host "  DEBUG: Mounts passed filter: $mountsPassedFilter" -ForegroundColor Magenta
Write-Host "  DEBUG: Mounts added to results: $($results | Where-Object { $_.GroupId -eq 67108864 } | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Magenta

Write-Host "[4/5] Group breakdown:" -ForegroundColor Yellow
foreach ($groupId in ($groupCounts.Keys | Sort-Object)) {
    $groupName = switch ($groupId) {
        16777217 { "Beastmaster's Whistle" }
        16777220 { "Blood Soaked Vellum" }
        16777218 { "Summoner's Stone" }
        16777224 { "Draconic Warhorn" }
        16777232 { "Elemental Lodestone" }
        553648129 { "Seasonal Pet 1" }
        553648130 { "Seasonal Pet 2" }
        553648136 { "Seasonal Pet 3" }
        134217728 { "Non-Combat Companions" }
        67108864 { "Mounts (Regular)" }
        671088640 { "Mounts (Seasonal)" }
        167772160 { "Books of Ascension" }
        default { "Unknown ($groupId)" }
    }
    Write-Host "  $groupName : $($groupCounts[$groupId]) items" -ForegroundColor Gray
}

Write-Host "[5/5] Saving to $OutputPath..." -ForegroundColor Yellow
$results | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host ""
Write-Host "✓ Successfully created MasterFullValidated.json with $($results.Count) items" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Run enrichment: .\utilities\EnrichZoneData.ps1" -ForegroundColor Gray
Write-Host "  2. Generate database: .\utilities\GenerateVanityDB_Master.ps1" -ForegroundColor Gray
Write-Host ""
