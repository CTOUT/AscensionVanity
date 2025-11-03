# DiagnoseMissingItems.ps1
# Diagnostic script to identify missing vanity items

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$baseUrl = "https://db.ascension.gg"

# Category definitions with Drop filter applied
$vanityCategories = @{
    "Beastmaster's Whistles" = "101.1&filter=cr=128;crs=4;crv=0"
    "Blood Soaked Vellums" = "101.2&filter=cr=128;crs=4;crv=0"
    "Summoner's Stones" = "101.3&filter=cr=128;crs=4;crv=0"
    "Draconic Warhorns" = "101.4&filter=cr=128;crs=4;crv=0"
    "Elemental Lodestones" = "101.5&filter=cr=128;crs=4;crv=0"
}

# Cache directory
$cacheDir = Join-Path $PSScriptRoot ".cache"
$categoryCacheDir = Join-Path $cacheDir "categories_filtered"

if (-not (Test-Path $categoryCacheDir)) {
    New-Item -ItemType Directory -Path $categoryCacheDir -Force | Out-Null
}

Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DIAGNOSING MISSING VANITY ITEMS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Function to get cached content or fetch from web
function Get-CachedContent {
    param(
        [string]$url,
        [string]$cacheKey,
        [string]$cacheSubDir
    )
    
    $cachePath = Join-Path $cacheSubDir "$cacheKey.html"
    
    if (Test-Path $cachePath) {
        return Get-Content $cachePath -Raw
    }
    
    return $null
}

# Function to parse Listview data from category page
function Get-ItemsFromCategoryPage {
    param(
        [string]$htmlContent
    )
    
    try {
        $html = $htmlContent
        
        # Find the Listview data array
        $listviewStart = $html.IndexOf('new Listview')
        if ($listviewStart -lt 0) {
            Write-Warning "Could not find Listview initialization"
            return @()
        }
        
        $dataMarker = '"data":'
        $dataStart = $html.IndexOf($dataMarker, $listviewStart)
        if ($dataStart -lt 0) {
            Write-Warning "Could not find data array"
            return @()
        }
        
        $arrayStart = $html.IndexOf('[', $dataStart)
        if ($arrayStart -lt 0) {
            Write-Warning "Could not find start of array"
            return @()
        }
        
        # Find matching closing bracket
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
        
        $dataArrayText = $html.Substring($arrayStart, $arrayEnd - $arrayStart + 1)
        
        try {
            $itemsData = $dataArrayText | ConvertFrom-Json
        }
        catch {
            Write-Warning "Failed to parse JSON: $_"
            return @()
        }
        
        $items = @()
        
        foreach ($itemData in $itemsData) {
            $itemId = $itemData.id
            $itemName = $itemData.name_enus
            
            if (-not $itemName -and $itemData.name) {
                $itemName = $itemData.name
                if ($itemName -match "^1(.+)$") {
                    $itemName = $matches[1]
                }
            }
            
            # Check if item has drop source (code 2)
            $hasDrop = $false
            if ($itemData.sourcemore -and $itemData.sourcemore.Length -gt 0) {
                $hasDrop = $true
            }
            elseif ($itemData.source -and $itemData.source -contains 2) {
                $hasDrop = $true
            }
            
            if ($hasDrop) {
                $items += @{
                    ID = $itemId
                    Name = $itemName
                }
            }
        }
        
        return $items
        
    } catch {
        Write-Warning "Failed to parse category page: $_"
        return @()
    }
}

# Load our extracted database
Write-Host "Loading extracted database..." -ForegroundColor Gray
$luaFile = Join-Path $PSScriptRoot "AscensionVanity\VanityDB.lua"

if (-not (Test-Path $luaFile)) {
    Write-Host "ERROR: VanityDB.lua not found!" -ForegroundColor Red
    exit 1
}

$luaContent = Get-Content $luaFile -Raw

# Parse AV_VanityItems (specific creature drops)
$extractedItemIDs = @{}
if ($luaContent -match 'AV_VanityItems\s*=\s*\{([^}]+)\}') {
    $vanityItemsContent = $matches[1]
    $vanityItemsContent -split '\n' | ForEach-Object {
        if ($_ -match '\[(\d+)\]\s*=\s*(\d+)') {
            $itemId = [Int64]$matches[2]  # Use Int64 to match category page parsing
            $extractedItemIDs[$itemId] = "AV_VanityItems"
        }
    }
}

# Parse AV_GenericDrops
if ($luaContent -match 'AV_GenericDrops\s*=\s*\{([^}]+)\}') {
    $genericDropsContent = $matches[1]
    # Split by comma and extract all numbers
    $numbers = [regex]::Matches($genericDropsContent, '\d+')
    foreach ($match in $numbers) {
        $itemId = [Int64]$match.Value  # Use Int64 to match category page parsing
        if (-not $extractedItemIDs.ContainsKey($itemId)) {
            $extractedItemIDs[$itemId] = "AV_GenericDrops"
        }
    }
}

Write-Host "  Loaded $($extractedItemIDs.Count) items from extracted database" -ForegroundColor Green

# Debug: Check some known items
$testItemIds = @(80533, 1180525, 82367)
Write-Host "  Debug - Testing known item IDs:" -ForegroundColor Gray
foreach ($testId in $testItemIds) {
    $exists = $extractedItemIDs.ContainsKey($testId)
    Write-Host "    Item $testId : $exists" -ForegroundColor $(if ($exists) { "Green" } else { "Red" })
}

