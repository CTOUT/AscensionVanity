# ValidateBlankDescriptions.ps1
# Validates and enriches vanity items with blank descriptions using Ascension DB web scraping
# Updated for new VanityDB structure (no ValidationResults, direct itemid usage)

param(
    [string]$InputFile = "AscensionVanity\VanityDB.lua",
    [string]$OutputFile = "data\BlankDescriptions_Validated.json",
    [int]$DelayMs = 1500  # Delay between requests to avoid overwhelming the server
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Validate Blank Descriptions" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Storage for items with blank descriptions
$blankDescItems = @()

Write-Host "Step 1: Scanning VanityDB for items with blank descriptions..." -ForegroundColor Green

# Parse VanityDB.lua
$content = Get-Content $InputFile -Raw

# Extract items with blank descriptions
# Pattern: [itemid] = { ... ["description"] = "", ... }
$itemPattern = '\[(\d+)\] = \{[^}]*\["name"\] = "([^"]+)"[^}]*\["creaturePreview"\] = (\d+)[^}]*\["description"\] = ""'
$matches = [regex]::Matches($content, $itemPattern)

Write-Host "Found $($matches.Count) items with blank descriptions`n" -ForegroundColor Yellow

foreach ($match in $matches) {
    $itemId = $match.Groups[1].Value
    $itemName = $match.Groups[2].Value
    $creatureId = $match.Groups[3].Value
    
    $blankDescItems += [PSCustomObject]@{
        ItemId = $itemId
        CreatureId = $creatureId
        Name = $itemName
        Validated = $false
        DropsFrom = $null
        Region = $null
        GeneratedDescription = $null
    }
}

if ($blankDescItems.Count -eq 0) {
    Write-Host "No items with blank descriptions found. Exiting." -ForegroundColor Green
    exit 0
}

Write-Host "Items to validate:" -ForegroundColor Cyan
$blankDescItems | Select-Object -First 5 | ForEach-Object {
    Write-Host "  [$($_.ItemId)] $($_.Name) (Creature: $($_.CreatureId))" -ForegroundColor White
}
if ($blankDescItems.Count -gt 5) {
    Write-Host "  ... and $($blankDescItems.Count - 5) more" -ForegroundColor DarkGray
}

Write-Host "`nStep 2: Validating drop sources via Ascension DB..." -ForegroundColor Green
Write-Host "(This may take a few minutes - using $DelayMs ms delay between requests)`n" -ForegroundColor Gray

$validated = 0
$notDrops = 0
$failed = 0

foreach ($item in $blankDescItems) {
    Write-Host "Checking: $($item.Name) (Item: $($item.ItemId), Creature: $($item.CreatureId))..." -ForegroundColor Cyan
    
    # Reset state variables
    $npcInfo = $null
    $creatureName = $null
    $region = $null
    
    try {
        # Check item page for "Dropped by" section
        $itemUrl = "https://db.ascension.gg/?item=$($item.ItemId)"
        Write-Host "  → Fetching: $itemUrl" -ForegroundColor Gray
        
        $itemPage = Invoke-WebRequest -Uri $itemUrl -UseBasicParsing -TimeoutSec 30
        
        # Look for the dropped-by Listview data
        # Format: new Listview({"template":"npc","id":"dropped-by","parent":"lv-generic","data":[...]
        if ($itemPage.Content -match '"id":"dropped-by".*?"data":\s*(\[[^\]]+\])') {
            $dropDataJson = $matches[1]
            Write-Host "  ✓ Found 'Dropped by' data" -ForegroundColor Green
            
            try {
                $dropData = $dropDataJson | ConvertFrom-Json
                
                # Use creature ID if we have it, otherwise use first from drop list
                if ($item.CreatureId -eq 0 -or -not $item.CreatureId) {
                    $npcInfo = $dropData | Select-Object -First 1
                    if ($npcInfo) {
                        Write-Host "  ℹ No creature ID - using first from list: $($npcInfo.id)" -ForegroundColor Cyan
                    }
                } else {
                    $npcInfo = $dropData | Where-Object { $_.id -eq $item.CreatureId } | Select-Object -First 1
                    
                    if ($npcInfo) {
                        Write-Host "  ✓ Creature ID $($item.CreatureId) confirmed" -ForegroundColor Green
                    } else {
                        Write-Host "  ⚠ Creature ID $($item.CreatureId) not in list - using first" -ForegroundColor Yellow
                        $npcInfo = $dropData | Select-Object -First 1
                    }
                }
                
                if ($npcInfo) {
                    # Fetch NPC page for name and zone
                    $npcUrl = "https://db.ascension.gg/?npc=$($npcInfo.id)"
                    Write-Host "  → Fetching creature: $npcUrl" -ForegroundColor Gray
                    
                    Start-Sleep -Milliseconds $DelayMs
                    
                    $npcPage = Invoke-WebRequest -Uri $npcUrl -UseBasicParsing -TimeoutSec 30
                    
                    # Extract creature name from page title
                    if ($npcPage.Content -match '<title>([^-]+)\s*-\s*NPC') {
                        $creatureName = $matches[1].Trim()
                        Write-Host "  → Creature: $creatureName" -ForegroundColor Cyan
                    }
                    
                    # Get region from zone data
                    if ($npcInfo.location -and $npcInfo.location.Count -gt 0) {
                        $zoneId = $npcInfo.location[0]
                        Write-Host "  → Zone ID: $zoneId" -ForegroundColor Gray
                        
                        # Try multiple patterns to extract region
                        if ($npcPage.Content -match "'extra':\s*\{[^}]*'$zoneId':'([^']+)'") {
                            $region = $matches[1].Trim()
                            Write-Host "  ✓ Region (map data): $region" -ForegroundColor Green
                        }
                        elseif ($npcPage.Content -match 'This NPC can be found in\s*<a[^>]*>([^<]+)</a>') {
                            $region = $matches[1].Trim()
                            Write-Host "  ✓ Region (text): $region" -ForegroundColor Green
                        }
                        elseif ($npcPage.Content -match "zone=$zoneId`"[^>]*>([^<]+)</a>") {
                            $region = $matches[1].Trim()
                            Write-Host "  ✓ Region (link): $region" -ForegroundColor Green
                        }
                    }
                    
                    # Generate description
                    if ($creatureName -and $region) {
                        $item.DropsFrom = $creatureName
                        $item.Region = $region
                        $item.GeneratedDescription = "Has a chance to drop from $creatureName within $region"
                        $item.Validated = $true
                        Write-Host "  ✅ VALIDATED: '$creatureName' in '$region'" -ForegroundColor Green
                        $validated++
                    } elseif ($creatureName) {
                        $item.DropsFrom = $creatureName
                        $item.GeneratedDescription = "Has a chance to drop from $creatureName"
                        $item.Validated = $true
                        Write-Host "  ⚠ Partial: '$creatureName' (region unknown)" -ForegroundColor Yellow
                        $validated++
                    } else {
                        Write-Host "  ✗ Could not extract creature name" -ForegroundColor Red
                        $failed++
                    }
                } else {
                    Write-Host "  ✗ No creature info found in drop list" -ForegroundColor Red
                    $item.GeneratedDescription = "Source unknown"
                    $notDrops++
                }
            } catch {
                Write-Host "  ✗ Error parsing drop data: $($_.Exception.Message)" -ForegroundColor Red
                $failed++
            }
        } else {
            Write-Host "  ✗ No 'Dropped by' section - not a drop" -ForegroundColor Red
            $item.GeneratedDescription = "Not a drop-based item"
            $notDrops++
        }
    }
    catch {
        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
    
    Start-Sleep -Milliseconds $DelayMs
    Write-Host ""
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Validation Results:" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "✓ Validated as drops: $validated" -ForegroundColor Green
Write-Host "✗ Not drop-based: $notDrops" -ForegroundColor Yellow
Write-Host "✗ Failed to validate: $failed" -ForegroundColor Red
Write-Host "======================================`n" -ForegroundColor Cyan

# Export results
$blankDescItems | ConvertTo-Json -Depth 5 | Out-File $OutputFile -Encoding UTF8
Write-Host "Results exported to: $OutputFile" -ForegroundColor Cyan

# Show validated items
Write-Host "`nValidated Items ($validated):" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
$blankDescItems | Where-Object { $_.Validated -eq $true } | ForEach-Object {
    Write-Host "[$($_.ItemId)] $($_.Name)" -ForegroundColor Yellow
    Write-Host "  → $($_.GeneratedDescription)" -ForegroundColor Green
}

# Show items that need manual review
$needsReview = $blankDescItems | Where-Object { $_.Validated -eq $false }
if ($needsReview.Count -gt 0) {
    Write-Host "`nItems Needing Review ($($needsReview.Count)):" -ForegroundColor Yellow
    Write-Host "======================================" -ForegroundColor Cyan
    $needsReview | ForEach-Object {
        Write-Host "[$($_.ItemId)] $($_.Name)" -ForegroundColor Yellow
        Write-Host "  Reason: $($_.GeneratedDescription)" -ForegroundColor Gray
    }
}

Write-Host "`nNext Steps:" -ForegroundColor Green
Write-Host "1. Review $OutputFile for validation results" -ForegroundColor White
Write-Host "2. Run UpdateVanityDBDescriptions.ps1 to apply validated descriptions" -ForegroundColor White
Write-Host "3. Re-deploy updated VanityDB.lua to WoW addon folder`n" -ForegroundColor White

return @{
    Total = $blankDescItems.Count
    Validated = $validated
    NotDrops = $notDrops
    Failed = $failed
}
