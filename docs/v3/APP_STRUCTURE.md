# 📱 ExpenWall Mobile v3.0 - App Structure

**Clean Rebuild Architecture - February 2026**

---

## 🎯 Overview

ExpenWall v3.0 is a **5-tab expense tracking app** with:
- 🌊 Liquid morphism themes
- 💎 Glass morphism UI elements
- 📳 Haptic feedback everywhere
- 🎨 Material 3 design system
- ⚡ Lightning-fast IndexedStack navigation

---

## 🏗️ Visual Structure

```
┌─────────────────────────────────────┐
│        ExpenWall Mobile v3.0        │
│      (Material 3 App Bar)           │
├─────────────────────────────────────┤
│                                     │
│                                     │
│         ACTIVE TAB CONTENT          │
│        (IndexedStack)               │
│                                     │
│     [Dashboard | Expenses |         │
│      Planning | Social |            │
│            Insights]                │
│                                     │
│                                     │
├─────────────────────────────────────┤
│  [🏠] [📊] [📅] [👥] [💡]        │
│    ↑                                │
│  Active Tab (haptic feedback)       │
└─────────────────────────────────────┘
```

---

## 🗂️ File Structure

### **Current Active Files (v3.0):**

```
lib/
├── main.dart                         # Entry point
│   ├── Firebase initialization
│   ├── Provider setup
│   ├── Material 3 theme
│   └── Edge-to-edge mode
│
├── core/
│   └── theme/
│       ├── liquid_theme.dart         # Liquid morphism themes
│       │   ├── Ocean Wave (default)
│       │   └── Sunset Glow
│       └── theme_provider.dart       # State management
│
├── screens/
│   ├── home/
│   │   └── home_screen.dart          # Main 5-tab container
│   │       ├── IndexedStack (performance)
│   │       ├── BottomNavigationBar
│   │       └── Haptic feedback
│   │
│   └── dashboard/
│       └── dashboard_screen.dart     # Tab 1: Dashboard
│           └── Phase 1: Placeholder
│           └── Phase 2: Full features
│
├── widgets/
│   ├── glass_card.dart               # Reusable glass morphism card
│   │   ├── BackdropFilter blur
│   │   ├── Gradient border
│   │   └── 24px border radius
│   │
│   └── coming_soon_screen.dart       # Placeholder for tabs 2-5
│       ├── Icon
│       ├── Title
│       └── Message
│
├── models/                            # Data models (kept from v2)
│   ├── transaction.dart
│   ├── budget.dart
│   ├── category.dart
│   └── etc.
│
└── firebase_options.dart             # Firebase config
```

---

## 🎨 5-Tab Navigation System

### **Tab 1: Dashboard (🏠)**
**Status:** Phase 1 Complete → Phase 2 In Development

**Features (Phase 2):**
- Welcome greeting + user name
- Total balance (animated counter)
- Financial overview card (income/expense)
- Spending chart (7 days)
- Budget summary cards (top 3)
- Recent transactions (top 5)
- Add transaction FAB

**File:** `lib/screens/dashboard/dashboard_screen.dart`

---

### **Tab 2: Expenses (📊)**
**Status:** Coming Soon (Phase 3)

**Planned Features:**
- All transactions list
- Filter by date/category
- Search transactions
- Sort options
- Swipe to delete
- Category breakdown
- Export to CSV/PDF

**File:** Will be `lib/screens/expenses/expenses_screen.dart`

---

### **Tab 3: Planning (📅)**
**Status:** Coming Soon (Phase 4)

**Planned Features:**
- Budgets management
- Recurring bills tracker
- Shopping lists
- Bill reminders
- Budget alerts
- Category limits

**File:** Will be `lib/screens/planning/planning_screen.dart`

---

### **Tab 4: Social (👥)**
**Status:** Coming Soon (Phase 5)

**Planned Features:**
- Split bills
- Group expenses
- Contacts management
- Settlement tracking
- Cravings wishlist
- Shared budgets

**File:** Will be `lib/screens/social/social_screen.dart`

---

### **Tab 5: Insights (💡)**
**Status:** Coming Soon (Phase 6)

**Planned Features:**
- Spending trends
- Category analytics
- AI predictions
- Budget recommendations
- Savings goals
- Interactive charts
- PDF reports

**File:** Will be `lib/screens/insights/insights_screen.dart`

---

## 🎯 Navigation Flow

