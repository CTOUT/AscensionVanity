# 🚀 NEXT STEPS - API Validation Testing

**Status**: ✅ All code complete and ready for in-game testing  
**Date**: October 27, 2025  
**Estimated Time**: 15-30 minutes

---

## 🎯 Your Mission

Test the new API validation system in-game to:
1. ✅ Verify it works correctly
2. 📊 Get actual numbers for missing items
3. 🔍 Identify specific items to add
4. 📝 Generate data for database v2.1

---

## ✅ Step-by-Step Testing Checklist

### Phase 0: Developer Tools Setup (5 minutes) 🔧

**IMPORTANT**: You have developer addons enabled! Let's use them first.

1. **Open the Ascension API Documentation addon**:
   - Check your AddOns menu or keybindings
   - Search for "Vanity" or browse to "C_VanityCollection"
   - ✅ Document available functions (screenshot if possible)
   - ✅ Note function signatures and parameters

2. **Open the Developer Console**:
   - Check UI Development Tools menu/keybindings
   - ✅ Verify console is accessible
   - ✅ Test basic Lua execution: `print("Dev console works!")`

3. **Test the Vanity API directly in console**:
   ```lua
   -- Check if API exists
   print(type(C_VanityCollection))
   
   -- Get total categories
   local categories = C_VanityCollection.GetNumTransmogCategories()
   print("Categories: " .. categories)
   
   -- Test getting sources for first category
   local sources = C_VanityCollection.GetAllTransmogSources(0)
   print("Category 0 sources: " .. #sources)
   
   -- Inspect structure of first item
   if sources[1] then
       for k,v in pairs(sources[1]) do
           print("  " .. k .. " = " .. tostring(v))
       end
   end
   ```
   - ✅ Document the structure you see
   - ✅ Note any unexpected fields or values
   - ✅ Screenshot console output if possible

4. **Document API findings**:
   - Total categories found: _______________
   - Fields in each source: _______________
   - Data structure matches expectations: ☐ Yes ☐ No
   - Any surprises: _______________

### Phase 1: In-Game Testing (5 minutes)

1. **Launch Project Ascension and log in to your character**
   
2. **Test the API dump command**:
   ```
   /av apidump
   ```
   - ✅ Wait for completion message
   - ✅ Verify you see category counts
   - ✅ Note the total item count

3. **Save the data**:
   ```
   /reload
   ```
   - ✅ UI reloads
   - ✅ SavedVariables file should now contain the dump

4. **Test the validation command**:
   ```
   /av validate
   ```
   - ✅ See validation summary
   - ✅ Note API total vs Database total
   - ✅ Note number of missing items
   - ✅ Note number of mismatches

5. **Save validation results**:
   ```
   /reload
   ```

### Phase 2: PowerShell Analysis (5 minutes)

6. **Open PowerShell in the repository folder**:
   ```powershell
   cd D:\Repos\AscensionVanity
   ```

7. **Run basic analysis**:
   ```powershell
   .\utilities\AnalyzeAPIDump.ps1
   ```
   - ✅ Verify it finds the SavedVariables file
   - ✅ Check validation summary matches in-game results
   - ✅ Review category breakdown

