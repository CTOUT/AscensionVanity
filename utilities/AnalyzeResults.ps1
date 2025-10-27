# Analyze API Dump Results
# This script analyzes the SavedVariables from in-game API dump and validation

param(
    [switch]$Detailed
)

# Import local configuration
$configPath = Join-Path $PSScriptRoot "local.config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Error "Local configuration not found. Please copy 'local.config.example.ps1' to 'local.config.ps1' and configure your paths."
    exit 1
}

Import-Module $configPath -Force
if (-not (Test-LocalConfig)) {
    exit 1
}

Write-Host "`n🔍 Analyzing API Dump Results" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Gray

# Check if SavedVariables file exists
if (-not (Test-Path $script:SavedVariablesPath)) {
    Write-Error "SavedVariables file not found: $script:SavedVariablesPath"
    Write-Host "`n💡 Make sure you've run the following in-game:" -ForegroundColor Yellow
    Write-Host "   1. /av apidump" -ForegroundColor White
    Write-Host "   2. /av validate" -ForegroundColor White
    Write-Host "   3. /reload" -ForegroundColor White
    exit 1
}

# Read the SavedVariables file
Write-Host "`n📖 Reading SavedVariables file..." -ForegroundColor Yellow
$content = Get-Content $script:SavedVariablesPath -Raw

# Parse basic stats
Write-Host "`n📊 Extracting Statistics..." -ForegroundColor Yellow

# Look for APIDump section
if ($content -match 'APIDump\s*=\s*{') {
    Write-Host "✅ APIDump data found" -ForegroundColor Green
    
    # Count items in APIDump (rough estimate)
    $apiDumpSection = $content -replace '(?s).*APIDump\s*=\s*{(.*?)}.*', '$1'
    $apiItemCount = ([regex]::Matches($apiDumpSection, '\[\d+\]')).Count
    Write-Host "   Estimated API items: $apiItemCount" -ForegroundColor Gray
} else {
    Write-Host "❌ APIDump data not found" -ForegroundColor Red
}

# Look for ValidationResults section
if ($content -match 'ValidationResults\s*=\s*{') {
    Write-Host "✅ ValidationResults data found" -ForegroundColor Green
    
    # Extract validation stats
    if ($content -match 'TotalAPI\s*=\s*(\d+)') {
        $totalAPI = $matches[1]
        Write-Host "   Total API Items: $totalAPI" -ForegroundColor Cyan
    }
    
    if ($content -match 'TotalDB\s*=\s*(\d+)') {
        $totalDB = $matches[1]
        Write-Host "   Total DB Items: $totalDB" -ForegroundColor Cyan
    }
    
    if ($content -match 'ExactMatches\s*=\s*(\d+)') {
        $exactMatches = $matches[1]
        Write-Host "   Exact Matches: $exactMatches" -ForegroundColor Green
    }
    
    if ($content -match 'MissingFromDB\s*=\s*(\d+)') {
        $missingFromDB = $matches[1]
        Write-Host "   Missing from DB: $missingFromDB" -ForegroundColor Yellow
    }
    
    if ($content -match 'Mismatches\s*=\s*(\d+)') {
        $mismatches = $matches[1]
        Write-Host "   Mismatches: $mismatches" -ForegroundColor Red
    }
} else {
    Write-Host "❌ ValidationResults data not found" -ForegroundColor Red
}

# Detailed analysis if requested
if ($Detailed) {
    Write-Host "`n📋 Detailed Analysis" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Gray
    
    # Extract missing items
    if ($content -match '(?s)MissingItems\s*=\s*{(.*?)}') {
        $missingSection = $matches[1]
        Write-Host "`n❌ Missing Items (sample):" -ForegroundColor Yellow
        
        $missingItems = [regex]::Matches($missingSection, '\[(\d+)\]\s*=\s*(\d+)')
        $count = 0
        foreach ($match in $missingItems) {
            if ($count -ge 10) { break }
            $creatureId = $match.Groups[1].Value
            $itemId = $match.Groups[2].Value
            Write-Host "   Creature $creatureId -> Item $itemId" -ForegroundColor Gray
            $count++
        }
        
        if ($missingItems.Count -gt 10) {
            Write-Host "   ... and $($missingItems.Count - 10) more" -ForegroundColor DarkGray
        }
    }
    
    # Extract mismatches
    if ($content -match '(?s)MismatchedItems\s*=\s*{(.*?)}') {
        $mismatchSection = $matches[1]
        Write-Host "`n⚠️  Mismatched Items (sample):" -ForegroundColor Yellow
        
        $mismatchItems = [regex]::Matches($mismatchSection, '\[(\d+)\]\s*=\s*{[^}]*APIItem\s*=\s*(\d+)[^}]*DBItem\s*=\s*(\d+)')
        $count = 0
        foreach ($match in $mismatchItems) {
            if ($count -ge 10) { break }
            $creatureId = $match.Groups[1].Value
            $apiItem = $match.Groups[2].Value
            $dbItem = $match.Groups[3].Value
            Write-Host "   Creature $creatureId -> API: $apiItem, DB: $dbItem" -ForegroundColor Gray
            $count++
        }
        
        if ($mismatchItems.Count -gt 10) {
            Write-Host "   ... and $($mismatchItems.Count - 10) more" -ForegroundColor DarkGray
        }
    }
}

Write-Host "`n✨ Analysis Complete!" -ForegroundColor Green
Write-Host "`n💡 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Review the numbers above" -ForegroundColor White
Write-Host "   2. Run with -Detailed flag for more info: .\AnalyzeResults.ps1 -Detailed" -ForegroundColor White
Write-Host "   3. Generate updated database if needed" -ForegroundColor White
Write-Host ""
