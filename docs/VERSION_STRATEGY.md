# AscensionVanity - Version and Release Strategy

**Date:** November 3, 2025  
**Purpose:** Define clear naming conventions to avoid Git ambiguity

---

## 🏷️ Tag vs Branch Naming Convention

### Problem
Git creates ambiguity when branches and tags have the same name (e.g., both named `v2.1-beta`).
- `git push origin v2.1-beta` - Which one? Branch or tag?
- `git checkout v2.1-beta` - Ambiguous!

### Solution: Different Naming Patterns

**Branches:** Use simple version names
```
main
v2.1-beta
v2.2-dev
v2.3-dev
```

**Tags:** Use `release/` prefix
```
release/v2.1-beta
release/v2.2.0
release/v2.3.0-rc1
```

---

## 📋 Naming Conventions

### Branch Names

**Production:**
```
main              # Stable production code
```

**Beta/RC Testing:**
```
v2.1-beta         # Beta testing branch
v2.2-rc1          # Release candidate 1
```

**Development:**
```
v2.2-dev          # Active development
v2.3-dev          # Next version development
```

**Feature Branches (if needed):**
```
feature/minimap-button
fix/tooltip-lag
refactor/database-schema
```

### Tag Names

**Format:** `release/vX.Y[-suffix]`

**Stable Releases:**
```
release/v2.0.0    # Stable production
release/v2.1.0    # Stable production
release/v2.2.0    # Stable production
```

**Pre-releases:**
```
release/v2.1-beta       # Beta testing
release/v2.2-rc1        # Release candidate 1
release/v2.2-rc2        # Release candidate 2
release/v2.3-alpha      # Alpha testing
```

**Hotfixes:**
```
release/v2.1.1    # Hotfix for v2.1
release/v2.1.2    # Another hotfix
```

---

## 🔄 Release Workflow

### 1. Development Phase
```bash
# Work on v2.2-dev branch
git checkout v2.2-dev

# Make changes, commit
git add .
git commit -m "feat: add minimap button"

# Push to remote
git push origin v2.2-dev
```

### 2. Beta Release
```bash
# Create beta branch from dev
git checkout -b v2.2-beta v2.2-dev

# Bump version to beta
# Edit: AscensionVanity.toc, AscensionVanityConstants.lua
# Version: 2.2-beta

git commit -am "release: v2.2-beta"
git push origin v2.2-beta
```

### 3. Create GitHub Release
```bash
# On GitHub:
# 1. Go to Releases → New Release
# 2. Tag: release/v2.2-beta (will be created)
# 3. Target: v2.2-beta branch
# 4. Title: AscensionVanity v2.2-beta
# 5. Description: Copy from RELEASE_NOTES
# 6. Upload ZIP file
# 7. Check "This is a pre-release"
# 8. Publish
```

### 4. Stable Release
```bash
# After testing, promote beta to stable
git checkout v2.2-beta

# Update version to stable
# Edit files: 2.2-beta → 2.2
git commit -am "release: v2.2 stable"

# Merge to main
git checkout main
git merge v2.2-beta
git push origin main

# Create stable release on GitHub:
# Tag: release/v2.2.0
# Target: main
# Uncheck "This is a pre-release"
```

### 5. Continue Development
```bash
# Create next dev branch
git checkout -b v2.3-dev main

# Bump version
# Edit files: 2.2 → 2.3-dev
git commit -am "chore: start v2.3 development"
git push origin v2.3-dev
```

---

## 📊 Version Number Format

### Semantic Versioning
```
vMAJOR.MINOR.PATCH[-SUFFIX]

Examples:
v2.0.0        # Major release
v2.1.0        # Minor release (new features)
v2.1.1        # Patch release (bug fixes)
v2.2-beta     # Beta pre-release
v2.2-rc1      # Release candidate
v2.3-dev      # Development version
```

### What Increments When?

**MAJOR (v2 → v3)**
- Breaking changes
- Complete rewrites
- API changes that break existing code

**MINOR (v2.1 → v2.2)**
- New features
- Non-breaking changes
- Database schema updates
- New UI components

**PATCH (v2.1.0 → v2.1.1)**
- Bug fixes
- Performance improvements
- Documentation updates
- No new features

---

## 🎯 Current Version Strategy

### Active Versions (November 2025)

**Production:**
- `main` branch → Last stable: v2.0

**Beta Testing:**
- `v2.1-beta` branch
- Tag: `release/v2.1-beta` (create on GitHub)

**Development:**
- `v2.2-dev` branch (active)
- Will become `v2.2-beta` → `release/v2.2-beta`

---

## ✅ Checklist: Creating a Release

### Pre-Release
- [ ] All features complete
- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG updated
- [ ] Version bumped in all files

### Release
- [ ] Create release branch (e.g., `v2.2-beta`)
- [ ] Generate release package (`CreateReleasePackage.ps1`)
- [ ] Push branch to GitHub
- [ ] Create GitHub release:
  - Tag: `release/vX.Y-beta` (use prefix!)
  - Target: `vX.Y-beta` branch
  - Upload ZIP file
  - Copy release notes
  - Check pre-release if beta/rc

### Post-Release
- [ ] Test download link
- [ ] Announce release
- [ ] Monitor for issues
- [ ] Create next dev branch

---

## 🚫 What NOT to Do

**❌ Don't use same name for branch and tag:**
```bash
git tag v2.1-beta           # Bad! Same as branch name
git tag release/v2.1-beta   # Good! Different from branch
```

**❌ Don't push tags and branches together:**
```bash
git push origin --tags      # Dangerous! Pushes all tags
git push origin release/v2.1-beta  # Good! Specific tag
```

**❌ Don't reuse tag names:**
```bash
git tag -d v2.1-beta        # Deleting and recreating
git tag v2.1-beta           # is confusing!
```

**❌ Don't forget the prefix:**
```bash
git tag v2.2.0              # Ambiguous
git tag release/v2.2.0      # Clear!
```

---

## 📝 Quick Reference

### Branch Commands
```bash
# List all branches
git branch -a

# Create branch
git checkout -b v2.3-dev

# Push branch
git push origin v2.3-dev

# Delete local branch
git branch -d v2.1-beta

# Delete remote branch
git push origin --delete v2.1-beta
```

### Tag Commands
```bash
# List all tags
git tag

# Create annotated tag
git tag -a release/v2.2-beta -m "v2.2-beta release"

# Push specific tag
git push origin release/v2.2-beta

# Delete local tag
git tag -d release/v2.1-beta

# Delete remote tag
git push origin --delete release/v2.1-beta
```

---

## 🔄 Migration: Fixing Current Setup

### Current Issue (November 2025)
- Branch: `v2.1-beta` ✅
- Tag: `v2.1-beta` ❌ (ambiguous)

### Fix on GitHub Release
When creating the GitHub release:
1. **Tag:** `release/v2.1-beta` (use prefix)
2. **Target:** `v2.1-beta` (branch)
3. This creates the tag automatically with correct name

---

**Last Updated:** November 3, 2025  
**Current Version:** v2.1-beta  
**Next Version:** v2.2-dev
