# Firebase Authentication Implementation

## Current Status

✅ **Authentication**: Firebase Authentication with Email/Password
✅ **Database**: Firestore for user roles and data
✅ **Dependencies**: Added firebase_core, firebase_auth, cloud_firestore

## Implemented Features

### 1. Firebase Configuration
- Created `firebase_options.dart` with Android and iOS configurations
- Updated `main.dart` to initialize Firebase on app startup

### 2. Firebase Auth Service
- Updated `firebase_service.dart` with real Firebase Authentication
- Supports email/password sign-in and sign-up
- Fetches user role from Firestore `users` collection
- Handles authentication state changes

### 3. Role-Based Access Control
Three user roles supported:
1. **User** - `user@cctv.app` / `user@123`
2. **Admin** - `admin@cctv.app` / `admin@123`
3. **Super Admin** - `superadmin@cctv.app` / `superadmin@123`

### 4. Sign-In Flow
- Updated `signin_view.dart` to use Firebase Authentication
- Automatically determines dashboard type based on user role
- Stores authentication token and user data in secure storage

## Setup Instructions

### Step 1: Update Firebase Configuration

Replace the placeholder values in `lib/core/firebase/firebase_options.dart` with your actual Firebase project credentials:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `commctv-f2b45`
3. Go to Project Settings → General
4. Add Android and iOS apps
5. Download configuration files:
   - Android: `google-services.json` → place in `android/app/`
   - iOS: `GoogleService-Info.plist` → place in `ios/Runner/`

### Step 2: Update Firebase Options

Update `lib/core/firebase/firebase_options.dart` with actual values from your Firebase project:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY',
  appId: 'YOUR_ACTUAL_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'commctv-f2b45',
  storageBucket: 'commctv-f2b45.appspot.com',
);
```

### Step 3: Create Firebase Users

In Firebase Console → Authentication → Users, create the three test accounts:

1. **User Account**
   - Email: `user@cctv.app`
   - Password: `user@123`

2. **Admin Account**
   - Email: `admin@cctv.app`
   - Password: `admin@123`

3. **Super Admin Account**
   - Email: `superadmin@cctv.app`
   - Password: `superadmin@123`

### Step 4: Create Firestore Users Collection

In Firebase Console → Firestore Database, create a `users` collection with documents for each user:

**Document ID**: Use the Firebase Auth UID for each user

**Document Structure**:
```json
{
  "firstName": "User",
  "lastName": "Test",
  "email": "user@cctv.app",
  "role": "user",
  "createdAt": "2026-01-01T00:00:00Z"
}
```

For Admin:
```json
{
  "firstName": "Admin",
  "lastName": "Test",
  "email": "admin@cctv.app",
  "role": "admin",
  "createdAt": "2026-01-01T00:00:00Z"
}
```

For Super Admin:
```json
{
  "firstName": "Super",
  "lastName": "Admin",
  "email": "superadmin@cctv.app",
  "role": "super admin",
  "createdAt": "2026-01-01T00:00:00Z"
}
```

### Step 5: Enable Firebase Services

In Firebase Console, enable:
1. **Authentication** → Sign-in method → Email/Password → Enable
2. **Firestore Database** → Create database → Start in test mode
3. **Cloud Storage** → Get started → Start in test mode

### Step 6: Run the App

```bash
flutter pub get
flutter run
```

## Security Rules

### Firestore Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

## Testing the Implementation

1. Launch the app
2. Select "As a User" or "As a Admin" tab
3. Enter the corresponding credentials
4. You should be redirected to the appropriate dashboard based on your role

## Troubleshooting

### Common Issues

**Issue**: "Firebase not initialized" error
- **Solution**: Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is properly placed

**Issue**: "User not found" error
- **Solution**: Verify the user exists in Firebase Authentication console

**Issue**: "Permission denied" error
- **Solution**: Check Firestore security rules and ensure the user document exists

**Issue**: Wrong dashboard after login
- **Solution**: Verify the `role` field in the Firestore user document matches the expected value

### Phase 3: Database Migration

#### Option A: Use Firestore (Recommended for CCTV App)

1. **Update pubspec.yaml**
```yaml
dependencies:
  cloud_firestore: ^latest
```

2. **Implement Firestore collections**
```
cctv_app/
  users/
    {userId}/
      - profile
      - role
      - metadata
  cases/
    {caseId}/
      - details
      - defendants
      - posts
      - poll
  posts/
    {postId}/
      - content
      - comments
      - reactions
  alerts/
    {alertId}/
      - details
      - metadata
  advertisements/
    {adId}/
      - details
      - analytics
  notifications/
    {userId}/
      - {notificationId}
```

3. **Implement FirebaseFirestoreService**
```dart
Future<List<Map<String, dynamic>>> getPendingCases(int userId) async {
  final snapshot = await _firestore
      .collection('cases')
      .where('user_id', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .get();
  
  return snapshot.docs.map((doc) => doc.data()).toList();
}
```

#### Option B: Use Realtime Database (If real-time features critical)

1. **Update pubspec.yaml**
```yaml
dependencies:
  firebase_database: ^latest
```

2. **Implement real-time listeners**
```dart
void listenToCases(Function(List<Map<String, dynamic>>) onDataChanged) {
  _realtimeDb
      .ref('cases')
      .onValue
      .listen((event) {
    final cases = (event.snapshot.value as Map).entries
        .map((e) => Map<String, dynamic>.from(e.value))
        .toList();
    onDataChanged(cases);
  });
}
```

### Phase 4: File Storage Migration

1. **Update pubspec.yaml**
```yaml
dependencies:
  firebase_storage: ^latest
```

2. **Implement FirebaseStorageService**
```dart
Future<String?> uploadImage(String filePath, {String? fileName}) async {
  try {
    final file = File(filePath);
    final ref = _storage.ref('images/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  } catch (e) {
    print('Upload error: $e');
    return null;
  }
}
```

### Phase 5: Push Notifications Migration

1. **Update pubspec.yaml**
```yaml
dependencies:
  firebase_messaging: ^latest
```

2. **Implement FirebaseMessagingService**
```dart
Future<void> initialize() async {
  await FirebaseMessaging.instance.requestPermission();
  
  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Handle incoming messages
  });
  
  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}
