# EnrichWithWowhead.ps1
# Uses Wowhead as a fallback to get region information for items that were partially validated

param(
    [Parameter(Mandatory=$false)]
    [string]$InputFile = "data\BlankDescriptions_Validated.json",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "data\BlankDescriptions_Enriched.json",
    
    [Parameter(Mandatory=$false)]
    [int]$DelayMs = 2000
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Enrich with Wowhead Region Data" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Read validated items
$items = Get-Content $InputFile -Raw | ConvertFrom-Json

Write-Host "Loaded $($items.Count) items" -ForegroundColor White

# Find items that need region enrichment
$needsEnrichment = $items | Where-Object { 
    ($_.Validated -eq $true -and [string]::IsNullOrEmpty($_.Region)) -or
    ($_.Validated -eq $false -and $_.CreatureId)
}

Write-Host "Found $($needsEnrichment.Count) items needing region enrichment`n" -ForegroundColor Yellow

if ($needsEnrichment.Count -eq 0) {
    Write-Host "✓ All items already have complete information!" -ForegroundColor Green
    return
}

$enriched = 0
$failed = 0

foreach ($item in $needsEnrichment) {
    Write-Host "[$($item.ItemId)] $($item.Name)" -ForegroundColor Cyan
    Write-Host "  Creature ID: $($item.CreatureId)" -ForegroundColor Gray
    
    try {
        $wowheadUrl = "https://www.wowhead.com/wotlk/npc=$($item.CreatureId)"
        Write-Host "  Fetching: $wowheadUrl" -ForegroundColor Gray
        
        # Note: We can't actually fetch the page due to CORS/JavaScript limitations
        # Instead, we'll use the fetch_webpage tool via the AI assistant
        # For now, mark these items as needing manual Wowhead lookup
        Write-Host "  ℹ Needs manual Wowhead lookup" -ForegroundColor Yellow
        Write-Host "    URL: $wowheadUrl" -ForegroundColor Gray
        
        # Skip automatic fetching - this will be done via fetch_webpage tool
        $region = $null
        
        if ($region) {
            # Clean up HTML entities
            $region = [System.Web.HttpUtility]::HtmlDecode($region)
            
            # Update the item
            if ([string]::IsNullOrEmpty($item.Region)) {
                $item.Region = $region
            }
            
            # Regenerate description if needed
            if ($item.DropsFrom) {
                $item.GeneratedDescription = "Has a chance to drop from $($item.DropsFrom) within $region"
                if ($item.Validated -eq $false) {
                    $item.Validated = $true
                }
                Write-Host "  ✅ Found region: $region" -ForegroundColor Green
                $enriched++
            } else {
                Write-Host "  ⚠ Found region but no creature name: $region" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ✗ Could not extract region from Wowhead" -ForegroundColor Red
            $failed++
        }
    }
    catch {
        Write-Host "  ✗ Error fetching Wowhead: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
    
    Start-Sleep -Milliseconds $DelayMs
    Write-Host ""
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Enrichment Results:" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "✓ Enriched with region data: $enriched" -ForegroundColor Green
Write-Host "✗ Failed to enrich: $failed" -ForegroundColor Red
Write-Host "======================================`n" -ForegroundColor Cyan

# Export results
$items | ConvertTo-Json -Depth 5 | Out-File $OutputFile -Encoding UTF8
Write-Host "Results exported to: $OutputFile" -ForegroundColor Cyan

# Fix Unicode escapes
Write-Host "Fixing Unicode escapes..." -ForegroundColor Yellow
$content = Get-Content $OutputFile -Raw
$content = $content -replace '\\u0027', "'"
$content = $content -replace "\\'", "'"
$content | Set-Content $OutputFile -Encoding UTF8 -NoNewline

Write-Host "✓ Unicode escapes fixed" -ForegroundColor Green
Write-Host ""

# Show enriched items
Write-Host "`nEnriched Items ($enriched):" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
$enrichedItems = $items | Where-Object { $_.Validated -eq $true -and $_.Region }
$enrichedItems | Select-Object -First 20 | ForEach-Object {
    Write-Host "[$($_.ItemId)] $($_.Name)" -ForegroundColor Yellow
    Write-Host "  → $($_.GeneratedDescription)" -ForegroundColor White
}

if ($enrichedItems.Count -gt 20) {
    Write-Host "  ... and $($enrichedItems.Count - 20) more" -ForegroundColor DarkGray
}

Write-Host ""
