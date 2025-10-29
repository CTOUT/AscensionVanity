# FilterDropsFromAPI.ps1
# Filters API data to find pet taming items that drop from creatures

param(
    [string]$InputFile = "data\AscensionVanity.lua"
)

Write-Host "`n=== Filtering Pet Taming Items from Creature Drops ===" -ForegroundColor Cyan

$lines = Get-Content $InputFile
$inAPIDump = $false
$currentItem = @{}
$itemCount = 0

# Categories to track
$categories = @{
    "Beastmaster's Whistle" = @()
    "Blood Soaked Vellum" = @()
    "Summoner's Stone" = @()
    "Draconic Warhorn" = @()
    "Elemental Lodestone" = @()
}

Write-Host "Parsing APIDump section..." -ForegroundColor Yellow

foreach ($line in $lines) {
    # Detect APIDump section start
    if ($line -match '\["APIDump"\]') {
        $inAPIDump = $true
        continue
    }
    
    if ($inAPIDump) {
        # Capture top-level name (handle escaped quotes in Lua strings)
        if ($line -match '^\s*\["name"\]\s*=\s*"((?:[^"\\]|\\.)*)"') {
            $currentItem.Name = $matches[1]
        }
        
        # Capture itemId
        if ($line -match '^\s*\["itemId"\]\s*=\s*(\d+)') {
            $currentItem.ItemId = $matches[1]
        }
        
        # Capture creaturePreview
        if ($line -match '^\s*\["creaturePreview"\]\s*=\s*(\d+)') {
            $currentItem.CreatureId = $matches[1]
        }
        
        # Capture description from rawData (handle escaped quotes in Lua strings)
        if ($line -match '^\s*\["description"\]\s*=\s*"((?:[^"\\]|\\.)*)"') {
            $currentItem.Description = $matches[1]
        }
        
        # End of item - process it
        if ($line -match '^\s*\},\s*--\s*\[\d+\]') {
            # Check if this is a target category AND from drops
            if ($currentItem.Name -and $currentItem.Description) {
                $isTargetCategory = $false
                $category = ""
                
                foreach ($cat in $categories.Keys) {
                    if ($currentItem.Name -like "*$cat*") {
                        $isTargetCategory = $true
                        $category = $cat
                        break
                    }
                }
                
                # Check if from drops
                $isFromDrops = $currentItem.Description -like "Has a chance to drop from*"
                
                if ($isTargetCategory -and $isFromDrops) {
                    $categories[$category] += [PSCustomObject]@{
                        ItemId = $currentItem.ItemId
                        CreatureId = $currentItem.CreatureId
                        Name = $currentItem.Name
                        Description = $currentItem.Description
                    }
                    $itemCount++
                }
            }
            
            # Reset for next item
            $currentItem = @{}
        }
        
        # End of APIDump section
        if ($line -match '^\}\s*$') {
            break
        }
    }
}

Write-Host "`nResults:" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

$totalDrops = 0
foreach ($cat in $categories.Keys | Sort-Object) {
    $count = $categories[$cat].Count
    $totalDrops += $count
    Write-Host "$cat : $count items" -ForegroundColor $(if ($count -gt 0) { "Green" } else { "Gray" })
}

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "TOTAL DROP-BASED ITEMS: $totalDrops" -ForegroundColor Yellow -BackgroundColor DarkGreen

# Export detailed results
$outputFile = "data\DropsOnly_Analysis.json"
$categories | ConvertTo-Json -Depth 10 | Out-File $outputFile -Encoding UTF8
Write-Host "`nDetailed results exported to: $outputFile" -ForegroundColor Cyan

return $totalDrops
