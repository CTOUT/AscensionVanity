# Quote Escaping Fix - Test Plan

## Problem Identified
NPC/Creature names containing quotation marks (e.g., "Count" Ungula, Maury "Club Foot" Wilkins) were breaking the VanityDB.lua generation process.

## Root Causes Found

### 1. FilterDropsFromAPI.ps1 - Regex Pattern Issue
**Location**: Line 35 and Line 50
**Problem**: Regex pattern `"([^"]+)"` stops at first quote character, truncating names
**Example**:
- Input: `["name"] = "Beastmaster's Whistle: \"Count\" Ungula"`
- Old Regex: Captured only `Beastmaster's Whistle: \`
- New Regex: `"((?:[^"\\]|\\.)*)"` properly handles escaped quotes

### 2. GenerateVanityDB_V2.ps1 - Quote Escaping Issue  
**Location**: Lines 81-82
**Problem**: Using `-replace '"', '\"'` with PowerShell's regex operator caused issues
**Solution**: Changed to `.Replace('"', '\"')` method for cleaner string replacement

## Files Modified

1. **utilities/FilterDropsFromAPI.ps1**
   - Updated regex pattern to handle escaped quotes in Lua strings
   - Pattern: `(?:[^"\\]|\\.)*` matches either non-quote/non-backslash OR any escaped character

2. **utilities/GenerateVanityDB_V2.ps1**
   - Changed from `-replace` operator to `.Replace()` method
   - Ensures consistent `\"` escape sequence in output

## Test Cases

### Test 1: Extract from SavedVariables
```powershell
# Run FilterDropsFromAPI to regenerate JSON from SavedVariables
.\utilities\FilterDropsFromAPI.ps1 -InputFile "data\AscensionVanity.lua"
```

**Expected Result in DropsOnly_Analysis.json:**
```json
{
  "ItemId": "2341",
  "CreatureId": "18285",
  "Name": "Beastmaster's Whistle: \"Count\" Ungula",
  "Description": "Has a chance to drop from Count Ungula within Zangarmarsh"
}
```

### Test 2: Generate VanityDB.lua
```powershell
# Generate Lua files from JSON
.\utilities\GenerateVanityDB_V2.ps1
```

**Expected Result in VanityDB.lua:**
```lua
[2341] = {
    itemid = 2341,
    name = "Beastmaster's Whistle: \"Count\" Ungula",
    creaturePreview = 18285,
    description = "Has a chance to drop from Count Ungula within Zangarmarsh",
    icon = "Interface/Icons/Ability_Hunter_BeastCall"
},
```

### Test 3: Verify Lua Syntax
```powershell
# Check for syntax errors in generated file
Get-Content "data\VanityDB.lua" | Select-String -Pattern 'name = ".*\\",\s*$'
```

**Expected**: No matches (all strings properly terminated)

### Test 4: Known Problem Items
Verify these three specific items are correctly handled:

1. **Item 2341**: "Count" Ungula
   - Line should read: `name = "Beastmaster's Whistle: \"Count\" Ungula",`

2. **Item 2980**: Maury "Club Foot" Wilkins
   - Line should read: `name = "Blood Soaked Vellum: Maury \"Club Foot\" Wilkins",`

3. **Item 2982**: Chucky "Ten Thumbs"
   - Line should read: `name = "Blood Soaked Vellum: Chucky \"Ten Thumbs\"",`

## Validation Commands

### Check JSON Output
```powershell
$json = Get-Content "data\DropsOnly_Analysis.json" | ConvertFrom-Json
$json.'Beastmaster''s Whistle' | Where-Object { $_.ItemId -eq "2341" } | Format-List
$json.'Blood Soaked Vellum' | Where-Object { $_.ItemId -eq "2980" } | Format-List
$json.'Blood Soaked Vellum' | Where-Object { $_.ItemId -eq "2982" } | Format-List
```

### Check Lua Output
```powershell
Get-Content "data\VanityDB.lua" | Select-String -Pattern "2341|2980|2982" -Context 3
```

### Find Any Remaining Truncated Names
```powershell
# Should return NO results
Get-Content "data\VanityDB.lua" | Select-String -Pattern 'name = ".*\\",\s*$'
```

## Prevention for Future

The updated scripts now automatically handle:
- Creature names with quotes: "Name" 
- Nicknames in quotes: Name "Nickname" Surname
- Multiple quoted sections: "First" Name "Second"
- Escaped characters in Lua strings: `\"`, `\'`, `\\`, etc.

## Manual Verification Steps

1. Delete existing generated files:
   ```powershell
   Remove-Item "data\DropsOnly_Analysis.json" -ErrorAction SilentlyContinue
   Remove-Item "data\VanityDB.lua" -ErrorAction SilentlyContinue
   Remove-Item "data\VanityDB_Regions.lua" -ErrorAction SilentlyContinue
   ```

2. Regenerate from source:
   ```powershell
   .\utilities\FilterDropsFromAPI.ps1
   .\utilities\GenerateVanityDB_V2.ps1
   ```

3. Verify no syntax errors:
   ```powershell
   # Check for truncated names (should be empty)
   Get-Content "data\VanityDB.lua" | Select-String -Pattern 'name = ".*\\",\s*$'
   ```

4. Copy to addon folder:
   ```powershell
   Copy-Item "data\VanityDB.lua" -Destination "AscensionVanity\" -Force
   Copy-Item "data\VanityDB_Regions.lua" -Destination "AscensionVanity\" -Force
   ```

5. Test in-game to confirm addon loads without errors

## Success Criteria

- [ ] FilterDropsFromAPI extracts full names including quoted sections
- [ ] JSON output contains properly formatted names with `\"`
- [ ] GenerateVanityDB produces valid Lua syntax
- [ ] No truncated names ending with `\"`
- [ ] All three problem items (2341, 2980, 2982) display correctly
- [ ] Addon loads in-game without errors
- [ ] Tooltip displays correct creature names
