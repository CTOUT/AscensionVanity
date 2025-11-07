# Quote Escaping Fix - Final Documentation

**Date**: November 7, 2025  
**Issue**: Names/descriptions with quotes cause Lua syntax errors in-game  
**Status**: ✅ FIXED AND DOCUMENTED

## The Problem

Items with quotes in their names (Count Ungula, Maury "Club Foot" Wilkins, Chucky "Ten Thumbs") were causing Lua syntax errors in-game because the quotes weren't properly escaped in the generated VanityDB.lua file.

**This issue has been fixed at least 3 times before and keeps getting lost.**

## The Solution

The fix requires proper handling in TWO places:

### 1. MasterAPIDumpImport.ps1 (IMPORT - Unescape)
**File**: `utilities/MasterAPIDumpImport.ps1`  
**Lines**: 221-230

```powershell
# Match strings that may contain escaped quotes (\")
if ($block -match '\["name"\]\s*=\s*"((?:[^"\\]|\\.)*)"') {
    $name = $Matches[1]
    # Unescape Lua escape sequences: \" becomes "
    $name = $name -replace '\\"', '"'
}
if ($block -match '\["description"\]\s*=\s*"((?:[^"\\]|\\.)*)"') {
    $description = $Matches[1]
    # Unescape Lua escape sequences
    $description = $description -replace '\\"', '"'
}
```

**What it does**: Converts Lua-escaped strings like `Maury \"Club Foot\" Wilkins` back to plain text `Maury "Club Foot" Wilkins` for JSON storage.

### 2. GenerateVanityDB_Master.ps1 (GENERATE - Escape)
**File**: `utilities/GenerateVanityDB_Master.ps1`  
**Lines**: 277, 295-297

```powershell
# Escape backslashes FIRST, then quotes (order matters!)
$safeName = $p.name -replace '\\', '\\\\' -replace '"', '\"'
$safeDesc = $p.description -replace '\\', '\\\\' -replace '"', '\"'
$safeZone = if ($p.zone) { $p.zone -replace '\\', '\\\\' -replace '"', '\"' } else { $null }
$safeSubzone = if ($p.subzone) { $p.subzone -replace '\\', '\\\\' -replace '"', '\"' } else { $null }

# Quest lock fields also need escaping
$safeQuestName = $p.questLock.questName -replace '\\', '\\\\' -replace '"', '\"'
$safeWarning = $p.questLock.warning -replace '\\', '\\\\' -replace '"', '\"'
$safeNotes = $p.questLock.notes -replace '\\', '\\\\' -replace '"', '\"'
```

**What it does**: Converts plain text `Maury "Club Foot" Wilkins` back to Lua-escaped `Maury \"Club Foot\" Wilkins` for the generated .lua file.

## Round-Trip Example

```
1. Game Scan:       ["name"] = "Maury \"Club Foot\" Wilkins"
2. After Import:    Maury "Club Foot" Wilkins (stored in JSON)
3. After Generate:  name = "Maury \"Club Foot\" Wilkins" (back to Lua)
```

## Verification

Run this test to verify the fix is still in place:

```powershell
.\utilities\TestQuoteEscaping.ps1
```

Expected output: All 10 tests pass

## Test Items

These specific items MUST work correctly:

| Item ID | Name | Type |
|---------|------|------|
| 79631 | "Count" Ungula | Beastmaster's Whistle |
| 87655 | Maury "Club Foot" Wilkins | Blood Soaked Vellum |
| 87657 | Chucky "Ten Thumbs" | Blood Soaked Vellum |

## Documentation

This fix is documented in multiple places to prevent it from being lost again:

1. **Project Instructions**: `.github/instructions/wow-addon-development.instructions.md`
   - Pattern: "Lua String Escaping Round-Trip"
   - Gotcha: "Quote Escaping Must Be Maintained in Pipeline"

2. **Test Script**: `utilities/TestQuoteEscaping.ps1`
   - Automated verification
   - Runs before deploys (recommended)

3. **This Document**: `QUOTE_ESCAPING_FIX.md`
   - Complete reference
   - How it works
   - Where to find it

## ⚠️ CRITICAL WARNING

**DO NOT "simplify" or "refactor" the escaping logic without:**

1. Running `.\utilities\TestQuoteEscaping.ps1` first
2. Testing all 3 items in-game after changes
3. Verifying no Lua errors appear with `/console scriptErrors 1`

**This fix has been lost at least 3 times. Please respect the complexity - it's necessary.**

## If This Gets Broken Again

1. Check if `MasterAPIDumpImport.ps1` lines 221-230 still have the unescape logic
2. Check if `GenerateVanityDB_Master.ps1` line 277 still has the double escape
3. Run `.\utilities\TestQuoteEscaping.ps1` to identify what's missing
4. Search for "Maury", "Chucky", or "Count Ungula" in VanityDB.lua to see the current state
5. Refer back to this document for the correct implementation

## Why This Keeps Breaking

- The escaping logic looks "complex" or "redundant" to someone unfamiliar with the issue
- Someone tries to "simplify" the code without testing
- The issue isn't immediately obvious (only affects 3 items out of 2,355)
- The fix involves two different files in the pipeline
- PowerShell regex escaping is unintuitive (`\\\\` looks like a bug but it's correct)

## Final Note

If you're reading this because the fix got lost again: I'm sorry. This document exists because it's happened multiple times. Please follow the instructions exactly as written, run the tests, and don't simplify the escaping logic.

**The complexity is intentional and necessary.**
