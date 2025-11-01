<#
.SYNOPSIS
    Master pipeline: API scan export -> filtered combat pet vanity items -> enrichment overlay -> VanityDB.lua -> validation & triage.
.DESCRIPTION
    Consolidates legacy generation and filtering scripts into a single repeatable workflow.
    Compatible with PowerShell 5.1 (avoids PowerShell 7+ syntax).
.USAGE
    pwsh -File .\utilities\MasterVanityDBPipeline.ps1 -ScanFile data\AscensionVanity_Fresh_Scan_YYYY-MM-DD_FINAL.lua
.NOTES
    Date: 2025-11-01
    Categories kept: Beastmaster's Whistle, Blood Soaked Vellum, Summoner's Stone, Draconic Warhorn, Elemental Lodestone.
    Exclusions: purchase/reward/vendor/event/seasonal/etc. keywords.
    Outputs: MasterFullValidated.json, VanityDB.lua, optional validation & triage reports.
#>
[CmdletBinding()]
param(
    [string]$ScanFile = 'data/AscensionVanity_Fresh_Scan_2025-10-28_FINAL.lua',
    [string]$MappingFile = 'data/API_to_GameID_Mapping.json',
    [string]$ValidatedSubset = 'data/EmptyDescriptions_Validated.json',
    [string]$MasterJsonOut = 'data/MasterFullValidated.json',
    [string]$VanityDBOut = 'AscensionVanity/VanityDB.lua'
)

