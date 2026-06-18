# Build and Release Guide

This document defines build, signing, and release procedures for the Flutter mobile application on Android and iOS platforms.

**Current Implementation:** The current app is a backend-connected Flutter MVP with Material 3 UI, authentication wiring, contribution/review workflows, and knowledge browsing. Production wiring uses remote repositories against the Laravel API configured by `API_BASE_URL`.

**Target:** Production-ready builds for Google Play Store and Apple App Store with proper signing, environment configuration, and security hardening.

---

## Prerequisites

### Development Environment

| Requirement | Version | Notes |
| :--- | :--- | :--- |
| Flutter SDK | 3.19+ | Stable channel recommended |
| Dart SDK | 3.3+ | Bundled with Flutter |
| Android Studio | 2023.1+ | For Android builds |
| Xcode | 15.0+ | For iOS builds (macOS only) |
| Java JDK | 17+ | For Android builds |
| CocoaPods | 1.14+ | For iOS dependencies |
| Git | 2.40+ | Version control |

### Platform-Specific Requirements

#### Android
- Android SDK (API 34+ recommended)
- Android SDK Build-Tools
- Android SDK Platform-Tools
- Keystore for release signing

#### iOS
- macOS (required for Xcode)
- Apple Developer Account ($99/year)
- Signing certificates and provisioning profiles
- App Store Connect account access

---

## Environment Configuration

### Build Modes

| Mode | Purpose | Command Flag |
| :--- | :--- | :--- |
| Debug | Development and testing | `--debug` (default) |
| Profile | Performance testing | `--profile` |
| Release | Production deployment | `--release` |

### Environment Variables

The app uses `--dart-define` flags for environment configuration. Never commit sensitive values to version control.

| Variable | Description | Example |
| :--- | :--- | :--- |
| `API_BASE_URL` | Laravel API endpoint | `https://api.gamelan.app/api/v1` |
| `APP_VERSION` | App version string | `1.0.0` |
| `BUILD_NUMBER` | Build iteration | `1` |
| `ENVIRONMENT` | Environment tag | `production`, `staging`, `development` |

### Configuration Files

Create environment-specific configuration files (not committed to git):

```
docs/
├── BUILD_RELEASE.md (this file)
└── .env.local (gitignored, for local development)
```

Example `.env.local`:
```bash
API_BASE_URL=http://127.0.0.1:8000/api/v1
ENVIRONMENT=development
```

---

## Android Build and Release

### Step 1: Configure Android Signing

1. **Generate Upload Keystore** (one-time, keep secure):
   ```bash
   keytool -genkey -v -keystore gamelan-upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias gamelan-upload
   ```

2. **Store Keystore Securely:**
   - Never commit keystore to git
   - Use secure secret management (e.g., GitHub Secrets, CI/CD vault)
   - Backup keystore and passwords in multiple secure locations

3. **Create `android/key.properties`:**
   ```properties
   storePassword=<keystore-password>
   keyPassword=<key-password>
   keyAlias=gamelan-upload
   storeFile=<path-to-keystore>
   ```
   Add `android/key.properties` to `.gitignore`.

4. **Update `android/app/build.gradle`:**
   ```gradle
   android {
       ...
       signingConfigs {
           release {
               if (project.hasProperty('storeFile')) {
                   storeFile file(storeFile)
                   storePassword storePassword
                   keyAlias keyAlias
                   keyPassword keyPassword
               }
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
               minifyEnabled true
               shrinkResources true
               proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
           }
       }
   }
   ```

### Step 2: Update Android Manifest

Ensure `android/app/src/main/AndroidManifest.xml` includes:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
    
    <application
        android:label="Balinese Gamelan Knowledge"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false">
        ...
    </application>
</manifest>
```

**Security Note:** `usesCleartextTraffic="false"` enforces HTTPS for all network requests (required by `SECURITY_PRIVACY.md`).

### Step 3: Build Android Release

```bash
# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Build APK (for testing/distribution)
flutter build apk --release \
  --dart-define=API_BASE_URL=https://gamelan.madewardana.com/api/v1 \
  --dart-define=ENVIRONMENT=production

# Build App Bundle (for Google Play Store)
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://gamelan.madewardana.com/api/v1 \
  --dart-define=ENVIRONMENT=production
