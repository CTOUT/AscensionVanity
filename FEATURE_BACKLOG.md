# Feature Backlog - AscensionVanity

## Priority: Medium - Data Consistency

### Zone vs Subzone Standardization in Descriptions

**Status**: Deferred until stable master UI is implemented

**Current Situation**:
- Database has both `zone` and `subzone` fields
- Descriptions inconsistently reference zones vs subzones
- Examples:
  - "within Dustfire Valley" (subzone) vs "within Searing Gorge" (zone)
  - "within Wyrmskull Village" (subzone) vs "within Howling Fjord" (zone)
  - Some items correctly use both (zone field + subzone field)

**Proposal**:
Standardize all descriptions to use ZONE names only, while preserving subzone data in the `subzone` field:

```json
{
  "description": "Has a chance to drop from Tempered War Golem within Searing Gorge",
  "zone": "Searing Gorge",
  "subzone": "Dustfire Valley"
}
```

**Benefits**:
- ✅ Consistent player experience (descriptions always reference main zones)
- ✅ More accessible for players (zones are easier to find than subzones)
- ✅ Preserves detailed location data in structured fields
- ✅ Regional Guide can filter by zone OR subzone
- ✅ Database Browser can show both zone and subzone

**Implementation**:
1. Create mapping of all subzones → parent zones
2. Update description generation in `GenerateVanityDB_Master.ps1`
3. Ensure `zone` field = parent zone, `subzone` field = specific location
4. Update `EnrichZoneData.ps1` to populate both fields correctly
5. Test Regional Guide filtering with new structure

**Effort**: Medium (2-3 hours)
- Zone mapping creation: 1 hour
- Script updates: 1 hour
- Testing and validation: 1 hour

**Dependencies**:
- Stable master UI (in-game features working correctly)
- Full database coverage (99%+) ✅ Already achieved

**Added**: November 5, 2025
**Priority**: Medium (nice-to-have for v2.3+)

---

## Other Backlog Items

*(Add future feature requests below)*

