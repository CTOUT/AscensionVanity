<#
.SYNOPSIS
    Scrapes pet family data from db.ascension.gg to build comprehensive pet family mapping

.DESCRIPTION
    This script builds a complete database of pet families, their vanity items, abilities, and spell IDs.
    
    Data Structure:
    - Pet families (155 total)
    - Vanity items mapped to families
    - Abilities with spell IDs
    - Creature IDs mapped to families
    
    Output: data/PetFamilyMapping.json

.PARAMETER OutputPath
    Path to save the output JSON file (default: data/PetFamilyMapping.json)

.PARAMETER RateLimit
    Seconds to wait between requests (default: 2)

.PARAMETER CacheDays
    Maximum age of cache in days before refresh (default: 7)

.PARAMETER Force
    Force refresh even if cache is valid

.EXAMPLE
    .\ScrapePetFamilies.ps1
    Uses cached data if less than 7 days old
    
.EXAMPLE
    .\ScrapePetFamilies.ps1 -Force
    Forces refresh, ignoring cache
    
.EXAMPLE
    .\ScrapePetFamilies.ps1 -OutputPath "custom/output.json" -RateLimit 3 -CacheDays 30

.NOTES
    Author: CMTout
    Created: 2025-11-15
    
    This creates a shareable community resource for Ascension pet family data.
#>

