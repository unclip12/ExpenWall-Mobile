# ExpenWall Mobile

<div align="center">
  <h3>💰 Your Intelligent Wallet Manager</h3>
  <p>A beautiful, feature-rich expense tracking app built with Flutter</p>
</div>

## ✨ Features

### 📈 Smart Financial Management
- **Dashboard Overview** - Real-time insights into income, expenses, and net balance
- **Transaction Tracking** - Add, edit, and categorize all your transactions
- **Multi-Item Support** - Track individual items in shopping transactions
- **Budget Manager** - Set budgets and get warnings when approaching limits
- **Product Tracker** - Monitor price history of frequently purchased items

### 🎨 Premium UI/UX
- **Glassmorphism Design** - Modern liquid glass effects throughout
- **Smooth Animations** - 60fps transitions and micro-interactions
- **Dark Mode** - Full dark theme support
- **Material 3** - Latest Material Design components

### 🔥 Firebase Integration
- **Real-time Sync** - All data synced across devices instantly
- **Secure Auth** - Secret ID login system
- **Cloud Storage** - Never lose your data
- **Offline Support** - Works without internet (syncs when connected)

### 📊 Categories & Organization
- Food & Dining
- Transport
- Shopping
- Entertainment
- Health & Fitness
- Groceries
- Utilities
- Education
- Banking
- And more...

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Android Studio / Xcode
- Firebase project setup

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

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the respective platform folders
   - Run the FlutterFire configuration:
     ```bash
     flutterfire configure
     ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Screenshots

*Coming soon!*

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **Backend**: Firebase (Firestore, Auth)
- **State Management**: StatefulWidget (simple and effective)
- **UI**: Material 3 with custom glassmorphism
- **Architecture**: Feature-first with clean separation

## 📁 Project Structure

```
lib/
├── models/          # Data models (Transaction, Budget, etc.)
├── screens/         # All app screens
├── widgets/         # Reusable widgets (GlassCard, etc.)
├── services/        # Firebase & business logic
├── utils/           # Helpers & formatters
├── theme/           # App theme configuration
└── main.dart        # App entry point
```

## ✅ Features Checklist

- [x] Authentication (Secret ID login)
- [x] Dashboard with analytics
- [x] Add/Edit/Delete transactions
- [x] Multi-item transaction support
- [x] Budget management
- [x] Product price tracking
- [x] Category-wise filtering
- [x] Dark mode
- [x] Glassmorphism UI
- [ ] Charts & graphs
- [ ] Export data (CSV/PDF)
- [ ] Recurring transactions
- [ ] Multi-wallet support
- [ ] Merchant rules (auto-categorize)
- [ ] AI insights

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**unclip12**
- GitHub: [@unclip12](https://github.com/unclip12)
- Web Version: [ExpenWall Web](https://github.com/unclip12/ExpenWall)

## 🚀 Roadmap

### Version 1.0 (Current)
- [x] Core expense tracking
- [x] Firebase integration
- [x] Budget management
- [x] Product tracking

### Version 1.1 (Next)
- [ ] Charts and analytics
- [ ] Export functionality
- [ ] Recurring transactions
- [ ] Multi-wallet support

### Version 2.0 (Future)
- [ ] AI-powered insights
- [ ] Receipt scanning (OCR)
- [ ] Bill reminders
- [ ] Investment tracking
- [ ] Loan/EMI calculator

## ❤️ Acknowledgments

- Inspired by the web version of ExpenWall
- Built with love for the Flutter community
- Special thanks to all contributors

---

<div align="center">
  <p>Made with ❤️ using Flutter</p>
  <p>⭐ Star this repo if you find it useful!</p>
</div>
