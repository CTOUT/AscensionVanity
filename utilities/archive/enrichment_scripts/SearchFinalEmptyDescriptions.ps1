# Search for NPC locations using CREATURE IDs
# Final 18 items with empty descriptions

$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Web

$npcs = @(
    @{ItemId = 80096; CreatureId = 11359; Name = "Soulflayer"},
    @{ItemId = 80098; CreatureId = 11361; Name = "Zulian Tiger"},
    @{ItemId = 80099; CreatureId = 11365; Name = "Zulian Panther"},
    @{ItemId = 80106; CreatureId = 11673; Name = "Ancient Core Hound"},
    @{ItemId = 80353; CreatureId = 17144; Name = "Goretooth"},
    @{ItemId = 480382; CreatureId = 417217; Name = "Captain Claws"},
    @{ItemId = 601009; CreatureId = 37703; Name = "Surging Water Elemental"},
    @{ItemId = 601067; CreatureId = 6932; Name = "Swamp Spirit"},
    @{ItemId = 601677; CreatureId = 6561; Name = "Stone Warden"},
    @{ItemId = 603976; CreatureId = 76; Name = "Silver Golem"},
    @{ItemId = 1180288; CreatureId = 9417; Name = "Sleeping Dragon"},
    @{ItemId = 1180317; CreatureId = 148069; Name = "Chromatic Whelp"},
    @{ItemId = 1180320; CreatureId = 148070; Name = "Chromatic Dragonspawn"},
    @{ItemId = 1180510; CreatureId = 21497; Name = "Blackscale"},
    @{ItemId = 1180511; CreatureId = 148115; Name = "Blackscale"}, # Duplicate
    @{ItemId = 1180526; CreatureId = 21818; Name = "Infinite Whelp"},
    @{ItemId = 1180599; CreatureId = 23789; Name = "Smolderwing"},
    @{ItemId = 1180833; CreatureId = 32180; Name = "Tempus Wyrm"}
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Searching for NPC Locations (Creature IDs)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$results = @()
$foundCount = 0

foreach ($npc in $npcs) {
    Write-Host "[$($foundCount + 1)/$($npcs.Count)] $($npc.Name) (Creature $($npc.CreatureId))" -ForegroundColor Yellow
    
    $zone = $null
    $source = "Not Found"
    
    # Try db.ascension.gg first
    $ascensionUrl = "https://db.ascension.gg/?npc=$($npc.CreatureId)"
    Write-Host "  Checking db.ascension.gg..." -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $ascensionUrl -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        $content = $response.Content
        
        # Pattern 1: "This NPC can be found in [Zone]"
        if ($content -match 'This NPC can be found in\s+<a[^>]*>([^<]+)</a>') {
            $zone = $matches[1].Trim()
            $source = "db.ascension.gg"
        }
        # Pattern 2: Look for zone in listview
        elseif ($content -match '<div class="listview-mode-default">.*?<a[^>]*zone=(\d+)[^>]*>([^<]+)</a>') {
            $zone = $matches[2].Trim()
            $source = "db.ascension.gg (listview)"
        }
        
        if ($zone) {
            Write-Host "  ✓ Found: $zone" -ForegroundColor Green
            $foundCount++
        }
    }
    catch {
        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
    
    # If not found, try Wowhead WOTLK
    if (-not $zone) {
        $wowheadUrl = "https://www.wowhead.com/wotlk/npc=$($npc.CreatureId)"
        Write-Host "  Checking Wowhead WOTLK..." -ForegroundColor Gray
        
        try {
            $response = Invoke-WebRequest -Uri $wowheadUrl -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
            $content = $response.Content
            
            # Pattern 1: JavaScript WH.setSelectedLink
            if ($content -match 'WH\.setSelectedLink[^>]*>([^<]+)</a>') {
                $zone = $matches[1].Trim()
                $source = "Wowhead (JS link)"
            }
            # Pattern 2: "This NPC can be found in"
            elseif ($content -match 'This NPC can be found in\s+<a[^>]*>([^<]+)</a>') {
                $zone = $matches[1].Trim()
                $source = "Wowhead (direct)"
            }
            # Pattern 3: Plain text fallback
            elseif ($content -match 'This NPC can be found in\s+([A-Z][^<\.\(]{2,}?)(?=\s*[\.<]|$)') {
                $zone = $matches[1].Trim()
                $source = "Wowhead (text)"
            }
            
            if ($zone) {
                Write-Host "  ✓ Found: $zone" -ForegroundColor Green
                $foundCount++
            }
        }
        catch {
            Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }
    
    if (-not $zone) {
        Write-Host "  ✗ NOT FOUND" -ForegroundColor Red
        $zone = "NOT FOUND"
    }
    
    $results += [PSCustomObject]@{
        ItemId = $npc.ItemId
        CreatureId = $npc.CreatureId
        NPCName = $npc.Name
        Zone = $zone
        Source = $source
    }
    
    Write-Host ""
    Start-Sleep -Seconds 2
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$results | Format-Table -AutoSize

Write-Host "`nFound: $foundCount / $($npcs.Count) zones`n" -ForegroundColor $(if ($foundCount -eq $npcs.Count) { "Green" } else { "Yellow" })

# Export results
$csvPath = "data\FinalEmptyDescriptions_Results.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "Results exported to: $csvPath`n" -ForegroundColor Cyan

# Create JSON for successful enrichments
$enrichments = $results | Where-Object { $_.Zone -ne "NOT FOUND" } | ForEach-Object {
    [PSCustomObject]@{
        ItemId = $_.ItemId
        CreatureId = $_.CreatureId
        DropsFrom = $_.NPCName
        Region = $_.Zone
        GeneratedDescription = "Has a chance to drop from $($_.NPCName) within $($_.Zone)"
    }
}

if ($enrichments.Count -gt 0) {
    $jsonPath = "data\FinalEmptyDescriptions_Enrichment.json"
    $enrichments | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8
    Write-Host "Enrichment data exported to: $jsonPath`n" -ForegroundColor Green
}

# Show what still needs manual research
$notFound = $results | Where-Object { $_.Zone -eq "NOT FOUND" }
if ($notFound.Count -gt 0) {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Items Needing Manual Research ($($notFound.Count)):" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Yellow
    $notFound | ForEach-Object {
        Write-Host "  - $($_.NPCName) (Creature $($_.CreatureId), Item $($_.ItemId))" -ForegroundColor Yellow
    }
    Write-Host ""
}
