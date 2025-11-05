# Data Integrity Issues - To Investigate

## Issue 1: Player Pet Showing as Farmable (Nov 5, 2025)

**Symptom**: Another player's companion pet (Snappy - Scorpid) is showing vanity item drop information in tooltip

**Details from Screenshot**:
- Pet Name: "Snappy"
- Pet Type: "Scorpid" 
- Shows: "Vanity Items: Draconic Warhorn: Draconic Mageborn"
- Item ID shown: 1180235
- Creature ID shown: 6129

**Likely Causes**:
1. **Creature ID collision**: NPC Creature ID 6129 might be shared between:
   - A player companion pet (Scorpid battle pet)
   - An actual farmable NPC that drops Draconic Mageborn
   
2. **Item/Creature mapping issue**: The mapping between item 1180235 and creature 6129 might be incorrect

3. **Pet vs NPC distinction**: The addon may not be filtering out companion pets properly

**Investigation Steps** (After enrichment complete):
1. Check item 1180235 in database: `$d=Get-Content data\MasterFullValidated.json -Raw|ConvertFrom-Json;$d|?{$_.DbItemId -eq 1180235}`
2. Verify creature 6129 on db.ascension.gg: https://db.ascension.gg/?npc=6129
3. Check if this is a systematic issue (other player pets triggering false positives)
4. Review creature type filtering logic in Core.lua tooltip handler

**Root Cause Identified**:
The tooltip logic in `Core.lua` was only checking `UnitIsPlayer()` but not filtering out companion pets and player-controlled minions. Companion pets share creature IDs with farmable NPCs, causing false positives.

**Fix Applied** (Nov 5, 2025):
Added proper filtering in `Core.lua` line 342:
```lua
-- Filter out companion pets and player-owned units
if UnitIsOtherPlayersPet(unit) or (UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
    DebugPrint("Skipping player pet/minion:", UnitName(unit), "CreatureID:", creatureID)
    return
end
```

This now properly excludes:
- Other players' companion pets (`UnitIsOtherPlayersPet`)
- Player-controlled minions (warlock pets, hunter pets, etc.)
- While still allowing farmable NPCs with the same creature ID

**Status**: ✅ Fixed and deployed - Awaiting in-game testing

**Priority**: Medium (affects user experience, but limited scope)

---

## Issue 2: Manual Enrichments Not Being Applied

**Status**: In progress
- ManualResearch.json has 26 entries
- Need to properly merge into Manual_Enrichments.json
- Re-run enrichment pipeline after merge

---

*Add new data integrity issues above this line*
