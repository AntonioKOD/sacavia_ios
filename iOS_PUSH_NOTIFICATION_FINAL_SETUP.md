# iOS Push Notification Final Setup Guide

## 🚨 **Current Issue**
The iOS app shows:
```
📱 [PushNotificationManager] ❌ aps-environment NOT found
📱 [PushNotificationManager] ❌ Entitlements file NOT found
```

But the app is successfully connecting to production: `https://sacavia.com`

## 🔧 **Step-by-Step Fix**

### **Step 1: Xcode Project Configuration**

1. **Open Xcode** and load `SacaviaApp.xcodeproj`
2. **Select the project** (top level) in the navigator
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

### **Step 5: Check Build Settings**

1. **In Xcode, go to "Build Settings"**
2. **Search for "Code Signing"**
3. **Ensure "Code Signing Identity" is set correctly**
4. **Verify "Provisioning Profile" is set**
5. **Search for "Entitlements"**
6. **Ensure "Code Signing Entitlements" points to `SacaviaApp/SacaviaApp.entitlements`**

### **Step 6: Clean and Rebuild**

1. **In Xcode, go to "Product" > "Clean Build Folder"**
2. **Delete the app from simulator/device**
3. **Build and run the app again**

## 🔍 **Verification Steps**

### **Check Console Logs**
After fixing, you should see:
```
📱 [PushNotificationManager] ✅ aps-environment found: development
📱 [PushNotificationManager] ✅ Entitlements file found
📱 [AppDelegate] ✅ Successfully registered for remote notifications
📱 [PushNotificationManager] Device token: [ACTUAL_TOKEN]
```

### **Check Device Settings**
1. **Go to iOS Settings > Notifications > Sacavia**
2. **Ensure "Allow Notifications" is ON**
3. **Check that all notification types are enabled**

## 🚨 **Common Issues and Solutions**

### **Issue 1: "Entitlements file NOT found"**
**Solution:**
- Ensure the entitlements file is properly linked in Build Settings
- Check that the file path is correct: `SacaviaApp/SacaviaApp.entitlements`
- Clean and rebuild the project

### **Issue 2: "aps-environment NOT found"**
**Solution:**
- Ensure Push Notifications capability is added in Xcode
- Verify the entitlements file contains the `aps-environment` key
- Check that the app is properly signed

### **Issue 3: "Device token not available"**
**Solution:**
- Run on a real device (not simulator)
- Ensure user granted notification permission
- Check that app is properly signed

## 📱 **Testing After Fix**

1. **Run the app on a real device** (not simulator)
2. **Grant notification permission** when prompted
3. **Go to Profile > Settings > Test Notifications**
4. **Check that:**
   - Permission Status shows "Enabled"
   - Device Token shows an actual token
   - Registration Status shows "Registered"

## 🎯 **Expected Behavior After Fix**

1. **App Launch:**
   ```
   📱 [PushNotificationManager] ✅ aps-environment found: development
   📱 [PushNotificationManager] ✅ Entitlements file found
   📱 [AppDelegate] ✅ Successfully registered for remote notifications
   📱 [PushNotificationManager] Device token: [ACTUAL_TOKEN]
   📱 [PushNotificationManager] Device token successfully registered with server
   ```

2. **Notification Test:**
   - Local notifications work immediately
   - Server notifications work (logged but not sent in development)
   - Device registration status shows as "Registered"

## 🚀 **Production Deployment**

For production deployment:

1. **Change entitlements to production:**
   ```xml
   <key>aps-environment</key>
   <string>production</string>
   ```

2. **Configure Apple Developer Portal:**
   - Enable Push Notifications for your App ID
   - Generate APN certificates
   - Configure server with APN certificates

3. **Update server configuration:**
   - Add APN certificates to your production server
   - Configure push notification service

## ✅ **Current Status**

- ✅ **Production URL configured** (`https://sacavia.com`)
- ✅ **Server connection working**
- ✅ **Entitlements file exists**
- ⚠️ **Push Notifications capability needs to be added in Xcode**
- ⚠️ **Background Modes capability needs to be added in Xcode**

The key missing piece is adding the Push Notifications capability in Xcode! 🔧
