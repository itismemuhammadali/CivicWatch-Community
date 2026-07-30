# Firebase Emulator Setup and Run Guide

Since there are permission issues with the live Firestore, the application has been configured to use the local Firebase Emulator Suite. 

## Prerequisites
- Node.js installed
- Java (JRE) installed (Required by Firebase Emulator)
- Firebase CLI installed (`npm install -g firebase-tools`)

## How to Start the Emulators

1. Open your terminal in the project root (`CctvMobileApplication`).
2. Run the following command to start the emulators:
   ```bash
   firebase emulators:start
   ```
3. Wait for the terminal to say "All emulators ready!". It will start Auth on port `9099` and Firestore on port `8080`.
4. The Emulator UI will be available at: http://127.0.0.1:4000
   - You can view the local Firestore database and Auth users here.

## Application Configuration
The Flutter application is already configured to connect to these emulators automatically when running in **Debug Mode** (`kDebugMode`). Just launch the app normally:
```bash
flutter run -d chrome
```

## Adding Initial Credentials
When the emulator starts, it starts empty. You can register the users directly via the app's login/signup flow, or the app will **auto-provision** them when you try to login with the credentials provided:

- `user@cctv.app` / `user@123`
- `admin@cctv.app` / `admin@123`
- `superadmin@cctv.app` / `superadmin@123`

*Note: I have added logic to auto-create these specific accounts with their respective roles when a login attempt fails due to 'user-not-found' on the emulator.*

## How to Stop / Kill the Emulators
To gracefully stop the emulators:
- Press `Ctrl + C` in the terminal where the emulators are running.

### Force Killing Emulator Tasks (Windows)
If the emulators crash or ports (8080, 9099, 4000) are stuck/in-use, you can force kill the Java and Node processes holding them.
Open a terminal as Administrator and run:
```powershell
# Kill processes using standard emulator ports
Stop-Process -Id (Get-NetTCPConnection -LocalPort 8080).OwningProcess -Force
Stop-Process -Id (Get-NetTCPConnection -LocalPort 9099).OwningProcess -Force
Stop-Process -Id (Get-NetTCPConnection -LocalPort 4000).OwningProcess -Force
```
Alternatively, since the Firebase emulator primarily runs via Java:
```powershell
taskkill /F /IM java.exe
taskkill /F /IM node.exe
```
*(Warning: This will kill ALL Java and Node processes on your machine).*
firebase emulators:start --project commctv-f2b45
