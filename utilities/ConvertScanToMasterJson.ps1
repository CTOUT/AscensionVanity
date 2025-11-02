<#
.SYNOPSIS
    Convert AscensionVanity.lua scan file to MasterFullValidated.json
.DESCRIPTION
    Fast, simple parser that reads the Lua scan file line-by-line and converts
    combat pet items to JSON format with proper escaping.
    
    Filters to 5 combat pet Group IDs:
    - 16777217: Beastmaster's Whistle
    - 16777220: Blood Soaked Vellum
    - 16777218: Summoner's Stone
    - 16777224: Draconic Warhorn
    - 16777232: Elemental Lodestone
.USAGE
    .\utilities\ConvertScanToMasterJson.ps1
    .\utilities\ConvertScanToMasterJson.ps1 -ScanFile data\AscensionVanity.lua -OutputJson data\MasterFullValidated.json
#>
[CmdletBinding()]
param(
    [string]$ScanFile = 'data/AscensionVanity.lua',
    [string]$OutputJson = 'data/MasterFullValidated.json',
    [string]$ManualResearchFile = 'data/corrections/ManualResearch.json'
)

function Write-Step { param([string]$Message) Write-Host "[STEP] $Message" -ForegroundColor Cyan }
function Write-Info { param([string]$Message) Write-Host "  $Message" -ForegroundColor Gray }
function Write-Success { param([string]$Message) Write-Host "  ✓ $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "  ⚠ $Message" -ForegroundColor Yellow }

if (-not (Test-Path $ScanFile)) {
    Write-Error "Scan file not found: $ScanFile"
    exit 1
}

# Combat pet Group IDs
$combatPetGroups = @(16777217, 16777220, 16777218, 16777224, 16777232)

# Category mapping
$categoryMap = @{
    16777217 = "Beastmaster's Whistle"
    16777220 = "Blood Soaked Vellum"
    16777218 = "Summoner's Stone"
    16777224 = "Draconic Warhorn"
    16777232 = "Elemental Lodestone"
}

# Vendor/purchase exclusion keywords (case-insensitive)
$exclusionKeywords = @(
    'purchase',
    'webstore',
    'website',
    'previously',
    'bazaar',
    'seasonal',
    'reward',
    'promo',
    'event',
    'limited',
    'achievement',
    'reputation',
    'quartermaster',
    'obtained from',
    'purchased from',
    'sold by',
    'requires exalted',
    'can purchase'
)

Write-Step "Reading scan file: $ScanFile"
$lines = Get-Content $ScanFile -Encoding UTF8

Write-Step "Parsing APIDump section"
$items = [System.Collections.ArrayList]@()
$inAPIDump = $false
$currentItem = $null
$currentItemId = $null
$lineNum = 0
$totalLines = $lines.Count

foreach ($line in $lines) {
    $lineNum++
    
    # Show progress every 10000 lines
    if ($lineNum % 10000 -eq 0) {
        Write-Progress -Activity "Parsing scan file" -Status "$lineNum / $totalLines lines" -PercentComplete (($lineNum / $totalLines) * 100)
    }
    
    # Detect APIDump section start
    if ($line -match '^\s*\["APIDump"\]\s*=\s*\{') {
        $inAPIDump = $true
        Write-Info "Found APIDump section at line $lineNum"
        continue
    }
    
    # Skip until we're in APIDump
    if (-not $inAPIDump) { continue }
    
    # Detect item start: [12345] = {
    if ($line -match '^\s*\[(\d+)\]\s*=\s*\{') {
        $currentItemId = [int]$Matches[1]
        $currentItem = @{
            itemid = $currentItemId
            name = $null
            creaturePreview = 0
            group = 0
            icon = $null
            description = ''
        }
        continue
    }
    
    # Parse fields within current item
    if ($currentItem) {
        # Name: ["name"] = "Some Name",
        if ($line -match '^\s*\["name"\]\s*=\s*"(.+)"') {
            # Unescape Lua string: \" becomes " and \\ becomes \
            $rawName = $Matches[1]
            $unescapedName = $rawName -replace '\\(.)', '$1'  # Remove escape backslashes
            $currentItem.name = $unescapedName
        }
        # CreaturePreview: ["creaturePreview"] = 12345,
        elseif ($line -match '^\s*\["creaturePreview"\]\s*=\s*(\d+)') {
            $currentItem.creaturePreview = [int]$Matches[1]
        }
        # Group: ["group"] = 16777217,
        elseif ($line -match '^\s*\["group"\]\s*=\s*(\d+)') {
            $currentItem.group = [int]$Matches[1]
        }
        # Icon: ["icon"] = "icon_name",
        elseif ($line -match '^\s*\["icon"\]\s*=\s*"(.+)"') {
            $currentItem.icon = $Matches[1]
        }
        # Description: ["description"] = "Some description",
        elseif ($line -match '^\s*\["description"\]\s*=\s*"(.+)"') {
            # Unescape Lua string: \" becomes " and \\ becomes \
            $rawDesc = $Matches[1]
            $unescapedDesc = $rawDesc -replace '\\(.)', '$1'  # Remove escape backslashes
            $currentItem.description = $unescapedDesc
        }
        # Item end: },
        elseif ($line -match '^\s*\},?\s*$') {
            # Check if this item belongs to combat pet categories
            if ($combatPetGroups -contains $currentItem.group) {
                # Check for vendor/purchase exclusions in name or description
                $shouldExclude = $false
                $itemText = "$($currentItem.name) $($currentItem.description)".ToLower()
                
                foreach ($keyword in $exclusionKeywords) {
                    if ($itemText -match [regex]::Escape($keyword.ToLower())) {
                        $shouldExclude = $true
                        break
                    }
                }
                
                # Only add if not excluded
                if (-not $shouldExclude) {
                    $category = $categoryMap[$currentItem.group]
                    
                    # Create JSON object
                    $jsonItem = [PSCustomObject]@{
                        DbItemId = $currentItem.itemid
                        Name = $currentItem.name
                        CreatureId = if ($currentItem.creaturePreview -gt 0) { $currentItem.creaturePreview } else { $null }
                        Description = if ($currentItem.description) { $currentItem.description } else { $null }
                        Category = $category
                        Validated = if ($currentItem.description) { $true } else { $false }
                        VendorExempt = $false
                    }
                    
                    [void]$items.Add($jsonItem)
                }
            }
            
            # Reset for next item
            $currentItem = $null
            $currentItemId = $null
        }
    }
    
    # Exit APIDump section (reached end of the outer AscensionVanityDump table)
    if ($line -match '^\s*\}\s*$' -and $inAPIDump -and -not $currentItem) {
        # Could be end of APIDump or just a nested structure - keep parsing until we're sure
        # We'll keep going until we hit the actual end
    }
}

Write-Progress -Activity "Parsing scan file" -Completed
Write-Success "Parsed $($items.Count) combat pet items from scan"

# Load manual research if available
if (Test-Path $ManualResearchFile) {
    Write-Step "Loading manual research: $ManualResearchFile"
    $manualResearch = Get-Content $ManualResearchFile -Raw | ConvertFrom-Json
    
    $addedCount = 0
    $updatedCount = 0
    
    foreach ($research in $manualResearch) {
        $existingItem = $items | Where-Object { $_.DbItemId -eq $research.DbItemId }
        
        if ($existingItem) {
            # Update existing item with manual research
            if ($research.Description) {
                $existingItem.Description = $research.Description
                $existingItem.Validated = $true
                $updatedCount++
            }
            if ($research.CreatureId) {
                $existingItem.CreatureId = $research.CreatureId
            }
        } else {
            # Add new item from manual research
            $newItem = [PSCustomObject]@{
                DbItemId = $research.DbItemId
                Name = $research.Name
                CreatureId = $research.CreatureId
                Description = $research.Description
                Category = $research.Category
                Validated = $true
                VendorExempt = $false
            }
            [void]$items.Add($newItem)
            $addedCount++
        }
    }
    
    Write-Success "Manual research: $updatedCount updated, $addedCount added"
}

# Sort by ItemId for consistency
Write-Step "Sorting items by DbItemId"
$items = $items | Sort-Object DbItemId

# Write JSON
Write-Step "Writing JSON: $OutputJson"
$items | ConvertTo-Json -Depth 10 | Set-Content $OutputJson -Encoding UTF8

Write-Success "Complete! Wrote $($items.Count) items to $OutputJson"

# Statistics
$withDescriptions = ($items | Where-Object { $_.Description }).Count
$withoutDescriptions = $items.Count - $withDescriptions
$percentage = [math]::Round(($withDescriptions / $items.Count) * 100, 2)

Write-Host ""
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Info "Total items: $($items.Count)"
Write-Info "With descriptions: $withDescriptions ($percentage%)"
Write-Info "Without descriptions: $withoutDescriptions"
Write-Host ""
