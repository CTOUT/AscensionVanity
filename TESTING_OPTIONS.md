# Testing Options for WoW Lua Addons

## Overview

Testing World of Warcraft addons presents unique challenges since the code runs within the WoW client environment. This document outlines available testing approaches for AscensionVanity.

---

## 1. Manual Testing (Current Approach)

**Status:** ✅ Implemented (UI_TEST_PLAN.md)

### Advantages
- Tests real WoW environment
- Catches UI rendering issues
- Validates user experience
- No complex setup required
- Tests actual player workflows

### Disadvantages
- Time-consuming
- Not automated
- Requires manual execution
- Human error possible

### When to Use
- **Before every release** (required)
- After major feature changes
- When fixing critical bugs
- Before merging to main branch

---

## 2. Lua Unit Testing Frameworks

### Option A: Busted (Lua Testing Framework)

**Website:** https://github.com/Olivine-Labs/busted

**Description:** Popular Lua testing framework with BDD-style syntax.

**Pros:**
- Standard Lua testing framework
- Good assertion library
- Mocking capabilities
- CI/CD integration possible

**Cons:**
- Doesn't run in WoW environment
- Can't test WoW API calls
- Requires extensive mocking of WoW globals
- Setup complexity high

**Example:**
```lua
describe("VanityDB", function()
  it("should load items correctly", function()
    -- Would need to mock entire WoW API
    -- Not practical for our addon
    assert.truthy(AV_VanityItems)
  end)
end)
```

**Recommendation:** ❌ Not practical for WoW addons due to WoW API dependency

---

### Option B: WoW Addon Test Framework (Theoretical)

**Description:** Custom test framework that runs inside WoW.

**Pros:**
- Tests in actual WoW environment
- Access to real WoW API
- No mocking needed

**Cons:**
- Would need to be built from scratch
- Complex to implement
- Slower than standard unit tests
- Requires WoW to be running

**Implementation Complexity:** Very High

**Recommendation:** ❌ Too complex for current project scope

---

## 3. Static Analysis

### Option A: Luacheck (Linter)

**Website:** https://github.com/lunarmodules/luacheck

**Status:** ⚠️ Could be implemented

**Description:** Static analyzer for Lua code.

**Pros:**
- Catches syntax errors
- Identifies unused variables
- Detects undefined globals
- Fast (no WoW needed)
- CI/CD integration easy

**Cons:**
- Doesn't test functionality
- Requires WoW API stub definitions
- False positives possible

**Setup:**
```bash
# Install luacheck
luarocks install luacheck

# Run analysis
luacheck AscensionVanity/ --std max+wow
```

**Configuration:** `.luacheckrc`
```lua
std = "lua51+wow"
ignore = {
    "211", -- Unused local variable
    "212", -- Unused argument
}
globals = {
    "AscensionVanityDB",
    "AV_VanityItems",
    "AV_IconList",
    -- Add all addon globals
}
```

**Recommendation:** ✅ Worth implementing for catching obvious errors

---

### Option B: Lua Language Server

**Website:** https://github.com/LuaLS/lua-language-server

**Description:** VS Code extension with type checking.

**Pros:**
- Real-time error detection
- Autocomplete
- Type inference
- Free and easy to set up

**Cons:**
- Needs WoW API definitions
- Can't test runtime behavior

**Setup:**
1. Install "Lua" extension in VS Code
2. Add WoW API definitions (community-maintained)
3. Configure workspace settings

**Recommendation:** ✅ Already available in VS Code, minimal setup

---

## 4. Integration Testing Approaches

### Option A: Automated UI Testing (Selenium-style)

**Status:** ❌ Not practical for WoW

**Description:** Automated UI interaction testing.

**Why Not Practical:**
- WoW doesn't expose automation APIs
- Third-party automation violates ToS
- Complex to implement
- Fragile tests

**Recommendation:** ❌ Not feasible

---

### Option B: Manual Integration Test Scripts

**Status:** ✅ Implemented in UI_TEST_PLAN.md

**Description:** Documented test scenarios with expected outcomes.

**Implementation:**
- Comprehensive test plan (UI_TEST_PLAN.md)
- Step-by-step instructions
- Pass/fail criteria
- Coverage matrix

**Recommendation:** ✅ Best approach for WoW addons

---

## 5. Smoke Testing

### Quick Validation Script

**Purpose:** Rapid validation that nothing is broken.

**Implementation:** `/script` commands in WoW

**Example Smoke Tests:**
```lua
-- Test 1: Addon loaded
/script if AscensionVanityDB then print("✓ DB loaded") else print("✗ DB not loaded") end

-- Test 2: Functions exist
/script if AscensionVanity_ShowSettings then print("✓ Functions loaded") else print("✗ Functions missing") end

-- Test 3: UI frames exist
/script if AscensionVanitySettingsPanel then print("✓ Settings UI loaded") else print("✗ Settings UI missing") end

-- Test 4: Database populated
/script local count = 0; for _ in pairs(AV_VanityItems) do count = count + 1 end; print(count .. " creatures in database")
```

**Recommendation:** ✅ Quick validation after deployment

---

## 6. Recommended Testing Strategy for AscensionVanity

