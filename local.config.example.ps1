# Local Configuration Example
# Copy this file to 'local.config.ps1' and update with your actual paths
# local.config.ps1 is gitignored and will not be committed to the repository

# =============================================================================
# SYSTEM-SPECIFIC PATHS - UPDATE THESE FOR YOUR INSTALLATION
# =============================================================================

# Ascension WoW Installation
$script:AscensionPath = "D:\PATH\TO\Ascension Launcher\resources\client"

# WoW Account Name (used in SavedVariables path)
$script:AccountName = "your-email@example.com"

# Derived Paths (automatically constructed from above)
$script:SavedVariablesPath = Join-Path $AscensionPath "WTF\Account\$AccountName\SavedVariables\AscensionVanity.lua"
$script:ScreenshotsPath = Join-Path $AscensionPath "Screenshots"
$script:AddOnsPath = Join-Path $AscensionPath "Interface\AddOns\AscensionVanity"

# =============================================================================
# OPTIONAL: Additional Configuration
# =============================================================================

# Backup locations (optional)
$script:BackupPath = "D:\PATH\TO\Backups\AscensionVanity"

# =============================================================================
# VALIDATION (DO NOT MODIFY)
# =============================================================================

function Test-LocalConfig {
    $errors = @()
    
    if (-not (Test-Path $script:AscensionPath)) {
        $errors += "AscensionPath does not exist: $($script:AscensionPath)"
    }
    
    if (-not (Test-Path $script:SavedVariablesPath)) {
        Write-Warning "SavedVariables file not found (may not exist yet): $($script:SavedVariablesPath)"
    }
    
    if ($errors.Count -gt 0) {
        Write-Error "Local configuration validation failed:`n$($errors -join "`n")"
        return $false
    }
    
    Write-Host "✅ Local configuration validated successfully" -ForegroundColor Green
    return $true
}

# Export configuration for scripts to use
Export-ModuleMember -Variable @(
    'AscensionPath',
    'AccountName', 
    'SavedVariablesPath',
    'ScreenshotsPath',
    'AddOnsPath',
    'BackupPath'
) -Function 'Test-LocalConfig'
