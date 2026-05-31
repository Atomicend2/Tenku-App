# Tenku 🚀
### Connect. Create. Belong.

A modern WhatsApp + Discord hybrid built with Flutter & Firebase.

---

## ✅ What's Built

### Phase 1 — MVP (Complete)
- **Auth**: Sign Up, Login, Email Verification, Forgot Password, Profile Setup
- **Direct Messages**: Send/Edit/Delete, Reply, Reactions ❤️🔥😂, Read Receipts, Typing Indicator
- **Communities**: Create, Join, Leave, Discover public communities
- **Channels**: Text channels (#general), Voice channel placeholders (🎤)
- **Status**: Text & Image statuses, 24hr auto-expiry, story viewer
- **Profiles**: Avatar, Display Name, Bio, Username

### Phase 2 — Added
- **Voice Calls**: Full UI + Agora RTC integration hooks
- **Video Calls**: Full UI with PiP local video + Agora hooks
- **File Sharing**: PDF, DOCX, ZIP, Images, Videos (25MB limit)
- **Search**: Global search for Users and Communities
- **Notifications**: FCM push notifications + in-app notification center

---

## 🔧 Setup Instructions

### Step 1: Install Flutter
```bash
# Install Flutter SDK from https://flutter.dev/docs/get-started/install
flutter --version  # Should be 3.x+
```

### Step 2: Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click **Add Project** → Name it "Tenku"
3. Enable **Google Analytics** (optional)
4. Click **Create Project**

### Step 3: Enable Firebase Services
In Firebase Console, enable:
- **Authentication** → Email/Password
- **Firestore Database** → Start in test mode → choose region
- **Storage** → Start in test mode
- **Cloud Messaging** → No setup needed (auto-enabled)

### Step 4: Configure Firebase in Flutter
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# In the tenku project folder, run:
flutterfire configure
# Select your "Tenku" project
# Select: android, ios, web
# This generates lib/firebase_options.dart automatically
```

### Step 5: Install Dependencies
```bash
cd tenku
flutter pub get
```

### Step 6: Add Google Services files
- **Android**: Download `google-services.json` from Firebase Console → App → Android → place in `android/app/`
- **iOS**: Download `GoogleService-Info.plist` → place in `ios/Runner/`

### Step 7: Update Android build.gradle
`android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

`android/build.gradle` (project level) — add in dependencies:
```gradle
classpath 'com.google.gms:google-services:4.4.1'
```

`android/app/build.gradle` — add at bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### Step 8: Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage:rules
```

### Step 9: Run the App
```bash
# Debug on connected device/emulator
flutter run

# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📱 Phase 2 — Voice & Video Calls Setup

### Get Agora App ID (Free)
1. Go to https://console.agora.io
2. Create account → Create Project
3. Copy your **App ID**
4. Open `lib/services/call_service.dart`
5. Replace `'YOUR_AGORA_APP_ID'` with your actual App ID

### Add Agora to pubspec.yaml
```yaml
agora_rtc_engine: ^6.3.2
```

### Enable Calls in chat_screen.dart
In the `VoiceCallScreen` and `VideoCallScreen`, search for `// TODO: Initialize Agora` and implement:
```dart
// Initialize engine
_agoraEngine = createAgoraRtcEngine();
await _agoraEngine.initialize(RtcEngineContext(appId: CallService.agoraAppId));

// For video only:
await _agoraEngine.enableVideo();

// Join channel
await _agoraEngine.joinChannel(
  token: '',  // Use token in production
  channelId: call.channelId,
  uid: 0,
  options: const ChannelMediaOptions(),
);
```

---

## 🗂️ Project Structure
```
lib/
├── constants/
│   ├── app_constants.dart    # Colors, dimensions, strings
│   └── app_theme.dart        # Material 3 dark theme
├── models/
│   ├── user_model.dart
│   ├── message_model.dart
│   ├── community_model.dart
│   ├── status_model.dart
│   ├── notification_model.dart
├── services/
│   ├── auth_service.dart
│   ├── chat_service.dart
│   ├── community_service.dart
│   ├── status_service.dart
│   ├── storage_service.dart
│   ├── notification_service.dart
│   ├── call_service.dart        # Phase 2
│   ├── file_share_service.dart  # Phase 2
│   └── search_service.dart      # Phase 2
├── providers/
│   └── auth_provider.dart
├── screens/
│   ├── auth/          # Login, Register, Verify, ForgotPw, Setup
│   ├── home/          # Home + Shell
│   ├── chat/          # Chat list + Chat screen
│   ├── community/     # Communities, Detail, Channel, Create
│   ├── status/        # Status feed + Create
│   ├── profile/       # Profile + Edit
│   ├── call/          # Voice call + Video call  (Phase 2)
│   ├── search/        # Global search            (Phase 2)
│   └── notifications/ # Notification center      (Phase 2)
├── widgets/
│   ├── common/        # Avatar, Button, TextField, IncomingCall
│   └── chat/          # File message bubbles
├── utils/
│   └── router.dart
├── firebase_options.dart   # Generated by flutterfire configure
└── main.dart
```

---

## 🗄️ Firestore Collections
```
users/          — User profiles, online status, FCM tokens
chats/          — Direct chat metadata
  └ messages/   — Chat messages
communities/    — Community info, members, roles
channels/       — Community channels
  └ messages/   — Channel messages
statuses/       — 24hr status posts
calls/          — Call records (Phase 2)
notifications/  — User notifications
```

---

## 🚀 Phase 3 (Future)
- AI Assistant (@TenkuAI) — use Anthropic Claude API
- Voice Notes — flutter_sound package
- Pinned Messages
- Polls
- Events / Calendar
- Discord-style Roles system

---

## 🐛 Common Issues

**Build fails with "minSdkVersion"**: Set `minSdkVersion 21` in `android/app/build.gradle`

**Firebase not initialized**: Make sure `flutterfire configure` ran and `firebase_options.dart` exists

**Notifications not working on Android 13+**: Ensure `POST_NOTIFICATIONS` permission is in manifest (already added)

**Image picker doesn't work**: Add storage permissions to AndroidManifest (already added)

---

Built with ❤️ using Flutter + Firebase
"# Tenku-App" 
