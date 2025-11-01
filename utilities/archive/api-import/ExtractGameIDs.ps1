# Extract Game IDs from Fresh Scan APIDump
# This extracts the CORRECT game item IDs from the raw API data

param(
    [string]$FreshScan = "data\AscensionVanity_Fresh_Scan_2025-10-28_111305.lua",
    [string]$OutputMapping = "data\API_to_GameID_Mapping.json"
)

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          Extract Game Item IDs from API Dump                    ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Reading Fresh Scan file (this may take a moment)..." -ForegroundColor Yellow
$content = Get-Content $FreshScan -Raw

Write-Host "Extracting APIDump section..." -ForegroundColor Yellow

# Parse the APIDump entries
$mapping = @{}
$apiId = 0
$inAPIDump = $false
$inEntry = $false
$currentGameId = $null
$currentName = $null

foreach ($line in ($content -split "`n")) {
    # Detect APIDump section start
    if ($line -match '\["APIDump"\] = \{') {
        $inAPIDump = $true
        Write-Host "  Found APIDump section" -ForegroundColor Green
        continue
    }
    
    if (-not $inAPIDump) { continue }
    
    # Detect entry start
    if ($line -match '^\s*\{') {
        $inEntry = $true
        $currentGameId = $null
        $currentName = $null
        continue
    }
    
    if ($inEntry) {
        # Extract game itemid from rawData (lowercase "itemid")
        if ($line -match '^\s+\["itemid"\] = (\d+)') {
            $currentGameId = [int]$matches[1]
        }
        
        # Extract API itemId (camelCase "itemId", outside rawData)
        if ($line -match '^\s*\["itemId"\] = (\d+)') {
            $apiId = [int]$matches[1]
        }
        
        # Extract name (outside rawData, after itemId)
        if ($line -match '^\s*\["name"\] = "([^"]+)"' -and $apiId -and -not $currentName) {
            $currentName = $matches[1]
        }
        
        # Entry complete
        if ($line -match '^\s*\},?\s*--\s*\[\d+\]') {
            if ($currentGameId -and $apiId -and $currentName) {
                $mapping[$apiId] = @{
                    GameItemId = $currentGameId
                    Name = $currentName
                }
            }
            $inEntry = $false
            
            # Progress indicator
            if ($apiId % 1000 -eq 0) {
                Write-Host "  Processed $apiId items..." -ForegroundColor Gray
            }
        }
    }
    
    # End of APIDump
    if ($line -match '^\s*\},\s*--\s*\["APIDump"\]') {
        $inAPIDump = $false
        break
    }
}

Write-Host "`n✅ Extraction complete!" -ForegroundColor Green
Write-Host "  Total mappings: $($mapping.Count)" -ForegroundColor Cyan

# Convert to JSON for easy use
Write-Host "`nSaving mapping to JSON..." -ForegroundColor Yellow
$jsonMapping = @()
foreach ($apiId in ($mapping.Keys | Sort-Object)) {
    $jsonMapping += [PSCustomObject]@{
        ApiId = $apiId
        GameItemId = $mapping[$apiId].GameItemId
        Name = $mapping[$apiId].Name
    }
}

$jsonMapping | ConvertTo-Json | Set-Content $OutputMapping -Encoding UTF8

Write-Host "  Saved to: $OutputMapping" -ForegroundColor Green

# Show sample
Write-Host "`nSample mappings:" -ForegroundColor Cyan
$jsonMapping | Select-Object -First 10 | Format-Table -AutoSize

Write-Host "`n✅ Complete! Use this mapping for database generation." -ForegroundColor Green
Write-Host ""
