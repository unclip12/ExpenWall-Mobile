# ExpenWall Mobile - Development Guide

## 🛠️ Development Setup

### Prerequisites Checklist
- [ ] Flutter SDK 3.0+
- [ ] Dart SDK 3.0+
- [ ] Android Studio / Xcode
- [ ] Git
- [ ] Firebase CLI
- [ ] FlutterFire CLI

### Initial Setup

1. **Clone and Install**
   ```bash
   git clone https://github.com/unclip12/ExpenWall-Mobile.git
   cd ExpenWall-Mobile
   flutter pub get
   ```

2. **Firebase Configuration**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase
   flutterfire configure
   ```

3. **Run the App**
   ```bash
   # Check devices
   flutter devices
   
   # Run on specific device
   flutter run -d <device-id>
   ```

## 🏛️ Architecture

### Project Structure
```
lib/
├── models/              # Data models
│   ├── transaction.dart
│   ├── budget.dart
│   ├── product.dart
│   ├── wallet.dart
│   └── merchant_rule.dart
├── screens/            # UI Screens
│   ├── splash_screen.dart
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── dashboard_screen.dart
│   ├── transactions_screen.dart
│   ├── add_transaction_screen.dart
│   ├── budget_screen.dart
│   ├── products_screen.dart
│   └── settings_screen.dart
├── widgets/            # Reusable widgets
│   ├── glass_card.dart
│   └── transaction_item_widget.dart
├── services/           # Business logic
│   └── firestore_service.dart
├── utils/              # Helper functions
│   ├── currency_formatter.dart
│   └── category_icons.dart
├── theme/              # App theming
│   └── app_theme.dart
└── main.dart           # Entry point
```

### Design Patterns

1. **State Management**: StatefulWidget with setState
2. **Data Flow**: Firebase Streams → UI
3. **UI Pattern**: Glassmorphism + Material 3
4. **Navigation**: Navigator 2.0 ready

## 🎨 UI Guidelines

### Glass Card Usage
```dart
GlassCard(
  padding: const EdgeInsets.all(20),
  child: YourWidget(),
)
```

### Color Scheme
- Primary: Purple (#9333EA)
- Secondary: Violet (#8B5CF6)
- Accent: Pink (#EC4899)
- Success: Green (#10B981)
- Error: Red (#EF4444)

### Typography
- Headers: Bold, 18-24px
- Body: Regular, 14-16px
- Captions: Medium, 12-13px

## 🔥 Firebase Structure

### Firestore Collections
```
users/{userId}/
  ├── transactions/
  │   └── {transactionId}
  ├── budgets/
  │   └── {budgetId}
  ├── products/
  │   └── {productId}
  ├── wallets/
  │   └── {walletId}
  └── merchantRules/
      └── {ruleId}
```

## 🛡️ Testing

### Run Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

## 🚀 Building & Deployment

### Android Build
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS Build
```bash
# Debug
flutter build ios --debug

# Release
flutter build ios --release
```

## 📝 Code Style

### Naming Conventions
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Private members: `_leadingUnderscore`

### Import Order
1. Dart SDK
2. Flutter SDK
3. Third-party packages
4. Local imports

### Example
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/transaction.dart';
```

## 🐛 Debugging

### Common Issues

**1. Firebase not initialized**
```dart
// Ensure Firebase.initializeApp() is called in main()
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

**2. Bottom white line issue**
```dart
// Already fixed in main.dart
SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
```

**3. Gradle build fails**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

## 📊 Performance Tips

1. **Use const constructors** wherever possible
2. **Lazy load** heavy widgets
3. **Cache** Firebase data locally
4. **Optimize** images and assets
5. **Profile** with DevTools regularly

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Add tests if applicable
4. Run `flutter analyze`
5. Format code: `dart format .`
6. Commit with meaningful message
7. Create Pull Request

## 📚 Resources

- [Flutter Docs](https://docs.flutter.dev)
- [Firebase Docs](https://firebase.google.com/docs)
- [Material 3 Design](https://m3.material.io)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)

---

**Happy Coding! 🚀**
