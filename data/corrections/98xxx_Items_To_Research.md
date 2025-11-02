# 98xxx Creature ID Research Checklist

These 8 items have suspicious creature IDs in the 98765-98773 range and need manual verification.

## Items to Research

### 1. Large Crag Boar (Item 79429)
- **Wrong Creature ID**: 98768
- **Item Link**: https://db.ascension.gg/?item=79429#dropped-by
- **Status**: ❓ Needs Research
- **Correct ID**: _____
- **Source NPC**: _____

### 2. Ice Claw Bear (Item 79452)
- **Wrong Creature ID**: 98767
- **Item Link**: https://db.ascension.gg/?item=79452#dropped-by
- **Status**: ❓ Needs Research
- **Correct ID**: _____
- **Source NPC**: _____

### 3. Snow Leopard (Item 79454)
- **Wrong Creature ID**: 98769
- **Item Link**: https://db.ascension.gg/?item=79454#dropped-by
- **Status**: ❓ Needs Research
- **Correct ID**: _____
- **Source NPC**: _____

### 4. Dire Mottled Boar (Item 79592)
- **Wrong Creature ID**: 98770
- **Item Link**: https://db.ascension.gg/?item=79592#dropped-by
- **Status**: ❓ Needs Research
- **Correct ID**: _____
- **Source NPC**: _____

### 5. Surf Crawler (Item 79595)
- **Wrong Creature ID**: 98771
- **Item Link**: https://db.ascension.gg/?item=79595#dropped-by
- **Status**: ❓ Needs Research
- **Correct ID**: _____
- **Source NPC**: _____

### 6. Aku'mai Snapjaw (Item 79741)
- **Wrong Creature ID**: 98765
- **Item Link**: https://db.ascension.gg/?item=79741#dropped-by
- **Status**: ❓ Needs Research
- **Correct ID**: _____
- **Source NPC**: _____

### 7. The Beast (Item 80089)
- **Wrong Creature ID**: 98772
- **Item Link**: https://db.ascension.gg/?item=80089#dropped-by
- **Status**: ❓ Needs Research
- **Correct ID**: _____
- **Source NPC**: _____

### 8. Elder Springpaw (Item 80300)
- **Wrong Creature ID**: 98773
- **Item Link**: https://db.ascension.gg/?item=80300#dropped-by
- **Status**: ❓ Needs Research
- **Correct ID**: _____
- **Source NPC**: _____

## Research Method

For each item:
1. Click the "Item Link" above
2. Look at the "Dropped by" tab on db.ascension.gg
3. Find the matching NPC name (should match the item name after the colon)
4. Click the NPC name to get its ID from the URL (e.g., `?npc=1234`)
5. Fill in the "Correct ID" and "Source NPC" fields above

## Pattern Analysis

Similar to Prairie Stalker (98766 → 2959), these IDs are likely wrong. The 98xxx range seems to be another API artifact pattern.

## Next Steps

Once research is complete:
1. Add corrections to `CreatureIdCorrections.json`
2. Run `.\utilities\ConvertScanToMasterJson.ps1` to apply
3. Deploy and test

## Notes

- The "Dropped by" section on db.ascension.gg uses JavaScript, so automated scraping is difficult
- Manual verification ensures accuracy
- Similar to the 400xxxx prefix pattern we just fixed