```

**Output Locations:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

### Step 4: Google Play Store Submission

1. **Create App Listing** in Google Play Console
2. **Upload App Bundle** (`.aab` file, not APK)
3. **Complete Store Listing:**
   - App name: "Balinese Gamelan Knowledge"
   - Short description: "Community-driven Balinese gamelan knowledge management"
   - Full description: Include features, cultural context, and privacy commitments
   - Screenshots: 2-8 images (phone and tablet)
   - Feature graphic: 1024x500px
   - App icon: 512x512px
4. **Content Rating:** Complete questionnaire
5. **Privacy Policy:** URL to hosted privacy policy (required by `SECURITY_PRIVACY.md`)
6. **Target Audience:** Set age restrictions appropriately
7. **Release Track:** Choose Internal Testing → Closed Testing → Open Testing → Production

---

## iOS Build and Release

### Step 1: Configure iOS Signing

1. **Enroll in Apple Developer Program** ($99/year)

2. **Create Signing Certificate:**
   - Log in to [Apple Developer Portal](https://developer.apple.com)
   - Navigate to Certificates, IDs & Profiles
   - Create "Apple Distribution" certificate
   - Download and install in Keychain Access

3. **Create App ID:**
   - Bundle Identifier: `com.gamelan.app` (or your domain)
   - Enable required capabilities (Push Notifications if needed)

4. **Create Provisioning Profile:**
   - Type: Distribution (App Store)
   - Select App ID and Certificate
   - Download and install

5. **Configure in Xcode:**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target → Signing & Capabilities
   - Enable "Automatically manage signing" (recommended) or manual
   - Select Team and Bundle Identifier

### Step 2: Update iOS Configuration

1. **Update `ios/Runner/Info.plist`:**
   ```xml
   <key>CFBundleName</key>
   <string>Balinese Gamelan Knowledge</string>
   <key>CFBundleDisplayName</key>
   <string>Gamelan Knowledge</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>This app requires photo access to attach media to contributions.</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>This app requires microphone access to record audio for contributions.</string>
   <key>NSCameraUsageDescription</key>
   <string>This app requires camera access to capture media for contributions.</string>
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSAllowsArbitraryLoads</key>
       <false/>
   </dict>
   ```

   **Security Note:** `NSAllowsArbitraryLoads=false` enforces HTTPS (required by `SECURITY_PRIVACY.md`).

2. **Update `ios/Runner.xcodeproj/project.pbxproj`:**
   - Set `PRODUCT_BUNDLE_IDENTIFIER` to match App ID
   - Set `CURRENT_PROJECT_VERSION` (build number)
   - Set `MARKETING_VERSION` (version string)

### Step 3: Build iOS Release

```bash
# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Build iOS
flutter build ios --release \
  --dart-define=API_BASE_URL=https://gamelan.madewardana.com/api/v1 \
  --dart-define=ENVIRONMENT=production
