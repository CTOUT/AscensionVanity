<#!
.SYNOPSIS
    Generate full VanityDB.lua from MasterFullValidated.json
.DESCRIPTION
    Reads data/MasterFullValidated.json (created by BuildMasterFullValidated.ps1) containing all items.
    Emits AscensionVanity/VanityDB.lua with icon indexing and vendor exemptions (CreatureId 0 retained).
    Skips entries without Category or Name.
    Applies dedupe protection.
.NOTES
    Author: Automated master generator
    Date: 2025-11-01
#>
[CmdletBinding()]
param(
    [string]$MasterJson = 'data/MasterFullValidated.json',
    [string]$OutputDB = 'AscensionVanity/VanityDB.lua'
)

if (!(Test-Path $MasterJson)) { Write-Error "Master JSON not found: $MasterJson"; exit 1 }

Write-Host "Loading master JSON..." -ForegroundColor Cyan
$items = Get-Content $MasterJson -Raw | ConvertFrom-Json
Write-Host "Total items loaded: $($items.Count)" -ForegroundColor Yellow

# Load quest-locked NPC data (v2.2)
Write-Host "Loading quest-locked NPC data..." -ForegroundColor Cyan
$questLockedFile = 'data/QuestLockedNPCs.json'
$questLockedData = @{}

if (Test-Path $questLockedFile) {
    $questLockedJson = Get-Content $questLockedFile -Raw | ConvertFrom-Json
    foreach ($entry in $questLockedJson.questLockedNPCs) {
        $questLockedData[$entry.itemId] = $entry
    }
    Write-Host "  Loaded $($questLockedData.Count) quest-locked NPCs" -ForegroundColor Gray
} else {
    Write-Warning "Quest-locked NPCs file not found: $questLockedFile (no quest warnings will be included)"
}

# Load zone mappings for subzone → parent zone lookup (v2.1)
Write-Host "Loading zone mappings..." -ForegroundColor Cyan
$zoneMappingsFile = 'data/ZoneMappings.json'
$subzoneToZone = @{}

if (Test-Path $zoneMappingsFile) {
    $zoneMappings = Get-Content $zoneMappingsFile -Raw | ConvertFrom-Json
    
    # Build reverse lookup: subzone → parent zone
    foreach ($zoneName in $zoneMappings.zones.PSObject.Properties.Name) {
        $zoneData = $zoneMappings.zones.$zoneName
        if ($zoneData.subzones) {
            foreach ($subzone in $zoneData.subzones) {
                $subzoneToZone[$subzone] = $zoneName
            }
        }
    }
    
    Write-Host "  Loaded $($subzoneToZone.Count) subzone mappings" -ForegroundColor Gray
} else {
    Write-Warning "Zone mappings file not found: $zoneMappingsFile (subzones will be treated as zones)"
}

# Load pet family mappings (v2.3)
Write-Host "Loading pet family mappings..." -ForegroundColor Cyan
$petFamilyFile = 'data/PetFamilyMapping.json'
$petFamilyLookup = @{}
$petFamilyDetails = @{}

if (Test-Path $petFamilyFile) {
    $petFamilyData = Get-Content $petFamilyFile -Raw | ConvertFrom-Json
    
    # Build creatureId → family lookup (use creatures, not items!)
    foreach ($creatureId in $petFamilyData.creatureToFamily.PSObject.Properties.Name) {
        $familyData = $petFamilyData.creatureToFamily.$creatureId
        $petFamilyLookup[$creatureId] = $familyData
    }
    
    # Also store full family details for enrichment
    foreach ($familyId in $petFamilyData.families.PSObject.Properties.Name) {
        $family = $petFamilyData.families.$familyId
        $petFamilyDetails[$familyId] = $family
    }
    
    Write-Host "  Loaded $($petFamilyLookup.Count) creature → family mappings" -ForegroundColor Gray
    Write-Host "  Loaded $($petFamilyDetails.Count) family definitions" -ForegroundColor Gray
} else {
    Write-Warning "Pet family mappings file not found: $petFamilyFile (no family data will be included)"
}

