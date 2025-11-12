<#
.SYNOPSIS
    Consolidated Master Pipeline V2 - Complete database update workflow with modularity

.DESCRIPTION
    A modern, modular approach to the database pipeline that:
    - Combines all steps into one executable script
    - Provides clear progress tracking and error handling
    - Validates prerequisites before each step
    - Creates comprehensive logs
    - Supports dry-run mode for testing
    - Automatically handles the critical "copy enriched data" step
    
    Pipeline Steps:
    1. Import fresh scan from SavedVariables or data folder
    2. Normalize descriptions (fix formatting)
    3. Enrich zone data (extract from descriptions)
    4. Apply enriched data (automatic copy)
    5. Generate VanityDB.lua with quest locks
    6. Optional: Deploy to WoW AddOns folder

.PARAMETER SavedVariablesPath
    Path to AscensionVanity.lua SavedVariables file. If omitted, auto-detects from data folder.

.PARAMETER WoWPath
    Path to WoW installation for automatic deployment. If omitted, skips deployment.

.PARAMETER SkipImport
    Skip Step 1 (use existing MasterFullValidated.json)

.PARAMETER SkipNormalize
    Skip Step 2 (use existing normalized descriptions)

.PARAMETER SkipEnrich
    Skip Step 3 (use existing zone enrichment)

