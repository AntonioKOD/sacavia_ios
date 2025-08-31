import Foundation
import UserNotifications
import UIKit

class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()
    
    @Published var isRegistered = false
    @Published var deviceToken: String?
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkNotificationPermission()
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionStatus = settings.authorizationStatus
                print("📱 [PushNotificationManager] Notification permission status: \(settings.authorizationStatus.rawValue)")
                
                switch settings.authorizationStatus {
                case .authorized:
                    print("📱 [PushNotificationManager] Notifications are authorized")
                    self.isRegistered = true
                case .denied:
                    print("📱 [PushNotificationManager] Notifications are denied")
                    self.isRegistered = false
                case .notDetermined:
                    print("📱 [PushNotificationManager] Notification permission not determined")
                    self.isRegistered = false
                case .provisional:
                    print("📱 [PushNotificationManager] Notifications are provisional")
                    self.isRegistered = true
                case .ephemeral:
                    print("📱 [PushNotificationManager] Notifications are ephemeral")
                    self.isRegistered = true
                @unknown default:
                    print("📱 [PushNotificationManager] Unknown notification permission status")
                    self.isRegistered = false
                }
            }
        }
    }
    
    func requestPermission() {
        print("📱 [PushNotificationManager] Requesting notification permission")
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("📱 [PushNotificationManager] Notification permission granted")
                    self.isRegistered = true
                    self.registerForRemoteNotifications()
                    
                    // Schedule a welcome notification
                    self.scheduleLocalNotification(
                        title: "🎉 Notifications Enabled!",
                        body: "You'll now receive updates about new locations, events, and community activities.",
                        timeInterval: 2,
                        identifier: "permission_granted"
                    )
                    
                    
                } else {
                    print("📱 [PushNotificationManager] Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                    self.isRegistered = false
                    
                    // Schedule a reminder notification
                    self.scheduleLocalNotification(
                        title: "📱 Enable Notifications",
                        body: "To stay updated with new locations and events, enable notifications in Settings > Notifications > Sacavia",
                        timeInterval: 3,
                        identifier: "permission_denied_reminder"
                    )
                }
                self.checkNotificationPermission()
            }
        }
    }
    
    func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            print("📱 [PushNotificationManager] Registering for remote notifications")
            
