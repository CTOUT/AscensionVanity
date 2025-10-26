# AscensionVanity Database Extraction Script
# This PowerShell script fetches vanity items from Project Ascension database
# and generates the VanityData.lua file with intelligent validation

param(
    [switch]$Force  # Bypass cache and fetch fresh data
)

# Configuration
$vanityCategories = @{
    "Beastmaster's Whistle" = "101.1"
    "Blood Soaked Vellum" = "101.2"
    "Summoner's Stones" = "101.3"
    "Draconic Warhorns" = "101.4"
    "Elemental Lodestones" = "101.5"
}
$baseUrl = "https://db.ascension.gg"
$outputFile = "AscensionVanity\VanityDB.lua"

# Cache configuration
$cacheDir = Join-Path $PSScriptRoot ".cache"
$categoryCacheDir = Join-Path $cacheDir "categories"
$itemCacheDir = Join-Path $cacheDir "items"
$cacheExpirationHours = 24

# Initialize
Write-Host "AscensionVanity Database Extraction Tool v2.0" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Intelligent Validation Enabled" -ForegroundColor Green
if ($Force) {
    Write-Host "Cache Bypass: ENABLED (will fetch fresh data)" -ForegroundColor Yellow
} else {
    Write-Host "Cache: ENABLED (using cached data when available)" -ForegroundColor Green
}
Write-Host ""

