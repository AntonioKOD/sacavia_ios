//
//  SacaviaAppApp.swift
//  SacaviaApp
//
//  Created by Antonio Kodheli on 7/16/25.
//

import SwiftUI
import UserNotifications
import Firebase
import FirebaseCore
import FirebaseMessaging

@main
struct SacaviaAppApp: App {
    @StateObject var authManager = AuthManager.shared
    @StateObject var pushNotificationManager = PushNotificationManager.shared
    @StateObject var feedManager = FeedManager()
    
    // Add AppDelegate for push notification handling
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(authManager)
                .environmentObject(pushNotificationManager)
                .environmentObject(feedManager)
                .preferredColorScheme(.light) // Force light mode
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .launchScreenAware() // Ensures proper scaling behavior
                .deviceSpecificContent() // Device-specific optimizations
                .onAppear {
                    // Log API configuration and app info
                    logAPIConfiguration() // This will show the current API URL being used
                    logAppInfo() // This will show app version and bundle info
                    
                    // Check entitlements status
//                    pushNotificationManager.checkEntitlementsStatus()
                    
                    // Request notification permission when app launches
                    print("📱 [SacaviaAppApp] App launched, requesting notification permission")
                    pushNotificationManager.requestNotificationPermission()
                    
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

// MARK: - Helper Functions
extension SacaviaAppApp {
    private func logAppInfo() {
        // Log app information for debugging
        print("📱 [SacaviaAppApp] App Information:")
        print("📱 [SacaviaAppApp] - Environment: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? "Unknown")")
        print("📱 [SacaviaAppApp] - Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        print("📱 [SacaviaAppApp] - Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "Unknown")")
        print("📱 [SacaviaAppApp] - Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] ?? "Unknown")")
    }
}
