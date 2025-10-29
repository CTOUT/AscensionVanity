# Apply Final 8 Enrichments Based on Manual Research

$enrichments = @(
    @{
        ItemId = 480382
        Name = "Captain Claws"
        Location = $null
        Description = $null
        Note = "NPC doesn't exist - possibly reward/promo/purchase/not yet implemented"
    },
    @{
        ItemId = 601009
        Name = "Surging Water Elemental"
        Location = "Starter Zones"
        Description = "Has a chance to drop from Surging Water Elemental"
        Note = "Level 10 - likely in starter zones, possibly Shaman-related"
    },
    @{
        ItemId = 601677
        Name = "Stone Warden"
        Location = "Blackrock Depths"
        Description = "Has a chance to drop from Stone Warden within Blackrock Depths"
        Note = "Level 60-61 - Classic endgame dungeon"
    },
    @{
        ItemId = 603976
        Name = "Silver Golem"
        Location = "Drak'Tharon Keep"
        Description = "Has a chance to drop from Silver Golem within Drak'Tharon Keep"
        Note = "Ascension-specific (Spellwave Elemental), Drakkari Ice Troll zone"
    },
    @{
        ItemId = 1180288
        Name = "Sleeping Dragon"
        Location = "Blackrock Mountain"
        Description = "Has a chance to drop from Sleeping Dragon within Blackrock Mountain"
        Note = "Level 60 - Classic endgame, dragon-related area"
    },
    @{
        ItemId = 1180317
        Name = "Chromatic Whelp"
        Location = "Blackrock Mountain"
        Description = "Has a chance to drop from Chromatic Whelp within Blackrock Mountain"
        Note = "Ascension-specific, Level 57-58, Chromatic dragon area"
    },
    @{
        ItemId = 1180320
        Name = "Chromatic Dragonspawn"
        Location = "Blackrock Mountain"
        Description = "Has a chance to drop from Chromatic Dragonspawn within Blackrock Mountain"
        Note = "Ascension-specific, Level 57-58, Chromatic dragon area"
    },
    @{
        ItemId = 1180511
        Name = "Blackscale"
        Location = "Blade's Edge Mountains"
        Description = "Has a chance to drop from Blackscale within Blade's Edge Mountains"
        Note = "Ascension-specific, copy of NPC 21497, Level 70"
    }
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Applying Final 8 Manual Enrichments" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$vanityDbPath = "AscensionVanity\VanityDB.lua"
$content = Get-Content $vanityDbPath -Raw -Encoding UTF8

$updated = 0
$skipped = 0

foreach ($item in $enrichments) {
    Write-Host "Processing: $($item.Name)" -ForegroundColor White
    Write-Host "  Item ID: $($item.ItemId)" -ForegroundColor Gray
    
    if ($item.Description) {
        Write-Host "  Location: $($item.Location)" -ForegroundColor Green
        Write-Host "  Note: $($item.Note)" -ForegroundColor DarkGray
        
        # Pattern to match empty description
        $pattern = "(\[$($item.ItemId)\]\s*=\s*\{[^\}]*\[`"description`"\]\s*=\s*)`"`""
        
        if ($content -match $pattern) {
            $content = $content -replace $pattern, "`$1`"$($item.Description)`""
            $updated++
            Write-Host "  ✓ Updated" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Pattern not found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ⊗ Skipped - NPC doesn't exist" -ForegroundColor Yellow
        Write-Host "  Note: $($item.Note)" -ForegroundColor DarkGray
        $skipped++
    }
    
    Write-Host ""
}

if ($updated -gt 0) {
    Write-Host "Saving changes..." -ForegroundColor Cyan
    $content | Set-Content $vanityDbPath -Encoding UTF8 -NoNewline
    Write-Host "✓ Changes saved" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Green
Write-Host "  Updated: $updated" -ForegroundColor Green
Write-Host "  Skipped: $skipped (NPC doesn't exist)" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Check for remaining empty descriptions
$remainingEmpty = ([regex]::Matches($content, '\["description"\]\s*=\s*""')).Count

Write-Host "Remaining empty descriptions: $remainingEmpty" -ForegroundColor $(if ($remainingEmpty -eq 0) { "Green" } else { "Yellow" })

if ($remainingEmpty -gt 0) {
    Write-Host "These are likely correctly blank (rewards/promos/not yet implemented)" -ForegroundColor Gray
}
