# 🗺️ ExpenWall Mobile - Feature Roadmap

> **Comprehensive plan for upcoming features and improvements**
> Last Updated: February 2, 2026, 7:40 PM IST

---

## 🚀 PHASE 13: SMART AUTOCOMPLETE & AI FEATURES

### 🎯 Priority: HIGH
**Status:** 🟡 Planned

#### Features:

1. **Smart Merchant Autocomplete**
   - [ ] Show suggestions as user types merchant name
   - [ ] Learn from previous transactions
   - [ ] Show frequently used merchants first
   - [ ] Example: Type "chicken" → Shows "Chicken Biryani", "Chicken Nuggets", etc.

2. **Auto-Categorization**
   - [ ] Automatically detect category from merchant/item name
   - [ ] Example: "Chicken Biryani" → Auto-sets category to Food, subcategory to Restaurant
   - [ ] Learn from user corrections
   - [ ] Merchant rules engine

3. **Item Name Suggestions**
   - [ ] When typing item names, show previously used items
   - [ ] Show popular items in that category
   - [ ] Brand suggestions based on history

4. **Keyword Training**
   - [ ] Train app with custom keywords
   - [ ] Link keywords to categories
   - [ ] Import rules from ExpenWall Web

---

## 🎨 PHASE 14: THEME SYSTEM & UI OVERHAUL

### 🎯 Priority: HIGH
**Status:** 🟡 Planned

#### Features:

1. **10 Premium Themes**
   - [ ] **Midnight Purple** (Current - default)
   - [ ] **Ocean Blue**
   - [ ] **Forest Green**
   - [ ] **Sunset Orange**
   - [ ] **Cherry Blossom**
   - [ ] **Midnight Black**
   - [ ] **Arctic White**
   - [ ] **Lavender Dream**
   - [ ] **Emerald Luxury**
   - [ ] **Golden Hour**

2. **Theme Selector in Settings**
   - [ ] Beautiful theme preview cards
   - [ ] Live preview before applying
   - [ ] Save theme preference locally
   - [ ] Smooth transition animations

3. **Dark/Light Mode Toggle**
   - [ ] Manual toggle in Settings
   - [ ] System default option
   - [ ] Per-theme light/dark variants
   - [ ] Smooth transition animation

4. **Apple-Inspired Liquid Glass**
   - [ ] Bottom navigation bar with liquid glass effect
   - [ ] Glassmorphism with blur
   - [ ] Dynamic opacity based on content
   - [ ] Smooth color transitions
   - [ ] iOS-style animations

---

## 📝 PHASE 15: WORDING & UX IMPROVEMENTS

### 🎯 Priority: CRITICAL (Quick Fixes)
**Status:** 🟡 Ready to Implement

#### Changes:

1. **Transaction Type Wording**
   - [ ] Change "Income" → "Received" ✅
   - [ ] Change "Expense" → "Spent" ✅
   - [ ] More natural, user-friendly language

2. **Animated Type Selector**
   - [ ] Replace plain boxes with animated cards
   - [ ] Add flowing animation when selected
   - [ ] Icon animation (arrow flowing up/down)
   - [ ] Smooth gradient transitions
   - [ ] Haptic feedback

3. **Fix Category Emoji Display**
   - [ ] Remove duplicate emoji rendering
   - [ ] Show emoji only once in dropdown
   - [ ] Consistent emoji display across app

---

## 📊 PHASE 16: NEW SCREENS & FEATURES

### 🎯 Priority: HIGH
**Status:** 🟡 Planning

#### New Screens to Add:

1. **🛒 Buying List**
   - [ ] Shopping list management
   - [ ] Add items to buy
   - [ ] Mark items as purchased
   - [ ] Auto-create transaction from list
   - [ ] Share list with others
   - [ ] Price tracking per item

2. **🍔 Cravings**
   - [ ] Save items/places you want to try
   - [ ] Add photos and notes
   - [ ] Priority levels
   - [ ] Mark as done when visited
   - [ ] Share cravings

3. **🔄 Recurring Transactions**
   - [ ] Set up recurring expenses (rent, subscriptions)
   - [ ] Automatic transaction creation
   - [ ] Reminders before due date
   - [ ] Edit/pause/delete recurring items
   - [ ] History of all occurrences

4. **💸 Split Bills**
   - [ ] Split transactions among friends
   - [ ] Multiple split types:
     - Equal split
     - Custom amounts
     - Percentage-based
     - By items
   - [ ] Track who paid and who owes
   - [ ] Settlement tracking
   - [ ] Share split details

5. **📊 Reports & Analytics**
   - [ ] Spending trends over time
   - [ ] Category-wise breakdown
   - [ ] Monthly/weekly/yearly views
   - [ ] Budget vs actual comparison
   - [ ] Spending patterns
   - [ ] Export reports as PDF

