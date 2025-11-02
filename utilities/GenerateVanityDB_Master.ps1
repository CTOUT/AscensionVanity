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

# Icon mapping (same as final generator)
$iconMap = @{
    "Beastmaster's Whistle" = 1
    "Blood Soaked Vellum"   = 2
    "Summoner's Stone"      = 3
    "Draconic Warhorn"      = 4
    "Elemental Lodestone"   = 5
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
    $iconIndex = $iconMap[$it.Category]
    if (-not $iconIndex) { $skipped++; continue }
    # Parse zone/subzone from description (v2.1 enhancement)
    $zone = $null
    $subzone = $null
    if ($it.Description) {
        # Pattern: "within [location]"
        if ($it.Description -match 'within\s+([^"]+)$') {
            $location = $Matches[1].Trim()
            
            # Check if location is a subzone (needs parent zone lookup)
            $parentZone = $subzoneToZone[$location]
            if ($parentZone) {
                $zone = $parentZone
                $subzone = $location
            } else {
                # Treat as primary zone
                $zone = $location
                $subzone = $null
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
        icon = $iconIndex
    }
}

Write-Host "Emitted items: $($processed.Count)" -ForegroundColor Green
Write-Host "Skipped items (missing data/category): $skipped" -ForegroundColor Yellow

# Gather unique icons from raw scan data - ONLY from the 5 combat pet categories
Write-Host "Analyzing unique icons from combat pet categories..." -ForegroundColor Cyan
$scanFile = ".\data\AscensionVanity.lua"
$uniqueIcons = @{}

# Combat pet Group IDs we care about
$combatPetGroups = @(16777217, 16777220, 16777218, 16777224, 16777232)

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
                
                # Only process items from our 5 combat pet categories
                if ($combatPetGroups -contains $groupId) {
                    # Extract icon from this block
                    if ($blockContent -match '\["icon"\]\s*=\s*"([^"]+)"') {
                        $iconName = $Matches[1]
                        # Clean up icon path
                        $cleanIcon = $iconName -replace 'Interface\\\\Icons\\\\', '' -replace 'Interface\\Icons\\', ''
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
Write-Host "  Found $($iconArray.Count) unique icons from combat pet categories" -ForegroundColor Gray

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

$header = @"
-- AscensionVanity Full Database v2.1
-- Generated: $timestamp
-- Total Items: $($processed.Count)$scanMetadata
-- 
-- Database Structure:
--   AV_IconList: Deduplicated icon paths referenced by index
--   AV_VanityItems: Combat pet items indexed by game item ID
-- 
-- Schema v2.1 Fields:
--   itemid: Game item ID
--   name: Full item name with prefix
--   creaturePreview: Visual model ID (immutable from API)
--   creatureId: Drop source creature ID (corrected if needed)
--   description: Full description text
--   zone: Primary zone/region (optional)
--   subzone: Specific location within zone (optional)
--   icon: Index into AV_IconList
-- 
-- Categories: Beast, Demon, Elemental, Dragonkin, Undead
-- Group IDs: 16777217, 16777220, 16777218, 16777224, 16777232

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
    $safeName = $p.name -replace '\\', '\\' -replace '"', '\"'
    $safeDesc = $p.description -replace '\\', '\\' -replace '"', '\"'
    $safeZone = if ($p.zone) { $p.zone -replace '\\', '\\' -replace '"', '\"' } else { $null }
    $safeSubzone = if ($p.subzone) { $p.subzone -replace '\\', '\\' -replace '"', '\"' } else { $null }
    
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
    $db += ('        icon = ' + $p.icon)
    $db += '    },'
}
$db += "}" 

$db -join "`n" | Set-Content $OutputDB -Encoding UTF8
$sizeKB = (Get-Item $OutputDB).Length / 1KB
Write-Host "Database written: $OutputDB ($([math]::Round($sizeKB,2)) KB)" -ForegroundColor Cyan
Write-Host "Dedupe unique items: $($emitted.Count)" -ForegroundColor Green