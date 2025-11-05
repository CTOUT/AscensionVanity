# Quick Group ID Validation
# Fast check for unknown Group IDs without full JSON parsing

$ErrorActionPreference = 'Stop'

$freshScanPath = 'data/AscensionVanity.lua'

Write-Host "`n=== Quick Group ID Validation ===" -ForegroundColor Cyan

# Known Group IDs
$knownGroupIds = @(16777217, 16777220, 16777218, 16777224, 16777232, 553648129, 553648130, 553648136)

Write-Host "Known Group IDs: $($knownGroupIds -join ', ')" -ForegroundColor Gray

# Use regex to find all group IDs in the file (much faster than JSON parsing)
Write-Host "`nScanning file for Group IDs..." -ForegroundColor Yellow

$content = Get-Content $freshScanPath -Raw

# Extract all group values using regex
$groupMatches = [regex]::Matches($content, '\["group"\]\s*=\s*(\d+)')

$groupIds = @{}
foreach ($match in $groupMatches) {
    $groupId = [int]$match.Groups[1].Value
    if (-not $groupIds.ContainsKey($groupId)) {
        $groupIds[$groupId] = 0
    }
    $groupIds[$groupId]++
}

Write-Host "Found $($groupIds.Count) unique Group IDs" -ForegroundColor Cyan

# Check for unknown Group IDs
$unknownGroupIds = $groupIds.Keys | Where-Object { $_ -notin $knownGroupIds }

if ($unknownGroupIds.Count -gt 0) {
    Write-Host "`n⚠ WARNING: Found $($unknownGroupIds.Count) unknown Group IDs!" -ForegroundColor Yellow
    
    foreach ($groupId in ($unknownGroupIds | Sort-Object)) {
        $count = $groupIds[$groupId]
        Write-Host "  Group ID $groupId : $count items" -ForegroundColor Red
        
        # Show sample items from this group
        $sampleMatches = [regex]::Matches($content, "(\[`"name`"\]\s*=\s*`"[^`"]+`")[^}]*\[`"group`"\]\s*=\s*$groupId")
        if ($sampleMatches.Count -gt 0) {
            $sampleName = $sampleMatches[0].Groups[1].Value
            Write-Host "    Sample: $sampleName" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "`n⚠ ACTION REQUIRED: Add these Group IDs to the filter or investigate!" -ForegroundColor Yellow
} else {
    Write-Host "`n✓ All Group IDs are known - no new groups detected!" -ForegroundColor Green
}

# Show breakdown of known groups
Write-Host "`n=== Known Group Breakdown ===" -ForegroundColor Cyan
foreach ($groupId in ($knownGroupIds | Sort-Object)) {
    if ($groupIds.ContainsKey($groupId)) {
        $count = $groupIds[$groupId]
        $category = switch ($groupId) {
            16777217 { "Beastmaster's Whistle (Beasts)" }
            16777220 { "Blood Soaked Vellum (Undead)" }
            16777218 { "Summoner's Stone (Demons)" }
            16777224 { "Draconic Warhorn (Dragonkin)" }
            16777232 { "Elemental Lodestone (Elementals)" }
            553648129 { "Seasonal Rewards (Type 1)" }
            553648130 { "Seasonal Rewards (Type 2)" }
            553648136 { "Seasonal Rewards (Type 3)" }
            default { "Unknown" }
        }
        Write-Host "  $groupId : $count items - $category" -ForegroundColor White
    }
}

$totalKnown = ($knownGroupIds | ForEach-Object { if ($groupIds.ContainsKey($_)) { $groupIds[$_] } else { 0 } } | Measure-Object -Sum).Sum
Write-Host "`nTotal Combat Pets: $totalKnown" -ForegroundColor Green

Write-Host "`n=== Validation Complete ===" -ForegroundColor Cyan
