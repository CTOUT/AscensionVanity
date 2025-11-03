# Description Enrichment - Quick Start Guide

## 🚀 Single Command Enrichment

Run this ONE command to enrich all empty descriptions:

```powershell
.\utilities\MasterDescriptionEnrichment.ps1
```

That's it! The script will:
1. ✅ Find all items with empty descriptions
2. ✅ Search db.ascension.gg for zones
3. ✅ Fallback to Wowhead WOTLK if needed
4. ✅ Apply updates to VanityDB.lua
5. ✅ Generate comprehensive reports
6. ✅ List items needing manual research

## Expected Results

**Automation Success Rate:** 95-97%  
**Typical Run Time:** 30-60 seconds (with rate limiting)  
**Final Completion:** 99.5%+ coverage

## Output Files

All files saved to `data/` folder:

- **Enrichment_Results_{timestamp}.csv** - Complete search results
- **Enrichment_Data_{timestamp}.json** - Successful enrichments
- **Manual_Research_Needed_{timestamp}.txt** - Items to research manually

## Optional: Preview Mode

Test without making changes:

```powershell
.\utilities\MasterDescriptionEnrichment.ps1 -WhatIf
```

## Optional: Custom Rate Limiting

Adjust delay between requests (default 2 seconds):

```powershell
.\utilities\MasterDescriptionEnrichment.ps1 -RateLimitSeconds 3
```

## Manual Research

If items need manual research (typically 1-5 items):

1. Check `Manual_Research_Needed_{timestamp}.txt`
2. Search for the NPC on:
   - https://db.ascension.gg
   - https://www.wowhead.com/wotlk
   - In-game screenshots
3. Note the zone/location
4. Manually update VanityDB.lua:
   ```lua
   ["description"] = "Has a chance to drop from {NPC} within {Zone}"
   ```

## Common Manual Research Scenarios

- **Ascension-Specific NPCs:** Not on Wowhead, need in-game verification
- **Special Spawns:** Etherium Prison, event triggers
- **Rewards/Promos:** Shop items, promotional content
- **Not Yet Implemented:** NPC doesn't exist in database

## Full Documentation

For complete details, see:
- `docs/MASTER_ENRICHMENT_WORKFLOW.md` - Comprehensive guide
- `DESCRIPTION_ENRICHMENT_FINAL_REPORT.md` - Project summary

## When to Run

- After generating fresh VanityDB
- After game content updates
- Before release preparation
- When new vanity items are added

## Success Indicators

✅ **99%+ completion** = Excellent, production ready  
✅ **95-99% completion** = Good, minor manual research needed  
⚠️ **<95% completion** = May indicate issues with data sources

---

**Last Updated:** 2025-10-29  
**Current Database Coverage:** 99.95% (2,173/2,174 items)
