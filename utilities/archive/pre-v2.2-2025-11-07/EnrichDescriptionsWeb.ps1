<#
.SYNOPSIS
    Enriches missing item descriptions using multi-source web scraping

.DESCRIPTION
    Fetches zone/location data for items with empty descriptions using priority order:
    1. Game client data (already extracted)
    2. db.ascension.gg (primary - includes Ascension-specific content)
    3. wowhead.com/wotlk (fallback - classic WoW content)
    
    Updates MasterFullValidated.json with enriched data.

.PARAMETER ItemIds
    Specific item IDs to enrich (optional). If not provided, enriches all items
    with empty descriptions.

.PARAMETER DryRun
    Test mode - shows what would be enriched without making changes

.EXAMPLE
    .\EnrichFromWeb.ps1
    Enriches all items with empty descriptions

.EXAMPLE
    .\EnrichFromWeb.ps1 -ItemIds 79892,79893 -DryRun
    Test enrichment for specific items

.NOTES
    Author: AscensionVanity
    Last Updated: 2025-11-05
    Rate Limiting: 2 seconds between requests
    Priority: Game > db.ascension.gg > Wowhead
#>

param(
    [int[]]$ItemIds,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# File paths
$masterJsonPath = 'data/MasterFullValidated.json'
$manualEnrichmentsPath = 'data/Manual_Enrichments.json'
$outputPath = 'data/MasterFullValidated_Wowhead_Enriched.json'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Wowhead Description Enrichment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "[DRY RUN MODE] No changes will be saved`n" -ForegroundColor Yellow
}

# Load master JSON
Write-Host "[1/5] Loading master database..." -ForegroundColor Green
if (-not (Test-Path $masterJsonPath)) {
    Write-Host "  ERROR: $masterJsonPath not found!" -ForegroundColor Red
    exit 1
}

$items = Get-Content $masterJsonPath -Raw | ConvertFrom-Json
Write-Host "  Loaded $($items.Count) items" -ForegroundColor Gray

# Load manual enrichments if available
$manualEnrichments = @{}
if (Test-Path $manualEnrichmentsPath) {
    Write-Host "`n[2/5] Loading manual enrichments..." -ForegroundColor Green
    $manualData = Get-Content $manualEnrichmentsPath -Raw | ConvertFrom-Json
    foreach ($prop in $manualData.PSObject.Properties) {
        $manualEnrichments[$prop.Name] = $prop.Value
    }
    Write-Host "  Loaded $($manualEnrichments.Count) manual entries" -ForegroundColor Gray
} else {
    Write-Host "`n[2/5] No manual enrichments file found (skipping)" -ForegroundColor Yellow
}

# Identify items needing enrichment
Write-Host "`n[3/5] Identifying items needing enrichment..." -ForegroundColor Green

if ($ItemIds) {
    $needsEnrichment = $items | Where-Object { $_.DbItemId -in $ItemIds }
    Write-Host "  Processing $($needsEnrichment.Count) specified items" -ForegroundColor Gray
} else {
    $needsEnrichment = $items | Where-Object { 
        -not $_.Description -or $_.Description.Trim() -eq ''
    }
    Write-Host "  Found $($needsEnrichment.Count) items with empty descriptions" -ForegroundColor Gray
}

if ($needsEnrichment.Count -eq 0) {
    Write-Host "  No items need enrichment!" -ForegroundColor Green
    exit 0
}

# Load zone ID mappings
$zoneIdMapping = $null
if (Test-Path 'data/AscensionZoneIDs.json') {
    $zoneIdMapping = Get-Content 'data/AscensionZoneIDs.json' -Raw | ConvertFrom-Json
}

# Function to fetch data from db.ascension.gg (PRIMARY SOURCE)
function Get-AscensionItemData {
    param(
        [int]$ItemId,
        [string]$ItemName
    )
    
    $url = "https://db.ascension.gg/?item=$ItemId"
    
    try {
        Start-Sleep -Seconds 2  # Rate limiting
        
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        
        $result = @{
            Zone = $null
            Description = $null
            Found = $false
            Source = 'db.ascension.gg'
        }
        
        # Parse the "dropped-by" Listview data
        # Format: new Listview({"template":"npc",...,"data":[{..."location":[490],"name":"Devilsaur"...}]})
        if ($response.Content -match 'new Listview\(\{"template":"npc"[^{]*"data":\[([^\]]+)\]') {
            $npcData = $Matches[1]
            
            # Extract location ID array
            if ($npcData -match '"location":\[(\d+)\]') {
                $zoneId = $Matches[1]
                
                # Look up zone name from our mapping
                if ($script:zoneIdMapping -and $script:zoneIdMapping.$zoneId) {
                    $result.Zone = $script:zoneIdMapping.$zoneId
                    $result.Found = $true
                }
            }
            
            # Extract creature name if available
            if ($npcData -match '"name":"([^"]+)"') {
                $creatureName = $Matches[1]
            } else {
                $creatureName = $ItemName -replace '^[^:]+:\s*', ''  # Remove prefix from item name
            }
            
            # Create description
            if ($result.Zone) {
                $result.Description = "Has a chance to drop from $creatureName within $($result.Zone)"
            }
        }
        
        return $result
        
    } catch {
        Write-Host "    WARNING: db.ascension.gg failed - $_" -ForegroundColor Yellow
        return $null
    }
}