# Icon mapping - combat pets use fixed indices, others use actual icon from data
$iconMap = @{
    "Beastmaster's Whistle" = 1
    "Blood Soaked Vellum"   = 2
    "Summoner's Stone"      = 3
    "Draconic Warhorn"      = 4
    "Elemental Lodestone"   = 5
    # Cosmetic Abilities and Mounts use their actual icon string (not index)
}

$emitted = @{}
$processed = @()
$skipped = 0
foreach ($it in $items) {
    $id = $it.DbItemId
    if (-not $id) { $skipped++; continue }
    if ($emitted.ContainsKey($id)) { continue }
    if (-not $it.Name -or -not $it.Category) { $skipped++; continue }
    $emitted[$id] = $true
    
    # Get icon - either fixed index (combat pets) or lookup in array (cosmetics/mounts)
    $iconRef = $null
    if ($iconMap.ContainsKey($it.Category)) {
        # Combat pets use fixed indices
        $iconRef = $iconMap[$it.Category]
    } elseif ($it.Category -in @("Cosmetic Ability", "Mount") -and $it.Icon) {
        # Cosmetics/mounts - will look up index in icon array later
        $iconRef = $it.Icon  # Store icon name for now
    } else {
        $skipped++
        continue
    }
    # Use zone/subzone fields from JSON (v2.2 enhancement)
    # Zone enrichment now happens in EnrichZoneData.ps1 before generation
    $zone = $it.zone
    $subzone = $it.subzone
    
    # Check if the "zone" field is actually a subzone in our mappings
    # If so, swap them: promote parent to zone, demote current zone to subzone
    if ($zone -and -not $subzone) {
        $parentZone = $subzoneToZone[$zone]
        if ($parentZone) {
            # Zone field is actually a subzone - fix it!
            $subzone = $zone
            $zone = $parentZone
        }
    }
    
    # If subzone exists but no zone, try to find parent zone from mappings
    if ($subzone -and -not $zone) {
        $parentZone = $subzoneToZone[$subzone]
        if ($parentZone) {
            $zone = $parentZone
        }
    }
    
    # Check for quest lock data (v2.2)
    $questLock = $questLockedData[$id]
    
    # Check for pet family data (v2.3) - use CreatureId, not itemId!
    $petFamily = $null
    if ($it.CreatureId) {
        $familyBasic = $petFamilyLookup[$it.CreatureId.ToString()]
        if ($familyBasic) {
            # Get full family details
            $fullFamily = $petFamilyDetails[$familyBasic.familyId.ToString()]
            if ($fullFamily) {
                $petFamily = [pscustomobject]@{
                    familyId = $fullFamily.id
                    familyName = $fullFamily.name
                    familyType = $fullFamily.familyType
                    icon = $fullFamily.icon
                    isExotic = $fullFamily.isExotic
                }
            }
        }
    }
    
    $processed += [pscustomobject]@{
        itemid = $id
        name = $it.Name
        creaturePreview = $(if ($it.CreatureId) { $it.CreatureId } else { 0 })
        creatureId = $(if ($it.CreatureId) { $it.CreatureId } else { 0 })  # v2.1: Separate drop source
        description = $(if ($it.Description) { $it.Description } else { "" })
        zone = $zone  # v2.1: Primary zone
        subzone = $subzone  # v2.1: Specific location
        icon = $iconRef  # Icon index (number) or icon name (string to be looked up)
        questLock = $questLock  # v2.2: Quest lock information (null if not quest-locked)
        petFamily = $petFamily  # v2.3: Pet family data (null if not a combat pet)
    }
}

Write-Host "Emitted items: $($processed.Count)" -ForegroundColor Green
Write-Host "Skipped items (missing data/category): $skipped" -ForegroundColor Yellow

