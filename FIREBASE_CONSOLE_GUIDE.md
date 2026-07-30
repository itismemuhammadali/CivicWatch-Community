# Firebase Console Setup Guide

## Step 1: Get Firebase Config Files

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project `commctv-f2b45`
3. Click **gear icon** (top-left) → **Project settings**
4. Scroll down to **"Your apps"** section

### Android App:
1. Click **Android icon** ( </> )
2. Enter package name: `com.example.cctv_app`
3. Click **Register app**
4. Download **`google-services.json`**
5. Place it in `CctvMobileApplication/android/app/`

### iOS App:
1. Click **iOS icon** ( </> )
2. Enter bundle ID: `com.example.cctvApp`
3. Click **Register app**
4. Download **`GoogleService-Info.plist`**
5. Place it in `CctvMobileApplication/ios/Runner/`

---

## Step 2: Copy Config Values

In **Project Settings → General**, copy these values and update `firebase_options.dart`:

| Field | Where to find |
|-------|---------------|
| `apiKey` | Web API Key (top of General tab) |
| `appId` | Your apps → Android/iOS App ID |
| `messagingSenderId` | Project number (top of General tab) |
| `projectId` | Project ID (already known) |
| `storageBucket` | Default bucket name |

---

## Step 3: Enable Authentication

1. Left sidebar → **Build** → **Authentication**
2. Click **Get started**
3. Click **Email/Password** provider
4. Toggle **Enable** → Click **Save**

---

## Step 4: Create Firestore Database

1. Left sidebar → **Build** → **Firestore Database**
2. Click **Create database**
3. Select **Start in test mode** → Click **Next**
4. Choose location (closest to you) → Click **Enable**

---

## Step 5: Create Test Users in Authentication

1. Left sidebar → **Build** → **Authentication** → **Users** tab
2. Click **Add user** button

Create these 3 users:

| Email | Password |
|-------|----------|
| `user@cctv.app` | `user@123` |
| `admin@cctv.app` | `admin@123` |
| `superadmin@cctv.app` | `superadmin@123` |

**Important**: Copy each user's **User UID** after creation (you'll need it for Step 6)

---

## Step 6: Create User Documents in Firestore

1. Left sidebar → **Build** → **Firestore Database**
2. Click **+ Start collection**
3. Enter Collection ID: `users` → Click **Next**

### For each user, click **Add document**:

**Document 1** (for user@cctv.app):
- Document ID: *(paste the UID you copied)*
- Fields:
  - `firstName` → `string` → `User`
  - `lastName` → `string` → `Test`
  - `email` → `string` → `user@cctv.app`
  - `role` → `string` → `user`
  - `createdAt` → `timestamp` → *(click timestamp icon)*

**Document 2** (for admin@cctv.app):
- Document ID: *(paste the UID)*
- Fields:
  - `firstName` → `string` → `Admin`
  - `lastName` → `string` → `Test`
  - `email` → `string` → `admin@cctv.app`
  - `role` → `string` → `admin`
  - `createdAt` → `timestamp` → *(click timestamp icon)*

**Document 3** (for superadmin@cctv.app):
- Document ID: *(paste the UID)*
- Fields:
  - `firstName` → `string` → `Super`
  - `lastName` → `string` → `Admin`
  - `email` → `string` → `superadmin@cctv.app`
  - `role` → `string` → `super admin`
  - `createdAt` → `timestamp` → *(click timestamp icon)*

---

## Step 7: Set Firestore Security Rules

1. Firestore Database → **Rules** tab
2. Replace with:

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

3. Click **Publish**

---

## Step 8: Update Code & Run

After completing above, update `firebase_options.dart` with your actual values, then:

```bash
flutter pub get
flutter run
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Firebase not initialized" | Ensure config files are in correct folders |
| "User not found" | Check user exists in Firebase Authentication |
| "Permission denied" | Check Firestore rules and user documents |
| Wrong dashboard | Verify `role` field matches: `user`, `admin`, or `super admin` |
