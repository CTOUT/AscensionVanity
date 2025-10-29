# Test Wowhead Pattern Matching
# Debug script to understand the HTML structure

$testCases = @(
    @{ NpcId = 10375; Name = "Spire Spiderling"; ExpectedZone = "Blackrock Spire" },
    @{ NpcId = 10376; Name = "Crystal Fang"; ExpectedZone = "Blackrock Spire" }
)

foreach ($test in $testCases) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Testing: $($test.Name) (NPC $($test.NpcId))" -ForegroundColor Cyan
    Write-Host "Expected: $($test.ExpectedZone)" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan
    
    $url = "https://www.wowhead.com/wotlk/npc=$($test.NpcId)"
    
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
        $content = $response.Content
        
        Write-Host "Content retrieved: $($content.Length) bytes" -ForegroundColor Gray
        
        # Try multiple patterns
        $patterns = @(
            @{ Name = "Pattern 1: Link tag"; Regex = 'This NPC can be found in\s+<a[^>]*>([^<]+)</a>' },
            @{ Name = "Pattern 2: Plain text"; Regex = 'This NPC can be found in\s+([^<\.]+)' },
            @{ Name = "Pattern 3: Any text after"; Regex = 'This NPC can be found in\s+(.+?)[\.<]' },
            @{ Name = "Pattern 4: Infobox location"; Regex = 'infobox-title">Location</div>.*?<a[^>]*>([^<]+)</a>' }
        )
        
        $found = $false
        foreach ($pattern in $patterns) {
            if ($content -match $pattern.Regex) {
                Write-Host "  ✓ $($pattern.Name) MATCHED!" -ForegroundColor Green
                Write-Host "    Zone: $($matches[1])" -ForegroundColor Yellow
                $found = $true
                break
            }
        }
        
        if (-not $found) {
            Write-Host "  ✗ No patterns matched" -ForegroundColor Red
            
            # Show snippet if the text exists
            if ($content -match 'This NPC can be found in') {
                $index = $content.IndexOf("This NPC can be found in")
                $start = [Math]::Max(0, $index - 50)
                $length = [Math]::Min(250, $content.Length - $start)
                $snippet = $content.Substring($start, $length)
                
                Write-Host "`n  Raw HTML snippet:" -ForegroundColor Yellow
                Write-Host "  $snippet" -ForegroundColor White
            } else {
                Write-Host "  Text 'This NPC can be found in' not found in content" -ForegroundColor Red
            }
        }
        
    } catch {
        Write-Host "  ERROR: $_" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 2
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Complete" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