# Gather unique icons from raw scan data - ONLY from combat pet categories
Write-Host "Analyzing unique icons from combat pet categories..." -ForegroundColor Cyan
$scanFile = ".\data\AscensionVanity.lua"
$uniqueIcons = @{}

# Collectible Group IDs (10 total)
# Combat pets - Dropped (5 Group IDs):
#   16777217 = Beastmaster's Whistle (Beasts)
#   16777220 = Blood Soaked Vellum (Undead)
#   16777218 = Summoner's Stone (Demons)
#   16777224 = Draconic Warhorn (Dragonkin)
#   16777232 = Elemental Lodestone (Elementals)
# Combat pets - Seasonal/Event rewards (3 Group IDs):
#   553648129, 553648130, 553648136 = Seasonal reward pets
# Cosmetic Abilities (1 Group ID):
#   134217728 = Sigils and other cosmetic abilities (960 sigils + 289 other cosmetics)
# Mounts (1 Group ID):
#   67108864 = Mounts (604 total, ~28 farmable drops)
$combatPetGroups = @(16777217, 16777220, 16777218, 16777224, 16777232, 553648129, 553648130, 553648136)
$nonCombatCompanionGroups = @(134217728)  # Sigils, Calves, Cubs, etc.
$mountGroups = @(67108864, 671088640)  # Regular + Seasonal mounts
$bookGroups = @(167772160)  # Books of Ascension
$allCollectibleGroups = $combatPetGroups + $nonCombatCompanionGroups + $mountGroups + $bookGroups

