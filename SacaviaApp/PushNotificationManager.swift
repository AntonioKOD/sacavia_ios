import Foundation
import UserNotifications
import UIKit

class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()
    
    @Published var isRegistered = false
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String?
    @Published var isConnected = false
    
    private var baseAPIURL: String {
        return isDevelopment ? "http://localhost:3000" : "https://sacavia.com"
    }
    
    private override init() {
        super.init()
        setupNotificationCenter()
    }
    
    // MARK: - Setup
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
        setupNotificationCategories()
        checkNotificationPermission()
    }
    
    // MARK: - Notification Categories
    private func setupNotificationCategories() {
        // Location Share Category with action buttons
        let viewLocationAction = UNNotificationAction(
            identifier: "VIEW_LOCATION_ACTION",
            title: "View Location",
            options: [.foreground]
        )
        
        let replyAction = UNNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: [.destructive]
        )
        
        let locationShareCategory = UNNotificationCategory(
            identifier: "LOCATION_SHARE_CATEGORY",
            actions: [viewLocationAction, replyAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([locationShareCategory])
        print("📱 [PushNotificationManager] Registered notification categories")
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionStatus = settings.authorizationStatus
                self.isRegistered = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestNotificationPermission() {
        print("📱 [PushNotificationManager] Requesting notification permission...")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .provisional]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ [PushNotificationManager] Notification permission granted")
                    self.permissionStatus = .authorized
                    self.isRegistered = true
                    
                    // Register for remote notifications after permission is granted
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                        print("📱 [PushNotificationManager] Registered for remote notifications")
                    }
                } else {
                    print("❌ [PushNotificationManager] Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                    self.permissionStatus = .denied
                    self.isRegistered = false
                }
                
                // Log current permission status
                self.logCurrentPermissionStatus()
            }
        }
    }
    
    private func logCurrentPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("📱 [PushNotificationManager] Current permission status:")
                print("📱 [PushNotificationManager] - Authorization: \(settings.authorizationStatus.rawValue)")
                print("📱 [PushNotificationManager] - Alert setting: \(settings.alertSetting.rawValue)")
                print("📱 [PushNotificationManager] - Badge setting: \(settings.badgeSetting.rawValue)")
                print("📱 [PushNotificationManager] - Sound setting: \(settings.soundSetting.rawValue)")
                print("📱 [PushNotificationManager] - Lock screen setting: \(settings.lockScreenSetting.rawValue)")
                print("📱 [PushNotificationManager] - Notification center setting: \(settings.notificationCenterSetting.rawValue)")
            }
        }
    }
    
    // MARK: - Token Management
    func sendFCMTokenToServer(_ token: String) {
        print("📱 [PushNotificationManager] Sending FCM token to server: \(token)")
        
        // Get current user ID if available
        let userId = getCurrentUserId()
        
        // Register FCM token with server via TokenAPI
        Task {
            let deviceInfo = TokenAPI.getCurrentDeviceInfo()
            let result = await TokenAPI.shared.registerDeviceToken(
                deviceToken: token,
                userId: userId,
                platform: "ios",
                deviceInfo: deviceInfo
            )
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ [PushNotificationManager] FCM token registered successfully: \(response.message)")
                    self.deviceToken = token
                    
                    // Schedule success notification
                    self.scheduleLocalNotification(
                        title: "✅ Token Registered",
                        body: "Your device is now registered for push notifications",
                        timeInterval: 2,
                        identifier: "token_registered_success"
                    )
                case .failure(let error):
                    print("❌ [PushNotificationManager] Failed to register FCM token: \(error.localizedDescription)")
                    
                    // Schedule error notification
                    self.scheduleLocalNotification(
                        title: "❌ Registration Failed",
                        body: "Failed to register device: \(error.localizedDescription)",
                        timeInterval: 2,
                        identifier: "token_registered_failed"
                    )
                }
            }
        }
    }
    
    // MARK: - Token Management via TokenAPI
    func registerDeviceToken(_ token: String, userId: String? = nil) async -> Bool {
        print("📱 [PushNotificationManager] Registering device token: \(token)")
        
        let deviceInfo = TokenAPI.getCurrentDeviceInfo()
        let result = await TokenAPI.shared.registerDeviceToken(
            deviceToken: token,
            userId: userId,
            platform: "ios",
            deviceInfo: deviceInfo
        )
        
        DispatchQueue.main.async {
            switch result {
            case .success(let response):
                print("✅ [PushNotificationManager] Device token registered: \(response.message)")
                self.deviceToken = token
                self.isRegistered = true
            case .failure(let error):
                print("❌ [PushNotificationManager] Failed to register device token: \(error.localizedDescription)")
                self.isRegistered = false
            }
        }
        
        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    func deactivateDeviceToken(_ token: String, userId: String? = nil) async -> Bool {
        print("📱 [PushNotificationManager] Deactivating device token: \(token)")
        
        let result = await TokenAPI.shared.deactivateDeviceToken(
            deviceToken: token,
            userId: userId
        )
        
        DispatchQueue.main.async {
            switch result {
            case .success(let response):
                print("✅ [PushNotificationManager] Device token deactivated: \(response.message)")
                if self.deviceToken == token {
                    self.deviceToken = nil
                    self.isRegistered = false
                }
            case .failure(let error):
                print("❌ [PushNotificationManager] Failed to deactivate device token: \(error.localizedDescription)")
            }
        }
        
        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    func subscribeToTopics(_ topics: [String], deviceToken: String? = nil, userId: String? = nil) async -> Bool {
        let token = deviceToken ?? self.deviceToken ?? ""
        guard !token.isEmpty else {
            print("❌ [PushNotificationManager] No device token available for topic subscription")
            return false
        }
        
        print("📱 [PushNotificationManager] Subscribing to topics: \(topics)")
        
        let result = await TokenAPI.shared.subscribeToTopics(
            deviceToken: token,
            topics: topics,
            userId: userId
        )
        
        DispatchQueue.main.async {
            switch result {
            case .success(let response):
                print("✅ [PushNotificationManager] Subscribed to topics: \(response.message)")
            case .failure(let error):
                print("❌ [PushNotificationManager] Failed to subscribe to topics: \(error.localizedDescription)")
            }
        }
        
        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    func unsubscribeFromTopics(_ topics: [String], deviceToken: String? = nil, userId: String? = nil) async -> Bool {
        let token = deviceToken ?? self.deviceToken ?? ""
        guard !token.isEmpty else {
            print("❌ [PushNotificationManager] No device token available for topic unsubscription")
            return false
        }
        
        print("📱 [PushNotificationManager] Unsubscribing from topics: \(topics)")
        
        let result = await TokenAPI.shared.unsubscribeFromTopics(
            deviceToken: token,
            topics: topics,
            userId: userId
        )
        
        DispatchQueue.main.async {
            switch result {
            case .success(let response):
                print("✅ [PushNotificationManager] Unsubscribed from topics: \(response.message)")
            case .failure(let error):
                print("❌ [PushNotificationManager] Failed to unsubscribe from topics: \(error.localizedDescription)")
            }
        }
        
        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    func getCurrentTopics(deviceToken: String? = nil, userId: String? = nil) async -> [String] {
        let token = deviceToken ?? self.deviceToken ?? ""
        guard !token.isEmpty else {
            print("❌ [PushNotificationManager] No device token available for topic retrieval")
            return []
        }
        
        print("📱 [PushNotificationManager] Getting current topics for device: \(token)")
        
        let result = await TokenAPI.shared.getCurrentTopics(
            deviceToken: token,
            userId: userId
        )
        
        switch result {
        case .success(let response):
            if let topics = response.subscribedTopics {
                print("✅ [PushNotificationManager] Retrieved \(topics.count) topics")
                return topics
            } else {
                print("📱 [PushNotificationManager] No topics found")
                return []
            }
        case .failure(let error):
            print("❌ [PushNotificationManager] Failed to get topics: \(error.localizedDescription)")
            return []
        }
    }
    
    func sendTestNotification(title: String, body: String, data: [String: String]? = nil) async -> Bool {
        guard let deviceToken = self.deviceToken else {
            print("❌ [PushNotificationManager] No device token available for test notification")
            return false
        }
        
        print("📱 [PushNotificationManager] Sending test notification to device: \(deviceToken)")
        
        let result = await TokenAPI.shared.sendNotification(
            type: "token",
            target: deviceToken,
            title: title,
            body: body,
            data: data
        )
        
        DispatchQueue.main.async {
            switch result {
            case .success(let response):
                print("✅ [PushNotificationManager] Test notification sent: \(response.message)")
            case .failure(let error):
                print("❌ [PushNotificationManager] Failed to send test notification: \(error.localizedDescription)")
            }
        }
        
        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func getCurrentUserId() -> String? {
        // Get current user ID from your authentication system
        // This should integrate with your existing AuthManager
        return AuthManager.shared.user?.id
    }

    // Test connection to server
    func testServerConnection(completion: @escaping (Bool, String) -> Void) {
        print("📱 [PushNotificationManager] Testing server connection")
        
        let urlString = "\(baseAPIURL)/api/mobile/test"
        print("📱 [PushNotificationManager] Connection test URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add auth token if available
        if let authToken = AuthManager.shared.token {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("📱 [PushNotificationManager] Connection test error: \(error)")
                    completion(false, "Connection failed: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📱 [PushNotificationManager] Connection test response status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        completion(true, "Server connection successful!")
                    } else {
                        completion(false, "Server returned status: \(httpResponse.statusCode)")
                    }
                } else {
                    completion(false, "Invalid response")
                }
            }
        }.resume()
    }
    
    // Check entitlements status
    func checkEntitlementsStatus() {
        
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        print("📱 [PushNotificationManager] Will present notification: \(notification.request.content.title)")
        print("📱 [PushNotificationManager] Notification body: \(notification.request.content.body)")
        print("📱 [PushNotificationManager] User info: \(notification.request.content.userInfo)")
        
        // Always show banner, sound, and badge for foreground notifications
        let presentationOptions: UNNotificationPresentationOptions = [.banner, .sound, .badge]
        print("📱 [PushNotificationManager] Presenting notification with options: \(presentationOptions)")
        completionHandler(presentationOptions)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        print("📱 [PushNotificationManager] Did receive notification response: \(userInfo)")
        print("📱 [PushNotificationManager] Action identifier: \(actionIdentifier)")
        
        // Handle action buttons
        switch actionIdentifier {
        case "VIEW_LOCATION_ACTION":
            if let locationId = userInfo["locationId"] as? String {
                print("📱 [PushNotificationManager] View Location action tapped for: \(locationId)")
                navigateToLocation(locationId: locationId)
            }
        case "REPLY_ACTION":
            if let locationId = userInfo["locationId"] as? String,
               let shareId = userInfo["shareId"] as? String {
                print("📱 [PushNotificationManager] Reply action tapped for location: \(locationId), share: \(shareId)")
                openLocationShareReply(locationId: locationId, shareId: shareId)
            }
        case "DISMISS_ACTION":
            print("📱 [PushNotificationManager] Dismiss action tapped")
            // Just dismiss, no action needed
        case UNNotificationDefaultActionIdentifier:
            // Default tap action
            handleNotificationTap(userInfo)
        default:
            print("📱 [PushNotificationManager] Unknown action identifier: \(actionIdentifier)")
            handleNotificationTap(userInfo)
        }
        
        completionHandler()
    }
    
    // MARK: - Action Handlers
    private func openLocationShareReply(locationId: String, shareId: String) {
        // Post notification to open location share reply interface
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenLocationShareReply"),
            object: nil,
            userInfo: [
                "locationId": locationId,
                "shareId": shareId
            ]
        )
    }
    
    private func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
        // Handle different notification types
        if let type = userInfo["type"] as? String {
            switch type {
            case "location_shared":
                if let locationId = userInfo["locationId"] as? String {
                    // Navigate to location detail
                    print("📱 [PushNotificationManager] Navigate to shared location: \(locationId)")
                    navigateToLocation(locationId: locationId)
                }
            case "location_share_reply":
                if let locationId = userInfo["locationId"] as? String {
                    // Navigate to location detail for reply
                    print("📱 [PushNotificationManager] Navigate to location for reply: \(locationId)")
                    navigateToLocation(locationId: locationId)
                }
            case "post_tagged":
                if let postId = userInfo["postId"] as? String {
                    // Navigate to post detail
                    print("📱 [PushNotificationManager] Navigate to tagged post: \(postId)")
                    navigateToPost(postId: postId)
                }
            case "review_tagged":
                if let reviewId = userInfo["reviewId"] as? String {
                    // Navigate to review detail
                    print("📱 [PushNotificationManager] Navigate to tagged review: \(reviewId)")
                    navigateToReview(reviewId: reviewId)
                }
            case "new_location":
                if let locationId = userInfo["locationId"] as? String {
                    // Navigate to location detail
                    print("📱 [PushNotificationManager] Navigate to location: \(locationId)")
                    navigateToLocation(locationId: locationId)
                }
            case "new_review":
                if let locationId = userInfo["locationId"] as? String {
                    // Navigate to location reviews
                    print("📱 [PushNotificationManager] Navigate to location reviews: \(locationId)")
                    navigateToLocation(locationId: locationId)
                }
            case "friend_activity":
                if let userId = userInfo["userId"] as? String {
                    // Navigate to friend profile
                    print("📱 [PushNotificationManager] Navigate to friend profile: \(userId)")
                    navigateToProfile(userId: userId)
                }
            case "event_reminder":
                if let eventId = userInfo["eventId"] as? String {
                    // Navigate to event detail
                    print("📱 [PushNotificationManager] Navigate to event: \(eventId)")
                    navigateToEvent(eventId: eventId)
                }
            default:
                print("📱 [PushNotificationManager] Unknown notification type: \(type)")
            }
        }
    }
    
    // MARK: - Navigation Helpers
    private func navigateToLocation(locationId: String) {
        // Post notification to open location detail
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToLocation"),
            object: nil,
            userInfo: ["locationId": locationId]
        )
    }
    
    private func navigateToPost(postId: String) {
        // Post notification to open post detail
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToPost"),
            object: nil,
            userInfo: ["postId": postId]
        )
    }
    
    private func navigateToReview(reviewId: String) {
        // Post notification to open review detail
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToReview"),
            object: nil,
            userInfo: ["reviewId": reviewId]
        )
    }
    
    private func navigateToProfile(userId: String) {
        // Post notification to open profile
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToProfile"),
            object: nil,
            userInfo: ["userId": userId]
        )
    }
    
    private func navigateToEvent(eventId: String) {
        // Post notification to open event
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToEvent"),
            object: nil,
            userInfo: ["eventId": eventId]
        )
    }
}

// MARK: - Local Notifications
extension PushNotificationManager {
    func scheduleLocalNotification(
        title: String,
        body: String,
        timeInterval: TimeInterval,
        identifier: String,
        userInfo: [String: Any]? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [PushNotificationManager] Failed to schedule local notification: \(error)")
            } else {
                print("✅ [PushNotificationManager] Local notification scheduled: \(identifier)")
            }
        }
    }
    
    func scheduleLocalNotification(
        title: String,
        body: String,
        date: Date,
        identifier: String,
        userInfo: [String: Any]? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [PushNotificationManager] Failed to schedule local notification: \(error)")
            } else {
                print("✅ [PushNotificationManager] Local notification scheduled: \(identifier)")
            }
        }
    }
    
    func cancelLocalNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("📱 [PushNotificationManager] Cancelled local notification: \(identifier)")
    }
    
    func cancelAllLocalNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("📱 [PushNotificationManager] Cancelled all local notifications")
    }
} 