.PARAMETER SkipDeploy
    Skip Step 6 (don't copy to WoW folder)

.PARAMETER DryRun
    Test mode - shows what would be done without making changes

.PARAMETER Verbose
    Show detailed progress information

.EXAMPLE
    .\utilities\MasterPipeline_V2.ps1
    Full pipeline with auto-detection

.EXAMPLE
    .\utilities\MasterPipeline_V2.ps1 -WoWPath "D:\OneDrive\Warcraft"
    Full pipeline with deployment

.EXAMPLE
    .\utilities\MasterPipeline_V2.ps1 -SkipImport -WoWPath "D:\OneDrive\Warcraft"
    Quick regeneration from existing data

.EXAMPLE
    .\utilities\MasterPipeline_V2.ps1 -DryRun
    Test mode - no changes made

.NOTES
    Author: CMTout & GitHub Copilot
    Version: 2.0
    Last Updated: 2025-11-07
    
    DESIGN IMPROVEMENTS:
    - All-in-one execution (no need to run multiple scripts)
    - Automatic prerequisite validation
    - Better error messages with suggestions
    - Progress tracking with visual indicators
    - Comprehensive logging to file
    - Handles the critical "copy enriched" step automatically
#>

[CmdletBinding()]
param(
    [string]$SavedVariablesPath,
    [string]$WoWPath,
    [switch]$SkipImport,
    [switch]$SkipNormalize,
    [switch]$SkipEnrich,
    [switch]$SkipDeploy,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$script:LogFile = $null
$script:StartTime = Get-Date

# ============================================================================
# LOGGING & UI HELPERS
# ============================================================================

function Write-Header {
    param([string]$Text)
    $border = "=" * 80
    Write-Host ""
    Write-Host $border -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host $border -ForegroundColor Cyan
    Write-Host ""
    Log "=== $Text ==="
}

function Write-Step {
    param([string]$Number, [string]$Text)
    Write-Host ""
    Write-Host "[$Number] " -ForegroundColor Yellow -NoNewline
    Write-Host $Text -ForegroundColor White
    Log "[$Number] $Text"
}

function Write-Success {
    param([string]$Text)
    Write-Host "  ✓ " -ForegroundColor Green -NoNewline
    Write-Host $Text -ForegroundColor White
    Log "✓ $Text"
}

function Write-Info {
    param([string]$Text)
    Write-Host "  → " -ForegroundColor Gray -NoNewline
    Write-Host $Text -ForegroundColor Gray
    Log "→ $Text"
}

function Write-Warning {
    param([string]$Text)
    Write-Host "  ⚠ " -ForegroundColor Yellow -NoNewline
    Write-Host $Text -ForegroundColor Yellow
    Log "⚠ $Text"
}

function Write-Error {
    param([string]$Text)
    Write-Host "  ✗ " -ForegroundColor Red -NoNewline
    Write-Host $Text -ForegroundColor Red
    Log "✗ $Text"
}

function Log {
    param([string]$Message)
    if ($script:LogFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $script:LogFile -Value "[$timestamp] $Message"
    }
}

function Test-FileExists {
    param([string]$Path, [string]$Description)
    if (Test-Path $Path) {
        $size = (Get-Item $Path).Length
        $sizeKB = [math]::Round($size / 1KB, 1)
        Write-Success "$Description exists ($sizeKB KB)"
        return $true
    } else {
        Write-Error "$Description not found: $Path"
        return $false
    }
}

# ============================================================================
# PREREQUISITE VALIDATION
# ============================================================================

function Test-Prerequisites {
    Write-Step "0" "Validating Prerequisites"
    
    $allGood = $true
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 5) {
        Write-Success "PowerShell $($psVersion.Major).$($psVersion.Minor)"
    } else {
        Write-Error "PowerShell 5.1+ required (found $psVersion)"
        $allGood = $false
    }
    
    # Check key directories
    $dataPath = Join-Path $PSScriptRoot '..\data'
    if (Test-Path $dataPath) {
        Write-Success "Data directory exists"
    } else {
        Write-Error "Data directory not found: $dataPath"
        $allGood = $false
    }
    
    # Check required data files
    $requiredFiles = @(
        @{Path = "$dataPath\ZoneMappings.json"; Desc = "Zone mappings"},
        @{Path = "$dataPath\QuestLockedNPCs.json"; Desc = "Quest-locked NPCs"},
        @{Path = "$dataPath\API_to_GameID_Mapping.json"; Desc = "API to Game ID mapping"}
    )
    
    foreach ($file in $requiredFiles) {
        if (-not (Test-FileExists $file.Path $file.Desc)) {
            $allGood = $false
        }
    }
    
    if (-not $allGood) {
        throw "Prerequisites not met. Please resolve the errors above."
    }
    
    Write-Success "All prerequisites validated"
}

# ============================================================================
# STEP 1: IMPORT FRESH SCAN
# ============================================================================

function Invoke-ImportStep {
    param([string]$SavedVariablesPath)
    
    Write-Step "1" "Import Fresh Scan"
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would import scan"
        return
    }
    
    # Auto-detect scan if not provided
    if (-not $SavedVariablesPath) {
        $dataFolder = Join-Path $PSScriptRoot '..\data'
        $scanFile = Get-ChildItem "$dataFolder\AscensionVanity*.lua" | 
                    Where-Object { $_.Name -notlike "*_backup*" -and $_.Name -notlike "*Fresh_Scan*" } | 
                    Sort-Object LastWriteTime -Descending | 
                    Select-Object -First 1
        
        if ($scanFile) {
            $SavedVariablesPath = $scanFile.FullName
            Write-Info "Auto-detected scan: $($scanFile.Name)"
        } else {
            throw "No scan file found in data folder. Please provide -SavedVariablesPath or place AscensionVanity.lua in data folder."
        }
    }
    
    Write-Info "Running MasterAPIDumpImport.ps1..."
    & "$PSScriptRoot\MasterAPIDumpImport.ps1" -SavedVariablesPath $SavedVariablesPath
    
    # Validate output file instead of exit code
    $masterJson = Join-Path $PSScriptRoot '..\data\MasterFullValidated.json'
    if (-not (Test-FileExists $masterJson "MasterFullValidated.json")) {
        throw "Import did not produce expected output file"
    }
    
    # Show item count
    $data = Get-Content $masterJson -Raw | ConvertFrom-Json
    Write-Success "Imported $($data.Count) items"
}

# ============================================================================
# STEP 2: NORMALIZE DESCRIPTIONS
# ============================================================================

function Invoke-NormalizeStep {
    Write-Step "2" "Normalize Descriptions"
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would normalize descriptions"
        return
    }
    
    Write-Info "Running NormalizeDescriptions.ps1..."
    & "$PSScriptRoot\NormalizeDescriptions.ps1"
    
    # Note: Script may not set LASTEXITCODE explicitly, check for output file instead
    $masterJson = Join-Path $PSScriptRoot '..\data\MasterFullValidated.json'
    if (-not (Test-Path $masterJson)) {
        throw "Normalization failed - MasterFullValidated.json not found"
    }
    
    Write-Success "Descriptions normalized"
}

# ============================================================================
# STEP 3: ENRICH ZONE DATA
# ============================================================================

