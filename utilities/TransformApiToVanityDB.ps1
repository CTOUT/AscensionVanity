# TransformApiToVanityDB.ps1
# Transforms the captured API data format to match VanityDB.lua structure for comparison

param(
    [string]$InputFile = "data\AscensionVanity.lua",
    [string]$OutputFile = "data\AscensionVanity_Transformed.lua"
)

Write-Host "Reading API data from: $InputFile" -ForegroundColor Cyan

# Read the entire file
$content = Get-Content $InputFile -Raw

# Extract the apiOnly array using regex
if ($content -match '(?s)\["apiOnly"\]\s*=\s*\{(.*?)\}\s*,\s*\}') {
    $apiDataBlock = $matches[1]
    
    # Parse individual items using regex
    $itemPattern = '\{\s*\["name"\]\s*=\s*"([^"]+)",\s*\["creatureID"\]\s*=\s*(\d+),\s*\["itemID"\]\s*=\s*(\d+),\s*\}'
    $matches = [regex]::Matches($apiDataBlock, $itemPattern)
    
    Write-Host "Found $($matches.Count) items in API data" -ForegroundColor Green
    
    # Create output in VanityDB format
    $output = @"
-- AscensionVanity - Transformed API Data
-- Converted from API capture format to VanityDB format
-- Total items: $($matches.Count)
-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

AV_VanityItems_API = {
"@
    
    # Sort by itemID for consistency
    $items = @()
    foreach ($match in $matches) {
        $itemName = $match.Groups[1].Value
        $creatureID = $match.Groups[2].Value
        $itemID = $match.Groups[3].Value
        
        $items += [PSCustomObject]@{
            ItemID = [int]$itemID
            CreatureID = [int]$creatureID
            Name = $itemName
        }
    }
    
    # Sort by ItemID
    $sortedItems = $items | Sort-Object ItemID
    
    # Generate output lines
    foreach ($item in $sortedItems) {
        $output += "`n    [$($item.ItemID)] = $($item.CreatureID), -- $($item.Name)"
    }
    
    $output += "`n}"
    
    # Write to output file
    $output | Out-File $OutputFile -Encoding UTF8
    
    Write-Host "`nTransformation complete!" -ForegroundColor Green
    Write-Host "Output file: $OutputFile" -ForegroundColor Cyan
    Write-Host "Total items transformed: $($sortedItems.Count)" -ForegroundColor Yellow
    
} else {
    Write-Host "ERROR: Could not find apiOnly data in input file" -ForegroundColor Red
    exit 1
}