```

**Output Location:** `build/ios/iphoneos/Runner.app`

### Step 4: Archive and Upload to App Store Connect

1. **Open in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Select Generic iOS Device** as target

3. **Product → Archive**

4. **Organizer Window Opens:**
   - Select the archive
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Choose "Upload"
   - Follow signing and export options
   - Upload

5. **Alternative (Command Line):**
   ```bash
   xcodebuild -workspace ios/Runner.xcworkspace \
     -scheme Runner \
     -configuration Release \
     -archivePath build/ios/archive/Runner.xcarchive \
     archive
   
   xcodebuild -exportArchive \
     -archivePath build/ios/archive/Runner.xcarchive \
     -exportPath build/ios/ipa \
     -exportOptionsPlist ios/ExportOptions.plist
   ```

### Step 5: App Store Connect Submission

1. **Create App Listing** in App Store Connect
2. **Select Build** from uploaded builds (may take 15-30 min to process)
3. **Complete App Information:**
   - App name: "Balinese Gamelan Knowledge"
   - Subtitle: "Community Gamelan Knowledge"
   - Description: Include features and cultural context
   - Keywords: gamelan, balinese, music, culture, knowledge
   - Screenshots: Required for all supported device sizes
   - App Preview Video: Optional (15-30 seconds)
   - App Icon: 1024x1024px
4. **Privacy Details:** Complete App Privacy questionnaire
5. **Content Rights:** Confirm you have rights to all content
6. **Age Rating:** Complete rating questionnaire
7. **Release Options:**
   - Manual release
   - Automatic release after approval
   - Phased release over 7 days (recommended)
8. **Submit for Review**

---

## Version Management

### Version Numbering

Follow semantic versioning: `MAJOR.MINOR.PATCH`

| Component | When to Increment | Example |
| :--- | :--- | :--- |
| MAJOR | Breaking changes, workflow changes | 1.0.0 → 2.0.0 |
| MINOR | New features, ontology extensions | 1.0.0 → 1.1.0 |
| PATCH | Bug fixes, security patches | 1.0.0 → 1.0.1 |

### Update Version in `pubspec.yaml`:

```yaml
name: gamelan_app
description: Balinese Gamelan Knowledge Management Application
version: 1.0.0+1  # version+build_number
```

### Version Checklist Before Release

- [ ] Update `pubspec.yaml` version
- [ ] Update `CHANGELOG.md` with release notes
- [ ] Verify API compatibility (check `docs/API_CONTRACT.md`)
- [ ] Run full test suite (`flutter test`, `flutter analyze`)
- [ ] Test on physical devices (Android and iOS)
- [ ] Verify environment configuration for production
- [ ] Confirm backend API is production-ready
- [ ] Review security checklist (`docs/SECURITY_PRIVACY.md`)

---

## CI/CD Integration

### GitHub Actions Example

Create `.github/workflows/build-release.yml`:

```yaml
name: Build and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: |
          echo "${{ secrets.ANDROID_KEYSTORE }}" | base64 --decode > android/app/gamelan-upload-keystore.jks
          echo "storePassword=${{ secrets.ANDROID_STORE_PASSWORD }}" > android/key.properties
          echo "keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}" >> android/key.properties
          echo "keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}" >> android/key.properties
          echo "storeFile=gamelan-upload-keystore.jks" >> android/key.properties
      - run: |
          flutter build appbundle --release \
            --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }} \
            --dart-define=ENVIRONMENT=production
      - uses: actions/upload-artifact@v4
        with:
          name: app-release
          path: build/app/outputs/bundle/release/app-release.aab

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build ios --release \
          --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }} \
          --dart-define=ENVIRONMENT=production
      # Note: iOS signing requires additional certificate provisioning
```

### Environment Secrets

Store these in CI/CD secret management (never in code):

| Secret | Description |
| :--- | :--- |
| `API_BASE_URL` | Production API endpoint |
| `ANDROID_KEYSTORE` | Base64-encoded keystore file |
| `ANDROID_STORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | Key alias |
| `IOS_CERTIFICATE` | Base64-encoded signing certificate |
| `IOS_PROVISIONING_PROFILE` | Base64-encoded provisioning profile |
| `APP_STORE_CONNECT_API_KEY` | App Store Connect API key for automation |

---

## Testing Before Release

### Pre-Release Checklist

| Check | Android | iOS | Status |
| :--- | :--- | :--- | :--- |
| Build compiles without errors | ☐ | ☐ | |
| All widget tests pass | ☐ | ☐ | |
| Integration tests pass | ☐ | ☐ | |
| `flutter analyze` clean | ☐ | ☐ | |
| Authentication flow works | ☐ | ☐ | |
| Contribution submission works | ☐ | ☐ | |
| Review workflow works | ☐ | ☐ | |
| Search functionality works | ☐ | ☐ | |
| Media upload works | ☐ | ☐ | |
| Token storage is secure | ☐ | ☐ | |
| HTTPS enforced | ☐ | ☐ | |
| No sensitive data in logs | ☐ | ☐ | |
| App icon and splash screen | ☐ | ☐ | |
| Permissions declared correctly | ☐ | ☐ | |

### Device Testing Matrix

| Platform | Minimum OS | Target OS | Devices to Test |
| :--- | :--- | :--- | :--- |
| Android | API 24 (7.0) | API 34 (14) | Phone, Tablet |
| iOS | iOS 15.0 | iOS 17+ | iPhone, iPad |

### Staging Environment

Before production release, test against staging backend:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://staging-api.gamelan.app/api/v1 \
  --dart-define=ENVIRONMENT=staging
