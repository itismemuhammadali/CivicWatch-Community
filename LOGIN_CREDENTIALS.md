# Mock Login Credentials Guide

## 🔐 Login Credentials for Testing

The app now supports **three distinct login types** with **specific required passwords**. Use these exact credentials to test different dashboards and features.

---

## 👤 USER (Regular User Dashboard)

**Email**: `user@cctv.app`
**Password**: `user@123` ⭐ **REQUIRED**

### Access
- ✅ User Dashboard
- ✅ Home Feed
- ✅ Cases (Create, View, Delete)
- ✅ Posts (Create, Comment, React)
- ✅ Profile
- ✅ Saved Posts
- ✅ Pending Cases
- ✅ Notifications

### Role Details
- **Role ID**: 1
- **Role Description**: "user"
- **Dashboard Type**: USER
- **Access Level**: Regular user features

---

## 👨‍💼 ADMIN (Admin Dashboard)

**Email**: `admin@cctv.app`
**Password**: `admin@123` ⭐ **REQUIRED**

### Access
- ✅ Admin Dashboard
- ✅ Alerts Management
- ✅ User Management
- ✅ Dashboard Statistics
- ✅ Create/View Application Alerts
- ✅ Send User Warnings
- ✅ View All Users

### Role Details
- **Role ID**: 2
- **Role Description**: "admin"
- **Dashboard Type**: ADMIN
- **Access Level**: Administrative features

---

## 👑 SUPER ADMIN (Super Admin Dashboard)

**Email**: `superadmin@cctv.app`
**Password**: `superadmin@123` ⭐ **REQUIRED**

### Access
- ✅ Super Admin Dashboard
- ✅ Full System Access
- ✅ User & Admin Management
- ✅ System Configuration
- ✅ All Admin Features Plus:
  - Advanced Analytics
  - System Monitoring
  - Admin User Management
  - Ad Campaign Oversight

### Role Details
- **Role ID**: 3
- **Role Description**: "super admin"
- **Dashboard Type**: ADMIN (shares admin features + additional)
- **Access Level**: Super administrative features

---

## 🧪 Testing Each Role

### Test User Credentials
```
Login Type: USER
Email: user@cctv.app
Password: user@123
Expected: User dashboard opens
```

### Test Admin Credentials
```
Login Type: ADMIN
Email: admin@cctv.app
Password: admin@123
Expected: Admin dashboard opens
```

### Test Super Admin Credentials
```
Login Type: SUPER ADMIN
Email: superadmin@cctv.app
Password: superadmin@123
Expected: Super admin dashboard opens
```

---

## 📝 Login Flow

### Step 1: Open App
- App shows authentication screen with two tabs: **User** and **Admin**

### Step 2: Select Role Tab
- **User Tab**: Shows user login
- **Admin Tab**: Shows admin/superadmin login (shared admin interface)

### Step 3: Enter Email
Choose based on what dashboard you want to test:
- User dashboard: Use `user@cctv.app`
- Admin dashboard: Use `admin@cctv.app`
- Super admin dashboard: Use `superadmin@cctv.app`

### Step 4: Enter Password
Use the exact password for the role:
- User: `user@123`
- Admin: `admin@123`
- Super Admin: `superadmin@123`

### Step 5: Tap Login
- Role is detected from email
- Password is validated
- Appropriate dashboard loads
- Session saved

---

## ✨ Password Policy (Mock Mode)

**For Testing Only:**
- Passwords are **case-sensitive**
- Passwords must **match exactly**
- Format: `role@123`

| Role | Password | Required |
|------|----------|----------|
| User | `user@123` | ✅ Yes |
| Admin | `admin@123` | ✅ Yes |
| Super Admin | `superadmin@123` | ✅ Yes |

---

## 🚨 Password Validation

If you enter wrong credentials:

| Error | Reason |
|-------|--------|
| "Invalid credentials for User account" | Wrong password for user email |
| "Invalid credentials for Admin account" | Wrong password for admin email |
| "Invalid credentials for SuperAdmin account" | Wrong password for superadmin email |
| "Email is required" | Empty email field |
| "Password is required" | Empty password field |
| "Invalid email format" | Email doesn't contain "@" |

