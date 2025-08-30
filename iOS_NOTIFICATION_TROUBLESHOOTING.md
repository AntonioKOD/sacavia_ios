# iOS Notification Troubleshooting Guide

## Overview
This guide helps you troubleshoot notification issues in the Sacavia iOS app. The notification system includes both local notifications and push notifications.

## Quick Diagnostic Steps

### 1. Check App Permissions
1. **Open iOS Settings**
2. **Go to Notifications > Sacavia**
3. **Verify these settings:**
   - ✅ Allow Notifications: ON
   - ✅ Sounds: ON
   - ✅ Badges: ON
   - ✅ Banners: ON (or your preferred style)

### 2. Check App Status
1. **Open the Sacavia app**
2. **Go to Profile > Settings > Test Notifications**
3. **Check the status indicators:**
   - Permission Status: Should show "Enabled"
   - Device Token: Should show a token string
   - Registration Status: Should show "Registered"

### 3. Check Console Logs
1. **Open Xcode**
2. **Connect your device**
3. **Open Console app on Mac**
4. **Filter for "Sacavia"**
5. **Look for notification-related logs**

## Common Issues and Solutions

### Issue 1: "Permission denied"
**Symptoms:**
- App shows "Permission Status: Disabled"
- No notification permission prompt appears
- Settings shows notifications are blocked

**Solutions:**
1. **Reset notification permissions:**
   - Go to iOS Settings > General > Reset > Reset Location & Privacy
   - Reinstall the app
   - Grant notification permission when prompted

2. **Manual permission reset:**
   - Go to iOS Settings > Notifications > Sacavia
   - Toggle "Allow Notifications" OFF, then ON
   - Restart the app

3. **Check Focus modes:**
   - Go to iOS Settings > Focus
   - Ensure Sacavia is allowed in your current focus mode

### Issue 2: "Device token not available"
**Symptoms:**
- App shows "Device Token: Not available"
- Push notifications don't work
- Console shows registration errors

**Causes:**
- Push notification entitlements missing
- App not properly signed
- Development vs production configuration

**Solutions:**
1. **Check Xcode project settings:**
   - Open Xcode project
   - Select your target
   - Go to "Signing & Capabilities"
   - Ensure "Push Notifications" capability is added
   - Verify "Background Modes" includes "Remote notifications"

2. **Check entitlements file:**
   - Verify `SacaviaApp.entitlements` exists
   - Ensure it contains `aps-environment` key
   - Value should be `development` for debug builds

3. **Check App ID configuration:**
   - Go to Apple Developer Portal
   - Select your App ID
   - Enable Push Notifications
   - Generate and download certificates

### Issue 3: "Server connection failed"
**Symptoms:**
- Test Server Connection fails
- Device registration fails
- Network errors in console

**Solutions:**
1. **Check network connectivity:**
   - Ensure device has internet connection
   - Try on different network (WiFi vs Cellular)

2. **Check server URL:**
   - Verify `baseAPIURL` in `APIService.swift`
   - Ensure server is running and accessible

3. **Check authentication:**
   - Ensure user is logged in
   - Verify auth token is valid
   - Try logging out and back in

### Issue 4: "Local notifications work but push notifications don't"
**Symptoms:**
- Test Local Notification works
- Test Server Notification fails
- Device token exists but push notifications don't arrive

**Causes:**
- APN certificates not configured on server
- Development vs production environment mismatch
- Server-side push notification code issues

**Solutions:**
1. **Check server configuration:**
   - Verify APN certificates are uploaded to server
   - Check server logs for push notification errors
   - Ensure server is using correct environment (dev/prod)

2. **Check environment matching:**
   - Development builds should use development APN
   - Production builds should use production APN
   - Verify `aps-environment` matches your build configuration

### Issue 5: "Notifications appear but don't work properly"
**Symptoms:**
- Notifications show but tapping doesn't work
- Wrong notification content
- Notifications don't close

**Solutions:**
1. **Check notification handlers:**
   - Verify `UNUserNotificationCenterDelegate` is set
   - Check `didReceive response` method
   - Ensure navigation logic is correct

