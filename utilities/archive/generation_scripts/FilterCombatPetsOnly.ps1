# FilterCombatPetsOnly.ps1
# Filters VanityDB_New.lua to contain ONLY the 5 combat pet vanity item categories

$inputFile = ".\AscensionVanity\VanityDB_New.lua"
$outputFile = ".\AscensionVanity\VanityDB.lua"

# Define the 5 combat pet categories to keep
$combatPetPatterns = @(
    "Beastmaster's Whistle:",
    "Blood Soaked Vellum:",
    "Summoner's Stone:",
    "Draconic Warhorn:",
    "Elemental Lodestone:"
)

# Parse the Lua table
$lines = Get-Content $inputFile

$outputLines = @()
$currentItem = @()
$inItem = $false
$itemCount = 0
$keptCount = 0

Write-Host "Filtering combat pet items only..." -ForegroundColor Cyan

foreach ($line in $lines) {
    # Check if this is the start of the table
    if ($line -match "^AV_VanityItems = \{") {
        $outputLines += $line
        continue
    }
    
    # Check if this is the end of the table
    if ($line -match "^\}") {
        $outputLines += $line
        continue
    }
    
    # Check if this is the start of an item entry
    if ($line -match "^\s+\[(\d+)\] = \{") {
        $inItem = $true
        $currentItem = @($line)
        continue
    }
    
    # If we're in an item, collect lines
    if ($inItem) {
        $currentItem += $line
        
        # Check if this is the end of the item
        if ($line -match "^\s+\}") {
            $inItem = $false
            $itemCount++
            
            # Check if this item matches any combat pet pattern
            $itemText = $currentItem -join "`n"
            $keepItem = $false
            
            foreach ($pattern in $combatPetPatterns) {
                if ($itemText -match [regex]::Escape($pattern)) {
                    $keepItem = $true
                    break
                }
            }
            
            if ($keepItem) {
                $outputLines += $currentItem
                $keptCount++
                
                # Show progress every 100 items
                if ($keptCount % 100 -eq 0) {
                    Write-Host "Kept $keptCount combat pet items..." -ForegroundColor Green
                }
            }
            
            $currentItem = @()
        }
    }
}

# Write header
$header = @"
-- AscensionVanity Database - Combat Pets Only
-- Generated from filtered API scan on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Contains ONLY the 5 combat pet vanity item categories:
--   • Beastmaster's Whistles (Hunter)
--   • Blood Soaked Vellums (Death Knight)
--   • Summoner's Stones (Warlock)
--   • Draconic Warhorns (Mage)
--   • Elemental Lodestones (Shaman)
-- Total items: $keptCount

"@

$finalOutput = $header + ($outputLines -join "`n")

# Write the output file
$finalOutput | Set-Content $outputFile -Encoding UTF8

Write-Host "`nFiltering complete!" -ForegroundColor Green
Write-Host "Original items: $itemCount" -ForegroundColor Yellow
Write-Host "Kept combat pet items: $keptCount" -ForegroundColor Green
Write-Host "Removed: $($itemCount - $keptCount)" -ForegroundColor Red
Write-Host "`nOutput written to: $outputFile" -ForegroundColor Cyan

# Show size comparison
$originalSize = (Get-Item $inputFile).Length / 1KB
$newSize = (Get-Item $outputFile).Length / 1KB
$savings = (($originalSize - $newSize) / $originalSize) * 100

Write-Host "`nSize comparison:" -ForegroundColor Cyan
Write-Host "  Original: $([math]::Round($originalSize, 2)) KB" -ForegroundColor Yellow
Write-Host "  Filtered: $([math]::Round($newSize, 2)) KB" -ForegroundColor Green
Write-Host "  Savings: $([math]::Round($savings, 2))%" -ForegroundColor Magenta
