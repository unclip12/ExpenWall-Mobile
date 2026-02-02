# 🧪 ExpenWall Mobile - Testing Guide

> **Testing the new features added on February 2, 2026**
> Version 2.1.0 - Smart Features + Theme System

---

## 🔨 BUILD THE APP

### Option 1: GitHub Actions (Automated)
1. Go to: https://github.com/unclip12/ExpenWall-Mobile/actions
2. Wait for the latest workflow to complete
3. Download the APK from Artifacts
4. Install on your Android device

### Option 2: Build Locally
```bash
cd ExpenWall-Mobile
flutter clean
flutter pub get
flutter build apk --release
```
APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## ✅ TESTING CHECKLIST

### 1. App Launch
- [ ] App opens without white screen
- [ ] Splash animation plays smoothly
- [ ] Loads to Dashboard screen
- [ ] No crashes or errors

### 2. Smart Autocomplete

**Test Steps:**
1. Tap the + button (bottom center)
2. Go to "Merchant / Shop / Person" field
3. Type "test" or any text
4. Add a transaction (e.g., "Test Shop", ₹100)
5. Save it
6. Tap + again
7. Type "test" in merchant field

**Expected Results:**
- [ ] As you type, suggestions appear below the field
- [ ] Shows "Test Shop (Used 1 time)"
- [ ] Tapping suggestion auto-fills the field
- [ ] Category and subcategory auto-fill based on previous transaction

**Test with Real Data:**
- [ ] Add "Chicken Biryani" transaction with Food/Restaurant
- [ ] Add another transaction, type "chick"
- [ ] Should show "Chicken Biryani (Used 1 time)"
- [ ] Should auto-set Food/Restaurant when selected

### 3. Wording Changes

**Test Steps:**
1. Open "Add Transaction" screen
2. Look at the Type section

**Expected Results:**
- [ ] Shows "Spent" instead of "Expense"
- [ ] Shows "Received" instead of "Income"
- [ ] Red gradient for "Spent"
- [ ] Green gradient for "Received"

### 4. Animated Type Selector

**Test Steps:**
1. Open "Add Transaction" screen
2. Tap "Spent" button
3. Tap "Received" button
4. Switch between them multiple times

**Expected Results:**
- [ ] Selected button has gradient background
- [ ] Arrow icon animates (moves slightly)
- [ ] Smooth color transition
- [ ] Glow effect around selected button
- [ ] Button size changes slightly when selected

### 5. Fixed Emoji Duplication

**Test Steps:**
1. Open "Add Transaction" screen
2. Look at Category dropdown
3. Tap to open dropdown
4. Check each category item

**Expected Results:**
- [ ] Emoji appears only ONCE per category
- [ ] No double emojis (🍕🍕 ❌)
- [ ] Clean, single emoji display (🍕 ✅)

### 6. Theme System

**Test Steps:**
1. Go to Settings tab (bottom right)
2. Look for "Appearance" section at the top
3. Tap on the theme card (shows current theme)
4. Modal opens with 10 themes in grid

**Expected Results:**
- [ ] Modal shows all 10 themes:
  - Midnight Purple
  - Ocean Blue
  - Forest Green
  - Sunset Orange
  - Cherry Blossom
  - Midnight Black
  - Midnight White
  - Lavender Dream
  - Emerald Luxury
  - Golden Hour
- [ ] Current theme has white border + checkmark
- [ ] Each theme shows icon, name, and description
- [ ] Beautiful gradient cards

**Test Theme Switching:**
1. Tap "Ocean Blue" theme
2. Wait for theme to change

**Expected Results:**
- [ ] App colors change to blue immediately
- [ ] No app restart required
- [ ] Smooth transition
- [ ] All screens update (Dashboard, Transactions, etc.)
- [ ] Background gradient changes
- [ ] Bottom navigation updates

**Test Multiple Themes:**
- [ ] Switch to Forest Green → See green colors
- [ ] Switch to Sunset Orange → See orange colors
- [ ] Switch to Cherry Blossom → See pink colors
- [ ] Switch back to Midnight Purple → See purple colors
- [ ] Close app and reopen → Last selected theme is saved

### 7. Dark Mode Toggle

**Test Steps:**
1. Go to Settings → Appearance
2. Look for "Dark Mode" toggle at the top
3. Toggle it ON

**Expected Results:**
- [ ] App switches to dark theme immediately
- [ ] Background becomes dark
- [ ] Text becomes light
- [ ] Cards have dark background
- [ ] Icons update color
- [ ] System status bar becomes light icons

**Test with Different Themes:**
1. Enable Dark Mode
2. Switch between themes (Ocean Blue, Forest Green, etc.)

**Expected Results:**
- [ ] Each theme works in dark mode
- [ ] Dark variant of each theme shows
- [ ] Colors are appropriate for dark mode

3. Toggle Dark Mode OFF

**Expected Results:**
- [ ] Returns to light theme
- [ ] Smooth transition
- [ ] All colors update properly

### 8. Settings Screen - Cloud Backup

**Test Steps:**
1. Go to Settings
2. Scroll to "Cloud Backup" section

**Expected Results:**
- [ ] Shows "Sign in with Google" if not signed in
- [ ] Beautiful card with cloud icon
- [ ] Explanation about privacy

