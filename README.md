# ExpenWall Mobile 💰📱

**Premium Flutter Mobile App for Expense Tracking with AI-powered insights and cravings tracking**

[![Build Status](https://github.com/unclip12/ExpenWall-Mobile/actions/workflows/build-apk.yml/badge.svg)](https://github.com/unclip12/ExpenWall-Mobile/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.19.0-blue.svg)](https://flutter.dev/)

---

## ✨ Features

### 📊 Core Features
- **Smart Transaction Tracking** with AI-powered categorization
- **Cravings Tracker** - Resist impulse purchases and build willpower
- **Real-time Analytics** with beautiful charts and insights
- **Budget Management** with smart notifications
- **Multi-wallet Support** - Track multiple accounts

### 🧠 AI-Powered Intelligence
- **Smart Autocomplete** - Learns your spending patterns
  - Type "chick" → See "Chicken Biryani", "Chicken 65", etc.
  - Learns new items you enter ("chicken nuggets" becomes a suggestion!)
  - 100+ pre-loaded common items (Indian food, merchants, categories)
- **Gemini AI Integration** for insights and recommendations
- **Pattern Recognition** for spending habits

### 🎨 Premium UI/UX
- **Material 3 Design** with liquid animations
- **Dark/Light Theme** support
- **Splash Screen** with shimmer effects
- **Smooth Transitions** at 60/120 FPS
- **Beautiful Charts** with FL Chart & Syncfusion

### 🔥 Unique Features
- **3D Celebration Animation** with fitness character when you resist cravings! 💪
- **Gamification** - Build streaks and earn achievements
- **Social Features** - Share progress (optional)

---

## 📸 Screenshots

_Coming soon..._

---

## 🚀 Getting Started

### Prerequisites

- Flutter 3.19.0 or higher
- Dart 3.3.0 or higher
- Android Studio / Xcode
- Firebase account
- Gemini API key (free from [ai.google.dev](https://ai.google.dev))

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/unclip12/ExpenWall-Mobile.git
   cd ExpenWall-Mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase** ⚠️ **IMPORTANT**
   
   🔒 This repo uses **GitHub Secrets** for Firebase configuration (for security).
   
   **For local development:**
   - Get `google-services.json` from Firebase Console
   - Place in `android/app/`
   - Get `lib/firebase_options.dart` from Firebase Console
   - These files are gitignored and won't be committed
   
   **For GitHub Actions builds:**
   - See [SECURITY_SETUP.md](SECURITY_SETUP.md)

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 🔒 Security & Secrets

**This repository does NOT contain API keys or Firebase config in the code!**

All sensitive data is stored in:
- **GitHub Secrets** for CI/CD builds
- **Local files** (gitignored) for development

### For Contributors:

1. Read [SECURITY_SETUP.md](SECURITY_SETUP.md) for setup instructions
2. Never commit `google-services.json` or `firebase_options.dart`
3. Use `.env` files for API keys (gitignored)

---

## 📚 Documentation

- [SECURITY_SETUP.md](SECURITY_SETUP.md) - How to set up GitHub Secrets
- [BUILD_STATUS.md](BUILD_STATUS.md) - Build info and APK download guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines _(coming soon)_

---

## 🛠️ Tech Stack

### Framework & Language
- **Flutter 3.19.0** - Cross-platform framework
- **Dart 3.3+** - Programming language

### Backend & Database
- **Firebase Auth** - User authentication
- **Cloud Firestore** - NoSQL database
- **Firebase Storage** - File storage

### State Management
- **Provider** - Simple and effective

### UI & Animations
- **Material 3** - Latest design system
- **Google Fonts** (Poppins) - Beautiful typography
- **Flutter Animate** - Premium animations
- **Lottie & Rive** - Vector animations

### Charts & Analytics
- **FL Chart** - Beautiful charts
- **Syncfusion Charts** - Advanced visualizations

### AI Integration
- **Gemini AI** - Google's AI model for insights

---

## 💻 Development

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                # UI screens
│   ├── splash_screen.dart
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   └── ... (more screens)
├── services/               # Business logic
│   ├── firebase_service.dart
│   └── autocomplete_service.dart
├── models/                 # Data models
│   └── suggestion.dart
├── constants/              # Constants & configs
│   └── common_suggestions.dart
└── firebase_options.dart   # ⚠️ Gitignored! (from secrets)
```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

### Building APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

**Important:** Never commit API keys or Firebase config files!

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**unclip12**
- GitHub: [@unclip12](https://github.com/unclip12)

---

## ⭐ Star History

If you find this project useful, please give it a star! ⭐

---

## 💬 Support

Have questions or issues? 
- Open an [Issue](https://github.com/unclip12/ExpenWall-Mobile/issues)
- Check [Discussions](https://github.com/unclip12/ExpenWall-Mobile/discussions)

---

## 🚀 Roadmap

- [x] Basic UI structure
- [x] Firebase integration
- [x] Smart autocomplete system
- [ ] Complete Transactions screen
- [ ] Complete Cravings tracker
- [ ] 3D celebration animation
- [ ] Analytics dashboard
- [ ] Budget management
- [ ] Recurring transactions
- [ ] Export to PDF/Excel
- [ ] iOS version
- [ ] Web version

---

**Made with ❤️ using Flutter**
