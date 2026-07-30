# Complete Role Testing Guide

## 🎯 Test All Three Roles in Your App

This guide walks you through testing the **User**, **Admin**, and **Super Admin** interfaces.

---

## 📱 Quick Navigation

- [User Role Testing](#user-role-testing)
- [Admin Role Testing](#admin-role-testing)
- [Super Admin Role Testing](#super-admin-role-testing)
- [Cross-Role Testing](#cross-role-testing)
- [Common Issues](#common-issues)

---

## 👤 USER ROLE TESTING

### Login Credentials
```
Email: user@cctv.app
Password: password (any password works)
Tab: USER (left tab on auth screen)
```

### Expected Behavior After Login

✅ **User Dashboard Opens**
- Bottom navigation with 4 tabs visible:
  1. Home
  2. Pending Cases
  3. My Posts
  4. Profile

### Feature Testing Checklist

#### Home Tab
- [ ] Post feed displays with mock posts
- [ ] Each post shows: Author, description, reactions, comments
- [ ] Pull to refresh works
- [ ] Load more functionality works

#### Pending Cases Tab
- [ ] Pending cases list displays
- [ ] Each case shows: Title, description, status
- [ ] Tap on case shows details
- [ ] Defendant info visible
- [ ] Poll voting available

#### My Posts Tab
- [ ] User's posts displayed
- [ ] Can view own posts
- [ ] Can create new post
- [ ] Can edit/delete own posts

#### Profile Tab
- [ ] User profile displayed with:
  - [ ] Name (from login data)
  - [ ] Email
  - [ ] Profile picture (placeholder)
  - [ ] Role: "user"
  - [ ] Settings option
- [ ] Can view account info
- [ ] Can access settings

### User-Specific Features
- [ ] Create Case
  - Enter title, description
  - Add defendants
  - Upload image/video
  - Confirm creation
- [ ] Add Comment to Post
  - Type comment
  - Submit comment
- [ ] React to Post
  - Tap heart/like/etc
  - Reaction count updates
- [ ] Save Post
  - Bookmark icon changes
  - Post appears in saved
- [ ] View Notifications
  - Mock notifications display
  - Can mark as read

### Logout
- [ ] Tap profile → logout
- [ ] Redirected to login screen
- [ ] Session cleared

---

## 👨‍💼 ADMIN ROLE TESTING

### Login Credentials
```
Email: admin@cctv.app
Password: password (any password works)
Tab: ADMIN (right tab on auth screen)
```

### Expected Behavior After Login

✅ **Admin Dashboard Opens**
- Bottom navigation with different tabs than user:
  1. Alerts
  2. Statistics
  3. Users
  4. Admin Profile

### Feature Testing Checklist

#### Alerts Tab
- [ ] Create Application Alert
  - Enter alert title/message
  - Select alert type
  - Confirm creation
- [ ] View All Alerts
  - List of alerts displays
  - Each shows: message, timestamp, status
- [ ] Delete Alert
  - Tap delete on alert
  - Confirm deletion
- [ ] Alert Details
  - View full alert message
  - See creation time
  - See creator info

#### Statistics Tab
- [ ] Dashboard Statistics Display
  - Total cases: 15
  - Pending cases: 5
  - Approved cases: 8
  - Total posts: 45
  - Total users: 23
  - Total alerts: 7
- [ ] Charts/Graphs Display (if available)
  - Daily statistics
  - Weekly trends
  - Monthly summary

#### Users Tab
- [ ] User List Displays
  - All users shown
  - Role badges visible
  - Status indicator shown
- [ ] User Actions
  - View user profile
  - Send warning to user
  - Block/unblock user (if available)
- [ ] User Details
  - User info visible
  - Role description: "admin" or "super admin"
  - Joined date shown

#### Admin Profile Tab
- [ ] Admin Info Displayed
  - Name: "Admin User" (from mock data)
  - Email: "admin@cctv.app"
  - Role: "admin"
  - Admin-specific settings
- [ ] Settings
  - Admin-specific options
  - Alert settings
  - User management settings

### Admin-Specific Features
- [ ] Create System Alert
  - Send to all users
  - Send to admins only
  - Confirmation message
- [ ] Send User Warning
  - Select user
  - Enter warning message
  - Confirm send
- [ ] View Analytics
  - Case creation trends
  - User activity metrics
  - Post engagement stats
- [ ] System Configuration
  - Manage parameters
  - Set global settings

### Admin Access Control
- [ ] Cannot access user personal dashboard
- [ ] Can access admin features only
- [ ] Settings show admin options
- [ ] Cannot create personal cases (or limited access)

### Logout
- [ ] Tap profile → logout
- [ ] Redirected to login screen
- [ ] Session cleared

---

## 👑 SUPER ADMIN ROLE TESTING

### Login Credentials
```
Email: superadmin@cctv.app
Password: password (any password works)
Tab: ADMIN (right tab on auth screen)
```

### Expected Behavior After Login

✅ **Super Admin Dashboard Opens**
- Similar to admin but with **extended features**
- Bottom navigation with tabs similar to admin + additional options

### Feature Testing Checklist

#### All Admin Features (Should Work)
- [ ] Create alerts (same as admin)
- [ ] View statistics (same as admin)
- [ ] Manage users (same as admin)
- [ ] Access profile (same as admin)

#### Super Admin-Only Features
- [ ] Advanced User Management
  - Assign roles to users
  - Promote users to admin
  - Demote admin to user
  - Full user lifecycle management
- [ ] System Configuration
  - Configure system parameters
  - Set global settings
  - Manage feature flags (if available)
- [ ] Ad Campaign Oversight
  - View all advertisements
  - Manage ad campaigns
  - Override ad decisions
- [ ] Admin Management
  - View all admins
  - Manage admin accounts
  - Assign admin permissions
- [ ] System Monitoring
  - View system health
  - Check performance metrics
  - View error logs (if available)

#### Super Admin Permissions
- [ ] Can manage other admins
- [ ] Can modify system settings
- [ ] Can view audit logs
- [ ] Can override case decisions
- [ ] Can manage advertisements
- [ ] Can configure feature flags

### Super Admin Access Control
- [ ] Cannot access regular user dashboard
- [ ] Has access to all admin features
- [ ] Plus additional super admin features
- [ ] Settings show super admin options

### Logout
- [ ] Tap profile → logout
- [ ] Redirected to login screen
- [ ] Session cleared

---

## 🔄 CROSS-ROLE TESTING

### Test Role Switching

#### Scenario 1: User → Admin
1. Login as `user@cctv.app` on **USER** tab
2. View user dashboard
3. Logout
4. Switch to **ADMIN** tab
5. Login as `admin@cctv.app`
6. Verify admin dashboard shows different features
7. ✅ Different dashboards should appear

#### Scenario 2: Admin → Super Admin
1. Login as `admin@cctv.app` on **ADMIN** tab
2. View admin dashboard
3. Note available features
4. Logout
5. Login as `superadmin@cctv.app`
6. Compare available features
7. ✅ Super admin should have more options

#### Scenario 3: Round Trip
1. Login as **User** → View dashboard
2. Logout → Verify cleared
3. Login as **Admin** → View dashboard
4. Logout → Verify cleared
5. Login as **Super Admin** → View dashboard
6. Logout → Verify cleared
7. ✅ All three should work seamlessly

### Tab Selection Testing

#### User Tab Features
- [ ] Only shows user login fields
- [ ] After user login → user dashboard
- [ ] Cannot access admin features from this tab

#### Admin Tab Features
- [ ] Shows admin/super admin login
- [ ] Both admin and super admin emails work
- [ ] After login → admin/super admin dashboard
- [ ] User cannot login from this tab

### Session Persistence Testing

#### User Session
1. Login as user
2. Close app completely
3. Reopen app
4. ✅ Should still be logged in as user
5. Logout

#### Admin Session
1. Login as admin
2. Close app completely
3. Reopen app
4. ✅ Should still be logged in as admin
5. Logout

#### Super Admin Session
1. Login as super admin
2. Close app completely
3. Reopen app
4. ✅ Should still be logged in as super admin
5. Logout

---

## ✨ Feature Comparison Matrix

| Feature | User | Admin | Super Admin |
|---------|------|-------|-------------|
| View Dashboard | ✅ | ✅ | ✅ |
| View Home Feed | ✅ | ❌ | ❌ |
| Create Cases | ✅ | ❌/Limited | ❌/Limited |
| View Cases | ✅ | ✅ | ✅ |
| Create Alerts | ❌ | ✅ | ✅ |
| Manage Users | ❌ | ✅ | ✅ |
| Manage Admins | ❌ | ❌ | ✅ |
| View Analytics | ❌ | ✅ | ✅ |
| System Config | ❌ | Limited | ✅ |
| Manage Ads | ❌ | Limited | ✅ |

---

## 🧪 Complete Testing Workflow (30 minutes)

### Phase 1: User Testing (10 min)
1. Open app
2. Select **USER** tab
3. Login with `user@cctv.app`
4. Test 5 user features
5. Logout
6. Verify session cleared

### Phase 2: Admin Testing (10 min)
1. Select **ADMIN** tab
2. Login with `admin@cctv.app`
3. Test 5 admin features
4. Logout
5. Verify session cleared

### Phase 3: Super Admin Testing (10 min)
1. Select **ADMIN** tab
2. Login with `superadmin@cctv.app`
3. Test 5 super admin features
4. Compare with admin features
5. Logout
6. Verify session cleared

---

## ✅ Success Criteria

- [ ] User can login and see user dashboard
- [ ] Admin can login and see admin dashboard
- [ ] Super admin can login and see super admin dashboard
- [ ] Each role sees appropriate features
- [ ] Cannot access features of other roles
- [ ] Session persists after app restart
- [ ] Can logout and login as different role
- [ ] All UI displays correctly for each role
- [ ] No crashes or errors
- [ ] Mock data generates for all roles

---

## 🐛 Common Issues & Solutions

### Issue: Both Admin and User Login on Same Tab
**Solution**: Make sure to select the correct tab:
- User tab for user login
- Admin tab for admin/super admin login

### Issue: Super Admin Dashboard Looks Same as Admin
**Solution**: This is expected in mock mode. Extended features may be in admin area.

### Issue: Can't Find Super Admin Features
**Solution**: 
- Make sure logged in as `superadmin@cctv.app`
- Check role description shows "super admin"
- Some features might be in admin area

### Issue: Session Lost After Logout
**Solution**: 
- Normal behavior - session should clear
- Login again to create new session
- Check settings → cache management

### Issue: Wrong Dashboard After Login
**Solution**:
- Make sure on correct tab (USER vs ADMIN)
- Email must match role:
  - `user@cctv.app` for user dashboard
  - `admin@cctv.app` for admin dashboard
  - `superadmin@cctv.app` for super admin dashboard

---

## 📊 Test Results Template

Use this to document your testing:

```
Date: ____________
Tester: __________

USER ROLE:
  Email: user@cctv.app
  - Dashboard loaded: ✅ / ❌
  - Features visible: ✅ / ❌
  - Session persisted: ✅ / ❌
  - Logout worked: ✅ / ❌
  
ADMIN ROLE:
  Email: admin@cctv.app
  - Dashboard loaded: ✅ / ❌
  - Features visible: ✅ / ❌
  - Session persisted: ✅ / ❌
  - Logout worked: ✅ / ❌
  
SUPER ADMIN ROLE:
  Email: superadmin@cctv.app
  - Dashboard loaded: ✅ / ❌
  - Features visible: ✅ / ❌
  - Session persisted: ✅ / ❌
  - Logout worked: ✅ / ❌

CROSS-ROLE:
  - Role switching works: ✅ / ❌
  - Tab selection works: ✅ / ❌
  - No feature access issues: ✅ / ❌

Issues Found:
- [List any issues]

Overall Status: ✅ PASS / ❌ FAIL
```

---

## 🎉 Summary

You now have **three fully functional test accounts**:

1. **User** (`user@cctv.app`) → User Dashboard
2. **Admin** (`admin@cctv.app`) → Admin Dashboard  
3. **Super Admin** (`superadmin@cctv.app`) → Super Admin Dashboard

**Start testing all three roles with the credentials provided!**

---

**Version**: 1.0.0
**Date**: January 7, 2026
**Status**: ✅ Ready for Testing
