<#
.SYNOPSIS
    Compare ZoneMappings.json against Wowpedia data

.DESCRIPTION
    Verifies our zone and subzone data matches canonical Wowpedia sources
    
    Sources:
    - Zones: https://wowpedia.fandom.com/wiki/Zones_by_level_(original)#Classification
    - Subzones: Individual zone pages (e.g., https://wowpedia.fandom.com/wiki/Desolace_(Classic)#Maps_and_subregions)
#>

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Zone Mappings Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load our mappings
$mappings = Get-Content "data\ZoneMappings.json" -Raw | ConvertFrom-Json

# Count what we have
$ourZoneCount = ($mappings.zones | Get-Member -MemberType NoteProperty).Count
$ourSubzoneCount = 0
$mappings.zones.PSObject.Properties | ForEach-Object {
    if ($_.Value.subzones) {
        $ourSubzoneCount += $_.Value.subzones.Count
    }
}

Write-Host "Our Data:" -ForegroundColor Yellow
Write-Host "  Zones: $ourZoneCount" -ForegroundColor Gray
Write-Host "  Subzones: $ourSubzoneCount" -ForegroundColor Gray
Write-Host ""

# Canonical zone list from Wowpedia (Classic zones)
# Source: https://wowpedia.fandom.com/wiki/Zones_by_level_(original)#Classification
$canonicalZones = @(
    # Eastern Kingdoms
    "Alterac Mountains", "Arathi Highlands", "Badlands", "Blasted Lands",
    "Burning Steppes", "Deadwind Pass", "Dun Morogh", "Duskwood", "Eastern Plaguelands",
    "Elwynn Forest", "Eversong Woods", "Ghostlands", "Hillsbrad Foothills",
    "Loch Modan", "Redridge Mountains", "Searing Gorge", "Silverpine Forest",
    "Stranglethorn Vale", "Swamp of Sorrows", "The Hinterlands", "Tirisfal Glades",
    "Western Plaguelands", "Westfall", "Wetlands",
    
    # Kalimdor
    "Ashenvale", "Azshara", "Azuremyst Isle", "Bloodmyst Isle", "Darkshore",
    "Desolace", "Durotar", "Dustwallow Marsh", "Felwood", "Feralas",
    "Moonglade", "Mulgore", "Silithus", "Stonetalon Mountains", "Tanaris",
    "Teldrassil", "The Barrens", "Thousand Needles", "Un'Goro Crater",
    "Winterspring",
    
    # Outland (TBC)
    "Blade's Edge Mountains", "Hellfire Peninsula", "Nagrand", "Netherstorm",
    "Shadowmoon Valley", "Terokkar Forest", "Zangarmarsh",
    
    # Northrend (WOTLK)
    "Borean Tundra", "Crystalsong Forest", "Dragonblight", "Grizzly Hills",
    "Howling Fjord", "Icecrown", "Sholazar Basin", "The Storm Peaks",
    "Zul'Drak",
    
    # Cities
    "Darnassus", "Ironforge", "Orgrimmar", "Shattrath City", "Silvermoon City",
    "Stormwind City", "Thunder Bluff", "Undercity", "The Exodar", "Dalaran"
)

Write-Host "Canonical Zones (from Wowpedia): $($canonicalZones.Count)" -ForegroundColor Yellow
Write-Host ""

# Find missing zones
$missingZones = $canonicalZones | Where-Object { -not $mappings.zones.$_ }
$extraZones = $mappings.zones.PSObject.Properties.Name | Where-Object { $_ -notin $canonicalZones -and $_ -ne "Dungeons and Raids" }

if ($missingZones.Count -gt 0) {
    Write-Host "Missing Zones:" -ForegroundColor Red
    $missingZones | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
}

if ($extraZones.Count -gt 0) {
    Write-Host "Extra Zones (not in canonical list):" -ForegroundColor Yellow
    $extraZones | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host ""
}

if ($missingZones.Count -eq 0 -and $extraZones.Count -eq 0) {
    Write-Host "✓ All zones match Wowpedia!" -ForegroundColor Green
    Write-Host ""
}

# Check Desolace subzones specifically
Write-Host "Desolace Subzone Check:" -ForegroundColor Cyan
Write-Host ""

# Canonical Desolace subzones from Wowpedia
# Source: https://wowpedia.fandom.com/wiki/Desolace_(Classic)#Maps_and_subregions
$canonicalDesolaceSubzones = @(
    "Cenarion Wildlands",
    "Ethel Rethor",
    "Gelkis Village",
    "Kodo Graveyard",
    "Kolkar Village",
    "Kormek's Hut",
    "Magram Territory",
    "Magram Village",
    "Mannoroc Coven",
    "Nijel's Point",
    "Ranazjar Isle",
    "Sargeron",
    "Shadowbreak Ravine",
    "Shadowprey Village",
    "Shok'Thokar",
    "Slitherblade Shore",
    "Tethris Aran",
    "Thunk's Abode",
    "Thunder Axe Fortress",
    "Valley of Bones",
    "Valley of Spears"
)

Write-Host "Canonical Desolace subzones: $($canonicalDesolaceSubzones.Count)" -ForegroundColor Yellow
Write-Host "Our Desolace subzones: $($mappings.zones.Desolace.subzones.Count)" -ForegroundColor Gray
Write-Host ""

$missingDesolaceSubzones = $canonicalDesolaceSubzones | Where-Object { $_ -notin $mappings.zones.Desolace.subzones }
$extraDesolaceSubzones = $mappings.zones.Desolace.subzones | Where-Object { $_ -notin $canonicalDesolaceSubzones }

if ($missingDesolaceSubzones.Count -gt 0) {
    Write-Host "Missing Desolace Subzones:" -ForegroundColor Red
    $missingDesolaceSubzones | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
}

if ($extraDesolaceSubzones.Count -gt 0) {
    Write-Host "Extra Desolace Subzones (not in canonical list):" -ForegroundColor Yellow
    $extraDesolaceSubzones | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host ""
}

if ($missingDesolaceSubzones.Count -eq 0 -and $extraDesolaceSubzones.Count -eq 0) {
    Write-Host "✓ Desolace subzones match Wowpedia!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Missing: $($missingDesolaceSubzones.Count)" -ForegroundColor $(if ($missingDesolaceSubzones.Count -gt 0) { "Red" } else { "Green" })
    Write-Host "  Extra: $($extraDesolaceSubzones.Count)" -ForegroundColor $(if ($extraDesolaceSubzones.Count -gt 0) { "Yellow" } else { "Green" })
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Validation Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
