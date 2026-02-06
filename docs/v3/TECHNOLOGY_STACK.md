# 🛠️ ExpenWall Mobile v3.0 - Technology Stack

**Modern Standards & Best Practices**

---

## 🎯 Core Technologies

### **Flutter & Dart**
- **Flutter Version:** 3.24.3+
- **Dart Version:** 3.5+
- **Channel:** Stable
- **Rendering Engine:** Impeller (enabled by default)
- **Target Platforms:** Android (primary), iOS (future)

**Why Flutter 3.24+?**
- ✅ Impeller for 120fps performance
- ✅ Material 3 fully supported
- ✅ Better memory management
- ✅ Improved build times

---

## 🎨 UI Framework

### **Material Design 3**
```yaml
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,  # ← Required!
    colorScheme: ColorScheme.fromSeed(...),
  ),
)
```

**Material 3 Components Used:**
- `FilledButton` / `FilledButton.tonal`
- `OutlinedButton`
- `Card` with elevated style
- `BottomSheet` with rounded corners
- `FloatingActionButton.extended`
- `NavigationBar` (bottom nav)
- `Chip` and `FilterChip`
- `Badge`
- `SegmentedButton`

**Design Tokens:**
- Primary color: Defined in theme
- Surface tints
- Dynamic color (future)
- Elevation levels

---

## 🌊 Custom Design System

### **Liquid Morphism**

**Concept:** Fluid, gradient-based backgrounds with animated transitions

**Implementation:**
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF2196F3),  // Light Blue
        Color(0xFF1565C0),  // Navy Blue
        Color(0xFF0D47A1),  // Deep Blue
      ],
    ),
  ),
)
```

**Themes:**
1. **Ocean Wave** (Default)
   - Primary: `#1976D2` (Deep Blue)
   - Accent: `#00BCD4` (Cyan)
   - Gradient: Blue → Navy → Deep Blue

2. **Sunset Glow**
   - Primary: `#FF6F00` (Deep Orange)
   - Accent: `#E91E63` (Pink)
   - Gradient: Orange → Dark Orange → Red-Orange

---

### **Glass Morphism**

**Concept:** Frosted glass effect with backdrop blur

**Implementation:**
```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
    ),
  ),
)
```

**Properties:**
- Blur: 10px (sigma)
- Background opacity: 10%
- Border: 1.5px white with 20% opacity
- Border radius: 24px
- Shadow: Elevation 4

**Widget:** `lib/widgets/glass_card.dart`

---

## 📦 Required Packages

### **pubspec.yaml:**
```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.0

  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_analytics: ^10.8.0
  firebase_storage: ^11.6.0

  # UI/UX
  flutter_animate: ^4.5.0        # Smooth animations
  rive: ^0.13.0                   # Designer animations
  lottie: ^3.1.0                  # After Effects animations
  cached_network_image: ^3.3.0    # Image caching

  # Charts & Visualization
  fl_chart: ^0.68.0               # Beautiful charts

  # Utilities
  intl: ^0.19.0                   # Date/number formatting
  url_launcher: ^6.2.0            # Open links
  share_plus: ^7.2.0              # Share functionality
  image_picker: ^1.0.0            # Camera/gallery

  # Storage
  shared_preferences: ^2.2.0      # Local key-value storage
  path_provider: ^2.1.0           # File paths

  # PDF Generation (Phase 6)
  pdf: ^3.10.0
  printing: ^5.11.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.0
```

---

## 🔥 Backend - Firebase

### **Services Used:**

1. **Firebase Authentication**
   - Google Sign-In (primary)
   - Email/Password (future)
   - Anonymous sign-in (future)

2. **Cloud Firestore**
   - NoSQL database
   - Real-time sync
   - Offline support
   - Security rules

3. **Firebase Analytics**
   - User behavior tracking
   - Event logging
   - Crash reporting

4. **Firebase Storage**
   - Receipt images
   - Profile pictures
   - Exported reports

5. **Firebase App Distribution**
   - Beta testing
   - Auto-updates
   - Release notes

### **Firestore Structure:**
```
users/ (collection)
  {userId}/ (document)
    - name: string
    - email: string
    - createdAt: timestamp
    - theme: string
    
    transactions/ (subcollection)
      {transactionId}/ (document)
        - amount: number
        - category: string
        - description: string
        - date: timestamp
        - type: "income" | "expense"
    
    budgets/ (subcollection)
      {budgetId}/ (document)
        - category: string
        - limit: number
        - spent: number
        - month: string
    
    categories/ (subcollection)
      {categoryId}/ (document)
        - name: string
        - icon: string
        - color: string
```

---

## 🎯 State Management

### **Provider Pattern**

**Why Provider?**
- ✅ Built-in with Flutter
- ✅ Simple and lightweight
- ✅ Perfect for this app size
- ✅ No complex boilerplate

**Structure:**
```dart
// Define Provider
class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = OceanWaveTheme();
  
  ThemeData get themeData => _themeData;
  
  void toggleTheme() {
    _themeData = _themeData == OceanWaveTheme() 
        ? SunsetGlowTheme() 
        : OceanWaveTheme();
    notifyListeners();
  }
}

// Provide at root
ChangeNotifierProvider(
  create: (_) => ThemeProvider(),
  child: MaterialApp(...),
)

// Consume in widgets
final theme = Provider.of<ThemeProvider>(context);
// or
Consumer<ThemeProvider>(
  builder: (context, provider, child) => ...,
)
```

