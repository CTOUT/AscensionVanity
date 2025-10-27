# UpdateDatabaseFromAPI.ps1
# Generates an updated VanityDB.lua from the API dump in SavedVariables

param(
    [Parameter(Mandatory=$false)]
    [string]$SavedVariablesPath = "$env:USERPROFILE\AppData\Local\Ascension Launcher\World of Warcraft\WTF\Account\YOUR_ACCOUNT\SavedVariables\AscensionVanity.lua",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "$PSScriptRoot\..\AscensionVanity\VanityDB_Updated.lua",
    
    [Parameter(Mandatory=$false)]
    [switch]$Backup
)

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  AscensionVanity - Database Generator from API" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if SavedVariables file exists
if (-not (Test-Path $SavedVariablesPath)) {
    Write-Host "ERROR: SavedVariables file not found!" -ForegroundColor Red
    Write-Host "Path: $SavedVariablesPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please run '/av apidump' and '/reload' in-game first!" -ForegroundColor Yellow
    exit 1
}

Write-Host "Reading API dump from SavedVariables..." -ForegroundColor Cyan
$content = Get-Content $SavedVariablesPath -Raw

# Check if APIDump exists
if ($content -notmatch "APIDump\s*=\s*\{") {
    Write-Host "ERROR: No API dump found in SavedVariables!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run '/av apidump' in-game and then '/reload'" -ForegroundColor Yellow
    exit 1
}

Write-Host "API dump found!" -ForegroundColor Green

# Backup existing database if requested
if ($Backup) {
    $currentDB = "$PSScriptRoot\..\AscensionVanity\VanityDB.lua"
    if (Test-Path $currentDB) {
        $backupPath = "$PSScriptRoot\..\AscensionVanity\VanityDB_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').lua"
        Copy-Item $currentDB $backupPath
        Write-Host "Backed up current database to: $backupPath" -ForegroundColor Green
    }
}

# Parse the itemsByCreature table from the API dump
Write-Host ""
Write-Host "Parsing creature → item mappings from API..." -ForegroundColor Cyan

# Extract itemsByCreature section
$itemsByCreaturePattern = 'itemsByCreature\s*=\s*\{(.*?)\n\s*\}'
if ($content -match $itemsByCreaturePattern) {
    $itemsByCreatureData = $Matches[1]
    
    # Parse individual mappings: [creatureID] = { itemID1, itemID2, ... }
    $mappingPattern = '\[(\d+)\]\s*=\s*\{\s*([\d,\s]+)\s*\}'
    $mappings = [regex]::Matches($itemsByCreatureData, $mappingPattern)
    
    Write-Host "Found $($mappings.Count) creature → item mappings" -ForegroundColor Yellow
    
    # Build the new database structure
    $dbEntries = @{}
    $totalItems = 0
    $multiDropCreatures = 0
    
    foreach ($match in $mappings) {
        $creatureID = [int]$match.Groups[1].Value
        $itemIDsRaw = $match.Groups[2].Value
        
        # Parse item IDs (can be comma-separated for creatures with multiple drops)
        $itemIDs = $itemIDsRaw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
        
        if ($itemIDs.Count -gt 0) {
            # For now, take the first item (most creatures drop only one item)
            $itemID = $itemIDs[0]
            $dbEntries[$creatureID] = $itemID
            $totalItems++
            
            if ($itemIDs.Count -gt 1) {
                $multiDropCreatures++
            }
        }
    }
    
    Write-Host "  → $totalItems unique creature mappings" -ForegroundColor Green
    Write-Host "  → $multiDropCreatures creatures with multiple items (using first item)" -ForegroundColor Yellow
    
} else {
    Write-Host "ERROR: Could not find itemsByCreature data!" -ForegroundColor Red
    exit 1
}

# Extract item names for comments
Write-Host ""
Write-Host "Extracting item names for documentation..." -ForegroundColor Cyan

$itemNames = @{}
$itemsPattern = 'items\s*=\s*\{(.*?)\n\s*\},'
if ($content -match $itemsPattern) {
    $itemsData = $Matches[1]
    
    # Parse item data: [itemID] = { ... name = "ItemName", ... }
    $namePattern = '\[(\d+)\]\s*=\s*\{[^}]*name\s*=\s*"([^"]+)"'
    $nameMatches = [regex]::Matches($itemsData, $namePattern)
    
    foreach ($match in $nameMatches) {
        $itemID = [int]$match.Groups[1].Value
        $itemName = $match.Groups[2].Value
        $itemNames[$itemID] = $itemName
    }
    
    Write-Host "  → Extracted $($itemNames.Count) item names" -ForegroundColor Green
}

# Generate the new VanityDB.lua file
Write-Host ""
Write-Host "Generating new VanityDB.lua..." -ForegroundColor Cyan

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$output = @"
-- AscensionVanity - Vanity Items Database
-- Auto-generated from Ascension API via C_VanityCollection.GetAllItems()
-- Generated: $timestamp
-- Total items: $totalItems

AV_VanityItems = {
"@

# Sort by creature ID for easier lookup
$sortedCreatures = $dbEntries.Keys | Sort-Object

foreach ($creatureID in $sortedCreatures) {
    $itemID = $dbEntries[$creatureID]
    
    # Get item name if available
    $comment = ""
    if ($itemNames.ContainsKey($itemID)) {
        $comment = " -- $($itemNames[$itemID])"
    }
    
    $output += "`n    [$creatureID] = $itemID,$comment"
}

$output += @"

}

-- Generic drops by creature type (reserved for future use)
AV_GenericDropsByType = {
    -- Placeholder for type-based generic drops
}
"@

# Write to file
$output | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Database generation complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Generated file: $OutputPath" -ForegroundColor Green
Write-Host "  → Total mappings: $totalItems" -ForegroundColor Yellow
Write-Host "  → Creatures with multiple items: $multiDropCreatures" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review the generated file: VanityDB_Updated.lua" -ForegroundColor Yellow
Write-Host "  2. Compare with current VanityDB.lua to verify changes" -ForegroundColor Yellow
Write-Host "  3. Rename VanityDB_Updated.lua to VanityDB.lua to use it" -ForegroundColor Yellow
Write-Host "  4. Test in-game to verify all items work correctly" -ForegroundColor Yellow
Write-Host ""
