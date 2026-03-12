# 🛠️ ExpenWall Mobile — Development Guide

## 📦 Tech Stack
| Layer | Technology |
|-------|------------|
| Framework | Flutter (Dart) |
| State Management | Riverpod / Provider |
| Backend | Firebase (Auth + Firestore + Storage) |
| OCR | Google ML Kit |
| AI Insights | Gemini API |
| Charts | fl_chart |
| CI/CD | GitHub Actions |

---

## 🏗️ Project Structure
```
lib/
├── core/
│   ├── theme/        # Dark fintech design system
│   ├── utils/        # Currency formatter, date helpers
│   └── widgets/      # ExpenseCard, BudgetRing, etc.
├── features/
│   ├── auth/         # Login, signup
│   ├── dashboard/    # Main spending overview
│   ├── expenses/     # Add, edit, list expenses
│   ├── scanner/      # Receipt OCR scanner
│   ├── budget/       # Budget manager
│   ├── analytics/    # Charts, trends, reports
│   ├── cravings/     # Impulse spend tracker
│   └── settings/     # Profile, preferences
├── services/
│   ├── firebase/     # Firestore, Auth, Storage
│   ├── ocr/          # ML Kit receipt parsing
│   └── ai/           # Gemini API insights
test/
```

---

## 🤖 AI Development Workflow
See `.github/agents/README.md` for the full agent suite.

### Quick Reference
- **OCR features** → `AI_ENGINEER.md`
- **Flutter screens** → `MOBILE_APP_BUILDER.md`
- **Charts & UI** → `UI_DESIGNER.md`
- **Firebase rules** → `SECURITY_ENGINEER.md`

---

## 🔒 Security Checklist (Pre-Release)
- [ ] `google-services.json` in `.gitignore`
- [ ] Receipt images use signed URLs (not public)
- [ ] Firestore rules validate amount > 0
- [ ] No financial amounts logged in crash reports
- [ ] Firebase App Check enabled
- [ ] Release build obfuscated

---

## 📅 Open Issues
Check [GitHub Issues](https://github.com/unclip12/ExpenWall-Mobile/issues) for current bugs and feature requests.

---

*See `.github/agents/` for AI development agent prompts.*