```
┌──────────────┐
│  main.dart   │
│              │
│  Firebase +  │
│  Provider    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ HomeScreen   │
│              │
│ IndexedStack │  ← Keeps all tabs in memory
│ with 5 tabs  │  ← Super fast switching
└──────┬───────┘
       │
       ├─────────┬─────────┬─────────┬─────────┐
       ▼         ▼         ▼         ▼         ▼
  Dashboard  Expenses  Planning  Social  Insights
   (Active)   (Soon)    (Soon)   (Soon)   (Soon)
```

---

## 🎨 Design Patterns

### **1. Glass Morphism Cards**
```dart
GlassCard(
  child: YourContent(),
)
```
- BackdropFilter with blur
- Semi-transparent background
- Gradient border
- 24px border radius
- Elevation shadow

### **2. Liquid Background**
- Animated gradient (3 colors)
- Smooth color transitions
- Theme-aware (Ocean Wave / Sunset Glow)
- Full-screen container

### **3. Haptic Feedback**
```dart
HapticFeedback.lightImpact();  // On every interaction
```
- Tab switches
- Button presses
- Card taps
- Swipe actions

### **4. Material 3 Components**
- FilledButton / OutlinedButton
- Card with elevated style
- Bottom sheets
- FABs with extended style
- Chips and badges

---

## 📦 State Management

### **Provider Pattern:**
```dart
ChangeNotifierProvider<ThemeProvider>(
  create: (_) => ThemeProvider(),
  child: MaterialApp(...),
)
```

**Current Providers:**
- `ThemeProvider` - Theme switching

**Future Providers (Phase 2+):**
- `TransactionProvider` - Transaction CRUD
- `BudgetProvider` - Budget management
- `UserProvider` - User data
- `CategoryProvider` - Categories

---

## 🔥 Firebase Structure

### **Collections:**
```
users/
  {userId}/
    ├── profile (doc)
    ├── transactions/ (subcollection)
    ├── budgets/ (subcollection)
    ├── categories/ (subcollection)
    └── settings/ (subcollection)
```

**Authentication:** Firebase Auth with Google Sign-In

---

## ⚡ Performance Optimizations

### **1. IndexedStack for Tabs**
- All tabs stay in memory
- Instant switching (no rebuild)
- State preservation
- Smooth animations

### **2. Const Constructors**
- Every widget uses `const` where possible
- Reduces rebuilds
- Better performance

### **3. Impeller Rendering**
- Flutter 3.24+ with Impeller enabled
- 120fps on Samsung S21 FE
- Smooth animations

### **4. Lazy Loading**
- Paginated lists
- On-demand data loading
- Cached images

---

## 🎨 Theme System

### **Ocean Wave (Default)**
```dart
primaryColor: Color(0xFF1976D2)      // Deep Blue
accentColor: Color(0xFF00BCD4)       // Cyan
gradient: [Blue, Navy, Deep Blue]
```

### **Sunset Glow**
```dart
primaryColor: Color(0xFFFF6F00)      // Deep Orange
accentColor: Color(0xFFE91E63)       // Pink
gradient: [Orange, Dark Orange, Red-Orange]
```

**Switching:** User can toggle in settings (Phase 2+)

---

## 📱 Responsive Design

**Primary Target:** Android (Samsung S21 FE)
- Screen: 6.4" FHD+ (1080 x 2400)
- Refresh: 120Hz
- OS: Android 14

**Future:** iOS support in later phases

---

## 🔐 Security

- Firebase Auth required
- User data isolated
- API keys in GitHub Secrets
- Release signing with keystore
- HTTPS only

---

## 📊 Build System

**GitHub Actions:** `.github/workflows/build-apk.yml`
- Triggers on every push to main
- Builds release APK
- Signs with keystore
- Deploys to Firebase App Distribution
- Sends notification to device

**Build Time:** ~5-7 minutes

---

## 🎯 Next Steps

1. ✅ Phase 1: Foundation (Complete)
2. 🔄 Phase 2: Dashboard Features (In Progress)
3. ⏳ Phase 3: Expenses Tab
4. ⏳ Phase 4: Planning Tab
5. ⏳ Phase 5: Social Tab
6. ⏳ Phase 6: Insights Tab

---

**Last Updated:** February 7, 2026, 12:01 AM IST  
**Status:** Phase 1 Complete, Phase 2 Ready to Start
