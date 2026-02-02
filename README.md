# 📱 ExpenWall Mobile

**Your intelligent wallet manager - now on mobile!**

## ⚠️ For Contributors & AI Assistants

**🔴 IMPORTANT:** Before making any commits or working on this project, read:

### 📋 [DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md)

**This file contains critical rules about:**
- ✅ Phase-based commit strategy (1 Phase = 1 Commit)
- ✅ When builds trigger (version tags only)
- ✅ How to structure work
- ✅ Testing workflow

**Also check:**
- [PROGRESS.md](PROGRESS.md) - Current development status
- [.github/workflows/build-apk.yml](.github/workflows/build-apk.yml) - Build configuration

---

## ✨ Features

### Core Functionality
- 💰 Smart expense tracking with categories
- 📊 Budget management with visual progress
- 🔄 Recurring bills automation
- 👥 Split bills with friends
- 🛒 Shopping list (Buying List)
- 🍕 Cravings tracker
- 🏪 Merchant rules & auto-categorization
- ☁️ Google Drive cloud sync

### UI/UX
- 📱 Beautiful Material 3 UI with glassmorphism
- 🌙 10 theme options (Dark/Light modes)
- ✨ Money flow animations
- 🎨 Gradient backgrounds
- 📊 Expandable tab navigation
- 💫 Smooth 60fps animations

### Smart Features
- 🤖 Auto-categorization (1000+ keywords)
- 📸 Receipt OCR (Phase 1 complete)
- 🔔 Smart notifications
- 📈 Analytics & insights (coming soon)
- 📄 PDF reports (coming soon)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.24.3 or higher
- Dart 3.0+
- Firebase project (configured)
- Java 17+ (for Android builds)

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

### GitHub Actions Builds

APK builds are automated via GitHub Actions:
- **Triggered by:** Version tags (`v2.3.1`, `v2.4.0`, etc.) OR manual trigger
- **NOT triggered by:** Regular commits to main
- **Download:** Go to Actions tab → Latest successful build → Artifacts

See [DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md) for details.

## 🔧 Firebase Setup

This app uses Firebase for:
- **Authentication** - Anonymous/Secret ID login
- **Firestore Database** - Real-time data sync
- **Cloud Storage** - Future use

Firebase configuration is managed via GitHub Secrets for security.

### Required Secrets
- `FIREBASE_OPTIONS_DART` - Firebase options file
- `GOOGLE_SERVICES_JSON` - Google services configuration

## 🎨 Design System

### Themes (10 Available)
1. Midnight Purple (default)
2. Ocean Blue
3. Forest Green
4. Sunset Orange
5. Cherry Blossom
6. Deep Ocean
7. Golden Hour
8. Royal Purple
9. Emerald Dream
10. Rose Gold

### Design Elements
- **GlassCard** - Liquid glass morphism effects
- **ExpandableTabBar** - 65%-35% expansion animation
- **MoneyFlowAnimation** - Particle system for transactions
- **AnimatedGradientBackground** - Pulsating gradients
- **FloatingCurrencySymbols** - Ambient animations

## 📱 Screens & Features

### Dashboard Tab
- Financial overview with summary cards
- Quick stats (income, expenses, balance)
- Recent transactions preview

### Expenses Tab  
- Complete transaction history
- Advanced filters (category, date, merchant)
- Swipe actions (edit, delete)
- Multi-item transaction support

### Planning Tab
- **Buying List** - Shopping list with price tracking
- **Cravings** - Track desired purchases with priority
- **Recurring Bills** - Automated bill reminders
- **Split Bills** - Split expenses with friends

### Social Tab
- **Contacts** - Manage contact list
- **Groups** - Create groups for split bills

### Insights Tab
- Analytics dashboard (coming soon)
- Spending patterns
- Budget analysis

## 🏗️ Architecture

### State Management
- Flutter's built-in `StatefulWidget`
- Service-based architecture
- Local storage with JSON files

### Data Flow
```
UI Layer (Screens/Widgets)
    ↓
Service Layer (Business Logic)
    ↓
Storage Layer (Local + Cloud)
```

### Key Services
- `TransactionService` - Transaction CRUD
- `BudgetService` - Budget management
- `RecurringBillService` - Recurring bills automation
- `SplitBillService` - Split bills logic
- `ContactService` - Contacts & groups
- `LocalStorageService` - JSON file storage
- `CloudSyncService` - Google Drive sync
- `ThemeService` - Theme management
- `ItemRecognitionService` - Smart categorization

## 📊 Current Status

**Version:** v2.3.1 (Split Bills - Testing)  
**Progress:** 85% Complete  
**Next:** Analytics & PDF Reports

See [PROGRESS.md](PROGRESS.md) for detailed status.

## 🔐 Security

- Firebase credentials stored in GitHub Secrets
- Secure authentication with Secret ID
- Firestore security rules
- No sensitive data in source code
- User data isolated by userId

## 🧪 Testing

### Current Testing
- Manual testing via APK builds
- User acceptance testing per phase

### Planned
- Unit tests for services
- Widget tests for UI components
- Integration tests for flows

## 🤝 Contributing

**Before contributing:**

1. Read [DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md) - **MANDATORY**
2. Check [PROGRESS.md](PROGRESS.md) for current status
3. Follow phase-based commit strategy
4. Test changes before committing
5. Update documentation

### Commit Message Format
Use conventional commits:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation only
- `refactor:` - Code refactoring
- `test:` - Testing
- `ci:` - CI/CD changes
- `chore:` - Maintenance

## 📄 License

MIT License - See LICENSE file for details

## 👨‍💻 Author

**unclip12**  
Repository: [github.com/unclip12/ExpenWall-Mobile](https://github.com/unclip12/ExpenWall-Mobile)

---

## 🗺️ Roadmap

- ✅ Core expense tracking
- ✅ Budget management
- ✅ Cloud sync (Google Drive)
- ✅ Themes & animations
- ✅ Recurring bills
- ✅ Split bills
- ✅ Smart categorization (1000+ keywords)
- 🔄 Receipt OCR (Phase 1 done)
- ⏳ Analytics & insights
- ⏳ PDF reports
- ⏳ Advanced charts
- ⏳ SQLite database migration

---

**Built with ❤️ using Flutter**
