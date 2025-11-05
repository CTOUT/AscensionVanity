<#
.SYNOPSIS
    Validates high/unusual creature IDs against db.ascension.gg

.DESCRIPTION
    Ascension has duplicate NPCs with modified IDs (40-prefix, 400-prefix, or other patterns).
    This script identifies items with unusually high creature IDs and validates them via:
    1. Direct creature ID lookup on db.ascension.gg
    2. Item name search to find the correct creature ID
    3. Comparison to identify mismatches

.NOTES
    CreatureID = Source of the drop (what you kill)
    CreaturePreview = Appearance of the pet (what it looks like when spawned)
    These can differ, and we need to validate the CreatureID is correct.

.EXAMPLE
    .\ValidateHighCreatureIDs.ps1
    Validates all items and generates report

.EXAMPLE
    .\ValidateHighCreatureIDs.ps1 -Threshold 100000
    Only check IDs above 100,000
#>

param(
    [int]$Threshold = 100000,  # Check IDs above this value
    [switch]$AutoFix,          # Automatically apply corrections
    [int]$RateLimitSeconds = 2
)

$ErrorActionPreference = 'Stop'

$masterPath = 'data/MasterFullValidated.json'
$zoneMapPath = 'data/AscensionZoneMap.json'
$reportPath = 'data/triage/HighCreatureID_Validation_Report.csv'
$correctionsPath = 'data/corrections/CreatureIdCorrections_HighIDs.json'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  High Creature ID Validation" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Load data
Write-Host "[1/5] Loading data..." -ForegroundColor Green
$items = Get-Content $masterPath -Raw | ConvertFrom-Json
$zoneMapJson = Get-Content $zoneMapPath -Raw | ConvertFrom-Json
$script:zoneMap = @{}
foreach ($prop in $zoneMapJson.PSObject.Properties) {
    $script:zoneMap[$prop.Name] = $prop.Value
}

Write-Host "  Loaded $($items.Count) items" -ForegroundColor Gray
Write-Host "  Threshold: Creature IDs > $Threshold" -ForegroundColor Gray

# Identify high IDs
Write-Host "`n[2/5] Identifying high creature IDs..." -ForegroundColor Green
$highIdItems = $items | Where-Object { $_.CreatureId -gt $Threshold }
Write-Host "  Found $($highIdItems.Count) items with high creature IDs" -ForegroundColor Yellow

if ($highIdItems.Count -eq 0) {
    Write-Host "  No items to validate!" -ForegroundColor Green
    exit 0
}

# Helper function to extract creature name from item name
function Get-CreatureNameFromItem {
    param([string]$ItemName)
    if ($ItemName -match '^[^:]+:\s*(.+)$') {
        return $Matches[1].Trim()
    }
    return $ItemName
}

# Helper function to generate potential base IDs
function Get-PotentialBaseIds {
    param([int]$CreatureId)
    
    $idString = $CreatureId.ToString()
    $potentialIds = @()
    
    # Original ID
    $potentialIds += $CreatureId
    
    # Try removing 40 prefix (4015650 -> 15650)
    if ($idString.Length -eq 7 -and $idString.StartsWith('40')) {
        $baseId = [int]$idString.Substring(2)
        $potentialIds += $baseId
    }
    
    # Try removing 400 prefix (40015650 -> 15650)
    if ($idString.Length -eq 8 -and $idString.StartsWith('400')) {
        $baseId = [int]$idString.Substring(3)
        $potentialIds += $baseId
    }
    
    # Try removing first digit if 6+ digits (141734 -> 41734, 21734, etc.)
    if ($idString.Length -ge 6) {
        for ($i = 1; $i -lt $idString.Length - 4; $i++) {
            $testId = [int]$idString.Substring($i)
            if ($testId -gt 100 -and $testId -lt 100000) {
                $potentialIds += $testId
            }
        }
    }
    
    return $potentialIds | Select-Object -Unique
}