//            // Check if we have push notification entitlements
//            if Bundle.main.object(forInfoDictionaryKey: "aps-environment") == nil {
//                print("📱 [PushNotificationManager] ❌ No push notification entitlements found. Running in local-only mode.")
//                print("📱 [PushNotificationManager] To enable push notifications:")
//                print("📱 [PushNotificationManager] 1. Add 'Push Notifications' capability in Xcode")
//                print("📱 [PushNotificationManager] 2. Configure App ID in Apple Developer Portal")
//                print("📱 [PushNotificationManager] 3. Add APN certificates to server")
//                
//                // Set up for local notifications only
//                self.isRegistered = true
//                self.permissionStatus = .authorized
//                
//                // Schedule a local notification to inform the user
//                self.scheduleLocalNotification(
//                    title: "📱 Development Mode",
//                    body: "Push notifications are disabled. Local notifications are working!",
//                    timeInterval: 2,
//                    identifier: "development_mode_info"
//                )
//                return
//            } else {
//                print("📱 [PushNotificationManager] ✅ Push notification entitlements found!")
//                print("📱 [PushNotificationManager] aps-environment: \(Bundle.main.object(forInfoDictionaryKey: "aps-environment") ?? "nil")")
//            }
            
            print("📱 [PushNotificationManager] Calling UIApplication.shared.registerForRemoteNotifications()")
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func unregisterForRemoteNotifications() {
        DispatchQueue.main.async {
            print("📱 [PushNotificationManager] Unregistering from remote notifications")
            UIApplication.shared.unregisterForRemoteNotifications()
        }
    }
    
    func sendDeviceTokenToServer(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString
        
        print("📱 [PushNotificationManager] Device token: \(tokenString)")
        
        // Send token to your backend
        sendTokenToBackend(tokenString)
    }
    
    private func sendTokenToBackend(_ token: String) {
        let urlString = "\(baseAPIURL)/api/mobile/notifications/register-device"
        print("📱 [PushNotificationManager] Device registration URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("📱 [PushNotificationManager] Invalid URL for device registration")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let authToken = AuthManager.shared.token {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            print("📱 [PushNotificationManager] Using auth token for device registration")
        } else {
            print("📱 [PushNotificationManager] No auth token available for device registration")
            return
        }
        
        let body = [
            "deviceToken": token,
            "platform": "ios",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("📱 [PushNotificationManager] Device registration request body: \(body)")
        } catch {
            print("📱 [PushNotificationManager] Error creating device registration request body: \(error)")
            return
        }
        
        print("📱 [PushNotificationManager] Sending device token to server...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("📱 [PushNotificationManager] Error sending device token: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 [PushNotificationManager] Device registration response status: \(httpResponse.statusCode)")
                
                if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        print("📱 [PushNotificationManager] Device registration response: \(json ?? [:])")
                    } catch {
                        print("📱 [PushNotificationManager] Error parsing device registration response: \(error)")
                    }
                }
                
                if httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        self.isRegistered = true
                    }
                    print("📱 [PushNotificationManager] Device token successfully registered with server")
                } else {
                    print("📱 [PushNotificationManager] Server returned error: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    // Track recent notifications to prevent duplicates
    private var recentNotificationIds = Set<String>()
    private let maxRecentNotifications = 100
    
    func scheduleLocalNotification(title: String, body: String, timeInterval: TimeInterval = 5, identifier: String? = nil) {
        // Create a unique identifier for this notification
        let notificationId = identifier ?? "\(title)_\(body)_\(Date().timeIntervalSince1970)"
        
        // Check if we've recently shown this notification
        if recentNotificationIds.contains(notificationId) {
            print("📱 [PushNotificationManager] Skipping duplicate notification: \(title)")
            return
        }
        
        // Add to recent notifications
        recentNotificationIds.insert(notificationId)
        
        // Limit the size of recent notifications set
        if recentNotificationIds.count > maxRecentNotifications {
            recentNotificationIds.removeAll()
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["notificationId": notificationId]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("📱 [PushNotificationManager] Error scheduling notification: \(error)")
            } else {
                print("📱 [PushNotificationManager] Scheduled notification: \(title)")
            }
        }
    }
    
    // Test notification function
    func sendTestNotification() {
        print("📱 [PushNotificationManager] Sending test notification")
        scheduleLocalNotification(
            title: "🧪 Test Notification",
            body: "This is a test notification to verify the notification system is working properly.",
            timeInterval: 2,
            identifier: "test_notification"
        )
    }
    
    // Force device re-registration
    func forceReregisterDevice() {
        print("📱 [PushNotificationManager] Force re-registering device")
        if let deviceToken = self.deviceToken {
            print("📱 [PushNotificationManager] Re-registering device token: \(deviceToken)")
            sendTokenToBackend(deviceToken)
        } else {
            print("📱 [PushNotificationManager] No device token available for re-registration")
            // Try to register for remote notifications again
            registerForRemoteNotifications()
        }
    }
    
    // Check device registration status
    func checkDeviceRegistrationStatus(completion: @escaping (Bool, String) -> Void) {
        print("📱 [PushNotificationManager] Checking device registration status")
        
        let urlString = "\(baseAPIURL)/api/mobile/notifications/check-registration"
        print("📱 [PushNotificationManager] Check registration URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add auth token if available
        if let authToken = AuthManager.shared.token {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        } else {
            completion(false, "No authentication token available")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completion(true, "Device is registered")
                    } else {
                        completion(false, "Device not registered (Status: \(httpResponse.statusCode))")
                    }
                } else {
                    completion(false, "Invalid response")
                }
            }
        }.resume()
    }
    
    // Server test notification function
    func sendServerTestNotification(completion: @escaping (Bool, String) -> Void) {
        print("📱 [PushNotificationManager] Sending server test notification")
        
        let urlString = "\(baseAPIURL)/api/mobile/notifications/test"
        print("📱 [PushNotificationManager] Server test URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("📱 [PushNotificationManager] Invalid URL for server test notification")
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let authToken = AuthManager.shared.token {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            print("📱 [PushNotificationManager] Using auth token for server test")
        } else {
            print("📱 [PushNotificationManager] No auth token available for server test")
            completion(false, "No authentication token available")
            return
        }
        
        let testData: [String: Any] = [
            "title": "🧪 Server Test Notification",
            "body": "This is a test push notification sent from the server!",
            "data": [
                "type": "test_notification",
                "timestamp": Date().timeIntervalSince1970
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testData)
            print("📱 [PushNotificationManager] Server test request body: \(testData)")
        } catch {
            print("📱 [PushNotificationManager] Error creating server test request body: \(error)")
            completion(false, "Error creating request: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("📱 [PushNotificationManager] Server test network error: \(error)")
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📱 [PushNotificationManager] Server test response status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        if let data = data {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                print("📱 [PushNotificationManager] Server test response: \(json ?? [:])")
                                completion(true, "Server test notification sent successfully!")
                            } catch {
                                print("📱 [PushNotificationManager] Error parsing server test response: \(error)")
                                completion(true, "Server test notification sent! (Response parsing failed)")
                            }
                        } else {
                            completion(true, "Server test notification sent successfully!")
                        }
                    } else {
                        var errorMessage = "Server returned error: \(httpResponse.statusCode)"
                        if let data = data {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let details = json?["details"] as? String {
                                    errorMessage = details
                                } else if let error = json?["error"] as? String {
                                    errorMessage = error
                                }
                            } catch {
                                print("📱 [PushNotificationManager] Error parsing error response: \(error)")
                            }
                        }
                        print("📱 [PushNotificationManager] Server test failed: \(errorMessage)")
                        completion(false, errorMessage)
                    }
                } else {
                    print("📱 [PushNotificationManager] Server test invalid response")
                    completion(false, "Invalid server response")
                }
            }
        }.resume()
    }
    
    // Function to send different types of notifications
    func sendLocationNotification(locationName: String, locationId: String) {
        scheduleLocalNotification(
            title: "📍 New Location Added",
            body: "A new location '\(locationName)' has been added to your area!",
            timeInterval: 1,
            identifier: "location_\(locationId)"
        )
    }
    
    func sendEventNotification(eventName: String, eventId: String) {
        scheduleLocalNotification(
            title: "🎉 New Event",
            body: "A new event '\(eventName)' is happening soon!",
            timeInterval: 1,
            identifier: "event_\(eventId)"
        )
    }
    
    func sendFriendActivityNotification(friendName: String, activity: String) {
        scheduleLocalNotification(
            title: "👥 Friend Activity",
            body: "\(friendName) \(activity)",
            timeInterval: 1,
            identifier: "friend_activity_\(Date().timeIntervalSince1970)"
        )
    }
    func sendFCMTokenToServer(_ token: String) {
            print("📱 [PushNotificationManager] Sending FCM token to server: \(token)")
            // TODO: replace with your API call to register token
            // Example:
            // APIService.shared.registerPushToken(token: token) { result in
            //     switch result {
            //     case .success: print("📱 [PushNotificationManager] Token registered successfully")
            //     case .failure(let error): print("📱 [PushNotificationManager] Failed to register token: \(error)")
            //     }
            // }
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
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        print("📱 [PushNotificationManager] Did receive notification response: \(userInfo)")
        handleNotificationTap(userInfo)
        completionHandler()
    }
    
    private func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
        // Handle different notification types
        if let type = userInfo["type"] as? String {
            switch type {
            case "new_location":
                if let locationId = userInfo["locationId"] as? String {
                    // Navigate to location detail
                    print("📱 [PushNotificationManager] Navigate to location: \(locationId)")
                }
            case "new_review":
                if let locationId = userInfo["locationId"] as? String {
                    // Navigate to location reviews
                    print("📱 [PushNotificationManager] Navigate to location reviews: \(locationId)")
                }
            case "friend_activity":
                if let userId = userInfo["userId"] as? String {
                    // Navigate to friend profile
                    print("📱 [PushNotificationManager] Navigate to friend profile: \(userId)")
                }
            default:
                print("📱 [PushNotificationManager] Unknown notification type: \(type)")
            }
        }
    }
} 
