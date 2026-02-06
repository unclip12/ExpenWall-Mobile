# 🤖 AI INSTRUCTIONS - READ THIS FIRST!

**📌 CRITICAL:** Any AI assistant working on ExpenWall Mobile MUST read this document first!

---

## 🎯 PROJECT STATUS (February 2026)

### **Current Version: v3.0 - Clean Rebuild (Phase 1 Complete)**

**What happened:**
- ❌ **v2.x is DEPRECATED** - All old code moved to `lib_v2_backup/` (57 files)
- ✅ **v3.0 is ACTIVE** - Complete clean rebuild with modern architecture
- 🚀 **Phase 1 Complete** - Foundation with liquid morphism themes
- 📱 **Next:** Phase 2 - Dashboard Features (A-F)

---

## 📂 DOCUMENTATION STRUCTURE

### **🎯 Active v3.0 Documentation (READ THESE):**

1. **THIS FILE (AI_INSTRUCTIONS.md)** - Master overview
2. **docs/v3/APP_STRUCTURE.md** - Visual blueprint of 5-tab app
3. **docs/v3/REBUILD_PLAN.md** - 6-phase roadmap
4. **docs/v3/TECHNOLOGY_STACK.md** - Modern tech standards
5. **docs/v3/PHASE1_COMPLETE.md** - Phase 1 completion status

### **📦 Archived v2.x Documentation (IGNORE UNLESS NEEDED):**

All old v2 docs are in `docs/archive_v2/`:
- PROGRESS.md (v2 progress)
- BUILD_STATUS.md (v2 build info)
- DEVELOPMENT.md (v2 dev guide)
- ROADMAP.md (old roadmap)
- VERSION_HISTORY.md (v2 history)
- etc.

**⚠️ DO NOT reference v2 docs unless specifically asked about old features!**

---

## 🏗️ CURRENT APP STRUCTURE (v3.0)

### **Active Files (8 files total):**

```
lib/
├── core/
│   └── theme/
│       ├── liquid_theme.dart        # Material 3 themes
│       └── theme_provider.dart      # State management
├── screens/
│   ├── home/
│   │   └── home_screen.dart         # 5-tab navigation
│   └── dashboard/
│       └── dashboard_screen.dart    # Phase 1 placeholder
├── widgets/
│   ├── glass_card.dart              # Glass morphism widget
│   └── coming_soon_screen.dart      # Placeholder screens
├── models/                           # Data models (kept from v2)
├── firebase_options.dart             # Firebase config
└── main.dart                         # v3.0 entry point
```

### **Backup (DO NOT EDIT):**
```
lib_v2_backup/
├── screens/     # 33 old screens
├── services/    # 11 old services
├── widgets/     # 7 old widgets
├── theme/       # 3 old theme files
├── utils/       # 2 old utils
└── main_v2.dart # Old entry point
```

---

## 🎨 DESIGN SYSTEM (v3.0)

### **Liquid Morphism Themes:**

