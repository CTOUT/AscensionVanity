# Generate VanityDB from Filtered API Scan
# Creates a new VanityDB.lua with smart drop-based filtering

param(
    [string]$SavedVariablesPath = "d:\Program Files\Ascension Launcher\resources\client\WTF\Account\chris-tout@outlook.com\SavedVariables\AscensionVanity.lua",
    [string]$OutputPath = ".\AscensionVanity\VanityDB_New.lua",
    [switch]$Backup
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Generate VanityDB from API Scan" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $SavedVariablesPath)) {
    Write-Host "ERROR: SavedVariables file not found" -ForegroundColor Red
    exit 1
}

# Backup existing VanityDB if requested
if ($Backup -and (Test-Path ".\AscensionVanity\VanityDB.lua")) {
    $backupPath = ".\AscensionVanity\VanityDB_Backup_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').lua"
    Copy-Item ".\AscensionVanity\VanityDB.lua" -Destination $backupPath
    Write-Host "Backed up existing VanityDB to: $backupPath" -ForegroundColor Green
    Write-Host ""
}

Write-Host "Reading API scan data..." -ForegroundColor Yellow
$content = Get-Content $SavedVariablesPath -Raw

# Statistics
$stats = @{
    TotalScanned = 0
    ConfirmedDrops = 0
    PotentialDrops = 0
    Excluded = 0
    Generated = 0
}

$vanityItems = @{}  # ItemID -> Item Data

# Extract all items with full details
# Pattern handles escaped quotes in strings: (?:[^"\\]|\\.)*
# This matches either: non-quote/non-backslash OR backslash followed by any character
$pattern = '\["itemId"\]\s*=\s*(\d+),.*?\["itemLink"\]\s*=\s*"((?:[^"\\]|\\.)*)".*?\["name"\]\s*=\s*"((?:[^"\\]|\\.)*)".*?\["quality"\]\s*=\s*(\d+).*?\["creaturePreview"\]\s*=\s*(\d+).*?\["description"\]\s*=\s*"((?:[^"\\]|\\.)*)".*?\["icon"\]\s*=\s*"((?:[^"\\]|\\.)*)"'
$regexMatches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

Write-Host "Processing $($regexMatches.Count) items..." -ForegroundColor Yellow
Write-Host ""

foreach ($match in $regexMatches) {
    $itemId = [int]$match.Groups[1].Value
    $itemLink = $match.Groups[2].Value
    $itemName = $match.Groups[3].Value
    $quality = [int]$match.Groups[4].Value
    $creatureId = [int]$match.Groups[5].Value
    $description = $match.Groups[6].Value
    $icon = $match.Groups[7].Value
    
    $stats.TotalScanned++
    
    # Apply smart filtering - ONLY INCLUDE BEASTMASTER'S WHISTLES (combat pets)
    $shouldInclude = $false
    $category = ""
    
    # RULE 1: ONLY include items with "Beastmaster's Whistle" in the name
    if ($itemName -match "Beastmaster's Whistle") {
        # Still exclude vendor/time-limited items even if they're whistles
        if ($description -match "Webstore|webstore|purchase|Purchase|buy|sold|vendor|Vendor|quest|Quest|achievement|Achievement|Available from|Purchasable|Token|Previously had a chance") {
            $shouldInclude = $false
            $stats.Excluded++
        }
        # Confirmed drops (has drop/chance language)
        elseif ($description -match "drop|drops|chance") {
            $shouldInclude = $true
            $stats.ConfirmedDrops++
            $category = "confirmed_drop"
        }
        # Has creature ID with no/minimal description (potential drop)
        elseif ($creatureId -gt 0 -and ($description -eq "" -or $description.Length -lt 20)) {
            $shouldInclude = $true
            $stats.PotentialDrops++
            $category = "potential_drop"
        }
        else {
            $shouldInclude = $false
            $stats.Excluded++
        }
    }
    # RULE 2: Exclude everything else (mounts, non-combat pets, etc.)
    else {
        $shouldInclude = $false
        $stats.Excluded++
    }
    
    # Add to vanity items if included
    if ($shouldInclude) {
        $vanityItems[$itemId] = @{
            ItemId = $itemId
            Name = $itemName
            CreaturePreview = $creatureId
            Description = $description
            Icon = $icon
            Quality = $quality
            ItemLink = $itemLink
            Category = $category
        }
        $stats.Generated++
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PROCESSING SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total items scanned: $($stats.TotalScanned)" -ForegroundColor White
Write-Host "Confirmed drops: $($stats.ConfirmedDrops)" -ForegroundColor Green
Write-Host "Potential drops: $($stats.PotentialDrops)" -ForegroundColor Yellow
Write-Host "Excluded: $($stats.Excluded)" -ForegroundColor Red
Write-Host ""
Write-Host "Items to include in VanityDB: $($stats.Generated)" -ForegroundColor Green
Write-Host ""

# Generate the Lua file
Write-Host "Generating VanityDB.lua..." -ForegroundColor Yellow

$luaContent = @"
-- AscensionVanity Database V2.0
-- Generated from API scan on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
-- Smart filtered for drop-based items only
-- Total items: $($stats.Generated)
-- Confirmed drops: $($stats.ConfirmedDrops)
-- Potential drops (needs verification): $($stats.PotentialDrops)

AV_VanityItems = {
"@

# Sort by item ID
$sortedItems = $vanityItems.GetEnumerator() | Sort-Object { [int]$_.Key }

foreach ($entry in $sortedItems) {
    $item = $entry.Value
    
    # Data from Lua file is already properly escaped, so we can use it directly
    # Just need to ensure no additional escaping occurs
    $safeName = $item.Name
    $safeDescription = $item.Description
    $safeIcon = $item.Icon
    
    # Add comment indicator for potential drops needing verification
    $comment = ""
    if ($item.Category -eq "potential_drop" -and ($item.Description -eq "" -or $item.Description.Length -lt 20)) {
        $comment = " -- NEEDS VERIFICATION"
    }
    
    $luaContent += @"

    [$($item.ItemId)] = {
        itemid = $($item.ItemId),
        name = "$safeName",
        creaturePreview = $($item.CreaturePreview),
        description = "$safeDescription",
        icon = "$safeIcon"
    },$comment
"@
}

$luaContent += @"

}

-- Metadata
AV_VanityDB_Meta = {
    version = "2.0",
    generated = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    totalItems = $($stats.Generated),
    confirmedDrops = $($stats.ConfirmedDrops),
    potentialDrops = $($stats.PotentialDrops),
    source = "API Scan with Smart Filtering"
}
"@

# Write the file
$luaContent | Out-File -FilePath $OutputPath -Encoding UTF8 -NoNewline

Write-Host "VanityDB generated successfully!" -ForegroundColor Green
Write-Host "Output: $OutputPath" -ForegroundColor Cyan
Write-Host ""

# File size
$fileInfo = Get-Item $OutputPath
$sizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
Write-Host "File size: $sizeKB KB" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Review VanityDB_New.lua for accuracy" -ForegroundColor White
Write-Host "2. Search for 'NEEDS VERIFICATION' comments" -ForegroundColor White
Write-Host "3. Replace VanityDB.lua with VanityDB_New.lua when ready" -ForegroundColor White
Write-Host "4. Test in-game with /reload" -ForegroundColor White
Write-Host ""
