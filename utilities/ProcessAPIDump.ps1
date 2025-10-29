# ProcessAPIDump.ps1
# Processes the AscensionVanity_Dump.lua file from in-game API scan
# Converts it to the format expected by the database generation utilities

param(
    [string]$DumpFile = "data\AscensionVanity_Dump.lua",
    [string]$OutputFile = "data\AscensionVanity.lua",
    [switch]$KeepOriginal = $true
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Process API Dump" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if dump file exists
if (-not (Test-Path $DumpFile)) {
    Write-Host "❌ Error: Dump file not found: $DumpFile" -ForegroundColor Red
    Write-Host "`nExpected location:" -ForegroundColor Yellow
    Write-Host "  WTF\Account\<your-account>\SavedVariables\AscensionVanity_Dump.lua" -ForegroundColor Gray
    Write-Host "`nDid you:" -ForegroundColor Yellow
    Write-Host "  1. Run /avscan scan in-game?" -ForegroundColor White
    Write-Host "  2. Exit WoW to save the data?" -ForegroundColor White
    Write-Host "  3. Copy AscensionVanity_Dump.lua to the data\ folder?`n" -ForegroundColor White
    exit 1
}

Write-Host "Reading dump file: $DumpFile" -ForegroundColor Cyan

# Read the dump file
$content = Get-Content $DumpFile -Raw

# Extract metadata
$lastScanDate = "Unknown"
$totalItems = 0
$scanVersion = "Unknown"

if ($content -match '\["LastScanDate"\]\s*=\s*"([^"]+)"') {
    $lastScanDate = $matches[1]
}

if ($content -match '\["TotalItems"\]\s*=\s*(\d+)') {
    $totalItems = [int]$matches[1]
}

if ($content -match '\["ScanVersion"\]\s*=\s*"([^"]+)"') {
    $scanVersion = $matches[1]
}

Write-Host "`nDump Metadata:" -ForegroundColor Green
Write-Host "  Last Scan: $lastScanDate" -ForegroundColor White
Write-Host "  Total Items: $totalItems" -ForegroundColor White
Write-Host "  Scan Version: $scanVersion" -ForegroundColor White

# Transform the dump file to the expected format
Write-Host "`nTransforming to standard format..." -ForegroundColor Cyan

# The dump file has:
# AscensionVanityDump = {
#   APIDump = { ... },
#   ValidationResults = { ... }
# }
#
# We need to convert it to:
# AscensionVanityDB = {
#   APIDump = { ... },
#   ValidationResults = { ... }
# }

$transformedContent = $content -replace 'AscensionVanityDump\s*=', 'AscensionVanityDB ='

# Write to output file
Write-Host "Writing to: $OutputFile" -ForegroundColor Cyan
$transformedContent | Out-File $OutputFile -Encoding UTF8

Write-Host "`n✅ Dump processing complete!" -ForegroundColor Green

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "  1. Run: .\utilities\AnalyzeAPIDump.ps1 -Detailed" -ForegroundColor White
Write-Host "  2. Run: .\utilities\ValidateAndEnrichEmptyDescriptions.ps1" -ForegroundColor White
Write-Host "  3. Run: .\utilities\GenerateVanityDB_V2.ps1" -ForegroundColor White
Write-Host "  4. Run: .\DeployAddon.ps1`n" -ForegroundColor White

# Show file sizes
$dumpSize = (Get-Item $DumpFile).Length
$outputSize = (Get-Item $OutputFile).Length

Write-Host "File Sizes:" -ForegroundColor Cyan
Write-Host "  Dump: $([math]::Round($dumpSize / 1MB, 2)) MB" -ForegroundColor White
Write-Host "  Output: $([math]::Round($outputSize / 1MB, 2)) MB`n" -ForegroundColor White