if (Test-Path $scanFile) {
    $scanContent = Get-Content $scanFile -Raw
    
    # Find the APIDump section start
    $apiDumpStart = $scanContent.IndexOf('["APIDump"] = {')
    if ($apiDumpStart -gt 0) {
        $apiDumpContent = $scanContent.Substring($apiDumpStart)
        
        # Extract items with their group and icon from APIDump
        $itemBlocks = [regex]::Matches($apiDumpContent, '\[(\d+)\]\s*=\s*\{([^}]+)\}', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        
        foreach ($itemBlock in $itemBlocks) {
            $blockContent = $itemBlock.Groups[2].Value
            
            # Extract group ID from this block
            if ($blockContent -match '\["group"\]\s*=\s*(\d+)') {
                $groupId = [int]$Matches[1]
                
                # Only process items from our collectible categories
                if ($allCollectibleGroups -contains $groupId) {
                    # Extract icon from this block
                    if ($blockContent -match '\["icon"\]\s*=\s*"([^"]+)"') {
                        $iconName = $Matches[1]
                        # Clean up icon path - handle both escaped and normal slashes
                        $cleanIcon = $iconName -replace 'Interface\\\\Icons\\\\', '' -replace 'Interface\\Icons\\', '' -replace 'Interface/Icons/', ''
                        if ($cleanIcon -and -not $uniqueIcons.ContainsKey($cleanIcon)) {
                            $uniqueIcons[$cleanIcon] = $true
                        }
                    }
                }
            }
        }
    } else {
        Write-Warning "Could not find ['APIDump'] section in scan file"
    }
} else {
    Write-Warning "Scan file not found: $scanFile"
}

$iconArray = $uniqueIcons.Keys | Sort-Object
Write-Host "  Found $($iconArray.Count) unique icons from collectible categories" -ForegroundColor Gray

# Build icon name to index lookup
$iconNameToIndex = @{}
$idx = 1
foreach ($icon in $iconArray) {
    $iconNameToIndex[$icon] = $idx
    $idx++
}

# Convert string icon references to indices in processed items
foreach ($item in $processed) {
    if ($item.icon -is [string]) {
        # Clean the icon name
        $cleanIcon = $item.icon -replace 'Interface\\\\Icons\\\\', '' -replace 'Interface\\Icons\\', '' -replace 'Interface/Icons/', ''
        if ($iconNameToIndex.ContainsKey($cleanIcon)) {
            $item.icon = $iconNameToIndex[$cleanIcon]
        } else {
            # Icon not in array - this shouldn't happen, but handle gracefully
            Write-Warning "Icon not found in array: $cleanIcon (item $($item.itemid))"
            $item.icon = 1  # Default to first icon
        }
    }
}

# Build DB content with metadata
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

# Try to get source scan metadata
$scanMetadata = ""
$scanFile = ".\data\AscensionVanity.lua"
if (Test-Path $scanFile) {
    $scanContent = Get-Content $scanFile -Raw
    if ($scanContent -match '\["AscensionVersion"\]\s*=\s*"([^"]+)"') {
        $customVer = $matches[1]
        $scanMetadata = "`n-- Source Scan: Ascension $customVer"
    }
    if ($scanContent -match '\["LastScanDate"\]\s*=\s*"([^"]+)"') {
        $scanDate = $matches[1]
        $scanMetadata += "`n-- Scan Date: $scanDate"
    }
}

$iconListContent = ""
$iconIndex = 1
foreach ($icon in $iconArray) {
    $iconListContent += "    [$iconIndex] = `"$icon`","
    $iconIndex++
}
$iconListContent = $iconListContent.TrimEnd(',')

# Extract version metadata for runtime checks
$ascensionVersion = "Unknown"
$scanDate = "Unknown"
if (Test-Path $scanFile) {
    $scanContent = Get-Content $scanFile -Raw
    if ($scanContent -match '\["AscensionVersion"\]\s*=\s*"([^"]+)"') {
        $ascensionVersion = $matches[1]
    }
    if ($scanContent -match '\["LastScanDate"\]\s*=\s*"([^"]+)"') {
        $scanDate = $matches[1]
    }
}

$header = @"
-- AscensionVanity Full Database v2.3
-- Generated: $timestamp
-- Total Items: $($processed.Count)$scanMetadata
-- 
-- Database Structure:
--   AV_IconList: Deduplicated icon paths referenced by index
--   AV_VanityItems: Combat pet items indexed by game item ID
-- 
-- Schema v2.3 Fields:
--   itemid: Game item ID
--   name: Full item name with prefix
--   creaturePreview: Visual model ID (immutable from API)
--   creatureId: Drop source creature ID (corrected if needed)
--   description: Full description text
--   zone: Primary zone/region (optional)
--   subzone: Specific location within zone (optional)
--   icon: Index into AV_IconList
--   questLock: Quest-locked NPC information (optional v2.2)
--     - questId: Quest ID number
--     - questName: Quest name string
--     - lockType: "completion", "phase", "daily", "weekly"
--     - faction: "Horde", "Alliance", "Both"
--     - warning: Custom warning message
--     - notes: Additional context (summon method, etc.)
--   petFamily: Pet family information (optional v2.3)
--     - familyId: Pet family ID (1-155)
--     - familyName: Family display name (Wolf, Cat, Spider, etc.)
--     - familyType: Family role type (Ferocity, Tenacity, Cunning, Demon, Undead, Elemental, Dragonkin)
--     - icon: Family icon path
--     - isExotic: Whether family requires Beast Mastery specialization
-- 
-- Categories: Beast, Demon, Elemental, Dragonkin, Undead
-- Group IDs (10 total):
--   Combat Pets (Dropped): 16777217, 16777220, 16777218, 16777224, 16777232
--   Combat Pets (Seasonal): 553648129, 553648130, 553648136
--   Non-Combat Companions: 134217728 (Sigils, Calves, Cubs, etc.)
--   Mounts (Regular): 67108864
--   Mounts (Seasonal): 671088640
--   Books of Ascension: 167772160

-- Database metadata for version checking
AV_DatabaseInfo = {
    generatedDate = "$timestamp",
    ascensionVersion = "$ascensionVersion",
    scanDate = "$scanDate",
    totalItems = $($processed.Count),
    schemaVersion = "2.3",
    questLockedCount = $(($processed | Where-Object { $_.questLock }).Count),
    petFamilyCount = $(($processed | Where-Object { $_.petFamily }).Count)
}

AV_IconList = {
$iconListContent
}

AV_VanityItems = {
"@
$db = @($header)

foreach ($p in ($processed | Sort-Object itemid)) {
    # Escape for Lua strings
    # ConvertFrom-Json unescapes JSON, giving us the actual string
    # We need to escape backslashes first, then quotes for Lua
    # Using [regex]::Escape to properly handle backslashes, then manually escape quotes
    $safeName = $p.name -replace '\\', '\\\\' -replace '"', '\"'
    $safeDesc = $p.description -replace '\\', '\\\\' -replace '"', '\"'
    $safeZone = if ($p.zone) { $p.zone -replace '\\', '\\\\' -replace '"', '\"' } else { $null }
    $safeSubzone = if ($p.subzone) { $p.subzone -replace '\\', '\\\\' -replace '"', '\"' } else { $null }
    
    $db += ('    [' + $p.itemid + '] = {')
    $db += ('        itemid = ' + $p.itemid + ',')
    $db += ('        name = "' + $safeName + '",')
    $db += ('        creaturePreview = ' + $p.creaturePreview + ',')
    $db += ('        creatureId = ' + $p.creatureId + ',')
    $db += ('        description = "' + $safeDesc + '",')
    if ($safeZone) {
        $db += ('        zone = "' + $safeZone + '",')
    }
    if ($safeSubzone) {
        $db += ('        subzone = "' + $safeSubzone + '",')
    }
    $db += ('        icon = ' + $p.icon + ',')
    
    # Add quest lock data if present (v2.2)
    if ($p.questLock) {
        $safeQuestName = $p.questLock.questName -replace '\\', '\\\\' -replace '"', '\"'
        $safeWarning = $p.questLock.warning -replace '\\', '\\\\' -replace '"', '\"'
        $safeNotes = $p.questLock.notes -replace '\\', '\\\\' -replace '"', '\"'
        
        $db += '        questLock = {'
        $db += ('            questId = ' + $p.questLock.questId + ',')
        $db += ('            questName = "' + $safeQuestName + '",')
        $db += ('            lockType = "' + $p.questLock.lockType + '",')
        $db += ('            faction = "' + $p.questLock.faction + '",')
        $db += ('            warning = "' + $safeWarning + '",')
        $db += ('            notes = "' + $safeNotes + '"')
        $db += '        },'
    }
    
    # Add pet family data if present (v2.3)
    if ($p.petFamily) {
        $safeFamilyName = $p.petFamily.familyName -replace '\\', '\\\\' -replace '"', '\"'
        $safeFamilyType = $p.petFamily.familyType -replace '\\', '\\\\' -replace '"', '\"'
        $safeFamilyIcon = $p.petFamily.icon -replace '\\', '\\\\' -replace '"', '\"'
        
        $db += '        petFamily = {'
        $db += ('            familyId = ' + $p.petFamily.familyId + ',')
        $db += ('            familyName = "' + $safeFamilyName + '",')
        $db += ('            familyType = "' + $safeFamilyType + '",')
        $db += ('            icon = "' + $safeFamilyIcon + '",')
        $db += ('            isExotic = ' + $(if ($p.petFamily.isExotic) { 'true' } else { 'false' }))
        $db += '        }'
    }
    else {
        # Remove trailing comma from last line if no petFamily
        $db[-1] = $db[-1] -replace ',$', ''
    }
    
    $db += '    },'
}
$db += "}" 

$db -join "`n" | Set-Content $OutputDB -Encoding UTF8
$sizeKB = (Get-Item $OutputDB).Length / 1KB
Write-Host "Database written: $OutputDB ($([math]::Round($sizeKB,2)) KB)" -ForegroundColor Cyan
Write-Host "Dedupe unique items: $($emitted.Count)" -ForegroundColor Green