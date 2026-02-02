# 🔧 Development Workflow & Build Rules

**Last Updated:** February 3, 2026, 2:06 AM IST  
**Purpose:** Guidelines for AI assistants and contributors working on ExpenWall Mobile

---

## 🚨 CRITICAL RULES - READ FIRST

### ⚠️ Rule #1: Phase-Based Commits (MOST IMPORTANT)

**❌ NEVER DO THIS:**
```
Update file1.dart → Commit → Push
Update file2.dart → Commit → Push  
Update file3.dart → Commit → Push
Update file4.dart → Commit → Push
```
**Result:** 4 commits, cluttered history, confusing progress tracking

**✅ ALWAYS DO THIS:**
```
Update ALL files needed for Phase 1
Batch into ONE commit with clear message
Push ONCE: "feat: Phase 1 Complete - [Feature Name]"
```
**Result:** 1 clean commit per phase, clear milestones, organized history

### 🎯 Commit Strategy

#### Phase Completion Commits
When working on a feature with multiple files/changes:

1. **Identify the phase scope** - What files need to be updated for this phase?
2. **Make ALL changes** - Update/create all necessary files
3. **Test locally if possible** - Verify syntax, no obvious errors
4. **Commit ONCE** with descriptive message:
   ```
   feat: Phase 1 Complete - Split Bills Core Models
   feat: Phase 2 Complete - Split Bills Service Logic  
   feat: Phase 3 Complete - Split Bills UI Screens
   ```
5. **Push ONCE** - All phase changes together

#### When to Make Individual Commits
- **Bug fixes** - One commit per bug fix
- **Documentation updates** - Can be separate
- **Small tweaks** - After user testing, minor adjustments
- **Emergency hotfixes** - Critical production issues

---

## 🏗️ Build Trigger Rules

### Current Workflow Configuration
Location: `.github/workflows/build-apk.yml`

**Builds ONLY trigger on:**
1. **Version Tags** - `v*.*.*` (e.g., v2.3.1, v2.4.0)
2. **Manual Trigger** - Via GitHub Actions UI

**Builds DO NOT trigger on:**
- Regular commits to main
- Code updates during development
- Documentation changes
- Any normal pushes

### When to Create Version Tags

**Only create version tags when:**
1. ✅ All phases for the version are complete
2. ✅ User has tested and approved the functionality
3. ✅ User explicitly says: "Ready to release" or "Build final APK"
4. ✅ PROGRESS.md shows feature is marked complete
5. ✅ No known critical bugs

**How to create version tags:**
```bash
# After all changes are committed and pushed
git tag v2.3.1
git push origin v2.3.1
```

**Tag naming convention:**
- Major release: `v3.0.0` (Breaking changes, major features)
- Minor release: `v2.4.0` (New features, no breaking changes)
- Patch release: `v2.3.1` (Bug fixes, small improvements)

---

## 📋 Phase-Based Development Process

### Example: Adding Split Bills Feature

**Phase 1: Core Models**
- Create `models/split_bill.dart`
- Create `models/participant.dart`
- Create `models/contact.dart`
- Create `models/group.dart`
- **ONE COMMIT:** "feat: Phase 1 Complete - Split Bills Core Models"
- **ONE PUSH**

**Phase 2: Service Logic**
- Create `services/split_bill_service.dart`
- Create `services/contact_service.dart`
- Update `services/local_storage_service.dart`
- **ONE COMMIT:** "feat: Phase 2 Complete - Split Bills Service Logic"
- **ONE PUSH**

**Phase 3: UI Screens**
- Create `screens/split_bills_screen.dart`
- Create `screens/create_split_bill_screen.dart`
- Create `screens/bill_details_screen.dart`
- Create `screens/contacts_screen.dart`
- Create `screens/groups_screen.dart`
- **ONE COMMIT:** "feat: Phase 3 Complete - Split Bills UI Screens"
- **ONE PUSH**

