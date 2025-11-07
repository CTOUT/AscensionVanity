<#
.SYNOPSIS
    Enriches missing item descriptions using multi-source web scraping

.DESCRIPTION
    Priority order (optimized for Ascension-only items):
    1. Manual enrichments (from Manual_Enrichments.json)
    2. db.ascension.gg by item ID (best for seeing all NPCs that drop)
    3. db.ascension.gg by creature ID
    4. db.ascension.gg by creature name search
    
    Note: Wowhead not included as these are Ascension-only combat pets

.PARAMETER ItemIds
    Specific item IDs to enrich (optional)

.PARAMETER DryRun
    Test mode - shows what would be enriched without saving

.EXAMPLE
    .\EnrichMissingDescriptions.ps1
    Enriches all items with empty descriptions

.EXAMPLE
    .\EnrichMissingDescriptions.ps1 -ItemIds 79892,79893
    Enrich specific items

.NOTES
    Author: AscensionVanity
    Last Updated: 2025-11-05
    Rate Limiting: 2 seconds between requests
#>

param(
    [int[]]$ItemIds,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# File paths
$masterJsonPath = 'data/MasterFullValidated.json'
$manualEnrichmentsPath = 'data/Manual_Enrichments.json'
$zoneMapPath = 'data/AscensionZoneMap.json'
$outputPath = 'data/MasterFullValidated_WebEnriched.json'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Multi-Source Description Enrichment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "[DRY RUN MODE] No changes will be saved`n" -ForegroundColor Yellow
}

# Load zone mapping
Write-Host "[1/6] Loading zone mappings..." -ForegroundColor Green
if (-not (Test-Path $zoneMapPath)) {
    Write-Host "  ERROR: $zoneMapPath not found!" -ForegroundColor Red
    Write-Host "  Create it with: Get-Content data\zones_list.html | Select-String '`"id`":(\d+).*?`"name`":`"([^`"]+)`"' -AllMatches | % Matches | % { `$zoneMap.Add(`$_.Groups[1].Value, `$_.Groups[2].Value) }" -ForegroundColor Yellow
    exit 1
}
$zoneMapJson = Get-Content $zoneMapPath -Raw | ConvertFrom-Json
$script:zoneMap = @{}
foreach ($prop in $zoneMapJson.PSObject.Properties) {
    $script:zoneMap[$prop.Name] = $prop.Value
}
Write-Host "  Loaded $($script:zoneMap.Count) zone mappings" -ForegroundColor Gray

# Load master JSON
Write-Host "`n[2/6] Loading master database..." -ForegroundColor Green
$items = Get-Content $masterJsonPath -Raw | ConvertFrom-Json
Write-Host "  Loaded $($items.Count) items" -ForegroundColor Gray

# Load manual enrichments
$manualEnrichments = @{}
if (Test-Path $manualEnrichmentsPath) {
    Write-Host "`n[3/6] Loading manual enrichments..." -ForegroundColor Green
    $manualData = Get-Content $manualEnrichmentsPath -Raw | ConvertFrom-Json
    foreach ($prop in $manualData.PSObject.Properties) {
        $manualEnrichments[$prop.Name] = $prop.Value
    }
    Write-Host "  Loaded $($manualEnrichments.Count) manual entries" -ForegroundColor Gray
} else {
    Write-Host "`n[3/6] No manual enrichments file (skipping)" -ForegroundColor Yellow
}

# Identify items needing enrichment
Write-Host "`n[4/6] Identifying items needing enrichment..." -ForegroundColor Green
if ($ItemIds) {
    $needsEnrichment = $items | Where-Object { $_.DbItemId -in $ItemIds }
} else {
    $needsEnrichment = $items | Where-Object { -not $_.Description -or $_.Description.Trim() -eq '' }
}
Write-Host "  Found $($needsEnrichment.Count) items" -ForegroundColor Gray

if ($needsEnrichment.Count -eq 0) {
    Write-Host "  No items need enrichment!" -ForegroundColor Green
    exit 0
}

# Helper function to extract creature name from item name
function Get-CreatureNameFromItem {
    param([string]$ItemName)
    if ($ItemName -match '^[^:]+:\s*(.+)$') {
        return $Matches[1].Trim()
    }
    return $ItemName
}

