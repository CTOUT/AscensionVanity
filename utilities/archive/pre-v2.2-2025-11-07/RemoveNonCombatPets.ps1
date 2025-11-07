<#
.SYNOPSIS
    Removes non-combat-pet items from VanityDB.lua

.DESCRIPTION
    Removes items that don't match the 5 combat pet category prefixes:
    - Beastmaster's Whistle
    - Blood Soaked Vellum
    - Summoner's Stone
    - Draconic Warhorn
    - Elemental Lodestone
    
    These are typically mounts, weapons, armor, and other non-pet items
    that were incorrectly included in the database.

.PARAMETER DryRun
    Shows what would be removed without actually modifying the file

.EXAMPLE
    .\RemoveNonCombatPets.ps1 -DryRun
    Preview changes without modifying files

.EXAMPLE
    .\RemoveNonCombatPets.ps1
    Remove non-combat-pet items from VanityDB.lua
#>

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# File paths
$vanityDBPath = ".\AscensionVanity\VanityDB.lua"
$backupPath = ".\AscensionVanity\VanityDB.lua.backup"

# Validate file exists
if (-not (Test-Path $vanityDBPath)) {
    Write-Error "VanityDB.lua not found at: $vanityDBPath"
    exit 1
}

Write-Host "`n=== Non-Combat-Pet Removal Tool ===" -ForegroundColor Cyan
Write-Host "Target file: $vanityDBPath" -ForegroundColor Yellow

# Read the file
Write-Host "`nReading VanityDB.lua..." -ForegroundColor Cyan
$lines = Get-Content $vanityDBPath

# Category prefixes to keep
$categoryPrefixes = @(
    "Beastmaster's Whistle:",
    "Blood Soaked Vellum:",
    "Summoner's Stone:",
    "Draconic Warhorn:",
    "Elemental Lodestone:"
)

# Parse items
$itemsToRemove = @()
$validItems = 0
$currentItem = $null
$inItem = $false
$itemLines = @()

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    
    # Start of item
    if ($line -match '^\s+\[(\d+)\] = \{') {
        $currentItemId = $matches[1]
        $inItem = $true
        $itemLines = @($i)
        continue
    }
    
    # Item name line
    if ($inItem -and $line -match 'name = "([^"]+)"') {
        $itemName = $matches[1]
        
        # Check if valid category
        $isValid = $false
        foreach ($prefix in $categoryPrefixes) {
            if ($itemName.StartsWith($prefix)) {
                $isValid = $true
                break
            }
        }
        
        if ($isValid) {
            $validItems++
        } else {
            $itemsToRemove += [PSCustomObject]@{
                ItemId = $currentItemId
                Name = $itemName
                StartLine = $itemLines[0]
            }
        }
    }
    
    # End of item
    if ($inItem -and $line -match '^\s+\},?\s*$') {
        $itemLines += $i
        $inItem = $false
        
        # Store end line for last item
        if ($itemsToRemove.Count -gt 0 -and $itemsToRemove[-1].ItemId -eq $currentItemId) {
            $itemsToRemove[-1] | Add-Member -NotePropertyName EndLine -NotePropertyValue $i -Force
        }
    }
}

Write-Host "Total valid items: $validItems" -ForegroundColor Green
Write-Host "Total items to remove: $($itemsToRemove.Count)" -ForegroundColor Yellow

Write-Host "`nItems to remove: $($itemsToRemove.Count)" -ForegroundColor Yellow
Write-Host "Valid combat pet items: $validItems" -ForegroundColor Green

if ($itemsToRemove.Count -eq 0) {
    Write-Host "`nNo non-combat-pet items found. Database is clean!" -ForegroundColor Green
    exit 0
}

# Display items to be removed
Write-Host "`nNon-combat-pet items found:" -ForegroundColor Red
$itemsToRemove | Format-Table -Property ItemId, Name -AutoSize

if ($DryRun) {
    Write-Host "`n[DRY RUN] No changes made. Run without -DryRun to remove these items." -ForegroundColor Yellow
    exit 0
}

# Confirm removal
Write-Host "`nThis will remove $($itemsToRemove.Count) items from VanityDB.lua" -ForegroundColor Yellow
$confirmation = Read-Host "Continue? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

# Create backup
Write-Host "`nCreating backup..." -ForegroundColor Cyan
Copy-Item $vanityDBPath $backupPath -Force
Write-Host "Backup created: $backupPath" -ForegroundColor Green

# Remove items by rebuilding file
Write-Host "`nRemoving non-combat-pet items..." -ForegroundColor Cyan
$newLines = @()
$skipUntilLine = -1

for ($i = 0; $i -lt $lines.Count; $i++) {
    # Check if we should skip this line
    if ($i -le $skipUntilLine) {
        continue
    }
    
    # Check if this line starts an item to remove
    $shouldSkip = $false
    foreach ($item in $itemsToRemove) {
        if ($i -eq $item.StartLine) {
            $skipUntilLine = $item.EndLine
            $shouldSkip = $true
            Write-Host "  Removing [$($item.ItemId)]: $($item.Name)" -ForegroundColor Yellow
            break
        }
    }
    
    if (-not $shouldSkip) {
        $newLines += $lines[$i]
    }
}

# Update item count in header
for ($i = 0; $i -lt $newLines.Count; $i++) {
    if ($newLines[$i] -match '-- Total items: \d+') {
        $newLines[$i] = "-- Total items: $validItems"
        break
    }
}

# Write the updated content
Write-Host "`nWriting updated VanityDB.lua..." -ForegroundColor Cyan
$newLines | Set-Content $vanityDBPath

Write-Host "`n=== Removal Complete ===" -ForegroundColor Green
Write-Host "Items removed: $($itemsToRemove.Count)" -ForegroundColor Yellow
Write-Host "Items remaining: $validItems" -ForegroundColor Green
Write-Host "Backup saved to: $backupPath" -ForegroundColor Cyan
Write-Host "`nReload the addon in-game to see changes." -ForegroundColor Yellow