---

## 🎯 Quick Testing Guide

### Test All Three Roles (15 minutes)

1. **Test User Role** (5 min)
   - Email: `user@cctv.app`
   - Password: `user@123`
   - Verify User Dashboard loads
   - Logout

2. **Test Admin Role** (5 min)
   - Switch to Admin tab
   - Email: `admin@cctv.app`
   - Password: `admin@123`
   - Verify Admin Dashboard loads
   - Logout

3. **Test Super Admin Role** (5 min)
   - Switch to Admin tab
   - Email: `superadmin@cctv.app`
   - Password: `superadmin@123`
   - Verify Super Admin Dashboard loads
   - Logout

---

## 🔄 Email Detection Logic

The login system detects role based on **email string matching**:

```dart
const userPassword = 'user@123';
const adminPassword = 'admin@123';
const superAdminPassword = 'superadmin@123';

if (email.contains('superadmin')) {
  // Validate with superAdminPassword
  // roleId = 3
} 
else if (email.contains('admin')) {
  // Validate with adminPassword
  // roleId = 2
} 
else {
  // Validate with userPassword
  // roleId = 1
}
```

---

## ⚠️ Important Notes

### Password Validation
- **Enabled**: All passwords are now validated
- **Case Sensitive**: `user@123` is different from `User@123`
- **Exact Match**: Password must match exactly as specified
- **Required**: All three roles require their specific passwords

### Common Mistakes
- Using wrong password (e.g., `admin@123` for user account)
- Case mismatch (e.g., `User@123` instead of `user@123`)
- Missing special character (e.g., `user123` instead of `user@123`)
- Extra spaces in email or password

### Session Management
- Login credentials are saved securely
- Closing and reopening app maintains session
- User remains logged in until logout
- Logout clears session and credentials

---

## 🧑‍💻 Developer Reference

### Validation Logic

```dart
static String? _validateMockCredentials(String email, String password) {
  const userPassword = 'user@123';
  const adminPassword = 'admin@123';
  const superAdminPassword = 'superadmin@123';

  if (email.contains('superadmin')) {
    if (password != superAdminPassword) {
      return 'Invalid credentials for SuperAdmin account';
    }
  } else if (email.contains('admin')) {
    if (password != adminPassword) {
      return 'Invalid credentials for Admin account';
    }
  } else {
    if (password != userPassword) {
      return 'Invalid credentials for User account';
    }
  }
  
  return null; // Valid
}
```

---

## 🔮 Future: Firebase Authentication

When migrating to Firebase:

```dart
// Phase 2: Firebase Auth Implementation
// Passwords will be validated against Firebase Auth
// Real password requirements will apply
// See: FIREBASE_MIGRATION_GUIDE.md
```

---

## Summary

| Role | Email | Password | Tab | Status |
|------|-------|----------|-----|--------|
| User | `user@cctv.app` | `user@123` | USER | ✅ Ready |
| Admin | `admin@cctv.app` | `admin@123` | ADMIN | ✅ Ready |
| Super Admin | `superadmin@cctv.app` | `superadmin@123` | ADMIN | ✅ Ready |

**Use these exact credentials to test your app!**

---

**Version**: 1.0.0 (Updated with Password Validation)
**Date**: January 7, 2026
**Status**: ✅ Ready for Testing

### Access
- ✅ User Dashboard
- ✅ Home Feed
- ✅ Cases (Create, View, Delete)
- ✅ Posts (Create, Comment, React)
- ✅ Profile
- ✅ Saved Posts
- ✅ Pending Cases
- ✅ Notifications

### Role Details
- **Role ID**: 1
- **Role Description**: "user"
- **Dashboard Type**: USER
- **Access Level**: Regular user features

### Navigation
After login → **User Dashboard** with bottom navigation:
- Home
- Pending Cases
- My Posts
- Profile

---

## 👨‍💼 ADMIN (Admin Dashboard)

**Email**: `admin@cctv.app` (or any email containing "admin" but NOT "superadmin")
**Password**: Any password (mock ignores password)

