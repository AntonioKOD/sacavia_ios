import SwiftUI

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var sharingPreferences = SharingPreferences()
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Control who can share locations with you and tag you in posts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Privacy Overview")
                }
                
                Section {
                    Toggle("Allow location shares", isOn: $sharingPreferences.allowLocationShares)
                        .onChange(of: sharingPreferences.allowLocationShares) { _, newValue in
                            updateSharingPreference("allowLocationShares", value: newValue)
                        }
                    
                    Toggle("Allow tagging in posts", isOn: $sharingPreferences.allowTagging)
                        .onChange(of: sharingPreferences.allowTagging) { _, newValue in
                            updateSharingPreference("allowTagging", value: newValue)
                        }
                } header: {
                    Text("General Settings")
                } footer: {
                    Text("When disabled, others won't be able to share locations with you or tag you in posts and reviews.")
                }
                
                if sharingPreferences.allowLocationShares {
                    Section {
                        Toggle("Share with everyone", isOn: $sharingPreferences.shareWithEveryone)
                            .onChange(of: sharingPreferences.shareWithEveryone) { _, newValue in
                                updateSharingPreference("shareWithEveryone", value: newValue)
                            }
                        
                        Toggle("Share with friends only", isOn: $sharingPreferences.shareWithFriends)
                            .onChange(of: sharingPreferences.shareWithFriends) { _, newValue in
                                updateSharingPreference("shareWithFriends", value: newValue)
                            }
                    } header: {
                        Text("Location Sharing")
                    } footer: {
                        Text("Control who can share locations with you. Friends only is recommended for privacy.")
                    }
                }
                
                if sharingPreferences.allowTagging {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tagging Notification Settings")
                                .font(.headline)
                            
                            Toggle("Notify when tagged in posts", isOn: $sharingPreferences.notifyOnTag)
                                .onChange(of: sharingPreferences.notifyOnTag) { _, newValue in
                                    updateSharingPreference("notifyOnTag", value: newValue)
                                }
                            
                            Toggle("Notify when tagged in reviews", isOn: $sharingPreferences.notifyOnReviewTag)
                                .onChange(of: sharingPreferences.notifyOnReviewTag) { _, newValue in
                                    updateSharingPreference("notifyOnReviewTag", value: newValue)
                                }
                        }
                    } header: {
                        Text("Tagging Notifications")
                    } footer: {
                        Text("Choose which types of tags you want to be notified about.")
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Blocked Users")
                            .font(.headline)
                        
                        Text("Manage users you've blocked from sharing with you or tagging you")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("View Blocked Users") {
                            // TODO: Navigate to blocked users view
                        }
                        .foregroundColor(.blue)
                    }
                } header: {
                    Text("Blocking")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data & Privacy")
                            .font(.headline)
                        
                        Text("Your sharing and tagging data is stored securely and can be deleted at any time.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Delete All Sharing Data") {
                            // TODO: Show confirmation alert
                        }
                        .foregroundColor(.red)
                    }
                } header: {
                    Text("Data Management")
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadSharingPreferences()
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") { }
            } message: {
                Text("Your privacy settings have been updated.")
            }
            .alert("Error", isPresented: .constant(!errorMessage.isEmpty)) {
                Button("OK") {
                    errorMessage = ""
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loadSharingPreferences() {
        // TODO: Implement API call to fetch user's sharing preferences
        // For now, using default values
        sharingPreferences = SharingPreferences()
    }
    
    private func updateSharingPreference(_ key: String, value: Bool) {
        isLoading = true
        
        // TODO: Implement API call to update sharing preferences
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            self.showSuccess = true
        }
    }
}

// MARK: - Sharing Preferences Model
struct SharingPreferences {
    var allowLocationShares: Bool = true
    var allowTagging: Bool = true
    var shareWithEveryone: Bool = false
    var shareWithFriends: Bool = true
    var notifyOnTag: Bool = true
    var notifyOnReviewTag: Bool = true
}

// MARK: - Blocked Users View
struct BlockedUsersView: View {
    @State private var blockedUsers: [BlockedUser] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading blocked users...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if blockedUsers.isEmpty {
                    EmptyBlockedUsersView()
                } else {
                    List {
                        ForEach(blockedUsers) { user in
                            BlockedUserRowView(user: user) {
                                unblockUser(user)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Blocked Users")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadBlockedUsers()
            }
        }
    }
    
    private func loadBlockedUsers() {
        isLoading = true
        // TODO: Implement API call to fetch blocked users
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.blockedUsers = mockBlockedUsers
            self.isLoading = false
        }
    }
    
    private func unblockUser(_ user: BlockedUser) {
        // TODO: Implement API call to unblock user
        blockedUsers.removeAll { $0.id == user.id }
    }
}

// MARK: - Blocked User Row View
struct BlockedUserRowView: View {
    let user: BlockedUser
    let onUnblock: () -> Void
    
    @State private var showingUnblockAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user.profileImage?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(String(user.name.prefix(1)).uppercased())
                            .font(.headline)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("@\(user.username ?? "unknown")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Blocked \(user.blockedAt)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Unblock") {
                showingUnblockAlert = true
            }
            .foregroundColor(.blue)
            .alert("Unblock User", isPresented: $showingUnblockAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Unblock", role: .destructive) {
                    onUnblock()
                }
            } message: {
                Text("Are you sure you want to unblock \(user.name)? They will be able to share locations with you and tag you again.")
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Empty Blocked Users View
struct EmptyBlockedUsersView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("No blocked users")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("You haven't blocked anyone yet. Blocked users won't be able to share locations with you or tag you.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Data Models
// BlockedUser is already defined in SharedModels.swift

// MARK: - Mock Data
private let mockBlockedUsers: [BlockedUser] = [
    BlockedUser(
        id: "1",
        name: "Spam User",
        username: "spamuser",
        email: "spam@example.com",
        profileImage: nil,
        bio: nil,
        blockedAt: "2024-01-15T10:30:00Z",
        reason: "Spam content"
    )
]

#Preview {
    PrivacySettingsView()
}
