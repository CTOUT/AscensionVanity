# Slash Command Correction

**Date**: 2025-11-06  
**Issue**: Documentation incorrectly references `/av` as a valid command  
**Status**: ❌ Incorrect - `/av` is used by Ascension's own interface system

## Correct Slash Commands

The addon registers **three** valid slash commands:

```lua
SLASH_ASCENSIONVANITY1 = "/avanity"
SLASH_ASCENSIONVANITY2 = "/ascvan"
SLASH_ASCENSIONVANITY3 = "/ascensionvanity"
```

**Correct usage:**
- `/avanity` - Primary command (recommended)
- `/ascvan` - Short alias
- `/ascensionvanity` - Full name

**Incorrect usage:**
- ❌ `/av` - **CONFLICTS** with Ascension's own interface system

## Files Requiring Correction

### 🔴 High Priority (Active Documentation)

| File | Occurrences | Priority | Notes |
|------|-------------|----------|-------|
| `TEST_PROGRESS_EXPANSION.lua` | 1 | ✅ FIXED | Active test script |
| `DeployAddon.ps1` | 1 | ✅ FIXED | Deployment instructions |
| `PROGRESS_TRACKER_EXPANSION.md` | Multiple | 🔴 HIGH | New feature doc |
| `SESSION_2025-11-06_PROGRESS_EXPANSION.md` | Multiple | 🔴 HIGH | Recent session |
| `docs/QUICK_START.md` | 4 | 🔴 HIGH | User-facing guide |
| `docs/PROJECT_STATUS.md` | 10+ | 🔴 HIGH | Main status doc |
| `docs/guides/IN_GAME_TESTING_GUIDE.md` | 10+ | 🔴 HIGH | Testing guide |
| `docs/guides/DEPLOYMENT_GUIDE.md` | 3 | 🔴 HIGH | Deployment docs |
| `docs/guides/API_QUICK_REFERENCE.md` | 15+ | 🔴 HIGH | API reference |
| `docs/guides/API_SCANNING_GUIDE.md` | 1+ | 🔴 HIGH | Scanning guide |
| `docs/guides/DEV_CONSOLE_REFERENCE.md` | 10+ | 🔴 HIGH | Console reference |
| `docs/LOCAL_CONFIG.md` | 1 | 🔴 HIGH | Config guide |
| `docs/DATA_SCHEMAS.md` | 1 | 🔴 HIGH | Schema docs |

### 🟡 Medium Priority (Historical/Archive)

| File | Occurrences | Priority | Notes |
|------|-------------|----------|-------|
| `CHANGELOG.md` | 6 | 🟡 MEDIUM | Historical changelog |
| `docs/archive/NEXT_STEPS.md` | 8+ | 🟡 MEDIUM | Archived docs |
| `docs/archive/TODO.md` | 2 | 🟡 MEDIUM | Old TODO list |
| `docs/archive/session_notes/*.md` | 30+ | 🟡 MEDIUM | Session logs |
| `docs/development/logs/*.md` | 10+ | 🟡 MEDIUM | Development logs |

## Recommended Fix Pattern

### Search & Replace Strategy

**Find:**
```regex
/av\b(?!\s+(help|debug|config|version|progress|browser|guide|scanner|apidump|validate|export|showexport|api|dump|dumpitem|learned|color|show))
```

**Replace with:**
```
/avanity
```

**For command examples:**
```
Before: /av help
After:  /avanity help

Before: /av progress
After:  /avanity progress

Before: /av browser
After:  /avanity browser
```

## Files Fixed So Far

### ✅ Immediate Fixes (2025-11-06)
- ✅ `TEST_PROGRESS_EXPANSION.lua` - Changed `/av progress` → `/avanity progress`
- ✅ `DeployAddon.ps1` - Changed `/av help` → `/avanity help`

### ✅ High Priority Documentation (2025-11-06 - Bulk Fix)
- ✅ `PROGRESS_TRACKER_EXPANSION.md` - Fixed 6 references
- ✅ `SESSION_2025-11-06_PROGRESS_EXPANSION.md` - Fixed multiple references
- ✅ `docs/QUICK_START.md` - Fixed 4+ references
- ✅ `docs/PROJECT_STATUS.md` - Fixed 10+ references
- ✅ `docs/LOCAL_CONFIG.md` - Fixed references
- ✅ `docs/DATA_SCHEMAS.md` - Fixed references
- ✅ `docs/guides/IN_GAME_TESTING_GUIDE.md` - Fixed 10+ references
- ✅ `docs/guides/DEPLOYMENT_GUIDE.md` - Fixed 3+ references
- ✅ `docs/guides/API_QUICK_REFERENCE.md` - Fixed 15+ references
- ✅ `docs/guides/API_SCANNING_GUIDE.md` - Fixed references
- ✅ `docs/guides/DEV_CONSOLE_REFERENCE.md` - Fixed 10+ references

