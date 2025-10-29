# Generate IconIndex.lua from VanityDB.lua
param(
    [Parameter(Mandatory=$false)]
    [string]$InputFile = "AscensionVanity\VanityDB.lua",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "AscensionVanity\IconIndex.lua"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Icon Index Generation" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$content = Get-Content $InputFile -Raw

# Extract all unique icons
$iconPattern = '\["icon"\] = "([^"]+)"'
$iconMatches = [regex]::Matches($content, $iconPattern)

$icons = @{}
foreach ($match in $iconMatches) {
    $icon = $match.Groups[1].Value
    if (-not $icons.ContainsKey($icon)) {
        $icons[$icon] = 0
    }
    $icons[$icon]++
}

Write-Host "Found $($icons.Count) unique icons" -ForegroundColor Green
Write-Host ""

# Sort icons alphabetically
$sortedIcons = $icons.GetEnumerator() | Sort-Object Name

# Generate Lua file
$header = @"
-- IconIndex.lua
-- Icon reference index for all vanity items
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Unique Icons: $($icons.Count)

IconIndex = {
"@

$iconEntries = @()
foreach ($entry in $sortedIcons) {
    $iconEntries += "`t[`"$($entry.Name)`"] = $($entry.Value)"
}

$footer = @"
}

-- Usage: IconIndex["Ability_Hunter_BeastCall"] returns the count of items using that icon
"@

$luaContent = @"
$header
$($iconEntries -join ",`n")
$footer
"@

# Write output
$luaContent | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline

Write-Host "✓ Generated: $OutputFile" -ForegroundColor Green
Write-Host "  Unique icons: $($icons.Count)" -ForegroundColor White
Write-Host ""

# Show top 10 most used icons
Write-Host "Top 10 most used icons:" -ForegroundColor Cyan
$icons.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host "  [$($_.Value)x] $($_.Key)" -ForegroundColor White
}

Write-Host "`n========================================" -ForegroundColor Cyan
