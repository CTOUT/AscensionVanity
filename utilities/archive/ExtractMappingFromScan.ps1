<#
.SYNOPSIS
    Extract API_to_GameID_Mapping.json from fresh scan export
.DESCRIPTION
    Fast extraction script that processes large scan files efficiently
    without regex timeouts. Extracts item ID, name, and creature ID.
#>

param(
    [string]$ScanFile = ".\data\AscensionVanity.lua",
    [string]$OutputFile = ".\data\API_to_GameID_Mapping.json"
)

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Extract Mapping from Fresh Scan (Fast Parser)           ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

if (!(Test-Path $ScanFile)) {
    Write-Error "Scan file not found: $ScanFile"
    exit 1
}

Write-Host "Parsing items (streaming mode - efficient for large files)..." -ForegroundColor Yellow

$items = @()
$itemCount = 0
$inApiDump = $false
$inItem = $false
$currentItem = @{}

# Stream file line-by-line (memory efficient)
Get-Content $ScanFile | ForEach-Object {
    $line = $_
    
    # Detect APIDump section
    if ($line -match '\["APIDump"\]\s*=\s*\{') {
        $inApiDump = $true
        return
    }
    
    if (-not $inApiDump) { return }
    # Start of item entry
    if ($line -match '^\s*\[(\d+)\]\s*=\s*\{') {
        $inItem = $true
        $currentItem = @{
            GameItemId = [int]$matches[1]
            ApiId = [int]$matches[1]
            Name = ""
            CreatureId = 0
        }
    }
    # Extract fields
    elseif ($inItem) {
        if ($line -match '\["name"\]\s*=\s*"([^"]+)"') {
            $currentItem.Name = $matches[1]
        }
        elseif ($line -match '\["creaturePreview"\]\s*=\s*(\d+)') {
            $currentItem.CreatureId = [int]$matches[1]
        }
        elseif ($line -match '\["itemid"\]\s*=\s*(\d+)') {
            $currentItem.GameItemId = [int]$matches[1]
        }
        # End of item entry
        elseif ($line -match '^\s*\},?\s*$') {
            if ($currentItem.Name) {
                $items += [pscustomobject]@{
                    ApiId = $currentItem.ApiId
                    GameItemId = $currentItem.GameItemId
                    Name = $currentItem.Name
                    CreatureId = $currentItem.CreatureId
                }
                $itemCount++
                if ($itemCount % 500 -eq 0) {
                    Write-Host "  Processed $itemCount items..." -ForegroundColor Gray
                }
            }
            $inItem = $false
        }
    }
    # End of APIDump section (outer brace)
    if ($line -match '^\s*\}\s*,?\s*$' -and -not $inItem) {
        $inApiDump = $false
    }
}

Write-Host "Extracted $itemCount items" -ForegroundColor Green

# Sort by GameItemId for consistency
$items = $items | Sort-Object GameItemId

Write-Host "Writing to $OutputFile..." -ForegroundColor Yellow
$items | ConvertTo-Json -Depth 4 | Out-File $OutputFile -Encoding UTF8

Write-Host "`n✓ Mapping file created successfully!" -ForegroundColor Green
Write-Host "  File: $OutputFile" -ForegroundColor Cyan
Write-Host "  Items: $itemCount" -ForegroundColor Cyan

# Create timestamped backup
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupFile = $OutputFile -replace '\.json$', "_$timestamp.json"
Copy-Item $OutputFile $backupFile
Write-Host "  Backup: $backupFile" -ForegroundColor Gray

Write-Host "`nVerifying sample items..." -ForegroundColor Yellow
$testItems = @(79581, 79582, 79583, 79584, 79585, 79586)
$mapping = $items | Where-Object { $_.GameItemId -in $testItems }
$mapping | Format-Table GameItemId, Name, CreatureId -AutoSize

Write-Host "`nDone!" -ForegroundColor Green
