# 🔒 Security Policy — ExpenWall Mobile

## What Is Protected

ExpenWall handles **financial data** — expense amounts, merchant names, receipt images, spending patterns. This requires higher security standards than a typical app.

---

## ❌ Files That Must NEVER Be Committed

| File | Why It's Dangerous |
|------|--------------------|
| `android/app/google-services.json` | Firebase API keys — gives full Firestore/Storage access |
| `ios/Runner/GoogleService-Info.plist` | Same for iOS |
| `lib/firebase_options.dart` | Firebase project config |
| `*.jks` / `*.keystore` | Android signing — can fake your app identity |
| `key.properties` | Keystore password in plaintext |
| `.env` | API keys including Gemini API key |
| `.cognetivy/` | AI session history with financial logic context |
| `.cursor/mcp.json` | MCP server config |
| `.antigravity/` | Antigravity agent session data |
| `/receipts_local/` | User receipt images (PII) |

All covered in `.gitignore`.

---

## ✅ How Secrets Are Managed

- Firebase config files generated during CI/CD from GitHub Secrets
- Keystore stored as `ANDROID_KEYSTORE_BASE64` in GitHub Secrets  
- Gemini API key stored as `GEMINI_API_KEY` in GitHub Secrets
- No secrets are ever hardcoded in source code

---

## 🤖 AI Agent Safety (Codex / Antigravity)

ExpenWall uses AI agents for development. Follow these rules:

1. **Never paste Firebase config** into Codex/Antigravity chat — use `YOUR_API_KEY` placeholders
2. **Never share receipt image paths** that contain real user data in prompts
3. **Never paste Gemini API key** into any AI chat
4. **Add `.cognetivy/` to `.gitignore`** before using Cognetivy (already done)
5. Codex and Antigravity **read your entire repo** when you give them access — zero secrets should exist in code
6. Review ALL files AI creates before committing — agents sometimes hallucinate hardcoded values

---

## 🚨 Agency Agents Safety Note

The `.github/agents/` folder contains **plain Markdown prompt files only**.
They are safe to be public. They contain:
- ✅ Flutter architecture patterns
- ✅ Firestore schema descriptions (no values)
- ✅ UI design guidelines
- ❌ NO API keys, passwords, or real user data

---

## 💰 Financial Data Rules

- Store amounts as **integers (paise/cents)** — never floats
- Never log expense amounts in crash reports or analytics
- Receipt images in Firebase Storage must use **signed URLs only** (never public)
- Delete receipts from Storage when the expense is deleted
- Firestore rules must enforce `request.auth.uid == userId` on all user data

---

## 📣 Reporting a Vulnerability

Do not open a public GitHub issue. Use GitHub Security Advisories for private disclosure.