2. **Check notification data:**
   - Verify notification payload structure
   - Check userInfo parsing
   - Ensure navigation parameters are correct

## Testing Notifications

### 1. Local Notification Test
1. **Open the app**
2. **Go to Profile > Settings > Test Notifications**
3. **Tap "Test Local Notification"**
4. **Expected result:** Notification appears immediately

### 2. Server Connection Test
1. **Tap "Test Server Connection"**
2. **Expected result:** "Server connection successful!"

### 3. Server Notification Test
1. **Tap "Test Server Notification"**
2. **Expected result:** Push notification arrives from server

### 4. Registration Status Check
1. **Tap "Check Registration Status"**
2. **Expected result:** "Device is registered"

## Environment Setup

### Development Environment
```swift
// In Xcode project settings:
// - Bundle Identifier: com.sacavia.app
// - Team: Your development team
// - Signing: Automatic or Manual
// - Capabilities: Push Notifications

// In entitlements file:
<key>aps-environment</key>
<string>development</string>
```

### Production Environment
```swift
// In Xcode project settings:
// - Bundle Identifier: com.sacavia.app
// - Team: Your production team
// - Signing: Manual with distribution certificate
// - Capabilities: Push Notifications

// In entitlements file:
<key>aps-environment</key>
<string>production</string>
```

## Debug Mode

Enable debug logging by checking console output for:
```
📱 [PushNotificationManager] Notification permission status: 3
📱 [PushNotificationManager] Device token: [TOKEN]
📱 [PushNotificationManager] Device token successfully registered with server
📱 [AppDelegate] ✅ Successfully registered for remote notifications
```

## Device-Specific Issues

### iPhone
- Check Do Not Disturb mode
- Verify Focus modes
- Check notification settings per app

### iPad
- Check notification settings
- Verify app is not in split-screen mode
- Check if notifications are enabled for iPad

### Simulator
- Push notifications don't work in simulator
- Use local notifications for testing
- Test on real device for push notifications

## Server-Side Issues

### Check API Endpoints
1. `/api/mobile/test` - Server connectivity
2. `/api/mobile/notifications/register-device` - Device registration
3. `/api/mobile/notifications/test` - Push notification test
4. `/api/mobile/notifications/check-registration` - Registration status

### Check Server Logs
Look for:
- Device token registration logs
- Push notification sending logs
- Authentication errors
- Network errors

## Performance Issues

### Too Many Notifications
- Implement notification batching
- Add rate limiting
- Use notification tags to prevent duplicates

### Slow Notification Delivery
- Check server performance
- Optimize database queries
- Use background workers for notification sending

## Security Considerations

### APN Certificates
- Keep certificates secure
- Rotate certificates regularly
- Use environment variables for sensitive data

### User Privacy
- Respect user preferences
- Allow users to opt out
- Don't send sensitive data in notifications

## Getting Help

If you're still experiencing issues:

1. **Check the console logs** for specific error messages
2. **Verify your environment setup** matches the requirements
3. **Test on different devices** to isolate device-specific issues
4. **Check the network tab** for failed API requests
5. **Review the notification implementation** in the code

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Permission denied" | User blocked notifications | Reset permissions in Settings |
| "Device token not available" | Registration failed | Check entitlements and signing |
| "Server connection failed" | Network/auth issues | Check connectivity and auth |
| "Push notification failed" | APN configuration | Check server APN setup |
| "Registration failed" | Entitlements missing | Add Push Notifications capability |

## Testing Checklist

- [ ] App has notification permission
- [ ] Device token is generated
- [ ] Device is registered with server
- [ ] Local notifications work
- [ ] Server connection works
- [ ] Push notifications work
- [ ] Notification taps work
- [ ] Notifications close properly
- [ ] Focus modes allow notifications
- [ ] Do Not Disturb is not blocking

## Next Steps

1. **Run through the testing checklist**
2. **Use the NotificationTestView** in the app
3. **Check console logs** for detailed information
4. **Verify server configuration** if push notifications fail
5. **Test on real device** (not simulator)

The enhanced logging and testing tools should help identify exactly what's causing the notification issues! 🔍
