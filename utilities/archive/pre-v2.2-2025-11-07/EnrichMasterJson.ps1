# Enrich MasterFullValidated.json with zone/location descriptions
# Queries db.ascension.gg and Wowhead WOTLK for NPC locations

#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter()]
    [string]$InputJson = 'data/MasterFullValidated.json',
    
    [Parameter()]
    [string]$OutputJson = 'data/MasterFullValidated.json',
    
    [Parameter()]
    [string]$CacheFile = 'data/corrections/EnrichmentCache.json',
    
    [Parameter()]
    [int]$RateLimitSeconds = 2,
    
    [Parameter()]
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

function Write-Step { param([string]$Message) Write-Host "[STEP] $Message" -ForegroundColor Cyan }
function Write-Info { param([string]$Message) Write-Host "  $Message" -ForegroundColor Gray }
function Write-Success { param([string]$Message) Write-Host "  ✓ $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "  ⚠ $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "  ✗ $Message" -ForegroundColor Red }

if (-not (Test-Path $InputJson)) {
    Write-Error "Input JSON not found: $InputJson"
    exit 1
}

Write-Step "Loading MasterFullValidated.json"
$items = Get-Content $InputJson -Raw | ConvertFrom-Json
$totalItems = $items.Count
Write-Info "Total items: $totalItems"

# Load enrichment cache
$cache = @{}
if (Test-Path $CacheFile) {
    Write-Step "Loading enrichment cache: $CacheFile"
    $cacheData = Get-Content $CacheFile -Raw | ConvertFrom-Json
    foreach ($entry in $cacheData) {
        $cache[$entry.CreatureId] = $entry
    }
    Write-Info "Loaded $($cache.Count) cached lookups"
} else {
    Write-Info "No cache file found - will create new cache"
}

# Find items needing enrichment (no description and has CreatureId)
$needsEnrichment = $items | Where-Object { 
    (-not $_.Description -or $_.Description -eq '') -and 
    $_.CreatureId -and 
    $_.CreatureId -gt 0 
}

Write-Info "Items needing enrichment: $($needsEnrichment.Count)"

if ($needsEnrichment.Count -eq 0) {
    Write-Success "All items already have descriptions!"
    exit 0
}

Write-Step "Enriching descriptions from db.ascension.gg and Wowhead WOTLK"

$foundCount = 0
$notFoundCount = 0
$errorCount = 0
$cacheHits = 0
$index = 0
$newCacheEntries = @()