# Method 1: db.ascension.gg by item ID (BEST - shows all NPCs that drop it)
function Get-AscensionItemData {
    param([int]$ItemId, [string]$ItemName)
    
    $url = "https://db.ascension.gg/?item=$ItemId"
    try {
        Start-Sleep -Seconds 2
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        
        $matches = [regex]::Matches($response.Content, 'new Listview\({"template":"npc","id":"dropped-by"[^}]+?"data":\[([^\]]+)\]')
        if ($matches.Count -gt 0) {
            $dataJson = $matches[0].Groups[1].Value
            $npcMatches = [regex]::Matches($dataJson, '"id":(\d+).*?"location":\[(\d+)\].*?"name":"([^"]+)"')
            
            if ($npcMatches.Count -gt 0) {
                # Prefer lowest ID (original, not custom Ascension NPC)
                $sortedMatches = $npcMatches | Sort-Object { [int]$_.Groups[1].Value }
                $match = $sortedMatches[0]
                
                $npcId = $match.Groups[1].Value
                $zoneId = $match.Groups[2].Value
                $npcName = $match.Groups[3].Value
                
                if ($script:zoneMap.ContainsKey($zoneId)) {
                    $zoneName = $script:zoneMap[$zoneId]
                    return @{
                        Zone = $zoneName
                        Description = "Has a chance to drop from $npcName within $zoneName"
                        Source = "db.ascension.gg (item -> NPC #$npcId, zone #$zoneId)"
                        Found = $true
                    }
                }
            }
        }
        return $null
    } catch {
        return $null
    }
}

# Method 2: db.ascension.gg by creature ID
function Get-AscensionCreatureData {
    param([int]$CreatureId, [string]$ItemName)
    if ($CreatureId -eq 0) { return $null }
    
    $url = "https://db.ascension.gg/?npc=$CreatureId"
    try {
        Start-Sleep -Seconds 2
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        
        if ($response.Content -match 'This NPC can be found in[^<]*<span[^>]*>.*?<a[^>]+>([^<]+)</a>') {
            $zoneName = $Matches[1].Trim()
            $creatureName = Get-CreatureNameFromItem -ItemName $ItemName
            return @{
                Zone = $zoneName
                Description = "Has a chance to drop from $creatureName within $zoneName"
                Source = "db.ascension.gg (creature #$CreatureId)"
                Found = $true
            }
        }
        return $null
    } catch {
        return $null
    }
}

# Method 3: db.ascension.gg creature name search
function Search-AscensionCreatureName {
    param([string]$CreatureName)
    
    $searchUrl = "https://db.ascension.gg/?npcs&filter=na=$([uri]::EscapeDataString($CreatureName))"
    try {
        Start-Sleep -Seconds 2
        $response = Invoke-WebRequest -Uri $searchUrl -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        
        $matches = [regex]::Matches($response.Content, '"id":(\d+).*?"location":\[(\d+)\].*?"name":"([^"]+)"')
        if ($matches.Count -gt 0) {
            $exactMatch = $matches | Where-Object { $_.Groups[3].Value -eq $CreatureName } | Sort-Object { [int]$_.Groups[1].Value } | Select-Object -First 1
            $match = if ($exactMatch) { $exactMatch } else { ($matches | Sort-Object { [int]$_.Groups[1].Value })[0] }
            
            $npcId = $match.Groups[1].Value
            $zoneId = $match.Groups[2].Value
            $npcName = $match.Groups[3].Value
            
            if ($script:zoneMap.ContainsKey($zoneId)) {
                $zoneName = $script:zoneMap[$zoneId]
                return @{
                    Zone = $zoneName
                    Description = "Has a chance to drop from $npcName within $zoneName"
                    Source = "db.ascension.gg (search '$CreatureName' -> NPC #$npcId)"
                    Found = $true
                }
            }
        }
        return $null
    } catch {
        return $null
    }
}

# Enrich items
Write-Host "`n[5/6] Enriching items..." -ForegroundColor Green
$stats = @{ Manual = 0; Method1 = 0; Method2 = 0; Method3 = 0; Failed = 0 }

