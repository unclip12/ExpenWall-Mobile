# ExpenWall Mobile - Feature Testing Checklist

Last Updated: February 5, 2026, 3:50 AM IST

Purpose: Systematic testing guide to identify and fix bugs across all features

## How to Use

1. Test sequentially from Phase 1 to Phase 10
2. Mark status: ✅ Working / ⚠️ Minor issues / ❌ Broken / 🚫 Disabled / ⏭️ Not tested
3. Document bugs with expected vs actual behavior
4. Priority: 🔴 Critical (1-3) / 🟡 Important (4-6) / 🟢 Enhanced (7-9) / 🔵 Nice-to-have (10)

---

## PHASE 1: Core Authentication & Navigation 🔴

### 1.1 App Launch & Authentication
- ✅ App launches without crashes
- ✅ Splash screen displays correctly
- 🚫 Secret ID login (DISABLED by design)
- 🚫 Logout functionality (DISABLED by design)

Status: ✅ COMPLETE

### 1.2 Bottom Navigation
- ✅ All 5 tabs visible
- ✅ Tapping tabs switches screens
- ✅ **Main tab horizontal swipe DISABLED** (by design for stability)
- ✅ **Sub-tab horizontal swipe WORKS** (Planning/Social) (FIXED: Feb 5, 2026)
- ✅ **Vertical scrolling WORKS in all screens** (FIXED: Feb 5, 2026)
- ✅ Haptic feedback enhanced (FIXED: Feb 5, 2026)
- ✅ Selected tab indicator works
- ✅ App bar title changes correctly

Status: ✅ COMPLETE

Fixes Applied:
- **Round 1 (9843253b):** Enhanced haptic to mediumImpact
- **Round 2 (bd373d9f):** Fixed scrolling conflicts
  - Main PageView: NeverScrollableScrollPhysics (tap-only navigation)
  - Sub-tab PageViews: PageScrollPhysics (allows swipe)
  - Result: Vertical scrolling restored, sub-tabs swipeable

---

## PHASE 2: Core Transaction Management 🔴

### 2.1 Add Transaction - Basic
- ⏭️ FAB opens transaction bottom sheet
- ⏭️ Bottom sheet displays correctly
- ⏭️ Can enter amount
- ⏭️ Can select type (Expense/Income)
- ⏭️ Can select category
- ⏭️ Can add description
- ⏭️ Can select date
- ⏭️ Save button works
- ⏭️ Bottom sheet closes after save
- ⏭️ Money flow animation plays
- ⏭️ Haptic feedback on save

Status: ⏭️ NOT TESTED

### 2.2 Add Transaction - Advanced
- ⏭️ Can add merchant name
- ⏭️ Merchant auto-suggestions work
- ⏭️ Can add payment method
- ⏭️ Can add location
- ⏭️ Can add tags
- ⏭️ Receipt camera works
- ⏭️ Can add multiple items
- ⏭️ Item-level categorization

Status: ⏭️ NOT TESTED

### 2.3 View Transactions
- ⏭️ Expenses tab shows all transactions
- ⏭️ List loads correctly
- ⏭️ Transactions in correct order
- ⏭️ Cards display all info
- ⏭️ Empty state shows when no data
- ⏭️ Pull-to-refresh works

Status: ⏭️ NOT TESTED

### 2.4 Edit & Delete Transactions
- ⏭️ Tap card opens details
- ⏭️ Edit button works
- ⏭️ Can modify fields
- ⏭️ Save changes works
- ⏭️ Delete button works
- ⏭️ Delete confirmation appears
- ⏭️ Swipe actions work

Status: ⏭️ NOT TESTED

---

## PHASE 3: Dashboard & Overview 🔴

### 3.1 Dashboard Screen
- ⏭️ Dashboard loads without errors
- ⏭️ Total balance displays correctly
- ⏭️ Income/Expense summary accurate
- ⏭️ Text visible in dark mode
- ⏭️ Text visible in light mode
- ⏭️ Recent transactions preview
- ⏭️ Charts display correctly
- ⏭️ Glass card effects render
- ⏭️ Text has proper contrast

