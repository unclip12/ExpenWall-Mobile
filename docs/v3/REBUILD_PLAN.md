# 🗺️ ExpenWall Mobile v3.0 - Rebuild Plan

**6-Phase Development Roadmap**

---

## 🎯 Vision

Rebuild ExpenWall from scratch with:
- 🌊 Modern liquid morphism design
- ⚡ Lightning-fast performance
- 🎨 Material 3 components
- 📳 Delightful interactions
- 🔥 Clean, maintainable code

**Timeline:** February - April 2026 (10 weeks)

---

## ✅ Phase 1: Foundation
**Duration:** 1 week (Feb 1-5, 2026)  
**Status:** ✅ COMPLETE

### **Goals:**
- Set up liquid morphism theme system
- Create 5-tab navigation structure
- Build glass morphism components
- Enable Material 3
- Add haptic feedback

### **Deliverables:**
✅ Liquid themes (Ocean Wave + Sunset Glow)  
✅ ThemeProvider for state management  
✅ Home screen with 5-tab navigation  
✅ Glass morphism card widget  
✅ Coming Soon placeholder screens  
✅ Material 3 enabled  
✅ Haptic feedback on interactions  
✅ Edge-to-edge mode  
✅ GitHub Actions CI/CD  
✅ Firebase App Distribution  

### **Files Created:**
- `lib/main.dart` (v3.0)
- `lib/core/theme/liquid_theme.dart`
- `lib/core/theme/theme_provider.dart`
- `lib/screens/home/home_screen.dart`
- `lib/screens/dashboard/dashboard_screen.dart`
- `lib/widgets/glass_card.dart`
- `lib/widgets/coming_soon_screen.dart`
- `lib/firebase_options.dart`

**Testing:** Deployed to Samsung S21 FE via Firebase  
**Approval:** Waiting for user testing ✅

---

## 🟡 Phase 2: Dashboard Features
**Duration:** 2 weeks (Feb 6-19, 2026)  
**Status:** READY TO START

### **Goals:**
Build complete Dashboard tab with 6 key features (A-F)

---

### **Feature A: Welcome + Total Balance**
**Priority:** 🔴 HIGH - Build First  
**Duration:** 1 day

#### **Design Specs:**
```
┌──────────────────────────────────┐
│  Good Evening, Unclip! 👋        │  ← Time-based greeting
│                                  │
│         ₹ 45,230.50              │  ← Animated counter
│      Your Total Balance          │  ← Subtitle
└──────────────────────────────────┘
```

#### **Requirements:**
- Greeting based on time:
  - 5am-12pm: "Good Morning"
  - 12pm-5pm: "Good Afternoon"
  - 5pm-10pm: "Good Evening"
  - 10pm-5am: "Good Night"
- User name from Firebase (first name only)
- Balance from Firestore sum of all transactions
- Animated counter (count-up effect)
- Currency: ₹ (Indian Rupee)
- Format: #,##,###.## (Indian numbering)
- Glass morphism card

#### **Implementation:**
```dart
class WelcomeBalanceCard extends StatelessWidget {
  final String userName;
  final double totalBalance;
  
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          _buildGreeting(),
          SizedBox(height: 16),
          _buildAnimatedBalance(),
        ],
      ),
    );
  }
}
```

#### **Data Source:**
- `Firestore: users/{userId}/profile/name`
- `Firestore: users/{userId}/transactions (SUM)`

---

### **Feature B: Financial Overview Card**
**Priority:** 🟠 MEDIUM  
**Duration:** 1 day

#### **Design Specs:**
```
┌──────────────────────────────────┐
│  This Month                      │
│                                  │
│  Income      ₹ 50,000  ━━━━━ 80%│
│  Expense     ₹ 32,450  ━━━ 60%  │
│                                  │
│  Net Savings: ₹ 17,550  📈      │
└──────────────────────────────────┘
```

#### **Requirements:**
- Show current month income vs expense
- Visual progress bars (relative to max)
- Percentage indicators
- Net savings calculation
- Color coding:
  - Income: Green
  - Expense: Red
  - Savings positive: Green arrow up
  - Savings negative: Red arrow down
- Glass morphism card

#### **Implementation:**
```dart
class FinancialOverviewCard extends StatelessWidget {
  final double income;
  final double expense;
  
  @override
  Widget build(BuildContext context) {
    final savings = income - expense;
    return GlassCard(
      child: Column(
        children: [
          _buildMonthHeader(),
          _buildIncomeBar(),
          _buildExpenseBar(),
          _buildSavings(savings),
        ],
      ),
    );
  }
}
```

