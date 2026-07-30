# Mock Mode Testing Guide

## Overview

This guide ensures all UI features work correctly with mock data and no backend connection. The app is now in **offline-first mode** with complete mock data generation.

## Current Status

✅ **Mock Mode Enabled**: All API calls return generated mock data
✅ **Local Caching**: Data persists locally for offline access
✅ **Firebase Ready**: Service stubs prepared for future Firebase migration
✅ **UI Fully Functional**: No backend required

## Quick Start

### 1. Verify Configuration

Check that mock mode is enabled:
```dart
// lib/core/network/api_config.dart
static const bool MOCK_MODE = true;  // ✅ Should be true
static const bool USE_FIREBASE = false;  // ✅ Should be false
```

### 2. Build and Run

```bash
cd CctvMobileApplication
flutter pub get
flutter run
```

The app will now use mock data for all API calls with simulated 300ms network delays.

## Testing Checklist

### Authentication & Session Management

- [ ] **Sign Up**
  - Navigate to Sign Up page
  - Enter: First Name, Last Name, Email, Password
  - Expected: User created with role_id=1 (User)
  - Data persists in local storage
  - Redirects to home dashboard

- [ ] **Sign In (User)**
  - Login with any email/password combo
  - Expected: User role dashboard displayed
  - Token saved securely
  - User info cached locally

- [ ] **Sign In (Admin)**
  - Login with email containing "admin"
  - Expected: Admin role dashboard (role_id=2)
  - Admin-specific features enabled
  - Admin alerts visible

- [ ] **Session Persistence**
  - Sign in successfully
  - Close app completely
  - Reopen app
  - Expected: Session maintained, no re-login needed

- [ ] **Logout**
  - Click logout
  - Expected: Session cleared, redirected to login
  - Local data cleared
  - Can login again

### User Dashboard (User Role)

#### Home Tab
- [ ] **Pending Cases Display**
  - Expected: 5 mock cases loaded
  - Each case shows: Title, Description, Status badge
  - Media thumbnail displayed if available
  - Click on case to view details

- [ ] **Recent Posts Feed**
  - Expected: 8-10 mock posts loaded
  - Each post shows: Author info, description, reactions, comments count
  - Timestamps displayed correctly
  - Refresh pulls latest posts

- [ ] **Pull to Refresh**
  - Pull down on post feed
  - Expected: New mock data generated
  - Loading indicator shown
  - Feed updates with new posts

#### Pending Cases Tab
- [ ] **Case List**
  - Expected: List of pending cases displayed
  - Case status badges visible
  - Defendant info shown
  - Created date displayed

- [ ] **Case Details**
  - Tap on case
  - Expected: Case detail page opens
  - Full description visible
  - Media/evidence displayed
  - Defendant information shown
  - Poll voting visible

- [ ] **Case Actions**
  - Accept terms button works
  - Vote on poll functionality
  - Add comment works
  - Add reaction works

#### Posts Tab
- [ ] **My Posts**
  - Navigate to user posts tab
  - Expected: User-specific posts loaded (5 posts)
  - Can filter by case
  - Can view all reactions/comments

- [ ] **Saved Posts**
  - View saved posts
  - Expected: Saved posts loaded (3 posts)
  - Save/unsave toggle works
  - Bookmark icon updates

#### Profile Tab
- [ ] **User Profile Display**
  - Profile page shows:
    - [ ] User avatar (placeholder)
    - [ ] Name (First + Last)
    - [ ] Email
    - [ ] Role description
    - [ ] Location info (Country, State)
    - [ ] Date of birth

- [ ] **Edit Profile**
  - Update profile fields
  - Expected: Changes saved to local storage
  - Persists on app restart

- [ ] **Settings**
  - Theme toggle
  - Notification preferences
  - Language selection (if available)
  - Clear cache option

### Admin Dashboard (Admin Role)

#### Alerts Management Tab
- [ ] **Create Alert**
  - Navigate to create alert
  - Enter alert title/message
  - Expected: Alert created, saved locally
  - Confirmation message shown

- [ ] **View All Alerts**
  - Alert list displayed
  - Each alert shows: Message, creation time, status
  - Can filter by status
  - Can delete alert

- [ ] **Send User Warning**
  - Select user from list
  - Enter warning message
  - Expected: Warning created and shown in UI

