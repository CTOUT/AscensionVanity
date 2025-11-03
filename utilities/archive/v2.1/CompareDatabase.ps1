# Compare Web-Scraped Database vs Game Client Export
# This script identifies mistakes and omissions in VanityDB.lua

param(
    [switch]$ShowMissing,
    [switch]$ShowAll
)

# Import local configuration
. .\local.config.ps1

Write-Host "`n🔍 Database Comparison Analysis" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Gray

# Import the SavedVariables data
Write-Host "`n📥 Loading game client export..." -ForegroundColor Yellow
.\ImportResults.ps1 | Out-Null

$apiData = Get-Content ".\data\AscensionVanity_SavedVariables.lua" -Raw

# Count API items (from the apiOnly section)
$apiItems = [regex]::Matches($apiData, '\["creatureID"\]\s*=\s*(\d+)')
Write-Host "   Game API Total: $($apiItems.Count) items" -ForegroundColor Cyan

# Count database items
Write-Host "`n📚 Loading web-scraped database..." -ForegroundColor Yellow
$dbContent = Get-Content ".\AscensionVanity\VanityDB.lua" -Raw
$dbEntries = [regex]::Matches($dbContent, '\[(\d+)\]\s*=\s*{')
Write-Host "   VanityDB.lua Total: $($dbEntries.Count) items" -ForegroundColor Cyan

# Calculate difference
$missing = $apiItems.Count - $dbEntries.Count
Write-Host "`n📊 COMPARISON RESULTS:" -ForegroundColor Yellow
Write-Host "   Missing from database: $missing items" -ForegroundColor Red
Write-Host "   Coverage: $([math]::Round(($dbEntries.Count / $apiItems.Count) * 100, 1))%" -ForegroundColor $(if ($missing -gt 100) { "Red" } else { "Green" })

if ($ShowMissing -or $ShowAll) {
    Write-Host "`n❌ Sample Missing Items (first 20):" -ForegroundColor Red
    
    $sampleItems = [regex]::Matches($apiData, '{\s*\["itemID"\]\s*=\s*(\d+),\s*\["name"\]\s*=\s*"([^"]+)",\s*\["creatureID"\]\s*=\s*(\d+)') | Select-Object -First 20
    
    foreach ($match in $sampleItems) {
        $itemId = $match.Groups[1].Value
        $itemName = $match.Groups[2].Value
        $creatureId = $match.Groups[3].Value
        
        Write-Host "   Item $itemId`: $itemName (Creature: $creatureId)" -ForegroundColor Gray
    }
}

Write-Host "`n💡 RECOMMENDATION:" -ForegroundColor Yellow
Write-Host "   The web-scraped database is INCOMPLETE." -ForegroundColor White
Write-Host "   You should regenerate VanityDB.lua using the game API data." -ForegroundColor White
Write-Host "`n   Run: .\utilities\UpdateDatabaseFromAPI.ps1" -ForegroundColor Cyan
Write-Host ""
