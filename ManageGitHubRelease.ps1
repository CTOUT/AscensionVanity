<#
.SYNOPSIS
    Manages GitHub releases for AscensionVanity v2.0.

.DESCRIPTION
    This script helps archive old releases and create a new v2.0 release on GitHub.
    Requires GitHub CLI (gh) to be installed and authenticated.

.EXAMPLE
    .\ManageGitHubRelease.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "🚀 AscensionVanity v2.0 GitHub Release Manager" -ForegroundColor Cyan
Write-Host "=" * 60

# Check if gh CLI is installed
Write-Host "`n🔍 Checking GitHub CLI installation..." -ForegroundColor Yellow
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue

if (-not $ghInstalled) {
    Write-Host "❌ GitHub CLI (gh) is not installed!" -ForegroundColor Red
    Write-Host "`nPlease install it from: https://cli.github.com/" -ForegroundColor Yellow
    Write-Host "After installation, run: gh auth login" -ForegroundColor Yellow
    exit 1
}

Write-Host "  ✓ GitHub CLI found" -ForegroundColor Green

# Check authentication
Write-Host "`n🔐 Checking GitHub authentication..." -ForegroundColor Yellow
try {
    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Not authenticated with GitHub!" -ForegroundColor Red
        Write-Host "`nPlease run: gh auth login" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  ✓ Authenticated" -ForegroundColor Green
} catch {
    Write-Host "❌ GitHub authentication check failed!" -ForegroundColor Red
    exit 1
}

# Get current repository
$repoRoot = $PSScriptRoot
Set-Location $repoRoot

Write-Host "`n📋 Current GitHub Releases:" -ForegroundColor Yellow
Write-Host ""
gh release list

# Ask user confirmation
Write-Host "`n⚠️  Release Management Plan:" -ForegroundColor Yellow
Write-Host "  1. Archive old releases (v1.0.0, v2.0.0-beta, v2.1-beta)" -ForegroundColor White
Write-Host "  2. Create new v2.0 stable release" -ForegroundColor White
Write-Host "  3. Upload AscensionVanity-v2.0.zip" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Do you want to proceed? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "❌ Operation cancelled" -ForegroundColor Yellow
    exit 0
}

# Archive old releases by editing them to mark as pre-release/draft
Write-Host "`n📦 Archiving old releases..." -ForegroundColor Yellow

$oldReleases = @("v1.0.0", "v2.0.0-beta", "v2.1-beta")

foreach ($release in $oldReleases) {
    Write-Host "  Processing: $release" -ForegroundColor Gray
    try {
        # Mark as pre-release to move them down the list
        gh release edit $release --prerelease --title "[$release] (Archived - superseded by v2.0)"
        Write-Host "    ✓ Marked as pre-release: $release" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠️  Could not archive: $release (may not exist)" -ForegroundColor Yellow
    }
}

# Create release notes from file
$releaseNotesPath = Join-Path $repoRoot "releases\RELEASE_NOTES_v2.0.md"
$releaseZipPath = Join-Path $repoRoot "releases\AscensionVanity-v2.0.zip"

if (-not (Test-Path $releaseNotesPath)) {
    Write-Host "❌ Release notes not found: $releaseNotesPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $releaseZipPath)) {
    Write-Host "❌ Release package not found: $releaseZipPath" -ForegroundColor Red
    exit 1
}

# Create the new release
Write-Host "`n🎉 Creating v2.0 stable release..." -ForegroundColor Yellow

try {
    # Create release with notes and attach the zip file
    gh release create v2.0 `
        --title "AscensionVanity v2.0 - Stable Release" `
        --notes-file $releaseNotesPath `
        --latest `
        $releaseZipPath
    
    Write-Host "  ✓ Release v2.0 created successfully!" -ForegroundColor Green
    Write-Host "  ✓ Attached: AscensionVanity-v2.0.zip" -ForegroundColor Green
    Write-Host "  ✓ Marked as latest release" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create release!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    
    # Check if release already exists
    Write-Host "`nℹ️  If the release already exists, you can update it with:" -ForegroundColor Yellow
    Write-Host "   gh release upload v2.0 releases\AscensionVanity-v2.0.zip --clobber" -ForegroundColor White
    exit 1
}

# Display final release list
Write-Host "`n📋 Updated GitHub Releases:" -ForegroundColor Cyan
Write-Host ""
gh release list

Write-Host "`n✅ Release management complete!" -ForegroundColor Green
Write-Host "`n🔗 View your releases at:" -ForegroundColor Cyan
Write-Host "   https://github.com/CTOUT/AscensionVanity/releases" -ForegroundColor White
Write-Host "`n🎊 v2.0 is now the latest stable release!" -ForegroundColor Green
