<#!
.SYNOPSIS
    Validate and report anomalous CreatureId values in API_to_GameID_Mapping.json.

.DESCRIPTION
    Scans the mapping JSON for CreatureId values that look out of place based on heuristic rules:
      * Extreme: >= 500000
      * HighRange: >= 90000
      * MidRange:  >= 40000
      * Suspicious prefixes: 400xxxx, 987xx for Beastmaster style entries
    Cross-references anomalies against local scan files to count evidence occurrences.
    Produces JSON and CSV reports for manual follow-up (db.ascension.gg verification).

.PARAMETER MappingPath
    Path to API_to_GameID_Mapping.json (default: .\data\API_to_GameID_Mapping.json)

.PARAMETER DataFolder
    Folder containing scan/source Lua files to search (default: .\data)

.PARAMETER OutputPrefix
    Prefix for output report files (default: CreatureId_Anomalies_Report)

.EXAMPLE
    ./utilities/ValidateCreatureIds.ps1

.EXAMPLE
    ./utilities/ValidateCreatureIds.ps1 -MappingPath .\data\API_to_GameID_Mapping.json -DataFolder .\data -Verbose

.NOTES
    Author: GitHub Copilot + CMTout
    Date: 2025-11-01
    Validation is heuristic; manual confirmation required for each anomaly.
#>
[CmdletBinding()]
param(
    [string]$MappingPath = '.\data\API_to_GameID_Mapping.json',
    [string]$DataFolder = '.\data',
    [string]$OutputPrefix = 'CreatureId_Anomalies_Report',
    [switch]$All,
    [switch]$RegionPrep
)

if (!(Test-Path $MappingPath)) {
    Write-Error "Mapping file not found: $MappingPath"; exit 1
}
if (!(Test-Path $DataFolder)) {
    Write-Error "Data folder not found: $DataFolder"; exit 1
}

Write-Verbose "Loading mapping JSON..."
$mappingRaw = Get-Content $MappingPath -Raw | ConvertFrom-Json

# Optional load of current VanityDB.lua for description/vendor phrase detection
$vanityDbPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'AscensionVanity\VanityDB.lua'
$descriptions = @{}
if (Test-Path $vanityDbPath) {
    try {
        $dbContent = Get-Content $vanityDbPath -Raw
        # Pattern: [ITEMID] = { ... name = "..", creaturePreview = N, ... description = "...",
        $itemBlockPattern = '\[(\d+)\]\s*=\s*\{[^}]*?description\s*=\s*"([^"]*)"'
        $matchesBlocks = [regex]::Matches($dbContent, $itemBlockPattern, 'Singleline')
        foreach ($m in $matchesBlocks) {
            $id = [int]$m.Groups[1].Value
            $desc = $m.Groups[2].Value
            $descriptions[$id] = $desc
        }
    } catch {
        Write-Warning "Failed to parse VanityDB.lua descriptions: $_"
    }
}

# Vendor phrases to classify vendor exemptions
$vendorPhrases = @(
    'Obtained from the Argent Quartermaster',
    'Purchased from',
    'Sold by',
    'Requires Exalted with'
)

# Vanity categories of interest (prefix match in Name)
$targetPrefixes = @(
    "Beastmaster's Whistle",
    "Blood Soaked Vellum",
    "Summoner's Stone",
    "Draconic Warhorn",
    "Elemental Lodestone"
)

# Heuristic thresholds
$thresholdExtreme = 500000
$thresholdHigh    = 90000
$thresholdMid     = 40000

# Files to search for evidence
$searchFiles = Get-ChildItem $DataFolder -File -Include 'AscensionVanity_Fresh_Scan_*.lua','AscensionVanity.lua','AscensionVanity_Transformed.lua' -ErrorAction SilentlyContinue

function Get-CreatureEvidence {
    param(
        [int]$CreatureId
    )
    # Match substring 'creaturePreview' followed later by '= <id>' using regex
    $pattern = "creaturePreview.*=\s+$CreatureId"
    $filesFound = @()
    foreach ($f in $searchFiles) {
    $match = Select-String -Path $f.FullName -Pattern $pattern -ErrorAction SilentlyContinue
        if ($match) { $filesFound += $f.Name }
    }
    [pscustomobject]@{
        Count = $filesFound.Count
        Files = $filesFound -join ';'
    }
}

