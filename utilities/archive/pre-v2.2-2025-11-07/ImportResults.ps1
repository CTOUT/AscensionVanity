# Import API Dump Results
# Copies SavedVariables to workspace for analysis

# Import local configuration
$configPath = Join-Path $PSScriptRoot "local.config.ps1"
if (-not (Test-Path $configPath)) {
    Write-Error "Local configuration not found. Please copy 'local.config.example.ps1' to 'local.config.ps1' and configure your paths."
    exit 1
}

. $configPath

Write-Host "`n📥 Importing API Dump Results" -ForegroundColor Cyan
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

# Create data directory if it doesn't exist
$dataDir = Join-Path $PSScriptRoot "data"
if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir | Out-Null
}

# Copy SavedVariables to workspace
$destPath = Join-Path $dataDir "AscensionVanity_SavedVariables.lua"
Write-Host "📋 Copying SavedVariables to workspace..." -ForegroundColor Yellow
Write-Host "   From: $script:SavedVariablesPath" -ForegroundColor Gray
Write-Host "   To: $destPath" -ForegroundColor Gray

Copy-Item -Path $script:SavedVariablesPath -Destination $destPath -Force

Write-Host "`n✅ SavedVariables imported successfully!" -ForegroundColor Green
Write-Host "`n📄 File Location: $destPath" -ForegroundColor Cyan

# Quick preview
Write-Host "`n📊 Quick Preview:" -ForegroundColor Yellow
$content = Get-Content $destPath -Raw

# Extract basic stats
if ($content -match 'ValidationResults\s*=\s*{') {
    Write-Host "✅ Found ValidationResults" -ForegroundColor Green
    
    if ($content -match 'TotalAPI\s*=\s*(\d+)') {
        Write-Host "   Total API Items: $($matches[1])" -ForegroundColor Cyan
    }
    
    if ($content -match 'TotalDB\s*=\s*(\d+)') {
        Write-Host "   Total DB Items: $($matches[1])" -ForegroundColor Cyan
    }
    
    if ($content -match 'ExactMatches\s*=\s*(\d+)') {
        Write-Host "   Exact Matches: $($matches[1])" -ForegroundColor Green
    }
    
    if ($content -match 'MissingFromDB\s*=\s*(\d+)') {
        Write-Host "   Missing from DB: $($matches[1])" -ForegroundColor Yellow
    }
    
    if ($content -match 'Mismatches\s*=\s*(\d+)') {
        Write-Host "   Mismatches: $($matches[1])" -ForegroundColor Red
    }
}

Write-Host "`n💡 Next: Run .\AnalyzeResults.ps1 -Detailed for full analysis" -ForegroundColor Yellow
Write-Host ""
