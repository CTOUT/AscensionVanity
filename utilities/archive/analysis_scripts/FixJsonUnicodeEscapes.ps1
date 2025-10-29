# Fix Unicode Escapes in JSON
# Converts escaped characters like \u0027 back to their proper characters

param(
    [Parameter(Mandatory=$false)]
    [string]$InputFile = "data\BlankDescriptions_Validated.json",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "data\BlankDescriptions_Validated.json"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Fix Unicode Escapes in JSON" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Read and parse JSON (this automatically decodes Unicode escapes)
Write-Host "Reading: $InputFile" -ForegroundColor Yellow
$items = Get-Content $InputFile -Raw | ConvertFrom-Json

Write-Host "Found $($items.Count) items" -ForegroundColor White

# Check for items that had Unicode escapes (now decoded)
$affectedItems = $items | Where-Object { 
    ($_.Region -and $_.Region -match "'") -or 
    ($_.GeneratedDescription -and $_.GeneratedDescription -match "'")
}

if ($affectedItems.Count -gt 0) {
    Write-Host "`nItems with apostrophes (previously Unicode escaped):" -ForegroundColor Cyan
    foreach ($item in $affectedItems) {
        Write-Host "  [$($item.ItemId)] $($item.Name)" -ForegroundColor White
        if ($item.Region) {
            Write-Host "    Region: $($item.Region)" -ForegroundColor Green
        }
    }
}

# Save back with proper encoding (no Unicode escapes)
Write-Host "`nSaving corrected JSON..." -ForegroundColor Yellow
$items | ConvertTo-Json -Depth 5 | Set-Content $OutputFile -Encoding UTF8

Write-Host "✓ Saved to: $OutputFile" -ForegroundColor Green
Write-Host "✓ Unicode escapes have been decoded to proper characters" -ForegroundColor Green
Write-Host ""
