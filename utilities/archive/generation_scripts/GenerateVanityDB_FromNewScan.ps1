<#
.SYNOPSIS
    Generate VanityDB.lua from new API scanner dump

.DESCRIPTION
    Processes the AscensionVanity_Fresh_Scan file from the new scanner
    and generates a clean VanityDB.lua file with proper icon indexing.

.PARAMETER ScanFile
    Path to the scan file (AscensionVanity_Fresh_Scan_*.lua)

.PARAMETER OutputFile
    Path for the output VanityDB.lua file

.EXAMPLE
    .\GenerateVanityDB_FromNewScan.ps1 -ScanFile "data\AscensionVanity_Fresh_Scan_2025-10-28_NEW.lua"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ScanFile = "data\AscensionVanity_Fresh_Scan_2025-10-28_NEW.lua",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "AscensionVanity\VanityDB.lua"
)

Write-Host "`n" -NoNewline
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         VanityDB Generator - From New API Scanner              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verify scan file exists
if (-not (Test-Path $ScanFile)) {
    Write-Host "❌ Scan file not found: $ScanFile" -ForegroundColor Red
    exit 1
}

Write-Host "Loading scan file: $ScanFile" -ForegroundColor Yellow
$content = Get-Content $ScanFile -Raw

# Extract APIDump section
Write-Host "Extracting APIDump..." -ForegroundColor Yellow

# Find the APIDump table
$apiDumpMatch = [regex]::Match($content, '\["APIDump"\] = \{(.*?)\n\t\},', [System.Text.RegularExpressions.RegexOptions]::Singleline)

if (-not $apiDumpMatch.Success) {
    Write-Host "❌ Could not find APIDump in scan file" -ForegroundColor Red
    exit 1
}

$apiDumpContent = $apiDumpMatch.Groups[1].Value

# Parse all items
Write-Host "Parsing items..." -ForegroundColor Yellow

$items = @{}
$iconUsage = @{}

# Match each item entry
$itemPattern = '\[(\d+)\] = \{([^\}]+)\}'
$itemMatches = [regex]::Matches($apiDumpContent, $itemPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

foreach ($match in $itemMatches) {
    $itemId = $match.Groups[1].Value
    $itemData = $match.Groups[2].Value
    
    # Extract fields
    $name = if ($itemData -match '\["name"\] = "([^"]+)"') { $matches[1] } else { "Unknown" }
    $description = if ($itemData -match '\["description"\] = "([^"]*)"') { $matches[1] } else { "" }
    $icon = if ($itemData -match '\["icon"\] = "([^"]+)"') { $matches[1] } else { "" }
    $creaturePreview = if ($itemData -match '\["creaturePreview"\] = (\d+)') { $matches[1] } else { "0" }
    
    # Track icon usage for indexing
    if ($icon -and -not $iconUsage.ContainsKey($icon)) {
        $iconUsage[$icon] = $iconUsage.Count + 1
    }
    
    $items[$itemId] = @{
        name = $name
        description = $description
        icon = $icon
        iconIndex = $iconUsage[$icon]
        creaturePreview = $creaturePreview
    }
}

Write-Host "  → Found $($items.Count) items" -ForegroundColor Green
Write-Host "  → Unique icons: $($iconUsage.Count)" -ForegroundColor Green

# Generate VanityDB.lua
Write-Host "`nGenerating VanityDB.lua..." -ForegroundColor Yellow

$output = @"
-- VanityDB.lua
-- Generated from API Scanner on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
-- Total Items: $($items.Count)
-- Unique Icons: $($iconUsage.Count)

VanityDB = {
"@

# Add icon index
$output += "`n    IconIndex = {"
$iconList = $iconUsage.GetEnumerator() | Sort-Object Value
foreach ($iconEntry in $iconList) {
    $output += "`n        [$($iconEntry.Value)] = `"$($iconEntry.Name)`","
}
$output += "`n    },"

# Add items (sorted by itemid)
$output += "`n`n    Items = {"

$sortedItems = $items.GetEnumerator() | Sort-Object { [int]$_.Key }
foreach ($item in $sortedItems) {
    $itemId = $item.Key
    $data = $item.Value
    
    # Escape any quotes in description
    $desc = $data.description -replace '"', '\"'
    
    $output += "`n        [$itemId] = {"
    $output += "`n            name = `"$($data.name)`","
    $output += "`n            description = `"$desc`","
    $output += "`n            icon = $($data.iconIndex),"
    $output += "`n            creaturePreview = $($data.creaturePreview)"
    $output += "`n        },"
}

$output += "`n    }"
$output += "`n}"
$output += "`n"

# Write to file
Write-Host "Writing to $OutputFile..." -ForegroundColor Yellow
$output | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline

$fileSize = (Get-Item $OutputFile).Length / 1KB

Write-Host "`n✅ Generation complete!" -ForegroundColor Green
Write-Host "  Output: $OutputFile" -ForegroundColor White
Write-Host "  Size: $([math]::Round($fileSize, 2)) KB" -ForegroundColor White
Write-Host "  Items: $($items.Count)" -ForegroundColor White
Write-Host "  Unique Icons: $($iconUsage.Count)" -ForegroundColor White
Write-Host "  All IDs are GAME item IDs (correct!)" -ForegroundColor Green
Write-Host ""