```

---

## Post-Release

### Monitoring

1. **Google Play Console:**
   - Android Vitals (crashes, ANRs)
   - User reviews and ratings
   - Installation statistics

2. **App Store Connect:**
   - App Analytics
   - Crash reports
   - Reviews and ratings

3. **Backend Monitoring:**
   - API error rates
   - Authentication failures
   - Contribution submission rates

### Hotfix Procedure

For critical bugs requiring immediate fix:

1. Create hotfix branch from release tag
2. Fix issue and test thoroughly
3. Increment PATCH version (e.g., 1.0.0 → 1.0.1)
4. Build and submit to stores
5. Use "Phased Release" for iOS to monitor crash rates
6. Document in `CHANGELOG.md`

### Deprecation Policy

When releasing MAJOR version updates:

1. Announce deprecation timeline (minimum 30 days)
2. Support at least 2 previous MINOR versions
3. Update `README.md` with supported versions
4. Communicate breaking changes clearly

---

## Security Checklist

### Before Every Release

- [ ] `API_BASE_URL` points to production endpoint (not localhost/staging)
- [ ] No debug logging enabled in release build
- [ ] No sensitive data hardcoded in source code
- [ ] Keystore and signing credentials stored securely (not in git)
- [ ] HTTPS enforced (no cleartext traffic)
- [ ] Access tokens stored in secure storage (`flutter_secure_storage`)
- [ ] Privacy policy URL is valid and accessible
- [ ] App permissions are minimal and documented
- [ ] No unpublished or sensitive knowledge exposed in build
- [ ] Backend authorization is enforced (not just mobile UI gating)
- [ ] Rate limiting configured on backend
- [ ] Cultural sensitivity rules enforced per `docs/SECURITY_PRIVACY.md`

### App Store Compliance

- [ ] Privacy policy hosted and linked
- [ ] App privacy questionnaire completed accurately
- [ ] Content rights confirmed
- [ ] Age rating appropriate for cultural content
- [ ] Terms of service accessible
- [ ] Contact information provided
- [ ] Data collection disclosed (authentication, contributions, media)

---

## Troubleshooting

### Common Build Issues

| Issue | Solution |
| :--- | :--- |
| `flutter build` fails on Android | Run `flutter clean`, check `key.properties`, verify JDK version |
| iOS build fails on signing | Check certificate validity, provisioning profile, bundle identifier match |
| API calls fail in release | Verify `API_BASE_URL` dart-define, check HTTPS, verify backend CORS |
| App crashes on startup | Check `/me` endpoint availability, token storage, null safety |
| Media upload fails | Verify permissions in manifest/Info.plist, check file size limits |
| Large APK size | Enable `minifyEnabled`, `shrinkResources`, check asset compression |

### Useful Commands

```bash
# Check Flutter health
flutter doctor -v

# Clean and rebuild
flutter clean && flutter pub get

# Run tests
flutter test

# Analyze code
flutter analyze

# Build with verbose logging
flutter build apk --release -v

# Check app size
flutter build apk --release --analyze-size

# List connected devices
flutter devices

# Run on specific device
flutter run --device-id <device-id>
```

---

## Release Notes Template

Create `CHANGELOG.md` entries following this format:

```markdown
## [1.0.0] - 2026-05-23

### Added
- Initial release with contribution and review workflows
- Backend authentication integration
- Knowledge browsing, semantic-first search, and keyword fallback
- Media attachment support
- Role-aware review UI
- Backend-authorized RDF publication queueing UI

### Security
- HTTPS enforced for all API calls
- Secure token storage
- Cultural sensitivity protections per SECURITY_PRIVACY.md

### Known Issues
- Offline sync not yet implemented (target: v1.1.0)
- Production admin screens not yet implemented
```

---

## References

| Document | Purpose |
| :--- | :--- |
| `docs/SECURITY_PRIVACY.md` | Security and privacy requirements |
| `docs/API_CONTRACT.md` | API endpoint specifications |
| `docs/CODE_STYLE.md` | Code naming and style conventions |
| `docs/MOBILE_APP_GUIDE.md` | Mobile app architecture and standards |
| `docs/CROWDSOURCING_WORKFLOW.md` | Contribution and review workflow |
| `README.md` | Project overview and current state |

---

## Next Steps After Release

1. Monitor crash reports and user feedback for 7 days
2. Plan v1.1.0 features (offline sync, enhanced search)
3. Gather community feedback on contribution workflow
4. Review ontology extensions for v1.2.0 (per `docs/ONTOLOGY_GUIDE.md`)
5. Consider localization (Indonesian, Balinese) per `docs/MOBILE_APP_GUIDE.md`