$progressCount = 0
foreach ($item in $needsEnrichment) {
    $progressCount++
    $itemId = $item.DbItemId
    $creatureId = $item.CreatureId
    $itemName = $item.Name
    
    if ($progressCount % 5 -eq 0) {
        Write-Host "  Progress: $progressCount / $($needsEnrichment.Count)" -ForegroundColor Gray
    }
    
    # Priority 1: Manual enrichment
    if ($manualEnrichments.ContainsKey($itemId.ToString())) {
        Write-Host "  [$itemId] Manual" -ForegroundColor Cyan
        $manual = $manualEnrichments[$itemId.ToString()]
        if ($manual.description) { $item | Add-Member -NotePropertyName "Description" -NotePropertyValue $manual.description -Force }
        if ($manual.zone) { $item | Add-Member -NotePropertyName "zone" -NotePropertyValue $manual.zone -Force }
        if ($manual.subzone) { $item | Add-Member -NotePropertyName "subzone" -NotePropertyValue $manual.subzone -Force }
        $stats.Manual++
        continue
    }
    
    Write-Host "  [$itemId] $itemName" -ForegroundColor White
    
    # Priority 2: db.ascension.gg by item ID
    $result = Get-AscensionItemData -ItemId $itemId -ItemName $itemName
    if ($result -and $result.Found) {
        Write-Host "    ✓ $($result.Source)" -ForegroundColor Green
        $item | Add-Member -NotePropertyName "Description" -NotePropertyValue $result.Description -Force
        $item | Add-Member -NotePropertyName "zone" -NotePropertyValue $result.Zone -Force
        $stats.Method1++
        continue
    }
    
    # Priority 3: db.ascension.gg by creature ID
    $result = Get-AscensionCreatureData -CreatureId $creatureId -ItemName $itemName
    if ($result -and $result.Found) {
        Write-Host "    ✓ $($result.Source)" -ForegroundColor Green
        $item | Add-Member -NotePropertyName "Description" -NotePropertyValue $result.Description -Force
        $item | Add-Member -NotePropertyName "zone" -NotePropertyValue $result.Zone -Force
        $stats.Method2++
        continue
    }
    
    # Priority 4: db.ascension.gg by creature name
    $creatureName = Get-CreatureNameFromItem -ItemName $itemName
    $result = Search-AscensionCreatureName -CreatureName $creatureName
    if ($result -and $result.Found) {
        Write-Host "    ✓ $($result.Source)" -ForegroundColor Green
        $item | Add-Member -NotePropertyName "Description" -NotePropertyValue $result.Description -Force
        $item | Add-Member -NotePropertyName "zone" -NotePropertyValue $result.Zone -Force
        $stats.Method3++
        continue
    }
    
    Write-Host "    ✗ Failed" -ForegroundColor Red
    $stats.Failed++
}

Write-Host "`n[6/6] Summary" -ForegroundColor Green
Write-Host "  Manual: $($stats.Manual)" -ForegroundColor Cyan
Write-Host "  db.ascension (item): $($stats.Method1)" -ForegroundColor Green
Write-Host "  db.ascension (creature): $($stats.Method2)" -ForegroundColor Green
Write-Host "  db.ascension (search): $($stats.Method3)" -ForegroundColor Green
Write-Host "  Failed: $($stats.Failed)" -ForegroundColor Red
Write-Host "  Success Rate: $([math]::Round(($stats.Method1 + $stats.Method2 + $stats.Method3) / $needsEnrichment.Count * 100, 1))%" -ForegroundColor Cyan

if (-not $DryRun) {
    Write-Host "`nSaving..." -ForegroundColor Green
    $items | ConvertTo-Json -Depth 10 | Out-File $outputPath -Encoding UTF8
    Write-Host "  Saved: $outputPath" -ForegroundColor Cyan
    
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "  1. Review: $outputPath"
    Write-Host "  2. Copy: Copy-Item '$outputPath' '$masterJsonPath' -Force"
    Write-Host "  3. Re-enrich zones: .\utilities\EnrichZoneData.ps1"
    Write-Host "  4. Regenerate: .\utilities\GenerateVanityDB_Master.ps1"
} else {
    Write-Host "`n[DRY RUN] No files modified" -ForegroundColor Yellow
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