8. **Run detailed analysis**:
   ```powershell
   .\utilities\AnalyzeAPIDump.ps1 -Detailed
   ```
   - ✅ Check `API_Analysis\` folder was created
   - ✅ Review the markdown report
   - ✅ Check the raw Lua export

### Phase 3: Data Review (10 minutes)

9. **Open SavedVariables file**:
   ```
   <YOUR_WOW_PATH>\WTF\Account\<YOUR_ACCOUNT_NAME>\SavedVariables\AscensionVanity.lua
   ```
   - ✅ Search for `APIDump = {`
   - ✅ Find `totalItems =` and note the count
   - ✅ Search for `ValidationResults = {`
   - ✅ Find `apiOnly = {` section
   - ✅ Review first few missing items

10. **Document findings** in this file (add to bottom):
    - Total API items: [NUMBER]
    - Total DB items: [NUMBER]
    - Missing items: [NUMBER]
    - Mismatches: [NUMBER]
    - Sample missing items: [LIST A FEW]

### Phase 4: Database Generation (Optional - 10 minutes)

11. **Generate updated database**:
    ```powershell
    .\utilities\UpdateDatabaseFromAPI.ps1 -Backup
    ```
    - ✅ Verify backup was created
    - ✅ Check `VanityDB_Updated.lua` was generated
    - ✅ Note total mappings count

12. **Compare databases**:
    ```powershell
    # Use your favorite diff tool
    code --diff .\AscensionVanity\VanityDB.lua .\AscensionVanity\VanityDB_Updated.lua
    ```
    - ✅ Review added items
    - ✅ Check for changed mappings
    - ✅ Verify format is correct

---

## 📊 What to Look For

### Expected Results
- **API Total**: ~2000 items (could be more/less)
- **Database Total**: 1857 items (current count)
- **Missing Items**: ~144 items (the ones we're looking for!)
- **Mismatches**: Unknown (hopefully small number)

### Key Questions to Answer
1. How many items are in the API total?
2. How many items are missing from our database?
3. Are the missing items distributed across all categories or concentrated?
4. Are there any unexpected mismatches?
5. Do the item names look correct in the API dump?

---

## �️ Developer Tools Available

### Ascension Developer Addons (ENABLED)
You have access to powerful development tools:

1. **Ascension API Documentation**
   - Browse available APIs and functions
   - Real-time documentation lookup
   - Useful for: Discovering new C_VanityCollection functions

2. **Ascension UI Development Tools**
   - Frame inspection and debugging
   - UI element analysis
   - Useful for: Debugging our addon's UI components

3. **Ascension Resources For Custom UI**
   - Custom UI resources and helpers
   - Additional development utilities

### 🎮 Dev Console Commands

**Opening the Dev Console**:
- Look for console commands in the UI Development Tools addon
- Typical commands: `/console`, `/devconsole`, or button in addon menu

**Useful Console Commands for Testing**:
```lua
-- Test API availability
C_VanityCollection.GetAllSourceInfo()

-- Inspect specific creature
C_VanityCollection.GetItemInfo(123, 1) -- Replace with real CreatureID

-- Check if function exists
print(type(C_VanityCollection))

-- Dump all C_VanityCollection functions
for k,v in pairs(C_VanityCollection) do 
  print(k, type(v)) 
end

-- Quick validation check
/av validate

-- Get specific item details
/av iteminfo 12345 -- Replace with ItemID

-- Check category stats
/av stats
```

**Advanced Debugging**:
```lua
-- Enable verbose logging
AscensionVanity.DEBUG = true

-- Watch API calls in real-time
hooksecurefunc(C_VanityCollection, "GetAllSourceInfo", function()
  print("GetAllSourceInfo called!")
end)

-- Inspect our database
/dump AscensionVanityDB

-- Check loaded item count
/dump #AscensionVanityDB.creatureToItem
```

---

## �🐛 Troubleshooting

### If `/av apidump` fails
- Check if `C_VanityCollection` API exists: `/av api`
- Make sure you're logged into Project Ascension (not retail WoW)
- Try `/reload` and run again

### If PowerShell script can't find SavedVariables
- Update the path in the script: `-SavedVariablesPath "YOUR_PATH"`
- Default path: `<YOUR_WOW_PATH>\WTF\Account\<YOUR_ACCOUNT_NAME>\SavedVariables\AscensionVanity.lua`
- Make sure you ran `/reload` after `/av apidump`

### If validation shows 0 matches
- Make sure VanityDB.lua is loaded (check addon is enabled)
- Run `/av debug` to verify database is loaded
- Try `/reload` and run `/av validate` again

---

## 📝 Report Your Findings Here

### Test Results (Fill in after testing)

**Date Tested**: _______________  
**Character**: _______________

**API Dump Results**:
- Total items in API: _______________
- Categories found: _______________
- Processing time: _______________

**Validation Results**:
- API Total Items: _______________
- Database Total Items: _______________
- Exact Matches: _______________
- Missing Items (API only): _______________
- Mismatches: _______________

**Sample Missing Items** (first 5):
1. [CreatureID] Item [ItemID]: _______________
2. [CreatureID] Item [ItemID]: _______________
3. [CreatureID] Item [ItemID]: _______________
4. [CreatureID] Item [ItemID]: _______________
5. [CreatureID] Item [ItemID]: _______________

**Sample Mismatches** (if any):
1. Creature [ID]: API has [ItemID], DB has [ItemID]
2. _______________

**PowerShell Analysis**:
- Script ran successfully: ☐ Yes ☐ No
- Reports generated: ☐ Yes ☐ No
- Data looks correct: ☐ Yes ☐ No

**Database Generation**:
- Updated database created: ☐ Yes ☐ No
- Total mappings in new DB: _______________
- Looks ready to use: ☐ Yes ☐ No

**Issues Encountered**:
- _______________
- _______________

**Additional Notes**:
- _______________
- _______________

---

## 🎉 After Testing

Once you've completed testing and documented results:

1. **Review the findings** and verify everything looks correct
2. **Decide next steps**:
   - Option A: Use generated database immediately (if it looks good)
   - Option B: Manually review missing items first
   - Option C: Investigate mismatches before updating

3. **Update this repository**:
   - Add your test results to this file
   - Update PROJECT_STATUS.md with validation findings
   - Commit the documentation updates

4. **Let me know the results** and we can:
   - Fix any issues discovered
   - Update the database with missing items
   - Prepare for v2.1 release

---

## 📚 Documentation Reference

- **Full Guide**: [docs/guides/API_VALIDATION_GUIDE.md](../guides/API_VALIDATION_GUIDE.md)
- **Quick Reference**: [docs/guides/API_QUICK_REFERENCE.md](../guides/API_QUICK_REFERENCE.md)
- **Session Notes**: [docs/SESSION_NOTES_2025-10-27_API_VALIDATION.md](SESSION_NOTES_2025-10-27_API_VALIDATION.md)

---

**Ready to test? Let's find those 144 missing items! 🔍**
