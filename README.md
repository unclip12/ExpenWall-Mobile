# 📱 ExpenWall Mobile

**Your intelligent wallet manager - now on mobile!**

## ✨ Features

- 💰 Smart expense tracking
- 📊 Budget management with visual progress
- 🏪 Product price tracking across shops
- 📱 Beautiful Material 3 UI with glassmorphism
- 🌙 Dark mode support
- ☁️ Real-time cloud sync with Firebase
- 🔐 Secure authentication

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.24.3 or higher
- Dart 3.0+
- Firebase project (configured)

### Installation

```bash
# Clone the repository
git clone https://github.com/unclip12/ExpenWall-Mobile.git
cd ExpenWall-Mobile

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 📦 Building

### APK (Android)
```bash
flutter build apk --release
```

### App Bundle (Android)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🔧 Firebase Setup

This app uses Firebase for:
- Authentication (Anonymous/Secret ID)
- Firestore Database (real-time data sync)
- Cloud Storage

Firebase configuration is managed via GitHub Secrets for security.

## 🎨 Design

- **Material 3 Design System**
- **Glassmorphism UI effects**
- **Smooth animations (60fps)**
- **Responsive layouts**
- **Dark/Light theme**

## 📱 Screens

1. **Dashboard** - Financial overview with summary cards
2. **Transactions** - Complete transaction history with filters
3. **Add Transaction** - Smart form with multi-item support
4. **Budgets** - Visual budget tracking with alerts
5. **Products** - Price comparison across shops
6. **Settings** - App preferences and logout

## 🔐 Security

- Firebase credentials stored in GitHub Secrets
- Secure authentication
- Firestore security rules
- No sensitive data in source code

## 📄 License

MIT License - See LICENSE file for details

## 👨‍💻 Author

**unclip12**

---

**Built with ❤️ using Flutter**
