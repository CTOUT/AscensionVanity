<#
.SYNOPSIS
    Fast extraction of API_to_GameID_Mapping from fresh scan
.DESCRIPTION
    Uses optimized regex pattern matching to extract items quickly
#>

param(
    [string]$ScanFile = ".\data\AscensionVanity.lua.bak",
    [string]$OutputFile = ".\data\sources\API_to_GameID_Mapping.json"
)

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Extract Mapping from Fresh Scan (Fast Parser)           ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

if (!(Test-Path $ScanFile)) {
    Write-Error "Scan file not found: $ScanFile"
    exit 1
}

Write-Host "Reading scan file..." -ForegroundColor Yellow
$content = Get-Content $ScanFile -Raw

Write-Host "Extracting items..." -ForegroundColor Yellow

# Pattern to match each item block
$pattern = '\[(\d+)\]\s*=\s*\{[^\}]*?\["name"\]\s*=\s*"([^"]+)"[^\}]*?\["creaturePreview"\]\s*=\s*(\d+)'

$matches = [regex]::Matches($content, $pattern)
Write-Host "Found $($matches.Count) items" -ForegroundColor Green

$items = @()
foreach ($match in $matches) {
    $items += [pscustomobject]@{
        ApiId = [int]$match.Groups[1].Value
        GameItemId = [int]$match.Groups[1].Value  
        Name = $match.Groups[2].Value
        CreatureId = [int]$match.Groups[3].Value
    }
}

# Sort by GameItemId
$items = $items | Sort-Object GameItemId

Write-Host "Writing to $OutputFile..." -ForegroundColor Yellow
$items | ConvertTo-Json -Depth 4 | Out-File $OutputFile -Encoding UTF8

Write-Host "`n✓ Mapping file created successfully!" -ForegroundColor Green
Write-Host "  File: $OutputFile" -ForegroundColor Cyan
Write-Host "  Items: $($items.Count)" -ForegroundColor Cyan

# Create timestamped backup
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupFile = $OutputFile -replace '\.json$', "_$timestamp.json"
Copy-Item $OutputFile $backupFile
Write-Host "  Backup: $backupFile" -ForegroundColor Gray

# Generate validation checksum (integrity check)
Write-Host "`nGenerating validation checksum..." -ForegroundColor Yellow
$checksum = (Get-FileHash $OutputFile -Algorithm SHA256).Hash
$validation = @{
    ChecksumSHA256 = $checksum
    ItemCount = $items.Count
    GeneratedDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    SourceFile = (Resolve-Path $ScanFile).Path
    ExtractedBy = $env:USERNAME
} | ConvertTo-Json -Depth 4

$validationFile = "$OutputFile.validation.json"
$validation | Out-File $validationFile -Encoding UTF8
Write-Host "  Validation: $validationFile" -ForegroundColor Gray

Write-Host "`n⚠️  IMPORTANT: This file is IMMUTABLE - do not edit directly!" -ForegroundColor Yellow
Write-Host "   For corrections, use: data\corrections\CreatureIdCorrections.json" -ForegroundColor Cyan

Write-Host "`nVerifying sample items (79581-79586)..." -ForegroundColor Yellow
$testItems = @(79581, 79582, 79583, 79584, 79585, 79586)
$mapping = $items | Where-Object { $_.GameItemId -in $testItems }
$mapping | Format-Table GameItemId, Name, CreatureId -AutoSize

Write-Host "`nDone!" -ForegroundColor Green
