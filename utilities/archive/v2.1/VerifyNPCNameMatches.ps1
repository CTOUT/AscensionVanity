# Verify NPC Name Matches against db.ascension.gg
# Checks if the creature named in the item actually drops it

#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter()]
    [string]$DiscrepancyReport = 'data\VanityDB_Discrepancies_20251102_123820.csv',
    
    [Parameter()]
    [int]$RateLimitSeconds = 2
)

$ErrorActionPreference = 'Stop'

function Write-Step { param([string]$Message) Write-Host "[STEP] $Message" -ForegroundColor Cyan }
function Write-Info { param([string]$Message) Write-Host "  $Message" -ForegroundColor Gray }
function Write-Success { param([string]$Message) Write-Host "  ✓ $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "  ⚠ $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "  ✗ $Message" -ForegroundColor Red }

if (-not (Test-Path $DiscrepancyReport)) {
    Write-Error "Report not found: $DiscrepancyReport"
    exit 1
}

Write-Step "Loading discrepancy report"
$items = Import-Csv $DiscrepancyReport | Where-Object { $_.Issues -match 'NPCNameMismatch' }
Write-Info "Found $($items.Count) items with NPC name mismatches"

Write-Step "Verifying item drops on db.ascension.gg"
$corrections = @()
$index = 0

foreach ($item in $items) {
    $index++
    $itemId = $item.ItemId
    $itemName = $item.Name
    
    # Extract NPC name from item name (after the colon)
    $npcNameInItem = if ($itemName -match ':\s*(.+)$') { $matches[1] } else { "" }
    
    Write-Host "`n[$index/$($items.Count)] Item $itemId - $itemName" -ForegroundColor White
    Write-Info "NPC in item name: '$npcNameInItem'"
    Write-Info "Current description: $($item.Description.Substring(0, [Math]::Min(80, $item.Description.Length)))..."
    
    # Check db.ascension.gg for this item's drops
    $url = "https://db.ascension.gg/?item=$itemId"
    Write-Info "Checking $url"
    
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15
        $content = $response.Content
        
        # Look for the creature name in the "Dropped by" section
        # Pattern: <a href="?npc=...">CreatureName</a> in the dropped-by listview
        $droppedBySection = if ($content -match '<h2[^>]*>Dropped by</h2>(.*?)<h2') { $matches[1] } else { "" }
        
        if ($droppedBySection) {
            # Extract all creature names from links
            $creatureMatches = [regex]::Matches($droppedBySection, '<a[^>]*href="\?npc=\d+"[^>]*>([^<]+)</a>')
            $creatures = $creatureMatches | ForEach-Object { $_.Groups[1].Value }
            
            Write-Info "Dropped by: $($creatures -join ', ')"
            
            # Check if the item name creature is in the drop list
            $matchFound = $false
            foreach ($creature in $creatures) {
                if ($creature -eq $npcNameInItem) {
                    Write-Success "MATCH FOUND: '$npcNameInItem' does drop this item"
                    $matchFound = $true
                    
                    # Extract zone from current description
                    $currentZone = ""
                    if ($item.Description -match 'within (.+)$') {
                        $currentZone = $matches[1]
                    }
                    
                    $corrections += [PSCustomObject]@{
                        ItemId = $itemId
                        Name = $itemName
                        CreatureId = $item.CreatureId
                        ShouldUseItemName = $true
                        NPCNameInItem = $npcNameInItem
                        CurrentDescription = $item.Description
                        SuggestedDescription = "Has a chance to drop from $npcNameInItem within $currentZone"
                        DroppedBy = ($creatures -join '; ')
                    }
                    break
                }
            }
            
            if (-not $matchFound) {
                Write-Warn "Item name creature '$npcNameInItem' NOT in drop list"
                Write-Info "Using current description (in-game data)"
                
                $corrections += [PSCustomObject]@{
                    ItemId = $itemId
                    Name = $itemName
                    CreatureId = $item.CreatureId
                    ShouldUseItemName = $false
                    NPCNameInItem = $npcNameInItem
                    CurrentDescription = $item.Description
                    SuggestedDescription = $item.Description
                    DroppedBy = ($creatures -join '; ')
                }
            }
        } else {
            Write-Warn "No 'Dropped by' section found"
            
            $corrections += [PSCustomObject]@{
                ItemId = $itemId
                Name = $itemName
                CreatureId = $item.CreatureId
                ShouldUseItemName = $null
                NPCNameInItem = $npcNameInItem
                CurrentDescription = $item.Description
                SuggestedDescription = $item.Description
                DroppedBy = "Not found"
            }
        }
    }
    catch {
        Write-Fail "Error: $($_.Exception.Message)"
        
        $corrections += [PSCustomObject]@{
            ItemId = $itemId
            Name = $itemName
            CreatureId = $item.CreatureId
            ShouldUseItemName = $null
            NPCNameInItem = $npcNameInItem
            CurrentDescription = $item.Description
            SuggestedDescription = $item.Description
            DroppedBy = "ERROR: $($_.Exception.Message)"
        }
    }
    
    # Rate limiting
    if ($index -lt $items.Count) {
        Start-Sleep -Seconds $RateLimitSeconds
    }
}

Write-Host "`n"
Write-Step "Verification Results"
$needsCorrection = ($corrections | Where-Object { $_.ShouldUseItemName -eq $true }).Count
Write-Host "  Items where item name IS correct: $needsCorrection" -ForegroundColor Green
Write-Host "  Items where current description is correct: $(($corrections | Where-Object { $_.ShouldUseItemName -eq $false }).Count)" -ForegroundColor Yellow
Write-Host "  Items with errors: $(($corrections | Where-Object { $_.ShouldUseItemName -eq $null }).Count)" -ForegroundColor Red

# Save report
$reportPath = "data\NPCNameMatch_Verification_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$corrections | Export-Csv $reportPath -NoTypeInformation
Write-Success "Report saved: $reportPath"

Write-Host "`nComplete!" -ForegroundColor Green
