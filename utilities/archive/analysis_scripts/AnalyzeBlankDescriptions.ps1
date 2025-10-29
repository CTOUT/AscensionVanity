# Analyze Blank Descriptions in VanityDB.lua
param(
    [Parameter(Mandatory=$false)]
    [string]$InputFile = "AscensionVanity\VanityDB.lua"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Blank Descriptions Analysis" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$content = Get-Content $InputFile -Raw

# Parse items with blank descriptions
$itemPattern = '\[(\d+)\] = \{[^}]+\["name"\] = "([^"]+)"[^}]+\["description"\] = ""'
$blankItems = [regex]::Matches($content, $itemPattern)

Write-Host "Found $($blankItems.Count) items with blank descriptions`n" -ForegroundColor Yellow

# Group by prefix
$byPrefix = @{}
foreach ($match in $blankItems) {
    $itemId = $match.Groups[1].Value
    $name = $match.Groups[2].Value
    
    # Extract prefix
    $prefix = "Unknown"
    if ($name -match '^([^:]+):') {
        $prefix = $matches[1]
    }
    
    if (-not $byPrefix.ContainsKey($prefix)) {
        $byPrefix[$prefix] = @()
    }
    
    $byPrefix[$prefix] += [PSCustomObject]@{
        ItemId = [int]$itemId
        Name = $name
    }
}

# Display by prefix
foreach ($prefix in $byPrefix.Keys | Sort-Object) {
    $items = $byPrefix[$prefix] | Sort-Object ItemId
    Write-Host "[$($items.Count)] $prefix" -ForegroundColor Cyan
    $items | Select-Object -First 10 | ForEach-Object {
        Write-Host "  [$($_.ItemId)] $($_.Name)" -ForegroundColor White
    }
    if ($items.Count -gt 10) {
        Write-Host "  ... and $($items.Count - 10) more" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# Export to JSON for further processing
$exportData = @()
foreach ($match in $blankItems) {
    $exportData += [PSCustomObject]@{
        itemid = [int]$match.Groups[1].Value
        name = $match.Groups[2].Value
    }
}

$exportPath = "data\BlankDescriptions_Analysis.json"
$exportData | ConvertTo-Json -Depth 3 | Out-File $exportPath -Encoding UTF8
Write-Host "Exported to: $exportPath" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