### Access
- ✅ Admin Dashboard
- ✅ Alerts Management
- ✅ User Management
- ✅ Dashboard Statistics
- ✅ Create/View Application Alerts
- ✅ Send User Warnings
- ✅ View All Users

### Role Details
- **Role ID**: 2
- **Role Description**: "admin"
- **Dashboard Type**: ADMIN
- **Access Level**: Administrative features

### Navigation
After login → **Admin Dashboard** with bottom navigation:
- Alerts
- Statistics
- Users
- Admin Profile

---

## 👑 SUPER ADMIN (Super Admin Dashboard)

**Email**: `superadmin@cctv.app` (email containing "superadmin")
**Password**: Any password (mock ignores password)

### Access
- ✅ Super Admin Dashboard
- ✅ Full System Access
- ✅ User & Admin Management
- ✅ System Configuration
- ✅ All Admin Features Plus:
  - Advanced Analytics
  - System Monitoring
  - Admin User Management
  - Ad Campaign Oversight

### Role Details
- **Role ID**: 3
- **Role Description**: "super admin"
- **Dashboard Type**: ADMIN (shares admin features + additional)
- **Access Level**: Super administrative features

### Navigation
After login → **Super Admin Dashboard** with extended features

---

## 🧪 Testing Each Role

### Test User Credentials
```
Login Type: USER
Email: user@cctv.app
Password: password123 (any password)
Expected: User dashboard opens
```

### Test Admin Credentials
```
Login Type: ADMIN
Email: admin@cctv.app
Password: password123 (any password)
Expected: Admin dashboard opens
```

### Test Super Admin Credentials
```
Login Type: SUPER ADMIN
Email: superadmin@cctv.app
Password: password123 (any password)
Expected: Super admin dashboard opens
```

---

## 📝 Login Flow

### Step 1: Open App
- App shows authentication screen with two tabs: **User** and **Admin**

### Step 2: Select Role Tab
- **User Tab**: Shows user login
- **Admin Tab**: Shows admin/superadmin login (shared admin interface)

### Step 3: Enter Email
Choose based on what dashboard you want to test:
- User dashboard: Use `user@cctv.app` (or any email without "admin")
- Admin dashboard: Use `admin@cctv.app` (or any email with "admin")
- Super admin dashboard: Use `superadmin@cctv.app`

### Step 4: Enter Password
- Any password works (mock ignores it)
- Recommended: `password` or `123456`

### Step 5: Tap Login
- Role is detected from email
- Appropriate dashboard loads
- Session saved

---

## 🎯 Quick Testing Guide

### Test All Three Roles (15 minutes)

1. **Test User Role** (5 min)
   - Login with `user@cctv.app`
   - Verify User Dashboard loads
   - View home feed
   - Check case list
   - Logout

2. **Test Admin Role** (5 min)
   - Switch to Admin tab
   - Login with `admin@cctv.app`
   - Verify Admin Dashboard loads
   - View alerts
   - Check statistics
   - Logout

3. **Test Super Admin Role** (5 min)
   - Switch to Admin tab
   - Login with `superadmin@cctv.app`
   - Verify Super Admin Dashboard loads
   - Access admin features
   - Check extended options
   - Logout

---

## 🔄 Email Detection Logic

The login system detects role based on **email string matching**:

```dart
final email = username.toLowerCase();

if (email.contains('superadmin')) {
  // Load SuperAdmin interface
  // roleId = 3
  // roleDescription = 'super admin'
} 
else if (email.contains('admin')) {
  // Load Admin interface
  // roleId = 2
  // roleDescription = 'admin'
} 
else {
  // Load User interface
  // roleId = 1
  // roleDescription = 'user'
}
```

---

## ✨ Custom Email Testing

You can also test with **any custom email** by following the pattern:

| Pattern | Role | Example |
|---------|------|---------|
| Contains "superadmin" | Super Admin | `john.superadmin@example.com` |
| Contains "admin" (no "superadmin") | Admin | `jane.admin@company.com` |
| Anything else | User | `bob@company.com`, `test@gmail.com` |

