# Extract creature IDs for items with empty descriptions

$itemIds = @(80096, 80098, 80099, 80106, 80353, 480382, 601009, 601067, 601677, 603976, 1180288, 1180317, 1180320, 1180510, 1180511, 1180526, 1180599, 1180833)

$content = Get-Content "AscensionVanity\VanityDB.lua" -Raw

Write-Host "`nExtracting creature IDs from VanityDB.lua...`n" -ForegroundColor Cyan

$results = @()

foreach ($itemId in $itemIds) {
    # Pattern to match the item entry and extract name and creaturePreview
    $pattern = "\[$itemId\]\s*=\s*\{[^\}]*?\[`"name`"\]\s*=\s*`"([^`"]+)`"[^\}]*?\[`"creaturePreview`"\]\s*=\s*(\d+)"
    
    if ($content -match $pattern) {
        $itemName = $matches[1]
        $creatureId = $matches[2]
        
        # Extract just the NPC name (after the prefix)
        $npcName = $itemName -replace '^(Beastmaster''s Whistle|Elemental Lodestone|Draconic Warhorn):\s*', ''
        
        $result = [PSCustomObject]@{
            ItemId = $itemId
            CreatureId = $creatureId
            ItemName = $itemName
            NPCName = $npcName
        }
        
        $results += $result
        
        Write-Host "$itemId -> Creature $creatureId : $npcName" -ForegroundColor Green
    }
    else {
        Write-Host "$itemId -> NOT FOUND" -ForegroundColor Red
    }
}

Write-Host "`nFound $($results.Count) / $($itemIds.Count) creature IDs`n" -ForegroundColor Yellow

# Export results
$results | Export-Csv -Path "data\EmptyDescriptions_CreatureIds.csv" -NoTypeInformation
Write-Host "Exported to: data\EmptyDescriptions_CreatureIds.csv" -ForegroundColor Cyan

# Display formatted table
$results | Format-Table -AutoSize
