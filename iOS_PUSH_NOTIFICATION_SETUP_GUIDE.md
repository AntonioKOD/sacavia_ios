# iOS Push Notification Setup Guide

## 🚨 **Current Issue**
The iOS app is showing:
```
❌ No push notification entitlements found. Running in local-only mode.
To enable push notifications:
1. Add 'Push Notifications' capability in Xcode
2. Configure App ID in Apple Developer Portal
3. Add APN certificates to server
```

## 🔧 **Step-by-Step Fix**

### **Step 1: Configure Xcode Project**

1. **Open Xcode** and load `SacaviaApp.xcodeproj`
2. **Select the project** in the navigator (top level)
3. **Select the target** (SacaviaApp)
4. **Go to "Signing & Capabilities" tab**

### **Step 2: Add Push Notifications Capability**

1. **Click the "+ Capability" button** (top left of capabilities section)
2. **Search for "Push Notifications"**
3. **Double-click to add it**
4. **Verify it appears in the capabilities list**

### **Step 3: Add Background Modes Capability**

1. **Click "+ Capability" again**
2. **Search for "Background Modes"**
3. **Double-click to add it**
4. **Check the box for "Remote notifications"**

### **Step 4: Verify Entitlements File**

Your `SacaviaApp.entitlements` file should look like this:
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

### **Step 5: Configure Apple Developer Portal**

1. **Go to [Apple Developer Portal](https://developer.apple.com/account/)**
2. **Navigate to "Certificates, Identifiers & Profiles"**
3. **Select "Identifiers"**
4. **Find your App ID** (com.sacavia.app)
5. **Click on it to edit**
6. **Scroll down to "Capabilities"**
7. **Enable "Push Notifications"**
8. **Save the changes**

### **Step 6: Generate APN Certificates (Optional for Development)**

For development, you can use the existing setup. For production:

1. **In Apple Developer Portal, go to "Certificates"**
2. **Click "+" to create a new certificate**
3. **Select "Apple Push Notification service SSL (Sandbox & Production)"**
4. **Choose your App ID**
5. **Follow the certificate creation process**
6. **Download and install the certificate**

### **Step 7: Update Xcode Build Settings**

1. **In Xcode, go to "Build Settings"**
2. **Search for "Code Signing"**
3. **Ensure "Code Signing Identity" is set correctly**
4. **Verify "Provisioning Profile" is set**

### **Step 8: Clean and Rebuild**

1. **In Xcode, go to "Product" > "Clean Build Folder"**
2. **Delete the app from simulator/device**
3. **Build and run the app again**

### **Step 9: Test the Setup**

1. **Run the app on a real device** (not simulator)
2. **Go to Profile > Settings > Test Notifications**
3. **Check the status indicators:**
   - Permission Status: Should show "Enabled"
   - Device Token: Should show a token string
   - Registration Status: Should show "Registered"

## 🔍 **Verification Steps**

### **Check Console Logs**
Look for these success messages:
```
📱 [PushNotificationManager] ✅ Push notification entitlements found!
📱 [AppDelegate] ✅ Successfully registered for remote notifications
📱 [PushNotificationManager] Device token: [TOKEN_STRING]
📱 [PushNotificationManager] Device token successfully registered with server
```

### **Check Device Settings**
1. **Go to iOS Settings > Notifications > Sacavia**
2. **Ensure "Allow Notifications" is ON**
3. **Check that all notification types are enabled**

## 🚨 **Common Issues and Solutions**

### **Issue 1: "No push notification entitlements found"**
**Solution:**
- Ensure Push Notifications capability is added in Xcode
- Verify entitlements file contains `aps-environment`
- Clean and rebuild the project

### **Issue 2: "Device token not available"**
**Solution:**
- Run on a real device (not simulator)
- Ensure user granted notification permission
- Check that app is properly signed

### **Issue 3: "Registration failed"**
**Solution:**
- Verify App ID has Push Notifications enabled
- Check network connectivity
- Ensure server is running and accessible

### **Issue 4: "APN provider not initialized"**
**Solution:**
- This is normal in development mode
- For production, configure APN certificates on server
- Development mode will still work for testing

## 📱 **Testing Checklist**

- [ ] Push Notifications capability added in Xcode
- [ ] Background Modes capability added with "Remote notifications"
- [ ] Entitlements file contains `aps-environment`
- [ ] App ID has Push Notifications enabled in Apple Developer Portal
- [ ] App is running on a real device
- [ ] User granted notification permission
- [ ] Device token is generated
- [ ] Device is registered with server
- [ ] Local notifications work
- [ ] Server notifications work (in development mode)

## 🎯 **Expected Behavior After Fix**

1. **App Launch:**
   ```
   📱 [PushNotificationManager] ✅ Push notification entitlements found!
   📱 [PushNotificationManager] aps-environment: development
   📱 [AppDelegate] ✅ Successfully registered for remote notifications
   📱 [PushNotificationManager] Device token: [ACTUAL_TOKEN]
   📱 [PushNotificationManager] Device token successfully registered with server
   ```

2. **Notification Test:**
   - Local notifications work immediately
   - Server notifications work (logged but not sent in development)
   - Device registration status shows as "Registered"

## 🚀 **Next Steps**

1. **Follow the setup steps above**
2. **Test on a real device**
3. **Use the NotificationTestView to verify functionality**
4. **For production, configure APN certificates on the server**

The key is ensuring the Xcode project has the Push Notifications capability properly configured! 🔧