Write-Host ""

# Fetch all items from database URLs and compare
$allDatabaseItems = @{}
$missingItems = @()

foreach ($category in $vanityCategories.GetEnumerator()) {
    $categoryName = $category.Key
    $categoryId = $category.Value
    $categoryUrl = "$baseUrl/?items=$categoryId"
    
    Write-Host "Processing: $categoryName" -ForegroundColor Cyan
    Write-Host "  URL: $categoryUrl" -ForegroundColor Gray
    
    # Try cache first
    $cacheKey = "category_filtered_" + ($categoryId -replace '[^a-zA-Z0-9]', '_')
    $htmlContent = Get-CachedContent -url $categoryUrl -cacheKey $cacheKey -cacheSubDir $categoryCacheDir
    
    if (-not $htmlContent) {
        Write-Host "  Fetching from web..." -ForegroundColor Yellow
        
        try {
            Start-Sleep -Milliseconds 500
            $response = Invoke-WebRequest -Uri $categoryUrl -UseBasicParsing -ErrorAction Stop
            $htmlContent = $response.Content
            
            # Cache it
            $cachePath = Join-Path $categoryCacheDir "$cacheKey.html"
            $htmlContent | Out-File -FilePath $cachePath -Encoding UTF8
            
        } catch {
            Write-Host "  ERROR: Failed to fetch - $_" -ForegroundColor Red
            continue
        }
    } else {
        Write-Host "  Using cached data" -ForegroundColor Gray
    }
    
    # Parse items from page
    $categoryItems = Get-ItemsFromCategoryPage -htmlContent $htmlContent
    Write-Host "  Found $($categoryItems.Count) items with Drop source" -ForegroundColor Green
    
    # Check which items are missing from our extraction
    $debugCount = 0
    foreach ($item in $categoryItems) {
        $itemId = $item.ID
        $itemName = $item.Name
        
        $allDatabaseItems[$itemId] = @{
            Name = $itemName
            Category = $categoryName
        }
        
        # Debug first few items
        if ($debugCount -lt 3) {
            $exists = $extractedItemIDs.ContainsKey($itemId)
            Write-Host "    DEBUG: Item $itemId ($itemName) - In extracted? $exists (Type: $($itemId.GetType().Name))" -ForegroundColor DarkGray
            $debugCount++
        }
        
        if (-not $extractedItemIDs.ContainsKey($itemId)) {
            $missingItems += @{
                ID = $itemId
                Name = $itemName
                Category = $categoryName
            }
        }
    }
    
    Write-Host ""
}

# Summary
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DIAGNOSTIC RESULTS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Database (with Drop filter): $($allDatabaseItems.Count) items" -ForegroundColor White
Write-Host "Extracted to Lua files:      $($extractedItemIDs.Count) items" -ForegroundColor White
Write-Host "Missing from extraction:     $($missingItems.Count) items" -ForegroundColor $(if ($missingItems.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

if ($missingItems.Count -gt 0) {
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "  MISSING ITEMS BREAKDOWN" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    
    # Group by category
    $missingByCategory = $missingItems | Group-Object -Property Category
    
    foreach ($group in $missingByCategory) {
        Write-Host "$($group.Name): $($group.Count) missing items" -ForegroundColor Cyan
        
        if ($group.Count -le 10) {
            foreach ($item in $group.Group | Sort-Object Name) {
                Write-Host "  - [$($item.ID)] $($item.Name)" -ForegroundColor Gray
            }
        } else {
            # Show first 5 and last 5
            $sortedItems = $group.Group | Sort-Object Name
            Write-Host "  First 5:" -ForegroundColor Gray
            $sortedItems | Select-Object -First 5 | ForEach-Object {
                Write-Host "    - [$($_.ID)] $($_.Name)" -ForegroundColor Gray
            }
            Write-Host "  ... ($($group.Count - 10) more items)" -ForegroundColor DarkGray
            Write-Host "  Last 5:" -ForegroundColor Gray
            $sortedItems | Select-Object -Last 5 | ForEach-Object {
                Write-Host "    - [$($_.ID)] $($_.Name)" -ForegroundColor Gray
            }
        }
        Write-Host ""
    }
    
    # Export full list to file
    $reportFile = Join-Path $PSScriptRoot "MissingItems_Report.txt"
    $report = @"
═══════════════════════════════════════════
  MISSING VANITY ITEMS - DETAILED REPORT
═══════════════════════════════════════════

Total Missing: $($missingItems.Count) items
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

"@
    
    foreach ($group in $missingByCategory) {
        $report += "`n$($group.Name) ($($group.Count) items):`n"
        $report += "─────────────────────────────────────────────`n"
        foreach ($item in $group.Group | Sort-Object Name) {
            $report += "  [$($item.ID)] $($item.Name)`n"
        }
    }
    
    $report | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Host "Full report saved to: MissingItems_Report.txt" -ForegroundColor Green
    Write-Host ""
}

Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  NEXT STEPS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Review the missing items list above" -ForegroundColor White
Write-Host "2. Check if these are edge cases or validation issues" -ForegroundColor White
Write-Host "3. Run extraction with -Verbose to see why they were skipped" -ForegroundColor White
Write-Host "4. Consider if the missing items are worth special handling" -ForegroundColor White
Write-Host ""
