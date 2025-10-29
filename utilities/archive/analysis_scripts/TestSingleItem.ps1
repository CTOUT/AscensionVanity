# Quick Single Item Test
# Test the pattern on just Spire Spiderling

$itemId = 80088
$creatureId = 10375
$name = "Beastmaster's Whistle: Spire Spiderling"
$dropsFrom = "Spire Spiderling"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing: $name" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Item ID: $itemId" -ForegroundColor Gray
Write-Host "Creature ID: $creatureId" -ForegroundColor Gray
Write-Host "Drops From: $dropsFrom" -ForegroundColor Gray
Write-Host ""

$wowheadUrl = "https://www.wowhead.com/wotlk/npc=$creatureId"
Write-Host "Fetching: $wowheadUrl" -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri $wowheadUrl -UseBasicParsing -TimeoutSec 10
    $content = $response.Content
    
    Write-Host "✓ Content retrieved: $($content.Length) bytes" -ForegroundColor Green
    Write-Host ""
    
    # Try multiple patterns
    $patterns = @(
        @{ Name = "Link tag"; Pattern = 'This NPC can be found in\s+<a[^>]*>([^<]+)</a>' },
        @{ Name = "Plain text"; Pattern = 'This NPC can be found in\s+([^<\.\(]+)' },
        @{ Name = "Infobox"; Pattern = '<div class="infobox-title">Location</div>.*?<a[^>]*>([^<]+)</a>' }
    )
    
    $foundRegion = $false
    Write-Host "Testing patterns..." -ForegroundColor Yellow
    
    foreach ($patternInfo in $patterns) {
        Write-Host "  Trying: $($patternInfo.Name)..." -ForegroundColor Gray
        
        if ($content -match $patternInfo.Pattern) {
            $region = $matches[1].Trim()
            
            # Validate the captured region
            if ($region -notmatch '<|>|span id=') {
                Write-Host "  ✓ MATCH! Region: '$region'" -ForegroundColor Green
                
                $description = "Has a chance to drop from $dropsFrom within $region"
                Write-Host ""
                Write-Host "Generated Description:" -ForegroundColor Cyan
                Write-Host "  $description" -ForegroundColor White
                
                $foundRegion = $true
                break
            } else {
                Write-Host "  ⚠ Matched but contains HTML: '$region'" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ✗ No match" -ForegroundColor DarkGray
        }
    }
    
    if (-not $foundRegion) {
        Write-Host ""
        Write-Host "✗ No region found with any pattern" -ForegroundColor Red
        Write-Host "  Fallback description: Has a chance to drop from $dropsFrom" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "✗ ERROR: $_" -ForegroundColor Red
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