**If you want to test Google Sign-in:**
- [ ] Tap "Sign in with Google"
- [ ] Google sign-in dialog appears
- [ ] After sign-in, shows connected state
- [ ] Shows your email
- [ ] Auto-sync toggle available
- [ ] Backup Now / Restore buttons work

### 9. Manual Backup

**Test Steps:**
1. Add some test transactions
2. Go to Settings → Manual Backup
3. Tap "Export"

**Expected Results:**
- [ ] File save/share dialog opens
- [ ] Can share via WhatsApp, email, etc.
- [ ] Filename: `ExpenWall_Backup_YYYYMMDD_HHMMSS.json`
- [ ] Success message shows

**Test Import:**
1. Tap "Import"
2. Select the exported file

**Expected Results:**
- [ ] File picker opens
- [ ] Can select .json files
- [ ] Import success message
- [ ] Message says "Restart app to see changes"

### 10. Navigation & UI

**Test Bottom Navigation:**
- [ ] Tap each tab (Home, Activity, Budget, Products, Settings)
- [ ] Each screen loads correctly
- [ ] Selected tab is highlighted
- [ ] Icon colors change when selected
- [ ] Smooth transitions

**Test Floating Action Button:**
- [ ] FAB appears on Dashboard and Transactions screens
- [ ] FAB disappears on other screens
- [ ] Tapping FAB opens Add Transaction screen
- [ ] FAB has nice elevation/shadow

### 11. Dashboard

**Test with Data:**
1. Add several test transactions:
   - Spent: Grocery ₹500
   - Spent: Restaurant ₹300
   - Received: Salary ₹5000
2. Go to Dashboard

**Expected Results:**
- [ ] Shows correct Income total
- [ ] Shows correct Expense total
- [ ] Shows correct Net Balance
- [ ] Category breakdown shows
- [ ] Recent transactions appear
- [ ] Beautiful glass cards
- [ ] Smooth animations when opening

### 12. Transactions Screen

**Expected Results:**
- [ ] Lists all transactions
- [ ] Newest first
- [ ] Shows merchant, amount, category
- [ ] Shows emoji for each category
- [ ] Can scroll smoothly
- [ ] Swipe to delete works (if implemented)

---

## 🐛 BUG REPORTING

### If You Find a Bug:

**Report Format:**
```
BUG: [Short description]

Steps to reproduce:
1. Open app
2. Go to Settings
3. Tap theme selector
4. [etc.]

Expected: [What should happen]
Actual: [What actually happened]

Device: [Phone model]
Android Version: [e.g., Android 12]
App Version: 2.1.0

Screenshot: [If possible]
```

---

## 📸 SCREENSHOT CHECKLIST

### Important Screenshots to Take:

1. **Theme Selector Modal**
   - [ ] Modal showing all 10 themes in grid
   - [ ] Selected theme with checkmark

2. **Add Transaction - Autocomplete**
   - [ ] Typing in merchant field
   - [ ] Suggestions appearing below
   - [ ] Showing "Used X times"

3. **Add Transaction - Type Selector**
   - [ ] "Spent" selected with red gradient
   - [ ] "Received" selected with green gradient

4. **Settings - Appearance**
   - [ ] Dark mode toggle
   - [ ] Current theme display

5. **Different Themes**
   - [ ] Dashboard in Midnight Purple
   - [ ] Dashboard in Ocean Blue
   - [ ] Dashboard in Forest Green
   - [ ] Dashboard in Dark Mode

6. **Dashboard with Data**
   - [ ] Showing income/expense cards
   - [ ] Category breakdown
   - [ ] Recent transactions

---

## ✨ WHAT'S NEW IN THIS VERSION

### Version 2.1.0 Features:

✅ **Smart Autocomplete**
- Type merchant name → See previous matches
- Shows usage frequency
- Auto-fills category and subcategory

✅ **10 Premium Themes**
- Beautiful theme selector
- Live switching (no restart)
- Each theme with unique colors

✅ **Dark/Light Mode**
- Toggle in Settings
- Works with all themes
- Smooth transitions

✅ **UI Improvements**
- Fixed emoji duplication
- Changed "Income/Expense" → "Received/Spent"
- Animated type selector with gradients
- Better visual feedback

✅ **Bug Fixes**
- No more white screen on launch
- Stable offline-first architecture
- Smooth performance

---

## 🎯 PRIORITY TESTS

### Must Test (Critical):
1. ✅ App launches without crash
2. ✅ Can add a transaction
3. ✅ Autocomplete works
4. ✅ Theme switching works
5. ✅ Dark mode works

### Should Test (Important):
6. ✅ Emoji duplication fixed
7. ✅ "Received/Spent" wording
8. ✅ Animated type selector
9. ✅ All 10 themes load
10. ✅ Settings screen works

### Nice to Test (Optional):
11. ✅ Cloud backup (if you want to set up Google OAuth)
12. ✅ Manual export/import
13. ✅ Dashboard calculations
14. ✅ Budget screen
15. ✅ Products screen

---

## 📞 FEEDBACK

After testing, please report:

**What Works:**
- List features that work perfectly
- Any pleasant surprises

**What Doesn't Work:**
- Bugs or crashes
- Performance issues
- UI problems

**Suggestions:**
- What could be better
- Missing features
- UX improvements

---

**Happy Testing! 🎉**

*If everything works as expected, we'll move on to:*
- Liquid glass navigation (Apple-style)
- Buying List screen
- Cravings screen
- And more amazing features!
