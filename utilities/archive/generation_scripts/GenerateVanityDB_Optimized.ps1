# GenerateVanityDB_Optimized.ps1
# Generates optimized VanityDB.lua with:
# - Correct ItemId (game ID) as primary key
# - Icon indexing to reduce file size
# - Backfilled descriptions from EmptyDescriptions_Validated.json

param(
    [string]$ApiDataFile = "AscensionVanity\VanityDB_New.lua",
    [string]$DescriptionsFile = "data\EmptyDescriptions_Validated.json",
    [string]$OutputDB = "AscensionVanity\VanityDB.lua"
)

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        VanityDB Optimized Generator - Combat Pets Only          ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Define the 5 combat pet categories with their icons
$iconMap = @{
    "Beastmaster's Whistle" = "Ability_Hunter_BeastCall"
    "Blood Soaked Vellum" = "Ability_DK_RuneWeapon"
    "Summoner's Stone" = "Spell_Shadow_SummonFelGuard"
    "Draconic Warhorn" = "Spell_Nature_WispSplode"
    "Elemental Lodestone" = "Spell_Fire_SelfDestruct"
}

# Create reverse lookup for icon indices
$iconList = @(
    "Ability_Hunter_BeastCall",      # 1 - Beastmaster's Whistles
    "Ability_DK_RuneWeapon",         # 2 - Blood Soaked Vellums
    "Spell_Shadow_SummonFelGuard",   # 3 - Summoner's Stones
    "Spell_Nature_WispSplode",       # 4 - Draconic Warhorns
    "Spell_Fire_SelfDestruct"        # 5 - Elemental Lodestones
)

$iconIndex = @{}
for ($i = 0; $i -lt $iconList.Count; $i++) {
    $iconIndex[$iconList[$i]] = $i + 1
}

Write-Host "Loading source data..." -ForegroundColor Yellow

# Load the transformed API data
$apiContent = Get-Content $ApiDataFile -Raw

# Load validated descriptions for backfilling
$descriptions = @{}
if (Test-Path $DescriptionsFile) {
    Write-Host "Loading validated descriptions for backfilling..." -ForegroundColor Yellow
    $validatedData = Get-Content $DescriptionsFile | ConvertFrom-Json
    foreach ($item in $validatedData) {
        # Use actual game ItemId (DbItemId) as key
        $descriptions[$item.DbItemId] = $item.GeneratedDescription
    }
    Write-Host "  Loaded $($descriptions.Count) validated descriptions" -ForegroundColor Green
}

# Parse the Lua table
Write-Host "Parsing API data..." -ForegroundColor Yellow
$items = @()
$lines = $apiContent -split "`n"

$currentItem = $null
$inItem = $false

foreach ($line in $lines) {
    # Start of an item
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
            $currentItem.ItemId = [int]$matches[1]
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
        elseif ($line -match 'icon\s*=\s*"([^"]+)"') {
            $currentItem.Icon = $matches[1]
        }
        elseif ($line -match '^\s*\}') {
            # End of item - determine category and keep if combat pet
            $category = $null
            foreach ($cat in $iconMap.Keys) {
                if ($currentItem.Name -like "$cat*") {
                    $category = $cat
                    break
                }
            }
            
            if ($category) {
                # This is a combat pet item
                $currentItem.Category = $category
                
                # Backfill empty description if available
                if ([string]::IsNullOrEmpty($currentItem.Description) -and $descriptions.ContainsKey($currentItem.ItemId)) {
                    $currentItem.Description = $descriptions[$currentItem.ItemId]
                }
                
                # Determine icon index
                $expectedIcon = $iconMap[$category]
                $currentItem.IconIndex = $iconIndex[$expectedIcon]
                
                $items += [PSCustomObject]$currentItem
            }
            
            $inItem = $false
            $currentItem = $null
        }
    }
}

Write-Host "`nFiltering Results:" -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$categoryStats = $items | Group-Object Category | Sort-Object Name
foreach ($cat in $categoryStats) {
    Write-Host "  $($cat.Name): $($cat.Count) items" -ForegroundColor White
}

$emptyDescriptions = ($items | Where-Object { [string]::IsNullOrEmpty($_.Description) }).Count
$backfilled = ($items | Where-Object { -not [string]::IsNullOrEmpty($_.Description) -and $descriptions.ContainsKey($_.ItemId) }).Count

Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  TOTAL: $($items.Count) combat pet items" -ForegroundColor Yellow
Write-Host "  Descriptions backfilled: $backfilled" -ForegroundColor Green
Write-Host "  Still empty: $emptyDescriptions" -ForegroundColor $(if ($emptyDescriptions -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

# Generate optimized database
Write-Host "Generating optimized VanityDB.lua..." -ForegroundColor Yellow

$dbContent = @"
-- AscensionVanity Database - Combat Pets Only (Optimized)
-- Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Contains ONLY the 5 combat pet vanity item categories
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

# Sort by ItemId (game ID) for consistency
$sortedItems = $items | Sort-Object ItemId

foreach ($item in $sortedItems) {
    # Escape quotes in strings
    $safeName = $item.Name -replace '"', '\"'
    $safeDesc = $item.Description -replace '"', '\"'
    
    $needsVerification = if ([string]::IsNullOrEmpty($item.Description)) { " -- NEEDS VERIFICATION" } else { "" }
    
    $dbContent += @"

    [$($item.ItemId)] = {
        itemid = $($item.ItemId),
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

# Calculate file size
$fileSize = (Get-Item $OutputDB).Length / 1KB

Write-Host "`n✅ Generation complete!" -ForegroundColor Green
Write-Host "  Output: $OutputDB" -ForegroundColor Cyan
Write-Host "  Size: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Cyan
Write-Host "  Items: $($items.Count)" -ForegroundColor Cyan
Write-Host ""
