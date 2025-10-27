#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Compares the game client export (SavedVariables) with VanityDB.lua for PET TAMING ITEMS ONLY
.DESCRIPTION
    This script parses both databases and identifies discrepancies for these 5 pet taming item types:
    - Beastmaster's Whistle
    - Blood Soaked Vellum
    - Draconic Warhorn
    - Elemental Lodestone
    - Summoner's Stone
    
    COMPARISON METHOD: Uses CREATURE NAME as the comparison key since the two databases
    use different ID numbering systems.
#>

# Use direct paths
$GameExportPath = "$PSScriptRoot\..\data\AscensionVanity_SavedVariables.lua"
$VanityDBPath = "$PSScriptRoot\..\AscensionVanity\VanityDB.lua"
$OutputPath = "$PSScriptRoot\..\DatabaseComparison_Report.txt"

Write-Host "🐾 PET TAMING ITEMS DATABASE COMPARISON" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Focus: Creature Name Comparison (accounts for different ID systems)" -ForegroundColor Gray

# Define pet taming item name patterns
$petTamingPatterns = @(
    "Beastmaster's Whistle",
    "Blood Soaked Vellum",
    "Draconic Warhorn",
    "Elemental Lodestone",
    "Summoner's Stone"
)

# Helper function to check if item is a pet taming item
function Test-PetTamingItem {
    param([string]$ItemName)
    foreach ($pattern in $petTamingPatterns) {
        if ($ItemName -like "*$pattern*") {
            return $true
        }
    }
    return $false
}

# Parse VanityDB.lua to extract PET TAMING items by CREATURE NAME
Write-Host "`n📖 Reading VanityDB.lua (filtering for pet taming items)..." -ForegroundColor Yellow
$vanityContent = Get-Content $VanityDBPath -Raw
$vanityByCreature = @{}

# Pattern: [creatureID] = itemID, -- ItemType: CreatureName
$vanityMatches = [regex]::Matches($vanityContent, '\[(\d+)\]\s*=\s*(\d+),\s*--\s*([^:]+):\s*(.+)')

foreach ($match in $vanityMatches) {
    $creatureID = $match.Groups[1].Value
    $itemID = $match.Groups[2].Value
    $itemType = $match.Groups[3].Value.Trim()
    $creatureName = $match.Groups[4].Value.Trim()
    
    # Only include pet taming items
    if (Test-PetTamingItem -ItemName $itemType) {
        # Use normalized creature name as key for comparison
        $normalizedName = $creatureName.ToLower().Trim()
        $vanityByCreature[$normalizedName] = @{
            ItemType = $itemType
            CreatureID = $creatureID
            ItemID = $itemID
            CreatureName = $creatureName
        }
    }
}

Write-Host "✅ VanityDB.lua contains: $($vanityByCreature.Count) unique pet taming creatures" -ForegroundColor Green

# Parse SavedVariables to extract PET TAMING items by CREATURE NAME
Write-Host "`n📖 Reading game export (filtering for pet taming creature drops)..." -ForegroundColor Yellow
$gameContent = Get-Content $GameExportPath -Raw
$gameByCreature = @{}

# Pattern to match items in the apiOnly section with creature drops
$apiOnlyMatches = [regex]::Matches($gameContent, '\["itemID"\]\s*=\s*(\d+),\s*\["name"\]\s*=\s*"([^"]+)",\s*\["creatureID"\]\s*=\s*(\d+)')

foreach ($match in $apiOnlyMatches) {
    $itemID = $match.Groups[1].Value
    $fullName = $match.Groups[2].Value
    $creatureID = $match.Groups[3].Value
    
    # Only include pet taming items that drop from creatures
    if (Test-PetTamingItem -ItemName $fullName) {
        # Extract creature name from "ItemType: CreatureName" format
        if ($fullName -match '^([^:]+):\s*(.+)$') {
            $itemType = $matches[1].Trim()
            $creatureName = $matches[2].Trim()
            
            # Use normalized creature name as key for comparison
            $normalizedName = $creatureName.ToLower().Trim()
            $gameByCreature[$normalizedName] = @{
                ItemType = $itemType
                CreatureID = $creatureID
                ItemID = $itemID
                CreatureName = $creatureName
            }
        }
    }
}

Write-Host "✅ Game export contains: $($gameByCreature.Count) unique pet taming creatures" -ForegroundColor Green

