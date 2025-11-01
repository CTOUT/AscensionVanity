# AnalyzeAPIDump.ps1
# Analyzes the API dump from SavedVariables and generates comparison reports

param(
    [Parameter(Mandatory=$false)]
    [string]$SavedVariablesPath,
    
    [Parameter(Mandatory=$false)]
    [switch]$Detailed,
    
    [Parameter(Mandatory=$false)]
    [string]$ExportPath = "$PSScriptRoot\..\API_Analysis"
)

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  AscensionVanity - API Dump Analyzer" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Function to detect WoW installation path from registry
function Get-WoWInstallPath {
    try {
        $regPath = "HKLM:\SOFTWARE\WOW6432Node\Blizzard Entertainment\World of Warcraft"
        if (Test-Path $regPath) {
            $installPath = (Get-ItemProperty -Path $regPath -Name "InstallPath" -ErrorAction SilentlyContinue).InstallPath
            if ($installPath -and (Test-Path $installPath)) {
                Write-Host "Detected WoW installation from registry: $installPath" -ForegroundColor Green
                return $installPath
            }
        }
    } catch {
        Write-Verbose "Registry detection failed: $_"
    }
    return $null
}

# Function to find SavedVariables file
function Find-SavedVariablesPath {
    param([string]$WoWPath)
    
    if (-not $WoWPath) { return $null }
    
    $wtfPath = Join-Path $WoWPath "WTF\Account"
    if (-not (Test-Path $wtfPath)) { return $null }
    
    # Search for any account folder with AscensionVanity.lua
    $accountFolders = Get-ChildItem -Path $wtfPath -Directory -ErrorAction SilentlyContinue
    foreach ($accountFolder in $accountFolders) {
        $savedVarsPath = Join-Path $accountFolder.FullName "SavedVariables\AscensionVanity.lua"
        if (Test-Path $savedVarsPath) {
            Write-Host "Found SavedVariables for account: $($accountFolder.Name)" -ForegroundColor Green
            return $savedVarsPath
        }
    }
    
    return $null
}

# Determine SavedVariables path
if (-not $SavedVariablesPath) {
    Write-Host "No path specified, attempting auto-detection..." -ForegroundColor Yellow
    
    # Try to import local.config.ps1 first
    $localConfigPath = Join-Path $PSScriptRoot "..\local.config.ps1"
    if (Test-Path $localConfigPath) {
        Write-Host "Loading configuration from local.config.ps1..." -ForegroundColor Cyan
        try {
            Import-Module $localConfigPath -ErrorAction Stop
            $SavedVariablesPath = $script:SavedVariablesPath
            Write-Host "Using path from local.config.ps1" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to load local.config.ps1: $_"
        }
    }
    
    # If not found, try registry detection
    if (-not $SavedVariablesPath) {
        Write-Host "Attempting registry-based detection..." -ForegroundColor Cyan
        $wowPath = Get-WoWInstallPath
        if ($wowPath) {
            $SavedVariablesPath = Find-SavedVariablesPath -WoWPath $wowPath
        }
    }
    
    # Final fallback: prompt user
    if (-not $SavedVariablesPath) {
        Write-Host ""
        Write-Host "ERROR: Could not auto-detect SavedVariables path!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please specify the path manually:" -ForegroundColor Yellow
        Write-Host "  .\utilities\AnalyzeAPIDump.ps1 -SavedVariablesPath '<YOUR_PATH>'" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Or create a local.config.ps1 file in the repository root." -ForegroundColor Yellow
        Write-Host "See local.config.example.ps1 for template." -ForegroundColor Yellow
        exit 1
    }
}

# Check if SavedVariables file exists
if (-not (Test-Path $SavedVariablesPath)) {
    Write-Host "ERROR: SavedVariables file not found!" -ForegroundColor Red
    Write-Host "Expected path: $SavedVariablesPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "  1. Run '/av apidump' in-game" -ForegroundColor Yellow
    Write-Host "  2. Type '/reload' to save the data" -ForegroundColor Yellow
    Write-Host "  3. Run this script again" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or specify the correct path:" -ForegroundColor Yellow
    Write-Host "  .\utilities\AnalyzeAPIDump.ps1 -SavedVariablesPath '<YOUR_PATH>'" -ForegroundColor Yellow
    exit 1
}

Write-Host "Reading SavedVariables from: $SavedVariablesPath" -ForegroundColor Green
$content = Get-Content $SavedVariablesPath -Raw

# Parse Lua table structure (simplified parser)
function Get-LuaTable {
    param([string]$Content, [string]$TableName)
    
    # Find the table
    $pattern = "$TableName\s*=\s*\{(.*?)\n\}"
    if ($Content -match $pattern) {
        return $Matches[1]
    }
    return $null
}

# Check if APIDump exists
if ($content -notmatch "APIDump\s*=\s*\{") {
    Write-Host "ERROR: No API dump found in SavedVariables!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run '/av apidump' in-game and then '/reload'" -ForegroundColor Yellow
    exit 1
}

Write-Host "API dump found in SavedVariables!" -ForegroundColor Green
Write-Host ""