# Check Wowhead WOTLK
function Test-WowheadNpc {
    param([int]$NpcId, [string]$ExpectedName)
    
    Start-Sleep -Seconds $RateLimitSeconds
    
    try {
        $url = "https://www.wowhead.com/wotlk/npc=$NpcId"
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        
        # Extract name from title
        if ($response.Content -match '<title>([^<-]+)') {
            $name = $Matches[1].Trim()
            $nameMatch = $name -eq $ExpectedName
            
            # Try to extract zone
            $zone = $null
            if ($response.Content -match '"location":\[(\d+)\]') {
                # Would need Wowhead zone mapping
            }
            
            return @{
                Success = $true
                Exists = $true
                Name = $name
                NameMatch = $nameMatch
                Zone = $zone
            }
        }
        
        return @{ Success = $false; Exists = $false }
        
    } catch {
        return @{ Success = $false; Exists = $false; Error = $_.Exception.Message }
    }
}

# Validation function
function Test-CreatureIdViaWeb {
    param(
        [int]$CreatureId,
        [string]$ItemName,
        [int]$ItemId
    )
    
    $creatureName = Get-CreatureNameFromItem -ItemName $ItemName
    $result = @{
        CreatureName = $creatureName
        OriginalId = $CreatureId
        CorrectId = $CreatureId
        Source = $null
        NameMatch = $false
        Confidence = "Unknown"
    }
    
    # Strategy: Try multiple sources in order of reliability
    # 1. Try potential base IDs (removing 40/400 prefix) on db.ascension.gg
    # 2. Search by creature name on db.ascension.gg
    # 3. Try original ID on wowhead.com/wotlk
    # 4. Search by creature name on wowhead.com/wotlk
    
    $potentialIds = Get-PotentialBaseIds -CreatureId $CreatureId
    
    # Method 1: Try each potential base ID on Ascension
    foreach ($testId in $potentialIds) {
        if ($testId -eq $CreatureId) { continue }  # Skip original, try modified IDs first
        
        Start-Sleep -Seconds $RateLimitSeconds
        
        try {
            $url = "https://db.ascension.gg/?npc=$testId"
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
            
            if ($response.Content -match '<title>([^<]+) - NPC') {
                $actualName = $Matches[1].Trim()
                
                if ($actualName -eq $creatureName) {
                    # Found matching name with base ID!
                    $zone = $null
                    if ($response.Content -match '"location":\[(\d+)\]') {
                        $zoneId = $Matches[1]
                        if ($script:zoneMap.ContainsKey($zoneId)) {
                            $zone = $script:zoneMap[$zoneId]
                        }
                    }
                    
                    $result.CorrectId = $testId
                    $result.Source = "db.ascension.gg (base ID: $testId from $CreatureId)"
                    $result.NameMatch = $true
                    $result.Confidence = "High"
                    $result.Zone = $zone
                    return $result
                }
            }
        } catch {
            # ID doesn't exist, try next
            continue
        }
    }
    
    # Method 2: Search by creature name on Ascension
    Start-Sleep -Seconds $RateLimitSeconds
    
    try {
        $searchUrl = "https://db.ascension.gg/?npcs&filter=na=$([uri]::EscapeDataString($creatureName))"
        $searchResponse = Invoke-WebRequest -Uri $searchUrl -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        
        $npcMatches = [regex]::Matches($searchResponse.Content, '"id":(\d+).*?"name":"([^"]+)"')
        
        if ($npcMatches.Count -gt 0) {
            # Find exact name match, prefer lowest ID
            $exactMatch = $npcMatches | Where-Object { $_.Groups[2].Value -eq $creatureName } | 
                         Sort-Object { [int]$_.Groups[1].Value } | Select-Object -First 1
            
            if ($exactMatch) {
                $foundId = [int]$exactMatch.Groups[1].Value
                
                $result.CorrectId = $foundId
                $result.Source = "db.ascension.gg (name search)"
                $result.NameMatch = $true
                $result.Confidence = "Medium"
                return $result
            }
        }
    } catch {
        # Name search failed, continue
    }
    
    # Method 3: Try original ID on Wowhead WOTLK
    $wowheadResult = Test-WowheadNpc -NpcId $CreatureId -ExpectedName $creatureName
    
    if ($wowheadResult.Success -and $wowheadResult.Exists) {
        if ($wowheadResult.NameMatch) {
            $result.CorrectId = $CreatureId
            $result.Source = "wowhead.com/wotlk (original ID)"
            $result.NameMatch = $true
            $result.Confidence = "Medium"
            $result.Zone = $wowheadResult.Zone
            return $result
        }
    }
    
    # Method 4: Try base IDs on Wowhead WOTLK
    foreach ($testId in $potentialIds) {
        if ($testId -eq $CreatureId) { continue }
        
        $wowheadResult = Test-WowheadNpc -NpcId $testId -ExpectedName $creatureName
        
        if ($wowheadResult.Success -and $wowheadResult.Exists -and $wowheadResult.NameMatch) {
            $result.CorrectId = $testId
            $result.Source = "wowhead.com/wotlk (base ID: $testId from $CreatureId)"
            $result.NameMatch = $true
            $result.Confidence = "Low"
            $result.Zone = $wowheadResult.Zone
            return $result
        }
    }
    
    # Method 5: Search by name on Wowhead (not implemented - would need custom parsing)
    
    # No match found
    $result.CorrectId = $CreatureId  # Keep original
    $result.Source = "Not found - keeping original ID"
    $result.NameMatch = $false
    $result.Confidence = "None"
    return $result
}

