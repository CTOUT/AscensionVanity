<#
.SYNOPSIS
    Normalize description formatting for consistency

.DESCRIPTION
    Standardizes description text:
    - Replace "with" → "within" for location references
    - Ensure all descriptions end with a period
    - Consistent spacing and capitalization
    
    WORKFLOW:
    1. Load MasterFullValidated.json
    2. Normalize description formatting
    3. Save normalized JSON

.PARAMETER DryRun
    Test mode - show what would be done without making changes

.EXAMPLE
    .\NormalizeDescriptions.ps1
    Standard execution

.EXAMPLE
    .\NormalizeDescriptions.ps1 -DryRun
    Test mode (show changes without saving)

.NOTES
    Author: CMTout
    Last Updated: 2025-11-04
#>

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Paths
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath
$dataPath = Join-Path $rootPath "data"
$masterJsonPath = Join-Path $dataPath "MasterFullValidated.json"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Description Normalization Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN MODE] No changes will be saved" -ForegroundColor Yellow
    Write-Host ""
}

# Validate source file exists
if (-not (Test-Path $masterJsonPath)) {
    Write-Host "[ERROR] Source file not found: $masterJsonPath" -ForegroundColor Red
    exit 1
}

# Load source data
Write-Host "[1/3] Loading source data..." -ForegroundColor Green
$items = Get-Content $masterJsonPath -Raw | ConvertFrom-Json
Write-Host "  Loaded $($items.Count) items" -ForegroundColor Gray

# Normalize descriptions
Write-Host ""
Write-Host "[2/3] Normalizing descriptions..." -ForegroundColor Green

$changedCount = 0
$changes = @()

foreach ($item in $items) {
    if (-not $item.Description) {
        continue
    }
    
    $originalDesc = $item.Description
    $newDesc = $originalDesc
    
    # Normalize "with" to "within" for location references
    # Pattern: "with Zone" → "within Zone"
    # But NOT: "with a chance" (keep this as-is)
    if ($newDesc -match '\bwith\s+([A-Z][^.,!?]*?)(?:\s|$)' -and $newDesc -notmatch 'with a chance') {
        $newDesc = $newDesc -replace '\bwith\s+([A-Z])', 'within $1'
    }
    
    # Ensure description ends with a period
    if (-not $newDesc.EndsWith('.')) {
        $newDesc = $newDesc.TrimEnd() + '.'
    }
    
    # Remove double periods
    $newDesc = $newDesc -replace '\.\.+', '.'
    
    # Trim whitespace
    $newDesc = $newDesc.Trim()
    
    # Check if changed
    if ($newDesc -ne $originalDesc) {
        $changedCount++
        $item.Description = $newDesc
        
        $changes += [PSCustomObject]@{
            ItemId = $item.DbItemId
            Name = $item.Name
            Before = $originalDesc
            After = $newDesc
        }
    }
}

Write-Host "  Normalized $changedCount descriptions" -ForegroundColor Gray

# Show sample changes
if ($changes.Count -gt 0) {
    Write-Host ""
    Write-Host "Sample Changes (first 10):" -ForegroundColor Cyan
    $changes | Select-Object -First 10 | ForEach-Object {
        Write-Host ""
        Write-Host "[$($_.ItemId)] $($_.Name)" -ForegroundColor White
        Write-Host "  Before: $($_.Before)" -ForegroundColor Yellow
        Write-Host "  After:  $($_.After)" -ForegroundColor Green
    }
}

# Statistics
Write-Host ""
Write-Host "[3/3] Generating statistics..." -ForegroundColor Green

$withDescCount = ($items | Where-Object { $_.Description }).Count
$withPeriodCount = ($items | Where-Object { $_.Description -and $_.Description.EndsWith('.') }).Count

Write-Host "  Items with descriptions: $withDescCount" -ForegroundColor Gray
Write-Host "  Descriptions ending with period: $withPeriodCount ($([math]::Round($withPeriodCount/$withDescCount*100,1))%)" -ForegroundColor Gray
Write-Host "  Descriptions normalized: $changedCount" -ForegroundColor Gray

# Save normalized data
if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY RUN] Would save to: $masterJsonPath" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Saving normalized data..." -ForegroundColor Green
    
    # Backup original
    $backupPath = "$masterJsonPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $masterJsonPath $backupPath
    Write-Host "  Backup saved to: $backupPath" -ForegroundColor Gray
    
    # Save normalized data
    $items | ConvertTo-Json -Depth 10 | Set-Content $masterJsonPath -Encoding UTF8
    Write-Host "  Saved to: $masterJsonPath" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Normalization Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total Items: $($items.Count)" -ForegroundColor Gray
Write-Host "  Descriptions Normalized: $changedCount" -ForegroundColor Green
Write-Host "  Changes Made:" -ForegroundColor Gray
Write-Host "    - 'with Zone' → 'within Zone': $(($changes | Where-Object { $_.Before -match '\bwith\s+[A-Z]' }).Count)" -ForegroundColor Gray
Write-Host "    - Added periods: $(($changes | Where-Object { -not $_.Before.EndsWith('.') }).Count)" -ForegroundColor Gray
Write-Host ""

if (-not $DryRun) {
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Re-run zone enrichment:" -ForegroundColor Gray
    Write-Host "     .\utilities\EnrichZoneData.ps1" -ForegroundColor White
    Write-Host "  2. Regenerate database:" -ForegroundColor Gray
    Write-Host "     .\utilities\GenerateVanityDB_Master.ps1" -ForegroundColor White
    Write-Host ""
}
