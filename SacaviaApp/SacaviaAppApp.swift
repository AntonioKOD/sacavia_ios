//
//  SacaviaAppApp.swift
//  SacaviaApp
//
//  Created by Antonio Kodheli on 7/16/25.
//

import SwiftUI
import UserNotifications

@main
struct SacaviaAppApp: App {
    @StateObject var authManager = AuthManager.shared
    @StateObject var pushNotificationManager = PushNotificationManager.shared
    @StateObject var feedManager = FeedManager()
    
    // Add AppDelegate for push notification handling
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(pushNotificationManager)
                .environmentObject(feedManager)
                .preferredColorScheme(.light) // Force light mode
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .launchScreenAware() // Ensures proper scaling behavior
                .deviceSpecificContent() // Device-specific optimizations
                .onAppear {
                    // Log API configuration
                    logAPIConfiguration()
                    
                    // Check entitlements status
                    pushNotificationManager.checkEntitlementsStatus()
                    
                    // Request notification permission when app launches
                    print("📱 [SacaviaAppApp] App launched, requesting notification permission")
                    pushNotificationManager.requestPermission()
                    
                    // Schedule a test notification after 3 seconds to verify the system works
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        print("📱 [SacaviaAppApp] Scheduling test notification")
                        pushNotificationManager.scheduleLocalNotification(
                            title: "🎉 Welcome to Sacavia!",
                            body: "Your journey of guided discovery begins now. Explore authentic places and connect with your community.",
                            timeInterval: 2,
                            identifier: "welcome_notification"
                        )
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Refresh feed with interaction state sync when app becomes active
                    Task {
                        await feedManager.refreshFeedWithInteractionSync()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .userDidLogin)) { _ in
                    // Force refresh feed after successful login
                    Task {
                        await feedManager.forceRefreshAfterLogin()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .userDidLogout)) { _ in
                    // Clear feed after logout
                    feedManager.clearFeedAfterLogout()
                }
        }
    }
}

// MARK: - App Delegate for Push Notifications
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("📱 [AppDelegate] App did finish launching")
        
        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = PushNotificationManager.shared
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 [AppDelegate] ✅ Successfully registered for remote notifications")
        print("📱 [AppDelegate] Device token data length: \(deviceToken.count) bytes")
        PushNotificationManager.shared.sendDeviceTokenToServer(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("📱 [AppDelegate] ❌ Failed to register for remote notifications: \(error)")
        print("📱 [AppDelegate] Error domain: \(error._domain)")
        print("📱 [AppDelegate] Error code: \(error._code)")
        print("📱 [AppDelegate] Error description: \(error.localizedDescription)")
        
        // Check if this is the entitlements error
        if error.localizedDescription.contains("aps-environment") {
            print("📱 [AppDelegate] ❌ Push notification entitlements missing. Running in local-only mode.")
            print("📱 [AppDelegate] To fix this:")
            print("📱 [AppDelegate] 1. Add 'Push Notifications' capability in Xcode")
            print("📱 [AppDelegate] 2. Configure App ID in Apple Developer Portal")
            
            // Set up for local notifications only
            DispatchQueue.main.async {
                PushNotificationManager.shared.isRegistered = true
                PushNotificationManager.shared.permissionStatus = .authorized
            }
        } else {
            print("📱 [AppDelegate] Different error - not entitlements related")
            // Schedule a local notification to inform the user
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                PushNotificationManager.shared.scheduleLocalNotification(
                    title: "📱 Notification Setup",
                    body: "Push notifications are disabled. You can enable them in Settings > Notifications > Sacavia",
                    timeInterval: 1,
                    identifier: "notification_setup_reminder"
                )
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle push notification when app is in background
        print("📱 [AppDelegate] Received remote notification: \(userInfo)")
        
        // Process the notification
        if let aps = userInfo["aps"] as? [String: Any],
           let alert = aps["alert"] as? [String: Any],
           let title = alert["title"] as? String,
           let body = alert["body"] as? String {
            
            // Show a local notification if the app is in background
            if application.applicationState != .active {
                PushNotificationManager.shared.scheduleLocalNotification(
                    title: title,
                    body: body,
                    timeInterval: 1,
                    identifier: "remote_notification_\(Date().timeIntervalSince1970)"
                )
            }
        }
        
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        print("📱 [AppDelegate] Received local notification: \(notification.alertTitle ?? "No title")")
    }
}
