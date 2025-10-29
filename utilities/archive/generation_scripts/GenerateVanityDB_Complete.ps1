# GenerateVanityDB_Complete.ps1
# Generates complete optimized database with ALL items using correct game IDs

param(
    [string]$FullDatabase = "AscensionVanity\VanityDB_New.lua",
    [string]$IdMapping = "data\AscensionVanity_Transformed.lua",
    [string]$DescriptionFixes = "data\EmptyDescriptions_Validated.json",
    [string]$OutputDB = "AscensionVanity\VanityDB.lua"
)

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Complete VanityDB Generator - ALL Items with Correct IDs    ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Icon mapping
$iconMap = @{
    "Beastmaster's Whistle" = 1
    "Blood Soaked Vellum" = 2
    "Summoner's Stone" = 3
    "Draconic Warhorn" = 4
    "Elemental Lodestone" = 5
}

# Step 1: Load API ID → Game ID mapping
Write-Host "Loading API ID → Game ID mapping..." -ForegroundColor Yellow
$mappingContent = Get-Content $IdMapping -Raw
$apiToGameId = @{}

# Parse the mapping: [API_ID] = GAME_ID
$mappingMatches = [regex]::Matches($mappingContent, '\[(\d+)\]\s*=\s*(\d+)')
foreach ($match in $mappingMatches) {
    $apiId = [int]$match.Groups[1].Value
    $gameId = [int]$match.Groups[2].Value
    $apiToGameId[$apiId] = $gameId
}

Write-Host "  Loaded $($apiToGameId.Count) API ID mappings" -ForegroundColor Green

# Step 2: Load description fixes
Write-Host "Loading description fixes..." -ForegroundColor Yellow
$descriptionFixes = @{}
if (Test-Path $DescriptionFixes) {
    $fixesData = Get-Content $DescriptionFixes | ConvertFrom-Json
    foreach ($item in $fixesData) {
        if ($item.Validated) {
            # Use game ID as key
            $descriptionFixes[$item.DbItemId] = $item.GeneratedDescription
        }
    }
}
Write-Host "  Loaded $($descriptionFixes.Count) description fixes" -ForegroundColor Green

# Step 3: Load full database (uses API IDs as keys)
Write-Host "Loading full item database..." -ForegroundColor Yellow
$dbContent = Get-Content $FullDatabase -Raw
$items = @()
$lines = $dbContent -split "`n"

$currentItem = $null
$inItem = $false

foreach ($line in $lines) {
    # Start of an item: [API_ID] = {
    if ($line -match '^\s*\[(\d+)\]\s*=\s*\{') {
        $currentItem = @{
            ApiId = [int]$matches[1]
        }
        $inItem = $true
        continue
    }
    
    # Inside an item
    if ($inItem) {
        if ($line -match 'itemid\s*=\s*(\d+)') {
            $currentItem.ItemId = [int]$matches[1]  # This is actually API ID in the old file
        }
        elseif ($line -match 'name\s*=\s*"([^"]+)"') {
            $currentItem.Name = $matches[1]
        }
        elseif ($line -match 'creaturePreview\s*=\s*(\d+)') {
            $currentItem.CreatureId = [int]$matches[1]
        }
        elseif ($line -match 'description\s*=\s*"([^"]*)"') {
            $currentItem.Description = $matches[1]
        }
        elseif ($line -match '^\s*\}') {
            # End of item - process it
            
            # Determine category
            $category = $null
            foreach ($cat in $iconMap.Keys) {
                if ($currentItem.Name -like "$cat*") {
                    $category = $cat
                    break
                }
            }
            
            # Only keep combat pet items
            if ($category) {
                # Map API ID → Game ID
                $gameId = $apiToGameId[$currentItem.ApiId]
                
                if ($gameId) {
                    # Check if we have a description fix
                    if ($descriptionFixes.ContainsKey($gameId)) {
                        $currentItem.Description = $descriptionFixes[$gameId]
                    }
                    
                    $currentItem.GameItemId = $gameId
                    $currentItem.Category = $category
                    $currentItem.IconIndex = $iconMap[$category]
                    
                    $items += [PSCustomObject]$currentItem
                }
            }
            
            $inItem = $false
            $currentItem = $null
        }
    }
}

Write-Host "  Parsed $($items.Count) combat pet items" -ForegroundColor Green

# Statistics
Write-Host "`nCategory Breakdown:" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
$categoryStats = $items | Group-Object Category | Sort-Object Name
foreach ($cat in $categoryStats) {
    Write-Host "  $($cat.Name): $($cat.Count) items" -ForegroundColor White
}

$emptyDescriptions = ($items | Where-Object { [string]::IsNullOrEmpty($_.Description) }).Count
$fixedDescriptions = ($items | Where-Object { -not [string]::IsNullOrEmpty($_.Description) -and $descriptionFixes.ContainsKey($_.GameItemId) }).Count

Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  TOTAL: $($items.Count) items" -ForegroundColor Yellow
Write-Host "  Descriptions fixed: $fixedDescriptions" -ForegroundColor Green
Write-Host "  Still empty: $emptyDescriptions" -ForegroundColor $(if ($emptyDescriptions -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

# Step 4: Generate optimized database
Write-Host "Generating optimized database with icon indexing..." -ForegroundColor Yellow

$dbContent = @"
-- AscensionVanity Database - Combat Pets Only (Optimized & Corrected)
-- Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Uses CORRECT game Item IDs as primary keys
-- Total items: $($items.Count)
-- Optimization: Icon indexing (~40KB saved)

-- Icon lookup table
AV_IconList = {
    [1] = "Ability_Hunter_BeastCall",      -- Beastmaster's Whistles (Hunter)
    [2] = "Ability_DK_RuneWeapon",         -- Blood Soaked Vellums (Death Knight)
    [3] = "Spell_Shadow_SummonFelGuard",   -- Summoner's Stones (Warlock)
    [4] = "Spell_Nature_WispSplode",       -- Draconic Warhorns (Mage)
    [5] = "Spell_Fire_SelfDestruct"        -- Elemental Lodestones (Shaman)
}

AV_VanityItems = {
"@

# Sort by Game Item ID
$sortedItems = $items | Sort-Object GameItemId

foreach ($item in $sortedItems) {
    $safeName = $item.Name -replace '"', '\"'
    $safeDesc = $item.Description -replace '"', '\"'
    
    $needsVerification = if ([string]::IsNullOrEmpty($item.Description)) { " -- NEEDS VERIFICATION" } else { "" }
    
    $dbContent += @"

    [$($item.GameItemId)] = {
        itemid = $($item.GameItemId),
        name = "$safeName",
        creaturePreview = $($item.CreatureId),
        description = "$safeDesc",
        icon = $($item.IconIndex)
    },$needsVerification
"@
}

$dbContent += @"

}
"@

# Write output
Write-Host "Writing to $OutputDB..." -ForegroundColor Yellow
$dbContent | Set-Content $OutputDB -Encoding UTF8

$fileSize = (Get-Item $OutputDB).Length / 1KB

Write-Host "`n✅ Generation complete!" -ForegroundColor Green
Write-Host "  Output: $OutputDB" -ForegroundColor Cyan
Write-Host "  Size: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Cyan
Write-Host "  Items: $($items.Count)" -ForegroundColor Cyan
Write-Host "  Using CORRECT Game Item IDs as keys" -ForegroundColor Green
Write-Host ""