$anomalies = @()
$processed = 0
$total = $mappingRaw.Count
Write-Host "Scanning $total mapping entries for anomalies..."
foreach ($row in $mappingRaw) {
    $processed++
    if ($processed % 2000 -eq 0) { Write-Host "Processed $processed / $total" }
    $cid = $row.CreatureId
    if (-not $cid -or $cid -eq 0) { continue }

    $reasons = @()
    if ($cid -ge $thresholdExtreme) { $reasons += 'extreme' }
    elseif ($cid -ge $thresholdHigh) { $reasons += 'highRange' }
    elseif ($cid -ge $thresholdMid) { $reasons += 'midRange' }

    if ($cid.ToString() -match '^400\d{3,}$') { $reasons += '400prefix' }
    if ($cid.ToString() -match '^987\d{2,}$') { $reasons += '987prefix' }

    if ($reasons.Count -gt 0) {
        if (-not $All) {
            $isTarget = $false
            foreach ($p in $targetPrefixes) {
                if ($row.Name -like "$p*") { $isTarget = $true; break }
            }
            if (-not $isTarget) { continue }
        }
        $evidence = Get-CreatureEvidence -CreatureId $cid
        # Suggestion classification
        $suggestion = 'review'
        if ($row.Name -like "Beastmaster's Whistle: *" -and $cid -ge $thresholdExtreme -and $evidence.Count -eq 0) {
            $suggestion = 'exempt_vendor_candidate'
        } elseif ($row.Name -like "Beastmaster's Whistle: *" -and $cid.ToString() -match '^400' -and $evidence.Count -eq 0) {
            $suggestion = 'strip_400_prefix_candidate'
        } elseif ($row.Name -like "Beastmaster's Whistle: Venomtail Scorpid" -and $cid -ge $thresholdExtreme) {
            $suggestion = 'correct_to_3127'
        } elseif ($row.Name -like "Beastmaster's Whistle: *" -and $cid -ge 90000 -and $evidence.Count -eq 0) {
            $suggestion = 'likely_non_drop_set_0'
        }
        # Vendor phrase override using description if present
        $dbDesc = $descriptions[[int]$row.GameItemId]
        if ($dbDesc) {
            foreach ($phrase in $vendorPhrases) {
                if ($dbDesc -like "*$phrase*") { $suggestion = 'exempt_vendor_phrase'; break }
            }
        }
        $anomalies += [pscustomobject]@{
            GameItemId = $row.GameItemId
            Name       = $row.Name
            CreatureId = $cid
            Reasons    = ($reasons -join ',')
            EvidenceCount = $evidence.Count
            EvidenceFiles = $evidence.Files
            Suggestion  = $suggestion
            Description = $dbDesc
        }
    }
}

Write-Host "Anomalies detected: $($anomalies.Count)"

# Output paths
$jsonPath = Join-Path $DataFolder "$OutputPrefix.json"
$csvPath  = Join-Path $DataFolder "$OutputPrefix.csv"

$anomalies | ConvertTo-Json -Depth 4 | Out-File $jsonPath -Encoding UTF8
$anomalies | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "Reports written:" -ForegroundColor Green
Write-Host " JSON: $jsonPath"
Write-Host " CSV:  $csvPath"

# Summary grouping
$grouped = $anomalies | Group-Object Reasons | Sort-Object Count -Descending
Write-Host "Reason Distribution:" -ForegroundColor Cyan
foreach ($g in $grouped) {
    Write-Host ("  {0,-15} {1,5}" -f $g.Name, $g.Count)
}

Write-Host "Top anomalies (first 15):" -ForegroundColor Cyan
$anomalies | Sort-Object CreatureId -Descending | Select-Object -First 15 | Format-Table -AutoSize

Write-Host "\nNEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. Manually validate each anomaly against db.ascension.gg (ignore wowhead)."
Write-Host "  2. Confirm whether high-range IDs correspond to custom Ascension entries."
Write-Host "  3. Correct mapping JSON entries where CreatureId is a display/model ID vs creature entry."
Write-Host "  4. Re-run this script until anomaly count stabilized (only legitimate high-range remain)."

if ($RegionPrep) {
    Write-Host "\nPreparing region lookup triage (extreme anomalies only)..." -ForegroundColor Cyan
    $extreme = $anomalies | Where-Object { $_.Reasons -match 'extreme' }
    $triage = foreach ($row in $extreme) {
        # Extract base name after first colon (e.g., "Beastmaster's Whistle: Jungle King" -> "Jungle King")
        $baseName = $row.Name
        if ($baseName -match ':') { $baseName = ($baseName -split ':',2)[1].Trim() }
        [pscustomobject]@{
            GameItemId    = $row.GameItemId
            FullName      = $row.Name
            BaseName      = $baseName
            CreatureId    = $row.CreatureId
            Reasons       = $row.Reasons
            EvidenceCount = $row.EvidenceCount
            EvidenceFiles = $row.EvidenceFiles
            RegionFound   = ''   # to be filled manually after db.ascension.gg search
            Status        = 'pending'
        }
    }
    $triagePath = Join-Path $DataFolder 'CreatureId_Region_Triage.csv'
    $triage | Export-Csv -Path $triagePath -NoTypeInformation -Encoding UTF8
    Write-Host "Region triage file written: $triagePath" -ForegroundColor Green
    Write-Host "Columns: GameItemId,FullName,BaseName,CreatureId,Reasons,EvidenceCount,EvidenceFiles,RegionFound,Status" -ForegroundColor Green
    Write-Host "Fill RegionFound with zone/region text from db.ascension.gg (or 'none'), then set Status to 'confirmed' or 'corrected'." -ForegroundColor Yellow
}
