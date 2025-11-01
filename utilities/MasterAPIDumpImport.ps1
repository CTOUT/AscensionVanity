<#
.SYNOPSIS
    Master workflow to import and normalize Ascension Vanity API dump data from SavedVariables.
.DESCRIPTION
    Consolidates the legacy API dump utilities (ProcessAPIDump, AnalyzeAPIDump, ExtractGameIDs, ProcessFreshScan)
    into a single repeatable PowerShell 5.1–compatible script. The workflow:
        1. Resolve the AscensionVanity.lua SavedVariables file (auto-detect or user supplied).
        2. Extract the AscensionVanityDB / AscensionVanityDump tables and emit a timestamped fresh scan file.
        3. Parse the APIDump entries to produce ApiId → GameItemId mapping metadata.
        4. Generate summary statistics and optional reports for downstream processing.
    The outputs can be fed directly into MasterVanityDBPipeline.ps1 to regenerate VanityDB.lua.
.PARAMETER SavedVariablesPath
    Optional explicit path to the AscensionVanity.lua SavedVariables file. If omitted the script will try to resolve
    the path via local.config.ps1, registry detection, or prompt the user with guidance.
.PARAMETER OutputDirectory
    Directory where generated artifacts (fresh scan, mapping JSON, summary report) will be written. Defaults to ./data.
.PARAMETER ScanLabel
    Optional suffix appended to the generated fresh scan filename (e.g. "PREPATCH", "HOTFIX").
.PARAMETER SkipMappingExport
    When set, the ApiId → GameItemId mapping JSON export is skipped.
.PARAMETER SkipSummaryFile
    When set, the textual import summary report is not written to disk (console output still shown).
.PARAMETER NoScanCopy
    When set, the script will parse metadata but will not emit the normalized fresh scan Lua file.
.EXAMPLE
    ./utilities/MasterAPIDumpImport.ps1
.EXAMPLE
    ./utilities/MasterAPIDumpImport.ps1 -SavedVariablesPath "C:\\Games\\Ascension\\WTF\\Account\\Foo\\SavedVariables\\AscensionVanity.lua" -ScanLabel PREPATCH
.NOTES
    Author: GitHub Copilot (AscensionVanity consolidation)
    Date: 2025-11-01
    PowerShell: Compatible with Windows PowerShell 5.1 and PowerShell 7+
