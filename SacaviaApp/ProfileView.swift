import SwiftUI
import AVKit

// MARK: - Profile View Model
class ProfileViewModel: ObservableObject {
    private let apiService = APIService()
    @Published var profile: ProfileUser?
    @Published var posts: [ProfilePost] = []
    @Published var aboutData: ProfileAboutData?
    @Published var isLoading = false
    @Published var error: String?
    @Published var isOwnProfile = false
    @Published var refreshTrigger = 0 // Force UI refresh
    
    func loadProfile(userId: String?) async {
        print("🔍 [ProfileViewModel] Starting to load profile for userId: \(userId ?? "nil")")
        
        await MainActor.run {
            isLoading = true
            error = nil
            print("🔍 [ProfileViewModel] Set loading to true and cleared error")
        }
        
        do {
            let currentUserId = AuthManager.shared.user?.id
            let targetUserId = userId ?? currentUserId
            
            print("🔍 [ProfileViewModel] Current user ID: \(currentUserId ?? "nil")")
            print("🔍 [ProfileViewModel] Target user ID: \(targetUserId ?? "nil")")
            
            // Check if this is the current user's profile
            await MainActor.run {
                isOwnProfile = (userId == nil || userId == currentUserId)
            }
            
            print("🔍 [ProfileViewModel] Is own profile: \(isOwnProfile)")
            
            // Load profile data
            print("🔍 [ProfileViewModel] About to call apiService.getUserProfile with userId: \(targetUserId ?? "nil")")
            let (profileData, recentPosts) = try await apiService.getUserProfile(userId: targetUserId)
            print("🔍 [ProfileViewModel] API call completed successfully!")
            print("🔍 [ProfileViewModel] Profile data received: \(profileData.name)")
            print("🔍 [ProfileViewModel] Profile ID: \(profileData.id)")
            print("🔍 [ProfileViewModel] Recent posts received: \(recentPosts.count)")
            
            await MainActor.run {
                print("🔍 [ProfileViewModel] Updating UI on main thread...")
                self.profile = profileData
                self.posts = recentPosts
                self.isLoading = false
                print("🔍 [ProfileViewModel] UI updated successfully!")
                print("🔍 [ProfileViewModel] Profile loaded: \(profileData.name) - Posts: \(profileData.stats?.postsCount ?? 0), Followers: \(profileData.stats?.followersCount ?? 0), Following: \(profileData.stats?.followingCount ?? 0)")
                print("🔍 [ProfileViewModel] Final state - profile: \(self.profile?.name ?? "nil"), posts: \(self.posts.count), loading: \(self.isLoading)")
            }
            
        } catch {
            print("🔍 [ProfileViewModel] ERROR loading profile: \(error)")
            print("🔍 [ProfileViewModel] Error type: \(type(of: error))")
            print("🔍 [ProfileViewModel] Error details: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
                print("🔍 [ProfileViewModel] Error set in UI: \(self.error ?? "nil")")
                print("🔍 [ProfileViewModel] Final error state - error: \(self.error ?? "nil"), loading: \(self.isLoading)")
            }
        }
    }
    