### Tier 1: Pre-Commit (Developer)
- [ ] **Luacheck** - Static analysis for syntax errors
- [ ] **Visual inspection** - Code review
- [ ] **Quick smoke test** - `/reload` and verify no errors

### Tier 2: Pre-Merge (Feature Complete)
- [ ] **Smoke testing** - Quick validation scripts
- [ ] **Targeted manual testing** - Test changed functionality
- [ ] **Integration check** - Verify no regressions

### Tier 3: Pre-Release (Before Main Merge)
- [ ] **Full manual test plan** - Complete UI_TEST_PLAN.md
- [ ] **Performance testing** - Memory usage, load times
- [ ] **Cross-feature testing** - All features work together
- [ ] **Edge case testing** - Error conditions, unusual inputs

---

## 7. Luacheck Implementation Guide

### Step 1: Install Luacheck

**Windows (via Scoop):**
```powershell
scoop install luarocks
luarocks install luacheck
```

**Windows (via Chocolatey):**
```powershell
choco install lua luarocks
luarocks install luacheck
```

**Linux/Mac:**
```bash
luarocks install luacheck
```

### Step 2: Create `.luacheckrc` in Repository Root

```lua
-- AscensionVanity Luacheck Configuration
std = "lua51"

-- Ignore specific warnings
ignore = {
    "211", -- Unused local variable (common in WoW addons)
    "212", -- Unused argument (event handlers often ignore args)
    "213", -- Unused loop variable
}

-- Global variables defined by WoW API
read_globals = {
    -- Standard Lua
    "string", "table", "math", "pairs", "ipairs",
    
    -- WoW API Functions
    "print", "CreateFrame", "GameTooltip", "UIParent",
    "tinsert", "tremove", "wipe",
    "GetTime", "GetAddOnMetadata",
    "InterfaceOptions_AddCategory",
    "StaticPopupDialogs", "StaticPopup_Show",
    
    -- WoW Constants
    "NORMAL_FONT_COLOR", "HIGHLIGHT_FONT_COLOR",
    "RAID_CLASS_COLORS",
}

-- Globals we define (our addon variables)
globals = {
    "AscensionVanityDB",
    "AV_VanityItems",
    "AV_IconList",
    "AV_DumpData",
    "AscensionVanity_InitConfig",
    "AscensionVanity_ShowSettings",
    "AscensionVanity_ShowScanner",
    "AscensionVanity_SyncDebugCheckbox",
    "AscensionVanity_SyncSettingsUI",
}

-- Files to check
files = {
    "AscensionVanity/",
}

-- Files to exclude
exclude_files = {
    "AscensionVanity/VanityDB.lua", -- Generated file, very large
}
```

### Step 3: Run Luacheck

```powershell
# Check all files
luacheck AscensionVanity/

# Check specific file
luacheck AscensionVanity/Core.lua

# Check with verbose output
luacheck AscensionVanity/ -v

# Output to file
luacheck AscensionVanity/ > luacheck_report.txt
```

### Step 4: CI/CD Integration (GitHub Actions)

**File:** `.github/workflows/luacheck.yml`

```yaml
name: Lua Lint

on: [push, pull_request]

jobs:
  luacheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install Lua and LuaRocks
        run: |
          sudo apt-get update
          sudo apt-get install -y lua5.1 luarocks
      
      - name: Install Luacheck
        run: sudo luarocks install luacheck
      
      - name: Run Luacheck
        run: luacheck AscensionVanity/
```

---

## 8. Testing Checklist Template

### Before Each Commit
- [ ] Code compiles (no syntax errors)
- [ ] Luacheck passes (if implemented)
- [ ] `/reload` works without errors
- [ ] Changed functionality works

### Before Each Merge
- [ ] Smoke tests pass
- [ ] Targeted tests for changed features pass
- [ ] No Lua errors in 5-minute play session
- [ ] Settings persist correctly

### Before Each Release
- [ ] Full UI_TEST_PLAN.md completed
- [ ] All test suites pass
- [ ] Performance is acceptable
- [ ] Documentation updated
- [ ] CHANGELOG.md updated

---

## 9. Current Testing Status

### ✅ Implemented
- Comprehensive manual test plan (UI_TEST_PLAN.md)
- Smoke test examples
- Pre-commit checklist

### ⚠️ Recommended Next Steps
1. Implement Luacheck for static analysis
2. Create `.luacheckrc` configuration
3. Add Luacheck to development workflow
4. Consider CI/CD integration for automated checks

### ❌ Not Recommended
- Full unit testing framework (too complex)
- Automated UI testing (not practical for WoW)
- Custom test framework (overkill for project size)

---

## 10. Conclusion

**Best Testing Approach for AscensionVanity:**

1. **Static Analysis (Luacheck)** - Catch obvious errors automatically
2. **Manual Test Plan** - Comprehensive UI and integration testing
3. **Smoke Tests** - Quick validation after changes
4. **Code Review** - Peer review before merges

This combination provides:
- ✅ Fast feedback (static analysis)
- ✅ Comprehensive coverage (manual tests)
- ✅ Real environment validation (in-game testing)
- ✅ Practical for small team/solo dev
- ✅ No complex infrastructure needed

**Remember:** For WoW addons, manual testing in the actual game environment is essential. No amount of automated testing can replace real-world usage testing.
