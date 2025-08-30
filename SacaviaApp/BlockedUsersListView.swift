import SwiftUI

struct BlockedUsersListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var feedManager: FeedManager
    @State private var blockedUsers: [BlockedUser] = []
    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingUnblockConfirmation = false
    @State private var selectedUser: BlockedUser?
    @State private var isUnblocking = false
    @State private var showingUnblockSuccess = false
    @State private var unblockedUserName = ""
    @State private var searchText = ""
    
    // Computed property for filtered users
    private var filteredBlockedUsers: [BlockedUser] {
        if searchText.isEmpty {
            return blockedUsers
        } else {
            return blockedUsers.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                (user.username?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                if !blockedUsers.isEmpty {
                    SearchBar(text: $searchText, placeholder: "Search blocked users...")
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                Group {
                    if isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading blocked users...")
                                .foregroundColor(.secondary)
                                .padding(.top)
                        }
                    } else if blockedUsers.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "person.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("No Blocked Users")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("You haven't blocked any users yet.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else if filteredBlockedUsers.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("No Results")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("No blocked users match your search.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else {
                        List(filteredBlockedUsers) { user in
                            BlockedUserRow(
                                user: user,
                                onUnblock: {
                                    selectedUser = user
                                    showingUnblockConfirmation = true
                                },
                                isUnblocking: isUnblocking,
                                selectedUserId: selectedUser?.id
                            )
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Blocked Users")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await loadBlockedUsers()
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadBlockedUsers()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserBlocked"))) { _ in
            Task {
                print("🔍 [BlockedUsersListView] Received UserBlocked notification, refreshing list...")
                await loadBlockedUsers()
            }
        }
        .refreshable {
            await loadBlockedUsers()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserBlocked"))) { _ in
            Task {
                await loadBlockedUsers()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("User Unblocked", isPresented: $showingUnblockSuccess) {
            Button("OK") { }
        } message: {
            Text("\(unblockedUserName) has been unblocked successfully.")
        }
        .confirmationDialog("Unblock User", isPresented: $showingUnblockConfirmation) {
            if let user = selectedUser {
                Button("Unblock \(user.name)", role: .destructive) {
                    Task {
                        await unblockUser(user)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
        } message: {
            if let user = selectedUser {
                Text("Are you sure you want to unblock \(user.name)? They will be able to see your content and interact with you again.")
            }
        }
    }
    
    private func loadBlockedUsers() async {
        print("🔍 [BlockedUsersListView] Loading blocked users...")
        isLoading = true
        
        do {
            let users = try await APIService.shared.getBlockedUsersDetails()
            print("🔍 [BlockedUsersListView] Received \(users.count) blocked users from API")
            for user in users {
                print("🔍 [BlockedUsersListView] Blocked user: \(user.name) (ID: \(user.id))")
            }
            
            await MainActor.run {
                self.blockedUsers = users
                self.isLoading = false
                print("🔍 [BlockedUsersListView] Updated UI with \(users.count) blocked users")
            }
        } catch {
            print("🔍 [BlockedUsersListView] Error loading blocked users: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showingError = true
                self.isLoading = false
            }
        }
    }
    
    private func unblockUser(_ user: BlockedUser) async {
        isUnblocking = true
        
        do {
            let success = try await APIService.shared.unblockUser(targetUserId: user.id)
            
            if success {
                await MainActor.run {
                    // Remove user from the list
                    blockedUsers.removeAll { $0.id == user.id }
                    // Remove user from blocked list in FeedManager
                    feedManager.removeBlockedUser(user.id)
                    // Show success message
                    unblockedUserName = user.name
                    showingUnblockSuccess = true
                }
            } else {
                await MainActor.run {
                    errorMessage = "Failed to unblock user. Please try again."
                    showingError = true
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        
        isUnblocking = false
    }
}

struct BlockedUserRow: View {
    let user: BlockedUser
    let onUnblock: () -> Void
    let isUnblocking: Bool
    let selectedUserId: String?
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image
            if let profileImage = user.profileImage {
                AsyncImage(url: URL(string: profileImage.url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 44))
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                if let username = user.username {
                    Text("@\(username)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    if let reason = user.reason {
                        Text("• \(reason)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("• \(formatDate(user.blockedAt))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Unblock Button
            Button(action: onUnblock) {
                HStack(spacing: 4) {
                    if isUnblocking && selectedUserId == user.id {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.blue)
                    } else {
                        Text("Unblock")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
            }
            .disabled(isUnblocking && selectedUserId == user.id)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            let now = Date()
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: date, to: now)
            
            if let days = components.day {
                if days == 0 {
                    return "Today"
                } else if days == 1 {
                    return "Yesterday"
                } else if days < 7 {
                    return "\(days) days ago"
                } else if days < 30 {
                    let weeks = days / 7
                    return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
                } else {
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .none
                    return formatter.string(from: date)
                }
            }
        }
        
        return dateString
    }
}

// MARK: - Search Bar Component
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    BlockedUsersListView()
}
