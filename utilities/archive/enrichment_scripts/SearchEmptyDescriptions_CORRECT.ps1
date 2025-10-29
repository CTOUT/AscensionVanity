# Search for NPC locations for items with empty descriptions
# Using the CORRECT NPC names (after the prefix)

Add-Type -AssemblyName System.Web

$items = @(
    @{ID = 80096; Name = "Soulflayer"; FullName = "Beastmaster's Whistle: Soulflayer"},
    @{ID = 80098; Name = "Zulian Tiger"; FullName = "Beastmaster's Whistle: Zulian Tiger"},
    @{ID = 80099; Name = "Zulian Panther"; FullName = "Beastmaster's Whistle: Zulian Panther"},
    @{ID = 80106; Name = "Ancient Core Hound"; FullName = "Beastmaster's Whistle: Ancient Core Hound"},
    @{ID = 80353; Name = "Goretooth"; FullName = "Beastmaster's Whistle: Goretooth"},
    @{ID = 480382; Name = "Captain Claws"; FullName = "Beastmaster's Whistle: Captain Claws"},
    @{ID = 601009; Name = "Surging Water Elemental"; FullName = "Elemental Lodestone: Surging Water Elemental"},
    @{ID = 601067; Name = "Swamp Spirit"; FullName = "Elemental Lodestone: Swamp Spirit"},
    @{ID = 601677; Name = "Stone Warden"; FullName = "Elemental Lodestone: Stone Warden"},
    @{ID = 603976; Name = "Silver Golem"; FullName = "Elemental Lodestone: Silver Golem"},
    @{ID = 1180288; Name = "Sleeping Dragon"; FullName = "Draconic Warhorn: Sleeping Dragon"},
    @{ID = 1180317; Name = "Chromatic Whelp"; FullName = "Draconic Warhorn: Chromatic Whelp"},
    @{ID = 1180320; Name = "Chromatic Dragonspawn"; FullName = "Draconic Warhorn: Chromatic Dragonspawn"},
    @{ID = 1180510; Name = "Blackscale"; FullName = "Draconic Warhorn: Blackscale"},
    @{ID = 1180511; Name = "Blackscale"; FullName = "Draconic Warhorn: Blackscale"}, # Duplicate
    @{ID = 1180526; Name = "Infinite Whelp"; FullName = "Draconic Warhorn: Infinite Whelp"},
    @{ID = 1180599; Name = "Smolderwing"; FullName = "Draconic Warhorn: Smolderwing"},
    @{ID = 1180833; Name = "Tempus Wyrm"; FullName = "Draconic Warhorn: Tempus Wyrm"}
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Searching for NPC Locations" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$results = @()

foreach ($item in $items) {
    Write-Host "Searching for: $($item.Name) (ID: $($item.ID))" -ForegroundColor Yellow
    
    # URL encode the NPC name
    $encodedName = [System.Web.HttpUtility]::UrlEncode($item.Name)
    
    # Try db.ascension.gg first
    $ascensionUrl = "https://db.ascension.gg/?search=$encodedName"
    Write-Host "  Checking: $ascensionUrl" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $ascensionUrl -UseBasicParsing -TimeoutSec 10
        $content = $response.Content
        
        # Look for zone information in various patterns
        $zoneMatch = $null
        
        # Pattern 1: "This NPC can be found in [Zone]"
        if ($content -match "This NPC can be found in ([^<.(]+)") {
            $zoneMatch = $matches[1].Trim()
        }
        # Pattern 2: Look for listview-row with zone name
        elseif ($content -match '<div class="listview-row[^>]*>.*?<a[^>]*>([^<]+)</a>.*?</div>' -and $matches[1] -notmatch "^\d+$") {
            $zoneMatch = $matches[1].Trim()
        }
        
        if ($zoneMatch) {
            Write-Host "  ✓ Found on db.ascension.gg: $zoneMatch" -ForegroundColor Green
            $results += [PSCustomObject]@{
                ID = $item.ID
                NPCName = $item.Name
                FullName = $item.FullName
                Zone = $zoneMatch
                Source = "db.ascension.gg"
            }
            Start-Sleep -Seconds 2
            continue
        }
    }
    catch {
        Write-Host "  ✗ Error accessing db.ascension.gg: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Try Wowhead WOTLK
    $wowheadUrl = "https://www.wowhead.com/wotlk/npc=$($item.ID)"
    Write-Host "  Checking: $wowheadUrl" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $wowheadUrl -UseBasicParsing -TimeoutSec 10
        $content = $response.Content
        
        # Look for zone in various Wowhead patterns
        $zoneMatch = $null
        
        # Pattern 1: "This NPC can be found in [Zone]"
        if ($content -match "This NPC can be found in ([^<.(]+)") {
            $zoneMatch = $matches[1].Trim()
        }
        # Pattern 2: Look in WH.setSelectedLink
        elseif ($content -match 'WH\.setSelectedLink[^>]*>([^<]+)</a>') {
            $zoneMatch = $matches[1].Trim()
        }
        
        if ($zoneMatch) {
            Write-Host "  ✓ Found on Wowhead: $zoneMatch" -ForegroundColor Green
            $results += [PSCustomObject]@{
                ID = $item.ID
                NPCName = $item.Name
                FullName = $item.FullName
                Zone = $zoneMatch
                Source = "Wowhead"
            }
        }
        else {
            Write-Host "  ✗ Not found on Wowhead" -ForegroundColor Red
            $results += [PSCustomObject]@{
                ID = $item.ID
                NPCName = $item.Name
                FullName = $item.FullName
                Zone = "NOT FOUND"
                Source = "None"
            }
        }
    }
    catch {
        Write-Host "  ✗ Error accessing Wowhead: $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{
            ID = $item.ID
            NPCName = $item.Name
            FullName = $item.FullName
            Zone = "ERROR"
            Source = "Error"
        }
    }
    
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SEARCH RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Display results
$results | Format-Table -AutoSize

# Export to CSV
$csvPath = ".\data\EmptyDescriptions_SearchResults.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "Results exported to: $csvPath" -ForegroundColor Green

# Create enrichment data
$enrichmentData = @()
foreach ($result in $results) {
    if ($result.Zone -ne "NOT FOUND" -and $result.Zone -ne "ERROR") {
        $enrichmentData += [PSCustomObject]@{
            ID = $result.ID
            FullName = $result.FullName
            Description = $result.Zone
        }
    }
}

$jsonPath = ".\data\EmptyDescriptions_Enrichment.json"
$enrichmentData | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8
Write-Host "Enrichment data exported to: $jsonPath" -ForegroundColor Green

Write-Host ""
Write-Host "Found: $($enrichmentData.Count) / $($items.Count) NPCs" -ForegroundColor $(if ($enrichmentData.Count -eq $items.Count) { "Green" } else { "Yellow" })