    func toggleFollow() {
        guard let userId = profile?.id else { 
            print("🔍 [ProfileViewModel] No profile ID available for toggle follow")
            return 
        }
        
        Task {
            do {
                let isCurrentlyFollowing = profile?.isFollowing ?? false
                let success: Bool
                
                print("🔍 [ProfileViewModel] Toggling follow for user \(userId), currently following: \(isCurrentlyFollowing)")
                
                // Update UI immediately for better UX
                await MainActor.run {
                    if let currentProfile = self.profile {
                        let updatedProfile = ProfileUser(
                            id: currentProfile.id,
                            name: currentProfile.name,
                            email: currentProfile.email,
                            username: currentProfile.username,
                            profileImage: currentProfile.profileImage,
                            bio: currentProfile.bio,
                            location: currentProfile.location,
                            role: currentProfile.role,
                            isCreator: currentProfile.isCreator,
                            isVerified: currentProfile.isVerified,
                            stats: currentProfile.stats,
                            isFollowing: !isCurrentlyFollowing,
                            joinedAt: currentProfile.joinedAt,
                            interests: currentProfile.interests,
                            socialLinks: currentProfile.socialLinks,
                            following: currentProfile.following,
                            followers: currentProfile.followers
                        )
                        self.profile = updatedProfile
                        print("🔍 [ProfileViewModel] UI updated immediately, new following state: \(updatedProfile.isFollowing ?? false)")
                    }
                }
                
                // Make API call
                if isCurrentlyFollowing {
                    print("🔍 [ProfileViewModel] Attempting to unfollow user \(userId)")
                    success = try await apiService.unfollowUser(userId: userId)
                } else {
                    print("🔍 [ProfileViewModel] Attempting to follow user \(userId)")
                    success = try await apiService.followUser(userId: userId)
                }
                
                print("🔍 [ProfileViewModel] API call result: \(success)")
                
                if success {
                    await MainActor.run {
                        // Update AuthManager state for real-time updates
                        AuthManager.shared.updateFollowState(targetUserId: userId, isFollowing: !isCurrentlyFollowing)
                        
                        // If this is the current user's profile, update their followers count
                        if let currentUserId = AuthManager.shared.user?.id, currentUserId == userId {
                            let delta = isCurrentlyFollowing ? -1 : 1
                            AuthManager.shared.updateFollowersCount(delta: delta)
                        }
                        
                        print("🔍 [ProfileViewModel] Real-time state updated successfully")
                    }
                } else {
                    // Revert the UI change if the API call failed
                    await MainActor.run {
                        if let currentProfile = self.profile {
                            let revertedProfile = ProfileUser(
                                id: currentProfile.id,
                                name: currentProfile.name,
                                email: currentProfile.email,
                                username: currentProfile.username,
                                profileImage: currentProfile.profileImage,
                                bio: currentProfile.bio,
                                location: currentProfile.location,
                                role: currentProfile.role,
                                isCreator: currentProfile.isCreator,
                                isVerified: currentProfile.isVerified,
                                stats: currentProfile.stats,
                                isFollowing: isCurrentlyFollowing, // Revert to original state
                                joinedAt: currentProfile.joinedAt,
                                interests: currentProfile.interests,
                                socialLinks: currentProfile.socialLinks,
                                following: currentProfile.following,
                                followers: currentProfile.followers
                            )
                            self.profile = revertedProfile
                            print("🔍 [ProfileViewModel] UI reverted due to API failure")
                        }
                    }
                }
            } catch {
                print("🔍 [ProfileViewModel] Failed to toggle follow: \(error)")
                
                // Revert the UI change if there was an error
                await MainActor.run {
                    if let currentProfile = self.profile {
                        let revertedProfile = ProfileUser(
                            id: currentProfile.id,
                            name: currentProfile.name,
                            email: currentProfile.email,
                            username: currentProfile.username,
                            profileImage: currentProfile.profileImage,
                            bio: currentProfile.bio,
                            location: currentProfile.location,
                            role: currentProfile.role,
                            isCreator: currentProfile.isCreator,
                            isVerified: currentProfile.isVerified,
                            stats: currentProfile.stats,
                            isFollowing: profile?.isFollowing ?? false, // Revert to original state
                            joinedAt: currentProfile.joinedAt,
                            interests: currentProfile.interests,
                            socialLinks: currentProfile.socialLinks,
                            following: currentProfile.following,
                            followers: currentProfile.followers
                        )
                        self.profile = revertedProfile
                        print("🔍 [ProfileViewModel] UI reverted due to error")
                    }
                    
                    self.error = "Failed to update follow status: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func logout() async {
        AuthManager.shared.logout()
    }
    
    func forceRefreshProfile(userId: String?) async {
        print("🔍 [ProfileViewModel] Force refreshing profile for userId: \(userId ?? "nil")")
        await loadProfile(userId: userId)
    }
    
    func cleanup() {
        profile = nil
        posts = []
        aboutData = nil
        error = nil
    }
}

// MARK: - Profile-specific Data Models
struct ProfileAboutData {
    let interests: [String]
    let socialLinks: [SocialLink]
    let joinedAt: String
}

// MARK: - Profile View
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var authManager = AuthManager.shared
    @EnvironmentObject var feedManager: FeedManager
    @State private var selectedTab = 0
    @State private var showingEditProfile = false
    @State private var showingLogoutAlert = false
    @State private var showingMoreMenu = false
    @State private var showingDeleteAccount = false
    @State private var showingReportContent = false
    @State private var showingBlockUser = false
    @State private var showingBlockedUsers = false
    @State private var selectedPostIndex: Int?
    @State private var showingPostsFeed = false

    @Environment(\.dismiss) private var dismiss
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    let userId: String?
    
    init(userId: String? = nil) {
        self.userId = userId
    }
    
    private var isCurrentUserProfile: Bool {
        if userId == nil {
            return true
        }
        return userId == authManager.user?.id
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .accentColor(primaryColor)
                        Text("Loading profile...")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Please wait while we load the profile data")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Profile")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry") {
                            Task {
                                await viewModel.loadProfile(userId: userId)
                            }
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(primaryColor)
                        .cornerRadius(25)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.profile != nil {
                    VStack(spacing: 16) {
                        // Custom Navigation Bar with improved back button
                        HStack {
                            // Always show back button if not current user's profile OR if presented modally
                            if !isCurrentUserProfile || userId != nil {
                                Button(action: { 
                                    print("🔍 [ProfileView] Back button tapped")
                                    dismiss() 
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.left")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                        Text("Back")
                                            .font(.body)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            
                            Spacer()
                            
                            Text(viewModel.profile?.name ?? "Profile")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if viewModel.isOwnProfile {
                                Menu {
                                    Button("Edit Profile") {
                                        print("🔍 [ProfileView] Edit Profile menu item tapped")
                                        showingEditProfile = true
                                    }
                                    
                                    Button("Blocked Users") {
                                        print("🔍 [ProfileView] Blocked Users menu item tapped")
                                        showingBlockedUsers = true
                                    }
                                    
                                    Button("Delete Account", role: .destructive) {
                                        print("🔍 [ProfileView] Delete Account menu item tapped")
                                        showingDeleteAccount = true
                                    }
                                    
                                    Button("Logout", role: .destructive) {
                                        print("🔍 [ProfileView] Logout menu item tapped")
                                        showingLogoutAlert = true
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.title2)
                                        .foregroundColor(primaryColor)
                                        .frame(width: 44, height: 44)
                                }
                            } else {
                                Menu {
                                    Button("Refresh Profile") {
                                        print("🔍 [ProfileView] Refresh Profile menu item tapped")
                                        Task {
                                            await viewModel.loadProfile(userId: userId)
                                        }
                                    }
                                    
                                    Button("Report User", role: .destructive) {
                                        print("🔍 [ProfileView] Report User menu item tapped")
                                        showingReportContent = true
                                    }
                                    
                                    Button("Block User", role: .destructive) {
                                        print("🔍 [ProfileView] Block User menu item tapped")
                                        showingBlockUser = true
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.title2)
                                        .foregroundColor(primaryColor)
                                        .frame(width: 44, height: 44)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        .background(Color(.systemBackground))
                        
                        // Profile Header
                        ProfileHeaderView(profile: viewModel.profile)
                        
                        // Stats Cards
                        let effectiveUserId = userId ?? viewModel.profile?.id
                        ProfileStatsView(profile: viewModel.profile, posts: viewModel.posts, userId: effectiveUserId)
                        
                        // Follow Button (only for other users' profiles)
                        if !viewModel.isOwnProfile {
                            ProfileFollowButtonView(
                                isFollowing: viewModel.profile?.isFollowing ?? false,
                                onToggleFollow: { viewModel.toggleFollow() },
                                primaryColor: primaryColor
                            )
                        }
                        
                        // Content Tabs
                        ProfileContentTabsView(
                            selectedTab: $selectedTab,
                            posts: viewModel.posts,
                            aboutData: viewModel.aboutData,
                            userId: effectiveUserId,
                            profile: viewModel.profile
                        )
                    }
                } else {
                    // Profile is nil - show loading or error state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading profile...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            print("🔍 [ProfileView] Pull-to-refresh triggered")
            await viewModel.forceRefreshProfile(userId: userId)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            // Load profile data when the view appears
            print("🔍 [ProfileView] Task modifier executing - userId: \(userId ?? "nil")")
            print("🔍 [ProfileView] Current loading state: \(viewModel.isLoading)")
            print("🔍 [ProfileView] Current profile: \(viewModel.profile?.name ?? "nil")")
            print("🔍 [ProfileView] About to call loadProfile...")
            await viewModel.loadProfile(userId: userId)
            print("🔍 [ProfileView] Task completed - loading state: \(viewModel.isLoading)")
            print("🔍 [ProfileView] Task completed - profile: \(viewModel.profile?.name ?? "nil")")
            print("🔍 [ProfileView] Task completed - error: \(viewModel.error ?? "nil")")
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .fullScreenCover(isPresented: $showingEditProfile) {
            ProfileEditView()
        }
        .fullScreenCover(isPresented: $showingDeleteAccount) {
            DeleteAccountView()
        }
        .fullScreenCover(isPresented: $showingReportContent) {
            if let targetUserId = userId, let targetUserName = viewModel.profile?.name {
                ReportContentView(
                    contentType: "user",
                    contentId: targetUserId,
                    contentTitle: targetUserName
                )
            }
        }
        .fullScreenCover(isPresented: $showingBlockUser) {
            if let targetUserId = userId, let targetUserName = viewModel.profile?.name {
                BlockUserView(
                    targetUserId: targetUserId,
                    targetUserName: targetUserName,
                    onUserBlocked: { blockedUserId in
                        Task {
                            // Handle user blocked
                        }
                    }
                )
                .environmentObject(feedManager)
            }
        }
        .fullScreenCover(isPresented: $showingBlockedUsers) {
            BlockedUsersListView()
                .environmentObject(feedManager)
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                Task {
                    await viewModel.logout()
                }
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    let profile: ProfileUser?
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Image
            ProfileImageView(profile: profile)
            
            // User Info
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(profile?.name ?? "Loading...")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if profile?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                    }
                    
                    if profile?.isCreator == true {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                if let username = profile?.username {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let bio = profile?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if let location = profile?.location {
                    ProfileLocationView(location: location)
                }
                
                // Settings button for current user's profile
                if profile?.id == AuthManager.shared.user?.id {
                    Button(action: {
                        showingSettings = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "gear")
                                .font(.system(size: 16, weight: .medium))
                            Text("Settings")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(AuthManager.shared)
                .environmentObject(PushNotificationManager.shared)
        }
    }
}

// MARK: - Profile Image View
struct ProfileImageView: View {
    let profile: ProfileUser?
    
    var body: some View {
        ZStack {
            if let imageUrl = profile?.profileImage?.url {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProfilePlaceholderImageView(name: profile?.name)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            } else {
                ProfilePlaceholderImageView(name: profile?.name)
                    .frame(width: 100, height: 100)
            }
        }
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 255/255, green: 107/255, blue: 107/255), // #FF6B6B
                            Color(red: 78/255, green: 205/255, blue: 196/255)   // #4ECDC4
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
        .shadow(radius: 8)
    }
}

// MARK: - Profile Placeholder Image View
struct ProfilePlaceholderImageView: View {
    let name: String?
    
    var body: some View {
        Circle()
            .fill(LinearGradient(
                colors: [
                    Color(red: 255/255, green: 107/255, blue: 107/255).opacity(0.8), // #FF6B6B
                    Color(red: 78/255, green: 205/255, blue: 196/255).opacity(0.8)   // #4ECDC4
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .overlay(
                Text(name?.prefix(1).uppercased() ?? "?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Profile Location View
struct ProfileLocationView: View {
    let location: UserLocation
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "location.fill")
                .foregroundColor(Color(red: 78/255, green: 205/255, blue: 196/255)) // #4ECDC4
            Text(formatLocation(location))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func formatLocation(_ location: UserLocation) -> String {
        var parts: [String] = []
        if let city = location.city { parts.append(city) }
        if let state = location.state { parts.append(state) }
        if let country = location.country { parts.append(country) }
        return parts.isEmpty ? "Location not specified" : parts.joined(separator: ", ")
    }
}

// MARK: - Profile Stats View
struct ProfileStatsView: View {
    let profile: ProfileUser?
    let posts: [ProfilePost]
    let userId: String?
    @State private var showingFollowers = false
    @State private var showingFollowing = false
    @StateObject private var authManager = AuthManager.shared
    
    private var postsCount: Int {
        posts.count
    }
    
    private var followersCount: Int {
        // Use real-time data from AuthManager if this is the current user's profile
        if let currentUserId = authManager.user?.id, currentUserId == userId {
            // Current user's profile - use AuthManager data
            return authManager.user?.followerCount ?? 0
        } else {
            // Other user's profile - use profile data
            return profile?.stats?.followersCount ?? profile?.followers?.count ?? 0
        }
    }
    
    private var followingCount: Int {
        // Use real-time data from AuthManager if this is the current user's profile
        if let currentUserId = authManager.user?.id, currentUserId == userId {
            // Current user's profile - use AuthManager data
            return authManager.user?.following?.count ?? 0
        } else {
            // Other user's profile - use profile data
            return profile?.stats?.followingCount ?? profile?.following?.count ?? 0
        }
    }
    
    var body: some View {
        
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ProfileStatCard(
                    title: "Posts",
                    value: "\(postsCount)",
                    icon: "doc.text"
                )
                
                Divider()
                    .frame(height: 40)
                
                Button(action: {
                    showingFollowers = true
                }) {
                    ProfileStatCard(
                        title: "Followers",
                        value: "\(followersCount)",
                        icon: "person.2"
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .frame(height: 40)
                
                Button(action: {
                    showingFollowing = true
                }) {
                    ProfileStatCard(
                        title: "Following",
                        value: "\(followingCount)",
                        icon: "person.3"
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .fullScreenCover(isPresented: $showingFollowers) {
            if let userId = userId {
                FollowersModalView(userId: userId)
            }
        }
        .fullScreenCover(isPresented: $showingFollowing) {
            if let userId = userId {
                FollowingModalView(userId: userId)
            }
        }
    }
}

// MARK: - Profile Stat Card
struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 255/255, green: 107/255, blue: 107/255)) // #FF6B6B
            
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Color(red: 78/255, green: 205/255, blue: 196/255)) // #4ECDC4
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Followers View Model
@MainActor
class FollowersViewModel: ObservableObject {
    @Published var followers: [FollowerUser] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiService = APIService()
    
    func loadFollowers(userId: String) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        apiService.fetchFollowers(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let followers):
                    self?.followers = followers
                    print("🔍 [FollowersViewModel] Loaded \(followers.count) followers")
                case .failure(let error):
                    self?.error = error.localizedDescription
                    print("🔍 [FollowersViewModel] Error loading followers: \(error)")
                }
            }
        }
    }
}

// MARK: - Following View Model
@MainActor
class FollowingViewModel: ObservableObject {
    @Published var following: [FollowerUser] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiService = APIService()
    
    func loadFollowing(userId: String) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        apiService.fetchFollowing(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let following):
                    self?.following = following
                    print("🔍 [FollowingViewModel] Loaded \(following.count) following")
                case .failure(let error):
                    self?.error = error.localizedDescription
                    print("🔍 [FollowingViewModel] Error loading following: \(error)")
                }
            }
        }
    }
}

// MARK: - Follower Row View
struct FollowerRowView: View {
    let follower: FollowerUser
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Profile Image
                if let imageUrl = follower.profileImage {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String(follower.name.prefix(1)).uppercased())
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(follower.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let username = follower.username {
                        Text("@\(username)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Follow Button (if not the current user)
                if follower.id != AuthManager.shared.user?.id {
                    let isFollowing = AuthManager.shared.user?.following?.contains(follower.id) ?? false
                    
                    Button(action: {
                        // Handle follow/unfollow
                        print("🔍 [FollowerRowView] Follow button tapped for user: \(follower.id), currently following: \(isFollowing)")
                        
                        Task {
                            do {
                                if isFollowing {
                                    let success = try await APIService().unfollowUser(userId: follower.id)
                                    if success {
                                        AuthManager.shared.updateFollowState(targetUserId: follower.id, isFollowing: false)
                                    }
                                } else {
                                    let success = try await APIService().followUser(userId: follower.id)
                                    if success {
                                        AuthManager.shared.updateFollowState(targetUserId: follower.id, isFollowing: true)
                                    }
                                }
                            } catch {
                                print("🔍 [FollowerRowView] Failed to toggle follow: \(error)")
                            }
                        }
                    }) {
                        Text(isFollowing ? "Following" : "Follow")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isFollowing ? .primary : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                isFollowing 
                                    ? Color.gray.opacity(0.1)
                                    : Color(red: 255/255, green: 107/255, blue: 107/255)
                            )
                            .cornerRadius(15)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Profile Follow Button View
struct ProfileFollowButtonView: View {
    let isFollowing: Bool
    let onToggleFollow: () -> Void
    let primaryColor: Color
    
    var body: some View {
        Button(isFollowing ? "Following" : "Follow") {
            onToggleFollow()
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(isFollowing ? primaryColor : .white)
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .background(
            isFollowing ? Color.clear : primaryColor
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(isFollowing ? primaryColor : Color.clear, lineWidth: 2)
        )
        .cornerRadius(25)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

// MARK: - Profile Content Tabs View
struct ProfileContentTabsView: View {
    @Binding var selectedTab: Int
    let posts: [ProfilePost]
    let aboutData: ProfileAboutData?
    let userId: String?
    let profile: ProfileUser?
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("Content", selection: $selectedTab) {
                Text("Posts").tag(0)
                Text("Events").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .accentColor(Color(red: 255/255, green: 107/255, blue: 107/255)) // #FF6B6B
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            // Tab Content
            if selectedTab == 0 {
                ProfilePostsTabView(posts: posts, userId: userId)
            } else {
                ProfileEventsTabView(profile: profile, posts: posts)
            }
        }
    }
}

// MARK: - Profile Posts Tab View
struct ProfilePostsTabView: View {
    let posts: [ProfilePost]
    let userId: String?
    @State private var selectedPostIndex: Int?
    @State private var showingPostsFeed = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if !posts.isEmpty {
                HStack {
                    Text("\(posts.count) Posts")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    if posts.isEmpty {
                        ProfileEmptyStateView(
                            icon: "doc.text",
                            title: "No Posts Yet",
                            message: "This user hasn't shared any posts yet."
                        )
                        .gridCellColumns(3)
                        .padding(.top, 50)
                    } else {
                        ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                            ProfilePostGridItem(post: post)
                                .onTapGesture {
                                    selectedPostIndex = index
                                    showingPostsFeed = true
                                }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(.systemGroupedBackground), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .fullScreenCover(isPresented: $showingPostsFeed) {
            UserPostsFeedView(
                posts: posts,
                initialIndex: selectedPostIndex ?? 0,
                userId: userId,
                profileName: nil
            )
        }
    }
}

// MARK: - Profile Post Grid Item
struct ProfilePostGridItem: View {
    let post: ProfilePost
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 0) {
                // Media content area
                ZStack {
                    if let imageUrl = getPostImageUrl() {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.7)
                                )
                        }
                        
                        // Video indicator overlay
                        if hasVideo() {
                            VStack {
                                HStack {
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.7))
                                            .frame(width: 24, height: 24)
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.top, 8)
                                    .padding(.trailing, 8)
                                }
                                Spacer()
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            if hasVideo() {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(red: 255/255, green: 107/255, blue: 107/255).opacity(0.7))
                                Text("Video")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                            } else {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(red: 255/255, green: 107/255, blue: 107/255).opacity(0.7))
                                Text("Post")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 255/255, green: 107/255, blue: 107/255).opacity(0.06), Color(red: 78/255, green: 205/255, blue: 196/255).opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                }
                .frame(height: 120)
                .clipped()
                
                // Content preview area
                VStack(alignment: .leading, spacing: 6) {
                    // Show title first, then content
                    if let title = post.title, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                    } else if !post.content.isEmpty {
                        Text(post.content)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Show post type badge
                    if post.type != "post" {
                        Text(post.type.capitalized)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 255/255, green: 107/255, blue: 107/255))
                            .cornerRadius(8)
                    }
                    
                    HStack {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text("\(post.likeCount)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        if post.commentCount > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "message.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text("\(post.commentCount)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .cornerRadius(16)
    }
    
    private func getPostImageUrl() -> String? {
        print("🔍 [ProfilePostGridItem] Getting image URL for post: \(post.id)")
        print("🔍 [ProfilePostGridItem] Post data: featuredImage=\(post.featuredImage?.url ?? "nil"), image=\(post.image ?? "nil"), photos=\(post.photos?.count ?? 0), media=\(post.media?.count ?? 0)")
        
        // Priority order for images:
        // 1. Featured image (highest priority)
        if let featuredImage = post.featuredImage?.url {
            let url = absoluteMediaURL(featuredImage)?.absoluteString
            print("🔍 [ProfilePostGridItem] Using featured image: \(url ?? "nil")")
            return url
        }
        
        // 2. Main image
        if let image = post.image {
            let url = absoluteMediaURL(image)?.absoluteString
            print("🔍 [ProfilePostGridItem] Using main image: \(url ?? "nil")")
            return url
        }
        
        // 3. First photo from photos array
        if let photos = post.photos, !photos.isEmpty {
            let url = absoluteMediaURL(photos.first!)?.absoluteString
            print("🔍 [ProfilePostGridItem] Using first photo: \(url ?? "nil")")
            return url
        }
        
        // 4. First media from media array
        if let media = post.media, !media.isEmpty {
            let url = absoluteMediaURL(media.first!)?.absoluteString
            print("🔍 [ProfilePostGridItem] Using first media: \(url ?? "nil")")
            return url
        }
        
        // 5. Video thumbnail (for video posts)
        if let videoThumbnail = post.videoThumbnail {
            let url = absoluteMediaURL(videoThumbnail)?.absoluteString
            print("🔍 [ProfilePostGridItem] Using video thumbnail: \(url ?? "nil")")
            return url
        }
        
        print("🔍 [ProfilePostGridItem] No image URL found")
        return nil
    }
    
    private func hasVideo() -> Bool {
        return post.video != nil || 
               (post.videos != nil && !post.videos!.isEmpty) ||
               (post.media != nil && post.media!.contains { $0.contains("video") || $0.contains(".mp4") || $0.contains(".mov") })
    }
    
    private func getVideoUrl() -> String? {
        if let video = post.video {
            return absoluteMediaURL(video)?.absoluteString
        }
        if let videos = post.videos, !videos.isEmpty {
            return absoluteMediaURL(videos.first!)?.absoluteString
        }
        if let media = post.media {
            for mediaItem in media {
                if mediaItem.contains("video") || mediaItem.contains(".mp4") || mediaItem.contains(".mov") {
                    return absoluteMediaURL(mediaItem)?.absoluteString
                }
            }
        }
        return nil
    }
}

// MARK: - Profile Events Tab View
struct ProfileEventsTabView: View {
    let profile: ProfileUser?
    let posts: [ProfilePost]
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("No Events Yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("When you create events, they'll appear here")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 50)
    }
}

// MARK: - Profile Empty State View
struct ProfileEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [primaryColor.opacity(0.1), secondaryColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(primaryColor)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - User Posts Feed View
struct UserPostsFeedView: View {
    let posts: [ProfilePost]
    let initialIndex: Int
    let userId: String?
    let profileName: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                if posts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        
                        Text("No posts available")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("This user hasn't shared any posts yet.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(posts, id: \.id) { post in
                                SinglePostView(post: post, userId: userId, profileName: profileName)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Posts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Single Post View
struct SinglePostView: View {
    let post: ProfilePost
    let userId: String?
    let profileName: String?
    
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 8)
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(
                            LinearGradient(
                                colors: [primaryColor.opacity(0.8), secondaryColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        Text("U")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 2)
                            .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("User")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(formatDate(post.createdAt))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                
                // Content
                VStack(alignment: .leading, spacing: 18) {
                    if !post.content.isEmpty {
                        Text(post.content)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
                
                Divider().padding(.horizontal, 16)
                
                // Action bar
                HStack(spacing: 36) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.primary)
                        Text("\(post.likeCount)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                        Text("\(post.commentCount)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                        Text("\(post.saveCount)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            let now = Date()
            let timeInterval = now.timeIntervalSince(date)
            
            if timeInterval < 60 {
                return "Just now"
            } else if timeInterval < 3600 {
                let minutes = Int(timeInterval / 60)
                return "\(minutes)m ago"
            } else if timeInterval < 86400 {
                let hours = Int(timeInterval / 3600)
                return "\(hours)h ago"
            } else {
                let days = Int(timeInterval / 86400)
                return "\(days)d ago"
            }
        }
        
        return dateString.prefix(10).description
    }
}

// MARK: - Followers Modal View
struct FollowersModalView: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FollowersViewModel()
    @State private var selectedUserId: String?
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading followers...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Error loading followers")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button(action: {
                            Task {
                                await viewModel.loadFollowers(userId: userId)
                            }
                        }) {
                            Text("Try Again")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color(red: 255/255, green: 107/255, blue: 107/255))
                                .cornerRadius(25)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.followers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No followers yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("When people follow this user, they'll appear here.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.followers, id: \.id) { follower in
                        FollowerRowView(follower: follower) {
                            selectedUserId = follower.id
                            showingProfile = true
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Followers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadFollowers(userId: userId)
            }
            .fullScreenCover(isPresented: Binding(
                get: { showingProfile && selectedUserId != nil },
                set: { if !$0 { showingProfile = false; selectedUserId = nil } }
            )) {
                if let userId = selectedUserId {
                    ProfileView(userId: userId)
                        .onAppear {
                            print("🔍 [FollowersModalView] ProfileView appeared for user: \(userId)")
                        }
                        .onDisappear {
                            print("🔍 [FollowersModalView] ProfileView disappeared")
                        }
                }
            }
        }
    }
}

// MARK: - Following Modal View
struct FollowingModalView: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FollowingViewModel()
    @State private var selectedUserId: String?
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading following...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Error loading following")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button(action: {
                            Task {
                                await viewModel.loadFollowing(userId: userId)
                            }
                        }) {
                            Text("Try Again")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color(red: 255/255, green: 107/255, blue: 107/255))
                                .cornerRadius(25)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.following.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("Not following anyone yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("When this user follows people, they'll appear here.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.following, id: \.id) { following in
                        FollowerRowView(follower: following) {
                            selectedUserId = following.id
                            showingProfile = true
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Following")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadFollowing(userId: userId)
            }
            .fullScreenCover(isPresented: Binding(
                get: { showingProfile && selectedUserId != nil },
                set: { if !$0 { showingProfile = false; selectedUserId = nil } }
            )) {
                if let userId = selectedUserId {
                    ProfileView(userId: userId)
                        .onAppear {
                            print("🔍 [FollowingModalView] ProfileView appeared for user: \(userId)")
                        }
                        .onDisappear {
                            print("🔍 [FollowingModalView] ProfileView disappeared")
                        }
                }
            }
        }
    }
}