function Invoke-EnrichStep {
    Write-Step "3" "Enrich Zone Data"
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would enrich zone data"
        return
    }
    
    Write-Info "Running EnrichZoneData.ps1..."
    & "$PSScriptRoot\EnrichZoneData.ps1"
    
    # Check for enriched output file instead of exit code
    $enrichedJson = Join-Path $PSScriptRoot '..\data\MasterFullValidated_ZoneEnriched.json'
    if (-not (Test-FileExists $enrichedJson "Zone-enriched JSON")) {
        throw "Enrichment did not produce expected output file"
    }
    
    # Show zone coverage
    $data = Get-Content $enrichedJson -Raw | ConvertFrom-Json
    $withZone = ($data | Where-Object { $_.zone }).Count
    $coverage = [math]::Round(($withZone / $data.Count) * 100, 1)
    Write-Success "Zone data enriched: $withZone / $($data.Count) items ($coverage%)"
    
    # CRITICAL: Copy enriched data back to master file
    Write-Info "Applying enriched data to master file..."
    $masterJson = Join-Path $PSScriptRoot '..\data\MasterFullValidated.json'
    Copy-Item $enrichedJson $masterJson -Force
    Write-Success "Enriched data applied to MasterFullValidated.json"
}

# ============================================================================
# STEP 4: GENERATE VANITYDB.LUA
# ============================================================================

function Invoke-GenerateStep {
    Write-Step "4" "Generate VanityDB.lua (to temp location)"
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would generate VanityDB.lua"
        return
    }
    
    # Generate to temporary location first
    $tempVanityDB = Join-Path $PSScriptRoot '..\data\VanityDB_NEW.lua'
    Write-Info "Generating to temporary location: $tempVanityDB"
    & "$PSScriptRoot\GenerateVanityDB_Master.ps1" -OutputDB $tempVanityDB
    
    # Validate output file
    if (-not (Test-FileExists $tempVanityDB "VanityDB_NEW.lua")) {
        throw "Generation did not produce expected output file"
    }
    
    # Check for zone data in output
    $content = Get-Content $tempVanityDB -Raw
    if ($content -match 'zone\s*=\s*"') {
        Write-Success "VanityDB.lua generated with zone data"
    } else {
        Write-Warning "VanityDB.lua may be missing zone data!"
    }
}

# ============================================================================
# STEP 5: VALIDATE & DEPLOY VANITYDB.LUA
# ============================================================================

function Invoke-ValidateStep {
    Write-Step "5" "Validate & Deploy VanityDB.lua"
    
    $deployedDB = Join-Path $PSScriptRoot '..\AscensionVanity\VanityDB.lua'
    $newDB = Join-Path $PSScriptRoot '..\data\VanityDB_NEW.lua'
    
    # Check if we have an old version to compare against
    if (-not (Test-Path $deployedDB)) {
        Write-Warning "No existing VanityDB.lua found - deploying without validation (first-time generation)"
        if (-not $DryRun) {
            Copy-Item $newDB $deployedDB -Force
            Write-Success "VanityDB.lua deployed"
        }
        return
    }
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would validate and deploy VanityDB.lua"
        return
    }
    
    Write-Info "Comparing new version against deployed version..."
    Write-Info "This ensures data quality before deployment"
    Write-Host ""
    
    # Run validation script
    $validateScript = Join-Path $PSScriptRoot 'ValidateVanityDB.ps1'
    & $validateScript -OldDB $deployedDB -NewDB $newDB
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Validation PASSED - deploying new VanityDB.lua"
        Copy-Item $newDB $deployedDB -Force
        Write-Success "VanityDB.lua deployed to: $deployedDB"
    } elseif ($LASTEXITCODE -eq 2) {
        Write-Warning "Validation passed with WARNINGS - review above before proceeding"
        
        # Prompt user
        Write-Host ""
        $response = Read-Host "Deploy anyway? (Y/n)"
        if ($response -eq 'n' -or $response -eq 'N') {
            Write-Host "New VanityDB.lua saved to: $newDB" -ForegroundColor Yellow
            Write-Host "To deploy manually: Copy-Item '$newDB' '$deployedDB' -Force" -ForegroundColor Gray
            throw "Deployment cancelled by user"
        }
        # User said yes - deploy
        Copy-Item $newDB $deployedDB -Force
        Write-Success "VanityDB.lua deployed to: $deployedDB"
    } else {
        Write-Error "Validation FAILED - deployment blocked"
        Write-Host "New VanityDB.lua saved to: $newDB" -ForegroundColor Yellow
        Write-Host "Review the validation report above and fix issues before deploying" -ForegroundColor Yellow
        throw "Validation failed - deployment blocked"
    }
    
    Write-Host ""
}