param(
    [string]$OutputPath = "data\PetFamilyMapping.json",
    [int]$RateLimit = 2,
    [int]$CacheDays = 7,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Resolve paths
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptRoot
$outputFile = Join-Path $projectRoot $OutputPath
$outputDir = Split-Path -Parent $outputFile

# Ensure output directory exists
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "=== Pet Family Scraper for db.ascension.gg ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output: $outputFile" -ForegroundColor Gray
Write-Host "Rate Limit: $RateLimit seconds between requests" -ForegroundColor Gray
Write-Host "Cache Max Age: $CacheDays days" -ForegroundColor Gray
Write-Host ""

# Check if cache exists and is recent
if ((Test-Path $outputFile) -and -not $Force) {
    $fileAge = (Get-Date) - (Get-Item $outputFile).LastWriteTime
    
    if ($fileAge.TotalDays -lt $CacheDays) {
        Write-Host "✓ Using cached data (age: $([math]::Round($fileAge.TotalDays, 1)) days)" -ForegroundColor Green
        Write-Host "  File: $outputFile" -ForegroundColor Gray
        Write-Host "  Last updated: $((Get-Item $outputFile).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
        Write-Host ""
        Write-Host "To force refresh, run with -Force parameter" -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host "Cache expired (age: $([math]::Round($fileAge.TotalDays, 1)) days > $CacheDays days)" -ForegroundColor Yellow
        Write-Host "Refreshing data..." -ForegroundColor Yellow
        Write-Host ""
    }
} elseif ($Force) {
    Write-Host "Force refresh requested - ignoring cache" -ForegroundColor Yellow
    Write-Host ""
}

# Initialize result structure
$result = @{
    generatedDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    source = "https://db.ascension.gg/?pets"
    totalFamilies = 0
    families = @{}
    itemToFamily = @{}
    creatureToFamily = @{}
    familyAbilities = @{}
}

# Step 1: Get list of all pet families from embedded JavaScript data
Write-Host "Step 1: Fetching pet family list..." -ForegroundColor Yellow

try {
    $familiesPage = Invoke-WebRequest -Uri "https://db.ascension.gg/?pets" -UseBasicParsing
    
    # Extract JSON data from JavaScript (embedded in new Listview() call)
    # The data is a large JSON array embedded in JavaScript
    $jsonMatch = [regex]::Match($familiesPage.Content, '"data":(\[.*?\})\]')
    
    if (-not $jsonMatch.Success) {
        throw "Could not find pet data in page JavaScript"
    }
    
    # Add closing bracket and parse
    $jsonData = $jsonMatch.Groups[1].Value + "]"
    $families = $jsonData | ConvertFrom-Json
    
    Write-Host "  Found $($families.Count) pet families" -ForegroundColor Green
    $result.totalFamilies = $families.Count
    
} catch {
    Write-Host "  ERROR: Failed to fetch family list" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    exit 1
}

# Step 2: Process family data from embedded JSON
Write-Host ""
Write-Host "Step 2: Processing family data..." -ForegroundColor Yellow

$progress = 0
foreach ($family in $families) {
    $progress++
    $percentComplete = [math]::Round(($progress / $families.Count) * 100, 1)
    
    $familyId = $family.id
    $familyName = $family.name
    
    Write-Host "  [$progress/$($families.Count) - $percentComplete%] Processing: $familyName (ID: $familyId)" -ForegroundColor Cyan
    
    try {
        # Initialize family data from JSON
        $familyData = @{
            id = $familyId
            name = $familyName
            vanityItems = @()
            tameableCreatures = @()
            abilities = @()
            icon = "Interface\Icons\" + $family.icon
            familyType = switch ($family.type) {
                0 { "Ferocity" }  # DPS
                1 { "Tenacity" }  # Tank
                2 { "Cunning" }   # Utility
                3 { "Demon" }
                4 { "Undead" }
                5 { "Elemental" }
                6 { "Dragonkin" }
                default { "Unknown" }
            }
            isExotic = [bool]$family.exotic
        }
        
        # Extract ability spell IDs from embedded data
        if ($family.spells -and $family.spells.Count -gt 0) {
            foreach ($spellId in $family.spells) {
                $familyData.abilities += @{
                    spellId = $spellId
                    name = ""  # Will fetch later if needed
                }
            }
        }
        
        # Now scrape individual family page for vanity items and tameable creatures
        $familyUrl = "https://db.ascension.gg/?pet=$familyId"
        $familyPage = Invoke-WebRequest -Uri $familyUrl -UseBasicParsing
        
        # Parse vanity items from embedded JavaScript (new Listview for "tame-items")
        # Pattern: new Listview({"template":"item","id":"tame-items","parent":"lv-generic","data":[{...}]
        if ($familyPage.Content -match 'new Listview\(\{"template":"item","id":"tame-items".*?"data":(\[.*?\])\}') {
            $itemsJson = $Matches[1]
            
            try {
                $items = $itemsJson | ConvertFrom-Json
                
                foreach ($item in $items) {
                    $itemId = $item.id
                    $itemName = $item.name
                    
                    $familyData.vanityItems += @{
                        itemId = $itemId
                        name = $itemName
                    }
                    
                    # Add to reverse lookup (this is what we'll use in database generation)
                    $result.itemToFamily[$itemId.ToString()] = @{
                        familyId = $familyId
                        familyName = $familyName
                        familyType = $familyData.familyType
                        icon = $familyData.icon
                        abilities = $familyData.abilities
                        isExotic = $familyData.isExotic
                    }
                }
            } catch {
                Write-Host "    ! Failed to parse vanity items JSON: $_" -ForegroundColor Yellow
            }
        }
        
        # Parse tameable creatures from embedded JavaScript (new Listview for "tameable")
        # Find the start position and manually extract the JSON array
        if ($familyPage.Content -match 'new Listview\(\{"template":"npc","id":"tameable"') {
            $startPos = $familyPage.Content.IndexOf('"data":[', $Matches.Index)
            
            if ($startPos -gt 0) {
                $startPos += 7  # Skip past "data":
                
                # Find matching closing bracket by counting brackets
                $bracketCount = 0
                $endPos = $startPos
                $inString = $false
                $escaped = $false
                
                for ($i = $startPos; $i -lt $familyPage.Content.Length; $i++) {
                    $char = $familyPage.Content[$i]
                    
                    if ($escaped) {
                        $escaped = $false
                        continue
                    }
                    
                    if ($char -eq '\') {
                        $escaped = $true
                        continue
                    }
                    
                    if ($char -eq '"') {
                        $inString = -not $inString
                        continue
                    }
                    
                    if (-not $inString) {
                        if ($char -eq '[') { $bracketCount++ }
                        if ($char -eq ']') {
                            $bracketCount--
                            if ($bracketCount -eq 0) {
                                $endPos = $i + 1
                                break
                            }
                        }
                    }
                }
                
                $creaturesJson = $familyPage.Content.Substring($startPos, $endPos - $startPos)
                
                try {
                    $creatures = $creaturesJson | ConvertFrom-Json
                
                foreach ($creature in $creatures) {
                    $creatureId = $creature.id
                    $creatureName = $creature.name
                    
                    $familyData.tameableCreatures += @{
                        creatureId = $creatureId
                        name = $creatureName
                    }
                    
                    # Add to reverse lookup (for future tooltip enhancements)
                    $result.creatureToFamily[$creatureId.ToString()] = @{
                        familyId = $familyId
                        familyName = $familyName
                    }
                    }
                } catch {
                    Write-Host "    ! Failed to parse tameable creatures JSON: $_" -ForegroundColor Yellow
                }
            }
        }
        
        # Store family data
        $result.families[$family.id.ToString()] = $familyData
        
        # Store abilities in separate lookup
        $result.familyAbilities[$family.id.ToString()] = $familyData.abilities
        
        Write-Host "    ✓ Items: $($familyData.vanityItems.Count) | Creatures: $($familyData.tameableCreatures.Count) | Abilities: $($familyData.abilities.Count)" -ForegroundColor Gray
        
    } catch {
        Write-Host "    ✗ ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Rate limiting
    if ($progress -lt $families.Count) {
        Start-Sleep -Seconds $RateLimit
    }
}

# Step 3: Save results
Write-Host ""
Write-Host "Step 3: Saving results..." -ForegroundColor Yellow

try {
    $jsonOutput = $result | ConvertTo-Json -Depth 10
    $jsonOutput | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-Host "  ✓ Saved to: $outputFile" -ForegroundColor Green
    
} catch {
    Write-Host "  ✗ ERROR: Failed to save output" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    exit 1
}

# Step 4: Generate summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Total Families: $($result.totalFamilies)" -ForegroundColor White
Write-Host "  Total Vanity Items: $($result.itemToFamily.Count)" -ForegroundColor White
Write-Host "  Total Tameable Creatures: $($result.creatureToFamily.Count)" -ForegroundColor White

$totalAbilities = ($result.familyAbilities.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
Write-Host "  Total Abilities: $totalAbilities" -ForegroundColor White

Write-Host ""
Write-Host "✓ Scraping complete! Output saved to: $outputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review the output JSON file" -ForegroundColor Gray
Write-Host "  2. Run GenerateVanityDB_Master.ps1 to integrate pet family data" -ForegroundColor Gray
Write-Host "  3. Test in-game with the Collection UI" -ForegroundColor Gray