#### **1. Ocean Wave Theme (Default)**
- Primary: Deep Blue (#1976D2)
- Accent: Cyan (#00BCD4)
- Gradient: Blue → Navy Blue → Deep Blue
- Glass effect: Blur 10px, Opacity 10%

#### **2. Sunset Glow Theme**
- Primary: Deep Orange (#FF6F00)
- Accent: Pink (#E91E63)
- Gradient: Orange → Dark Orange → Red-Orange
- Glass effect: Blur 10px, Opacity 10%

### **Key Visual Features:**
- ✨ Glass morphism cards (BackdropFilter blur)
- 🌊 Gradient backgrounds
- 💎 Material 3 design system
- 📳 Haptic feedback everywhere
- 🎯 Rounded corners (24px border radius)
- 🎨 Spring-based animations

---

## 🚀 TECHNOLOGY STACK

### **Core:**
- Flutter 3.24.3+ with Impeller rendering
- Dart 3.5+
- Material 3 (useMaterial3: true)
- Provider for state management

### **UI/UX:**
- BackdropFilter for glass morphism
- AnimatedContainer for smooth transitions
- HapticFeedback for interactions
- BouncingScrollPhysics for iOS-like scroll
- IndexedStack for tab performance

### **Required Packages:**
```yaml
flutter_animate: ^4.5.0          # Animations
rive: ^0.13.0                     # Designer animations
lottie: ^3.1.0                    # After Effects
fl_chart: ^0.68.0                 # Charts for Insights
cached_network_image: ^3.3.0      # Image caching
firebase_core: ^2.24.2            # Firebase
firebase_auth: ^4.16.0
cloud_firestore: ^4.14.0
provider: ^6.1.0                  # State management
```

**See docs/v3/TECHNOLOGY_STACK.md for complete details!**

---

## 📋 DEVELOPMENT PHASES

### **✅ Phase 1: Foundation (COMPLETE - Feb 5, 2026)**
**Status:** Deployed to Firebase, testing in progress

**What was built:**
- Liquid morphism theme system (2 themes)
- Glass morphism widgets
- 5-tab bottom navigation
- Home screen with IndexedStack
- Coming Soon placeholder screens (4 tabs)
- Dashboard showing Phase 1 status
- Material 3 enabled
- Haptic feedback

**Files created:** 8 new files

---

### **🟡 Phase 2: Dashboard Features (NEXT)**
**Status:** Waiting for Phase 1 approval

**Features to build (in order):**

#### **A. Welcome + Total Balance** (Build first)
- Time-based greeting (Morning/Afternoon/Evening)
- User name from Firebase
- Total balance with animated counter
- Currency: ₹ (Indian Rupee)

#### **B. Financial Overview Card**
- Income/Expense for current month
- Visual comparison bars
- Percentage indicators
- Glass morphism card

#### **C. Spending Chart (7 Days)**
- Bar chart using fl_chart
- Last 7 days spending
- Interactive tooltips
- Smooth animations

#### **D. Budget Summary Cards**
- Top 3 active budgets
- Progress bars
- Budget vs spent
- Warning indicators

#### **E. Recent Transactions (Top 5)**
- Latest 5 transactions
- Swipeable cards
- Category icons
- Amount with color coding

#### **F. Add Transaction FAB + Bottom Sheet**
- Floating Action Button
- Glass morphism bottom sheet
- Quick add form
- Category selection
- Amount input with formatter

**See docs/v3/REBUILD_PLAN.md for complete details!**

---

### **Phase 3-6: (Future)**
- Phase 3: Expenses Tab
- Phase 4: Planning Tab
- Phase 5: Social Tab
- Phase 6: Insights Tab

---

## 🎯 AI ASSISTANT RULES

### **✅ ALWAYS DO:**

1. **Check Phase Status First**
   - Read docs/v3/PHASE1_COMPLETE.md to see current status
   - Don't start Phase 2 until Phase 1 is approved

2. **Follow Technology Standards**
   - Read docs/v3/TECHNOLOGY_STACK.md
   - Use Material 3 (useMaterial3: true)
   - Use const constructors everywhere
   - Add haptic feedback to all interactions
   - Use glass morphism for cards

3. **Follow App Structure**
   - Read docs/v3/APP_STRUCTURE.md
   - Keep 5-tab structure
   - Don't modify Phase 1 foundation

4. **Build Features One at a Time**
   - Never build multiple features at once
   - Complete → Test → Approve → Next
   - Follow the exact order in REBUILD_PLAN.md

5. **Use Codespace Terminal Method**
   - Let user edit in GitHub Codespace
   - Provide commands one by one
   - Saves API calls
   - Faster than GitHub API

6. **Test Before Moving On**
   - Every feature must be tested on Samsung S21 FE
   - Get user approval before next feature
   - Fix issues immediately

### **❌ NEVER DO:**

1. **Don't Reference v2 Code**
   - v2 is deprecated
   - Don't look at lib_v2_backup/ unless asked
   - Don't suggest v2 patterns

2. **Don't Skip Phases**
   - Must complete Phase 1 before Phase 2
   - Must complete Phase 2 before Phase 3
   - Each phase builds on previous

3. **Don't Break Foundation**
   - Don't modify liquid_theme.dart
   - Don't change home_screen.dart navigation
   - Don't touch glass_card.dart

4. **Don't Use Old Packages**
   - No old theme packages
   - No deprecated packages
   - Follow TECHNOLOGY_STACK.md packages only

5. **Don't Build Without Design**
   - Every feature has specs in REBUILD_PLAN.md
   - Follow the exact design
   - Don't improvise UI

6. **Don't Push Directly**
   - Use Codespace terminal method
   - Let user commit and push
   - Saves API calls

---

## 🔑 GITHUB SECRETS (Configured)

All secrets are set up in GitHub Actions:
- ✅ FIREBASE_APP_ID
- ✅ FIREBASE_SERVICE_ACCOUNT_JSON
- ✅ FIREBASE_OPTIONS_DART
- ✅ GOOGLE_SERVICES_JSON
- ✅ KEYSTORE_BASE64
- ✅ KEYSTORE_PASSWORD
- ✅ KEY_ALIAS
- ✅ KEY_PASSWORD

**Workflow:** `.github/workflows/build-apk.yml`
- Builds on every push to main
- Auto-deploys to Firebase App Distribution
- Sends notification to Samsung S21 FE

---

## 📱 TESTING DEVICE

**Primary:** Samsung Galaxy S21 FE
- Android 14
- 120Hz display
- Installed via Firebase App Distribution

---

## 💬 USER PREFERENCES

### **Working Style:**
- Prefers step-by-step terminal commands
- Uses GitHub Codespaces for editing
- Wants to see visual previews (ASCII art)
- Likes detailed explanations
- Tests on real device before approval

### **Location:**
- Vijayawanda, Andhra Pradesh, India
- Timezone: IST (India Standard Time)
- Currency: ₹ (Indian Rupee)

---

## 📞 QUICK START FOR NEW AI SESSION

### **Step 1: Check Current Status**
```bash
# In GitHub Codespace:
cat docs/v3/PHASE1_COMPLETE.md
```

### **Step 2: Understand Structure**
```bash
find lib/ -name "*.dart" | grep -v models | grep -v v2_backup | sort
```

### **Step 3: Read Active Docs**
- Read docs/v3/APP_STRUCTURE.md
- Read docs/v3/REBUILD_PLAN.md
- Read docs/v3/TECHNOLOGY_STACK.md

### **Step 4: Ask User**
- "Has Phase 1 been tested and approved?"
- "Ready to start Phase 2 Feature A?"
- "Any changes needed to Phase 1?"

---

## 🎯 CURRENT FOCUS (February 2026)

**NOW:** Waiting for Phase 1 approval  
**NEXT:** Build Dashboard Feature A (Welcome + Balance)  
**GOAL:** Complete Phase 2 by end of February

---

## 📊 SUCCESS METRICS

### **Phase 1:**
- ✅ 8 clean files created
- ✅ 57 old files backed up
- ✅ Build succeeds on GitHub Actions
- ✅ Deploys to Firebase automatically
- 🟡 User testing in progress

### **Phase 2:** (Not started yet)
- Build 6 dashboard features
- Each feature tested individually
- User approval for each
- Complete dashboard by end of month

---

## 🔗 IMPORTANT LINKS

- **Repository:** https://github.com/unclip12/ExpenWall-Mobile
- **GitHub Actions:** https://github.com/unclip12/ExpenWall-Mobile/actions
- **Firebase Console:** (User has access)
- **Documentation:** docs/v3/ folder

---

## ⚡ FINAL REMINDER

**Before doing ANYTHING:**
1. ✅ Read this file (AI_INSTRUCTIONS.md)
2. ✅ Check docs/v3/PHASE1_COMPLETE.md
3. ✅ Understand current phase status
4. ✅ Ask user for confirmation
5. ✅ Follow TECHNOLOGY_STACK.md standards
6. ✅ Build one feature at a time
7. ✅ Test before moving on

**Remember:**
- 🎯 v3.0 is a CLEAN rebuild
- ❌ v2.x is deprecated (in lib_v2_backup/)
- ✨ Focus on liquid morphism beauty
- 📱 Test on Samsung S21 FE
- 🚀 Build features incrementally

---

**Last Updated:** February 6, 2026, 11:49 PM IST  
**Status:** Phase 1 Complete, Testing in Progress  
**Next:** Phase 2 Feature A (Pending Approval)

**🤖 AI: You are now fully briefed on ExpenWall Mobile v3.0!**
