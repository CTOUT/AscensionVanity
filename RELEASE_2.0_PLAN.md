# AscensionVanity v2.0 Stable Release Plan

**Date:** October 30, 2025  
**Current Status:** v2.0-beta on v2.0-dev branch  
**Target:** v2.0 stable release, merge to main, start v2.1-dev

---

## Phase 1: Repository Cleanup ✨

### Files to Archive (Move to `docs/archive/development-logs/`)
These are valuable development records but clutter the root:

- `ACTION_PLAN_2025-10-29.md`
- `APPEARANCE_COLLECTED_DISCOVERY.md`
- `APPEARANCE_COLLECTED_TEST_PLAN.md`
- `BUG_FIXES_2025-10-28.md`
- `CACHE_IMPLEMENTATION_SUMMARY.md`
- `CACHE_OPTIMIZATION_FALLBACK_FIX.md`
- `CACHE_QUICK_REFERENCE.md` (move to `docs/guides/`)
- `CACHE_STRATEGY_FINAL.md`
- `CACHE_STRATEGY_REALITY_CHECK.md`
- `CACHE_STRATEGY_UPDATED.md`
- `CACHE_TESTING_GUIDE.md` (move to `docs/guides/`)
- `CACHE_UPDATE_OCT30.md`
- `DESCRIPTION_ENRICHMENT_COMPLETE.md`
- `DESCRIPTION_ENRICHMENT_FINAL_REPORT.md`
- `EMPTY_DESCRIPTION_ISSUE.md`
- `EVENT_VALIDATION_RESULTS.md`
- `EVENT_VALIDATION_TEST.md`
- `FRESH_SCAN_CLARIFICATION.md`
- `FRESH_SCAN_READY.md`
- `IN_GAME_SCANNING_COMPLETE.md`
- `IN_GAME_TESTING_GUIDE.md` (move to `docs/guides/`)
- `MANUAL_ENRICHMENT_COMPLETE.md`
- `QUOTE_ESCAPING_FIX_COMPLETE.md`
- `QUOTE_ESCAPING_FIX_TEST_PLAN.md`
- `REPOSITORY_ORGANIZATION_COMPLETE.md`
- `SCRIPT_CONSOLIDATION_SUMMARY.md`
- `TOOLTIP_ICON_FIX.md`
- `VANITYDB_GENERATION_COMPLETE.md`
- `VANITYDB_GENERATION_FINAL.md`
- `UPGRADE_v2.1-beta.md`

### Files to Delete (Temporary/Test Files)
- `100` (unknown file)
- `strigid_owl_page.html` (test file)
- `temp_drops.txt`
- `temp_listview.txt`
- `validation_log.txt`

### Files to Keep in Root
Essential project files that belong in root:
- `README.md` ✅
- `CHANGELOG.md` ✅
- `LICENSE` ✅
- `FEATURE_ROADMAP_V2.1.md` ✅ (future planning)
- `.gitignore` ✅
- `*.ps1` scripts ✅ (deployment and utilities)
- `local.config.example.ps1` ✅

### Directories to Reorganize

**Current Structure:**
```
├── API_Analysis/          # Keep but move to docs/development/
├── AscensionVanity/       # ✅ Core addon (keep in root)
├── data/                  # ✅ Database files (keep in root)
├── docs/                  # ✅ Documentation (keep, reorganize)
├── releases/              # ✅ Release artifacts (keep in root)
├── utilities/             # ✅ Scripts (keep in root)
```

**Proposed Final Structure:**
```
AscensionVanity/
├── .github/               # GitHub workflows
├── AscensionVanity/       # Core addon code
├── data/                  # Database and mapping files
├── docs/                  # All documentation
│   ├── guides/            # User guides
│   ├── development/       # Developer docs
│   │   ├── api-analysis/  # API scan results
│   │   └── logs/          # Development logs (archived)
│   └── images/            # Screenshots, diagrams
├── releases/              # Release artifacts
├── utilities/             # PowerShell scripts
├── CHANGELOG.md           # Version history
├── README.md              # Main documentation
├── LICENSE                # MIT License
└── *.ps1                  # Deployment scripts
```

---

## Phase 2: Pre-Release Validation ✅

### Code Quality Checks
- [ ] Review all Lua files for TODOs or debug code
- [ ] Verify all features work as documented
- [ ] Test cache system thoroughly
- [ ] Verify database integrity (2,174 items)
- [ ] Check for any hardcoded paths or test values

### Documentation Review
- [ ] Update README.md with v2.0 features
- [ ] Finalize CHANGELOG.md for v2.0
- [ ] Verify installation instructions
- [ ] Update feature list
- [ ] Add screenshots (if available)

### Testing Checklist
- [ ] Fresh installation test
- [ ] Upgrade from v1.x test
- [ ] Tooltip display verification
- [ ] Icon display verification
- [ ] Configuration UI test
- [ ] Cache performance test
- [ ] Database loading test
- [ ] Memory usage check

---

## Phase 3: Version Finalization 📝

### Update Version Numbers
Files to update to `2.0`:

1. **AscensionVanity/AscensionVanity.toc**
   - `## Version: 2.0`
   - `## Notes: Major release with database enrichment and cache system`

2. **CHANGELOG.md**
   - Add v2.0 release section with date
   - Summarize all changes since v1.x

3. **README.md**
   - Update version badge (if present)
   - Update feature list
   - Update statistics (2,174 items, 99.95% description coverage)