Status: ⏭️ NOT TESTED

### 3.2 Financial Overview
- ⏭️ Current month summary accurate
- ⏭️ Balance calculation correct
- ⏭️ Currency symbols display (₹)
- ⏭️ Number formatting correct

Status: ⏭️ NOT TESTED

---

## PHASE 4: Budget Management 🟡

### 4.1 Budget Creation
- ⏭️ Can access budget screen
- ⏭️ Can create new budget
- ⏭️ Can set amount
- ⏭️ Can select category
- ⏭️ Can set period
- ⏭️ Save works

Status: ⏭️ NOT TESTED

### 4.2 Budget Tracking
- ⏭️ Budget list displays
- ⏭️ Progress bar shows percentage
- ⏭️ Remaining amount accurate
- ⏭️ Budget exceeds alert
- ⏭️ Can edit budget
- ⏭️ Can delete budget

Status: ⏭️ NOT TESTED

---

## Testing Progress Summary

Overall: 10% Complete (1/10 phases)

- ✅ Phase 1: Authentication & Navigation - COMPLETE (with bug fixes)
- ⏭️ Phase 2: Core Transactions - Not started
- ⏭️ Phase 3: Dashboard - Not started
- ⏭️ Phase 4: Budget - Not started
- ⏭️ Phase 5: Planning - Not started
- ⏭️ Phase 6: Social - Not started
- ⏭️ Phase 7: Analytics - Not started
- ⏭️ Phase 8: Receipt OCR - Not started
- ⏭️ Phase 9: UI/Themes - Not started
- ⏭️ Phase 10: Settings - Not started

---

## Known Bugs

### Fixed ✅

**Round 1 - Feb 5, 2026, 3:30 AM**
1. Horizontal swipe between main tabs not working (Phase 1.2)
   - **Cause:** ClampingScrollPhysics preventing swipe
   - **Fix:** Changed to BouncingScrollPhysics
   - **Commit:** 9843253b723e5f81641be3d931299435bb523808

2. Weak haptic feedback (Phase 1.2)
   - **Cause:** Using selectionClick (too subtle)
   - **Fix:** Enhanced to mediumImpact
   - **Commit:** 9843253b723e5f81641be3d931299435bb523808

**Round 2 - Feb 5, 2026, 3:50 AM** (Regression fixes)
3. Vertical scrolling broken in all screens (Phase 1.2)
   - **Cause:** BouncingScrollPhysics on main PageView conflicting with child scrolls
   - **Fix:** Changed main PageView to NeverScrollableScrollPhysics
   - **Result:** Navigation via bottom tabs only (more predictable)
   - **Commit:** bd373d9f872d7e55d0969d789baba8de1babda8f

4. Sub-tab horizontal swipe not working (Planning/Social) (Phase 1.2)
   - **Cause:** ScrollPhysics conflict
   - **Fix:** Sub-tab PageViews use PageScrollPhysics
   - **Result:** Can swipe between Budget/Recurring/Buying and SplitBills/Cravings
   - **Commit:** bd373d9f872d7e55d0969d789baba8de1babda8f

5. Insights screen showing empty grey (Phase 7.1)
   - **Cause:** Physics conflict preventing rendering
   - **Fix:** Restored by fixing PageView physics
   - **Commit:** bd373d9f872d7e55d0969d789baba8de1babda8f

### Open ⚠️
(None currently - all Phase 1 bugs fixed)

---

## Navigation Design Decision 📝

**Main Tabs (Bottom Navigation):**
- Controlled by **tapping only** (no swipe)
- Reason: Prevents conflicts with vertical scrolling
- Result: More predictable, stable navigation

**Sub-Tabs (Planning/Social):**
- Controlled by **tapping OR swiping**
- Reason: Fewer conflicts in nested PageViews
- Result: Enhanced UX for related features

---

## Next Testing Session

Target: Phase 2 - Core Transaction Management
Focus: Add, view, edit, delete transactions
Priority: 🔴 Critical

When ready, start new chat with:
"Starting Phase 2 testing. Check TESTING_CHECKLIST.md for context."

---

Repository: github.com/unclip12/ExpenWall-Mobile
