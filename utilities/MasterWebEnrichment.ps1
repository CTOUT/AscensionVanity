<#
.SYNOPSIS
    Master web enrichment script - consolidates all db.ascension.gg scraping

.DESCRIPTION
    Single unified script that handles all external web enrichment:
    
    1. Pet Family Data:
       - Scrapes 155 pet families from db.ascension.gg/?pets
       - Maps 9,292 tameable creatures to families
       - Enriches missing items by scraping individual item pages
       
    2. Item Descriptions:
       - Fetches descriptions for items with empty/missing descriptions
       - Sources from db.ascension.gg item pages
       
    3. Zone/Location Data:
       - Parses descriptions to extract zone/subzone information
       - Uses existing ZoneMappings.json for validation
    
    Features:
    - Smart caching (configurable TTL)
    - Progress tracking and batch saves
    - Rate limiting (respectful to source)
    - Resumable (skips already enriched items)

.PARAMETER Force
    Force refresh all data, ignoring cache

.PARAMETER SkipPetFamilies
    Skip pet family enrichment

.PARAMETER SkipDescriptions
    Skip description enrichment

.PARAMETER SkipZones
    Skip zone/subzone extraction

.PARAMETER RateLimit
    Seconds between web requests (default: 2)

.PARAMETER CacheDays
    Maximum cache age in days (default: 7)

.EXAMPLE
    .\MasterWebEnrichment.ps1
    Run all enrichments with default settings
    
.EXAMPLE
    .\MasterWebEnrichment.ps1 -Force -RateLimit 3
    Force refresh all data with 3-second rate limit
    
.EXAMPLE
    .\MasterWebEnrichment.ps1 -SkipDescriptions
    Only enrich pet families and zones

.NOTES
    Author: CMTout
    Created: 2025-11-15
    Version: 1.0
    
    Consolidates:
    - ScrapePetFamilies.ps1
    - EnrichMissingPetFamilies.ps1
    - MasterDescriptionEnrichment.ps1
    - EnrichZoneData.ps1
#>

param(
    [switch]$Force,
    [switch]$SkipPetFamilies,
    [switch]$SkipDescriptions,
    [switch]$SkipZones,
    [int]$RateLimit = 2,
    [int]$CacheDays = 7
)

$ErrorActionPreference = "Stop"

# Resolve paths
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptRoot
$dataPath = Join-Path $projectRoot "data"

# Output files
$petFamilyMapping = Join-Path $dataPath "PetFamilyMapping.json"
$missingPetFamilies = Join-Path $dataPath "MissingPetFamilies_Enriched.json"
$masterJson = Join-Path $dataPath "MasterFullValidated.json"
$zoneEnrichedJson = Join-Path $dataPath "MasterFullValidated_ZoneEnriched.json"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           Master Web Enrichment - db.ascension.gg             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script consolidates all web scraping into one workflow" -ForegroundColor Gray
Write-Host "Rate Limit: $RateLimit seconds | Cache TTL: $CacheDays days" -ForegroundColor Gray
Write-Host ""

$startTime = Get-Date

# ==============================================================================
# PHASE 1: PET FAMILY DATA
# ==============================================================================

