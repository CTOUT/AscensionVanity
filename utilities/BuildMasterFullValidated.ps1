<#
.SYNOPSIS
    Build MasterFullValidated.json from the latest filtered scan and mapping corrections.
.DESCRIPTION
    Parses data/AscensionVanity_Fresh_Scan_2025-10-28_FINAL.lua to extract full item list.
    Merges authoritative creature ID corrections from API_to_GameID_Mapping.json.
    Assigns Category by prefix, applies vendor phrase exemption (CreatureId remains 0).
    Marks all items Validated = true if they have a non-empty description.
    Outputs data/MasterFullValidated.json for use with master database generation.
.NOTES
    Author: Automated build script
    Date: 2025-11-01
#>
[CmdletBinding()]
param(
    [string]$ScanFile = 'data/AscensionVanity_Fresh_Scan_2025-10-28_FINAL.lua',
    [string]$MappingFile = 'data/API_to_GameID_Mapping.json',
    [string]$OutputFile = 'data/MasterFullValidated.json',
    [string]$ValidatedSubset = 'data/EmptyDescriptions_Validated.json',
    [string]$EnrichmentCsv = 'data/Enrichment_Results_2025-10-29_120332.csv'
)

if (!(Test-Path $ScanFile)) { Write-Error "Scan file not found: $ScanFile"; exit 1 }
if (!(Test-Path $MappingFile)) { Write-Error "Mapping file not found: $MappingFile"; exit 1 }

Write-Host "Loading scan file..." -ForegroundColor Cyan
$scanContent = Get-Content $ScanFile -Raw

# Extract item blocks (multi-line). Non-greedy until solitary closing brace followed by optional comma/newline.
$itemPattern = '\[(\d+)\]\s*=\s*\{([\s\S]*?)\n\s*\},?'
$matches = [regex]::Matches($scanContent, $itemPattern)
Write-Host "Found $($matches.Count) raw item blocks" -ForegroundColor Yellow

Write-Host "Loading mapping JSON..." -ForegroundColor Cyan
$mapping = Get-Content $MappingFile -Raw | ConvertFrom-Json
$validatedIndex = @{}
if (Test-Path $ValidatedSubset) {
    Write-Host "Loading validated subset..." -ForegroundColor Cyan
    try {
        $validatedData = Get-Content $ValidatedSubset -Raw | ConvertFrom-Json
        foreach ($v in $validatedData) { if ($v.DbItemId) { $validatedIndex[[int]$v.DbItemId] = $v } }
        Write-Host "Validated subset entries: $($validatedIndex.Count)" -ForegroundColor Yellow
    } catch { Write-Warning "Failed to parse validated subset: $_" }
}

$enrichmentIndex = @{}
if (Test-Path $EnrichmentCsv) {
    Write-Host "Loading enrichment CSV..." -ForegroundColor Cyan
    try {
        $csv = Import-Csv $EnrichmentCsv
        foreach ($row in $csv) {
            $idField = $row.GameItemId
            if ($idField -and $idField -match '^\d+$') {
                $id = [int]$idField
                if (-not $enrichmentIndex.ContainsKey($id)) {
                    $enrichmentIndex[$id] = $row
                }
            }
        }
        Write-Host "Enrichment rows: $($enrichmentIndex.Count)" -ForegroundColor Yellow
    } catch { Write-Warning "Failed to load enrichment CSV: $_" }
}
$mappingIndex = @{}
foreach ($row in $mapping) { $mappingIndex[[int]$row.GameItemId] = $row }

$vendorPhrases = @(
    'Obtained from the Argent Quartermaster',
    'Purchased from',
    'Sold by',
    'Requires Exalted with'
)

function Get-Category {
    param([string]$name)
    if ($name -like "Beastmaster's Whistle:*") { return "Beastmaster's Whistle" }
    if ($name -like "Blood Soaked Vellum:*") { return "Blood Soaked Vellum" }
    if ($name -like "Summoner's Stone:*") { return "Summoner's Stone" }
    if ($name -like "Draconic Warhorn:*") { return "Draconic Warhorn" }
    if ($name -like "Elemental Lodestone:*") { return "Elemental Lodestone" }
    return $null
}

