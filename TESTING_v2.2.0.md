# 🧪 ExpenWall Mobile v2.2.0 - Testing Checklist

> Complete testing guide for version 2.2.0

---

## ✅ Testing Checklist

### **1. Bug Fixes** 🐛

#### Edit Transaction (CRITICAL)
- [ ] Open Expenses tab
- [ ] Tap on any transaction
- [ ] Tap "Edit" button
- [ ] **EXPECTED**: Edit screen opens with pre-filled data
- [ ] Modify any field (amount, merchant, etc.)
- [ ] Save changes
- [ ] **EXPECTED**: Changes are reflected in transaction list
- [ ] **BUG FIXED**: No keyboard auto-popup, edit actually works

---

### **2. New Navigation System** 🎯

#### Bottom Navigation - Expandable Tabs
- [ ] Check 5 main tabs visible:
  - Dashboard
  - Expenses
  - Planning
  - Social
  - Insights
- [ ] Tap each tab
- [ ] **EXPECTED**: Selected tab expands to 65%, others shrink to icons
- [ ] **EXPECTED**: Smooth animation, no glitches
- [ ] **EXPECTED**: Only selected tab shows label

#### Planning Sub-Tabs
- [ ] Tap "Planning" tab (calendar icon)
- [ ] **EXPECTED**: Second row of tabs appears with:
  - Budget (65% expanded by default)
  - Recurring (icon only)
  - Buying List (icon only)
- [ ] Tap Recurring icon
- [ ] **EXPECTED**: Recurring expands to 65%, others become icons
- [ ] Tap Buying List icon
- [ ] **EXPECTED**: Buying List expands, others shrink

#### Social Sub-Tabs
- [ ] Tap "Social" tab (people icon)
- [ ] **EXPECTED**: Second row appears with:
  - Split Bills (65% expanded)
  - Cravings (icon only)
- [ ] Tap Cravings
- [ ] **EXPECTED**: Cravings expands to 65%

---

### **3. New Screens** 📱

#### Buying List Screen
- [ ] Navigate to Planning → Buying List
- [ ] **EXPECTED**: Screen shows "Add to Shopping List" form
- [ ] Add item name: "Milk"
- [ ] Add price: "60"
- [ ] Tap add button
- [ ] **EXPECTED**: Item appears in "To Buy" list
- [ ] Tap checkbox on item
- [ ] **EXPECTED**: Item moves to "Purchased" section
- [ ] **EXPECTED**: Summary shows updated counts
- [ ] Delete an item
- [ ] **EXPECTED**: Item removed from list

#### Cravings Screen
- [ ] Navigate to Social → Cravings
- [ ] **EXPECTED**: Screen shows "Add New Craving" form
- [ ] Add name: "Biryani Paradise"
- [ ] Add notes: "Try their chicken biryani"
- [ ] Tap "Add Craving"
- [ ] **EXPECTED**: Item appears in "Want to Try" list
- [ ] Tap checkbox on item
- [ ] **EXPECTED**: Item moves to "Tried & Tested"
- [ ] **EXPECTED**: Shows "Added today" timestamp
- [ ] Delete a craving
- [ ] **EXPECTED**: Item removed

#### Recurring Bills Screen
- [ ] Navigate to Planning → Recurring
- [ ] **EXPECTED**: "Coming Soon in v2.3.0" message
- [ ] **EXPECTED**: Shows planned features list
- [ ] Tap FAB (Floating Action Button)
- [ ] **EXPECTED**: Snackbar says "Coming soon in v2.3.0!"

#### Split Bills Screen
- [ ] Navigate to Social → Split Bills
- [ ] **EXPECTED**: "Coming Soon in v2.3.0" message
- [ ] **EXPECTED**: Shows planned features list
- [ ] Tap FAB
- [ ] **EXPECTED**: Snackbar says "Coming soon in v2.3.0!"

---

### **4. Money Flow Animations** 💸

#### Income Animation
- [ ] Go to Dashboard or Expenses
- [ ] Tap FAB (+ button)
- [ ] Select "Received" (Income)
- [ ] Enter merchant: "Salary"
- [ ] Enter amount: "50000"
- [ ] Save
- [ ] **EXPECTED**: Money particles flow from TOP to BOTTOM
- [ ] **EXPECTED**: Green-colored rupee symbols (₹) and money bags (💰)
- [ ] **EXPECTED**: Heavy flow (50+ particles) for large amount
- [ ] **EXPECTED**: Animation lasts ~2 seconds

#### Expense Animation (Small Amount)
- [ ] Add new transaction
- [ ] Select "Spent" (Expense)
- [ ] Enter merchant: "Coffee"
- [ ] Enter amount: "50"
- [ ] Save
- [ ] **EXPECTED**: Few particles (5-10) flow from CENTER outward
- [ ] **EXPECTED**: Red-colored symbols
- [ ] **EXPECTED**: Light animation for small amount

#### Expense Animation (Large Amount)
- [ ] Add transaction
- [ ] Select "Spent"
- [ ] Enter amount: "15000"
- [ ] Save
- [ ] **EXPECTED**: Heavy money rain (100+ particles)
- [ ] **EXPECTED**: Particles flow outward in all directions
- [ ] **EXPECTED**: Dramatic effect for large amount

---

### **5. Liquid Glass Theme & Background** 🎨