function Step {
    param([string]$Message)
    Write-Host "[STEP] $Message" -ForegroundColor Cyan
}
function Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Gray
}
function Warn {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}
function Ok {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}
function Fail {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

if (-not (Test-Path $ScanFile)) { Fail "Scan file not found: $ScanFile"; exit 1 }
if (-not (Test-Path $MappingFile)) { Fail "Mapping file not found: $MappingFile"; exit 1 }

Step 'Load scan file'
$scanContent = Get-Content $ScanFile -Raw

Step 'Load mapping JSON'
try {
    $mappingData = Get-Content $MappingFile -Raw | ConvertFrom-Json
} catch {
    Fail "Mapping JSON parse failed: $_"
    exit 1
}
$mappingIndex = @{}
foreach ($row in $mappingData) {
    if ($row.GameItemId) {
        $mappingIndex[[int]$row.GameItemId] = $row
    }
}
Info "Mapping entries indexed: $($mappingIndex.Count)"

$combatPrefixes = @(
    "Beastmaster's Whistle:",
    "Blood Soaked Vellum:",
    "Summoner's Stone:",
    "Draconic Warhorn:",
    "Elemental Lodestone:"
)
# Primary Group IDs for legitimate drop-based combat pets (90-99% coverage validated)
$primaryGroupIds = @(
    16777217,  # Beastmaster's Whistle (96.2% coverage)
    16777220,  # Blood Soaked Vellum (95.4% coverage)
    16777218,  # Summoner's Stone (90.1% coverage)
    16777224,  # Draconic Warhorn (99.4% coverage)
    16777232   # Elemental Lodestone (94.7% coverage)
)

# Fallback exclusion keywords (for outlier items with non-primary group IDs)
$exclusionKeywords = @(
    'purchase',
    'webstore',
    'website',
    'previously',
    'bazaar',
    'seasonal',
    'reward',
    'promo',
    'event',
    'limited',
    'achievement',
    'reputation',
    'quartermaster'
)
$vendorPhrases = @(
    'Obtained from the',
    'Purchased from',
    'Sold by',
    'Requires Exalted'
)

Step 'Extract APIDump section'
$apidumpStart = $scanContent.IndexOf('["APIDump"] = {')
if ($apidumpStart -lt 0) { Fail 'APIDump section not found'; exit 1 }
$apidumpEnd = $scanContent.IndexOf('["LastScanDate"]', $apidumpStart)
if ($apidumpEnd -lt 0) { Fail 'LastScanDate marker not found'; exit 1 }
$apidumpSection = $scanContent.Substring($apidumpStart, $apidumpEnd - $apidumpStart)

Step 'Parse item blocks'
$patternIndexed = '\[(\d+)\]\s*=\s*\{([\s\S]*?)\}\s*,?\s*-- \[(\d+)\]'
$patternSimple  = '\[(\d+)\]\s*=\s*\{([\s\S]*?)\}\s*,?'
$matches = [regex]::Matches($apidumpSection, $patternIndexed)
if ($matches.Count -eq 0) { $matches = [regex]::Matches($apidumpSection, $patternSimple) }
Info "Raw item blocks matched: $($matches.Count)"
if ($matches.Count -eq 0) { Fail 'No item blocks parsed'; exit 1 }

Step 'Filter combat pet categories & apply exclusions'
$processed = @()
$excluded = 0
$excludedReasons = @{}
$categoryCounts = @{}

foreach ($match in $matches) {
    $block = $match.Groups[2].Value

    $itemIdMatch = [regex]::Match($block, 'itemId\s*=\s*(\d+)')
    $gameItemId = if ($itemIdMatch.Success) { [int]$itemIdMatch.Groups[1].Value } else { [int]$match.Groups[1].Value }

    $nameMatch = [regex]::Match($block, '\["name"\]\s*=\s*"([^\"]+)"')
    $name = if ($nameMatch.Success) { $nameMatch.Groups[1].Value } else { $null }

    $creatureMatch = [regex]::Match($block, '\["creaturePreview"\]\s*=\s*(\d+)')
    $creatureId = if ($creatureMatch.Success) { [int]$creatureMatch.Groups[1].Value } else { 0 }

    $descMatch = [regex]::Match($block, '\["description"\]\s*=\s*"([\s\S]*?)"')
    $description = if ($descMatch.Success) { $descMatch.Groups[1].Value } else { '' }

    $groupMatch = [regex]::Match($block, '\["group"\]\s*=\s*(\d+)')
    $groupId = if ($groupMatch.Success) { [int]$groupMatch.Groups[1].Value } else { 0 }

    # PRIMARY FILTER: Group ID (most reliable - 90-99% coverage)
    $hasValidGroup = $primaryGroupIds -contains $groupId

    if ($hasValidGroup) {
        # Group ID matched - item is valid, skip other checks for performance
        # Determine category from group ID
        $category = switch ($groupId) {
            16777217 { "Beastmaster's Whistle" }
            16777220 { "Blood Soaked Vellum" }
            16777218 { "Summoner's Stone" }
            16777224 { "Draconic Warhorn" }
            16777232 { "Elemental Lodestone" }
            default { $null }
        }
    } else {
        # FALLBACK FILTER: Name prefix + keyword exclusion (for outliers)
        $isCombat = $false
        $category = $null
        foreach ($prefix in $combatPrefixes) {
            if ($name -and $name -like "$prefix*") {
                $isCombat = $true
                $category = $prefix.TrimEnd(':')
                break
            }
        }
        if (-not $isCombat) { continue }

        # Apply stricter exclusion checks for non-primary group items
        $nameLower = if ($name) { $name.ToLower() } else { '' }
        $descLower = if ($description) { $description.ToLower() } else { '' }
        $isExcluded = $false
        $reason = ''
        foreach ($keyword in $exclusionKeywords) {
            if ($nameLower -match $keyword -or $descLower -match $keyword) {
                $isExcluded = $true
                $reason = $keyword
                break
            }
        }
        if ($isExcluded) {
            $excluded++
            if (-not $excludedReasons.ContainsKey($reason)) { $excludedReasons[$reason] = 0 }
            $excludedReasons[$reason]++
            continue
        }
    }

    if (-not $categoryCounts.ContainsKey($category)) { $categoryCounts[$category] = 0 }
    $categoryCounts[$category]++

    if ($mappingIndex.ContainsKey($gameItemId)) {
        $mapRow = $mappingIndex[$gameItemId]
        if ($mapRow.Name) { $name = $mapRow.Name }
        if ($mapRow.CreatureId -and $mapRow.CreatureId -ne $creatureId) { $creatureId = [int]$mapRow.CreatureId }
    }

    $processed += [pscustomobject]@{
        DbItemId = $gameItemId
        Name = $name
        CreatureId = $creatureId
        Description = $description
        Category = $category
        VendorExempt = $false
    }
}
Info "Combat pet items retained: $($processed.Count) | Excluded: $excluded"

Step 'Overlay enrichment subset & vendor phrases'
$validatedIndex = @{}
if (Test-Path $ValidatedSubset) {
    try {
        $validatedData = Get-Content $ValidatedSubset -Raw | ConvertFrom-Json
        foreach ($entry in $validatedData) {
            if ($entry.DbItemId) {
                $validatedIndex[[int]$entry.DbItemId] = $entry
            }
        }
        Info "Validated enrichment entries: $($validatedIndex.Count)"
    } catch {
        Warn "Failed to parse validated subset: $_"
    }
}

foreach ($row in $processed) {
    if ($validatedIndex.ContainsKey($row.DbItemId)) {
        $validated = $validatedIndex[$row.DbItemId]
        if (-not $row.Description -or $row.Description -match 'Has a chance to drop') {
            $row.Description = $validated.GeneratedDescription
        }
    }
    if ($row.Description) {
        foreach ($phrase in $vendorPhrases) {
            if ($row.Description -like "*$phrase*") {
                $row.VendorExempt = $true
                $row.CreatureId = 0
                break
            }
        }
    }
}

Step 'Emit MasterFullValidated.json'
$processed | ConvertTo-Json -Depth 4 | Out-File $MasterJsonOut -Encoding UTF8
Ok "Master JSON written: $MasterJsonOut"

Step 'Generate VanityDB.lua'
$iconMap = @{
    "Beastmaster's Whistle" = 1
    "Blood Soaked Vellum"   = 2
    "Summoner's Stone"      = 3
    "Draconic Warhorn"      = 4
    "Elemental Lodestone"   = 5
}

$header = @"
-- AscensionVanity Database
-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
-- Total items: $($processed.Count)

AV_IconList = {
    [1] = "Ability_Hunter_BeastCall",
    [2] = "Ability_DK_RuneWeapon",
    [3] = "Spell_Shadow_SummonFelGuard",
    [4] = "Spell_Nature_WispSplode",
    [5] = "Spell_Fire_SelfDestruct"
}

AV_VanityItems = {
"@
$lines = @($header)
$emitted = @{}
foreach ($row in ($processed | Sort-Object DbItemId)) {
    if ($emitted.ContainsKey($row.DbItemId)) { continue }
    $emitted[$row.DbItemId] = $true

    $safeName = if ($row.Name) { $row.Name -replace '"','\"' } else { '' }
    $safeDesc = if ($row.Description) { $row.Description -replace '"','\"' } else { '' }
    $iconIndex = if ($iconMap.ContainsKey($row.Category)) { $iconMap[$row.Category] } else { 0 }

    $lines += "    [$($row.DbItemId)] = {"
    $lines += "        itemid = $($row.DbItemId),"
    $lines += ('        name = "' + $safeName + '",')
    $lines += "        creaturePreview = $($row.CreatureId),"
    $lines += ('        description = "' + $safeDesc + '",')
    $lines += "        icon = $iconIndex"
    $lines += "    },"
}
$lines += "}"
$lines -join "`n" | Set-Content $VanityDBOut -Encoding UTF8
Ok "VanityDB.lua written: $VanityDBOut (items: $($emitted.Count))"

Step 'Validation & triage (optional)'
try {
    if (Test-Path '.\utilities\ValidateCreatureIds.ps1') {
        pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\utilities\ValidateCreatureIds.ps1 | Out-Null
    if ((Test-Path 'data/CreatureId_Anomalies_Report.csv') -and (Test-Path '.\utilities\GenerateAnomalyTriage.ps1')) {
            pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\utilities\GenerateAnomalyTriage.ps1 | Out-Null
            Ok 'Validation & triage complete'
        } else {
            Warn 'Validation CSV or triage script missing'
        }
    } else {
        Warn 'ValidateCreatureIds.ps1 not found – skipping validation'
    }
} catch {
    Warn "Validation failed: $_"
}

Step 'Summary'
Write-Host 'Category counts:' -ForegroundColor Cyan
foreach ($key in $categoryCounts.Keys) {
    Write-Host "  $key : $($categoryCounts[$key])" -ForegroundColor Gray
}
Write-Host 'Exclusion reasons:' -ForegroundColor Cyan
foreach ($key in $excludedReasons.Keys) {
    Write-Host "  $key : $($excludedReasons[$key])" -ForegroundColor Gray
}
Write-Host "Vendor exempt items: $((($processed | Where-Object VendorExempt).Count))" -ForegroundColor Cyan
Ok 'Pipeline completed'
