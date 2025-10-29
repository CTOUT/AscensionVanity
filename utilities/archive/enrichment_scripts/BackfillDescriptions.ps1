# BackfillDescriptions.ps1
# Backfills empty descriptions in VanityDB.lua using validated data from EmptyDescriptions_Validated.json

$dbFile = ".\AscensionVanity\VanityDB.lua"
$jsonFile = ".\data\EmptyDescriptions_Validated.json"

Write-Host "Loading validated descriptions from JSON..." -ForegroundColor Cyan
$validatedData = Get-Content $jsonFile | ConvertFrom-Json

# Create lookup dictionary: Name -> GeneratedDescription
$descriptionLookup = @{}
foreach ($item in $validatedData) {
    if ($item.Validated -and $item.GeneratedDescription) {
        $descriptionLookup[$item.Name] = $item.GeneratedDescription
    }
}

Write-Host "Found $($descriptionLookup.Count) validated descriptions" -ForegroundColor Green

# Read the database file
$content = Get-Content $dbFile

$updatedContent = @()
$updatedCount = 0
$currentName = $null
$inEmptyDescription = $false

Write-Host "`nBackfilling descriptions..." -ForegroundColor Cyan

foreach ($line in $content) {
    # Capture current item name
    if ($line -match '^\s+name = "([^"]+)",') {
        $currentName = $matches[1]
    }
    
    # Check if this is an empty description line that needs backfilling
    if ($line -match '^\s+description = "",') {
        if ($currentName -and $descriptionLookup.ContainsKey($currentName)) {
            $newDescription = $descriptionLookup[$currentName]
            $indent = if ($line -match '^(\s+)') { $matches[1] } else { "        " }
            $newLine = "${indent}description = `"$newDescription`","
            $updatedContent += $newLine
            $updatedCount++
            
            if ($updatedCount % 10 -eq 0) {
                Write-Host "  Backfilled $updatedCount descriptions..." -ForegroundColor Yellow
            }
        } else {
            $updatedContent += $line
        }
    } else {
        $updatedContent += $line
    }
}

# Write the updated file
$updatedContent | Set-Content $dbFile -Encoding UTF8

Write-Host "`nBackfill complete!" -ForegroundColor Green
Write-Host "Total descriptions backfilled: $updatedCount" -ForegroundColor Cyan

# Verify the results
$remainingEmpty = (Get-Content $dbFile | Select-String 'description = ""').Count
Write-Host "Remaining empty descriptions: $remainingEmpty" -ForegroundColor $(if ($remainingEmpty -eq 0) { "Green" } else { "Yellow" })

if ($remainingEmpty -gt 0) {
    Write-Host "`nNote: Some items still have empty descriptions. These may be:" -ForegroundColor Yellow
    Write-Host "  - Items not in the validation file" -ForegroundColor Gray
    Write-Host "  - Items that genuinely have no drop source information" -ForegroundColor Gray
}
