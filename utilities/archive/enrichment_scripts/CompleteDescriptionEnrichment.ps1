# Complete Description Enrichment Script
# Combines db.ascension.gg and Wowhead WOTLK lookups to enrich remaining blank descriptions

param(
    [Parameter(Mandatory=$false)]
    [string]$ValidatedFile = "data\BlankDescriptions_Validated.json",
    
    [Parameter(Mandatory=$false)]
    [int]$RateLimitSeconds = 2
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Complete Description Enrichment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Load validated items
$validatedItems = Get-Content $ValidatedFile -Raw | ConvertFrom-Json

# Filter to items needing enrichment:
# 1. Validated: true but Region: null (have DropsFrom, need region)
# 2. Validated: false (need full lookup)
$itemsNeedingEnrichment = $validatedItems | Where-Object { 
    ($_.Validated -eq $true -and -not $_.Region) -or 
    ($_.Validated -eq $false -and -not $_.GeneratedDescription)
}

Write-Host "Found $($itemsNeedingEnrichment.Count) items needing enrichment" -ForegroundColor Yellow
Write-Host ""

$enriched = 0
$failed = 0
$skipped = 0

foreach ($item in $itemsNeedingEnrichment) {
    $itemId = $item.ItemId
    $creatureId = $item.CreatureId
    $name = $item.Name
    
    Write-Host "Processing [$itemId] $name" -ForegroundColor Cyan
    Write-Host "  Creature ID: $creatureId" -ForegroundColor Gray
    
    $region = $null
    $dropsFrom = $item.DropsFrom
    
    # Strategy 1: If we already have DropsFrom, just need region from Wowhead WOTLK
    if ($dropsFrom) {
        Write-Host "  Strategy: Lookup region from Wowhead WOTLK" -ForegroundColor Gray
        
        try {
            # Use WOTLK-specific URL
            $wowheadUrl = "https://www.wowhead.com/wotlk/npc=$creatureId"
            Write-Host "  URL: $wowheadUrl" -ForegroundColor DarkGray
            
            $response = Invoke-WebRequest -Uri $wowheadUrl -UseBasicParsing -TimeoutSec 10
            $content = $response.Content
            
            # Try multiple patterns to extract zone/dungeon name
            $patterns = @(
                # Pattern 1: JavaScript onclick with zone name - MOST COMMON ON WOWHEAD WOTLK
                'WH\.setSelectedLink[^>]*>([^<]+)</a>',
                # Pattern 2: Direct link tag
                'This NPC can be found in\s+<a[^>]*>([^<]+)</a>',
                # Pattern 3: Plain text after "found in"
                'This NPC can be found in\s+([A-Z][^<\.\(]{2,}?)(?=\s*[\.<]|$)',
                # Pattern 4: Infobox location
                '<th>Location</th>\s*<td[^>]*>\s*<a[^>]*>([^<]+)</a>'
            )
            
            $foundRegion = $false
            foreach ($pattern in $patterns) {
                if ($content -match $pattern) {
                    $region = $matches[1].Trim()
                    
                    # Validate - skip if we captured HTML tags or invalid content
                    if ($region -notmatch '<|>|span id=|script|style' -and $region.Length -gt 2) {
                        Write-Host "  ✓ Found location: $region" -ForegroundColor Green
                        
                        # Update item with region
                        $item.Region = $region
                        $item.GeneratedDescription = "Has a chance to drop from $dropsFrom within $region"
                        $enriched++
                        $foundRegion = $true
                        break
                    }
                }
            }
            
            if (-not $foundRegion) {
                Write-Host "  ⚠ No region found on Wowhead - keeping description without region" -ForegroundColor Yellow
                # Keep the description without region
                $item.GeneratedDescription = "Has a chance to drop from $dropsFrom"
                $enriched++
            }
        }
        catch {
            Write-Host "  ✗ Wowhead lookup failed: $($_.Exception.Message)" -ForegroundColor Red
            # Keep existing DropsFrom, just no region
            $item.GeneratedDescription = "Has a chance to drop from $dropsFrom"
            $failed++
        }
    }
    # Strategy 2: No DropsFrom yet - try db.ascension.gg first
    else {
        Write-Host "  Strategy: Full lookup from db.ascension.gg" -ForegroundColor Gray
        
        $foundOnAscension = $false
        
        try {
            $ascensionUrl = "https://db.ascension.gg/item/$itemId"
            Write-Host "  URL: $ascensionUrl" -ForegroundColor DarkGray
            
            $response = Invoke-WebRequest -Uri $ascensionUrl -UseBasicParsing -TimeoutSec 10
            $content = $response.Content
            
            # Look for drop information
            if ($content -match '<div class="listview-row[^"]*"[^>]*>.*?<a[^>]*>([^<]+)</a>.*?<small[^>]*>([^<]+)</small>') {
                $dropsFrom = $matches[1]
                $region = $matches[2]
                
                Write-Host "  ✓ Found: $dropsFrom in $region" -ForegroundColor Green
                
                $item.Validated = $true
                $item.DropsFrom = $dropsFrom
                $item.Region = $region
                $item.GeneratedDescription = "Has a chance to drop from $dropsFrom within $region"
                $enriched++
                $foundOnAscension = $true
            }
        }
        catch {
            Write-Host "  ⚠ Item not found on db.ascension.gg" -ForegroundColor Yellow
        }
        
        # Fallback: If item not found on db.ascension.gg, try Wowhead WOTLK directly
        if (-not $foundOnAscension -and $creatureId) {
            Write-Host "  Fallback: Looking up creature on Wowhead WOTLK" -ForegroundColor Gray
            
            try {
                $wowheadUrl = "https://www.wowhead.com/wotlk/npc=$creatureId"
                Write-Host "  URL: $wowheadUrl" -ForegroundColor DarkGray
                
                $whResponse = Invoke-WebRequest -Uri $wowheadUrl -UseBasicParsing -TimeoutSec 10
                $whContent = $whResponse.Content
                
                # Extract creature name from page title
                $creatureName = $null
                if ($whContent -match '<title>([^-]+)\s*-\s*NPC') {
                    $creatureName = $matches[1].Trim()
                }
                
                # Extract location
                $region = $null
                $wowheadPatterns = @(
                    # Pattern 1: JavaScript onclick with zone name - MOST COMMON
                    'WH\.setSelectedLink[^>]*>([^<]+)</a>',
                    # Pattern 2: Direct link tag
                    'This NPC can be found in\s+<a[^>]*>([^<]+)</a>',
                    # Pattern 3: Plain text
                    'This NPC can be found in\s+([A-Z][^<\.\(]{2,}?)(?=\s*[\.<]|$)',
                    # Pattern 4: Infobox
                    '<th>Location</th>\s*<td[^>]*>\s*<a[^>]*>([^<]+)</a>'
                )
                
                foreach ($pattern in $wowheadPatterns) {
                    if ($whContent -match $pattern) {
                        $region = $matches[1].Trim()
                        if ($region -notmatch '<|>|span id=|script|style' -and $region.Length -gt 2) {
                            Write-Host "  ✓ Found on Wowhead: $creatureName in $region" -ForegroundColor Green
                            
                            $item.Validated = $true
                            $item.DropsFrom = $creatureName
                            $item.Region = $region
                            $item.GeneratedDescription = "Has a chance to drop from $creatureName within $region"
                            $enriched++
                            $foundOnAscension = $true
                            break
                        }
                    }
                }
                
                # If we found creature name but no location
                if (-not $foundOnAscension -and $creatureName) {
                    Write-Host "  ℹ Found creature name only: $creatureName" -ForegroundColor Cyan
                    $item.Validated = $true
                    $item.DropsFrom = $creatureName
                    $item.Region = $null
                    $item.GeneratedDescription = "Has a chance to drop from $creatureName"
                    $enriched++
                }
                elseif (-not $foundOnAscension) {
                    Write-Host "  ✗ Could not extract creature information from Wowhead" -ForegroundColor Red
                    $failed++
                }
            }
            catch {
                Write-Host "  ✗ Wowhead lookup failed: $($_.Exception.Message)" -ForegroundColor Red
                $failed++
            }
        }
        elseif (-not $foundOnAscension) {
            Write-Host "  ⚠ No creature ID available for fallback lookup" -ForegroundColor Yellow
            $item.Validated = $true
            $item.GeneratedDescription = "Not a drop-based item"
            $skipped++
        }
    }
    
    # Rate limiting
    Write-Host ""
    Start-Sleep -Seconds $RateLimitSeconds
}

# Save updated validated items
$validatedItems | ConvertTo-Json -Depth 10 | Set-Content $ValidatedFile -Encoding UTF8

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Enrichment Results:" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ Enriched: $enriched items" -ForegroundColor Green
Write-Host "⚠ Skipped (not drops): $skipped items" -ForegroundColor Yellow
Write-Host "✗ Failed: $failed items" -ForegroundColor Red
Write-Host "========================================`n" -ForegroundColor Cyan

# Show summary of what needs to be applied
$readyToApply = $validatedItems | Where-Object { 
    $_.GeneratedDescription -and $_.GeneratedDescription -ne "Not a drop-based item" 
}

Write-Host "Ready to apply: $($readyToApply.Count) descriptions" -ForegroundColor Green
Write-Host ""
Write-Host "Next step: Run .\utilities\ApplyValidatedDescriptions.ps1" -ForegroundColor Yellow
Write-Host ""