---

### **Feature C: Spending Chart (7 Days)**
**Priority:** 🟠 MEDIUM  
**Duration:** 2 days

#### **Design Specs:**
```
┌──────────────────────────────────┐
│  Last 7 Days Spending            │
│                                  │
│      ┃                           │
│      ┃     ┃                     │
│  ┃   ┃ ┃   ┃   ┃     ┃   ┃      │
│  Mon Tue Wed Thu Fri Sat Sun     │
│                                  │
│  Tap bar for details             │
└──────────────────────────────────┘
```

#### **Requirements:**
- Bar chart using `fl_chart` package
- Last 7 days of spending
- Interactive tooltips on tap
- Day labels (Mon-Sun)
- Smooth animations
- Gradient bars (theme colors)
- Glass morphism card

#### **Implementation:**
```dart
import 'package:fl_chart/fl_chart.dart';

class SpendingChartCard extends StatelessWidget {
  final List<DailySpending> data; // Last 7 days
  
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Text('Last 7 Days Spending'),
          SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: _buildBars(),
                // ... chart configuration
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### **Feature D: Budget Summary Cards**
**Priority:** 🟡 LOW  
**Duration:** 1 day

#### **Design Specs:**
```
┌──────────────────────────────────┐
│  Active Budgets                  │
│                                  │
│  🍔 Food         ₹2,500 / ₹5,000│
│  ━━━━━━━━━━━━━━━━━━━━ 50%       │
│                                  │
│  🚗 Transport    ₹1,800 / ₹3,000│
│  ━━━━━━━━━━━━━━━━━━━━ 60%       │
│                                  │
│  🎬 Entertainment ₹4,200 / ₹4,000│
│  ━━━━━━━━━━━━━━━━━━━━ 105% ⚠️  │
│                                  │
│  View All →                      │
└──────────────────────────────────┘
```

#### **Requirements:**
- Show top 3 active budgets
- Category icon + name
- Spent / Total amounts
- Progress bar
- Percentage indicator
- Warning icon if over budget (>100%)
- Color coding:
  - <70%: Green
  - 70-90%: Yellow
  - >90%: Red
- "View All" button to Planning tab
- Glass morphism cards (one per budget)

---

### **Feature E: Recent Transactions (Top 5)**
**Priority:** 🟡 LOW  
**Duration:** 1 day

#### **Design Specs:**
```
┌──────────────────────────────────┐
│  Recent Transactions             │
│                                  │
│  🍔 Lunch at Dominos             │
│  Food • Today, 2:30 PM           │
│                      - ₹ 450.00  │
│  ─────────────────────────────── │
│  ☕ Coffee                        │
│  Beverage • Today, 10:15 AM      │
│                      - ₹ 120.00  │
│  ─────────────────────────────── │
│  💰 Salary Credited              │
│  Income • Feb 1                  │
│                      + ₹ 50,000  │
│                                  │
│  View All →                      │
└──────────────────────────────────┘
```

#### **Requirements:**
- Show latest 5 transactions
- Swipeable cards (left: delete, right: edit)
- Category icon
- Transaction description
- Category name + date/time
- Amount with color:
  - Expense: Red with minus
  - Income: Green with plus
- Relative time (Today, Yesterday, Feb 1)
- "View All" button to Expenses tab
- Pull-to-refresh
- Glass morphism card

---

### **Feature F: Add Transaction FAB + Bottom Sheet**
**Priority:** 🔴 HIGH  
**Duration:** 2 days

#### **Design Specs:**
```
Floating Action Button:
┌───────────────┐
│      ➕       │  ← Extended FAB
│  Add Expense  │
└───────────────┘

Bottom Sheet (when tapped):
┌──────────────────────────────────┐
│  Add Transaction                 │
│  ════════════════════════════    │
│                                  │
│  Amount:                         │
│  ₹ [         ]                   │
│                                  │
│  Category:                       │
│  [🍔 Food      ▼]                │
│                                  │
│  Description:                    │
│  [                    ]          │
│                                  │
│  Date:                           │
│  [Today        📅]               │
│                                  │
│  Type: ( • Expense  ○ Income)    │
│                                  │
│  ┌──────────┐  ┌──────────┐     │
│  │  Cancel  │  │   Add    │     │
│  └──────────┘  └──────────┘     │
└──────────────────────────────────┘
```

#### **Requirements:**
- Extended FAB with icon + text
- Glass morphism bottom sheet
- Amount input with Indian currency formatter
- Category dropdown (pre-populated from Firestore)
- Description text field
- Date picker (default: today)
- Type toggle (Expense / Income)
- Form validation
- Submit to Firestore
- Success snackbar
- Haptic feedback on submit
- Close on success

#### **Implementation:**
```dart
FloatingActionButton.extended(
  onPressed: () => _showAddTransactionSheet(),
  icon: Icon(Icons.add),
  label: Text('Add Expense'),
)