# Compare by creature name
Write-Host "`n🔍 Analyzing differences BY CREATURE NAME..." -ForegroundColor Yellow
$missingFromVanity = @()
$inBothDBs = @()
$onlyInVanity = @()
$idMismatches = @()

foreach ($creatureName in $gameByCreature.Keys) {
    if (-not $vanityByCreature.ContainsKey($creatureName)) {
        $missingFromVanity += $creatureName
    } else {
        $inBothDBs += $creatureName
        
        # Check if IDs match
        $gameData = $gameByCreature[$creatureName]
        $vanityData = $vanityByCreature[$creatureName]
        
        if ($gameData.CreatureID -ne $vanityData.CreatureID -or $gameData.ItemID -ne $vanityData.ItemID) {
            $idMismatches += @{
                CreatureName = $gameData.CreatureName
                GameCreatureID = $gameData.CreatureID
                GameItemID = $gameData.ItemID
                VanityCreatureID = $vanityData.CreatureID
                VanityItemID = $vanityData.ItemID
            }
        }
    }
}

foreach ($creatureName in $vanityByCreature.Keys) {
    if (-not $gameByCreature.ContainsKey($creatureName)) {
        $onlyInVanity += $creatureName
    }
}

# Generate report
$report = @"
PET TAMING ITEMS DATABASE COMPARISON REPORT (BY CREATURE NAME)
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
=======================================================

COMPARISON METHOD: Creature Name (normalized, case-insensitive)
This accounts for different ID numbering systems between databases.

SUMMARY:
--------
VanityDB.lua (Web Scraped):      $($vanityByCreature.Count) creatures
Game Export (API):                $($gameByCreature.Count) creatures
Creatures in both databases:      $($inBothDBs.Count) creatures
Missing from VanityDB:            $($missingFromVanity.Count) creatures
Only in VanityDB (not in API):   $($onlyInVanity.Count) creatures
ID Mismatches (same creature):    $($idMismatches.Count) creatures

COVERAGE METRICS:
-----------------
Database Coverage: $(if ($gameByCreature.Count -gt 0) { ([math]::Round(($inBothDBs.Count / $gameByCreature.Count) * 100, 2)) } else { 0 })%
Missing Creatures: $(if ($gameByCreature.Count -gt 0) { ([math]::Round(($missingFromVanity.Count / $gameByCreature.Count) * 100, 2)) } else { 0 })%

CRITICAL ANALYSIS:
------------------
$( if ($missingFromVanity.Count -gt 0) {
"🚨 CRITICAL: VanityDB is missing $($missingFromVanity.Count) creatures that exist in the game!"
"   These creatures drop pet taming items but are not in your database."
} else {
"✅ VanityDB contains all pet taming creatures from the game export."
})

$( if ($onlyInVanity.Count -gt 0) {
"⚠️  WARNING: VanityDB has $($onlyInVanity.Count) creatures not found in the game API."
"   These may be outdated, incorrectly named, or from removed content."
} else {
"✅ No orphaned creatures in VanityDB."
})

$( if ($idMismatches.Count -gt 0) {
"📋 ID DIFFERENCES: $($idMismatches.Count) creatures exist in both databases but use different IDs."
"   This is EXPECTED because the databases use different ID numbering systems:"
"   - Web-scraped DB uses one ID system"
"   - Game API uses another ID system"
"   ✅ This is NORMAL and does NOT indicate a problem!"
} else {
"✅ All matching creatures have identical IDs (unusual but good!)."
})

MISSING CREATURES (Need to Add to VanityDB):
---------------------------------------------
$( if ($missingFromVanity.Count -gt 0) {
    ($missingFromVanity | ForEach-Object {
        $creature = $gameByCreature[$_]
        "$($creature.CreatureName) - $($creature.ItemType) (Game API: Creature=$($creature.CreatureID), Item=$($creature.ItemID))"
    }) -join "`n"
} else {
    "None - Database is complete!"
})

CREATURES ONLY IN VANITYDB (May Need Review):
----------------------------------------------
$( if ($onlyInVanity.Count -gt 0) {
    ($onlyInVanity | Select-Object -First 50 | ForEach-Object {
        $creature = $vanityByCreature[$_]
        "$($creature.CreatureName) - $($creature.ItemType) (VanityDB: Creature=$($creature.CreatureID), Item=$($creature.ItemID))"
    }) -join "`n"
    if ($onlyInVanity.Count -gt 50) {
        "`n... and $($onlyInVanity.Count - 50) more creatures (showing first 50)"
    }
} else {
    "None - All creatures validated!"
})

