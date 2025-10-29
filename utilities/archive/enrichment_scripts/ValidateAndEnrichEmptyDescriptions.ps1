# ValidateAndEnrichEmptyDescriptions.ps1
# Validates and enriches vanity items with empty descriptions using Ascension DB web scraping
# Uses the same approach as v1 to verify drops and get region information

param(
    [string]$APIFile = "data\AscensionVanity.lua",
    [string]$SavedVarsFile = "data\AscensionVanity_SavedVariables.lua",
    [string]$OutputFile = "data\EmptyDescriptions_Validated.json",
    [int]$DelayMs = 1000  # Delay between requests to avoid overwhelming the server
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Validate & Enrich Empty Descriptions" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Vanity item categories to check
$vanityCategories = @(
    "Beastmaster's Whistle",
    "Blood Soaked Vellum",
    "Summoner's Stone",
    "Draconic Warhorn",
    "Elemental Lodestone"
)

# Storage for items with empty descriptions
$emptyDescItems = @()

Write-Host "Step 1: Building API Item ID to DB Item ID mapping from SavedVariables..." -ForegroundColor Green

# Parse SavedVariables to get the mapping
$apiToDbMapping = @{}
$savedVarsContent = Get-Content $SavedVarsFile
$inValidation = $false

foreach ($line in $savedVarsContent) {
    if ($line -match '\["ValidationResults"\]') {
        $inValidation = $true
        continue
    }
    
    if (-not $inValidation) { continue }
    
    # Extract apiItem and dbItem
    if ($line -match '\["apiItem"\]\s*=\s*(\d+)') {
        $currentApiItem = $matches[1]
    }
    if ($line -match '\["dbItem"\]\s*=\s*(\d+)') {
        $currentDbItem = $matches[1]
        if ($currentApiItem) {
            $apiToDbMapping[$currentApiItem] = $currentDbItem
        }
    }
}

Write-Host "Built mapping for $($apiToDbMapping.Count) items" -ForegroundColor Cyan

Write-Host "`nStep 2: Scanning API file for vanity items with empty descriptions..." -ForegroundColor Green

# Parse the API file
$content = Get-Content $APIFile
$inAPIDump = $false
$currentItem = @{}

foreach ($line in $content) {
    # Start of APIDump section
    if ($line -match '\["APIDump"\]\s*=\s*\{') {
        $inAPIDump = $true
        continue
    }
    
    if (-not $inAPIDump) { continue }
    
    # Extract fields - note that name appears BOTH in rawData and outside
    # We want the name OUTSIDE rawData (after the closing brace)
    if ($line -match '\["itemId"\]\s*=\s*(\d+)') {
        $currentItem.ItemId = $matches[1]
    }
    
    # Capture ALL name occurrences (we'll use the last one found)
    if ($line -match '\["name"\]\s*=\s*"((?:[^"\\]|\\.)*)"') {
        $currentItem.Name = $matches[1]
    }
    
    if ($line -match '\["description"\]\s*=\s*""') {
        $currentItem.HasEmptyDesc = $true
    }
    
    # Capture ALL creaturePreview occurrences (we'll use the last one)
    if ($line -match '\["creaturePreview"\]\s*=\s*(\d+)') {
        $currentItem.CreatureId = $matches[1]
    }
    
    # End of item entry
    if ($line -match '\}\s*,\s*--\s*\[\d+\]') {
        # Check if this is a vanity item with empty description
        if ($currentItem.HasEmptyDesc -and $currentItem.Name) {
            $isVanity = $false
            $matchedCategory = $null
            foreach ($cat in $vanityCategories) {
                if ($currentItem.Name -like "*$cat*") {
                    $isVanity = $true
                    $matchedCategory = $cat
                    break
                }
            }
            
            if ($isVanity) {
                # Look up the real DB item ID from our mapping
                $dbItemId = $apiToDbMapping[$currentItem.ItemId]
                
                if (-not $dbItemId) {
                    Write-Host "  ⚠ Warning: No DB item ID mapping found for API item $($currentItem.ItemId)" -ForegroundColor Yellow
                    $dbItemId = $currentItem.ItemId  # Fallback to API item ID
                }
                
                $emptyDescItems += [PSCustomObject]@{
                    ItemId = $currentItem.ItemId
                    DbItemId = $dbItemId
                    CreatureId = $currentItem.CreatureId
                    Name = $currentItem.Name
                    Category = $matchedCategory
                    Validated = $false
                    DropsFrom = $null
                    Region = $null
                    GeneratedDescription = $null
                }
            }
        }
        $currentItem = @{}
    }
    
    # End of APIDump section
    if ($line -match '^\}\s*$' -and $inAPIDump) {
        break
    }
}

Write-Host "Found $($emptyDescItems.Count) vanity items with empty descriptions" -ForegroundColor Yellow

if ($emptyDescItems.Count -eq 0) {
    Write-Host "`nNo items to validate. Exiting." -ForegroundColor Green
    exit 0
}

Write-Host "`nStep 2: Validating drop sources via Ascension DB..." -ForegroundColor Green
Write-Host "(This may take a few minutes - using $DelayMs ms delay between requests)`n" -ForegroundColor Gray

$validated = 0
$notDrops = 0
$failed = 0

foreach ($item in $emptyDescItems) {
    Write-Host "Checking: $($item.Name) (DB Item: $($item.DbItemId), Creature: $($item.CreatureId))..." -ForegroundColor Cyan
    
    # CRITICAL: Reset state variables to prevent data contamination between items
    $npcInfo = $null
    $creatureName = $null
    $region = $null
    
    # Check if we have a valid DB item ID mapping
    if ($item.DbItemId -eq $item.ItemId) {
        Write-Host "  ⚠ WARNING: No DB item ID mapping found - using API item ID $($item.ItemId)" -ForegroundColor Yellow
        Write-Host "  ℹ This item may not be validated correctly. Check SavedVariables for mapping." -ForegroundColor Gray
        Write-Host "  → Skipping validation for this item" -ForegroundColor Yellow
        $item.GeneratedDescription = "Cannot validate - missing DB item ID mapping"
        $notDrops++
        Write-Host ""
        continue
    }
    
    try {
        # Step 1: Check item page for "Dropped by" section using DB item ID (in-game item ID)
        $itemUrl = "https://db.ascension.gg/?item=$($item.DbItemId)"
        Write-Host "  → Fetching: $itemUrl" -ForegroundColor Gray
        
        $itemPage = Invoke-WebRequest -Uri $itemUrl -UseBasicParsing -TimeoutSec 30
        
        # Look for the dropped-by Listview data embedded in the page
        # Format: new Listview({"template":"npc","id":"dropped-by","parent":"lv-generic","data":[...],"name":LANG.tab_droppedby...
        if ($itemPage.Content -match '"id":"dropped-by".*?"data":\s*(\[[^\}]+\]).*?"name":LANG\.tab_droppedby') {
            $dropDataJson = $matches[1]
            Write-Host "  ✓ Found 'Dropped by' data in page" -ForegroundColor Green
            
            # Try to parse the JSON to get NPC info
            try {
                $dropData = $dropDataJson | ConvertFrom-Json
                
                # If CreatureId is 0 or not set, use the first creature from the drop list
                if ($item.CreatureId -eq 0 -or -not $item.CreatureId) {
                    $npcInfo = $dropData | Select-Object -First 1
                    if ($npcInfo) {
                        Write-Host "  ℹ No specific creature ID stored - using first from drop list: $($npcInfo.id)" -ForegroundColor Cyan
                    }
                } else {
                    # Look for the specific creature ID
                    $npcInfo = $dropData | Where-Object { $_.id -eq $item.CreatureId } | Select-Object -First 1
                    
                    if ($npcInfo) {
                        Write-Host "  ✓ Creature ID $($item.CreatureId) confirmed in drop list" -ForegroundColor Green
                    } else {
                        # Fallback: If the specified creature isn't in the list, use the first one
                        Write-Host "  ⚠ Creature ID $($item.CreatureId) not in drop list - using first creature instead" -ForegroundColor Yellow
                        $npcInfo = $dropData | Select-Object -First 1
                    }
                }
                
                if ($npcInfo) {
                    # The creature name is NOT in the drop data JSON - fetch NPC page to get name and zone
                    $npcUrl = "https://db.ascension.gg/?npc=$($npcInfo.id)"
                    Write-Host "  → Fetching creature data: $npcUrl" -ForegroundColor Gray
                    
                    Start-Sleep -Milliseconds $DelayMs
                    
                    $npcPage = Invoke-WebRequest -Uri $npcUrl -UseBasicParsing -TimeoutSec 30
                    
                    # Extract creature name from page title
                    $creatureName = $null
                    if ($npcPage.Content -match '<title>([^-]+)\s*-\s*NPC') {
                        $creatureName = $matches[1].Trim()
                        Write-Host "  → Creature name: $creatureName" -ForegroundColor Cyan
                    }
                    
                    # Get region/location from the JSON data (it's an array of zone IDs)
                    $region = $null
                    if ($npcInfo.location -and $npcInfo.location.Count -gt 0) {
                        $zoneId = $npcInfo.location[0]
                        Write-Host "  → Zone ID: $zoneId" -ForegroundColor Gray
                        
                        # Extract region/zone information from NPC page's map data
                        # Pattern: 'extra':{'141':'Teldrassil'}
                        if ($npcPage.Content -match "'extra':\s*\{[^}]*'$zoneId':'([^']+)'") {
                            $region = $matches[1].Trim()
                            Write-Host "  ✓ Region extracted from map data: $region" -ForegroundColor Green
                        }
                        # Fallback: Try "This NPC can be found in" pattern
                        elseif ($npcPage.Content -match 'This NPC can be found in\s*<a[^>]*>([^<]+)</a>') {
                            $region = $matches[1].Trim()
                            Write-Host "  ✓ Region extracted from text: $region" -ForegroundColor Green
                        }
                        # Fallback: Try zone link pattern
                        elseif ($npcPage.Content -match "zone=$zoneId`"[^>]*>([^<]+)</a>") {
                            $region = $matches[1].Trim()
                            Write-Host "  ✓ Region extracted from link: $region" -ForegroundColor Green
                        }
                    }
                    
                    # Generate description
                    if ($creatureName -and $region) {
                        $item.DropsFrom = $creatureName
                        $item.Region = $region
                        $item.GeneratedDescription = "Has a chance to drop from $creatureName within $region"
                        $item.Validated = $true
                        Write-Host "  ✓ Validated: Drops from '$creatureName' in '$region'" -ForegroundColor Green
                        $validated++
                    } elseif ($creatureName) {
                        $item.DropsFrom = $creatureName
                        $item.GeneratedDescription = "Has a chance to drop from $creatureName"
                        $item.Validated = $true
                        Write-Host "  ⚠ Partial validation: Drops from '$creatureName' (region unknown)" -ForegroundColor Yellow
                        $validated++
                    } else {
                        Write-Host "  ✗ Could not extract creature name from drop data" -ForegroundColor Red
                        $failed++
                    }
                } else {
                    Write-Host "  ✗ Creature ID $($item.CreatureId) NOT found in drop list" -ForegroundColor Red
                    $item.GeneratedDescription = "Source unknown - not confirmed as drop"
                    $notDrops++
                }
            } catch {
                Write-Host "  ✗ Error parsing drop data JSON: $($_.Exception.Message)" -ForegroundColor Red
                $failed++
            }
        } else {
            Write-Host "  ✗ No 'Dropped by' section found - likely not a drop" -ForegroundColor Red
            $item.GeneratedDescription = "Not a drop-based item"
            $notDrops++
        }
    }
    catch {
        Write-Host "  ✗ Error fetching data: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
    
    # Rate limiting
    Start-Sleep -Milliseconds $DelayMs
    Write-Host ""
}

Write-Host "`nValidation Results:" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "✓ Validated as drops: $validated" -ForegroundColor Green
Write-Host "✗ Not drop-based: $notDrops" -ForegroundColor Yellow
Write-Host "✗ Failed to validate: $failed" -ForegroundColor Red
Write-Host "======================================`n" -ForegroundColor Cyan

# Export results
$emptyDescItems | ConvertTo-Json -Depth 5 | Out-File $OutputFile -Encoding UTF8
Write-Host "Results exported to: $OutputFile" -ForegroundColor Cyan

# Show validated items
Write-Host "`nValidated Items:" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
$emptyDescItems | Where-Object { $_.Validated -eq $true } | ForEach-Object {
    Write-Host "Item $($_.ItemId): $($_.Name)" -ForegroundColor Yellow
    Write-Host "  → $($_.GeneratedDescription)" -ForegroundColor Green
}

# Show items that need manual review
$needsReview = $emptyDescItems | Where-Object { $_.Validated -eq $false }
if ($needsReview.Count -gt 0) {
    Write-Host "`nItems Needing Manual Review:" -ForegroundColor Yellow
    Write-Host "======================================" -ForegroundColor Cyan
    $needsReview | ForEach-Object {
        Write-Host "Item $($_.ItemId): $($_.Name)" -ForegroundColor Yellow
        Write-Host "  Reason: $($_.GeneratedDescription)" -ForegroundColor Gray
    }
}

Write-Host "`nNext Steps:" -ForegroundColor Green
Write-Host "1. Review $OutputFile for validation results" -ForegroundColor White
Write-Host "2. Manually verify any items that failed validation" -ForegroundColor White
Write-Host "3. Update FilterDropsFromAPI.ps1 to use validated descriptions" -ForegroundColor White
Write-Host "4. Re-run the database generation pipeline`n" -ForegroundColor White

return $validated