# Validate each high ID item
Write-Host "`n[3/5] Validating creature IDs via web lookup..." -ForegroundColor Green
Write-Host "  (This will take ~$($highIdItems.Count * $RateLimitSeconds) seconds due to rate limiting)" -ForegroundColor Gray

$results = @()
$progressCount = 0

foreach ($item in $highIdItems) {
    $progressCount++
    
    if ($progressCount % 10 -eq 0) {
        Write-Host "  Progress: $progressCount / $($highIdItems.Count)" -ForegroundColor Gray
    }
    
    $validation = Test-CreatureIdViaWeb -CreatureId $item.CreatureId -ItemName $item.Name -ItemId $item.DbItemId
    
    # Determine status
    $needsCorrection = $validation.CorrectId -ne $item.CreatureId
    $status = if ($validation.Confidence -eq "None") { "NOT_FOUND" }
             elseif (-not $validation.NameMatch) { "NAME_MISMATCH" }
             elseif ($needsCorrection) { "NEEDS_CORRECTION" }
             else { "OK" }
    
    $result = [PSCustomObject]@{
        ItemId = $item.DbItemId
        ItemName = $item.Name
        Category = $item.Category
        CreatureName = $validation.CreatureName
        CurrentCreatureId = $item.CreatureId
        CorrectCreatureId = $validation.CorrectId
        NeedsCorrection = $needsCorrection
        NameMatch = $validation.NameMatch
        Confidence = $validation.Confidence
        Source = $validation.Source
        Zone = $validation.Zone
        CurrentZone = $item.zone
        CurrentDescription = $item.Description
        Status = $status
    }
    
    $results += $result
    
    # Display status
    $statusColor = switch ($result.Status) {
        "OK" { "Green" }
        "NEEDS_CORRECTION" { "Yellow" }
        "NAME_MISMATCH" { "Red" }
        "NOT_FOUND" { "DarkRed" }
    }
    
    $statusSymbol = switch ($result.Status) {
        "OK" { "✓" }
        "NEEDS_CORRECTION" { "⚠" }
        "NAME_MISMATCH" { "✗" }
        "NOT_FOUND" { "?" }
    }
    
    Write-Host "  $statusSymbol [$($item.DbItemId)]" -ForegroundColor $statusColor -NoNewline
    Write-Host " $($validation.CreatureName)" -ForegroundColor Gray
    
    if ($result.Status -ne "OK") {
        Write-Host "    Current: $($item.CreatureId) → Correct: $($result.CorrectCreatureId)" -ForegroundColor DarkGray
        Write-Host "    Source: $($validation.Source)" -ForegroundColor DarkGray
    }
}

