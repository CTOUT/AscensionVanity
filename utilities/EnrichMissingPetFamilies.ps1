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

# Load manual mappings (edge cases that can't be scraped)
$manualMappingsFile = Join-Path $projectRoot "data\ManualPetFamilyMappings.json"
$manualMappings = @{}
if (Test-Path $manualMappingsFile) {
    $manualData = Get-Content $manualMappingsFile -Raw | ConvertFrom-Json
    foreach ($mapping in $manualData.manualMappings) {
        $manualMappings[$mapping.itemId.ToString()] = $mapping
    }
    Write-Host "Loaded $($manualMappings.Count) manual mappings" -ForegroundColor Gray
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
    
    # Check manual mappings first (for edge cases)
    if ($manualMappings.ContainsKey($itemId)) {
        $manual = $manualMappings[$itemId]
        
        $enriched[$itemId] = @{
            itemId = [int]$itemId
            itemName = $manual.itemName
            creatureId = if ($item.CreatureId) { [int]$item.CreatureId } else { 0 }
            familyId = 0
            familyName = $manual.familyName
            familyType = $manual.familyType
            icon = ""
            isExotic = $false
            source = "manual-mapping"
            reason = $manual.reason
        }
        
        $found++
        Write-Host "    ✓ Manual mapping: $($manual.familyName) ($($manual.familyType)) - $($manual.reason)" -ForegroundColor Magenta
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
            
            # Strategy 1: Extract pet family data from JavaScript listview
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
                        source = "pet-family-listview"
                    }
                    
                    $found++
                    Write-Host "    ✓ Found: $($family.name) ($familyType)" -ForegroundColor Green
                    $success = $true
                    break
                }
            }
            
            # Strategy 2: Extract species from item tooltip (e.g., "Man'ari Eredar")
            # Pattern in JavaScript tooltip: <span class=\"q2\">SPECIES<\/span>
            if ($response -match '<span class=\\"q2\\">([^<]+)<\\/span><br \\/>' -and 
                $Matches[1] -notmatch '^(Binds|Unique|Soulbound|Use:|Requires|Item Level)') {
                
                $speciesName = $Matches[1].Trim()
                
                # Validate it's not empty and looks like a species name
                if ($speciesName.Length -gt 3) {
                    
                    # Attempt to map species to known family types
                    $familyType = "Unknown"
                    if ($speciesName -match 'Demon|Doomguard|Fel|Satyr|Eredar|Shivarra|Nathrezim|Imp') {
                        $familyType = "Demon"
                    } elseif ($speciesName -match 'Undead|Skeleton|Ghoul|Zombie|Wraith|Lich|Shade|Banshee') {
                        $familyType = "Undead"
                    } elseif ($speciesName -match 'Elemental|Revenant|Golem|Phoenix|Lasher|Treant|Ancient') {
                        $familyType = "Elemental"
                    } elseif ($speciesName -match 'Dragon|Drake|Whelp|Wyrm|Wyrmkin') {
                        $familyType = "Dragonkin"
                    }
                    
                    # Edge case mappings for non-3.3.5 families (map to closest 3.3.5 equivalent)
                    # Retail "Scalehide" → 3.3.5 "Rhino"
                    if ($speciesName -match 'Thunder Lizard') {
                        $speciesName = "Rhino"  # Scalehide family closest match
                    }
                    # Retail "Mammoth" → 3.3.5 "Rhino" 
                    elseif ($speciesName -match 'Elekk') {
                        $speciesName = "Rhino"  # Elekk use Mammoth abilities, map to Rhino
                    }
                    # Mechanical Dog → Wolf (no Dog family in 3.3.5)
                    elseif ($speciesName -match 'Dog|Hound') {
                        $speciesName = "Wolf"  # Dog family doesn't exist in 3.3.5
                    }
                    
                    $enriched[$itemId] = @{
                        itemId = [int]$itemId
                        itemName = $item.ItemName
                        creatureId = if ($item.CreatureId) { [int]$item.CreatureId } else { 0 }
                        familyId = 0
                        familyName = $speciesName
                        familyType = $familyType
                        icon = ""
                        isExotic = $false
                        source = "item-tooltip-species"
                    }
                    
                    $found++
                    Write-Host "    ✓ Found species in tooltip: $speciesName ($familyType)" -ForegroundColor Green
                    $success = $true
                    break
                }
            }
            
            # Strategy 3: Check for spell link (e.g., spell=944444)
            if ($response -match 'spell=(\d+)') {
                $spellId = $Matches[1]
                Write-Host "    → Found spell link: $spellId (could scrape for creature type)" -ForegroundColor Gray
                # Note: Could add spell scraping here in future
            }
            
            # No data found
            if (-not $success) {
                $notFound++
                Write-Host "    ✗ No family data or species found" -ForegroundColor Yellow
                $success = $true
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