ID DIFFERENCES (Same Creature, Different IDs):
-----------------------------------------------
NOTE: These ID differences are EXPECTED and NORMAL. Both databases track the same
creatures but use different ID numbering systems.

$( if ($idMismatches.Count -gt 0) {
    ($idMismatches | Select-Object -First 20 | ForEach-Object {
        @"
$($_.CreatureName):
  Game API:  Creature=$($_.GameCreatureID), Item=$($_.GameItemID)
  VanityDB:  Creature=$($_.VanityCreatureID), Item=$($_.VanityItemID)
"@
    }) -join "`n"
    if ($idMismatches.Count -gt 20) {
        "`n... and $($idMismatches.Count - 20) more mismatches (showing first 20)"
    }
} else {
    "None - All IDs match perfectly!"
})

RECOMMENDATION:
---------------
$( if ($missingFromVanity.Count -gt 0) {
"🔧 ACTION REQUIRED: 
   1. Add $($missingFromVanity.Count) missing creatures to VanityDB.lua
   2. These creatures exist in the game but are not in your web-scraped database
   3. Consider re-running your web scraping process to capture these
   4. Test in-game to confirm these creatures drop the items"
} elseif ($onlyInVanity.Count -gt 0) {
"⚠️  REVIEW NEEDED:
   $($onlyInVanity.Count) creatures in VanityDB are not in the current game API.
   They may be:
   - Removed from the game
   - Renamed (different spelling/capitalization)
   - Test/beta creatures no longer available
   Consider investigating these entries."
} else {
"✅ PERFECT: Your database is complete!
   All pet taming creature drops are properly cataloged."
})

$( if ($idMismatches.Count -gt 0) {
"`nℹ️  ABOUT ID DIFFERENCES:
   $($idMismatches.Count) creatures use different IDs between databases.
   This is NORMAL and EXPECTED. The two data sources use different numbering systems.
   Your addon will work correctly using VanityDB's IDs."
})

=======================================================
END OF REPORT
"@

# Write report to file
$report | Out-File -FilePath $OutputPath -Encoding UTF8

# Display summary to console
Write-Host "`n" -NoNewline
Write-Host "📊 PET TAMING CREATURES COMPARISON:" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "`nVanityDB creatures:  " -NoNewline
Write-Host $vanityByCreature.Count -ForegroundColor Yellow
Write-Host "Game API creatures:  " -NoNewline
Write-Host $gameByCreature.Count -ForegroundColor Yellow
Write-Host "Coverage:            " -NoNewline
$coveragePercent = if ($gameByCreature.Count -gt 0) { ([math]::Round(($inBothDBs.Count / $gameByCreature.Count) * 100, 2)) } else { 0 }
Write-Host "$coveragePercent%" -ForegroundColor $(if ($coveragePercent -eq 100) { 'Green' } elseif ($coveragePercent -gt 90) { 'Yellow' } else { 'Red' })
Write-Host "Missing creatures:   " -NoNewline
Write-Host $missingFromVanity.Count -ForegroundColor $(if ($missingFromVanity.Count -eq 0) { 'Green' } else { 'Red' })
Write-Host "Extra creatures:     " -NoNewline
Write-Host $onlyInVanity.Count -ForegroundColor $(if ($onlyInVanity.Count -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "ID differences:      " -NoNewline
Write-Host $idMismatches.Count -ForegroundColor $(if ($idMismatches.Count -eq 0) { 'Green' } else { 'Cyan' })

Write-Host "`n📄 Full report saved to: " -NoNewline
Write-Host $OutputPath -ForegroundColor Green

# Open report
if ($missingFromVanity.Count -gt 0 -or $onlyInVanity.Count -gt 0) {
    Write-Host "`n⚠️  Discrepancies detected! Opening report..." -ForegroundColor Yellow
    Start-Process notepad $OutputPath
} else {
    Write-Host "`n✅ Database is complete! All pet taming creatures accounted for." -ForegroundColor Green
    Write-Host "   (ID differences are normal and expected)" -ForegroundColor Cyan
}
