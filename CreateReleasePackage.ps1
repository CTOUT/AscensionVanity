# AscensionVanity v2.1-beta Release Package Creator
# Creates a clean ZIP file ready for distribution

param(
    [string]$Version = "2.1-beta",
    [string]$OutputDir = ".\releases"
)

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "AscensionVanity v$Version Packager" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}

# Create temp directory for packaging
$tempDir = ".\temp_release"
$addonDir = Join-Path $tempDir "AscensionVanity"

if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -Path $addonDir -ItemType Directory -Force | Out-Null

Write-Host "`n[1/5] Copying addon files..." -ForegroundColor Yellow

# Copy addon files (only what players need)
$addonFiles = @(
    "AscensionVanity.toc",
    "AscensionVanityConstants.lua",
    "AscensionVanityConfig.lua",
    "Core.lua",
    "VanityDB.lua",
    "VanityDB_Loader.lua",
    "APIScanner.lua",
    "ScannerUI.lua",
    "SettingsUI.lua",
    "RegionalGuide.lua"
)

$copiedFiles = 0
foreach ($file in $addonFiles) {
    $source = Join-Path "AscensionVanity" $file
    if (Test-Path $source) {
        Copy-Item $source $addonDir -Force
        $copiedFiles++
    } else {
        Write-Warning "Missing file: $file"
    }
}
Write-Host "  ✓ Copied $copiedFiles addon files" -ForegroundColor Green

Write-Host "`n[2/5] Copying documentation..." -ForegroundColor Yellow

# Copy essential documentation to temp root
$docs = @(
    "README.md",
    "CHANGELOG.md",
    "LICENSE"
)

$copiedDocs = 0
foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Copy-Item $doc $tempDir -Force
        $copiedDocs++
    }
}
Write-Host "  ✓ Copied $copiedDocs documentation files" -ForegroundColor Green

Write-Host "`n[3/5] Creating ZIP archive..." -ForegroundColor Yellow

# Create ZIP filename
$zipName = "AscensionVanity_v$Version.zip"
$zipPath = Join-Path $OutputDir $zipName

# Remove old ZIP if exists
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Create ZIP (PowerShell 5.0+)
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -CompressionLevel Optimal

$zipSize = (Get-Item $zipPath).Length / 1KB
Write-Host "  ✓ Created $zipName ($([math]::Round($zipSize, 2)) KB)" -ForegroundColor Green

Write-Host "`n[4/5] Verifying package..." -ForegroundColor Yellow

# Verify ZIP contents
$zipContents = Get-ChildItem $tempDir -Recurse -File
Write-Host "  ✓ Package contains $($zipContents.Count) files" -ForegroundColor Green

Write-Host "`n[5/5] Cleanup..." -ForegroundColor Yellow
Remove-Item $tempDir -Recurse -Force
Write-Host "  ✓ Temporary files removed" -ForegroundColor Green

# Summary
Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "Release Package Created!" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Package:  $zipName" -ForegroundColor White
Write-Host "Location: $OutputDir" -ForegroundColor White
Write-Host "Size:     $([math]::Round($zipSize, 2)) KB" -ForegroundColor White
Write-Host "`nPackage Contents:" -ForegroundColor White
Write-Host "  - AscensionVanity/ (addon folder with 10 files)" -ForegroundColor Gray
Write-Host "  - README.md" -ForegroundColor Gray
Write-Host "  - CHANGELOG.md" -ForegroundColor Gray
Write-Host "  - LICENSE" -ForegroundColor Gray

Write-Host "`n✓ Ready for distribution!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Test the addon from this ZIP" -ForegroundColor White
Write-Host "  2. Create GitHub release" -ForegroundColor White
Write-Host "  3. Upload $zipName" -ForegroundColor White
Write-Host "  4. Write release notes" -ForegroundColor White
Write-Host ""

# Return ZIP path for automation
return $zipPath