#>
[CmdletBinding()]
param(
    [string]$SavedVariablesPath,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\data'),
    [string]$ScanLabel,
    [switch]$SkipMappingExport,
    [switch]$SkipSummaryFile,
    [switch]$NoScanCopy
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

function Get-WoWInstallPath {
    try {
        $regPath = 'HKLM:\SOFTWARE\WOW6432Node\Blizzard Entertainment\World of Warcraft'
        if (Test-Path $regPath) {
            $installPath = (Get-ItemProperty -Path $regPath -Name 'InstallPath' -ErrorAction SilentlyContinue).InstallPath
            if ($installPath -and (Test-Path $installPath)) {
                return $installPath
            }
        }
    } catch {
        # ignore and fall through
    }
    return $null
}

function Resolve-SavedVariablesPath {
    param([string]$ProvidedPath)

    if ($ProvidedPath) {
        if (Test-Path $ProvidedPath) {
            return (Resolve-Path $ProvidedPath).Path
        }
        Fail "SavedVariables file not found: $ProvidedPath"
        throw "InvalidSavedVariablesPath"
    }

    $localConfig = Join-Path $PSScriptRoot '..\local.config.ps1'
    if (Test-Path $localConfig) {
        try {
            . $localConfig
            if ($script:SavedVariablesPath -and (Test-Path $script:SavedVariablesPath)) {
                return (Resolve-Path $script:SavedVariablesPath).Path
            }
        } catch {
            Warn "Unable to load local.config.ps1: $_"
        }
    }

    $wowPath = Get-WoWInstallPath
    if ($wowPath) {
        $wtfPath = Join-Path $wowPath 'WTF\Account'
        if (Test-Path $wtfPath) {
            $accountDirs = Get-ChildItem -Path $wtfPath -Directory -ErrorAction SilentlyContinue
            foreach ($dir in $accountDirs) {
                $candidate = Join-Path $dir.FullName 'SavedVariables\AscensionVanity.lua'
                if (Test-Path $candidate) {
                    Info "Detected SavedVariables for account: $($dir.Name)"
                    return (Resolve-Path $candidate).Path
                }
            }
        }
    }

    Fail 'Unable to locate AscensionVanity.lua automatically.'
    Warn 'Specify -SavedVariablesPath explicitly or configure local.config.ps1 (see local.config.example.ps1).'
    throw "MissingSavedVariables"
}

function Get-LuaTableBlock {
    param(
        [string]$Source,
        [string]$TableName
    )

    $assignIndex = $Source.IndexOf($TableName)
    if ($assignIndex -lt 0) {
        return $null
    }
    $braceIndex = $Source.IndexOf('{', $assignIndex)
    if ($braceIndex -lt 0) {
        return $null
    }

    $depth = 0
    $i = $braceIndex
    $length = $Source.Length
    while ($i -lt $length) {
        $char = $Source[$i]
        if ($char -eq '{') {
            $depth++
        } elseif ($char -eq '}') {
            $depth--
            if ($depth -eq 0) {
                $i++
                break
            }
        }
        $i++
    }

    if ($depth -ne 0) {
        return $null
    }

    return $Source.Substring($assignIndex, $i - $assignIndex)
}

function Extract-ApidumpEntries {
    param([string]$DumpText)

    $match = [regex]::Match($DumpText, '\["APIDump"\]\s*=\s*\{([\s\S]*?)\n\s*\}\s*,?')
    if (-not $match.Success) {
        throw "APIDumpSectionNotFound"
    }

    $entriesBlock = $match.Groups[1].Value
    $entryPattern = '\[(\d+)\]\s*=\s*\{([\s\S]*?)\}\s*,?'
    $entryMatches = [regex]::Matches($entriesBlock, $entryPattern)
    $results = @()

    foreach ($entryMatch in $entryMatches) {
        $apiId = [int]$entryMatch.Groups[1].Value
        $block = $entryMatch.Groups[2].Value

        $gameItemId = $apiId
        $creatureId = 0
        $name = ''
        $description = ''
        $icon = ''

        if ($block -match '(?i)\["itemid"\]\s*=\s*(\d+)') { $gameItemId = [int]$Matches[1] }
        if ($block -match '(?i)\["creaturePreview"\]\s*=\s*(\d+)') { $creatureId = [int]$Matches[1] }
        if ($block -match '\["name"\]\s*=\s*"([^"]+)"') { $name = $Matches[1] }
        if ($block -match '\["description"\]\s*=\s*"([\s\S]*?)"') { $description = $Matches[1] }
        if ($block -match '\["icon"\]\s*=\s*"([^"]+)"') { $icon = $Matches[1] }

        $results += [pscustomobject]@{
            ApiId = $apiId
            GameItemId = $gameItemId
            Name = $name
            CreatureId = $creatureId
            Description = $description
            Icon = $icon
        }
    }

    return $results
}

# Main workflow
try {
    Step 'Resolve SavedVariables path'
    $resolvedPath = Resolve-SavedVariablesPath -ProvidedPath $SavedVariablesPath
    Ok "Using SavedVariables path: $resolvedPath"

    Step 'Load SavedVariables content'
    $rawContent = Get-Content -LiteralPath $resolvedPath -Raw
    if ([string]::IsNullOrWhiteSpace($rawContent)) {
        throw "SavedVariablesEmpty"
    }

    $ascensionDBBlock = Get-LuaTableBlock -Source $rawContent -TableName 'AscensionVanityDB'
    $ascensionDumpBlock = Get-LuaTableBlock -Source $rawContent -TableName 'AscensionVanityDump'
    if (-not $ascensionDumpBlock) {
        throw "AscensionVanityDumpMissing"
    }

    $scanVersion = 'Unknown'
    $totalItems = 0
    $lastScanDate = 'Unknown'
    if ($ascensionDumpBlock -match '\["ScanVersion"\]\s*=\s*"([^"]+)"') { $scanVersion = $Matches[1] }
    if ($ascensionDumpBlock -match '\["TotalItems"\]\s*=\s*(\d+)') { $totalItems = [int]$Matches[1] }
    if ($ascensionDumpBlock -match '\["LastScanDate"\]\s*=\s*"([^"]+)"') { $lastScanDate = $Matches[1] }

    Step 'Parse APIDump entries'
    $entries = Extract-ApidumpEntries -DumpText $ascensionDumpBlock
    if ($entries.Count -eq 0) {
        throw "NoEntriesParsed"
    }
    Ok "Parsed $($entries.Count) APIDump entries"

    $timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    if (-not (Test-Path $OutputDirectory)) {
        Step "Create output directory: $OutputDirectory"
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    }

    if (-not $NoScanCopy) {
        Step 'Emit normalized fresh scan file'
        $builder = New-Object System.Text.StringBuilder
        $null = $builder.AppendLine('-- AscensionVanity API Dump Export')
        $null = $builder.AppendLine("-- Source: $resolvedPath")
        $null = $builder.AppendLine("-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        $null = $builder.AppendLine("-- Scan Version: $scanVersion")
        $null = $builder.AppendLine("-- Total Items (reported): $totalItems")
        $null = $builder.AppendLine()
        if ($ascensionDBBlock) {
            $null = $builder.AppendLine($ascensionDBBlock.TrimEnd())
            $null = $builder.AppendLine()
        }
        $null = $builder.AppendLine($ascensionDumpBlock.TrimEnd())
        $normalizedContent = $builder.ToString()

        $scanSuffix = if ($ScanLabel) { "_${ScanLabel}" } else { '' }
        $scanFileName = "AscensionVanity_Fresh_Scan_${timestamp}${scanSuffix}.lua"
        $scanPath = Join-Path $OutputDirectory $scanFileName
        $normalizedContent | Out-File -LiteralPath $scanPath -Encoding UTF8
        Ok "Fresh scan written: $scanPath"

        $latestPath = Join-Path $OutputDirectory 'AscensionVanity_Fresh_Scan_LATEST.lua'
        $normalizedContent | Out-File -LiteralPath $latestPath -Encoding UTF8
        Info "Latest scan copy updated: $latestPath"
    }

    if (-not $SkipMappingExport) {
        Step 'Export ApiId → GameItemId mapping'
        $mappingObjects = $entries | ForEach-Object {
            [pscustomobject]@{
                ApiId = $_.ApiId
                GameItemId = $_.GameItemId
                Name = $_.Name
                CreatureId = $_.CreatureId
            }
        }
        $mappingPath = Join-Path $OutputDirectory 'API_to_GameID_Mapping.json'
        $mappingObjects | ConvertTo-Json -Depth 4 | Out-File -LiteralPath $mappingPath -Encoding UTF8
        Ok "Mapping exported: $mappingPath"

        $historyPath = Join-Path $OutputDirectory ("API_to_GameID_Mapping_${timestamp}.json")
        $mappingObjects | ConvertTo-Json -Depth 4 | Out-File -LiteralPath $historyPath -Encoding UTF8
        Info "Historical snapshot saved: $historyPath"
    } else {
        Warn 'SkipMappingExport flag set – JSON mapping not written.'
    }

    Step 'Generate summary statistics'
    $categoryCounts = @{}
    foreach ($entry in $entries) {
        $category = $entry.Name
        if ($category -and ($category -like '*:*')) {
            $category = $category.Split(':')[0].Trim()
        } elseif (-not [string]::IsNullOrWhiteSpace($category)) {
            $category = $category.Split(' ')[0]
        } else {
            $category = 'Unknown'
        }
        if (-not $categoryCounts.ContainsKey($category)) {
            $categoryCounts[$category] = 0
        }
        $categoryCounts[$category]++
    }

    $summaryLines = @()
    $summaryLines += "Ascension Vanity API Import Summary"
    $summaryLines += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $summaryLines += "Source: $resolvedPath"
    $summaryLines += "Scan Version: $scanVersion"
    $summaryLines += "Last Scan Date: $lastScanDate"
    $summaryLines += "Reported Total Items: $totalItems"
    $summaryLines += "Parsed Entries: $($entries.Count)"
    $summaryLines += ''
    $summaryLines += 'Category Breakdown:'
    foreach ($key in ($categoryCounts.Keys | Sort-Object)) {
        $summaryLines += ("  {0,-25} {1,5}" -f $key, $categoryCounts[$key])
    }

    $missingCreature = ($entries | Where-Object { $_.CreatureId -eq 0 }).Count
    $summaryLines += ''
    $summaryLines += "Entries without creature preview: $missingCreature"

    $nonDrop = ($entries | Where-Object { [string]::IsNullOrWhiteSpace($_.Description) -or -not $_.Description.StartsWith('Has a chance to drop', [System.StringComparison]::InvariantCultureIgnoreCase) }).Count
    $summaryLines += "Descriptions not matching drop pattern: $nonDrop"

    foreach ($line in $summaryLines) {
        Info $line
    }

    if (-not $SkipSummaryFile) {
        $summaryPath = Join-Path $OutputDirectory ("API_Import_Summary_${timestamp}.txt")
        $summaryLines | Out-File -LiteralPath $summaryPath -Encoding UTF8
        Info "Summary report saved: $summaryPath"
    }

    Ok 'API dump import workflow completed.'

} catch {
    Fail "Master API dump import failed: $_"
    exit 1
}
