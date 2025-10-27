# API Validation - Quick Reference Card

## In-Game Commands

### `/av apidump`
**Purpose**: Extract complete API data to SavedVariables  
**When to use**: First step in validation process  
**Follow-up**: `/reload` to save data to disk

### `/av validate`
**Purpose**: Compare API data vs static database  
**When to use**: After running `/av apidump` and `/reload`  
**Shows**:
- Total items in API vs Database
- Exact matches count
- Missing items (in API but not in DB)
- Mismatches (different item IDs)

### `/av api`
**Purpose**: Scan for available Ascension vanity APIs  
**When to use**: Debug/verify API availability  
**Shows**: All C_VanityCollection functions available

### `/av dump`
**Purpose**: Dump vanity collection data structure  
**When to use**: Debug/investigate API structure  
**Shows**: First 2 items in full detail with nested structure

### `/av dumpitem <itemID>`
**Purpose**: Search for specific item in API data  
**When to use**: Verify a specific item's data  
**Example**: `/av dumpitem 79626`

---

## PowerShell Scripts

### `.\utilities\AnalyzeAPIDump.ps1`
**Purpose**: Analyze SavedVariables and show validation summary  
**Usage**: `.\utilities\AnalyzeAPIDump.ps1`  
**Detailed**: `.\utilities\AnalyzeAPIDump.ps1 -Detailed`  
**Output**:
- Validation statistics
- Category breakdown
- Difference analysis
- Optional: Detailed reports in `API_Analysis/` folder

### `.\utilities\UpdateDatabaseFromAPI.ps1`
**Purpose**: Generate new VanityDB.lua from API data  
**Usage**: `.\utilities\UpdateDatabaseFromAPI.ps1`  
**With backup**: `.\utilities\UpdateDatabaseFromAPI.ps1 -Backup`  
**Output**: Creates `VanityDB_Updated.lua` with complete API mappings

---

## Workflow Summary

### Quick Validation (5 minutes)
1. `/av apidump` → Wait for completion
2. `/reload` → Save data
3. `/av validate` → Review results

### Full Analysis (15 minutes)
1. **In-Game**: `/av apidump` → `/reload` → `/av validate`
2. **PowerShell**: `.\utilities\AnalyzeAPIDump.ps1 -Detailed`
3. **Review**: Check `API_Analysis/` folder for reports
4. **Manual**: Open SavedVariables file to see complete data

### Database Update (30 minutes)
1. **In-Game**: `/av apidump` → `/reload`
2. **PowerShell**: `.\utilities\UpdateDatabaseFromAPI.ps1 -Backup`
3. **Review**: Compare `VanityDB_Updated.lua` vs `VanityDB.lua`
4. **Replace**: Rename updated file to `VanityDB.lua`
5. **Test**: `/reload` in-game and verify tooltips

---

## File Locations

### SavedVariables (API Dump)
```
WTF\Account\[YourAccount]\SavedVariables\AscensionVanity.lua
```

### Generated Reports
```
API_Analysis\
  ├── APIDump_Raw_[timestamp].lua
  └── Analysis_Report_[timestamp].md
```

### Database Files
```
AscensionVanity\
  ├── VanityDB.lua (current)
  ├── VanityDB_Updated.lua (new from API)
  └── VanityDB_Backup_[timestamp].lua (backup)
```

---

## Validation Results Interpretation

### `apiTotal > dbTotal`
✅ **Normal** - API has more items than our database  
→ These are the missing items we need to add

### `matches` count
✅ **Higher is better** - Items correctly mapped  
→ Percentage: `(matches / dbTotal) * 100%`

### `apiOnly` items
📋 **Action Required** - Items to add to database  
→ These are definitely missing from our DB

### `mismatches` items
⚠️ **Critical** - Wrong mappings in our database  
→ Fix these first - they're incorrect data

---

## Common Issues

### No API dump found
**Fix**: Run `/av apidump` and `/reload` first

### SavedVariables file not found (PowerShell)
**Fix**: Update path in script or use `-SavedVariablesPath` parameter

### Validation shows 0 matches
**Fix**: Make sure VanityDB.lua is loaded (check with `/av debug`)

### Can't find missing items in SavedVariables
**Fix**: Search for `apiOnly = {` in the file

---

## Tips

- Always `/reload` after `/av apidump` to save data
- Run validation multiple times to verify consistency
- Keep backups before replacing VanityDB.lua
- Test updated database in-game before committing
- Use `-Detailed` flag for complete analysis reports

---

*Quick Reference Card v1.0 - October 27, 2025*
