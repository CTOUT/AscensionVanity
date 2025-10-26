# Count items by vanity category in generated database
# This helps compare database contents with in-game menu

$luaFile = "$PSScriptRoot\AscensionVanity\VanityDB.lua"

if (-not (Test-Path $luaFile)) {
    Write-Host "ERROR: VanityDB.lua not found!" -ForegroundColor Red
    Write-Host "Expected path: $luaFile" -ForegroundColor Yellow
    Write-Host "Make sure the file exists in the AscensionVanity subdirectory" -ForegroundColor Yellow
    exit
}

Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Vanity Items by Category" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$content = Get-Content $luaFile -Raw

# Define category patterns (based on typical naming conventions)
$categories = @{
    "Beastmaster's Whistles" = "Beastmaster's Whistle"
    "Draconic Warhorns" = "Draconic Warhorn"
    "Summoner's Stones" = "Summoner's Stone"
    "Blood Soaked Vellums" = "Blood Soaked Vellum"
    "Elemental Lodestones" = "Elemental Lodestone"
    "Necromantic Skulls" = "Necromantic Skull"
    "Chromatic Orbs" = "Chromatic Orb"
    "Unknown/Other" = ".*"  # Catch-all
}

$results = @{}
$totalCounted = 0

foreach ($category in $categories.Keys) {
    $pattern = $categories[$category]
    $matches = [regex]::Matches($content, "--.*$pattern", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $count = $matches.Count
    
    if ($count -gt 0) {
        $results[$category] = $count
        $totalCounted += $count
        
        Write-Host (" {0,-25}: {1,5} items" -f $category, $count) -ForegroundColor Green
        
        # Show first few examples
        if ($matches.Count -le 3) {
            foreach ($match in $matches) {
                $line = $match.Value -replace '--\s*', '  → '
                Write-Host "    $line" -ForegroundColor Gray
            }
        }
    }
}

Write-Host ""
Write-Host "─────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host (" {0,-25} {1,5} items" -f "Total Categorized:", $totalCounted) -ForegroundColor Cyan

# Count total entries in database
$totalEntries = ([regex]::Matches($content, '\[\d+\]\s*=\s*\d+')).Count
Write-Host (" {0,-25} {1,5} items" -f "Total in Database:", $totalEntries) -ForegroundColor Cyan

if ($totalEntries -gt $totalCounted) {
    $uncategorized = $totalEntries - $totalCounted
    Write-Host (" {0,-25} {1,5} items" -f "Uncategorized:", $uncategorized) -ForegroundColor Yellow
}

Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "NEXT STEP: Compare these counts with in-game vanity menu" -ForegroundColor Yellow
Write-Host "  1. Open WoW and check your vanity collection UI" -ForegroundColor Gray
Write-Host "  2. Note the item counts for each category" -ForegroundColor Gray
Write-Host "  3. Compare with the counts above" -ForegroundColor Gray
Write-Host "  4. Report any significant discrepancies" -ForegroundColor Gray
Write-Host ""
