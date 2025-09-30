import UIKit
import UserNotifications
import Firebase
import FirebaseCore
import FirebaseMessaging

// MARK: - Data Extension for Hex String Conversion
extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0..<len {
            let j = hexString.index(i, offsetBy: 2)
            let bytes = hexString[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let fcmTokenRegistrationFailed = Notification.Name("fcmTokenRegistrationFailed")
    static let apnsTokenRegistrationFailed = Notification.Name("apnsTokenRegistrationFailed")
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("📱 [AppDelegate] App did finish launching")
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set up Firebase Messaging
        setupFirebaseMessaging()
        
        // Set up push notification delegates
        setupPushNotificationDelegates(application)
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // MARK: - Firebase Messaging Setup
    private func setupFirebaseMessaging() {
        let messaging = Messaging.messaging()
        messaging.delegate = self
        
        // Enable auto initialization
        messaging.isAutoInitEnabled = true
        
        // Set APNs token if available
        if let apnsToken = UserDefaults.standard.data(forKey: "APNsToken") {
            messaging.apnsToken = apnsToken
            print("📱 [AppDelegate] Restored APNs token from UserDefaults")
            
            // Now get FCM token after APNs token is set
            messaging.token { [weak self] token, error in
                if let error = error {
                    print("❌ [AppDelegate] Error fetching FCM registration token: \(error)")
                } else if let token = token {
                    print("✅ [AppDelegate] FCM registration token: \(token)")
                    self?.handleNewFCMToken(token)
                }
            }
        } else {
            print("📱 [AppDelegate] No APNs token available yet, will get FCM token after APNs registration")
        }
    }
    
    // MARK: - Push Notification Setup
    private func setupPushNotificationDelegates(_ application: UIApplication) {
        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = PushNotificationManager.shared
        
        // Note: Permission request is handled by PushNotificationManager to avoid conflicts
        print("📱 [AppDelegate] Notification center delegate set to PushNotificationManager")
    }
    
    // MARK: - Remote Notification Registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ [AppDelegate] Successfully registered for remote notifications")
        print("📱 [AppDelegate] Device token data length: \(deviceToken.count) bytes")
        
        // Convert device token to readable format
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📱 [AppDelegate] APNs device token: \(token)")
        
        // Store APNs token in UserDefaults for restoration
        UserDefaults.standard.set(deviceToken, forKey: "APNsToken")
        
        // Pass APNs token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        
        // Now get FCM token after APNs token is set
        Messaging.messaging().token { [weak self] fcmToken, error in
            if let error = error {
                print("❌ [AppDelegate] Error fetching FCM token after APNs registration: \(error)")
            } else if let fcmToken = fcmToken {
                print("✅ [AppDelegate] FCM token after APNs registration: \(fcmToken)")
                self?.handleNewFCMToken(fcmToken)
            }
        }
        
        // Send APNs token to your server via TokenAPI
        sendDeviceTokenToServer(deviceToken: deviceToken, fcmToken: nil)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [AppDelegate] Failed to register for remote notifications: \(error)")
        print("📱 [AppDelegate] Error domain: \(error._domain)")
        print("📱 [AppDelegate] Error code: \(error._code)")
        print("📱 [AppDelegate] Error description: \(error.localizedDescription)")
        
        // Check for common error types
        if let nsError = error as NSError? {
            switch nsError.code {
            case 3000: // No valid 'aps-environment' entitlement
                print("❌ [AppDelegate] Push notification entitlements missing")
                print("📱 [AppDelegate] To fix this:")
                print("📱 [AppDelegate] 1. Add 'Push Notifications' capability in Xcode")
                print("📱 [AppDelegate] 2. Configure App ID in Apple Developer Portal")
                print("📱 [AppDelegate] 3. Ensure proper provisioning profile")
            case 3001: // Invalid provisioning profile
                print("❌ [AppDelegate] Invalid provisioning profile")
            case 3002: // Invalid APNs certificate
                print("❌ [AppDelegate] Invalid APNs certificate")
            default:
                print("📱 [AppDelegate] Unknown error code: \(nsError.code)")
            }
        }
        
        // Set up for local notifications only
        DispatchQueue.main.async {
            PushNotificationManager.shared.isRegistered = true
            PushNotificationManager.shared.permissionStatus = .authorized
        }
    }
    
    // MARK: - Remote Notification Handling
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📱 [AppDelegate] Received remote notification: \(userInfo)")
        
        // Handle FCM data messages
        if let fcmMessageID = userInfo["gcm.message_id"] {
            print("📱 [AppDelegate] FCM Message ID: \(fcmMessageID)")
        }
        
        // Process notification content
        if let aps = userInfo["aps"] as? [String: Any] {
            handleNotificationPayload(aps: aps, application: application)
        }
        
        // Handle custom data
        if let customData = userInfo["data"] as? [String: Any] {
            handleCustomData(customData)
        }
        
        completionHandler(.newData)
    }
    
    // MARK: - Local Notification Handling
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        print("📱 [AppDelegate] Received local notification: \(notification.alertTitle ?? "No title")")
    }
    
    // MARK: - Background App Refresh
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📱 [AppDelegate] Background app refresh triggered")
        
        // Perform background tasks here
        // For example, refresh data, sync with server, etc.
        
        completionHandler(.newData)
    }
    
    // MARK: - App State Changes
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("📱 [AppDelegate] App will enter foreground")
        
        // Ensure APNs token is set before getting FCM token
        if let apnsToken = UserDefaults.standard.data(forKey: "APNsToken") {
            Messaging.messaging().apnsToken = apnsToken
            print("📱 [AppDelegate] Restored APNs token for foreground refresh")
        }
        
        // Refresh FCM token when app becomes active
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                print("❌ [AppDelegate] Error refreshing FCM token in foreground: \(error)")
            } else if let token = token {
                print("✅ [AppDelegate] FCM token refreshed in foreground: \(token)")
                self?.handleNewFCMToken(token)
            }
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("📱 [AppDelegate] App did enter background")
        
        // Save any pending data
        UserDefaults.standard.synchronize()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("📱 [AppDelegate] App did become active")
        
        // Handle any failed token registrations
        NotificationCenter.default.addObserver(
            forName: .fcmTokenRegistrationFailed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let fcmToken = notification.object as? String {
                print("🔄 [AppDelegate] Retrying FCM token registration: \(fcmToken)")
                self?.handleNewFCMToken(fcmToken)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .apnsTokenRegistrationFailed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let apnsToken = notification.object as? String {
                print("🔄 [AppDelegate] Retrying APNs token registration: \(apnsToken)")
                // Convert string back to Data and retry
                if let tokenData = Data(hexString: apnsToken) {
                    self?.sendDeviceTokenToServer(deviceToken: tokenData, fcmToken: nil)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleNotificationPayload(aps: [String: Any], application: UIApplication) {
        if let alert = aps["alert"] as? [String: Any] {
            let title = alert["title"] as? String ?? "Notification"
            let body = alert["body"] as? String ?? ""
            
            print("📱 [AppDelegate] Notification - Title: \(title), Body: \(body)")
            
            // Show local notification if app is in background
            if application.applicationState != .active {
                PushNotificationManager.shared.scheduleLocalNotification(
                    title: title,
                    body: body,
                    timeInterval: 1,
                    identifier: "remote_notification_\(Date().timeIntervalSince1970)"
                )
            }
        }
        
        // Handle badge count
        if let badge = aps["badge"] as? Int {
            application.applicationIconBadgeNumber = badge
        }
        
        // Handle sound
        if let sound = aps["sound"] as? String {
            print("📱 [AppDelegate] Notification sound: \(sound)")
        }
        
        // Handle category
        if let category = aps["category"] as? String {
            print("📱 [AppDelegate] Notification category: \(category)")
        }
    }
    
    private func handleCustomData(_ data: [String: Any]) {
        print("📱 [AppDelegate] Custom data received: \(data)")
        
        // Handle specific data types
        if let type = data["type"] as? String {
            switch type {
            case "location":
                handleLocationNotification(data)
            case "event":
                handleEventNotification(data)
            case "user":
                handleUserNotification(data)
            default:
                print("📱 [AppDelegate] Unknown notification type: \(type)")
            }
        }
    }
    
    private func handleLocationNotification(_ data: [String: Any]) {
        if let locationId = data["locationId"] as? String {
            print("📱 [AppDelegate] Location notification for ID: \(locationId)")
            // Navigate to location or update UI
        }
    }
    
    private func handleEventNotification(_ data: [String: Any]) {
        if let eventId = data["eventId"] as? String {
            print("📱 [AppDelegate] Event notification for ID: \(eventId)")
            // Navigate to event or update UI
        }
    }
    
    private func handleUserNotification(_ data: [String: Any]) {
        if let userId = data["userId"] as? String {
            print("📱 [AppDelegate] User notification for ID: \(userId)")
            // Navigate to user profile or update UI
        }
    }
    
    private func handleNewFCMToken(_ token: String) {
        print("✅ [AppDelegate] New FCM token received: \(token)")
        
        // Send token to your server via TokenAPI
        sendDeviceTokenToServer(deviceToken: nil, fcmToken: token)
        
        // Update PushNotificationManager
        DispatchQueue.main.async {
            PushNotificationManager.shared.deviceToken = token
        }
    }
    
    private func sendDeviceTokenToServer(deviceToken: Data?, fcmToken: String?) {
        // Use the enhanced registration method
        registerTokenWithRetry(deviceToken: deviceToken, fcmToken: fcmToken)
    }
    
    private func registerTokenWithRetry(deviceToken: Data?, fcmToken: String?, retryCount: Int = 0) {
        // Get current user ID if available
        let userId = getCurrentUserId()
        
        if let fcmToken = fcmToken {
            print("📱 [AppDelegate] Sending FCM token to server: \(fcmToken)")
            
            // Register FCM token with server via TokenAPI
            Task {
                let deviceInfo = TokenAPI.getCurrentDeviceInfo()
                let result = await TokenAPI.shared.registerDeviceToken(
                    deviceToken: fcmToken,
                    userId: userId,
                    platform: "ios",
                    deviceInfo: deviceInfo
                )
                
                switch result {
                case .success(let response):
                    print("✅ [AppDelegate] FCM token registered successfully: \(response.message)")
                    // Store successful registration
                    UserDefaults.standard.set(fcmToken, forKey: "LastRegisteredFCMToken")
                    UserDefaults.standard.set(Date(), forKey: "LastFCMTokenRegistration")
                case .failure(let error):
                    print("❌ [AppDelegate] Failed to register FCM token: \(error.localizedDescription)")
                    
                    // Retry logic for failed registrations
                    if retryCount < 3 {
                        print("🔄 [AppDelegate] Retrying FCM token registration (attempt \(retryCount + 1)/3)")
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(retryCount + 1) * 2) {
                            self.registerTokenWithRetry(deviceToken: deviceToken, fcmToken: fcmToken, retryCount: retryCount + 1)
                        }
                    } else {
                        print("❌ [AppDelegate] FCM token registration failed after 3 attempts")
                        // Schedule retry for later when app becomes active
                        NotificationCenter.default.post(name: .fcmTokenRegistrationFailed, object: fcmToken)
                    }
                }
            }
        }
        
        if let deviceToken = deviceToken {
            let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
            print("📱 [AppDelegate] Sending APNs token to server: \(tokenString)")
            
            // Register APNs token with server via TokenAPI
            Task {
                let deviceInfo = TokenAPI.getCurrentDeviceInfo()
                let result = await TokenAPI.shared.registerDeviceToken(
                    deviceToken: tokenString,
                    userId: userId,
                    platform: "ios",
                    deviceInfo: deviceInfo
                )
                
                switch result {
                case .success(let response):
                    print("✅ [AppDelegate] APNs token registered successfully: \(response.message)")
                    // Store successful registration
                    UserDefaults.standard.set(tokenString, forKey: "LastRegisteredAPNsToken")
                    UserDefaults.standard.set(Date(), forKey: "LastAPNsTokenRegistration")
                case .failure(let error):
                    print("❌ [AppDelegate] Failed to register APNs token: \(error.localizedDescription)")
                    
                    // Retry logic for failed registrations
                    if retryCount < 3 {
                        print("🔄 [AppDelegate] Retrying APNs token registration (attempt \(retryCount + 1)/3)")
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(retryCount + 1) * 2) {
                            self.registerTokenWithRetry(deviceToken: deviceToken, fcmToken: fcmToken, retryCount: retryCount + 1)
                        }
                    } else {
                        print("❌ [AppDelegate] APNs token registration failed after 3 attempts")
                        // Schedule retry for later when app becomes active
                        NotificationCenter.default.post(name: .apnsTokenRegistrationFailed, object: tokenString)
                    }
                }
            }
        }
    }
    
    private func getCurrentUserId() -> String? {
        // Get current user ID from your authentication system
        // This should integrate with your existing AuthManager
        return AuthManager.shared.user?.id
    }
}

// MARK: - Firebase Messaging Delegate
extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            print("❌ [AppDelegate] No FCM token received")
            return
        }
        
        print("✅ [AppDelegate] FCM registration token updated: \(token)")
        handleNewFCMToken(token)
    }
    
    // Note: didReceiveMessage is not a standard Firebase Messaging delegate method
    // Data messages are handled in didReceiveRemoteNotification when the app is in foreground
}