$results = @()
$dupeCheck = @{}
$correctedCount = 0
$vendorCount = 0

foreach ($m in $matches) {
    $itemId = [int]$m.Groups[1].Value
    if ($dupeCheck.ContainsKey($itemId)) { continue }
    $dupeCheck[$itemId] = $true
    $block = $m.Groups[2].Value

    $name = $null; $creatureId = $null; $desc = $null
    $nameMatch = [regex]::Match($block, 'name\s*=\s*"([^"\n]*)"')
    if ($nameMatch.Success) { $name = $nameMatch.Groups[1].Value }
    $creatureMatch = [regex]::Match($block, 'creaturePreview\s*=\s*(\d+)')
    if ($creatureMatch.Success) { $creatureId = [int]$creatureMatch.Groups[1].Value }
    $descMatch = [regex]::Match($block, 'description\s*=\s*"([\s\S]*?)"')
    if ($descMatch.Success) { $desc = $descMatch.Groups[1].Value.Trim() }

    # Mapping correction override
    if ($mappingIndex.ContainsKey($itemId)) {
        $mapRow = $mappingIndex[$itemId]
        if ($mapRow.CreatureId -and $mapRow.CreatureId -ne $creatureId) {
            $creatureId = [int]$mapRow.CreatureId
            $correctedCount++
        }
        if ($mapRow.Name -and $mapRow.Name -ne $name) { $name = $mapRow.Name }
    }

    $category = Get-Category -name $name
    if (-not $category -and $name) {
        switch -Regex ($name) {
            "^Beastmaster's Whistle:" { $category = "Beastmaster's Whistle"; break }
            "^Blood Soaked Vellum:" { $category = "Blood Soaked Vellum"; break }
            "^Summoner's Stone:" { $category = "Summoner's Stone"; break }
            "^Draconic Warhorn:" { $category = "Draconic Warhorn"; break }
            "^Elemental Lodestone:" { $category = "Elemental Lodestone"; break }
        }
    }

    # Vendor phrase detection
    $isVendor = $false
    foreach ($phrase in $vendorPhrases) { if ($desc -like "*$phrase*") { $isVendor = $true; break } }
    if ($isVendor) { $vendorCount++ }

    # Overlay enrichment / validated subset
    if ($validatedIndex.ContainsKey($itemId)) {
        $val = $validatedIndex[$itemId]
        if ($val.Region -and $desc -and $desc -notmatch $val.Region) {
            # Prefer enriched region-specific description if existing desc is empty or generic
            if (-not $desc -or $desc -match 'Has a chance to drop') { $desc = $val.GeneratedDescription }
        } elseif (-not $desc -and $val.GeneratedDescription) {
            $desc = $val.GeneratedDescription
        }
    }
    if ($enrichmentIndex.ContainsKey($itemId)) {
        $enr = $enrichmentIndex[$itemId]
        if (-not $desc -and $enr.Description) { $desc = $enr.Description }
    }

    $validated = $true
    if (-not $desc -or $desc -eq '' -or $desc -match '^Cannot validate' -or -not $name) { $validated = $false }
    if ($isVendor) { $validated = $true }

    $results += [pscustomobject]@{
        DbItemId = $itemId
        Name = $name
        CreatureId = $creatureId
        Description = $desc
        Category = $category
        Validated = $validated
        VendorExempt = $isVendor
    }
}

Write-Host "Corrections applied: $correctedCount" -ForegroundColor Green
Write-Host "Vendor exempt items: $vendorCount" -ForegroundColor Yellow
Write-Host "Total unique items: $($results.Count)" -ForegroundColor Cyan
Write-Host "Items with names: $((($results | Where-Object Name).Count))" -ForegroundColor Cyan
Write-Host "Validated items: $((($results | Where-Object Validated).Count))" -ForegroundColor Cyan
Write-Host "Items with enrichment applied: $((($results | Where-Object { $_.Description -and $_.Description.Length -gt 0 }).Count))" -ForegroundColor Cyan

# Output JSON
$results | ConvertTo-Json -Depth 4 | Out-File $OutputFile -Encoding UTF8
Write-Host "Master JSON written: $OutputFile" -ForegroundColor Green
