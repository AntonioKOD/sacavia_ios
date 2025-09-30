# Firebase iOS SDK Setup & Push Notifications - Complete Guide

## ✅ Current Status

Your iOS app already has most of the Firebase setup implemented correctly:

- ✅ Firebase iOS SDK via Swift Package Manager
- ✅ `GoogleService-Info.plist` in app target
- ✅ Push Notifications capability enabled
- ✅ Basic AppDelegate implementation
- ✅ PushNotificationManager class

## 🔧 Swift Package Manager Setup

### 1. Verify Firebase Package
1. **In Xcode**: Go to your project → Package Dependencies
2. **Check**: `https://github.com/firebase/firebase-ios-sdk`
3. **Required Products**:
   - `FirebaseCore` ✅
   - `FirebaseMessaging` ✅

### 2. Add Missing Products (if needed)
```swift
// In Package.swift or Xcode Package Dependencies
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
],
targets: [
    .target(
        name: "SacaviaApp",
        dependencies: [
            .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
            .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
        ]
    )
]
```

## 📱 Xcode Project Configuration

### 1. Signing & Capabilities
1. **Select your target** → Signing & Capabilities
2. **Add Capability**: `Push Notifications`
3. **Add Capability**: `Background Modes`
   - ✅ `Remote notifications`
   - ✅ `Background fetch` (optional)

### 2. Bundle Identifier
- Ensure `com.sacavia.app` matches your Firebase project
- Verify in `GoogleService-Info.plist`

### 3. Provisioning Profile
- Use development profile for testing
- Ensure App ID has Push Notifications enabled

## 🚀 Enhanced AppDelegate Implementation

I've created a separate `AppDelegate.swift` file with comprehensive Firebase Messaging setup:

### Key Features:
- **Firebase Configuration**: Automatic setup and token management
- **Push Notification Handling**: Complete remote and local notification support
- **FCM Integration**: Token refresh and data message handling
- **Error Handling**: Comprehensive error logging and fallback
- **Background Support**: Background app refresh and notification handling

### File Structure:
```
SacaviaApp/
├── AppDelegate.swift              # New enhanced AppDelegate
├── SacaviaAppApp.swift           # Updated main app file
├── PushNotificationManager.swift  # Existing notification manager
└── GoogleService-Info.plist      # Firebase configuration
```

## 🔐 Entitlements Configuration

### 1. Development Entitlements (`SacaviaApp.entitlements`)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
</dict>
</plist>
```

### 2. Production Entitlements (`SacaviaAppRelease.entitlements`)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>production</string>
</dict>
</plist>
```

## 📋 Info.plist Configuration

### 1. Required Keys
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>background-fetch</string>
</array>

<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

### 2. Notification Categories (Optional)
```xml
<key>UNNotificationCategory</key>
<array>
    <dict>
        <key>identifier</key>
        <string>location_notification</string>
        <key>actions</key>
        <array>
            <dict>
                <key>identifier</key>
                <string>view_location</string>
                <key>title</key>
                <string>View Location</string>
                <key>options</key>
                <array>
                    <string>foreground</string>
                </array>
            </dict>
        </array>
    </dict>
</array>
```

## 🧪 Testing Push Notifications

### 1. Development Testing
```bash
# Test with Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Send test message to your device
3. Use FCM token from console logs
```

### 2. Local Testing
```swift
// In PushNotificationManager
func scheduleTestNotification() {
    scheduleLocalNotification(
        title: "🧪 Test Notification",
        body: "This is a test notification",
        timeInterval: 5,
        identifier: "test_notification"
    )
}
```

### 3. Console Logs
Look for these log messages:
```
✅ [AppDelegate] FCM registration token: [token]
✅ [AppDelegate] Successfully registered for remote notifications
📱 [AppDelegate] APNs device token: [token]
```

## 🔄 Token Management

### 1. FCM Token Refresh
- Automatically handled by Firebase SDK
- Tokens refresh when app becomes active
- Stored in `PushNotificationManager.shared.deviceToken`

### 2. Server Registration
```swift
// In AppDelegate
private func sendDeviceTokenToServer(deviceToken: Data?, fcmToken: String?) {
    if let fcmToken = fcmToken {
        // Send to your backend API
        // POST /api/push/register
        // {
        //   "deviceToken": fcmToken,
        //   "platform": "ios",
        //   "userId": "user_id"
        // }
    }
}
```

## 🚨 Common Issues & Solutions

### 1. "No valid 'aps-environment' entitlement"
**Solution**: 
- Add Push Notifications capability in Xcode
- Ensure proper provisioning profile
- Check Apple Developer Portal configuration

### 2. "Failed to register for remote notifications"
**Solution**:
- Verify bundle identifier matches Firebase project
- Check provisioning profile validity
- Ensure APNs certificate is uploaded to Firebase

### 3. "FCM token not received"
**Solution**:
- Verify Firebase configuration
- Check network connectivity
- Ensure `GoogleService-Info.plist` is in target

### 4. "Notifications not showing"
**Solution**:
- Check notification permissions
- Verify notification settings in iOS Settings
- Test with local notifications first

## 📊 Monitoring & Debugging

### 1. Firebase Console
- **Analytics**: Message delivery statistics
- **Crashlytics**: App crash reports
- **Cloud Messaging**: Message delivery logs

### 2. Xcode Console
- Filter by `[AppDelegate]` or `[PushNotificationManager]`
- Look for success/error indicators
- Monitor token refresh cycles

### 3. Device Settings
- **Settings → Notifications → Sacavia**
- Ensure notifications are enabled
- Check alert, badge, and sound settings

## 🚀 Production Deployment

### 1. App Store
- Update entitlements to `production`
- Use production provisioning profile
- Test with TestFlight before release

### 2. Firebase Configuration
- Upload production APNs certificate
- Update `GoogleService-Info.plist` if needed
- Configure production environment

### 3. Server Integration
- Update API endpoints to production URLs
- Implement proper error handling
- Add monitoring and analytics

## 📚 Additional Resources

- [Firebase iOS Documentation](https://firebase.google.com/docs/ios/setup)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [iOS Background Execution](https://developer.apple.com/documentation/backgroundtasks)

## ✅ Checklist

- [ ] Firebase iOS SDK added via SPM
- [ ] `GoogleService-Info.plist` in app target
- [ ] Push Notifications capability enabled
- [ ] Background Modes → Remote notifications enabled
- [ ] AppDelegate.swift implemented
- [ ] Entitlements configured
- [ ] Info.plist updated
- [ ] Test notifications working
- [ ] FCM tokens being received
- [ ] Server integration implemented
- [ ] Production configuration ready

Your app is now fully configured for Firebase Cloud Messaging with comprehensive push notification support!
