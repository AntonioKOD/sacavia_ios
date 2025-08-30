import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var pushNotificationManager: PushNotificationManager
    @State private var showingNotificationTest = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // User Section
                Section("Account") {
                    if let user = authManager.user {
                        HStack {
                            AsyncImage(url: URL(string: user.profileImage?.url ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.headline)
                                if let email = user.email {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Notifications Section
                Section("Notifications") {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.blue)
                        Text("Notification Status")
                        Spacer()
                        Text(notificationStatusText)
                            .foregroundColor(notificationStatusColor)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        showingNotificationTest = true
                    }) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.blue)
                            Text("Test Notifications")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    if pushNotificationManager.permissionStatus == .denied {
                        Button(action: {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                    .foregroundColor(.orange)
                                Text("Open Settings")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // App Section
                Section("App") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.blue)
                        Text("Environment")
                        Spacer()
                        Text(environmentText)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Support Section
                Section("Support") {
                    Button(action: {
                        // Open support URL
                        if let url = URL(string: "https://sacavia.com/support") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("Help & Support")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        // Open privacy policy
                        if let url = URL(string: "https://sacavia.com/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.blue)
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        // Open terms of service
                        if let url = URL(string: "https://sacavia.com/terms") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                
                // Account Actions Section
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingNotificationTest) {
                NotificationTestView()
                    .environmentObject(pushNotificationManager)
            }
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private var notificationStatusText: String {
        switch pushNotificationManager.permissionStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Disabled"
        case .notDetermined:
            return "Not Set"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var notificationStatusColor: Color {
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
    
    private var environmentText: String {
        #if DEBUG
        return "Development"
        #else
        return "Production"
        #endif
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
        .environmentObject(PushNotificationManager.shared)
}