---

## 🔐 Password Requirements

**For Mock Mode:**
- Password validation is **disabled** in mock mode
- Any password is accepted
- Use any string: `password`, `123456`, `test`, etc.

**Note**: When migrating to Firebase, proper password validation will be required.

---

## 💾 Session Management

### Session Persistence
- Login credentials are saved securely
- Closing and reopening app maintains session
- User remains logged in until logout

### Logout
- Tap logout in profile/settings
- Session cleared
- Redirected to login screen

### Session Expiry (Mock Mode)
- No automatic expiry in mock mode
- Session persists until manual logout
- All data cached locally

---

## 🧑‍💻 Developer Reference

### Mock Data Generation

```dart
// Generate user
MockDataGenerator.generateMockUser(
  email: 'user@cctv.app',
  roleId: 1,
  roleDescription: 'user',
)

// Generate admin
MockDataGenerator.generateMockAdminUser()
// email: 'admin@cctv.app'
// roleId: 2
// roleDescription: 'admin'

// Generate super admin
MockDataGenerator.generateMockSuperAdminUser()
// email: 'superadmin@cctv.app'
// roleId: 3
// roleDescription: 'super admin'
```

### Role to Dashboard Mapping

```dart
DashboardType _dashboardTypeFromRole({
  String? roleDescription,
  int? roleId
}) {
  final normalizedRole = roleDescription?.trim().toLowerCase();
  
  if (normalizedRole == 'super admin') return DashboardType.admin;
  if (normalizedRole == 'admin') return DashboardType.admin;
  if (normalizedRole == 'ad') return DashboardType.ad;
  if (normalizedRole == 'user') return DashboardType.user;

  return switch (roleId) {
    2 => DashboardType.admin,      // Admin
    3 => DashboardType.admin,      // Super Admin
    1 => DashboardType.user,       // User
    _ => DashboardType.user,       // Default
  };
}
```

---

## 🚨 Troubleshooting

### Wrong Dashboard Opened
- **Problem**: Logged in with `admin@cctv.app` but user dashboard opened
- **Solution**: Make sure you're on the **Admin tab** before logging in
- The login type must match the tab selected

### Can't Access Admin Features
- **Problem**: Features greyed out or not available
- **Solution**: 
  - Make sure email is `admin@cctv.app` or contains "admin"
  - Check role is showing as "admin" (not "user")
  - Logout and login again

### Session Lost
- **Problem**: Got logged out unexpectedly
- **Solution**: 
  - In mock mode, session should persist
  - Check if you manually logged out
  - Clear cache and login again

### Password Not Working
- **Problem**: Login fails with password error
- **Solution**: 
  - In mock mode, any password works
  - Check email spelling
  - Try refreshing the app

---

## 📊 Testing Checklist

- [ ] User login with `user@cctv.app` works
- [ ] User dashboard displays correctly
- [ ] Admin login with `admin@cctv.app` works
- [ ] Admin dashboard displays correctly
- [ ] Super admin login with `superadmin@cctv.app` works
- [ ] Super admin dashboard displays correctly
- [ ] Can switch between tabs and login types
- [ ] Session persists after app restart
- [ ] Logout clears session
- [ ] Different roles see different features

---

## 🔮 Future: Firebase Authentication

When migrating to Firebase:

```dart
// Phase 2: Firebase Auth Implementation
// See: FIREBASE_MIGRATION_GUIDE.md

// Will replace mock login with:
Future<bool> signIn({
  required String email,
  required String password,
}) async {
  // Firebase Auth implementation
  // Role fetched from Firestore
  // No email pattern detection needed
}
```

---

## Summary

| Role | Email | Password | Dashboard |
|------|-------|----------|-----------|
| User | `user@cctv.app` | Any | User Dashboard |
| Admin | `admin@cctv.app` | Any | Admin Dashboard |
| Super Admin | `superadmin@cctv.app` | Any | Super Admin Dashboard |

**Start testing now with these credentials!**

---

**Version**: 1.0.0
**Date**: January 7, 2026
**Status**: ✅ Ready for Testing
