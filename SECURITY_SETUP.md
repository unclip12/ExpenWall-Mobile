# 🔒 Security Setup Guide

**How to set up GitHub Secrets for Firebase configuration**

---

## ⚠️ Why Use GitHub Secrets?

Firebase configuration files contain API keys that should NOT be committed to public repositories. This project uses **GitHub Secrets** to:

✅ Keep API keys secure
✅ Prevent unauthorized access
✅ Follow security best practices
✅ Avoid GitHub security warnings

The build workflow automatically creates config files from secrets during the build process.

---

## 📝 Required Secrets

You need to add **2 secrets** to your GitHub repository:

1. `GOOGLE_SERVICES_JSON` - Android Firebase config
2. `FIREBASE_OPTIONS_DART` - Flutter Firebase config

---

## 🛠️ Step-by-Step Setup

### Step 1: Go to Repository Settings

1. Go to your repository: https://github.com/unclip12/ExpenWall-Mobile
2. Click **"Settings"** tab
3. In left sidebar: **"Secrets and variables"** > **"Actions"**

### Step 2: Get Firebase Configuration

#### For google-services.json:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** (gear icon)
4. Under "Your apps" → Select/Add Android app
5. Download `google-services.json`
6. **Base64 encode it:**
   ```bash
   # On Linux/Mac:
   base64 -w 0 google-services.json
   
   # On Windows (PowerShell):
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("google-services.json"))
   ```
7. Copy the base64 output

#### For firebase_options.dart:

1. In your Flutter project, run:
   ```bash
   flutterfire configure
   ```
2. This creates `lib/firebase_options.dart`
3. **Base64 encode it:**
   ```bash
   # On Linux/Mac:
   base64 -w 0 lib/firebase_options.dart
   
   # On Windows (PowerShell):
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("lib\firebase_options.dart"))
   ```
4. Copy the base64 output

### Step 3: Add Secrets to GitHub

#### Add GOOGLE_SERVICES_JSON:

1. Click **"New repository secret"**
2. Name: `GOOGLE_SERVICES_JSON`
3. Value: [paste base64 string from Step 2]
4. Click **"Add secret"**

#### Add FIREBASE_OPTIONS_DART:

1. Click **"New repository secret"**
2. Name: `FIREBASE_OPTIONS_DART`
3. Value: [paste base64 string from Step 2]
4. Click **"Add secret"**

### Step 4: Verify

You should see 2 secrets listed:
- ✅ `GOOGLE_SERVICES_JSON`
- ✅ `FIREBASE_OPTIONS_DART`

---

## 🚀 Testing the Setup

### Trigger a Build:

1. Go to **Actions** tab
2. Select **"Build Flutter APK"** workflow
3. Click **"Run workflow"** > **"Run workflow"**
4. Wait ~5-7 minutes
5. Download APK from "Artifacts" section

### Or Push a Commit:

Any push to `main` branch will automatically trigger a build.

---

## 💻 Local Development

For local development, you DON'T need GitHub Secrets. Instead:

1. Download `google-services.json` from Firebase Console
2. Place in `android/app/`
3. Run `flutterfire configure` to create `firebase_options.dart`
4. These files are **gitignored** and won't be committed

---

## 🔐 Security Best Practices

✅ **Never commit** Firebase config files
✅ **Always use** .gitignore for sensitive files
✅ **Store secrets** in GitHub Secrets or .env files
✅ **Rotate keys** if accidentally exposed
✅ **Enable Firebase Security Rules** in Firestore

---

## ❓ FAQ

**Q: Are Firebase API keys supposed to be secret?**

A: Firebase client-side keys are meant to be in mobile apps, BUT storing them in GitHub Secrets is still best practice to:
- Prevent automated scraping
- Follow security guidelines
- Avoid GitHub warnings

Real security comes from **Firebase Security Rules**!

**Q: What if I accidentally commit API keys?**

A: 
1. Remove them from code immediately
2. Add to .gitignore
3. Rotate the keys in Firebase Console
4. Consider using BFG Repo-Cleaner to clean git history

**Q: Can I see the secret values after adding them?**

A: No! GitHub only shows secret names, not values. You'll need to re-add if you lose them.

---

## 📞 Need Help?

If you have issues:
- Check build logs in Actions tab
- Verify secrets are named exactly as shown
- Ensure base64 encoding is correct
- Open an issue if stuck!

---

**That's it! Your repository is now secure!** 🔒✅
