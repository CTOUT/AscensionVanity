<#
.SYNOPSIS
    Test quote escaping in the database pipeline

.DESCRIPTION
    Verifies that the quote escaping fix is still present in both:
    1. MasterAPIDumpImport.ps1 (unescaping on import)
    2. GenerateVanityDB_Master.ps1 (escaping on generation)
    
    This test was created because this issue has been fixed multiple times
    and keeps getting lost.

.EXAMPLE
    .\utilities\TestQuoteEscaping.ps1

.NOTES
    Author: CMTout & GitHub Copilot
    Date: 2025-11-07
    Critical: DO NOT DELETE THIS TEST!
#>

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Quote Escaping Verification Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$passed = 0
$failed = 0

# Test 1: Verify MasterAPIDumpImport.ps1 has unescape logic
Write-Host "[TEST 1] Checking MasterAPIDumpImport.ps1 for unescape logic..." -ForegroundColor Yellow
$importScript = Get-Content ".\utilities\MasterAPIDumpImport.ps1" -Raw

if ($importScript -match '\(\?\:\[\^"\\\\]\|\\\\\.\)\*') {
    Write-Host "  ✓ Import script has proper regex for escaped quotes" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ FAIL: Import script missing escaped quote regex!" -ForegroundColor Red
    $failed++
}

if ($importScript -match '\$name\s*=\s*\$name\s*-replace\s*''\\\\\"''\s*,\s*''"''') {
    Write-Host "  ✓ Import script has name unescape logic" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ FAIL: Import script missing name unescape!" -ForegroundColor Red
    $failed++
}

if ($importScript -match '\$description\s*=\s*\$description\s*-replace\s*''\\\\\"''\s*,\s*''"''') {
    Write-Host "  ✓ Import script has description unescape logic" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ FAIL: Import script missing description unescape!" -ForegroundColor Red
    $failed++
}

Write-Host ""

# Test 2: Verify GenerateVanityDB_Master.ps1 has escape logic
Write-Host "[TEST 2] Checking GenerateVanityDB_Master.ps1 for escape logic..." -ForegroundColor Yellow
$genScript = Get-Content ".\utilities\GenerateVanityDB_Master.ps1" -Raw

# Check for backslash escaping (must come first)
if ($genScript -match '\$safeName\s*=.*-replace\s+''\\\\''.*''\\\\\\\\''') {
    Write-Host "  ✓ Generation script has proper backslash escaping for names" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ FAIL: Generation script missing backslash escaping for names!" -ForegroundColor Red
    $failed++
}

# Check for quote escaping
if ($genScript -match '\$safeName\s*=.*-replace\s+''"''.*''\\\"''') {
    Write-Host "  ✓ Generation script has proper quote escaping for names" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ FAIL: Generation script missing quote escaping for names!" -ForegroundColor Red
    $failed++
}

# Check description escaping
if ($genScript -match '\$safeDesc\s*=.*-replace\s+''\\\\''.*''\\\\\\\\''') {
    Write-Host "  ✓ Generation script has proper backslash escaping for descriptions" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ FAIL: Generation script missing backslash escaping for descriptions!" -ForegroundColor Red
    $failed++
}

if ($genScript -match '\$safeDesc\s*=.*-replace\s+''"''.*''\\\"''') {
    Write-Host "  ✓ Generation script has proper quote escaping for descriptions" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ FAIL: Generation script missing quote escaping for descriptions!" -ForegroundColor Red
    $failed++
}

Write-Host ""

# Test 3: Verify test items in VanityDB.lua
Write-Host "[TEST 3] Checking VanityDB.lua for properly escaped test items..." -ForegroundColor Yellow

if (Test-Path ".\AscensionVanity\VanityDB.lua") {
    $dbContent = Get-Content ".\AscensionVanity\VanityDB.lua" -Raw
    
    # Test for Count Ungula (79631)
    if ($dbContent -match 'name\s*=\s*"Beastmaster''s Whistle:\s*\\"Count\\" Ungula"') {
        Write-Host "  ✓ Count Ungula properly escaped" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  ✗ FAIL: Count Ungula not properly escaped!" -ForegroundColor Red
        $failed++
    }
    
    # Test for Maury "Club Foot" Wilkins (87655)
    if ($dbContent -match 'name\s*=\s*"Blood Soaked Vellum:\s*Maury\s*\\"Club Foot\\" Wilkins"') {
        Write-Host "  ✓ Maury \"Club Foot\" Wilkins properly escaped" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  ✗ FAIL: Maury not properly escaped!" -ForegroundColor Red
        $failed++
    }
    
    # Test for Chucky "Ten Thumbs" (87657)
    if ($dbContent -match 'name\s*=\s*"Blood Soaked Vellum:\s*Chucky\s*\\"Ten Thumbs\\""') {
        Write-Host "  ✓ Chucky \"Ten Thumbs\" properly escaped" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  ✗ FAIL: Chucky not properly escaped!" -ForegroundColor Red
        $failed++
    }
} else {
    Write-Host "  ⚠ SKIP: VanityDB.lua not found (not generated yet)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Passed: $passed" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "  Failed: $failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "⚠️  CRITICAL: Quote escaping fix is broken!" -ForegroundColor Red
    Write-Host "See: .github/instructions/wow-addon-development.instructions.md" -ForegroundColor Yellow
    Write-Host "Search for: 'Gotcha: Quote Escaping Must Be Maintained'" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host ""
    Write-Host "✓ All tests passed! Quote escaping is working correctly." -ForegroundColor Green
    exit 0
}
