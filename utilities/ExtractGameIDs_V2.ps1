# Extract Game IDs from Fresh Scan APIDump - V2
# Correctly parses rawData itemid vs top-level itemId

param(
    [string]$FreshScan = "data\AscensionVanity_Fresh_Scan_2025-10-28_111305.lua",
    [string]$OutputMapping = "data\API_to_GameID_Mapping.json"
)

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          Extract Game Item IDs from API Dump V2                 ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Reading Fresh Scan file..." -ForegroundColor Yellow
$content = Get-Content $FreshScan -Raw

Write-Host "Parsing APIDump entries..." -ForegroundColor Yellow

# Use regex to find all complete entries
$pattern = '(?s)\["itemLink"\] = "([^"]*)".*?\["rawData"\] = \{.*?\["itemid"\] = (\d+),.*?\["creaturePreview"\] = (\d+),.*?\["name"\] = "([^"]+)".*?\["itemId"\] = (\d+),'

$regexMatches = [regex]::Matches($content, $pattern)

Write-Host "  Found $($regexMatches.Count) entries" -ForegroundColor Green

$mapping = @()
$combatPetCount = 0

foreach ($match in $regexMatches) {
    $gameItemId = [int]$match.Groups[2].Value
    $creatureId = [int]$match.Groups[3].Value
    $name = $match.Groups[4].Value
    $apiId = [int]$match.Groups[5].Value
    
    # Track combat pets
    if ($creatureId -gt 0) {
        $combatPetCount++
    }
    
    $mapping += [PSCustomObject]@{
        ApiId = $apiId
        GameItemId = $gameItemId
        Name = $name
        CreatureId = $creatureId
    }
    
    if ($apiId % 1000 -eq 0) {
        Write-Host "  Processed $apiId items..." -ForegroundColor Gray
    }
}

Write-Host "`n✅ Extraction complete!" -ForegroundColor Green
Write-Host "  Total items: $($mapping.Count)" -ForegroundColor Cyan
Write-Host "  Combat pets (creatureId > 0): $combatPetCount" -ForegroundColor Cyan

# Save to JSON
Write-Host "`nSaving to JSON..." -ForegroundColor Yellow
$mapping | ConvertTo-Json | Set-Content $OutputMapping -Encoding UTF8
Write-Host "  Saved to: $OutputMapping" -ForegroundColor Green

# Verify Forest Spider
Write-Host "`nVerifying known items:" -ForegroundColor Cyan
$spider = $mapping | Where-Object { $_.Name -like "*Forest Spider*" }
if ($spider) {
    Write-Host "  Forest Spider:" -ForegroundColor White
    Write-Host "    API ID: $($spider.ApiId)" -ForegroundColor Gray
    Write-Host "    Game ID: $($spider.GameItemId)" -ForegroundColor Gray
    Write-Host "    Creature: $($spider.CreatureId)" -ForegroundColor Gray
    
    if ($spider.GameItemId -eq 79317) {
        Write-Host "    ✅ CORRECT!" -ForegroundColor Green
    } else {
        Write-Host "    ❌ Expected 79317, got $($spider.GameItemId)" -ForegroundColor Red
    }
}

Write-Host "`n✅ Complete!" -ForegroundColor Green
Write-Host ""