# Create cache directories if they don't exist
if (-not (Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    New-Item -ItemType Directory -Path $categoryCacheDir -Force | Out-Null
    New-Item -ItemType Directory -Path $itemCacheDir -Force | Out-Null
    Write-Host "Created cache directories" -ForegroundColor Green
    Write-Host ""
}

# Data structures
$specificCreatures = @{}
$genericDrops = @{}
$validationErrors = @()
$skippedItems = @()  # Track all skipped items with reasons
$stats = @{
    TotalItems = 0
    SpecificCreatures = 0
    GenericDrops = 0
    ValidatedDrops = 0
    SkippedInvalid = 0
    WebRequestsMade = 0
    CacheHits = 0
}

# Caching functions
function Get-CachedContent {
    param(
        [string]$url,
        [string]$cacheKey,
        [string]$cacheSubDir
    )
    
    # If Force flag set, always return null (triggers fresh fetch)
    if ($Force) {
        return $null
    }
    
    $cacheFile = Join-Path $cacheSubDir "$cacheKey.html"
    
    if (Test-Path $cacheFile) {
        $fileAge = (Get-Date) - (Get-Item $cacheFile).LastWriteTime
        if ($fileAge.TotalHours -lt $cacheExpirationHours) {
            Write-Verbose "Using cached content (age: $([Math]::Round($fileAge.TotalHours, 1)) hours)"
            return Get-Content $cacheFile -Raw
        } else {
            Write-Verbose "Cache expired (age: $([Math]::Round($fileAge.TotalHours, 1)) hours), fetching fresh..."
        }
    }
    
    return $null
}

function Set-CachedContent {
    param(
        [string]$content,
        [string]$cacheKey,
        [string]$cacheSubDir
    )
    
    $cacheFile = Join-Path $cacheSubDir "$cacheKey.html"
    Set-Content -Path $cacheFile -Value $content -Force
    Write-Verbose "Cached content for future use"
}


# Function to extract creature name from vanity item name
function Get-CreatureNameFromItem {
    param([string]$itemName)
    
    # Extract creature name after the colon
    # "Beastmaster's Whistle: Savannah Patriarch" -> "Savannah Patriarch"
    if ($itemName -match ":\s*(.+)$") {
        return $matches[1].Trim()
    }
    return $null
}

# Function to validate NPC drop source matches item name
function Test-NPCMatchesItem {
    param(
        [string]$npcName,
        [string]$expectedName
    )
    
    # Exact match (case-insensitive)
    if ($npcName -eq $expectedName) {
        return $true
    }
    
    # Fuzzy match - allow minor variations
    # "Savannah Prowler" matches "Savannah Prowler"
    # But "Felstalker" does NOT match "Savannah Prowler"
    
    $similarity = 0
    $npcWords = $npcName -split '\s+'
    $expectedWords = $expectedName -split '\s+'
    
    foreach ($word in $expectedWords) {
        if ($npcWords -contains $word) {
            $similarity++
        }
    }
    
    # Require at least 50% word match
    $threshold = [math]::Ceiling($expectedWords.Count / 2)
    return ($similarity -ge $threshold)
}

# Function to fetch and parse item page
function Get-ItemDropSources {
    param(
        [string]$itemUrl,
        [string]$expectedCreatureName
    )
    
    # Extract item ID from URL for cache key
    $itemId = ($itemUrl -split '=')[-1]
    $cacheKey = "item_$itemId"
    
    # Try cache first
    $htmlContent = Get-CachedContent -url $itemUrl -cacheKey $cacheKey -cacheSubDir $itemCacheDir
    
    if (-not $htmlContent) {
        # Fetch from web
        Write-Verbose "Fetching item page: $itemUrl"
        
        try {
            Start-Sleep -Milliseconds 300  # Rate limiting
            $response = Invoke-WebRequest -Uri $itemUrl -UseBasicParsing -ErrorAction Stop
            $htmlContent = $response.Content
            
            # Cache it
            Set-CachedContent -content $htmlContent -cacheKey $cacheKey -cacheSubDir $itemCacheDir
            $script:stats.WebRequestsMade++
        } catch {
            Write-Warning "Failed to fetch item page: $_"
            return @()
        }
    } else {
        $script:stats.CacheHits++
    }
    
    # Parse the HTML for drop sources (using Listview JSON structure)
    try {
        $html = $htmlContent
        
        # Find the "dropped-by" Listview section
        # Pattern can be either: "id":"dropped-by" or id:"dropped-by" or id:'dropped-by'
        $droppedByPattern = '"id"\s*:\s*"dropped-by"|id\s*:\s*[''"]dropped-by[''"]'
        if ($html -match $droppedByPattern) {
            $droppedBySection = $matches[0].Index
        } else {
            Write-Verbose "No dropped-by section found for: $expectedCreatureName"
            return @()
        }
        
        # Find the Listview initialization at or before the dropped-by marker
        # Search backwards from the match to find "new Listview({"
        $searchStart = [Math]::Max(0, $html.IndexOf($matches[0]) - 50)
        $listviewMarker = "new Listview({"
        $listviewStart = $html.IndexOf($listviewMarker, $searchStart)
        
        if ($listviewStart -eq -1) {
            Write-Verbose "No Listview found in dropped-by section for: $expectedCreatureName"
            return @()
        }
        
        # Find the data array within the Listview
        $dataMarker = '"data":'
        $dataStart = $html.IndexOf($dataMarker, $listviewStart)
        
        if ($dataStart -eq -1) {
            Write-Verbose "No data array found in Listview for: $expectedCreatureName"
            return @()
        }
        
        # Find the opening bracket of the data array
        $dataArrayStart = $html.IndexOf('[', $dataStart)
        
        if ($dataArrayStart -eq -1) {
            Write-Verbose "No data array opening bracket found for: $expectedCreatureName"
            return @()
        }
        
        # Find the matching closing bracket using bracket counting
        $bracketCount = 0
        $inArray = $false
        $dataArrayEnd = -1
        
        for ($i = $dataArrayStart; $i -lt $html.Length; $i++) {
            $char = $html[$i]
            
            if ($char -eq '[') {
                $bracketCount++
                $inArray = $true
            }
            elseif ($char -eq ']') {
                $bracketCount--
                if ($bracketCount -eq 0 -and $inArray) {
                    $dataArrayEnd = $i + 1
                    break
                }
            }
        }
        
        if ($dataArrayEnd -eq -1) {
            Write-Verbose "Could not find end of data array for: $expectedCreatureName"
            return @()
        }
        
        # Extract the JSON array string
        $jsonArrayLength = $dataArrayEnd - $dataArrayStart
        $jsonArray = $html.Substring($dataArrayStart, $jsonArrayLength)
        
        # Parse the JSON array
        try {
            $npcData = $jsonArray | ConvertFrom-Json
        } catch {
            Write-Verbose "Failed to parse JSON for: $expectedCreatureName - $_"
            return @()
        }
        
        # Process each NPC in the data array
        $validNPCs = @()
        
        foreach ($npc in $npcData) {
            $npcId = $npc.id
            $npcName = $npc.name
            
            if (-not $npcId -or -not $npcName) {
                continue
            }
            
            # Validate NPC name matches expected creature name
            if (Test-NPCMatchesItem -npcName $npcName -expectedName $expectedCreatureName) {
                $validNPCs += @{
                    ID = $npcId
                    Name = $npcName
                    URL = "$baseUrl/?npc=$npcId"
                }
                Write-Host "  ✓ Valid: $npcName (ID: $npcId)" -ForegroundColor Green
            } else {
                Write-Host "  ✗ Skipped: $npcName (doesn't match '$expectedCreatureName')" -ForegroundColor Yellow
                $script:stats.SkippedInvalid++
            }
        }
        
        return $validNPCs
        
    } catch {
        Write-Warning "Failed to parse item page: $_"
        return @()
    }
}

# Function to parse vanity items from category page
function Get-VanityItemsFromPage {
    param(
        [string]$categoryUrl,
        [string]$categoryName
    )
    
    Write-Host "Fetching category: $categoryName" -ForegroundColor Cyan
    
    # Generate cache key from category name
    $cacheKey = $categoryName.ToLower() -replace '[^a-z0-9]', '_'
    
    # Try to get from cache first
    $htmlContent = Get-CachedContent -url $categoryUrl -cacheKey $cacheKey -cacheSubDir $categoryCacheDir
    
    if (-not $htmlContent) {
        # Not in cache or expired, fetch from web
        Write-Host "  Fetching from web..." -ForegroundColor Gray
        
        try {
            $response = Invoke-WebRequest -Uri $categoryUrl -UseBasicParsing -ErrorAction Stop
            $htmlContent = $response.Content
            
            # Cache it for next time
            Set-CachedContent -content $htmlContent -cacheKey $cacheKey -cacheSubDir $categoryCacheDir
            $script:stats.WebRequestsMade++
        } catch {
            Write-Warning "Failed to fetch category page: $_"
            return @()
        }
    } else {
        Write-Host "  Using cached data" -ForegroundColor Cyan
        $script:stats.CacheHits++
    }
    
    # Parse the HTML for category items
    try {
        $html = $htmlContent
        
        # Extract data from Listview JavaScript initialization
        # Pattern: new Listview({...data:[{item1},{item2}...]...})
        Write-Host "  Extracting Listview data..." -ForegroundColor Gray
        
        # Find the Listview data array by manually parsing the JavaScript structure
        $listviewStart = $html.IndexOf('new Listview')
        if ($listviewStart -lt 0) {
            Write-Warning "Could not find Listview initialization in page"
            return @()
        }
        
        # Find the "data": array within the Listview object
        $dataMarker = '"data":'
        $dataStart = $html.IndexOf($dataMarker, $listviewStart)
        if ($dataStart -lt 0) {
            Write-Warning "Could not find data array in Listview"
            return @()
        }
        
        # Move to the start of the array (after "data":[)
        $arrayStart = $html.IndexOf('[', $dataStart)
        if ($arrayStart -lt 0) {
            Write-Warning "Could not find start of data array"
            return @()
        }
        
        # Find the matching closing bracket by counting brackets
        $bracketCount = 0
        $inString = $false
        $escape = $false
        $arrayEnd = -1
        
        for ($i = $arrayStart; $i -lt $html.Length; $i++) {
            $char = $html[$i]
            
            if ($escape) {
                $escape = $false
                continue
            }
            
            if ($char -eq '\') {
                $escape = $true
                continue
            }
            
            if ($char -eq '"') {
                $inString = -not $inString
                continue
            }
            
            if (-not $inString) {
                if ($char -eq '[') {
                    $bracketCount++
                }
                elseif ($char -eq ']') {
                    $bracketCount--
                    if ($bracketCount -eq 0) {
                        $arrayEnd = $i
                        break
                    }
                }
            }
        }
        
        if ($arrayEnd -lt 0) {
            Write-Warning "Could not find end of data array"
            return @()
        }
        
        # Extract the array JSON
        $dataArrayText = $html.Substring($arrayStart, $arrayEnd - $arrayStart + 1)
        
        # Parse the JSON array
        try {
            $itemsData = $dataArrayText | ConvertFrom-Json
            Write-Host "  Found $($itemsData.Count) item definitions" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to parse Listview data array: $_"
            return @()
        }
        
        $items = @()
        
        foreach ($itemData in $itemsData) {
            try {
                $itemId = $itemData.id
                
                # Extract source info from database
                # Two field types:
                # 1. sourcemore: [{"n":"NPC Name","t":1,"ti":npcID}] - specific NPCs with detailed info
                # 2. source: [2,4] - generic source type codes (2=Drop, 4=Quest, etc.)
                $sourceType = $null
                $sourceId = $null
                $sourceName = $null
                
                # Try sourcemore field first (detailed NPC info)
                if ($itemData.sourcemore -and $itemData.sourcemore.Length -gt 0) {
                    # Specific creature drop with detailed information
                    $sourceType = $itemData.sourcemore[0].t
                    $sourceId = $itemData.sourcemore[0].ti
                    $sourceName = $itemData.sourcemore[0].n
                    Write-Verbose "Item $itemId - sourcemore field: Type=$sourceType, ID=$sourceId, Name=$sourceName"
                }
                # Fallback to source field (generic source codes)
                elseif ($itemData.source -and $itemData.source.Length -gt 0) {
                    # Generic source codes - items without specific NPC data
                    # Common codes: 1=Crafted, 2=Drop, 3=PvP, 4=Quest, 5=Vendor
                    $sourceCodes = $itemData.source -join ','
                    Write-Verbose "Item $itemId - source field: codes=[$sourceCodes]"
                    
                    # Check if this is a drop (code 2) - these might have fetchable NPC data
                    if ($itemData.source -contains 2) {
                        # Mark as generic drop, will attempt to fetch NPC data from item page
                        $sourceType = 2  # Drop type
                        $sourceId = $null
                        $sourceName = "Generic Drop"
                        Write-Verbose "Item $itemId - marked as generic drop, will fetch NPC data"
                    } else {
                        # Other source types (Crafted, PvP, Quest, Vendor) - skip these
                        Write-Verbose "Item $itemId - source codes [$sourceCodes] don't include drops, skipping"
                        continue
                    }
                } else {
                    # No source information at all
                    Write-Verbose "Item $itemId - no source field found, skipping"
                    continue
                }
                
                # Extract item name (use name_enus which contains the English name)
                $itemName = $itemData.name_enus
                
                # If name_enus not available, try the name field and remove leading "1"
                if (-not $itemName -and $itemData.name) {
                    $itemName = $itemData.name
                    if ($itemName -match "^1(.+)$") {
                        $itemName = $matches[1]
                    }
                }
                
                $items += @{
                    ID = $itemId
                    Name = $itemName
                    URL = "$baseUrl/?item=$itemId"
                    SourceType = $sourceType
                    SourceID = $sourceId
                    SourceName = $sourceName
                    Icon = $itemData.icon
                    Class = $itemData.classs
                    Subclass = $itemData.subclass
                }
                
            } catch {
                Write-Verbose "Failed to parse item $itemId : $_"
            }
        }
        
        Write-Host "  Successfully parsed $($items.Count) items" -ForegroundColor Cyan
        return $items
        
    } catch {
        Write-Warning "Failed to parse category page: $_"
        return @()
    }
}

# Function to process a single vanity item
function Process-VanityItem {
    param(
        [hashtable]$item,
        [string]$categoryName
    )
    
    $script:stats.TotalItems++
    Write-Host "`nProcessing: $($item.Name)" -ForegroundColor White
    
    # Extract expected creature name from item name
    $expectedCreature = Get-CreatureNameFromItem -itemName $item.Name
    if (-not $expectedCreature) {
        Write-Warning "  Could not extract creature name from: $($item.Name)"
        $script:stats.SkippedInvalid++
        $script:skippedItems += @{
            ItemID = $item.ID
            ItemName = $item.Name
            Category = $categoryName
            Reason = "Could not extract creature name from item name"
        }
        return
    }
    
    Write-Host "  Expected creature: $expectedCreature" -ForegroundColor Gray
    
    # Check sourcemore data from the category page
    if ($item.SourceType -eq 1 -and $item.SourceName) {
        # Specific creature drop - sourcemore format: [1, npcId, npcName]
        Write-Host "  Source Type: Specific NPC ($($item.SourceName))" -ForegroundColor Gray
        
        # Validate that NPC name matches expected creature
        if (Test-NPCMatchesItem -npcName $item.SourceName -expectedName $expectedCreature) {
            # Add to specific creatures table
            $creatureName = $item.SourceName
            
            if (-not $script:specificCreatures.ContainsKey($creatureName)) {
                $script:specificCreatures[$creatureName] = @{
                    ItemID = $item.ID
                    ItemName = $item.Name
                    NPCID = $item.SourceID
                }
                $script:stats.SpecificCreatures++
                $script:stats.ValidatedDrops++
                Write-Host "  → Added as specific creature drop" -ForegroundColor Green
            }
        } else {
            # Validation failed - NPC name doesn't match item name
            $script:validationErrors += "Item '$($item.Name)' lists NPC '$($item.SourceName)' which doesn't match expected '$expectedCreature'"
            $script:stats.SkippedInvalid++
            $script:skippedItems += @{
                ItemID = $item.ID
                ItemName = $item.Name
                Category = $categoryName
                Reason = "Validation failed: NPC '$($item.SourceName)' doesn't match expected '$expectedCreature'"
            }
            Write-Warning "  ✗ Validation failed: NPC '$($item.SourceName)' doesn't match '$expectedCreature'"
        }
        
    } else {
        # Any other source type (Drop, Quest, generic, etc.) - fetch item page to get actual drop sources
        Write-Host "  Source Type: $($item.SourceType) - fetching drop sources..." -ForegroundColor Gray
        
        $dropSources = Get-ItemDropSources -itemUrl $item.URL -expectedCreatureName $expectedCreature
        
        if ($dropSources.Count -eq 0) {
            Write-Warning "  No valid drop sources found - skipping"
            $script:stats.SkippedInvalid++
            $script:skippedItems += @{
                ItemID = $item.ID
                ItemName = $item.Name
                Category = $categoryName
                Reason = "No valid drop sources found on item page"
            }
            return
        }
        
        if ($dropSources.Count -eq 1) {
            # Single specific creature
            $npc = $dropSources[0]
            $creatureName = $npc.Name
            
            if (-not $script:specificCreatures.ContainsKey($creatureName)) {
                $script:specificCreatures[$creatureName] = @{
                    ItemID = $item.ID
                    ItemName = $item.Name
                    NPCID = $npc.ID
                }
                $script:stats.SpecificCreatures++
                $script:stats.ValidatedDrops++
                Write-Host "  → Added as specific creature drop" -ForegroundColor Green
            }
        } else {
            # Multiple NPCs - treat as generic drop
            
            if (-not $script:genericDrops.ContainsKey("All")) {
                $script:genericDrops["All"] = @()
            }
            
            if ($script:genericDrops["All"] -notcontains $item.ID) {
                $script:genericDrops["All"] += $item.ID
                $script:stats.GenericDrops++
                $script:stats.ValidatedDrops++
                Write-Host "  → Added as generic drop" -ForegroundColor Green
            }
        }
    }
}


# Function to generate Lua code
function Generate-LuaCode {
    param(
        [hashtable]$creatures,
        [hashtable]$drops
    )
    
    $lua = @"
-- AscensionVanity - Vanity Items Database
-- Auto-generated from Project Ascension database
-- Total items: $($creatures.Count + $drops.Count)

AV_VanityItems = {
"@

    # Add specific creature entries (indexed by NPC ID for localization independence)
    # Only store IDs - let game API provide localized names at runtime
    foreach ($name in $creatures.Keys | Sort-Object) {
        $item = $creatures[$name]
        $npcID = $item.NPCID
        # Include item name as comment for human readability and category analysis
        $lua += "    [$npcID] = $($item.ItemID), -- $($item.ItemName)`n"
    }
    
    $lua += "}`n`n"
    
    # Add generic drops (simple flat array)
    $lua += "AV_GenericDrops = {`n"
    
    # Flatten all generic drops from the hash table
    $allGenericDrops = @()
    foreach ($type in $drops.Keys) {
        $allGenericDrops += $drops[$type]
    }
    
    # Sort and output unique item IDs
    $allGenericDrops | Select-Object -Unique | Sort-Object | ForEach-Object {
        $lua += "    $_,`n"
    }
    
    $lua += "}`n"
    
    return $lua
}


# Main extraction process
Write-Host "Starting intelligent database extraction..." -ForegroundColor Green
Write-Host "Categories to process: $($vanityCategories.Count)" -ForegroundColor Gray
Write-Host ""

try {
    $categoryIndex = 0
    foreach ($category in $vanityCategories.GetEnumerator()) {
        $categoryIndex++
        $categoryName = $category.Key
        $categoryId = $category.Value
        $categoryUrl = "$baseUrl/?items=$categoryId"
        
        Write-Host "[$categoryIndex/$($vanityCategories.Count)] Processing: $categoryName" -ForegroundColor Cyan
        Write-Host "URL: $categoryUrl" -ForegroundColor Gray
        Write-Host ""
        
        # Fetch items from this category
        $items = Get-VanityItemsFromPage -categoryUrl $categoryUrl -categoryName $categoryName
        
        if ($items.Count -eq 0) {
            Write-Warning "No items found in category: $categoryName"
            continue
        }
        
        # Process each item with validation
        $itemIndex = 0
        foreach ($item in $items) {
            $itemIndex++
            $percent = [math]::Round(($itemIndex / $items.Count) * 100)
            Write-Progress -Activity "Processing $categoryName" -Status "$itemIndex of $($items.Count)" -PercentComplete $percent
            
            Process-VanityItem -item $item -categoryName $categoryName
            
            # No sleep needed - caching handles rate limiting efficiently
        }
        
        Write-Progress -Activity "Processing $categoryName" -Completed
        Write-Host ""
        Write-Host "Category complete: $categoryName" -ForegroundColor Green
        Write-Host "─────────────────────────────────────────" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "EXTRACTION COMPLETE!" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Display statistics
    Write-Host "STATISTICS:" -ForegroundColor Cyan
    Write-Host "───────────" -ForegroundColor Gray
    Write-Host "Total items processed:    $($stats.TotalItems)" -ForegroundColor White
    Write-Host "Specific creature drops:  $($stats.SpecificCreatures)" -ForegroundColor Green
    Write-Host "Generic drops:            $($stats.GenericDrops)" -ForegroundColor Green
    Write-Host "Validated drops:          $($stats.ValidatedDrops)" -ForegroundColor Green
    Write-Host "Skipped (invalid):        $($stats.SkippedInvalid)" -ForegroundColor Yellow
    Write-Host ""
    
    # Cache statistics
    Write-Host "CACHE PERFORMANCE:" -ForegroundColor Cyan
    Write-Host "──────────────────" -ForegroundColor Gray
    Write-Host "Web requests made:        $($stats.WebRequestsMade)" -ForegroundColor White
    Write-Host "Cache hits:               $($stats.CacheHits)" -ForegroundColor Green
    $totalAccesses = $stats.WebRequestsMade + $stats.CacheHits
    if ($totalAccesses -gt 0) {
        $cacheHitRate = [Math]::Round(($stats.CacheHits / $totalAccesses) * 100, 1)
        $hitRateColor = if ($cacheHitRate -gt 80) { "Green" } elseif ($cacheHitRate -gt 50) { "Yellow" } else { "White" }
        Write-Host "Cache hit rate:           $cacheHitRate%" -ForegroundColor $hitRateColor
    }
    Write-Host ""
    
    
    # Generate Lua file
    Write-Host "GENERATING LUA CODE..." -ForegroundColor Cyan
    Write-Host ""
    $luaCode = Generate-LuaCode -creatures $specificCreatures -drops $genericDrops
    
    # Write to file
    $luaCode | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Host "✓ Lua file generated: $outputFile" -ForegroundColor Green
    Write-Host ""
    
    # Validation report
    if ($validationErrors.Count -gt 0) {
        Write-Host "VALIDATION WARNINGS:" -ForegroundColor Yellow
        Write-Host "───────────────────" -ForegroundColor Gray
        foreach ($error in $validationErrors) {
            Write-Host "  • $error" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
} catch {
    Write-Host ""
    Write-Host "FATAL ERROR!" -ForegroundColor Red
    Write-Host "─────────────" -ForegroundColor Gray
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack trace:" -ForegroundColor Gray
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    exit 1
}

Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "EXTRACTION COMPLETE!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Export skipped items report
if ($skippedItems.Count -gt 0) {
    $skippedReportFile = Join-Path $PSScriptRoot "SkippedItems_Detailed.txt"
    $report = @"
═══════════════════════════════════════════
  SKIPPED ITEMS - DETAILED REPORT
═══════════════════════════════════════════

Total Skipped: $($skippedItems.Count) items
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

"@
    
    # Group by reason
    $skippedByReason = $skippedItems | Group-Object -Property Reason
    
    foreach ($group in $skippedByReason | Sort-Object Count -Descending) {
        $report += "`nReason: $($group.Name)`n"
        $report += "Count: $($group.Count) items`n"
        $report += "─────────────────────────────────────────────`n"
        foreach ($item in $group.Group | Sort-Object ItemName) {
            $report += "  [$($item.ItemID)] $($item.ItemName) [$($item.Category)]`n"
        }
        $report += "`n"
    }
    
    $report | Out-File -FilePath $skippedReportFile -Encoding UTF8
    Write-Host "Skipped items report saved to: SkippedItems_Detailed.txt" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "───────────" -ForegroundColor Gray
Write-Host "1. Review the generated file: $outputFile" -ForegroundColor White
Write-Host "2. Copy the AscensionVanity folder to your WoW Addons directory" -ForegroundColor White
Write-Host "3. Test in-game: /reload" -ForegroundColor White
Write-Host "4. Verify tooltips: Mouse over creatures" -ForegroundColor White
Write-Host ""

# Quick command reference
Write-Host "QUICK COMMANDS:" -ForegroundColor Cyan
Write-Host "──────────────" -ForegroundColor Gray
Write-Host 'Copy to Addons:  Copy-Item -Recurse "AscensionVanity" "<WoW>\Interface\Addons\" -Force' -ForegroundColor DarkGray
Write-Host ""



# Usage instructions and documentation
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "INTELLIGENT EXTRACTION FEATURES" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script uses intelligent validation to ensure data quality:" -ForegroundColor White
Write-Host ""
Write-Host "✓ Category-based extraction" -ForegroundColor Green
Write-Host "  - Processes each vanity category separately (101.1 - 101.5)" -ForegroundColor Gray
Write-Host ""
Write-Host "✓ Name-based validation" -ForegroundColor Green
Write-Host "  - Extracts expected creature name from item name" -ForegroundColor Gray
Write-Host "  - Validates NPC names match expected creature" -ForegroundColor Gray
Write-Host "  - Skips invalid matches (e.g., Felstalker for Savannah Prowler)" -ForegroundColor Gray
Write-Host ""
Write-Host "✓ Smart categorization" -ForegroundColor Green
Write-Host "  - Single NPC → Specific creature drop" -ForegroundColor Gray
Write-Host "  - Multiple NPCs → Generic drop (by creature type)" -ForegroundColor Gray
Write-Host ""
Write-Host "✓ Error handling" -ForegroundColor Green
Write-Host "  - Graceful failure recovery" -ForegroundColor Gray
Write-Host "  - Detailed validation reporting" -ForegroundColor Gray
Write-Host "  - Statistics and warnings" -ForegroundColor Gray
Write-Host ""

Write-Host "VALIDATION EXAMPLE:" -ForegroundColor Yellow
Write-Host "──────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host 'Item: "Beastmaster''s Whistle: Savannah Prowler"' -ForegroundColor White
Write-Host "Expected creature: Savannah Prowler" -ForegroundColor Gray
Write-Host ""
Write-Host "Dropped by tab shows:" -ForegroundColor Gray
Write-Host "  • Savannah Prowler (ID: 3425)  → ✓ VALID (name matches)" -ForegroundColor Green
Write-Host "  • Felstalker (ID: 5278)        → ✗ SKIPPED (doesn't match)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Result: Only Savannah Prowler is added to database" -ForegroundColor Green
Write-Host ""

Write-Host "MANUAL EXTRACTION ALTERNATIVE:" -ForegroundColor Cyan
Write-Host "──────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "If automated extraction fails, use manual process:" -ForegroundColor Yellow
Write-Host ""
Write-Host "For each category (101.1 through 101.5):" -ForegroundColor White
Write-Host "  1. Visit category URL (e.g., https://db.ascension.gg/?items=101.1)" -ForegroundColor Gray
Write-Host '  2. For items with specific creature source:' -ForegroundColor Gray
Write-Host '     - Copy creature name from source column' -ForegroundColor DarkGray
Write-Host '     - Add to AV_VanityItems table' -ForegroundColor DarkGray
Write-Host '  3. For items with "Drop" source:' -ForegroundColor Gray
Write-Host '     - Click item link' -ForegroundColor DarkGray
Write-Host '     - Go to "Dropped by" tab' -ForegroundColor DarkGray
Write-Host '     - Verify NPC name matches item name' -ForegroundColor DarkGray
Write-Host '     - Skip mismatches (different names)' -ForegroundColor DarkGray
Write-Host '     - Add valid NPCs to database' -ForegroundColor DarkGray
Write-Host ""

Write-Host "FORMAT EXAMPLE:" -ForegroundColor Cyan
Write-Host "──────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "Specific creature drop:" -ForegroundColor Yellow
Write-Host '["Savannah Patriarch"] = {' -ForegroundColor DarkGray
Write-Host '    itemID = 79625,' -ForegroundColor DarkGray
Write-Host '    itemName = "Beastmaster''s Whistle: Savannah Patriarch",' -ForegroundColor DarkGray
Write-Host '    type = "Beast",' -ForegroundColor DarkGray
Write-Host '    npcID = 3241' -ForegroundColor DarkGray
Write-Host '},' -ForegroundColor DarkGray
Write-Host ""

Write-Host "Generic drop by type:" -ForegroundColor Yellow
Write-Host 'AV_GenericDropsByType["Beast"] = {' -ForegroundColor DarkGray
Write-Host '    "Beastmaster''s Whistle: Savannah Prowler",' -ForegroundColor DarkGray
Write-Host '    "Beastmaster''s Whistle: Young Panther",' -ForegroundColor DarkGray
Write-Host '    ...' -ForegroundColor DarkGray
Write-Host '}' -ForegroundColor DarkGray
Write-Host ""

Write-Host "TROUBLESHOOTING:" -ForegroundColor Cyan
Write-Host "────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "If extraction fails:" -ForegroundColor Yellow
Write-Host "  1. Check internet connection" -ForegroundColor White
Write-Host "  2. Verify database URLs are accessible" -ForegroundColor White
Write-Host "  3. Run with -Verbose flag for detailed logging" -ForegroundColor White
Write-Host "  4. Check HTML structure hasn't changed" -ForegroundColor White
Write-Host "  5. Review error messages in console" -ForegroundColor White
Write-Host ""

Write-Host "Run script with verbose output:" -ForegroundColor Gray
Write-Host '  .\ExtractDatabase.ps1 -Verbose' -ForegroundColor DarkGray
Write-Host ""
