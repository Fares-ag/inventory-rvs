# Firebase Integration Setup Guide

This inventory system has been integrated with Firebase. Follow these steps to complete the setup:

## 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Follow the setup wizard

## 2. Add Firebase to Your Flutter App

### For Android:
1. In Firebase Console, click "Add app" and select Android
2. Register your app with package name: `com.example.inventory_system` (found in `android/app/build.gradle.kts`)
3. Download `google-services.json`
4. Place it in `android/app/` directory
5. The Google Services Gradle plugin has already been configured in:
   - `android/settings.gradle.kts` (plugin declaration)
   - `android/app/build.gradle.kts` (plugin application)
   - Firebase BoM (Bill of Materials) is included in `android/app/build.gradle.kts`

### For iOS:
1. In Firebase Console, click "Add app" and select iOS
2. Register your app with bundle ID (found in `ios/Runner.xcodeproj`)
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

### For Web:
1. In Firebase Console, click "Add app" and select Web
2. Copy the Firebase configuration
3. It will be used in `firebase_options.dart`

## 3. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

## 4. Configure Firebase

Run this command in your project root:

```bash
flutterfire configure
```

This will:
- Detect your Firebase projects
- Generate `lib/firebase_options.dart` with your project configuration
- Configure your app for all platforms

## 5. Enable Firebase Services

In Firebase Console, enable:

1. **Authentication**:
   - Go to Authentication > Sign-in method
   - Enable "Email/Password"

2. **Firestore Database**:
   - Go to Firestore Database
   - Click "Create database"
   - Start in test mode (for development)
   - Choose a location

3. **Storage**:
   - Go to Storage
   - Click "Get started"
   - Start in test mode (for development)
   - Choose a location

## 6. Firestore Security Rules

Update your Firestore security rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    // Allow unauthenticated reads for login (username lookup)
    // Writes require authentication
    match /users/{userId} {
      allow read: if true; // Allow reads for login lookup
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Products collection
    match /products/{productId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Stock collection
    match /stock/{stockId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Locations collection
    match /locations/{locationId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Stock movements collection
    match /stock_movements/{movementId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## 7. Storage Security Rules

Update your Storage security rules in Firebase Console:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /product_images/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## 8. Create Default Admin User

After running the app for the first time, you'll need to create an admin user:

1. The app will attempt to create a default admin user
2. Or manually create one in Firebase Console > Authentication
3. Then add user details in Firestore > users collection

## Migration Notes

- All IDs have been changed from `int` to `String` for Firestore compatibility
- Images are now stored in Firebase Storage instead of local filesystem
- Real-time updates are enabled for all collections
- The old SQLite database code is still present but not used

## Troubleshooting

- If you see "Firebase not initialized" errors, make sure `firebase_options.dart` exists
- If authentication fails, check that Email/Password is enabled in Firebase Console
- If Firestore queries fail, check your security rules
- If image uploads fail, check Storage security rules and permissions