# Function to fetch data from Wowhead (FALLBACK SOURCE)
function Get-WowheadItemData {
    param(
        [int]$ItemId,
        [string]$ItemName
    )
    
    $url = "https://www.wowhead.com/wotlk/item=$ItemId"
    
    try {
        Start-Sleep -Seconds 2  # Rate limiting
        
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        
        $result = @{
            Zone = $null
            Description = $null
            Found = $false
            Source = 'wowhead.com'
        }
        
        # Parse dropped-by data from Wowhead
        # Look for zone in the dropped-by table or NPC tooltips
        if ($response.Content -match '"location":\[(\d+)\]') {
            $zoneId = $Matches[1]
            
            # Try to find zone name in the page
            if ($response.Content -match "zone=$zoneId[^>]*>([^<]+)</a>") {
                $result.Zone = $Matches[1].Trim()
                $result.Found = $true
            }
        }
        
        # Alternative: Look for explicit zone mentions
        if (-not $result.Zone -and $response.Content -match 'This item drops from.*?in\s+([^<\.]+)') {
            $result.Zone = $Matches[1].Trim()
            $result.Found = $true
        }
        
        # Create description
        if ($result.Zone) {
            $creatureName = $ItemName -replace '^[^:]+:\s*', ''  # Remove prefix
            $result.Description = "Has a chance to drop from $creatureName within $($result.Zone)"
        }
        
        return $result
        
    } catch {
        Write-Host "    WARNING: Wowhead failed - $_" -ForegroundColor Yellow
        return $null
    }
}

# Enrich items
Write-Host "`n[4/5] Enriching items from Wowhead..." -ForegroundColor Green
$enriched = 0
$manualApplied = 0
$failed = 0
$skipped = 0

$progressCount = 0
foreach ($item in $needsEnrichment) {
    $progressCount++
    $itemId = $item.DbItemId
    $creatureId = $item.CreatureId
    
    # Progress indicator every 10 items
    if ($progressCount % 10 -eq 0) {
        Write-Host "  Progress: $progressCount / $($needsEnrichment.Count) items..." -ForegroundColor Gray
    }
    
    # Check if we have manual enrichment for this item
    if ($manualEnrichments.ContainsKey($itemId.ToString())) {
        Write-Host "  [$itemId] Applying manual enrichment" -ForegroundColor Cyan
        $manual = $manualEnrichments[$itemId.ToString()]
        
        if ($manual.description) {
            $item | Add-Member -NotePropertyName "Description" -NotePropertyValue $manual.description -Force
        }
        if ($manual.zone) {
            $item | Add-Member -NotePropertyName "zone" -NotePropertyValue $manual.zone -Force
        }
        if ($manual.subzone) {
            $item | Add-Member -NotePropertyName "subzone" -NotePropertyValue $manual.subzone -Force
        }
        
        $manualApplied++
        continue
    }
    
    # Skip if no creature ID
    if ($creatureId -eq 0) {
        Write-Host "  [$itemId] No creature ID - skipping" -ForegroundColor DarkGray
        $skipped++
        continue
    }
    
    # Try db.ascension.gg first (PRIMARY SOURCE)
    Write-Host "  [$itemId] Fetching from db.ascension.gg..." -ForegroundColor White
    $ascensionData = Get-AscensionItemData -ItemId $itemId -ItemName $item.Name
    
    if ($ascensionData -and $ascensionData.Found) {
        Write-Host "    ✓ db.ascension.gg: $($ascensionData.Zone)" -ForegroundColor Green
        
        if ($ascensionData.Description) {
            $item | Add-Member -NotePropertyName "Description" -NotePropertyValue $ascensionData.Description -Force
        }
        if ($ascensionData.Zone) {
            $item | Add-Member -NotePropertyName "zone" -NotePropertyValue $ascensionData.Zone -Force
        }
        
        $enriched++
        continue
    }
    
    # Fallback to Wowhead if Ascension didn't have data
    Write-Host "    ⚠ db.ascension.gg: No data, trying Wowhead..." -ForegroundColor Yellow
    $wowheadData = Get-WowheadItemData -ItemId $itemId -ItemName $item.Name
    
    if ($wowheadData -and $wowheadData.Found) {
        Write-Host "    ✓ Wowhead: $($wowheadData.Zone)" -ForegroundColor Green
        
        if ($wowheadData.Description) {
            $item | Add-Member -NotePropertyName "Description" -NotePropertyValue $wowheadData.Description -Force
        }
        if ($wowheadData.Zone) {
            $item | Add-Member -NotePropertyName "zone" -NotePropertyValue $wowheadData.Zone -Force
        }
        
        $enriched++
    } else {
        Write-Host "    ✗ No data from any source" -ForegroundColor Red
        $failed++
    }
}

Write-Host "`n[5/5] Summary" -ForegroundColor Green
Write-Host "  Manual enrichments applied: $manualApplied" -ForegroundColor Cyan
Write-Host "  Wowhead enrichments: $enriched" -ForegroundColor Green
Write-Host "  Failed/No data: $failed" -ForegroundColor Yellow
Write-Host "  Skipped (no creature ID): $skipped" -ForegroundColor Gray
Write-Host "  Total processed: $($manualApplied + $enriched + $failed + $skipped)" -ForegroundColor White

if (-not $DryRun) {
    Write-Host "`nSaving enriched data..." -ForegroundColor Green
    $items | ConvertTo-Json -Depth 10 | Out-File $outputPath -Encoding UTF8
    Write-Host "  Saved to: $outputPath" -ForegroundColor Cyan
    
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "  1. Review: $outputPath"
    Write-Host "  2. If satisfied, copy to master:"
    Write-Host "     Copy-Item '$outputPath' '$masterJsonPath' -Force"
    Write-Host "  3. Re-run EnrichZoneData.ps1 to update zone fields"
    Write-Host "  4. Regenerate VanityDB.lua:"
    Write-Host "     .\utilities\GenerateVanityDB_Master.ps1"
} else {
    Write-Host "`n[DRY RUN] No files were modified" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Enrichment Complete!" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
