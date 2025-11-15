<#
.SYNOPSIS
    Scrapes "Pet" skills from db.ascension.gg to discover hidden pet families

.DESCRIPTION
    Complements ScrapePetFamilies.ps1 by finding pet families that don't appear
    in the tameable pets list (?pets page).
    
    Discovery: Many combat pets belong to families only documented in the 
    skills database (e.g., "Pet - Dreadwood Treant").
    
    Source: https://db.ascension.gg/?skills (392 "Pet" results)
    
    Output: data/PetSkillsMapping.json

.PARAMETER OutputPath
    Path to save the output JSON file (default: data/PetSkillsMapping.json)

.PARAMETER RateLimit
    Seconds to wait between requests (default: 2)

.PARAMETER MaxResults
    Maximum number of skills to scrape (default: 500, covers all 392)

.EXAMPLE
    .\ScrapePetSkills.ps1
    
.EXAMPLE
    .\ScrapePetSkills.ps1 -MaxResults 50
    Test with first 50 results

.NOTES
    Author: CMTout
    Created: 2025-11-15
    
    This fills gaps left by the tameable pets scraper.
#>

param(
    [string]$OutputPath = "data\PetSkillsMapping.json",
    [int]$RateLimit = 2,
    [int]$MaxResults = 500
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

Write-Host "=== Pet Skills Scraper for db.ascension.gg ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Source: https://db.ascension.gg/?skills" -ForegroundColor Gray
Write-Host "Output: $outputFile" -ForegroundColor Gray
Write-Host "Rate Limit: $RateLimit seconds" -ForegroundColor Gray
Write-Host "Max Results: $MaxResults" -ForegroundColor Gray
Write-Host ""

# Initialize result structure
$result = @{
    generatedDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    source = "https://db.ascension.gg/?skills"
    totalSkills = 0
    petFamilies = @{}
}

# Family type mapping (for when we can determine it)
$familyTypes = @{
    0 = "Ferocity"
    1 = "Tenacity"
    2 = "Cunning"
    3 = "Demon"
    4 = "Undead"
    5 = "Elemental"
    6 = "Dragonkin"
}

Write-Host "Step 1: Fetching skill list..." -ForegroundColor Yellow

try {
    # Search for "Pet" in skills category
    $skillsPage = Invoke-WebRequest -Uri "https://db.ascension.gg/?skills" -UseBasicParsing
    
    # Extract listview JSON (skills are in a Listview)
    # Pattern: new Listview({"template":"spell","id":"skills",...,"data":[...]})
    if ($skillsPage.Content -match 'new Listview\(\{"template":"spell","id":"skills".*?"data":(\[.*?\])') {
        $jsonData = $Matches[1]
        $skills = $jsonData | ConvertFrom-Json
        
        # Filter to only "Pet" skills
        $petSkills = $skills | Where-Object { $_.name -like "Pet*" }
        
        Write-Host "  Found $($petSkills.Count) pet skills (from $($skills.Count) total)" -ForegroundColor Green
        
        # Limit results if needed
        if ($petSkills.Count -gt $MaxResults) {
            Write-Host "  Limiting to first $MaxResults results" -ForegroundColor Yellow
            $petSkills = $petSkills | Select-Object -First $MaxResults
        }
        
        $result.totalSkills = $petSkills.Count
        
    } else {
        throw "Could not find skills listview in page JavaScript"
    }
    
} catch {
    Write-Host "  ERROR: Failed to fetch skills list" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Processing pet skills..." -ForegroundColor Yellow

$processed = 0
$foundAbilities = 0

foreach ($skill in $petSkills) {
    $processed++
    $percentComplete = [math]::Round(($processed / $petSkills.Count) * 100, 1)
    
    $skillId = $skill.id
    $skillName = $skill.name
    
    # Extract family name (remove "Pet - " or "Pet- " prefix)
    $familyName = $skillName -replace '^Pet-?\s*', ''
    
    Write-Host "  [$processed/$($petSkills.Count) - $percentComplete%] Processing: $familyName (Skill: $skillId)" -ForegroundColor Cyan
    
    try {
        # Scrape individual skill page for abilities
        $skillUrl = "https://db.ascension.gg/?skill=$skillId"
        $skillPage = Invoke-WebRequest -Uri $skillUrl -UseBasicParsing
        
        # Extract abilities from the skill page
        # Pattern: new Listview({"template":"spell",...,"data":[...]})
        $abilities = @()
        
        if ($skillPage.Content -match 'new Listview\(\{"template":"spell".*?"data":(\[.*?\])') {
            $abilitiesJson = $Matches[1]
            
            try {
                $abilityList = $abilitiesJson | ConvertFrom-Json
                
                foreach ($ability in $abilityList) {
                    $abilities += @{
                        spellId = $ability.id
                        name = $ability.name
                        icon = "Interface\Icons\$($ability.icon)"
                    }
                }
                
                $foundAbilities += $abilities.Count
                
            } catch {
                Write-Host "    ! Failed to parse abilities JSON" -ForegroundColor Yellow
            }
        }
        
        # Attempt to determine family type from skill description or abilities
        # This is heuristic-based since skills don't directly state the type
        $familyType = "Unknown"
        
        # Heuristic: Demon/Undead/Elemental/Dragonkin are usually obvious
        if ($familyName -match 'Demon|Doomguard|Fel|Satyr|Eredar|Shivarra') {
            $familyType = "Demon"
        } elseif ($familyName -match 'Undead|Skeleton|Ghoul|Zombie|Wraith|Lich|Shade') {
            $familyType = "Undead"
        } elseif ($familyName -match 'Elemental|Revenant|Golem|Phoenix|Lasher|Treant') {
            $familyType = "Elemental"
        } elseif ($familyName -match 'Dragon|Drake|Whelp|Wyrm|Wyrmkin') {
            $familyType = "Dragonkin"
        }
        # Otherwise leave as Unknown (could be Ferocity/Tenacity/Cunning)
        
        # Store family data
        $result.petFamilies[$familyName] = @{
            skillId = $skillId
            familyName = $familyName
            familyType = $familyType
            abilities = $abilities
            source = "skills-database"
        }
        
        Write-Host "    ✓ Found $($abilities.Count) abilities | Type: $familyType" -ForegroundColor Gray
        
    } catch {
        Write-Host "    ✗ ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Rate limiting
    if ($processed -lt $petSkills.Count) {
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
Write-Host "  Total Pet Skills: $($result.totalSkills)" -ForegroundColor White
Write-Host "  Unique Pet Families: $($result.petFamilies.Count)" -ForegroundColor White
Write-Host "  Total Abilities: $foundAbilities" -ForegroundColor White

# Breakdown by type
$typeBreakdown = $result.petFamilies.Values | Group-Object familyType | Sort-Object Count -Descending
Write-Host ""
Write-Host "  Family Type Breakdown:" -ForegroundColor Yellow
foreach ($group in $typeBreakdown) {
    Write-Host "    $($group.Name): $($group.Count)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✓ Scraping complete! Output saved to: $outputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review families not in PetFamilyMapping.json" -ForegroundColor Gray
Write-Host "  2. Merge with existing family data" -ForegroundColor Gray
Write-Host "  3. Re-run EnrichMissingPetFamilies.ps1 with expanded family list" -ForegroundColor Gray