#### Admin Stats
- [ ] **Dashboard Statistics**
  - Total cases: 15
  - Pending cases: 5
  - Approved cases: 8
  - Total posts: 45
  - Total users: 23

#### User Management
- [ ] **View All Users**
  - User list with roles
  - Role badges displayed
  - User status shown

### Ad Creator Dashboard (Ad Role - if available)

#### Ads Management
- [ ] **View All Ads**
  - Ads displayed in grid/list
  - Status badges (active, pending, archived)
  - View count shown

- [ ] **Create Ad**
  - Navigate to create ad
  - Fill in ad details
  - Upload image works with mock
  - Expected: Ad created, appears in list

- [ ] **Edit Ad**
  - Tap on ad
  - Update details
  - Changes reflected in list

### Common Features

#### File Uploads
- [ ] **Image Upload**
  - Select image from device
  - Expected: Mock URL returned immediately
  - Placeholder image displayed
  - Proceeds without backend delay

- [ ] **Video Upload**
  - Select video file
  - Expected: Mock video URL returned
  - Thumbnail displayed
  - Video player ready

#### Notifications
- [ ] **Notification Center**
  - Open notifications
  - Expected: 5 mock notifications displayed
  - Each shows: Type, message, timestamp
  - Can mark as read

- [ ] **Real-time Updates**
  - Create new case
  - Expected: Notification appears (mock)
  - Badge count updates

#### Search & Filter
- [ ] **Search Cases**
  - Type in search box
  - Expected: Mock cases filtered (client-side)
  - Results update as you type

- [ ] **Filter Posts**
  - Apply filters (by status, author, etc.)
  - Expected: Mock posts filtered
  - Filter badges visible

#### Comments & Reactions
- [ ] **Add Comment**
  - Type comment on post
  - Expected: Comment added immediately (mock)
  - Your info shows as commenter
  - Timestamp displayed

- [ ] **Add Reaction**
  - Tap reaction button (like, heart, etc.)
  - Expected: Reaction added
  - Count increments
  - Your reaction shown

- [ ] **Remove Reaction**
  - Tap same reaction again
  - Expected: Reaction removed
  - Count decrements

#### Polls & Voting
- [ ] **View Poll**
  - Open case with poll
  - Expected: Poll visible with voting options
  - Owner and defendant counts shown

- [ ] **Vote on Poll**
  - Click on vote option
  - Expected: Vote registered
  - Counts update
  - Your vote highlighted

### Data Persistence & Offline Mode

#### Local Caching
- [ ] **Cache Created**
  - App stores mock data locally
  - Check storage: `local_data_cache` keys present
  - Data persists between app restarts

- [ ] **Cache Expiration**
  - Wait 24+ hours (or modify cache duration for testing)
  - Expected: Cache expires and refreshes
  - New mock data generated

- [ ] **Clear Cache**
  - Trigger cache clear
  - Expected: Old data removed
  - Fresh mock data on next load

#### Offline Access
- [ ] **Airplane Mode Test**
  - Enable airplane mode
  - App still functional
  - Displays cached data
  - Shows "offline" indicator

- [ ] **Network Reconnect**
  - Disable airplane mode
  - Expected: App detects connection
  - Refreshes with new mock data

### Performance & UI

#### Loading States
- [ ] **Loading Indicators**
  - Loading spinners appear during API calls
  - 300ms simulated delay visible
  - Loading states clear when done

- [ ] **Error Handling**
  - Simulate error (if possible)
  - Expected: Error message shown
  - Retry button available
  - App doesn't crash

#### Animations & Transitions
- [ ] **Page Transitions**
  - Navigate between tabs
  - Expected: Smooth transitions
  - No lag or jank

- [ ] **List Animations**
  - Scroll through lists
  - Expected: Smooth scrolling
  - No performance issues

#### Responsive Design
- [ ] **Portrait Mode**
  - App displays correctly
  - All elements visible
  - Touch targets appropriate size

- [ ] **Landscape Mode**
  - Rotate device
  - Expected: Layout adapts
  - All content visible
  - No overlapping elements

- [ ] **Different Screen Sizes**
  - Test on small screen (emulator)
  - Test on large screen
  - Test on tablet
  - UI scales appropriately

### Edge Cases & Stress Testing

#### Large Data Sets
- [ ] **Many Posts**
  - Generate 100+ mock posts
  - Expected: App handles smoothly
  - Scrolling still responsive
  - No memory leaks