### Git Preparation
```powershell
# Ensure we're on v2.0-dev branch
git checkout v2.0-dev

# Commit any final changes
git add .
git commit -m "chore: prepare for v2.0 stable release"

# Tag the release
git tag -a v2.0 -m "Release v2.0 - Database enrichment and cache system"
```

---

## Phase 4: Branch Management 🌿

### Merge to Main
```powershell
# Switch to main branch
git checkout main

# Merge v2.0-dev (squash or merge, your preference)
git merge v2.0-dev -m "Release v2.0 - Major update with enriched database"

# Push to remote
git push origin main
git push origin v2.0  # Push the tag
```

### Create v2.1-dev Branch
```powershell
# Create new development branch from main
git checkout -b v2.1-dev main

# Update version in .toc file to 2.1-alpha
# (sed or manual edit)

# Commit version bump
git commit -am "chore: start v2.1-alpha development"

# Push new branch
git push origin v2.1-dev

# Set upstream tracking
git branch --set-upstream-to=origin/v2.1-dev v2.1-dev
```

### Branch Strategy Going Forward
- **main**: Stable releases only (v2.0, v2.1, v2.2, etc.)
- **v2.1-dev**: Active development for v2.1 features
- **feature/\***: Feature branches for specific work (optional)

---

## Phase 5: Release Creation 📦

### GitHub Release
Create a new release on GitHub:
- **Tag:** v2.0
- **Title:** AscensionVanity v2.0 - Database Enrichment
- **Description:** Copy from CHANGELOG.md v2.0 section
- **Attachment:** `AscensionVanity-v2.0.zip` (addon folder only)

### Release Package Contents
```
AscensionVanity-v2.0.zip
└── AscensionVanity/
    ├── AscensionVanity.toc
    ├── Core.lua
    ├── VanityDB.lua
    ├── VanityDB_Loader.lua
    ├── AscensionVanityConfig.lua
    ├── SettingsUI.lua
    ├── APIScanner.lua
    └── ScannerUI.lua
```

### Release Notes Template
```markdown
# AscensionVanity v2.0 - Database Enrichment

**Release Date:** October 30, 2025

## 🎉 What's New

### Database Improvements
- **2,174 combat pets** fully catalogued
- **99.95% description coverage** (2,173 items with detailed descriptions)
- Rich location information for efficient farming
- Drop source details where available

### Performance Enhancements
- **Intelligent cache system** for instant tooltip updates
- **Lazy loading** for optimized memory usage
- **Smart invalidation** ensures data freshness
- **Fallback mechanisms** for reliability

### User Interface
- Enhanced tooltips with better formatting
- Configuration UI for cache settings
- In-game API scanner for data collection
- Improved icon display system

## 📊 Statistics
- **Total Combat Pets:** 2,174
- **With Descriptions:** 2,173 (99.95%)
- **Unique Creatures:** 1,000+
- **Zones Covered:** All Azeroth, Outland, Northrend

## 📥 Installation
1. Download `AscensionVanity-v2.0.zip`
2. Extract to `World of Warcraft\_retail_\Interface\AddOns\`
3. Restart WoW or `/reload`
4. Enjoy enhanced vanity tooltips!

## 🔄 Upgrading from v1.x
- Automatic migration
- No configuration changes needed
- All learned items preserved

## 🐛 Known Issues
None reported. Please submit issues on GitHub if you encounter problems.

## 🙏 Acknowledgments
Thank you to the Ascension community for testing and feedback!
```

---

## Phase 6: Post-Release Tasks ✨

### Communication
- [ ] Post release announcement in Ascension Discord
- [ ] Update CurseForge/Wago (if applicable)
- [ ] Update GitHub README badges
- [ ] Announce on relevant WoW addon communities

### Archive Old Branch (Optional)
```powershell
# After successful release, optionally delete merged branch
git branch -d v2.0-dev  # Delete local
git push origin --delete v2.0-dev  # Delete remote
```

### Start v2.1 Planning
- [ ] Review FEATURE_ROADMAP_V2.1.md
- [ ] Prioritize Tier 1 features for v2.1
- [ ] Create initial development tasks
- [ ] Set up project board (optional)

---

## Rollback Plan 🚨

If issues are discovered after release:

1. **Revert on main:**
   ```powershell
   git checkout main
   git revert HEAD
   git push origin main
   ```

2. **Create hotfix branch:**
   ```powershell
   git checkout -b hotfix/2.0.1 v2.0
   # Fix issues
   git commit -am "fix: critical bug in cache system"
   git tag v2.0.1
   git checkout main
   git merge hotfix/2.0.1
   git push --all
   git push --tags
   ```

3. **Update release on GitHub with v2.0.1**

---

## Success Criteria ✅

Release is successful when:
- [✓] Repository is clean and organized
- [✓] All tests pass
- [✓] Documentation is current
- [✓] v2.0 tag exists on main branch
- [✓] v2.1-dev branch is active
- [✓] GitHub release is published
- [✓] Community is notified
- [✓] No critical bugs reported within 48 hours

---

## Timeline Estimate

- **Phase 1 (Cleanup):** 30 minutes
- **Phase 2 (Validation):** 1 hour
- **Phase 3 (Versioning):** 15 minutes
- **Phase 4 (Branching):** 15 minutes
- **Phase 5 (Release):** 30 minutes
- **Phase 6 (Post-Release):** 30 minutes

**Total:** ~3 hours for complete process

---

**Ready to proceed?** Let's start with Phase 1: Repository Cleanup! 🧹
