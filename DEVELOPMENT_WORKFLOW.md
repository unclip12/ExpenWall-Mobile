# Development Workflow & Build Rules

**Last Updated:** February 3, 2026, 2:00 AM IST

---

## 🚨 CRITICAL RULES FOR AI ASSISTANTS

### ⚠️ Build Trigger Policy

**APK builds should ONLY be triggered when:**
1. A version tag is created (e.g., `v2.3.1`, `v2.4.0`)
2. Manual trigger is explicitly requested by the user

**APK builds should NEVER be triggered by:**
- Regular commits during development
- Individual file updates
- Incomplete phases
- Documentation changes

---

## 📄 Phase-Based Development Approach

### ✅ CORRECT Workflow:

**When working on a feature/phase:**
1. **Plan:** Identify ALL files that need to be created/updated for the phase
2. **Batch:** Prepare ALL changes locally or in planning
3. **Commit Once:** Push ALL changes in ONE commit with clear message: "Phase X Complete"
4. **Test:** User manually triggers build if testing is needed

**Example:**
```bash
# Phase 1: Analytics Dashboard (5 files needed)
- Create lib/services/analytics_service.dart
- Create lib/models/analytics_data.dart
- Create lib/screens/analytics_screen.dart
- Update lib/screens/home_screen.dart
- Update pubspec.yaml (add chart package)

# ALL files prepared, then ONE commit:
git add .
git commit -m "feat: Analytics Dashboard - Phase 1 Complete

- Added analytics service
- Created analytics data model
- Built analytics screen UI
- Integrated into home screen
- Added charts package"
git push
```

### ❌ INCORRECT Workflow:

**DO NOT do this:**
```bash
# Create service
git add lib/services/analytics_service.dart
git commit -m "Add analytics service"
git push  # ❌ Push 1

# Create model
git add lib/models/analytics_data.dart
git commit -m "Add analytics model"
git push  # ❌ Push 2

# Create screen
git add lib/screens/analytics_screen.dart
git commit -m "Add analytics screen"
git push  # ❌ Push 3

# Result: 3 separate commits for ONE phase ❌
```

---

## 🎯 Phase Completion Checklist

Before pushing a "Phase Complete" commit, verify:

- [ ] **All planned files** for the phase are created/updated
- [ ] **No compilation errors** exist
- [ ] **Dependencies added** to pubspec.yaml (if needed)
- [ ] **Imports are correct** in all files
- [ ] **Code follows existing patterns** in the project
- [ ] **PROGRESS.md updated** with phase completion status
- [ ] **Commit message is descriptive** and mentions "Phase X Complete"

---

## 🚀 Release Workflow

### When a Version is Complete:

1. **User confirms:** "Version is ready" or "Everything works, release it"
2. **AI creates version tag:**
   ```bash
   git tag v2.3.1 -m "Release v2.3.1: Split Bills Feature"
   git push origin v2.3.1
   ```
3. **GitHub Actions automatically builds** the APK
4. **User downloads** from Actions artifacts
5. **User tests** and approves
6. **Optional:** Create GitHub Release with changelog

### Version Tag Format:

- **Major release:** `v3.0.0` (Breaking changes, major features)
- **Minor release:** `v2.4.0` (New features, no breaking changes)
- **Patch release:** `v2.3.1` (Bug fixes, minor improvements)

---

## 🔧 Manual Build Trigger

**When user wants to test during development:**

1. Go to GitHub Actions tab
2. Select "Build Flutter APK" workflow
3. Click "Run workflow" button
4. Select branch (usually `main`)
5. Click green "Run workflow" button
6. Wait 10-15 minutes for build
7. Download APK from Artifacts

**Use manual builds for:**
- Testing after phase completion
- Quick verification during development
- Testing specific commits

---

## 📅 Development Phases Example

### Typical Feature Development:

**Phase 1: Backend/Models** (1 commit)
- Create all model files
- Create all service files
- Add dependencies
- Push: "feat: Feature Name - Phase 1 Backend Complete"

**Phase 2: UI Screens** (1 commit)
- Create all screen files
- Create all widget files
- Push: "feat: Feature Name - Phase 2 UI Complete"

**Phase 3: Integration** (1 commit)
- Update navigation
- Connect screens to services
- Add to main app flow
- Push: "feat: Feature Name - Phase 3 Integration Complete"

**Phase 4: Testing & Fixes** (1 commit)
- Fix all build errors
- Fix all runtime issues
- Push: "feat: Feature Name - Phase 4 Complete & Ready"

**Total:** 4 commits for entire feature, NOT 20+ commits for individual files

---

## 📝 Commit Message Format

### For Phase Completions:
```
feat: <Feature Name> - Phase <X> Complete

<Bullet points of what was added/changed>
- Item 1
- Item 2
- Item 3
```

### For Bug Fixes:
```
fix: <Brief description>

<Details of what was fixed>
```

### For Documentation:
```
docs: <What was documented>

<Details>
```

### For Build/CI Changes:
```
ci: <What was changed in workflow>

<Details>
```

---

## ⚡ GitHub Actions Configuration

### Current Setup:

**File:** `.github/workflows/build-apk.yml`

**Triggers:**
```yaml
on:
  push:
    tags:
      - 'v*.*.*'  # Only version tags
  workflow_dispatch:  # Manual trigger
```

**This means:**
- ✅ Regular pushes to `main` do NOT trigger builds
- ✅ Only version tags trigger automatic builds
- ✅ Manual trigger always available from Actions tab

**DO NOT change this configuration** unless explicitly discussed with the user!

---

## 📊 Benefits of This Approach

### For the Project:
- ✅ **Clean git history** - Easy to see what was done when
- ✅ **Saves CI minutes** - No wasted builds
- ✅ **Clear milestones** - Each commit is meaningful
- ✅ **Easy rollback** - Can revert entire phases if needed
- ✅ **Professional** - Industry standard practice

### For Development:
- ✅ **Efficient testing** - Test complete phases, not fragments
- ✅ **Less noise** - No spam from incomplete work
- ✅ **Better tracking** - PROGRESS.md aligns with commits
- ✅ **Clearer communication** - Know exactly what's done

---

## 👁️ For AI Assistants: Quick Reference

**Before making ANY commits, ask yourself:**

1. **Is this a complete phase?**
   - Yes → Proceed with commit
   - No → Continue working, don't commit yet

2. **Are ALL files for this phase ready?**
   - Yes → Proceed with commit
   - No → Finish remaining files first

3. **Is this a version release?**
   - Yes → Create version tag
   - No → Regular commit only

4. **Does user want to test now?**
   - Yes → Tell them to manually trigger build
   - No → Continue with next phase

**Remember:** 
- Phase = Multiple files = ONE commit
- NOT: File = ONE commit

---

## 📞 Contact & Questions

If there are any questions about this workflow:
1. Refer to this document first
2. Check PROGRESS.md for current status
3. Ask user for clarification if needed

**This document is the source of truth for development workflow!**

---

*This workflow ensures efficient development, clean git history, and optimal use of GitHub Actions resources.*