if (-not $SkipPetFamilies) {
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "PHASE 1: Pet Family Enrichment" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Check cache
    $needsRefresh = $true
    if ((Test-Path $petFamilyMapping) -and -not $Force) {
        $fileAge = (Get-Date) - (Get-Item $petFamilyMapping).LastWriteTime
        if ($fileAge.TotalDays -lt $CacheDays) {
            Write-Host "✓ Pet family mapping cached ($([math]::Round($fileAge.TotalDays, 1)) days old)" -ForegroundColor Green
            $needsRefresh = $false
        } else {
            Write-Host "⟳ Cache expired ($([math]::Round($fileAge.TotalDays, 1)) days > $CacheDays days)" -ForegroundColor Yellow
        }
    }
    
    if ($needsRefresh -or $Force) {
        Write-Host "Running ScrapePetFamilies.ps1..." -ForegroundColor Yellow
        & (Join-Path $scriptRoot "ScrapePetFamilies.ps1") -OutputPath $petFamilyMapping -RateLimit $RateLimit -Force:$Force
    }
    
    # Now enrich missing items (those not in tameable creature list)
    Write-Host ""
    Write-Host "Checking for items needing individual page scraping..." -ForegroundColor Yellow
    
    # Load current database and check coverage
    if (Test-Path (Join-Path $projectRoot "AscensionVanity\VanityDB.lua")) {
        $db = Get-Content (Join-Path $projectRoot "AscensionVanity\VanityDB.lua") -Raw
        $itemsWithFamily = [regex]::Matches($db, 'petFamily\s*=\s*\{').Count
        
        # Count combat pet items more reliably using the database metadata or item count
        # Look for items in the combat pet categories (not counting mounts/companions)
        if ($db -match 'totalItems\s*=\s*(\d+)') {
            $totalItems = [int]$Matches[1]
        } else {
            $totalItems = 0
        }
        
        # Better approach: Count from MasterFullValidated.json if available
        $masterJsonPath = Join-Path $dataPath "MasterFullValidated.json"
        if (Test-Path $masterJsonPath) {
            $master = Get-Content $masterJsonPath -Raw | ConvertFrom-Json
            $combatPets = @($master | Where-Object { 
                $_.Category -match "Beastmaster's Whistle|Blood Soaked Vellum|Summoner's Stone|Draconic Warhorn|Elemental Lodestone"
            })
            $totalCombatPets = $combatPets.Count
        } else {
            # Fallback: assume all items with family data are combat pets
            $totalCombatPets = $itemsWithFamily
        }
        
        if ($totalCombatPets -gt 0) {
            $coverage = [math]::Round($itemsWithFamily/$totalCombatPets*100,1)
            Write-Host "  Current coverage: $itemsWithFamily / $totalCombatPets ($coverage%)" -ForegroundColor Gray
            
            if ($itemsWithFamily -lt $totalCombatPets) {
                $missing = $totalCombatPets - $itemsWithFamily
                Write-Host "  Need to enrich $missing items via individual page scraping" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Running EnrichMissingPetFamilies.ps1..." -ForegroundColor Yellow
                & (Join-Path $scriptRoot "EnrichMissingPetFamilies.ps1") -RateLimit $RateLimit
            } else {
                Write-Host "  ✓ All combat pets already have family data!" -ForegroundColor Green
            }
        } else {
            Write-Host "  ⚠ Could not determine combat pet count - skipping coverage check" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ⚠ VanityDB.lua not found - skipping coverage check" -ForegroundColor Yellow
    }
    
    Write-Host ""
} else {
    Write-Host "[SKIPPED] Pet family enrichment" -ForegroundColor Gray
    Write-Host ""
}

# ==============================================================================
# PHASE 2: ITEM DESCRIPTIONS
# ==============================================================================

if (-not $SkipDescriptions) {
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "PHASE 2: Description Enrichment" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Running MasterDescriptionEnrichment.ps1..." -ForegroundColor Yellow
    & (Join-Path $scriptRoot "MasterDescriptionEnrichment.ps1") -RateLimitSeconds $RateLimit
    
    Write-Host ""
} else {
    Write-Host "[SKIPPED] Description enrichment" -ForegroundColor Gray
    Write-Host ""
}

# ==============================================================================
# PHASE 3: ZONE/LOCATION DATA
# ==============================================================================

if (-not $SkipZones) {
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "PHASE 3: Zone/Location Extraction" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Running EnrichZoneData.ps1..." -ForegroundColor Yellow
    Write-Host "(No web scraping - parses existing descriptions)" -ForegroundColor Gray
    & (Join-Path $scriptRoot "EnrichZoneData.ps1")
    
    Write-Host ""
} else {
    Write-Host "[SKIPPED] Zone/location extraction" -ForegroundColor Gray
    Write-Host ""
}

# ==============================================================================
# SUMMARY
# ==============================================================================

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                  ENRICHMENT COMPLETE!                          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Duration: $([math]::Round($duration.TotalMinutes, 1)) minutes" -ForegroundColor White
Write-Host ""
Write-Host "Enriched Data Files:" -ForegroundColor Yellow
if (-not $SkipPetFamilies) {
    Write-Host "  ✓ $petFamilyMapping" -ForegroundColor Green
    if (Test-Path $missingPetFamilies) {
        Write-Host "  ✓ $missingPetFamilies" -ForegroundColor Green
    }
}
if (-not $SkipZones) {
    Write-Host "  ✓ $zoneEnrichedJson" -ForegroundColor Green
}
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review enriched data files for accuracy" -ForegroundColor Gray
Write-Host "  2. Copy zone-enriched JSON to master:" -ForegroundColor Gray
Write-Host "     Copy-Item '$zoneEnrichedJson' '$masterJson' -Force" -ForegroundColor Cyan
Write-Host "  3. Regenerate database with enriched data:" -ForegroundColor Gray
Write-Host "     .\utilities\GenerateVanityDB_Master.ps1" -ForegroundColor Cyan
Write-Host ""