# ============================================================================
# STEP 6: DEPLOY TO WOW
# ============================================================================

function Invoke-DeployStep {
    param([string]$WoWPath)
    
    if ($SkipDeploy -or -not $WoWPath) {
        Write-Step "6" "Deploy to WoW - SKIPPED"
        return
    }
    
    Write-Step "6" "Deploy to WoW"
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would deploy to: $WoWPath"
        return
    }
    
    Write-Info "Running DeployAddon.ps1..."
    & "$PSScriptRoot\..\DeployAddon.ps1" -WoWPath $WoWPath
    
    # Check if addon files were copied
    $targetPath = Join-Path $WoWPath "AscensionVanity\VanityDB.lua"
    if (-not (Test-Path $targetPath)) {
        throw "Deployment failed - VanityDB.lua not found in target folder"
    }
    
    Write-Success "Addon deployed to $WoWPath"
}

# ============================================================================
# MAIN PIPELINE EXECUTION
# ============================================================================

try {
    # Setup logging
    $logDir = Join-Path $PSScriptRoot '..\logs'
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $script:LogFile = Join-Path $logDir "Pipeline_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"
    
    Write-Header "AscensionVanity Master Pipeline V2"
    
    if ($DryRun) {
        Write-Host "  [DRY RUN MODE] No changes will be made" -ForegroundColor Yellow
        Write-Host ""
    }
    
    Log "Pipeline started"
    Log "Parameters: SavedVariablesPath=$SavedVariablesPath, WoWPath=$WoWPath, SkipImport=$SkipImport, SkipNormalize=$SkipNormalize, SkipEnrich=$SkipEnrich, SkipDeploy=$SkipDeploy, DryRun=$DryRun"
    
    # Step 0: Prerequisites
    Test-Prerequisites
    
    # Step 1: Import
    if (-not $SkipImport) {
        Invoke-ImportStep -SavedVariablesPath $SavedVariablesPath
    } else {
        Write-Step "1" "Import Fresh Scan - SKIPPED"
        Write-Info "Using existing MasterFullValidated.json"
    }
    
    # Step 2: Normalize
    if (-not $SkipNormalize) {
        Invoke-NormalizeStep
    } else {
        Write-Step "2" "Normalize Descriptions - SKIPPED"
    }
    
    # Step 3: Enrich
    if (-not $SkipEnrich) {
        Invoke-EnrichStep
    } else {
        Write-Step "3" "Enrich Zone Data - SKIPPED"
        Write-Warning "Make sure MasterFullValidated.json has zone data!"
    }
    
    # Step 4: Generate
    Invoke-GenerateStep
    
    # Step 5: Validate
    Invoke-ValidateStep
    
    # Step 6: Deploy (optional)
    Invoke-DeployStep -WoWPath $WoWPath
    
    # Summary
    Write-Header "Pipeline Complete!"
    
    $elapsed = (Get-Date) - $script:StartTime
    Write-Success "Total time: $($elapsed.Minutes)m $($elapsed.Seconds)s"
    Write-Info "Log file: $script:LogFile"
    
    if (-not $DryRun) {
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        if ($WoWPath) {
            Write-Host "  1. Launch World of Warcraft" -ForegroundColor White
            Write-Host "  2. Type: /reload" -ForegroundColor White
            Write-Host "  3. Test: /avanity browser" -ForegroundColor White
        } else {
            Write-Host "  1. Deploy: .\DeployAddon.ps1 -WoWPath 'D:\OneDrive\Warcraft'" -ForegroundColor White
            Write-Host "  2. Launch WoW and /reload" -ForegroundColor White
        }
        Write-Host ""
    }
    
    Log "Pipeline completed successfully"
    
} catch {
    Write-Header "Pipeline Failed!"
    Write-Error $_.Exception.Message
    Log "Pipeline failed: $($_.Exception.Message)"
    Log $_.ScriptStackTrace
    
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check log file: $script:LogFile" -ForegroundColor White
    Write-Host "  2. Review error message above" -ForegroundColor White
    Write-Host "  3. Try running failed step manually" -ForegroundColor White
    Write-Host "  4. See: docs\DATABASE_PIPELINE_VALIDATION.md" -ForegroundColor White
    Write-Host ""
    
    exit 1
}
