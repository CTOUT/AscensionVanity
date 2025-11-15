<#
.SYNOPSIS
    Enrich missing pet family data by scraping individual item pages

.DESCRIPTION
    Scrapes db.ascension.gg item pages for the 359 combat pets missing family data.
    Extracts pet family information from embedded JavaScript data.
    
.PARAMETER InputCSV
    Path to CSV with missing items (default: data/MissingPetFamilies.csv)

.PARAMETER OutputJSON
    Path to save enriched family data (default: data/MissingPetFamilies_Enriched.json)

.PARAMETER RateLimit
    Seconds between requests (default: 2)

.PARAMETER BatchSize
    Items to process before saving (default: 50)

.EXAMPLE
    .\EnrichMissingPetFamilies.ps1
    
.NOTES
    Author: CMTout
    Created: 2025-11-15
#>

param(
    [string]$InputCSV = "data\MissingPetFamilies.csv",
    [string]$OutputJSON = "data\MissingPetFamilies_Enriched.json",
    [int]$RateLimit = 2,
    [int]$BatchSize = 50
)

$ErrorActionPreference = "Stop"

# Resolve paths
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptRoot
$inputFile = Join-Path $projectRoot $InputCSV
$outputFile = Join-Path $projectRoot $OutputJSON

if (-not (Test-Path $inputFile)) {
    Write-Error "Input CSV not found: $inputFile"
    exit 1
}

Write-Host "=== Enrich Missing Pet Families ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Input: $inputFile" -ForegroundColor Gray
Write-Host "Output: $outputFile" -ForegroundColor Gray
Write-Host "Rate Limit: $RateLimit seconds" -ForegroundColor Gray
Write-Host ""

# Load input
$items = Import-Csv $inputFile
Write-Host "Loaded $($items.Count) items to enrich" -ForegroundColor Yellow

# Load existing enrichment if it exists
$enriched = @{}
if (Test-Path $outputFile) {
    $existing = Get-Content $outputFile -Raw | ConvertFrom-Json
    foreach ($entry in $existing) {
        $enriched[$entry.itemId.ToString()] = $entry
    }
    Write-Host "Loaded $($enriched.Count) existing enrichments" -ForegroundColor Gray
}

# Family type mapping
$familyTypes = @{
    0 = "Ferocity"
    1 = "Tenacity"
    2 = "Cunning"
    3 = "Demon"
    4 = "Undead"
    5 = "Elemental"
    6 = "Dragonkin"
}

Write-Host ""
Write-Host "Starting enrichment..." -ForegroundColor Yellow

$processed = 0
$found = 0
$notFound = 0
$errors = 0

foreach ($item in $items) {
    $itemId = $item.ItemId
    $processed++
    
    # Skip if already enriched
    if ($enriched.ContainsKey($itemId)) {
        Write-Host "  [$processed/$($items.Count)] Skipping $itemId (already enriched)" -ForegroundColor Gray
        continue
    }
    
    $percentComplete = [math]::Round(($processed / $items.Count) * 100, 1)
    Write-Host "  [$processed/$($items.Count) - $percentComplete%] Processing $itemId - $($item.ItemName)" -ForegroundColor Cyan
    
    # Retry logic with exponential backoff
    $maxRetries = 3
    $retryDelay = 2
    $success = $false
    
    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        try {
            $url = "https://db.ascension.gg/?item=$itemId"
            
            # Use .NET HttpClient for better timeout control
            $httpClient = [System.Net.Http.HttpClient]::new()
            $httpClient.Timeout = [System.TimeSpan]::FromSeconds(10)
            $response = $httpClient.GetStringAsync($url).Result
            $httpClient.Dispose()
            
            # Extract pet family data from JavaScript
            if ($response -match 'new Listview\(\{"template":"pet","id":"pet-family".*?"data":(\[.*?\])') {
                $json = $Matches[1]
                $family = $json | ConvertFrom-Json | Select-Object -First 1
                
                if ($family) {
                    # Map type ID to name
                    $typeId = [int]$family.type
                    $familyType = if ($familyTypes.ContainsKey($typeId)) { $familyTypes[$typeId] } else { "Unknown" }
                    
                    $enriched[$itemId] = @{
                        itemId = [int]$itemId
                        itemName = $item.ItemName
                        creatureId = if ($item.CreatureId) { [int]$item.CreatureId } else { 0 }
                        familyId = [int]$family.id
                        familyName = $family.name
                        familyType = $familyType
                        icon = "Interface\Icons\$($family.icon)"
                        isExotic = [bool]$family.exotic
                    }
                    
                    $found++
                    Write-Host "    ✓ Found: $($family.name) ($familyType)" -ForegroundColor Green
                    $success = $true
                    break
                } else {
                    $notFound++
                    Write-Host "    ✗ No family data in JSON" -ForegroundColor Yellow
                    $success = $true
                    break
                }
            } else {
                $notFound++
                Write-Host "    ✗ No pet-family section found" -ForegroundColor Yellow
                $success = $true
                break
            }
            
        } catch {
            if ($attempt -lt $maxRetries) {
                Write-Host "    ⟳ Retry $attempt/$maxRetries (timeout/error)" -ForegroundColor Yellow
                Start-Sleep -Seconds ($retryDelay * $attempt)
            } else {
                $errors++
                Write-Host "    ✗ ERROR after $maxRetries attempts: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    # Rate limiting
    Start-Sleep -Seconds $RateLimit
    
    # Save progress every batch
    if ($processed % $BatchSize -eq 0) {
        $enrichedArray = $enriched.Values | Sort-Object itemId
        $enrichedArray | ConvertTo-Json -Depth 10 | Out-File $outputFile -Encoding UTF8
        Write-Host "  [Progress saved: $($enriched.Count) enrichments]" -ForegroundColor Magenta
    }
}

# Final save
$enrichedArray = $enriched.Values | Sort-Object itemId
$enrichedArray | ConvertTo-Json -Depth 10 | Out-File $outputFile -Encoding UTF8

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Total Processed: $processed" -ForegroundColor White
Write-Host "  Found: $found" -ForegroundColor Green
Write-Host "  Not Found: $notFound" -ForegroundColor Yellow
Write-Host "  Errors: $errors" -ForegroundColor Red
Write-Host "  Total Enriched: $($enriched.Count)" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Enrichment complete! Saved to: $outputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review enriched data: $outputFile" -ForegroundColor Gray
Write-Host "  2. Merge into PetFamilyMapping.json or database generation" -ForegroundColor Gray
Write-Host "  3. Regenerate database: .\utilities\GenerateVanityDB_Master.ps1" -ForegroundColor Gray
