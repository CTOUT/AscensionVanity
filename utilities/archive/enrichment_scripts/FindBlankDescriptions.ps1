# Search for Item Descriptions on db.ascension.gg
# Finds drop information for items with blank descriptions

param(
    [Parameter(Mandatory=$false)]
    [string]$InputFile = "AscensionVanity\VanityDB.lua"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Finding Items with Blank Descriptions" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Read VanityDB
$content = Get-Content $InputFile -Raw

# Extract items with blank descriptions
$itemPattern = '\[(\d+)\] = \{[^}]*\["name"\] = "([^"]+)"[^}]*\["description"\] = ""[^}]*\}'
$blankItems = [regex]::Matches($content, $itemPattern)

Write-Host "Found $($blankItems.Count) items with blank descriptions`n" -ForegroundColor Yellow

# Create list for web searching
$itemsToSearch = @()

foreach ($match in $blankItems) {
    $itemId = $match.Groups[1].Value
    $itemName = $match.Groups[2].Value
    
    $itemsToSearch += [PSCustomObject]@{
        ItemId = $itemId
        Name = $itemName
        SearchUrl = "https://db.ascension.gg/?item=$itemId"
    }
}

# Export to file for reference
$itemsToSearch | Export-Csv "data\BlankDescriptions_ToSearch.csv" -NoTypeInformation

Write-Host "Items to search:" -ForegroundColor Cyan
$itemsToSearch | Select-Object -First 10 | ForEach-Object {
    Write-Host "  [$($_.ItemId)] $($_.Name)" -ForegroundColor White
    Write-Host "    URL: $($_.SearchUrl)" -ForegroundColor DarkGray
}

if ($itemsToSearch.Count -gt 10) {
    Write-Host "  ... and $($itemsToSearch.Count - 10) more" -ForegroundColor DarkGray
}

Write-Host "`n✓ Exported to: data\BlankDescriptions_ToSearch.csv" -ForegroundColor Green
Write-Host "`nNext: Use fetch_webpage tool to search each item URL" -ForegroundColor Cyan
Write-Host ""

# Return the list for use
return $itemsToSearch
