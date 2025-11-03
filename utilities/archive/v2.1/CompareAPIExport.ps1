# CompareAPIExport.ps1
# Compares exported API data with current VanityDB.lua static database
# Usage: .\CompareAPIExport.ps1

param(
    [string]$SavedVariablesPath = "$env:USERPROFILE\AppData\Local\Ascension Launcher\World of Warcraft\WTF\Account\YOUR_ACCOUNT\SavedVariables\AscensionVanity.lua",
    [string]$VanityDBPath = ".\AscensionVanity\VanityDB.lua"
)

Write-Host "=== AscensionVanity API Export Comparison Tool ===" -ForegroundColor Cyan
Write-Host ""

# Check if files exist
if (-not (Test-Path $SavedVariablesPath)) {
    Write-Host "Error: SavedVariables file not found at: $SavedVariablesPath" -ForegroundColor Red
    Write-Host "Please update the path or run '/av apidump' and '/av export' in-game first" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $VanityDBPath)) {
    Write-Host "Error: VanityDB.lua not found at: $VanityDBPath" -ForegroundColor Red
    exit 1
}

Write-Host "Reading SavedVariables..." -ForegroundColor Yellow
$savedVarsContent = Get-Content $SavedVariablesPath -Raw

Write-Host "Reading VanityDB.lua..." -ForegroundColor Yellow
$vanityDBContent = Get-Content $VanityDBPath -Raw

# Extract creature IDs from both sources
Write-Host "Parsing data structures..." -ForegroundColor Yellow

# Parse SavedVariables for ExportedData entries
$apiCreatures = @{}
if ($savedVarsContent -match '(?s)AscensionVanityDB.*?ExportedData.*?entries.*?\{(.*?)\}') {
    $exportEntries = $matches[1]
    
    # Parse each entry: [creatureID] = itemID or {itemID1, itemID2}
    $exportEntries -split "`n" | ForEach-Object {
        if ($_ -match '\[(\d+)\]\s*=\s*(\{[^}]+\}|\d+)') {
            $creatureID = $matches[1]
            $itemValue = $matches[2]
            $apiCreatures[$creatureID] = $itemValue
        }
    }
}

# Parse VanityDB.lua for AV_VanityItems
$dbCreatures = @{}
if ($vanityDBContent -match '(?s)AV_VanityItems\s*=\s*\{(.*?)^function') {
    $dbEntries = $matches[1]
    
    # Parse each entry
    $dbEntries -split "`n" | ForEach-Object {
        if ($_ -match '\[(\d+)\]\s*=\s*(\{[^}]+\}|\d+)') {
            $creatureID = $matches[1]
            $itemValue = $matches[2]
            $dbCreatures[$creatureID] = $itemValue
        }
    }
}

Write-Host ""
Write-Host "=== Comparison Results ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "API Export creatures: $($apiCreatures.Count)" -ForegroundColor White
Write-Host "Static DB creatures: $($dbCreatures.Count)" -ForegroundColor White
Write-Host ""

# Find differences
$apiOnly = @()
$dbOnly = @()
$mismatches = @()
$matches = 0

# Check API creatures against DB
foreach ($creatureID in $apiCreatures.Keys) {
    if ($dbCreatures.ContainsKey($creatureID)) {
        if ($apiCreatures[$creatureID] -eq $dbCreatures[$creatureID]) {
            $matches++
        } else {
            $mismatches += [PSCustomObject]@{
                CreatureID = $creatureID
                APIValue = $apiCreatures[$creatureID]
                DBValue = $dbCreatures[$creatureID]
            }
        }
    } else {
        $apiOnly += [PSCustomObject]@{
            CreatureID = $creatureID
            Value = $apiCreatures[$creatureID]
        }
    }
}

# Check DB creatures not in API
foreach ($creatureID in $dbCreatures.Keys) {
    if (-not $apiCreatures.ContainsKey($creatureID)) {
        $dbOnly += [PSCustomObject]@{
            CreatureID = $creatureID
            Value = $dbCreatures[$creatureID]
        }
    }
}

# Display results
Write-Host "Exact matches: $matches" -ForegroundColor Green
Write-Host "Mismatches: $($mismatches.Count)" -ForegroundColor Yellow
Write-Host "API only: $($apiOnly.Count)" -ForegroundColor Cyan
Write-Host "DB only: $($dbOnly.Count)" -ForegroundColor Magenta
Write-Host ""

# Show samples
if ($mismatches.Count -gt 0) {
    Write-Host "=== Mismatches (showing first 10) ===" -ForegroundColor Yellow
    $mismatches | Select-Object -First 10 | ForEach-Object {
        Write-Host "Creature $($_.CreatureID):" -ForegroundColor White
        Write-Host "  API: $($_.APIValue)" -ForegroundColor Cyan
        Write-Host "  DB:  $($_.DBValue)" -ForegroundColor Magenta
    }
    Write-Host ""
}

if ($apiOnly.Count -gt 0) {
    Write-Host "=== In API but not in DB (showing first 10) ===" -ForegroundColor Cyan
    $apiOnly | Select-Object -First 10 | ForEach-Object {
        Write-Host "Creature $($_.CreatureID): $($_.Value)" -ForegroundColor White
    }
    Write-Host ""
}

if ($dbOnly.Count -gt 0) {
    Write-Host "=== In DB but not in API (showing first 10) ===" -ForegroundColor Magenta
    $dbOnly | Select-Object -First 10 | ForEach-Object {
        Write-Host "Creature $($_.CreatureID): $($_.Value)" -ForegroundColor White
    }
    Write-Host ""
}

# Export full results to CSV
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputDir = ".\utilities\comparison_results"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

if ($mismatches.Count -gt 0) {
    $mismatchFile = "$outputDir\mismatches_$timestamp.csv"
    $mismatches | Export-Csv -Path $mismatchFile -NoTypeInformation
    Write-Host "Mismatches saved to: $mismatchFile" -ForegroundColor Yellow
}

if ($apiOnly.Count -gt 0) {
    $apiOnlyFile = "$outputDir\api_only_$timestamp.csv"
    $apiOnly | Export-Csv -Path $apiOnlyFile -NoTypeInformation
    Write-Host "API-only items saved to: $apiOnlyFile" -ForegroundColor Cyan
}

if ($dbOnly.Count -gt 0) {
    $dbOnlyFile = "$outputDir\db_only_$timestamp.csv"
    $dbOnly | Export-Csv -Path $dbOnlyFile -NoTypeInformation
    Write-Host "DB-only items saved to: $dbOnlyFile" -ForegroundColor Magenta
}

Write-Host ""
Write-Host "=== Comparison Complete ===" -ForegroundColor Green
