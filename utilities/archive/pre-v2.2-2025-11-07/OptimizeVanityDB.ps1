# Optimize VanityDB.lua with Icon Index
# Replaces icon strings with numerical references to save space

param(
    [Parameter(Mandatory=$false)]
    [string]$InputFile = "AscensionVanity\VanityDB.lua",
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "AscensionVanity\VanityDB.lua"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Optimize VanityDB with Icon Index" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Read current VanityDB
$content = Get-Content $InputFile -Raw

# Extract all items
$itemPattern = '\[(\d+)\] = \{([^}]+)\}'
$items = [regex]::Matches($content, $itemPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

Write-Host "✓ Found $($items.Count) items" -ForegroundColor Green

# Extract all unique icons and count usage
$iconPattern = '\["icon"\] = "([^"]+)"'
$iconCounts = @{}

foreach ($item in $items) {
    if ($item.Groups[2].Value -match $iconPattern) {
        $icon = $matches[1]
        if (-not $iconCounts.ContainsKey($icon)) {
            $iconCounts[$icon] = 0
        }
        $iconCounts[$icon]++
    }
}

# Create numerical index (sorted by usage - most used = index 1)
$iconIndex = @{}
$indexNum = 1
foreach ($icon in ($iconCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -ExpandProperty Name)) {
    $iconIndex[$icon] = $indexNum
    $indexNum++
}

Write-Host "`nIcon Index:" -ForegroundColor Yellow
foreach ($icon in ($iconCounts.GetEnumerator() | Sort-Object Value -Descending)) {
    Write-Host "  [$($iconIndex[$icon.Name])] $($icon.Name) - $($icon.Value) items" -ForegroundColor White
}

# Build new file with icon index
$header = @"
-- VanityDB.lua
-- Combat Pet Vanity Items Database
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Items: $($items.Count)
-- Optimized: Icon strings replaced with numerical index

-- Icon Index (reference for icon field below)
local IconIndex = {
"@

foreach ($icon in ($iconCounts.GetEnumerator() | Sort-Object { $iconIndex[$_.Name] })) {
    $header += "`n`t[$($iconIndex[$icon.Name])] = `"$($icon.Name)`","
}

$header += @"

}

VanityDB = {
"@

# Process each item and replace icon with index number
$optimizedItems = @()
foreach ($item in $items) {
    $itemId = $item.Groups[1].Value
    $itemData = $item.Groups[2].Value
    
    # Replace icon string with index number
    foreach ($icon in $iconIndex.Keys) {
        if ($itemData -match [regex]::Escape("`t`t`t[`"icon`"] = `"$icon`"")) {
            $itemData = $itemData -replace [regex]::Escape("`t`t`t[`"icon`"] = `"$icon`""), "`t`t`t[`"icon`"] = $($iconIndex[$icon])"
            break
        }
    }
    
    $optimizedItems += "`t[$itemId] = {$itemData}"
}

$footer = "`n}"

# Combine all parts
$optimizedContent = $header + "`n" + ($optimizedItems -join ",`n") + $footer

# Write output
$optimizedContent | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline

# Calculate savings
$oldSize = $content.Length
$newSize = $optimizedContent.Length
$saved = $oldSize - $newSize
$percentSaved = [math]::Round(($saved / $oldSize) * 100, 1)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✅ Optimization Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Original size: $oldSize characters" -ForegroundColor White
Write-Host "Optimized size: $newSize characters" -ForegroundColor White
Write-Host "Saved: $saved characters ($percentSaved%)" -ForegroundColor Green
Write-Host "Output: $OutputFile" -ForegroundColor Cyan
Write-Host ""