void _showAddTransactionSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddTransactionSheet(),
  );
}
```

---

### **Phase 2 Timeline:**

**Week 1 (Feb 6-12):**
- Day 1: Feature A (Welcome + Balance)
- Day 2: Feature B (Financial Overview)
- Day 3-4: Feature C (Spending Chart)
- Day 5: Testing & fixes

**Week 2 (Feb 13-19):**
- Day 1: Feature D (Budget Summary)
- Day 2: Feature E (Recent Transactions)
- Day 3-4: Feature F (Add Transaction FAB)
- Day 5: Full testing & approval

**Approval:** User testing on Samsung S21 FE

---

## ⏳ Phase 3: Expenses Tab
**Duration:** 2 weeks (Feb 20 - Mar 5, 2026)  
**Status:** NOT STARTED

### **Goals:**
- Complete transaction management
- Filtering and search
- Category breakdown
- Export functionality

### **Features:**
1. All transactions list (infinite scroll)
2. Filter by date range
3. Filter by category
4. Search by description
5. Sort options (date, amount, category)
6. Swipe to delete
7. Tap to view details
8. Edit transaction
9. Category pie chart
10. Export to CSV/PDF

---

## ⏳ Phase 4: Planning Tab
**Duration:** 2 weeks (Mar 6-19, 2026)  
**Status:** NOT STARTED

### **Goals:**
- Budget management
- Recurring bills
- Shopping lists
- Reminders

### **Features:**
1. Create/edit budgets
2. Budget categories
3. Monthly budget reset
4. Budget alerts (70%, 90%, 100%)
5. Recurring bills list
6. Bill reminders
7. Shopping lists
8. List items with prices
9. Budget recommendations

---

## ⏳ Phase 5: Social Tab
**Duration:** 2 weeks (Mar 20 - Apr 2, 2026)  
**Status:** NOT STARTED

### **Goals:**
- Split bills feature
- Group expenses
- Social features

### **Features:**
1. Create split bill
2. Add participants
3. Split methods (equal, percentage, custom)
4. Settlement tracking
5. Contact management
6. Group expenses
7. Cravings wishlist
8. Shared budgets
9. Payment reminders

---

## ⏳ Phase 6: Insights Tab
**Duration:** 2 weeks (Apr 3-16, 2026)  
**Status:** NOT STARTED

### **Goals:**
- Analytics and insights
- AI predictions
- Reports

### **Features:**
1. Spending trends
2. Category breakdown
3. Month-over-month comparison
4. Year-over-year analysis
5. AI spending predictions
6. Budget recommendations
7. Savings goals
8. Interactive charts
9. PDF report generation
10. Expense patterns detection

---

## 🎯 Success Metrics

### **Phase 1:**
- ✅ 8 files created
- ✅ 57 old files backed up
- ✅ Build succeeds
- ✅ Deploys automatically
- 🟡 User approved (pending)

### **Phase 2:**
- 6 dashboard features complete
- Each feature tested individually
- User approval for each
- Firebase integration working
- Performance >60fps

### **Overall (End of v3.0):**
- All 5 tabs complete
- All features working
- 0 critical bugs
- <3s app launch time
- Smooth 120fps animations
- User satisfaction: ⭐⭐⭐⭐⭐

---

## 📝 Development Guidelines

### **Build Order:**
1. Complete Phase 1 → Test → Approve
2. Build Phase 2 features A → F in order
3. Test each feature individually
4. Get approval before next feature
5. Complete Phase 2 → Test → Approve
6. Repeat for Phases 3-6

### **Testing:**
- Test on Samsung S21 FE after each feature
- Check performance (fps, memory)
- Verify Firebase integration
- Test edge cases
- Get user approval

### **Code Quality:**
- Use const constructors
- Add documentation comments
- Follow Material 3 guidelines
- Keep files under 300 lines
- Use meaningful variable names

---

**Last Updated:** February 7, 2026, 12:01 AM IST  
**Current Phase:** Phase 1 Complete, Phase 2 Ready  
**Next Feature:** Phase 2 Feature A (Welcome + Balance)
