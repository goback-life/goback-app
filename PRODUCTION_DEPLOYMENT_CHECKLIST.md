# Production & TestFlight Deployment Checklist

This checklist covers everything you need to prepare your app for production deployment and TestFlight distribution.

## Prerequisites

- [ ] Apple Developer Account (paid membership required for TestFlight)
- [ ] App Store Connect app created with bundle ID: `com.goback.app`
- [ ] Production Supabase project configured and ready
- [ ] Production Firebase project configured
- [ ] Xcode installed and updated
- [ ] Valid code signing certificates and provisioning profiles

---

## 1. Environment Configuration

### 1.1 Create/Update `.env` File

Create a `.env` file in the project root (if it doesn't exist) with production values:

```bash
# Debug mode (set to false for production)
APP_DEBUG=false

# Production Supabase Configuration
SUPABASE_PROJECT_URL=https://your-production-project.supabase.co
SUPABASE_ANON_KEY=your-production-anon-key

# GPG Passphrases for decrypting Firebase configs
GPG_PRESTAGE_CONFIG_PASSPHRASE=your_prestage_passphrase
GPG_STAGE_CONFIG_PASSPHRASE=your_stage_passphrase
GPG_PRODUCTION_CONFIG_PASSPHRASE=your_production_passphrase
```

**⚠️ Important:** 
- Never commit `.env` to version control (should be in `.gitignore`)
- Use production Supabase credentials, not staging
- Keep passphrases secure

### 1.2 Verify Environment Variables

Test that environment variables load correctly:
```bash
# On macOS/Linux
export $(grep -v '^#' .env | xargs)

# On Windows PowerShell
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}
```

---

## 2. Firebase Configuration

### 2.1 Decrypt Production Firebase Config

Decrypt the production Firebase configuration files:

**For macOS/Linux:**
```bash
gpg --batch --yes --passphrase="$GPG_PRODUCTION_CONFIG_PASSPHRASE" \
  --output config/production/google-services.json \
  --decrypt config/production/google-services.json.gpg

gpg --batch --yes --passphrase="$GPG_PRODUCTION_CONFIG_PASSPHRASE" \
  --output config/production/GoogleService-Info.plist \
  --decrypt config/production/GoogleService-Info.plist.gpg
```

**For Windows (PowerShell):**
```powershell
$passphrase = $env:GPG_PRODUCTION_CONFIG_PASSPHRASE
gpg --batch --yes --passphrase="$passphrase" --output config/production/google-services.json --decrypt config/production/google-services.json.gpg
gpg --batch --yes --passphrase="$passphrase" --output config/production/GoogleService-Info.plist --decrypt config/production/GoogleService-Info.plist.gpg
```

### 2.2 Copy Firebase Config to iOS

Ensure the production Firebase config is in the correct location:

```bash
# Create directory if it doesn't exist
mkdir -p ios/Runner/production

# Copy the decrypted file
cp config/production/GoogleService-Info.plist ios/Runner/production/
```

**Verify:**
- [ ] `ios/Runner/production/GoogleService-Info.plist` exists
- [ ] File contains valid Firebase configuration
- [ ] Bundle ID in Firebase config matches `com.goback.app`

---

## 3. iOS Configuration

### 3.1 Update App Version

Update version in `pubspec.yaml`:

```yaml
version: 1.0.1+1  # Format: major.minor.patch+buildNumber
```

**Version Guidelines:**
- Increment `buildNumber` (+1) for each TestFlight build
- Increment `patch` (1.0.1 → 1.0.2) for bug fixes
- Increment `minor` (1.0.x → 1.1.0) for new features
- Increment `major` (1.x.x → 2.0.0) for breaking changes

### 3.2 Fix Entitlements for Production

**⚠️ CRITICAL:** The entitlements file has been updated to use `production` for `aps-environment`, which is required for TestFlight.

**Note:** 
- ✅ **Already fixed:** The entitlements file has been updated to `production`
- ⚠️ **For development builds:** If you need push notifications in development/staging builds, you'll need to either:
  - Temporarily change back to `development` when testing locally
  - Create separate entitlements files per flavor (more complex setup)
- For TestFlight and App Store, `production` is required and correct

### 3.3 Verify Xcode Project Settings

Open the project in Xcode:
```bash
open ios/Runner.xcworkspace
```

Verify in Xcode:

1. **Select Production Scheme:**
   - Product → Scheme → Edit Scheme
   - Select "Release-production" for Archive

2. **Bundle Identifier:**
   - Select Runner target
   - General tab → Bundle Identifier should be `com.goback.app` for production

3. **Signing & Capabilities:**
   - Select Runner target
   - Signing & Capabilities tab
   - [ ] "Automatically manage signing" is checked (or manually configured)
   - [ ] Team is set to your Apple Developer team
   - [ ] Provisioning profile is valid for `com.goback.app`

4. **Deployment Target:**
   - General tab → Minimum Deployments
   - Should be iOS 16.0 or higher (as per Podfile)

5. **Build Configuration:**
   - Product → Scheme → Edit Scheme → Archive
   - Build Configuration should be "Release-production"

### 3.4 Verify Info.plist

Check `ios/Runner/Info.plist`:
- [ ] All permission descriptions are in appropriate languages (currently Italian)
- [ ] `CFBundleDisplayName` is set correctly
- [ ] `ITSAppUsesNonExemptEncryption` is set to `false` (if applicable)

---

## 4. Code & Dependencies

### 4.1 Clean Build

```bash
# Clean Flutter build
fvm flutter clean

# Clean iOS build
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### 4.2 Update Dependencies

```bash
# Get latest dependencies
fvm flutter pub get

# Update pods
cd ios
pod update
cd ..
```

### 4.3 Generate Code

```bash
# Generate code for main project
fvm dart run build_runner build --delete-conflicting-outputs

# Generate code for packages (if needed)
cd packages
for dir in */; do
  if [ -f "${dir}pubspec.yaml" ]; then
    cd "$dir"
    if grep -q "build_runner" pubspec.yaml; then
      fvm dart run build_runner build --delete-conflicting-outputs
    fi
    cd ..
  fi
done
cd ..
```

### 4.4 Run Linter

```bash
fvm flutter analyze
```

Fix any issues before proceeding.

---

## 5. Build for Production

### 5.1 Build iOS Release

```bash
# Build iOS release with production flavor
fvm flutter build ios --release --flavor production
```

**Verify:**
- [ ] Build completes without errors
- [ ] Output shows production bundle ID: `com.goback.app`
- [ ] No warnings about missing configurations

### 5.2 Test Production Build Locally (Optional but Recommended)

Before uploading to TestFlight, test the production build:

```bash
# Run production build on connected device
fvm flutter run --release --flavor production
```

**Test Checklist:**
- [ ] App launches successfully
- [ ] Connects to production Supabase (verify in logs)
- [ ] All features work correctly
- [ ] No crashes or errors
- [ ] Firebase services work (Crashlytics, etc.)

---

## 6. Archive in Xcode

### 6.1 Open Workspace

```bash
open ios/Runner.xcworkspace
```

### 6.2 Select Production Scheme

1. In Xcode toolbar, select scheme: **Runner (production)**
2. Select destination: **Any iOS Device** (not a simulator)

### 6.3 Archive

1. Product → Archive
2. Wait for archive to complete (may take several minutes)
3. Organizer window will open automatically

### 6.4 Verify Archive

In the Organizer:
- [ ] Archive appears in list
- [ ] Version and build number are correct
- [ ] Bundle identifier is `com.goback.app`
- [ ] No warnings or errors

---

## 7. Upload to TestFlight

### 7.1 Distribute App

1. In Xcode Organizer, select your archive
2. Click **Distribute App**
3. Select **App Store Connect**
4. Click **Next**
5. Select **Upload**
6. Click **Next**
7. Review options:
   - [ ] Include bitcode: **No** (Flutter doesn't use bitcode)
   - [ ] Upload symbols: **Yes** (for Crashlytics)
8. Click **Next**
9. Select your distribution certificate and provisioning profile
10. Click **Next**
11. Review summary and click **Upload**
12. Wait for upload to complete

### 7.2 Verify Upload in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app
3. Go to **TestFlight** tab
4. Wait for processing (can take 10-60 minutes)
5. Verify:
   - [ ] Build appears in "iOS Builds"
   - [ ] Processing completes successfully
   - [ ] No compliance issues

### 7.3 Add Test Information (First Time)

If this is your first TestFlight build:
- [ ] Add Test Information (what to test)
- [ ] Add App Description
- [ ] Add Privacy Policy URL (if required)
- [ ] Add Support URL

### 7.4 Add Internal Testers

1. Go to **Internal Testing** section
2. Add internal testers (up to 100)
3. Select the build
4. Click **Start Testing**

---

## 8. Pre-Submission Checklist

Before submitting to App Store Review:

### 8.1 App Store Connect

- [ ] App information is complete
- [ ] Screenshots uploaded (all required sizes)
- [ ] App description written
- [ ] Keywords added
- [ ] Support URL provided
- [ ] Privacy Policy URL provided (if required)
- [ ] Age rating completed
- [ ] App pricing set

### 8.2 Compliance

- [ ] Export compliance information completed
- [ ] Content rights verified
- [ ] Advertising identifier usage declared (if applicable)

### 8.3 Testing

- [ ] Tested on multiple iOS devices
- [ ] Tested on different iOS versions
- [ ] All features work correctly
- [ ] No crashes or critical bugs
- [ ] Performance is acceptable

---

## 9. Common Issues & Solutions

### Issue: "aps-environment" mismatch

**Problem:** Entitlements file has `development` but needs `production`

**Solution:** Update `ios/Runner/Runner.entitlements` as described in section 3.2

### Issue: Missing Firebase config

**Problem:** Build fails with missing GoogleService-Info.plist

**Solution:** 
1. Decrypt Firebase config (section 2.1)
2. Copy to `ios/Runner/production/` (section 2.2)
3. Verify firebaseScript.sh runs during build

### Issue: Code signing errors

**Problem:** "No signing certificate" or "Provisioning profile not found"

**Solution:**
1. Open Xcode → Preferences → Accounts
2. Add your Apple ID
3. Download certificates and profiles
4. In project settings, select correct team and profile

### Issue: Environment variables not loading

**Problem:** App crashes with "SUPABASE_PROJECT_URL not configured"

**Solution:**
1. Verify `.env` file exists in project root
2. Check `.env` is included in `pubspec.yaml` assets
3. Ensure environment service initializes before Supabase

### Issue: Build fails with pod errors

**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod deintegrate
pod install
cd ..
fvm flutter clean
fvm flutter pub get
```

---

## 10. Post-Deployment

### 10.1 Monitor TestFlight Feedback

- [ ] Check TestFlight feedback from testers
- [ ] Monitor crash reports in Firebase Crashlytics
- [ ] Review analytics data

### 10.2 Prepare for App Store Submission

Once TestFlight testing is complete:
1. Fix any critical issues
2. Increment version number
3. Create new archive
4. Submit for App Store Review

---

## Quick Reference Commands

```bash
# 1. Set environment variables (Windows PowerShell)
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

# 2. Decrypt Firebase config
gpg --batch --yes --passphrase="$env:GPG_PRODUCTION_CONFIG_PASSPHRASE" --output config/production/GoogleService-Info.plist --decrypt config/production/GoogleService-Info.plist.gpg

# 3. Copy Firebase config
mkdir -p ios/Runner/production
cp config/production/GoogleService-Info.plist ios/Runner/production/

# 4. Clean and build
fvm flutter clean
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter build ios --release --flavor production

# 5. Open Xcode
open ios/Runner.xcworkspace
```

---

## Notes

- **Never commit `.env` file** - it contains sensitive credentials
- **Always test production builds locally** before uploading to TestFlight
- **Increment build number** for each TestFlight upload
- **Keep staging and production environments separate**
- **Monitor Firebase Crashlytics** after deployment

---

**Last Updated:** Based on current project structure
**Next Steps:** Follow this checklist in order, checking off each item as you complete it.