foreach ($item in $needsEnrichment) {
    $index++
    
    # Extract NPC name from full item name
    $npcName = if ($item.Name -match ':\s*(.+)$') { $matches[1] } else { $item.Name }
    
    Write-Host "  [$index/$($needsEnrichment.Count)] $npcName (Creature $($item.CreatureId))" -ForegroundColor White
    
    $zone = $null
    $source = $null
    
    # Check cache first
    if ($cache.ContainsKey($item.CreatureId)) {
        $cached = $cache[$item.CreatureId]
        $zone = $cached.Zone
        $source = "$($cached.Source) (cached)"
        Write-Success "Found in cache: $zone"
        $item.Description = "Has a chance to drop from $npcName within $zone"
        $item.Validated = $true
        $foundCount++
        $cacheHits++
        continue
    }
    
    # Strategy 1: Try db.ascension.gg first (most reliable for Ascension)
    $ascensionUrl = "https://db.ascension.gg/?npc=$($item.CreatureId)"
    Write-Info "→ Checking db.ascension.gg..."
    
    try {
        $response = Invoke-WebRequest -Uri $ascensionUrl -UseBasicParsing -TimeoutSec 15
        $pageContent = $response.Content
        
        # Pattern 1: "This NPC can be found in [Zone]"
        if ($pageContent -match 'This NPC can be found in\s+<a[^>]*>([^<]+)</a>') {
            $zone = $matches[1].Trim()
            $source = "db.ascension.gg"
        }
        # Pattern 2: Look for zone in listview (creature drops)
        elseif ($pageContent -match '<div class="listview-mode-default">.*?<a[^>]*zone=(\d+)[^>]*>([^<]+)</a>') {
            $zone = $matches[2].Trim()
            $source = "db.ascension.gg (drops)"
        }
        
        if ($zone) {
            Write-Success "Found: $zone"
            $item.Description = "Has a chance to drop from $npcName within $zone"
            $item.Validated = $true
            $foundCount++
        }
    }
    catch {
        Write-Warn "Error: $($_.Exception.Message)"
        $errorCount++
    }
    
    # Strategy 2: Fallback to Wowhead WOTLK if not found
    if (-not $zone) {
        $wowheadUrl = "https://www.wowhead.com/wotlk/npc=$($item.CreatureId)"
        Write-Info "→ Checking Wowhead WOTLK..."
        
        try {
            $response = Invoke-WebRequest -Uri $wowheadUrl -UseBasicParsing -TimeoutSec 15
            $pageContent = $response.Content
            
            # Pattern 1: JavaScript WH.setSelectedLink
            if ($pageContent -match 'WH\.setSelectedLink[^>]*>([^<]+)</a>') {
                $zone = $matches[1].Trim()
                $source = "Wowhead WOTLK"
            }
            # Pattern 2: "This NPC can be found in" direct link
            elseif ($pageContent -match 'This NPC can be found in\s+<a[^>]*>([^<]+)</a>') {
                $zone = $matches[1].Trim()
                $source = "Wowhead WOTLK"
            }
            # Pattern 3: Plain text fallback
            elseif ($pageContent -match 'This NPC can be found in\s+([A-Z][^<\.\(]{2,}?)(?=\s*[\.<]|$)') {
                $zone = $matches[1].Trim()
                $source = "Wowhead WOTLK (text)"
            }
            
            if ($zone) {
                Write-Success "Found: $zone"
                $item.Description = "Has a chance to drop from $npcName within $zone"
                $item.Validated = $true
                $foundCount++
                
                # Add to cache
                $newCacheEntries += [PSCustomObject]@{
                    CreatureId = $item.CreatureId
                    NPCName = $npcName
                    Zone = $zone
                    Source = $source
                }
            }
        }
        catch {
            Write-Warn "Error: $($_.Exception.Message)"
            $errorCount++
        }
    }
    
    if (-not $zone) {
        Write-Fail "NOT FOUND"
        $notFoundCount++
    }
    
    # Rate limiting
    if ($index -lt $needsEnrichment.Count) {
        Start-Sleep -Seconds $RateLimitSeconds
    }
}

Write-Host ""
Write-Step "Enrichment Results"
Write-Host "  Found:     $foundCount / $($needsEnrichment.Count)" -ForegroundColor Green
Write-Host "  Cache Hits: $cacheHits" -ForegroundColor Cyan
Write-Host "  New Lookups: $($foundCount - $cacheHits)" -ForegroundColor Gray
Write-Host "  Not Found: $notFoundCount" -ForegroundColor Yellow
Write-Host "  Errors:    $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Gray" })
Write-Host ""

if ($WhatIf) {
    Write-Warn "WhatIf mode - no changes saved"
    exit 0
}

if ($foundCount -gt 0) {
    Write-Step "Saving updated JSON: $OutputJson"
    $items | ConvertTo-Json -Depth 10 | Set-Content $OutputJson -Encoding UTF8
    Write-Success "Saved $foundCount enrichments"
    Write-Info "Next step: Run GenerateVanityDB_Master.ps1 to regenerate VanityDB.lua"
} else {
    Write-Warn "No enrichments found - JSON not modified"
}

# Update cache with new entries
if ($newCacheEntries.Count -gt 0) {
    Write-Step "Updating enrichment cache"
    
    # Merge with existing cache
    $allCacheEntries = @()
    foreach ($entry in $cache.Values) {
        $allCacheEntries += $entry
    }
    $allCacheEntries += $newCacheEntries
    
    # Ensure cache directory exists
    $cacheDir = Split-Path $CacheFile -Parent
    if (-not (Test-Path $cacheDir)) {
        New-Item -Path $cacheDir -ItemType Directory -Force | Out-Null
    }
    
    # Save cache
    $allCacheEntries | Sort-Object CreatureId | ConvertTo-Json -Depth 10 | Set-Content $CacheFile -Encoding UTF8
    Write-Success "Saved $($newCacheEntries.Count) new cache entries"
    Write-Info "Total cached lookups: $($allCacheEntries.Count)"
}

Write-Host ""
Write-Host "Complete!" -ForegroundColor Green
Write-Host ""
