# Release Signing Setup Guide

This guide will help you set up proper release signing for your ExpenWall Mobile app so that APKs build on GitHub Actions can be installed on any Android device.

---

## 🔑 Step 1: Generate Release Keystore

### On Windows:
```bash
keytool -genkey -v -keystore expenwall-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias expenwall-key
```

### On Mac/Linux:
```bash
keytool -genkey -v -keystore expenwall-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias expenwall-key
```

### You'll be prompted for:
1. **Keystore password**: Enter a strong password (e.g., `MySecurePassword123`)
2. **Re-enter keystore password**: Same password again
3. **First and last name**: Your name or company name
4. **Organizational unit**: Can press Enter to skip
5. **Organization**: Can press Enter to skip
6. **City/Locality**: Can press Enter to skip
7. **State/Province**: Can press Enter to skip
8. **Country code**: Two-letter code (e.g., `IN` for India)
9. **Key password**: Press Enter to use same as keystore password

### Important:
- **SAVE THE PASSWORDS!** Write them down securely
- **BACKUP THE .jks FILE!** If you lose it, you can't update your app
- The keystore is valid for 10,000 days (~27 years)

---

## 📦 Step 2: Convert Keystore to Base64

GitHub secrets can't store binary files directly, so we convert the keystore to base64 text.

### On Windows (PowerShell):
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("expenwall-release-key.jks")) | Out-File keystore-base64.txt
```

### On Mac/Linux:
```bash
base64 expenwall-release-key.jks > keystore-base64.txt
```

This creates a `keystore-base64.txt` file with encoded content.

---

## 🔐 Step 3: Add Secrets to GitHub

1. Go to your repository: **https://github.com/unclip12/ExpenWall-Mobile**

2. Click **Settings** (top menu)

3. In left sidebar, click **Secrets and variables** → **Actions**

4. Click **New repository secret** and add these 4 secrets:

### Secret 1: KEYSTORE_BASE64
- **Name**: `KEYSTORE_BASE64`
- **Value**: Open `keystore-base64.txt` and copy ALL the content (it's very long!)
- Click **Add secret**

### Secret 2: KEYSTORE_PASSWORD
- **Name**: `KEYSTORE_PASSWORD`
- **Value**: The password you entered when creating the keystore
- Click **Add secret**

### Secret 3: KEY_ALIAS
- **Name**: `KEY_ALIAS`
- **Value**: `expenwall-key` (this is from the `-alias` in the keytool command)
- Click **Add secret**

### Secret 4: KEY_PASSWORD
- **Name**: `KEY_PASSWORD`
- **Value**: Same as KEYSTORE_PASSWORD (if you pressed Enter when asked for key password)
- Click **Add secret**

---

## ✅ Step 4: Verify Setup

1. After adding all 4 secrets, push any change to trigger a build

2. Go to **Actions** tab and wait for the build to complete

3. In the build summary, you should see:
   ```
   ✅ Properly Signed Release APK
   - Signed with release keystore
   - Will install on all devices
   - Production-ready build
   ```

4. Download the APK and install it on your phone - it should work!

---

## 🛡️ Security Best Practices

1. **Never commit the .jks file to Git**
   - Already in .gitignore
   - Only upload to GitHub Secrets

2. **Backup the keystore securely**
   - Store in password manager
   - Keep offline backup
   - If lost, you cannot update your app!

3. **Use strong passwords**
   - Minimum 12 characters
   - Mix of letters, numbers, symbols

4. **Don't share the passwords**
   - Only you should know them
   - GitHub Secrets are encrypted and hidden

---

## 🐞 Troubleshooting

### Build still uses debug signature
**Problem**: Build summary shows "Debug Signed APK"

**Solution**: Check that all 4 secrets are added correctly:
- Go to Settings → Secrets and variables → Actions
- Verify: KEYSTORE_BASE64, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD
- Secret names must match EXACTLY (case-sensitive)

### Base64 encoding fails
**Problem**: Can't encode the keystore file

**Solution**:
- Make sure you're in the same directory as the .jks file
- Check the file exists: `ls expenwall-release-key.jks`
- Try the command again

### APK still won't install
**Problem**: Even with proper signing, installation fails

**Solution**:
1. Uninstall ALL previous versions of ExpenWall
2. Restart your phone
3. Download fresh APK from latest build
4. Enable "Install from Unknown Sources" in Settings
5. Try installing again

### Forgot keystore password
**Problem**: Lost the password

**Solution**: Unfortunately, there's NO WAY to recover it. You must:
1. Generate a NEW keystore with a NEW alias
2. Update GitHub Secrets with new values
3. This will be treated as a NEW app (users must uninstall old version)

---

## 📝 Notes

- The keystore is used for BOTH release builds on GitHub Actions AND local release builds
- Debug builds (for development) don't use this keystore
- Each release must be signed with the SAME keystore to allow updates
- Google Play Store (if you publish later) requires the same signature

---

## 🚀 Quick Reference

### Generate Keystore:
```bash
keytool -genkey -v -keystore expenwall-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias expenwall-key
```

### Encode to Base64 (Linux/Mac):
```bash
base64 expenwall-release-key.jks > keystore-base64.txt
```

### Encode to Base64 (Windows PowerShell):
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("expenwall-release-key.jks")) | Out-File keystore-base64.txt
```

### GitHub Secrets Required:
1. `KEYSTORE_BASE64` - Content of keystore-base64.txt
2. `KEYSTORE_PASSWORD` - Your keystore password
3. `KEY_ALIAS` - `expenwall-key`
4. `KEY_PASSWORD` - Same as keystore password

---

**Need help?** Open an issue in the repository with details about the error you're facing.