- [ ] **Many Comments**
  - Post with 50+ comments
  - Expected: Loads and displays correctly
  - Smooth scrolling

#### Empty States
- [ ] **No Cases**
  - Clear cases cache
  - Expected: Empty state message shown
  - UI still functional

- [ ] **No Posts**
  - Clear posts cache
  - Expected: Empty state message shown
  - Refresh button available

#### Rapid Interactions
- [ ] **Rapid Clicks**
  - Click buttons rapidly
  - Expected: No crashes or bugs
  - Actions queue or debounce properly

- [ ] **Rapid Navigation**
  - Switch tabs/pages rapidly
  - Expected: App handles gracefully
  - No state corruption

### Browser DevTools Testing (if web version exists)

- [ ] **Network Tab**
  - All requests use `http://localhost:9999` (non-existent)
  - No actual network calls made
  - Only MOCK_MODE responses returned

- [ ] **Storage Tab**
  - Local storage shows cached data
  - Secure storage items present
  - Cache expiration times valid

- [ ] **Console**
  - No network errors
  - No unhandled exceptions
  - Debug logs show mock responses

## Testing Scenarios

### Scenario 1: New User Journey
1. Open app → See login page
2. Tap "Sign Up"
3. Enter user details
4. Create account → User dashboard
5. View home feed with mock posts
6. View pending cases
7. Interact with post (comment, react)
8. Logout

**Expected Result**: ✅ Complete user journey works without backend

### Scenario 2: Admin User Journey
1. Login with "admin" email
2. See admin dashboard
3. Create alert
4. View user statistics
5. View all alerts
6. Send warning to user

**Expected Result**: ✅ Admin features work correctly

### Scenario 3: Offline Experience
1. App logged in with data cached
2. Enable airplane mode
3. Navigate between sections
4. Create new case (mock)
5. Add comment to post
6. Disable airplane mode
7. See data persisted

**Expected Result**: ✅ App works fully offline

### Scenario 4: Data Refresh
1. Load initial mock data
2. Pull to refresh
3. New mock data generated
4. Timestamps updated
5. Previous data in cache for fallback

**Expected Result**: ✅ Refresh generates new data

## Debugging & Troubleshooting

### Enable Debug Mode
```dart
// lib/core/network/api_config.dart
static const bool DEBUG_MODE = true;
```

### Check Mock Mode Status
```dart
import 'package:cctv_app/core/network/api_config.dart';

print(ApiConfig.getConfigStatus());
```

### View Cache Info
```dart
import 'package:cctv_app/core/storage/local_data_cache.dart';

final cache = LocalDataCache();
final info = await cache.getCacheInfo();
print(info);
```

### Clear All Data
```dart
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/storage/local_data_cache.dart';

await const AuthStorage().clear();
await const LocalDataCache().clearAllCache();
```

## Performance Benchmarks

Expected performance with mock data:
- App launch: < 2 seconds
- Home feed load: ~1 second (with 300ms simulated delay)
- Case list load: ~1 second
- Page transitions: ~200-300ms
- Scroll FPS: 60 FPS (smooth)

## Known Limitations

- No real user creation (mock only)
- No actual file uploads (mock URLs)
- No real-time synchronization
- No backend persistence (local only)
- No push notifications (mock only)
- All data is generated, not from database

## Transition to Firebase

When ready to migrate to Firebase:

1. **Update Configuration**
   ```dart
   static const bool USE_FIREBASE = true;
   static const bool MOCK_MODE = false;
   ```

2. **Implement Firebase Services**
   - Refer to `FIREBASE_MIGRATION_GUIDE.md`
   - Replace mock implementations with Firebase

3. **Test Firebase Integration**
   - Repeat all tests with Firebase
   - Verify data syncing
   - Check security rules

## Success Criteria

✅ All tests pass with mock data
✅ No backend connection required
✅ UI fully functional offline
✅ Data persists between sessions
✅ No crashes or errors
✅ Performance acceptable
✅ Ready for Firebase migration

## Next Steps

1. Run through all test cases
2. Document any issues found
3. Fix UI/logic bugs if any
4. Prepare for Firebase setup
5. Plan migration timeline

---

**Last Updated**: January 2026
**Version**: 1.0.0
**Status**: Ready for Testing
