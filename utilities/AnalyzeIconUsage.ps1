# AnalyzeIconUsage.ps1
# Analyzes icon distribution in API data to determine optimization strategy

param(
    [string]$InputFile = "data\AscensionVanity.lua"
)

Write-Host "`n=== Analyzing Icon Usage in API Data ===" -ForegroundColor Cyan

$lines = Get-Content $InputFile
$inAPIDump = $false
$currentItem = @{}
$iconUsage = @{}
$categoryIcons = @{
    "Beastmaster's Whistle" = @{}
    "Blood Soaked Vellum" = @{}
    "Summoner's Stone" = @{}
    "Draconic Warhorn" = @{}
    "Elemental Lodestone" = @{}
}

foreach ($line in $lines) {
    if ($line -match '\["APIDump"\]') {
        $inAPIDump = $true
        continue
    }
    
    if ($inAPIDump) {
        # Capture name
        if ($line -match '^\s*\["name"\]\s*=\s*"([^"]+)"') {
            $currentItem.Name = $matches[1]
        }
        
        # Capture icon from rawData
        if ($line -match '^\s*\["icon"\]\s*=\s*"([^"]+)"') {
            $currentItem.Icon = $matches[1]
        }
        
        # Capture description to filter drops
        if ($line -match '^\s*\["description"\]\s*=\s*"([^"]*)"') {
            $currentItem.Description = $matches[1]
        }
        
        # End of item
        if ($line -match '^\s*\},\s*--\s*\[\d+\]') {
            if ($currentItem.Name -and $currentItem.Icon -and 
                $currentItem.Description -like "Has a chance to drop from*") {
                
                # Track overall icon usage
                if (-not $iconUsage.ContainsKey($currentItem.Icon)) {
                    $iconUsage[$currentItem.Icon] = 0
                }
                $iconUsage[$currentItem.Icon]++
                
                # Track per category
                foreach ($cat in $categoryIcons.Keys) {
                    if ($currentItem.Name -like "*$cat*") {
                        if (-not $categoryIcons[$cat].ContainsKey($currentItem.Icon)) {
                            $categoryIcons[$cat][$currentItem.Icon] = 0
                        }
                        $categoryIcons[$cat][$currentItem.Icon]++
                        break
                    }
                }
            }
            
            $currentItem = @{}
        }
        
        if ($line -match '^\}\s*$') {
            break
        }
    }
}

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    ICON USAGE ANALYSIS                           ║" -ForegroundColor Yellow -BackgroundColor DarkBlue
Write-Host "╠══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan

Write-Host "`nOVERALL ICON STATISTICS:" -ForegroundColor Cyan
Write-Host "  Total unique icons: $($iconUsage.Count)" -ForegroundColor Yellow
Write-Host "  Total items analyzed: $(($iconUsage.Values | Measure-Object -Sum).Sum)" -ForegroundColor Yellow

Write-Host "`nICON DISTRIBUTION:" -ForegroundColor Cyan
$sortedIcons = $iconUsage.GetEnumerator() | Sort-Object -Property Value -Descending
foreach ($icon in $sortedIcons) {
    $iconName = Split-Path $icon.Key -Leaf
    Write-Host "  $iconName : $($icon.Value) items" -ForegroundColor $(if ($icon.Value -gt 100) { "Green" } else { "Gray" })
}

Write-Host "`n`nPER-CATEGORY ICON ANALYSIS:" -ForegroundColor Cyan
foreach ($cat in $categoryIcons.Keys | Sort-Object) {
    $icons = $categoryIcons[$cat]
    if ($icons.Count -gt 0) {
        Write-Host "`n$cat :" -ForegroundColor Yellow
        Write-Host "  Unique icons: $($icons.Count)" -ForegroundColor White
        Write-Host "  Total items: $(($icons.Values | Measure-Object -Sum).Sum)" -ForegroundColor White
        
        if ($icons.Count -eq 1) {
            Write-Host "  ✅ SINGLE ICON - No indexing needed!" -ForegroundColor Green
            Write-Host "     Icon: $(($icons.Keys)[0])" -ForegroundColor Gray
        } else {
            Write-Host "  ⚠️  Multiple icons - Consider indexing" -ForegroundColor Yellow
            $topIcon = $icons.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1
            Write-Host "     Most common: $(Split-Path $topIcon.Key -Leaf) ($($topIcon.Value) items, $([math]::Round($topIcon.Value / (($icons.Values | Measure-Object -Sum).Sum) * 100, 1))%)" -ForegroundColor Gray
        }
    }
}

Write-Host "`n╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Export detailed results
$output = @{
    OverallStats = @{
        UniqueIcons = $iconUsage.Count
        TotalItems = ($iconUsage.Values | Measure-Object -Sum).Sum
    }
    IconUsage = $iconUsage
    CategoryBreakdown = $categoryIcons
}

$output | ConvertTo-Json -Depth 10 | Out-File "data\IconUsage_Analysis.json" -Encoding UTF8
Write-Host "`nDetailed results: data\IconUsage_Analysis.json`n" -ForegroundColor Cyan
