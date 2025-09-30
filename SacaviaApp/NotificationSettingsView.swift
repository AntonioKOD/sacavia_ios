import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var pushNotificationManager: PushNotificationManager
    @Environment(\.presentationMode) var presentationMode
    @State private var locationActivities = true
    @State private var eventRequests = true
    @State private var milestones = true
    @State private var friendActivities = true
    @State private var proximityAlerts = true
    @State private var specialOffers = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Push Notifications")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Push Notifications")
                                .font(.headline)
                            Text("Receive notifications on your device")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if pushNotificationManager.isRegistered {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Permission status
                    HStack {
                        Text("Status:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(permissionStatusText)
                            .font(.subheadline)
                            .foregroundColor(permissionStatusColor)
                    }
                    
                    if !pushNotificationManager.isRegistered {
                        Button("Enable Push Notifications") {
                            pushNotificationManager.requestNotificationPermission()
                        }
                        .foregroundColor(.blue)
                    }
                    
                    // Test notification button
                    Button("Send Test Notification") {
                        pushNotificationManager.scheduleLocalNotification(
                            title: "🧪 Test Notification",
                            body: "This is a test notification from settings",
                            timeInterval: 2,
                            identifier: "settings_test_notification"
                        )
                        alertMessage = "Test notification sent! Check if you received it."
                        showingAlert = true
                    }
                    .foregroundColor(.orange)
                    .disabled(!pushNotificationManager.isRegistered)
                    
                    // Server test notification button
                    Button("Send Server Test Notification") {
                        Task {
                            let success = await pushNotificationManager.sendTestNotification(
                                title: "🧪 Server Test",
                                body: "This is a test notification sent via the server",
                                data: ["type": "test", "source": "settings"]
                            )
                            DispatchQueue.main.async {
                                alertMessage = success ? "Server test notification sent successfully!" : "Failed to send server test notification"
                                showingAlert = true
                            }
                        }
                    }
                    .foregroundColor(.green)
                    .disabled(!pushNotificationManager.isRegistered)
                    
                    // Force re-registration button
                    Button("Force Re-register Device") {
                        if let deviceToken = pushNotificationManager.deviceToken {
                            Task {
                                let success = await pushNotificationManager.registerDeviceToken(deviceToken)
                                DispatchQueue.main.async {
                                    alertMessage = success ? "Device re-registration successful!" : "Device re-registration failed"
                                    showingAlert = true
                                }
                            }
                        } else {
                            alertMessage = "No device token available for re-registration"
                            showingAlert = true
                        }
                    }
                    .foregroundColor(.purple)
                    
                    // Check registration status button
                    Button("Check Registration Status") {
                        if let deviceToken = pushNotificationManager.deviceToken {
                            alertMessage = "Device is registered with token: \(String(deviceToken.prefix(20)))..."
                            showingAlert = true
                        } else {
                            alertMessage = "Device is not registered. No device token found."
                            showingAlert = true
                        }
                    }
                    .foregroundColor(.blue)
                    
                    // Test server connection button
                    Button("Test Server Connection") {
                        pushNotificationManager.testServerConnection { success, message in
                            DispatchQueue.main.async {
                                alertMessage = message
                                showingAlert = true
                            }
                        }
                    }
                    .foregroundColor(.teal)
                    
                    // Check entitlements button
                    Button("Check Entitlements") {
                        pushNotificationManager.checkEntitlementsStatus()
                        alertMessage = "Entitlements check completed. Check console logs for details."
                        showingAlert = true
                    }
                    .foregroundColor(.indigo)
                }
                
                Section(header: Text("Notification Types")) {
                    Toggle("Location Activities", isOn: $locationActivities)
                    Toggle("Event Requests", isOn: $eventRequests)
                    Toggle("Milestones", isOn: $milestones)
                    Toggle("Friend Activities", isOn: $friendActivities)
                    Toggle("Proximity Alerts", isOn: $proximityAlerts)
                    Toggle("Special Offers", isOn: $specialOffers)
                }
                
                Section(header: Text("Device Information")) {
                    if let deviceToken = pushNotificationManager.deviceToken {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Device Token:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(deviceToken)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(3)
                        }
                    } else {
                        Text("Device token not available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Notification Test", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var permissionStatusText: String {
        switch pushNotificationManager.permissionStatus {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Determined"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var permissionStatusColor: Color {
        switch pushNotificationManager.permissionStatus {
        case .authorized, .provisional, .ephemeral:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
}

#Preview {
    NotificationSettingsView()
        .environmentObject(PushNotificationManager.shared)
} 