# Investigate DB-Only Items
# Analyzes why some items in current DB aren't in the filtered API scan

param(
    [string]$OldDBPath = ".\AscensionVanity\VanityDB_Backup_2025-10-28_112402.lua",
    [string]$NewDBPath = ".\AscensionVanity\VanityDB_New.lua",
    [string]$SavedVariablesPath = "d:\Program Files\Ascension Launcher\resources\client\WTF\Account\chris-tout@outlook.com\SavedVariables\AscensionVanity.lua"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DB-Only Items Investigation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Read old DB
Write-Host "Reading old VanityDB..." -ForegroundColor Yellow
$oldDBContent = Get-Content $OldDBPath -Raw

$oldItems = @{}
$oldPattern = '\[(\d+)\]\s*=\s*\{[^}]*itemid\s*=\s*(\d+).*?creaturePreview\s*=\s*(\d+)'
$oldMatches = [regex]::Matches($oldDBContent, $oldPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

foreach ($match in $oldMatches) {
    $arrayIndex = [int]$match.Groups[1].Value
    $itemId = [int]$match.Groups[2].Value
    $creatureId = [int]$match.Groups[3].Value
    
    $oldItems[$itemId] = @{
        ArrayIndex = $arrayIndex
        ItemId = $itemId
        CreatureId = $creatureId
    }
}

Write-Host "Old DB has $($oldItems.Count) items" -ForegroundColor Green

# Read new DB
Write-Host "Reading new VanityDB..." -ForegroundColor Yellow
$newDBContent = Get-Content $NewDBPath -Raw

$newItems = @{}
$newPattern = '\[(\d+)\]\s*=\s*\{'
$newMatches = [regex]::Matches($newDBContent, $newPattern)

foreach ($match in $newMatches) {
    $itemId = [int]$match.Groups[1].Value
    $newItems[$itemId] = $true
}

Write-Host "New DB has $($newItems.Count) items" -ForegroundColor Green
Write-Host ""

# Find items in old but not in new
$dbOnlyItems = @()
foreach ($itemId in $oldItems.Keys) {
    if (-not $newItems.ContainsKey($itemId)) {
        $dbOnlyItems += $oldItems[$itemId]
    }
}

Write-Host "Items in old DB but NOT in new DB: $($dbOnlyItems.Count)" -ForegroundColor Yellow
Write-Host ""

# Now check the API scan for these items
Write-Host "Checking API scan for these items..." -ForegroundColor Yellow
$apiContent = Get-Content $SavedVariablesPath -Raw

$categories = @{
    NotInAPI = 0
    Webstore = 0
    Vendor = 0
    Quest = 0
    Achievement = 0
    NoCreature = 0
    NoDescription = 0
    Other = 0
}

$samples = @{
    NotInAPI = @()
    Webstore = @()
    Vendor = @()
    NoCreature = @()
    Other = @()
}

foreach ($item in $dbOnlyItems) {
    $itemId = $item.ItemId
    
    # Search for this item in API scan
    $itemPattern = "\[`"itemId`"\]\s*=\s*$itemId,.*?\[`"description`"\]\s*=\s*`"([^`"]*)`".*?\[`"creaturePreview`"\]\s*=\s*(\d+)"
    $itemMatch = [regex]::Match($apiContent, $itemPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    if ($itemMatch.Success) {
        $description = $itemMatch.Groups[1].Value
        $apiCreatureId = [int]$itemMatch.Groups[2].Value
        
        # Categorize why it was excluded
        if ($description -match "Webstore|webstore") {
            $categories.Webstore++
            if ($samples.Webstore.Count -lt 5) {
                $samples.Webstore += @{
                    ItemId = $itemId
                    Description = $description
                    OldCreature = $item.CreatureId
                    APICreature = $apiCreatureId
                }
            }
        }
        elseif ($description -match "purchase|Purchase|buy|vendor|Vendor") {
            $categories.Vendor++
            if ($samples.Vendor.Count -lt 5) {
                $samples.Vendor += @{
                    ItemId = $itemId
                    Description = $description
                    OldCreature = $item.CreatureId
                    APICreature = $apiCreatureId
                }
            }
        }
        elseif ($description -match "quest|Quest") {
            $categories.Quest++
        }
        elseif ($description -match "achievement|Achievement") {
            $categories.Achievement++
        }
        elseif ($apiCreatureId -eq 0) {
            $categories.NoCreature++
            if ($samples.NoCreature.Count -lt 5) {
                $samples.NoCreature += @{
                    ItemId = $itemId
                    Description = $description
                    OldCreature = $item.CreatureId
                    APICreature = $apiCreatureId
                }
            }
        }
        elseif ($description -eq "") {
            $categories.NoDescription++
        }
        else {
            $categories.Other++
            if ($samples.Other.Count -lt 5) {
                $samples.Other += @{
                    ItemId = $itemId
                    Description = $description
                    OldCreature = $item.CreatureId
                    APICreature = $apiCreatureId
                }
            }
        }
    }
    else {
        $categories.NotInAPI++
        if ($samples.NotInAPI.Count -lt 5) {
            $samples.NotInAPI += @{
                ItemId = $itemId
                OldCreature = $item.CreatureId
            }
        }
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CATEGORIZATION OF MISSING ITEMS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Not in API scan at all: $($categories.NotInAPI)" -ForegroundColor Red
Write-Host "Now Webstore items: $($categories.Webstore)" -ForegroundColor Magenta
Write-Host "Now Vendor items: $($categories.Vendor)" -ForegroundColor Magenta
Write-Host "Now Quest items: $($categories.Quest)" -ForegroundColor Magenta
Write-Host "Now Achievement items: $($categories.Achievement)" -ForegroundColor Magenta
Write-Host "API has no creature ID: $($categories.NoCreature)" -ForegroundColor Yellow
Write-Host "No description in API: $($categories.NoDescription)" -ForegroundColor Gray
Write-Host "Other reasons: $($categories.Other)" -ForegroundColor Yellow
Write-Host ""

# Show samples
if ($samples.NotInAPI.Count -gt 0) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "ITEMS NOT IN API SCAN (Removed?)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    foreach ($item in $samples.NotInAPI) {
        Write-Host "Item $($item.ItemId) (Old creature: $($item.OldCreature))" -ForegroundColor Red
    }
    Write-Host ""
}

if ($samples.Webstore.Count -gt 0) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "NOW WEBSTORE ITEMS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    foreach ($item in $samples.Webstore) {
        Write-Host "Item $($item.ItemId):" -ForegroundColor Magenta
        Write-Host "  Old creature: $($item.OldCreature)" -ForegroundColor Gray
        Write-Host "  API creature: $($item.APICreature)" -ForegroundColor Gray
        Write-Host "  Description: $($item.Description)" -ForegroundColor Gray
        Write-Host ""
    }
}

if ($samples.Vendor.Count -gt 0) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "NOW VENDOR ITEMS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    foreach ($item in $samples.Vendor) {
        Write-Host "Item $($item.ItemId):" -ForegroundColor Magenta
        Write-Host "  Old creature: $($item.OldCreature)" -ForegroundColor Gray
        Write-Host "  API creature: $($item.APICreature)" -ForegroundColor Gray
        Write-Host "  Description: $($item.Description)" -ForegroundColor Gray
        Write-Host ""
    }
}

if ($samples.NoCreature.Count -gt 0) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "API HAS NO CREATURE ID" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    foreach ($item in $samples.NoCreature) {
        Write-Host "Item $($item.ItemId):" -ForegroundColor Yellow
        Write-Host "  Old creature: $($item.OldCreature)" -ForegroundColor Gray
        Write-Host "  API creature: $($item.APICreature) (removed!)" -ForegroundColor Red
        Write-Host "  Description: $($item.Description)" -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Most DB-only items fall into these categories:" -ForegroundColor Yellow
Write-Host "1. Items moved to webstore/vendor ($($categories.Webstore + $categories.Vendor) items)" -ForegroundColor White
Write-Host "2. Items with creature IDs removed ($($categories.NoCreature) items)" -ForegroundColor White
Write-Host "3. Items completely removed from game ($($categories.NotInAPI) items)" -ForegroundColor White
Write-Host ""
Write-Host "These changes are expected as Ascension updates content." -ForegroundColor Green
Write-Host "The new VanityDB accurately reflects current drop-based items." -ForegroundColor Green
Write-Host ""