6. **🤖 AI Analyzer**
   - [ ] AI-powered insights
   - [ ] Spending predictions
   - [ ] Budget recommendations
   - [ ] Anomaly detection
   - [ ] Money-saving tips
   - [ ] Natural language queries

---

## 🧑 PHASE 17: NAVIGATION RESTRUCTURE

### 🎯 Priority: MEDIUM
**Status:** 🟡 Design Phase

#### Current Navigation (5 tabs):
1. Home (Dashboard)
2. Activity (Transactions)
3. Budget
4. Products
5. Settings

#### Proposed New Navigation:

**Option A: Expandable Bottom Nav**
- Keep 5 main tabs
- Add "More" menu with additional features
- Swipe up to reveal: Buying List, Cravings, Recurring, Split Bills, Reports, AI

**Option B: Nested Navigation**
- Home → Dashboard
- Transactions → All, Recurring, Split Bills
- Tools → Buying List, Cravings, AI Analyzer
- Insights → Budget, Reports, Analytics
- Settings

**Option C: Tab Bar + Drawer**
- Keep 3-4 main tabs
- Add side drawer for additional features
- Quick access to all features

**✅ Recommended: Option B** - Clean, organized, scalable

---

## 🔗 PHASE 18: WEB APP INTEGRATION

### 🎯 Priority: LOW (Future)
**Status:** 🟡 Research

#### Sync Features from ExpenWall Web:

1. **Automation Rules**
   - [ ] Import automation rules from web app
   - [ ] SMS parsing rules
   - [ ] Notification listeners
   - [ ] Auto-categorization rules

2. **Advanced Analytics**
   - [ ] All charts/graphs from web
   - [ ] Comparison features
   - [ ] Goal tracking
   - [ ] Savings calculator

3. **Multi-Currency Support**
   - [ ] Support for multiple currencies
   - [ ] Real-time exchange rates
   - [ ] Currency conversion

4. **Receipt OCR**
   - [ ] Scan receipts with camera
   - [ ] Extract items automatically
   - [ ] Auto-fill transaction form

5. **Notification Tracking**
   - [ ] Listen to payment notifications
   - [ ] Auto-create transactions
   - [ ] Bank SMS integration

---

## 🛠️ TECHNICAL IMPROVEMENTS

### Database & Storage:
- [ ] Add indexes for faster queries
- [ ] Implement search functionality
- [ ] Cache frequently accessed data
- [ ] Optimize JSON file structure

### Performance:
- [ ] Lazy loading for long lists
- [ ] Image compression
- [ ] Background sync optimization
- [ ] Memory leak fixes

### Security:
- [ ] Encrypt local data
- [ ] Biometric authentication (optional)
- [ ] PIN lock (optional)

---

## 📝 IMMEDIATE ACTION ITEMS (Next Week)

### 🔥 Critical Fixes:
1. **Fix category emoji duplication** [cite:18]
2. **Change Income/Expense → Received/Spent**
3. **Improve type selector UI** - Add animations
4. **Add autocomplete for merchant names**
5. **Add dark/light mode toggle in Settings**

### 🎨 UI Improvements:
6. **Redesign bottom navigation** - Apple liquid glass style
7. **Add theme selector** - Start with 3-5 themes
8. **Improve transaction type selector** - Animated, flowing design

### ✨ Smart Features:
9. **Implement merchant autocomplete**
10. **Add auto-categorization**
11. **Item name suggestions**

---

## 📊 TIMELINE

### Week 1 (Feb 3-9):
- ✅ Fix emoji duplication
- ✅ Change wording (Received/Spent)
- ✅ Add dark/light mode toggle
- ✅ Redesign type selector
- ✅ Implement basic autocomplete

### Week 2 (Feb 10-16):
- ✅ Add theme system (5 themes)
- ✅ Liquid glass navigation
- ✅ Auto-categorization
- ✅ Plan new screen layouts

### Week 3 (Feb 17-23):
- ✅ Implement Buying List screen
- ✅ Implement Cravings screen
- ✅ Add 5 more themes (total 10)

### Week 4 (Feb 24-Mar 2):
- ✅ Recurring transactions
- ✅ Split bills feature
- ✅ Navigation restructure

### Month 2 (March):
- Reports & Analytics
- AI Analyzer
- Web app integration research

### Month 3 (April):
- Receipt OCR
- Notification tracking
- Advanced automation

---

## 📚 RESOURCES & REFERENCES

### Design Inspiration:
- Apple iOS Design Guidelines
- Material 3 Design System
- Glassmorphism UI trends
- ExpenWall Web App

### APIs & Libraries:
- ML Kit (OCR)
- Charts library (fl_chart)
- Notification listener
- SMS parser

---

**Status Legend:**
- 🟢 Not Started
- 🟡 Planned
- 🟠 In Progress
- ✅ Completed
- ❌ Blocked

---

> 💡 **GOAL:** Transform ExpenWall Mobile into the most intelligent, beautiful, and feature-rich expense tracker on the market!
