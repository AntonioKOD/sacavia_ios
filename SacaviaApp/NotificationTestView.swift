import SwiftUI
import UserNotifications

struct NotificationTestView: View {
    @EnvironmentObject var pushNotificationManager: PushNotificationManager
    @State private var testResults: [String] = []
    @State private var isTesting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Notification Testing")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Test and verify notification functionality")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Status Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Current Status")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            StatusRow(
                                title: "Permission Status",
                                value: permissionStatusText,
                                color: permissionStatusColor
                            )
                            
                            StatusRow(
                                title: "Device Token",
                                value: pushNotificationManager.deviceToken ?? "Not available",
                                color: pushNotificationManager.deviceToken != nil ? .green : .red
                            )
                            
                            StatusRow(
                                title: "Registration Status",
                                value: pushNotificationManager.isRegistered ? "Registered" : "Not Registered",
                                color: pushNotificationManager.isRegistered ? .green : .red
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    // Test Buttons
                    VStack(spacing: 15) {
                        Text("Test Functions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            TestButton(
                                title: "Test Local Notification",
                                subtitle: "Send a test local notification",
                                icon: "bell",
                                action: testLocalNotification
                            )
                            
                            TestButton(
                                title: "Test Server Connection",
                                subtitle: "Check connection to server",
                                icon: "network",
                                action: testServerConnection
                            )
                            
                            TestButton(
                                title: "Test Server Notification",
                                subtitle: "Send test notification from server",
                                icon: "server.rack",
                                action: testServerNotification
                            )
                            
                            TestButton(
                                title: "Check Registration Status",
                                subtitle: "Verify device registration",
                                icon: "checkmark.shield",
                                action: checkRegistrationStatus
                            )
                            
                            TestButton(
                                title: "Force Re-register Device",
                                subtitle: "Re-register device token",
                                icon: "arrow.clockwise",
                                action: forceReregisterDevice
                            )
                            
                            TestButton(
                                title: "Check Entitlements",
                                subtitle: "Verify push notification setup",
                                icon: "key",
                                action: checkEntitlements
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Test Results
                    if !testResults.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Test Results")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(testResults, id: \.self) { result in
                                    HStack {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundColor(.blue)
                                        Text(result)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Clear Results Button
                    if !testResults.isEmpty {
                        Button("Clear Results") {
                            testResults.removeAll()
                        }
                        .foregroundColor(.red)
                        .padding()
                    }
                }
            }
            .navigationTitle("Notification Test")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Test Result", isPresented: $showingAlert) {
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
    
    private func testLocalNotification() {
        addResult("Testing local notification...")
        pushNotificationManager.sendTestNotification()
        addResult("✅ Local notification test completed")
        showAlert("Local notification test completed. Check if you received the notification.")
    }
    
    private func testServerConnection() {
        addResult("Testing server connection...")
        isTesting = true
        
        pushNotificationManager.testServerConnection { success, message in
            DispatchQueue.main.async {
                isTesting = false
                addResult(success ? "✅ Server connection successful" : "❌ Server connection failed: \(message)")
                showAlert(message)
            }
        }
    }
    
    private func testServerNotification() {
        addResult("Testing server notification...")
        isTesting = true
        
        pushNotificationManager.sendServerTestNotification { success, message in
            DispatchQueue.main.async {
                isTesting = false
                addResult(success ? "✅ Server notification test successful" : "❌ Server notification test failed: \(message)")
                showAlert(message)
            }
        }
    }
    
    private func checkRegistrationStatus() {
        addResult("Checking registration status...")
        isTesting = true
        
        pushNotificationManager.checkDeviceRegistrationStatus { success, message in
            DispatchQueue.main.async {
                isTesting = false
                addResult(success ? "✅ Device is registered" : "❌ Device not registered: \(message)")
                showAlert(message)
            }
        }
    }
    
    private func forceReregisterDevice() {
        addResult("Force re-registering device...")
        pushNotificationManager.forceReregisterDevice()
        addResult("✅ Device re-registration initiated")
        showAlert("Device re-registration initiated. Check the console for details.")
    }
    
    private func checkEntitlements() {
        addResult("Checking entitlements...")
        pushNotificationManager.checkEntitlementsStatus()
        addResult("✅ Entitlements check completed - check console for details")
        showAlert("Entitlements check completed. Check the console for detailed information.")
    }
    
    private func addResult(_ result: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        testResults.append("[\(timestamp)] \(result)")
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

struct StatusRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(color)
                .fontWeight(.medium)
        }
    }
}

struct TestButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NotificationTestView()
        .environmentObject(PushNotificationManager.shared)
}