**Total Fixed: 13 files (all high-priority user-facing documentation)**

## Bulk Fix Script (PowerShell)

```powershell
# WARNING: Review changes carefully before running!
# This will update all active documentation files

$filesToFix = @(
    "PROGRESS_TRACKER_EXPANSION.md",
    "SESSION_2025-11-06_PROGRESS_EXPANSION.md",
    "docs/QUICK_START.md",
    "docs/PROJECT_STATUS.md",
    "docs/guides/IN_GAME_TESTING_GUIDE.md",
    "docs/guides/DEPLOYMENT_GUIDE.md",
    "docs/guides/API_QUICK_REFERENCE.md",
    "docs/guides/API_SCANNING_GUIDE.md",
    "docs/guides/DEV_CONSOLE_REFERENCE.md",
    "docs/LOCAL_CONFIG.md",
    "docs/DATA_SCHEMAS.md"
)

foreach ($file in $filesToFix) {
    $path = Join-Path "C:\Repos\AscensionVanity" $file
    if (Test-Path $path) {
        Write-Host "Fixing: $file"
        $content = Get-Content $path -Raw
        
        # Replace /av with /avanity (but not in URLs or paths)
        $content = $content -replace '`/av\s', '`/avanity '
        $content = $content -replace '^/av\s', '/avanity '
        $content = $content -replace '\s/av\s', ' /avanity '
        
        Set-Content $path $content -NoNewline
    } else {
        Write-Host "Not found: $file" -ForegroundColor Yellow
    }
}
```

## Testing After Fix

```bash
# Verify no incorrect references remain in active docs
grep -r "/av " --include="*.md" docs/ --exclude-dir=archive

# Verify addon code still correct
grep "SLASH_ASCENSIONVANITY" AscensionVanity/Core.lua
```

## Impact Assessment

### User Impact
- **High**: Users following current documentation will use wrong command
- **Confusion**: `/av` conflicts with Ascension's interface, causing unexpected behavior
- **Mitigation**: Update all user-facing documentation ASAP

### Historical Impact
- **Low**: Archive files are historical record, can be updated but lower priority
- **Context**: Session notes should reflect what was actually typed (even if wrong)
- **Recommendation**: Add note at top of archived files about the correction

## Recommended Action Plan

1. **Immediate** (Today):
   - ✅ Fix `TEST_PROGRESS_EXPANSION.lua`
   - ✅ Fix `DeployAddon.ps1`
   - ✅ Fix `PROGRESS_TRACKER_EXPANSION.md`
   - ✅ Fix `SESSION_2025-11-06_PROGRESS_EXPANSION.md`

2. **High Priority** (This Week):
   - ✅ Fix all files in `docs/guides/` (9 files)
   - ✅ Fix `docs/QUICK_START.md`
   - ✅ Fix `docs/PROJECT_STATUS.md`
   - ✅ Fix `docs/LOCAL_CONFIG.md`
   - ✅ Fix `docs/DATA_SCHEMAS.md`

3. **Medium Priority** (Next Week):
   - 🔲 Update `CHANGELOG.md` (or add note)
   - 🔲 Add correction note to archived session notes
   - 🔲 Update development logs if actively referenced

4. **Final Verification**:
   - 🔲 Grep for remaining `/av ` references in active docs
   - 🔲 Test in-game to confirm no conflicts
   - ✅ Update this document with completion status

## Notes

- The addon code itself is **correct** (uses `/avanity`, `/ascvan`, `/ascensionvanity`)
- Only documentation needs fixing
- Archive files can be marked with "Historical Note" instead of editing
- Future documentation should consistently use `/avanity` as primary command

---

**Created**: 2025-11-06  
**Last Updated**: 2025-11-06  
**Status**: ✅ HIGH PRIORITY COMPLETE (13/13 files fixed)

**Git Commits:**
- `83cc23a` - Initial fixes (4 files)
- `87aab6b` - Bulk high-priority docs (9 files)

**Remaining:** Archive files only (~30 files, historical reference, lower priority)
