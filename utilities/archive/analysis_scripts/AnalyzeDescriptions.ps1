# Analyze Unique Descriptions
param(
    [Parameter(Mandatory=$false)]
    [string]$InputFile = "data\AscensionVanity_Fresh_Scan_2025-10-28_NEW.lua"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Unique Descriptions Analysis" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$content = Get-Content $InputFile -Raw

# Extract APIDump section
$apidumpStart = $content.IndexOf('["APIDump"] = {')
$apidumpEnd = $content.IndexOf('["LastScanDate"]', $apidumpStart)
$apidumpSection = $content.Substring($apidumpStart, $apidumpEnd - $apidumpStart)

# Parse descriptions
$descriptionPattern = '\["description"\] = "([^"]+)"'
$descriptions = [regex]::Matches($apidumpSection, $descriptionPattern)

Write-Host "Total descriptions: $($descriptions.Count)" -ForegroundColor White

# Filter out drop descriptions and get unique ones
$uniqueDescriptions = @{}
$dropCount = 0
$emptyCount = 0

foreach ($match in $descriptions) {
    $desc = $match.Groups[1].Value
    
    if ($desc -eq "") {
        $emptyCount++
    } elseif ($desc.StartsWith("Has a chance to drop from ")) {
        $dropCount++
    } else {
        if (-not $uniqueDescriptions.ContainsKey($desc)) {
            $uniqueDescriptions[$desc] = 0
        }
        $uniqueDescriptions[$desc]++
    }
}

Write-Host "Drop descriptions (starts with 'Has a chance to drop from'): $dropCount" -ForegroundColor Yellow
Write-Host "Empty descriptions: $emptyCount" -ForegroundColor Red
Write-Host "Unique non-drop descriptions: $($uniqueDescriptions.Count)" -ForegroundColor Green

Write-Host "`nTop 30 unique non-drop descriptions:" -ForegroundColor Cyan
Write-Host "(Showing count and first 100 chars)" -ForegroundColor DarkGray
Write-Host ""

$uniqueDescriptions.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 30 | ForEach-Object {
    $preview = $_.Key.Substring(0, [Math]::Min(100, $_.Key.Length))
    if ($_.Key.Length > 100) {
        $preview += "..."
    }
    Write-Host "  [$($_.Value)x] $preview" -ForegroundColor White
}

Write-Host "`n========================================" -ForegroundColor Cyan