```

### Phase 6: Analytics Migration

1. **Update pubspec.yaml**
```yaml
dependencies:
  firebase_analytics: ^latest
```

2. **Implement FirebaseAnalyticsService**
```dart
Future<void> logScreenView(String screenName) async {
  await FirebaseAnalytics.instance.logScreenView(
    screenName: screenName,
  );
}
```

### Phase 7: Remote Configuration

1. **Update pubspec.yaml**
```yaml
dependencies:
  firebase_remote_config: ^latest
```

2. **Set up feature flags in Firebase Console**
- Example: `enable_new_ui`, `maintenance_mode`, `max_file_size`

3. **Implement dynamic configuration**
```dart
Future<void> initialize() async {
  await FirebaseRemoteConfig.instance.fetchAndActivate();
}

bool isNewUiEnabled() {
  return FirebaseRemoteConfig.instance.getBool('enable_new_ui');
}
```

## API Endpoints to Firestore Mapping

| Backend Endpoint | Firestore Collection | Notes |
|---|---|---|
| /user/createUserBySignUp | users collection | Use Firebase Auth + Firestore |
| /user/userLogin | Firebase Auth | Use Email/Password auth |
| /user_case/createUserCase | cases collection | Firestore document write |
| /case_post/get_all_active_posts | posts collection | Firestore query + real-time listener |
| /application_cloud/upload_image | Cloud Storage | firebase_storage upload |
| /admin_control/createApplicationAlert | alerts collection | Firestore document write |
| /application_ads/getAds | advertisements collection | Firestore query |
| /application_notification/getNotifications | notifications collection | Cloud Messaging + Firestore |

## Data Model Examples

### Users Collection
```json
{
  "userId": "firebase_uid",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "roleId": 1,
  "roleDescription": "user",
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-01-01T00:00:00Z"
}
```

### Cases Collection
```json
{
  "caseId": "uuid",
  "userId": "firebase_uid",
  "caseTitle": "CCTV Case",
  "caseDescription": "Description",
  "caseStatus": "pending",
  "defendants": ["uid1", "uid2"],
  "createdAt": "2026-01-01T00:00:00Z"
}
```

### Posts Collection
```json
{
  "postId": "uuid",
  "caseId": "case_uuid",
  "createdBy": "firebase_uid",
  "postDescription": "Post content",
  "reactions": {"like": 5, "dislike": 1},
  "comments": [...],
  "createdAt": "2026-01-01T00:00:00Z"
}
```

## Security Rules Examples

### Firestore Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Cases - users can read cases they own or are defendants in
    match /cases/{caseId} {
      allow read: if request.auth.uid == resource.data.userId || 
                     request.auth.uid in resource.data.defendants;
      allow create, write: if request.auth.uid == resource.data.userId;
    }
    
    // Posts - everyone can read, only creator can write
    match /posts/{postId} {
      allow read: if true;
      allow create, write: if request.auth.uid == request.resource.data.createdBy;
    }
  }
}
```

### Storage Rules
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can upload to their own folder
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

## Testing Migration

1. **Create Firebase Emulator Setup**
   - Use Firebase Emulator Suite for local testing
   - Don't test against production Firebase

2. **Update ApiConfig for Testing**
```dart
class ApiConfig {
  static const bool USE_FIREBASE = true;
  static const bool USE_EMULATOR = true;  // Local testing
  static const String EMULATOR_HOST = 'localhost';
}
```

3. **Run Integration Tests**
   - Test authentication flows
   - Test CRUD operations
   - Test real-time updates

## Rollout Strategy

1. **Alpha**: Internal testing with Firebase
2. **Beta**: Limited Firebase rollout to test users
3. **Gradual**: Roll out to percentage of users (Firebase Remote Config)
4. **Full**: Complete migration when stable

## Fallback Plan

1. **Keep mock mode available** for offline functionality
2. **Local cache** as fallback if Firebase unavailable
3. **Error handling** to gracefully degrade

## Checklist for Production

- [ ] Firebase project created and configured
- [ ] All collections and documents structured
- [ ] Security rules tested and deployed
- [ ] Authentication fully implemented
- [ ] File uploads working
- [ ] Push notifications configured
- [ ] Analytics tracking working
- [ ] Remote config deployed
- [ ] Error handling comprehensive
- [ ] Offline mode tested
- [ ] Performance tested at scale
- [ ] Security audit completed
- [ ] Privacy compliance verified

## Support and Troubleshooting

### Common Issues

**Issue**: Authentication token expired
- **Solution**: Implement token refresh in ApiClient

**Issue**: Firestore quota exceeded
- **Solution**: Implement query optimization and caching

**Issue**: Storage upload fails
- **Solution**: Check file size limits and permissions

**Issue**: Real-time listeners not updating
- **Solution**: Verify Firestore security rules and permissions

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase Plugins](https://firebase.flutter.dev)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Cloud Messaging for Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/client)
