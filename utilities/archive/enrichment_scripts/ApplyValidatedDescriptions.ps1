# Apply Validated Descriptions to VanityDB.lua
# Updates blank descriptions with validated data from BlankDescriptions_Validated.json

param(
    [Parameter(Mandatory=$false)]
    [string]$ValidatedFile = "data\BlankDescriptions_Validated.json",
    
    [Parameter(Mandatory=$false)]
    [string]$VanityDBFile = "AscensionVanity\VanityDB.lua"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Apply Validated Descriptions" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Load validated items
$validatedItems = Get-Content $ValidatedFile -Raw | ConvertFrom-Json

# Filter to only items with generated descriptions
$itemsToUpdate = $validatedItems | Where-Object { 
    $_.GeneratedDescription -and $_.GeneratedDescription -ne "Not a drop-based item" 
}

Write-Host "Loaded $($itemsToUpdate.Count) items with validated descriptions" -ForegroundColor Green
Write-Host ""

# Read VanityDB.lua
$vanityDB = Get-Content $VanityDBFile -Raw

$updated = 0
$failed = 0

foreach ($item in $itemsToUpdate) {
    $itemId = $item.ItemId
    $description = $item.GeneratedDescription
    
    # Escape special regex characters in the description
    $escapedDesc = [regex]::Escape($description)
    
    # Pattern to match the item entry with blank description
    # Match: [itemid] = { ... ["description"] = "", ... }
    $pattern = "(\[$itemId\]\s*=\s*\{[^\}]*\[`"description`"\]\s*=\s*)`"`"([^\}]*\})"
    
    if ($vanityDB -match $pattern) {
        # Replace blank description with validated one
        $replacement = "`${1}`"$description`"`${2}"
        $vanityDB = $vanityDB -replace $pattern, $replacement
        
        Write-Host "✓ [$itemId] $($item.Name)" -ForegroundColor Green
        Write-Host "  → $description" -ForegroundColor Gray
        $updated++
    } else {
        Write-Host "✗ [$itemId] $($item.Name) - NOT FOUND or already has description" -ForegroundColor Yellow
        $failed++
    }
}

# Save updated VanityDB.lua
$vanityDB | Set-Content $VanityDBFile -Encoding UTF8 -NoNewline

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Update Results:" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ Updated: $updated descriptions" -ForegroundColor Green
Write-Host "✗ Skipped: $failed items" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "✓ VanityDB.lua updated successfully!" -ForegroundColor Green
Write-Host ""