**Phase 4: Integration & Fixes**
- Update navigation in `home_screen_v2.dart`
- Fix any build errors
- Update `pubspec.yaml` if needed
- **ONE COMMIT:** "feat: Phase 4 Complete - Split Bills Integration"
- **ONE PUSH**

**After All Phases:** User tests → Approves → Create `v2.3.1` tag → Auto-builds APK

---

## 🧪 Testing Workflow

### During Development
1. **User can request early APK** - Manually trigger build from Actions tab
2. **User tests phase** - Provides feedback
3. **Fix issues** - Make fixes as needed (can be individual commits for bug fixes)
4. **Continue to next phase** - Once user approves

### Final Testing
1. **All phases complete**
2. **User says "Ready to test"**
3. **Manual build trigger** OR **version tag** created
4. **User downloads APK** from GitHub Actions artifacts
5. **User tests thoroughly**
6. **User approves** OR **reports issues**
7. **If approved:** Tag as official release version

---

## 📝 Documentation Requirements

### Always Update These Files

**PROGRESS.md** - After EVERY phase completion:
- Mark phase as complete ✅
- Update status percentages
- Add completion timestamps
- Document any known issues
- Update roadmap if needed

**Commit Messages** - Use conventional commits:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation
- `refactor:` - Code refactoring
- `test:` - Testing
- `ci:` - CI/CD changes
- `chore:` - Maintenance

---

## 🚀 Release Checklist

Before creating a version tag:

- [ ] All planned phases complete
- [ ] PROGRESS.md updated
- [ ] No syntax errors (all files compile)
- [ ] User has tested early APK (if applicable)
- [ ] User explicitly approved for release
- [ ] Version number decided (major.minor.patch)
- [ ] Commit message follows convention
- [ ] All changes pushed to main

**Then and only then:**
```bash
git tag v2.X.X
git push origin v2.X.X
```

---

## 🤖 For AI Assistants

### When Starting Work on This Project

1. **Read this file FIRST** - Understand the workflow
2. **Check PROGRESS.md** - See what's already done
3. **Ask user:** "Which phase/feature should I work on?"
4. **Plan the phase:** List all files that need updating
5. **Execute:** Make ALL changes needed for the phase
6. **Commit ONCE:** With clear phase completion message
7. **Update PROGRESS.md** - Mark phase complete
8. **Ask user:** "Phase X complete. Test now or continue to Phase Y?"

### Never Forget

- ⚠️ **1 Phase = 1 Commit = 1 Push**
- ⚠️ **Never auto-create version tags** - User must approve
- ⚠️ **Always batch file updates** per logical phase
- ⚠️ **Update PROGRESS.md** after every phase
- ⚠️ **Wait for user approval** before tagging releases

---

## 📊 Success Metrics

**Good Workflow:**
- Clean commit history (5-10 commits per major feature)
- Clear phase boundaries
- User can test at any phase
- Easy to rollback if needed
- Organized GitHub Actions history

**Bad Workflow:**
- 50+ commits for one feature
- Unclear what each commit does
- APK builds on every tiny change
- Wasted GitHub Actions minutes
- Confused project state

---

## 🎯 Current Project Status

**Active Version:** v2.3.1 (Split Bills - In Development)  
**Last Phase Completed:** Phase 4 - Integration & Build Fixes  
**Next Action:** User testing → If approved → Tag v2.3.1  
**Check:** PROGRESS.md for detailed status

---

## 📞 Questions?

If unsure about:
- Whether to commit now or wait
- If a phase is complete
- When to trigger builds
- Version numbering

**Always ask the user first!**

---

**Remember:** This workflow exists to:
- ✅ Save GitHub Actions minutes
- ✅ Keep commit history clean
- ✅ Make testing easier
- ✅ Allow rollbacks per phase
- ✅ Track progress clearly

**Follow these rules strictly!**
