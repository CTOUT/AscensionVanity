# Search for Empty Description Items
# Searches both db.ascension.gg and Wowhead WOTLK for the 18 remaining items

$items = @(
    "Corrupted Ashbringer",
    "Invincible",
    "Mimiron's Head",
    "Ashes of Al'ar",
    "Fiery Warhorse",
    "Raven Lord",
    "White Hawkstrider",
    "Blue Drake",
    "Azure Drake",
    "Bronze Drake",
    "Twilight Drake",
    "Black Drake",
    "Swift White Hawkstrider",
    "Swift Razzashi Raptor",
    "Swift Zulian Tiger",
    "Corrupted Hippogryph",
    "Quel'dorei Steed",
    "Amani Battle Bear"
)

$results = @()

foreach ($itemName in $items) {
    Write-Host "`n=== Searching for: $itemName ===" -ForegroundColor Cyan
    
    # Search db.ascension.gg
    $ascensionUrl = "https://db.ascension.gg/?search=$($itemName -replace ' ','+')"
    Write-Host "Ascension URL: $ascensionUrl" -ForegroundColor Yellow
    
    try {
        $ascensionPage = Invoke-WebRequest -Uri $ascensionUrl -UseBasicParsing -TimeoutSec 10
        
        # Look for NPC links in search results
        if ($ascensionPage.Content -match 'npc=(\d+)[^>]*>([^<]+)</a>') {
            $npcId = $Matches[1]
            $npcName = $Matches[2]
            Write-Host "  Found NPC: $npcName (ID: $npcId)" -ForegroundColor Green
            
            # Get NPC details page
            $npcUrl = "https://db.ascension.gg/?npc=$npcId"
            $npcPage = Invoke-WebRequest -Uri $npcUrl -UseBasicParsing -TimeoutSec 10
            
            # Look for location in "This NPC can be found in" pattern
            if ($npcPage.Content -match 'This NPC can be found in[^<]*<a[^>]*>([^<]+)</a>') {
                $zone = $Matches[1]
                Write-Host "  Location: $zone" -ForegroundColor Green
                
                $results += [PSCustomObject]@{
                    ItemName = $itemName
                    NPCName = $npcName
                    NPCID = $npcId
                    Zone = $zone
                    Source = "db.ascension.gg"
                }
            }
        }
    }
    catch {
        Write-Host "  Ascension search failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 2
    
    # Search Wowhead WOTLK
    $wowheadSearchUrl = "https://www.wowhead.com/wotlk/search?q=$($itemName -replace ' ','+')"
    Write-Host "Wowhead URL: $wowheadSearchUrl" -ForegroundColor Yellow
    
    try {
        $wowheadSearch = Invoke-WebRequest -Uri $wowheadSearchUrl -UseBasicParsing -TimeoutSec 10
        
        # Look for NPC links
        if ($wowheadSearch.Content -match '/wotlk/npc=(\d+)/([^"]+)"') {
            $npcId = $Matches[1]
            $npcSlug = $Matches[2]
            Write-Host "  Found NPC: $npcSlug (ID: $npcId)" -ForegroundColor Green
            
            # Get NPC details page
            $npcUrl = "https://www.wowhead.com/wotlk/npc=$npcId"
            $npcPage = Invoke-WebRequest -Uri $npcUrl -UseBasicParsing -TimeoutSec 10
            
            # Look for location in multiple patterns
            $zone = $null
            
            # Pattern 1: "This NPC can be found in [Zone]"
            if ($npcPage.Content -match 'This NPC can be found in[^<]*<a[^>]*zone=\d+[^>]*>([^<]+)</a>') {
                $zone = $Matches[1]
            }
            # Pattern 2: WH.setSelectedLink in JavaScript
            elseif ($npcPage.Content -match 'WH\.setSelectedLink[^>]*>([^<]+)</a>') {
                $zone = $Matches[1]
            }
            
            if ($zone) {
                Write-Host "  Location: $zone" -ForegroundColor Green
                
                $results += [PSCustomObject]@{
                    ItemName = $itemName
                    NPCName = $npcSlug
                    NPCID = $npcId
                    Zone = $zone
                    Source = "Wowhead WOTLK"
                }
            }
        }
    }
    catch {
        Write-Host "  Wowhead search failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 2
}

# Display results
Write-Host "`n`n=== SEARCH RESULTS ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

# Export to CSV
$csvPath = "data\EmptyDescriptions_SearchResults.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "`nResults exported to: $csvPath" -ForegroundColor Green

# Generate enrichment commands
Write-Host "`n`n=== SUGGESTED ENRICHMENTS ===" -ForegroundColor Cyan
$grouped = $results | Group-Object ItemName
foreach ($group in $grouped) {
    $itemName = $group.Name
    $locations = $group.Group | Select-Object -ExpandProperty Zone -Unique
    $zone = $locations -join " or "
    
    Write-Host "`n# $itemName"
    Write-Host "`$content = Get-Content 'AscensionVanity\VanityDB.lua' -Raw -Encoding UTF8"
    Write-Host "`$content = `$content -replace '(`"$itemName`".*?description = )`"`"', '`$1`"$zone`"'"
    Write-Host "`$content | Set-Content 'AscensionVanity\VanityDB.lua' -Encoding UTF8 -NoNewline"
}