#### Pulsating Gradient
- [ ] Observe background on any screen
- [ ] **EXPECTED**: Gentle wave-like color transitions
- [ ] **EXPECTED**: Smooth, calming animation
- [ ] **EXPECTED**: No jarring color changes
- [ ] Wait 10-15 seconds
- [ ] **EXPECTED**: Continuous breathing effect

#### Floating Currency Symbols
- [ ] Look at background carefully
- [ ] **EXPECTED**: Very subtle Indian rupee (₹) symbols
- [ ] **EXPECTED**: Symbols slowly float upward
- [ ] **EXPECTED**: Barely visible (5-8% opacity)
- [ ] **EXPECTED**: Doesn't interfere with readability

#### Text Visibility
- [ ] Check text on various screens
- [ ] **EXPECTED**: All text is clearly readable
- [ ] **EXPECTED**: Text color adjusts based on background
- [ ] **EXPECTED**: No text hidden behind gradient
- [ ] Switch between screens
- [ ] **EXPECTED**: Consistent visibility everywhere

#### Glass Morphism Cards
- [ ] Look at cards on any screen
- [ ] **EXPECTED**: Frosted glass effect with blur
- [ ] **EXPECTED**: Subtle white border
- [ ] **EXPECTED**: Shadow beneath cards
- [ ] **EXPECTED**: Semi-transparent background

---

### **6. Theme System** 🌈

#### Current Theme (Should be one of 10)
- [ ] Go to Insights (Settings)
- [ ] Check "App Theme" section
- [ ] **EXPECTED**: Shows current theme name and icon
- [ ] Tap on theme card
- [ ] **EXPECTED**: Bottom sheet opens with 10 themes

#### Theme Switching
- [ ] Select a different theme (e.g., Ocean Blue)
- [ ] **EXPECTED**: Immediate color change throughout app
- [ ] **EXPECTED**: Smooth transition
- [ ] Navigate to different screens
- [ ] **EXPECTED**: New theme applied everywhere
- [ ] Try all 10 themes:
  1. Midnight Purple ✅
  2. Ocean Blue ✅
  3. Forest Green ✅
  4. Sunset Orange ✅
  5. Cherry Blossom ✅
  6. Midnight Black ✅
  7. Arctic White ✅
  8. Lavender Dream ✅
  9. Emerald Luxury ✅
  10. Golden Hour ✅

#### Dark Mode
- [ ] Go to Settings → Appearance
- [ ] Toggle Dark Mode ON
- [ ] **EXPECTED**: Darker colors, better contrast
- [ ] **EXPECTED**: Gradient adjusts to dark theme
- [ ] Toggle Dark Mode OFF
- [ ] **EXPECTED**: Returns to light mode

---

### **7. Existing Features (Regression Testing)** ↩️

#### Dashboard
- [ ] View income/expense summary
- [ ] Check recent transactions
- [ ] **EXPECTED**: All data displays correctly

#### Transactions
- [ ] View transaction list
- [ ] Filter by All/Expenses/Income
- [ ] **EXPECTED**: Filters work correctly
- [ ] Swipe to delete still works ✅

#### Budget
- [ ] View existing budgets
- [ ] Add new budget
- [ ] **EXPECTED**: Budget tracking works

#### Products
- [ ] Product price tracking still accessible
- [ ] **EXPECTED**: No regressions

#### Settings
- [ ] All settings sections present
- [ ] Cloud backup still works
- [ ] Manual export/import functional

---

## 📊 **Version Comparison**

### What's New in v2.2.0:
- ✅ Fixed edit transaction bug
- ✅ Expandable tab navigation (65%-35%)
- ✅ Planning tab with 3 sub-screens
- ✅ Social tab with 2 sub-screens
- ✅ Buying List (fully functional)
- ✅ Cravings (fully functional)
- ✅ Money flow animations
- ✅ Pulsating gradient background
- ✅ Floating currency symbols
- ✅ Better liquid glass design

### What's Still From v2.1.0:
- ✅ Smart autocomplete
- ✅ Auto-categorization
- ✅ 10 premium themes
- ✅ Dark/Light mode

---

## 🐛 **Bug Reporting Format**

If you find a bug, report it like this:

**Bug:** Edit button not working  
**Screen:** Transactions → Transaction Details  
**Steps:**
1. Open any transaction
2. Tap Edit button
3. Nothing happens

**Expected:** Edit screen should open  
**Actual:** No response

---

## ✨ **Priority Tests**

**Must Test (Critical):**
1. ✅ Edit transaction works
2. ✅ Navigation expansion animations
3. ✅ Money flow animations appear
4. ✅ New screens load properly
5. ✅ Text is readable on all backgrounds

**Should Test (Important):**
6. ✅ Buying List add/remove items
7. ✅ Cravings add/mark done
8. ✅ Theme switching
9. ✅ Dark mode toggle
10. ✅ Background animations smooth

**Nice to Test:**
11. ✅ Different amount animations
12. ✅ All 10 themes
13. ✅ Floating currency symbols visible

---

**Testing Started:** [Date]  
**Tested By:** [Your Name]  
**Build:** v2.2.0  
**Device:** [Android/iOS, Model]  

**Overall Status:** 🟢 Pass / 🟡 Pass with Minor Issues / 🔴 Failed

---

## 📝 **Notes**

Add any observations, suggestions, or issues here:




---

**Next Version:** v2.3.0 will add Recurring Bills and Split Bills functionality!
