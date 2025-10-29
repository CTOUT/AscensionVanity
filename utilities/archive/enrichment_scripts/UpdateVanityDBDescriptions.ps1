# UpdateVanityDBDescriptions.ps1
# Updates VanityDB.lua with validated descriptions from ValidateBlankDescriptions.ps1

param(
    [string]$ValidationFile = "data\BlankDescriptions_Validated.json",
    [string]$InputFile = "AscensionVanity\VanityDB.lua",
    [string]$OutputFile = "AscensionVanity\VanityDB.lua"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Update VanityDB Descriptions" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Load validated descriptions
if (-not (Test-Path $ValidationFile)) {
    Write-Host "❌ Validation file not found: $ValidationFile" -ForegroundColor Red
    Write-Host "Run ValidateBlankDescriptions.ps1 first!`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "Loading validation results..." -ForegroundColor Green
$validatedItems = Get-Content $ValidationFile -Raw | ConvertFrom-Json

$validatedCount = ($validatedItems | Where-Object { $_.Validated -eq $true }).Count
Write-Host "Found $validatedCount validated descriptions`n" -ForegroundColor Cyan

if ($validatedCount -eq 0) {
    Write-Host "No validated descriptions to apply. Exiting.`n" -ForegroundColor Yellow
    exit 0
}

# Load VanityDB
Write-Host "Reading VanityDB.lua..." -ForegroundColor Green
$content = Get-Content $InputFile -Raw

$updatedCount = 0

# Update each validated item
foreach ($item in $validatedItems) {
    if ($item.Validated -ne $true -or -not $item.GeneratedDescription) {
        continue
    }
    
    Write-Host "Updating [$($item.ItemId)] $($item.Name)" -ForegroundColor Cyan
    Write-Host "  → $($item.GeneratedDescription)" -ForegroundColor Green
    
    # Pattern to find this specific item and replace its description
    # Match: [itemid] = { ... ["description"] = "", ... }
    # Replace with: [itemid] = { ... ["description"] = "new description", ... }
    
    $itemPattern = "(\[$($item.ItemId)\] = \{[^}]*\[`"description`"\] = )`"`"([^}]*\})"
    $replacement = "`$1`"$($item.GeneratedDescription)`"`$2"
    
    $content = $content -replace $itemPattern, $replacement
    $updatedCount++
}

# Write updated content
Write-Host "`nWriting updated VanityDB.lua..." -ForegroundColor Green
$content | Out-File $OutputFile -Encoding UTF8 -NoNewline

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "✅ Update Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Updated descriptions: $updatedCount" -ForegroundColor White
Write-Host "Output file: $OutputFile`n" -ForegroundColor White

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review the updated VanityDB.lua" -ForegroundColor White
Write-Host "2. Run .\DeployAddon.ps1 to deploy to WoW" -ForegroundColor White
Write-Host "3. Test in-game to verify descriptions`n" -ForegroundColor White

return $updatedCount