# Generate summary
Write-Host "`n[4/5] Analysis Summary" -ForegroundColor Green

$stats = @{
    OK = ($results | Where-Object { $_.Status -eq "OK" }).Count
    NeedsCorrection = ($results | Where-Object { $_.Status -eq "NEEDS_CORRECTION" }).Count
    NameMismatch = ($results | Where-Object { $_.Status -eq "NAME_MISMATCH" }).Count
    NotFound = ($results | Where-Object { $_.Status -eq "NOT_FOUND" }).Count
}

Write-Host "  ✓ Valid (OK): $($stats.OK)" -ForegroundColor Green
Write-Host "  ⚠ Needs Correction: $($stats.NeedsCorrection)" -ForegroundColor Yellow
Write-Host "  ✗ Name Mismatch: $($stats.NameMismatch)" -ForegroundColor Red
Write-Host "  ? Not Found: $($stats.NotFound)" -ForegroundColor DarkRed

# Show confidence breakdown
$confidenceStats = $results | Group-Object Confidence | ForEach-Object { 
    "$($_.Name): $($_.Count)" 
} | Sort-Object
Write-Host "`n  Confidence Breakdown:" -ForegroundColor Gray
foreach ($stat in $confidenceStats) {
    Write-Host "    $stat" -ForegroundColor DarkGray
}

# Save report
Write-Host "`n[5/5] Saving report..." -ForegroundColor Green
$results | Export-Csv -Path $reportPath -NoTypeInformation
Write-Host "  Report saved: $reportPath" -ForegroundColor Cyan

# Generate corrections file for items needing correction
$corrections = $results | Where-Object { $_.NeedsCorrection -eq $true -and $_.Confidence -ne "None" }

if ($corrections.Count -gt 0) {
    Write-Host "`n  Found $($corrections.Count) items needing correction" -ForegroundColor Yellow
    
    $correctionData = @{}
    foreach ($correction in $corrections) {
        $correctionData[$correction.ItemId.ToString()] = @{
            itemId = $correction.ItemId
            itemName = $correction.ItemName
            creatureName = $correction.CreatureName
            wrongCreatureId = $correction.CurrentCreatureId
            correctCreatureId = $correction.CorrectCreatureId
            confidence = $correction.Confidence
            source = $correction.Source
            reason = "High ID validation - found via $($correction.Source)"
            verifiedBy = "Multi-source web validation"
            dateAdded = Get-Date -Format "yyyy-MM-dd"
            zone = $correction.Zone
        }
    }
    
    $correctionData | ConvertTo-Json -Depth 10 | Out-File $correctionsPath -Encoding UTF8
    Write-Host "  Corrections saved: $correctionsPath" -ForegroundColor Cyan
    
    if ($AutoFix) {
        Write-Host "`n  Applying corrections..." -ForegroundColor Yellow
        # Apply corrections to MasterFullValidated.json
        $master = Get-Content $masterPath -Raw | ConvertFrom-Json
        $correctionCount = 0
        
        foreach ($item in $master) {
            $correction = $corrections | Where-Object { $_.ItemId -eq $item.DbItemId }
            if ($correction) {
                $item | Add-Member -NotePropertyName "CreatureId" -NotePropertyValue $correction.CorrectCreatureId -Force
                $correctionCount++
                Write-Host "    ✓ Corrected item $($item.DbItemId): $($correction.CurrentCreatureId) → $($correction.CorrectCreatureId)" -ForegroundColor Green
            }
        }
        
        $master | ConvertTo-Json -Depth 10 | Out-File $masterPath -Encoding UTF8
        Write-Host "  Applied $correctionCount corrections to $masterPath" -ForegroundColor Green
    } else {
        Write-Host "`n  Run with -AutoFix to apply corrections automatically" -ForegroundColor Gray
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Validation Complete!" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