# Extract basic statistics from the dump
$statsPattern = 'totalItems\s*=\s*(\d+)'
if ($content -match $statsPattern) {
    $totalItems = $Matches[1]
    Write-Host "Total items in API dump: $totalItems" -ForegroundColor Cyan
}

# Extract categories
Write-Host ""
Write-Host "Extracting category breakdown..." -ForegroundColor Cyan

$categoryPattern = '\["([^"]+)"\]\s*=\s*(\d+)'
$categories = [regex]::Matches($content, $categoryPattern) | Where-Object {
    $_.Groups[1].Value -match "Whistle|Vellum|Stone|Warhorn|Lodestone"
}

if ($categories.Count -gt 0) {
    Write-Host ""
    Write-Host "Categories found:" -ForegroundColor Yellow
    $categoryStats = @{}
    foreach ($match in $categories) {
        $catName = $match.Groups[1].Value
        $catCount = [int]$match.Groups[2].Value
        $categoryStats[$catName] = $catCount
        Write-Host ("  {0,-30}: {1,5} items" -f $catName, $catCount) -ForegroundColor Green
    }
}

# Create export directory
if (-not (Test-Path $ExportPath)) {
    New-Item -ItemType Directory -Path $ExportPath | Out-Null
    Write-Host ""
    Write-Host "Created export directory: $ExportPath" -ForegroundColor Green
}

# Export timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"

# Check for ValidationResults
if ($content -match "ValidationResults\s*=\s*\{") {
    Write-Host ""
    Write-Host "Validation results found!" -ForegroundColor Green
    
    # Extract validation stats
    $apiTotalPattern = 'apiTotal\s*=\s*(\d+)'
    $dbTotalPattern = 'dbTotal\s*=\s*(\d+)'
    $matchesPattern = 'matches\s*=\s*(\d+)'
    
    $apiTotal = if ($content -match $apiTotalPattern) { $Matches[1] } else { "N/A" }
    $dbTotal = if ($content -match $dbTotalPattern) { $Matches[1] } else { "N/A" }
    $matchCount = if ($content -match $matchesPattern) { $Matches[1] } else { "N/A" }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Validation Summary" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ("  API Total Items:      {0,6}" -f $apiTotal) -ForegroundColor Yellow
    Write-Host ("  Database Total Items: {0,6}" -f $dbTotal) -ForegroundColor Yellow
    Write-Host ("  Exact Matches:        {0,6}" -f $matchCount) -ForegroundColor Green
    
    if ($apiTotal -ne "N/A" -and $dbTotal -ne "N/A") {
        $diff = [int]$apiTotal - [int]$dbTotal
        $diffColor = if ($diff -eq 0) { "Green" } elseif ($diff -gt 0) { "Yellow" } else { "Red" }
        Write-Host ("  Difference:           {0,6}" -f $diff) -ForegroundColor $diffColor
        
        if ($diff -gt 0) {
            Write-Host ""
            Write-Host "  → API has $diff more items than our database" -ForegroundColor Yellow
            Write-Host "    These might be the missing 144 items!" -ForegroundColor Yellow
        } elseif ($diff -lt 0) {
            Write-Host ""
            Write-Host "  → Database has $([Math]::Abs($diff)) more items than API" -ForegroundColor Red
            Write-Host "    This suggests data quality issues!" -ForegroundColor Red
        }
    }
    
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
}

# Generate detailed report if requested
if ($Detailed) {
    Write-Host ""
    Write-Host "Generating detailed analysis reports..." -ForegroundColor Cyan
    
    # Export the raw Lua data for easier analysis
    $rawExport = "$ExportPath\APIDump_Raw_$timestamp.lua"
    $content | Out-File -FilePath $rawExport -Encoding UTF8
    Write-Host "  → Exported raw data to: $rawExport" -ForegroundColor Green
    
    # Create a summary report
    $reportPath = "$ExportPath\Analysis_Report_$timestamp.md"
    $report = @"
# AscensionVanity API Analysis Report
**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary Statistics

- **API Total Items**: $apiTotal
- **Database Total Items**: $dbTotal
- **Exact Matches**: $matchCount
- **Difference**: $($apiTotal - $dbTotal)

## Category Breakdown

$(if ($categoryStats.Count -gt 0) {
    $categoryStats.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
        "- **$($_.Key)**: $($_.Value) items"
    }
} else {
    "No category data available"
})

## Next Steps

1. Review the SavedVariables file for detailed item mappings
2. Compare API items vs database items to find discrepancies
3. Investigate missing items (API items not in database)
4. Verify mismatched items (different item IDs for same creature)

## Files Generated

- Raw Lua dump: ``APIDump_Raw_$timestamp.lua``
- This report: ``Analysis_Report_$timestamp.md``

---
*Generated by AnalyzeAPIDump.ps1*
"@
    
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "  → Generated report: $reportPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Analysis complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review the validation results above" -ForegroundColor Yellow
Write-Host "  2. Check SavedVariables file for detailed item listings" -ForegroundColor Yellow
Write-Host "  3. Run with -Detailed flag for complete analysis reports" -ForegroundColor Yellow
Write-Host "  4. Use the exported data to update VanityDB.lua" -ForegroundColor Yellow
Write-Host ""