**Providers in v3.0:**
- `ThemeProvider` - Theme switching
- `TransactionProvider` (Phase 2) - CRUD operations
- `BudgetProvider` (Phase 4) - Budget management
- `UserProvider` (Phase 2) - User data

---

## ⚡ Performance Optimizations

### **1. Const Constructors**
```dart
const Text('Hello')        // ✅ Good
Text('Hello')              // ❌ Bad (rebuilds)
```

**Rule:** Use `const` wherever possible

### **2. IndexedStack for Tabs**
```dart
IndexedStack(
  index: currentIndex,
  children: [
    DashboardScreen(),
    ExpensesScreen(),
    // ...
  ],
)
```

**Benefits:**
- Keeps all tabs in memory
- Instant switching
- State preservation
- No rebuild on switch

### **3. ListView.builder for Long Lists**
```dart
ListView.builder(
  itemCount: transactions.length,
  itemBuilder: (context, index) {
    return TransactionTile(transactions[index]);
  },
)
```

**Never use:** `ListView(children: [...])` for long lists

### **4. Cached Network Images**
```dart
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### **5. Lazy Loading**
- Paginate Firestore queries (limit: 20)
- Load more on scroll
- Cache frequently accessed data

---

## 📱 Platform Specifics

### **Android**
- Min SDK: 24 (Android 7.0)
- Target SDK: 34 (Android 14)
- Compile SDK: 34
- NDK: 25.1.8937393
- Build Tools: 33.0.1

**Permissions:**
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### **iOS** (Future)
- Min iOS: 12.0
- Target: 17.0

---

## 🎨 Animation Standards

### **Durations:**
- Quick: 150ms (button press)
- Normal: 300ms (page transition)
- Slow: 500ms (complex animations)

### **Curves:**
```dart
Curves.easeInOut       // Smooth start and end
Curves.easeOut         // Smooth end
Curves.elasticOut      // Bouncy effect
Curves.fastOutSlowIn   // Material standard
```

### **Haptic Feedback:**
```dart
HapticFeedback.lightImpact()   // Soft tap
HapticFeedback.mediumImpact()  // Button press
HapticFeedback.heavyImpact()   // Important action
HapticFeedback.selectionClick() // Toggle/slider
```

**Rule:** Add haptic to all user interactions

---

## 🔐 Security Best Practices

### **1. API Keys in GitHub Secrets**
- Never commit API keys
- Use GitHub Actions secrets
- Inject at build time

### **2. Firestore Security Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId;
    }
  }
}
```

### **3. Release Signing**
- Use release keystore
- Store in GitHub Secrets
- Never commit keystore file

---

## 🧪 Testing Standards

### **Widget Tests:**
```dart
testWidgets('GlassCard displays child', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GlassCard(
        child: Text('Test'),
      ),
    ),
  );
  expect(find.text('Test'), findsOneWidget);
});
```

### **Integration Tests:**
- Test complete user flows
- Test Firebase integration
- Test navigation

---

## 📐 Code Standards

### **File Organization:**
```
lib/
├── main.dart
├── core/              # Core functionality
│   └── theme/
├── screens/           # Full-screen pages
│   └── feature/
│       └── feature_screen.dart
├── widgets/           # Reusable widgets
├── models/            # Data models
├── providers/         # State management
└── services/          # Business logic
```

### **Naming Conventions:**
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Private: `_leadingUnderscore`

### **Documentation:**
```dart
/// Brief description of the widget.
///
/// Longer description with usage example:
/// ```dart
/// GlassCard(
///   child: Text('Content'),
/// )
/// ```
class GlassCard extends StatelessWidget {
  /// The child widget to display inside the card.
  final Widget child;
  
  const GlassCard({required this.child});
}
```

---

## 🚀 Build & Deployment

### **GitHub Actions Workflow**

**File:** `.github/workflows/build-apk.yml`

**Triggers:**
- Push to main branch
- Version tags (`v*.*.*`)
- Manual trigger

**Steps:**
1. Checkout code
2. Setup Java 17
3. Setup Flutter 3.24.3
4. Inject Firebase config (from secrets)
5. Setup release keystore (from secrets)
6. Install dependencies
7. Build release APK
8. Upload to GitHub Actions
9. Deploy to Firebase App Distribution

**Build Time:** ~5-7 minutes

---

## 📊 Performance Targets

### **Metrics:**
- App launch: <3 seconds
- Navigation: <100ms
- Animations: 60fps+ (120fps on S21 FE)
- Memory: <150MB
- APK size: <50MB
- First paint: <1 second

### **Monitoring:**
- Firebase Performance Monitoring
- Crash reporting
- User analytics

---

## 🎯 Development Tools

### **Required:**
- VS Code / Android Studio
- Flutter SDK 3.24.3+
- Git
- GitHub account
- Firebase account

### **VS Code Extensions:**
- Flutter
- Dart
- GitLens
- Error Lens
- Prettier

### **GitHub Codespaces:**
- 2-core machine
- 120 hours/month free
- Pre-configured environment
- Git auto-configured

---

**Last Updated:** February 7, 2026, 12:01 AM IST  
**Status:** Active Development Standards  
**Version:** v3.0
