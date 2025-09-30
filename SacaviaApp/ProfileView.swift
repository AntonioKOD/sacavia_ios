import SwiftUI
import AVKit
import UIKit
import AVFoundation

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
    @Published var postsCacheBuster = UUID() // Cache buster for posts
    
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
                print("🔍 [ProfileViewModel] Previous profile: \(self.profile?.name ?? "nil")")
                print("🔍 [ProfileViewModel] Previous posts count: \(self.posts.count)")
                print("🔍 [ProfileViewModel] New profile data: \(profileData.name)")
                print("🔍 [ProfileViewModel] New posts count: \(recentPosts.count)")
                
                self.profile = profileData
                self.posts = recentPosts
                self.isLoading = false
                
                // Update posts cache buster to force UI refresh
                self.postsCacheBuster = UUID()
                
                print("🔍 [ProfileViewModel] UI updated successfully!")
                print("🔍 [ProfileViewModel] Profile loaded: \(profileData.name) - Posts: \(profileData.stats?.postsCount ?? 0), Followers: \(profileData.stats?.followersCount ?? 0), Following: \(profileData.stats?.followingCount ?? 0)")
                print("🔍 [ProfileViewModel] Final state - profile: \(self.profile?.name ?? "nil"), posts: \(self.posts.count), loading: \(self.isLoading)")
                print("🔍 [ProfileViewModel] Profile image URL: \(self.profile?.profileImage?.url ?? "nil")")
                print("🔍 [ProfileViewModel] Posts cache buster updated: \(self.postsCacheBuster)")
                
                // Debug each post's media content
                for (index, post) in recentPosts.enumerated() {
                    print("🔍 [ProfileViewModel] Post \(index): \(post.id)")
                    print("🔍 [ProfileViewModel] - Title: \(post.title ?? "nil")")
                    print("🔍 [ProfileViewModel] - Content: \(post.content)")
                    print("🔍 [ProfileViewModel] - Type: \(post.type)")
                    print("🔍 [ProfileViewModel] - Featured Image: \(post.featuredImage?.url ?? "nil")")
                    print("🔍 [ProfileViewModel] - Image: \(post.image ?? "nil")")
                    print("🔍 [ProfileViewModel] - Video: \(post.video ?? "nil")")
                    print("🔍 [ProfileViewModel] - Video Thumbnail: \(post.videoThumbnail ?? "nil")")
                    print("🔍 [ProfileViewModel] - Photos: \(post.photos?.count ?? 0) items")
                    print("🔍 [ProfileViewModel] - Videos: \(post.videos?.count ?? 0) items")
                    print("🔍 [ProfileViewModel] - Media: \(post.media?.count ?? 0) items")
                    print("🔍 [ProfileViewModel] - Images: \(post.images?.count ?? 0) items")
                    print("🔍 [ProfileViewModel] - Cover: \(post.cover ?? "nil")")
                    print("🔍 [ProfileViewModel] - Has Video: \(post.hasVideo ?? false)")
                    if let photos = post.photos, !photos.isEmpty {
                        print("🔍 [ProfileViewModel] - First Photo URL: \(photos.first!)")
                    }
                    if let media = post.media, !media.isEmpty {
                        print("🔍 [ProfileViewModel] - First Media URL: \(media.first!)")
                    }
                }
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
        print("🔍 [ProfileViewModel] Current profile before refresh: \(profile?.name ?? "nil")")
        print("🔍 [ProfileViewModel] Current posts count before refresh: \(posts.count)")
        await loadProfile(userId: userId)
        print("🔍 [ProfileViewModel] Profile refresh completed")
        print("🔍 [ProfileViewModel] New profile after refresh: \(profile?.name ?? "nil")")
        print("🔍 [ProfileViewModel] New posts count after refresh: \(posts.count)")
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
    @State private var showingDeleteAccount = false
    @State private var showingReportContent = false
    @State private var showingBlockUser = false
    @State private var showingBlockedUsers = false
    @State private var showingSharedLists = false
    @State private var showingSharingHistory = false
    @State private var showingPrivacySettings = false
    @State private var lastRefreshTime: Date = Date.distantPast

    @Environment(\.dismiss) private var dismiss

    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4

    let userId: String?

    init(userId: String? = nil) {
        self.userId = userId
    }

    private var isCurrentUserProfile: Bool {
        if userId == nil { return true }
        return userId == authManager.user?.id
    }

    private func debouncedRefresh() {
        let now = Date()
        let timeSinceLastRefresh = now.timeIntervalSince(lastRefreshTime)
        if timeSinceLastRefresh > 5.0 {
            lastRefreshTime = now
            Task { await viewModel.forceRefreshProfile(userId: userId) }
        }
    }
    
    // MARK: - Share App Function
    private func shareApp() {
        let appStoreURL = "https://apps.apple.com/us/app/sacavia/id6748926294"
        let shareText = "Check out Sacavia - Discover amazing places and connect with your community! 🗺️✨\n\n\(appStoreURL)\n\n#Sacavia #Discover #Community #Travel"
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // Configure for iPad presentation
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Present the share sheet
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(primaryColor)
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
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Error Loading Profile")
                .font(.title2)
                .fontWeight(.semibold)

            Text(viewModel.error ?? "Unknown error")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                Task {
                    await viewModel.loadProfile(userId: userId)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(primaryColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.error != nil {
                    errorView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.profile != nil {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Top bar
                            HStack {
                                if !isCurrentUserProfile {
                                    Button {
                                        dismiss()
                                    } label: {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                }

                                Spacer()

                                Text(viewModel.profile?.name ?? "Profile")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .foregroundColor(.primary.opacity(0.85))

                                Spacer()

                                Menu {
                                    if viewModel.isOwnProfile {
                                        Button("Edit Profile") { showingEditProfile = true }

                                        Button("Refresh Profile") {
                                            Task {
                                                await viewModel.forceRefreshProfile(userId: userId)
                                            }
                                        }

                                        Button("Shared Lists") { showingSharedLists = true }
                                        
                                        Button("Sharing History") { showingSharingHistory = true }
                                        
                                        Button("Share App") { shareApp() }
                                        
                                        Button("Privacy Settings") { showingPrivacySettings = true }

                                        Button("Blocked Users") { showingBlockedUsers = true }

                                        Button("Delete Account", role: .destructive) { showingDeleteAccount = true }

                                        Button("Logout", role: .destructive) { showingLogoutAlert = true }
                                    } else {
                                        Button("Refresh Profile") {
                                            Task {
                                                await viewModel.loadProfile(userId: userId)
                                            }
                                        }

                                        Button("Report User", role: .destructive) { showingReportContent = true }

                                        Button("Block User", role: .destructive) { showingBlockUser = true }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.title2)
                                        .foregroundColor(primaryColor)
                                        .frame(width: 44, height: 44)
                                }
                            }
                            .padding(.horizontal)

                            // Header
                            ProfileHeaderView(
                                profile: viewModel.profile, 
                                onEditProfile: { showingEditProfile = true }
                            )
                                .padding(.horizontal)

                            // Stats
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
                                profile: viewModel.profile,
                                postsCacheBuster: viewModel.postsCacheBuster
                            )
                        }
                        .padding(.bottom, 16)
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
            await viewModel.forceRefreshProfile(userId: userId)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            // Load profile data when the view appears
            await viewModel.loadProfile(userId: userId)

            // Test notification system
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("TestNotification"),
                    object: nil,
                    userInfo: ["message": "ProfileView test notification"]
                )
            }
        }
        .onAppear {
            // Refresh profile data when view appears to ensure we have the latest data
            Task {
                await viewModel.forceRefreshProfile(userId: userId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh when app comes to foreground (user might have added posts in another view)
            debouncedRefresh()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProfileImageUpdated"))) { _ in
            // Force refresh the profile to get updated image
            Task {
                await viewModel.forceRefreshProfile(userId: userId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProfileUpdated"))) { _ in
            // Force refresh the profile to get updated data
            Task {
                await viewModel.forceRefreshProfile(userId: userId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TestNotification"))) { _ in
            // Test notification received
        }
        .fullScreenCover(isPresented: $showingEditProfile) {
            ProfileEditView()
        }
        .onChange(of: showingEditProfile) { _, isShowing in
            if !isShowing {
                // ProfileEditView was dismissed, refresh the profile
                Task {
                    await viewModel.forceRefreshProfile(userId: userId)
                }
            }
        }
        .onChange(of: viewModel.profile?.profileImage?.url) { _, newUrl in
            // Force refresh when profile image URL changes
            if newUrl != nil {
                Task {
                    await viewModel.forceRefreshProfile(userId: userId)
                }
            }
        }
        .onChange(of: viewModel.posts.count) { _, _ in
            // Update posts cache buster when posts count changes
            viewModel.postsCacheBuster = UUID()
            // Trigger a debounced refresh to get the latest data
            debouncedRefresh()
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
                    onUserBlocked: { _ in }
                )
                .environmentObject(feedManager)
            }
        }
        .fullScreenCover(isPresented: $showingBlockedUsers) {
            BlockedUsersListView()
                .environmentObject(feedManager)
        }
        .fullScreenCover(isPresented: $showingSharedLists) {
            SharedListsView()
        }
        .fullScreenCover(isPresented: $showingSharingHistory) {
            SharingHistoryView()
        }
        .fullScreenCover(isPresented: $showingPrivacySettings) {
            PrivacySettingsView()
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
    var onEditProfile: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            // Profile Image
            ProfileImageView(profile: profile)
                .frame(width: 100, height: 100)

            // User Info
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text(profile?.name ?? "Loading...")
                        .font(.title3)
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

                // Actions for current user's profile
                if profile?.id == AuthManager.shared.user?.id {
                    HStack(spacing: 12) {
                        Button(action: { onEditProfile?() }) {
                            Label("Edit Profile", systemImage: "pencil")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 255/255, green: 107/255, blue: 107/255))

                    }
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.top, 4)
                }
            }
        }
    }

}

// MARK: - Profile Image View
struct ProfileImageView: View {
    let profile: ProfileUser?
    @State private var imageCacheBuster = UUID()
    
    var body: some View {
        ZStack {
            if let imageUrl = profile?.profileImage?.url {
                AsyncImage(url: URL(string: addCacheBuster(to: imageUrl))) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProfilePlaceholderImageView(name: profile?.name)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .id(imageCacheBuster) // Force view refresh when cache buster changes
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
        .onChange(of: profile?.profileImage?.url) { _, newUrl in
            // Update cache buster when profile image URL changes
            if newUrl != nil {
                imageCacheBuster = UUID()
                print("🔍 [ProfileImageView] Profile image URL changed, updating cache buster")
            }
        }
    }
    
    private func addCacheBuster(to url: String) -> String {
        let separator = url.contains("?") ? "&" : "?"
        return "\(url)\(separator)cb=\(imageCacheBuster.uuidString)"
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

    private var postsCount: Int { posts.count }

    private var followersCount: Int {
        if let currentUserId = authManager.user?.id, currentUserId == userId {
            return authManager.user?.followerCount ?? 0
        } else {
            return profile?.stats?.followersCount ?? profile?.followers?.count ?? 0
        }
    }

    private var followingCount: Int {
        if let currentUserId = authManager.user?.id, currentUserId == userId {
            return authManager.user?.following?.count ?? 0
        } else {
            return profile?.stats?.followingCount ?? profile?.following?.count ?? 0
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ProfileStatCard(title: "Posts", value: "\(postsCount)", icon: "doc.text")

            Divider().frame(height: 40)

            Button(action: { showingFollowers = true }) {
                ProfileStatCard(title: "Followers", value: "\(followersCount)", icon: "person.2")
            }
            .buttonStyle(PlainButtonStyle())

            Divider().frame(height: 40)

            Button(action: { showingFollowing = true }) {
                ProfileStatCard(title: "Following", value: "\(followingCount)", icon: "person.3")
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
        .fullScreenCover(isPresented: $showingFollowers) {
            if let userId = userId { FollowersModalView(userId: userId) }
        }
        .fullScreenCover(isPresented: $showingFollowing) {
            if let userId = userId { FollowingModalView(userId: userId) }
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
    let postsCacheBuster: UUID
    
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
                ProfilePostsTabView(posts: posts, userId: userId, profileName: profile?.name, postsCacheBuster: postsCacheBuster)
            } else {
                ProfileEventsTabView(profile: profile, posts: posts)
            }
        }
    }
}

// MARK: - Video Thumbnail Cache & View
final class VideoThumbnailCache {
    static let shared = NSCache<NSString, UIImage>()
}

struct VideoThumbnailView: View {
    let videoURLString: String
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(ProgressView().scaleEffect(0.7))
                    .task {
                        await generateThumbnail()
                    }
            }
        }
    }
    
    private func generateThumbnail() async {
        guard let url = URL(string: videoURLString) else { return }
        let key = videoURLString as NSString
        if let cached = VideoThumbnailCache.shared.object(forKey: key) {
            await MainActor.run { self.image = cached }
            return
        }
        
        await withTaskGroup(of: UIImage?.self) { group in
            group.addTask {
                let asset = AVAsset(url: url)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: 600, height: 600)
                let time = CMTime(seconds: 0.0, preferredTimescale: 600)
                do {
                    let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                    return UIImage(cgImage: cgImage)
                } catch {
                    print("🔍 [VideoThumbnailView] Failed to generate thumbnail: \(error)")
                    return nil
                }
            }
            
            for await result in group {
                if let img = result {
                    VideoThumbnailCache.shared.setObject(img, forKey: key)
                    await MainActor.run { self.image = img }
                }
            }
        }
    }
}

// MARK: - Profile Posts Tab View
struct ProfilePostsTabView: View {
    let posts: [ProfilePost]
    let userId: String?
    let profileName: String?
    let postsCacheBuster: UUID
    @State private var selectedPostIndex: Int?
    @State private var showingPostsFeed = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
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
                .padding(.vertical, 8)
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    if posts.isEmpty {
                        ProfileEmptyStateView(
                            icon: "doc.text",
                            title: "No Posts Yet",
                            message: "This user hasn't shared any posts yet."
                        )
                        .gridCellColumns(2)
                        .padding(.top, 50)
                    } else {
                        ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                            ProfilePostGridItem(post: post, postsCacheBuster: postsCacheBuster)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPostIndex = index
                                    showingPostsFeed = true
                                }
                                .onAppear {
                                    let _ = print("🔍 [ProfilePostsTabView] Post \(index) appeared: \(post.id)")
                                }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
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
        .onAppear {
            print("🔍 [ProfilePostsTabView] Posts count: \(posts.count)")
            for (index, post) in posts.enumerated() {
                print("🔍 [ProfilePostsTabView] Post \(index): \(post.id) - \(post.title ?? "No title")")
            }
        }
        .fullScreenCover(isPresented: $showingPostsFeed) {
            UserPostsFeedView(
                posts: posts,
                initialIndex: selectedPostIndex ?? 0,
                userId: userId,
                profileName: profileName
            )
        }
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

// MARK: - User Posts Feed View (TikTok/Instagram Style)
struct UserPostsFeedView: View {
    let posts: [ProfilePost]
    let initialIndex: Int
    let userId: String?
    let profileName: String?
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        ZStack {
            // Dark gradient background like TikTok
            LinearGradient(
                colors: [
                    Color.black,
                    Color.black.opacity(0.95),
                    Color.black.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if posts.isEmpty {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [primaryColor.opacity(0.2), secondaryColor.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "doc.text")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(primaryColor)
                    }
                    
                    VStack(spacing: 12) {
                        Text("No Posts Yet")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("This user hasn't shared any posts yet.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
            } else {
                // TikTok/Instagram-style vertical feed
                TabView(selection: $currentIndex) {
                    ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                        SinglePostView(
                            post: post,
                            userId: userId,
                            profileName: profileName,
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            dragOffset = value.translation.height
                        }
                        .onEnded { value in
                            isDragging = false
                            dragOffset = 0
                            
                            // Handle swipe to dismiss
                            if value.translation.height > 100 {
                                dismiss()
                            }
                        }
                )
                .offset(y: dragOffset)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: dragOffset)
                
                // Modern overlay controls with Sacavia branding
                VStack {
                    // Top controls with unique Sacavia styling
                    HStack {
                        Button(action: { dismiss() }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        // Sacavia logo/brand
                        HStack(spacing: 6) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [primaryColor, secondaryColor],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 20, height: 20)
                            
                            Text("Sacavia")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        // Post counter with unique styling
                        Text("\(currentIndex + 1)/\(posts.count)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [primaryColor.opacity(0.8), secondaryColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Bottom gradient overlay
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    .allowsHitTesting(false)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            currentIndex = initialIndex
        }
    }
}

// MARK: - Single Post View
struct SinglePostView: View {
    let post: ProfilePost
    let userId: String?
    let profileName: String?
    let primaryColor: Color
    let secondaryColor: Color
    
    @State private var isLiked = false
    @State private var isSaved = false
    @State private var showComments = false
    @State private var isVideoPlaying = false
    @State private var player: AVPlayer?
    @StateObject private var apiService = APIService()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-screen media background
                if hasVideo(), let videoUrl = getVideoUrl() {
                    // Video player
                    VideoPlayerView(
                        videoUrl: absoluteMediaURL(videoUrl) ?? URL(string: videoUrl)!,
                        enableAutoplay: true,
                        enableAudio: true,
                        loop: true
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .onAppear {
                        isVideoPlaying = true
                    }
                    .onDisappear {
                        isVideoPlaying = false
                    }
                } else if let imageUrl = getPostImageUrl() {
                    // Full-screen image
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } placeholder: {
                        // Gradient placeholder
                        LinearGradient(
                            colors: [primaryColor.opacity(0.3), secondaryColor.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                } else {
                    // Default gradient background
                    LinearGradient(
                        colors: [primaryColor.opacity(0.4), secondaryColor.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                
                // Content overlay
                HStack {
                    // Left side - Post content
                    VStack(alignment: .leading, spacing: 16) {
                        Spacer()
                        
                        // User info with actual profile data
                        HStack(spacing: 12) {
                            // Profile image with actual user data
                            AsyncImage(url: URL(string: getProfileImageUrl())) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [primaryColor, secondaryColor],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        Text(getUserInitials())
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 2)
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(getUserName())
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(formatDate(post.createdAt))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                        }
                        
                        // Post content
                        if !post.content.isEmpty {
                            Text(post.content)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(6)
                                .multilineTextAlignment(.leading)
                        }
                        
                        // Post type badge with unique Sacavia styling
                        if post.type != "post" {
                            HStack(spacing: 8) {
                                Image(systemName: getPostTypeIcon())
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(post.type.capitalized)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [primaryColor.opacity(0.8), secondaryColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Location info if available
                        if let location = post.location, !location.name.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(secondaryColor)
                                
                                Text(location.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 100)
                    
                    Spacer()
                    
                    // Right side - Action buttons (Sacavia style)
                    VStack(spacing: 24) {
                        Spacer()
                        
                        // Like button with unique Sacavia styling
                        VStack(spacing: 8) {
                            Button(action: handleLike) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: isLiked ? [primaryColor, secondaryColor] : [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: isLiked ? "heart.fill" : "heart")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(isLiked ? primaryColor : .white)
                                        .scaleEffect(isLiked ? 1.2 : 1.0)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("\(post.likeCount + (isLiked ? 1 : 0))")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        // Comment button
                        VStack(spacing: 8) {
                            Button(action: {
                                showComments = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "bubble.right")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("\(post.commentCount)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        // Share button
                        VStack(spacing: 8) {
                            Button(action: sharePost) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("Share")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        // Save button
                        VStack(spacing: 8) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isSaved.toggle()
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(isSaved ? secondaryColor : .white)
                                        .scaleEffect(isSaved ? 1.1 : 1.0)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("\(post.saveCount + (isSaved ? 1 : 0))")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showComments) {
            SimpleCommentModal(
                postId: post.id,
                commentCount: Binding.constant(post.commentCount),
                apiService: apiService,
                primaryColor: primaryColor
            )
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
    
    private func getUserName() -> String {
        if let profileName = profileName, !profileName.isEmpty {
            return profileName
        }
        return "User"
    }
    
    private func getUserInitials() -> String {
        let name = getUserName()
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else {
            return String(name.prefix(2))
        }
    }
    
    private func getProfileImageUrl() -> String {
        // Try to get profile image from AuthManager if this is the current user
        if let currentUserId = AuthManager.shared.user?.id, 
           let targetUserId = userId, 
           currentUserId == targetUserId {
            return AuthManager.shared.user?.profileImage?.url ?? ""
        }
        return ""
    }
    
    private func getPostTypeIcon() -> String {
        switch post.type.lowercased() {
        case "event":
            return "calendar"
        case "guide":
            return "book"
        case "review":
            return "star"
        case "photo":
            return "camera"
        case "video":
            return "video"
        default:
            return "doc.text"
        }
    }
    
    private func getPostImageUrl() -> String? {
        print("🔍 [SinglePostView] Getting image URL for post: \(post.id)")
        
        // Priority order for images:
        // 1. Featured image (highest priority)
        if let featuredImage = post.featuredImage?.url, !featuredImage.isEmpty {
            let url = absoluteMediaURL(featuredImage)?.absoluteString
            print("🔍 [SinglePostView] Using featured image: \(url ?? "nil")")
            return url
        }
        
        // 2. Cover image
        if let cover = post.cover, !cover.isEmpty {
            let url = absoluteMediaURL(cover)?.absoluteString
            print("🔍 [SinglePostView] Using cover image: \(url ?? "nil")")
            return url
        }
        
        // 3. Main image
        if let image = post.image, !image.isEmpty {
            let url = absoluteMediaURL(image)?.absoluteString
            print("🔍 [SinglePostView] Using main image: \(url ?? "nil")")
            return url
        }
        
        // 4. First image from images array
        if let images = post.images, !images.isEmpty {
            let url = absoluteMediaURL(images.first!)?.absoluteString
            print("🔍 [SinglePostView] Using first image: \(url ?? "nil")")
            return url
        }
        
        // 5. First photo from photos array
        if let photos = post.photos, !photos.isEmpty {
            let url = absoluteMediaURL(photos.first!)?.absoluteString
            print("🔍 [SinglePostView] Using first photo: \(url ?? "nil")")
            return url
        }
        
        // 6. First media from media array
        if let media = post.media, !media.isEmpty {
            let url = absoluteMediaURL(media.first!)?.absoluteString
            print("🔍 [SinglePostView] Using first media: \(url ?? "nil")")
            return url
        }
        
        // 7. Video thumbnail (for video posts)
        if let videoThumbnail = post.videoThumbnail, !videoThumbnail.isEmpty {
            let url = absoluteMediaURL(videoThumbnail)?.absoluteString
            print("🔍 [SinglePostView] Using video thumbnail: \(url ?? "nil")")
            return url
        }
        
        print("🔍 [SinglePostView] No image URL found")
        return nil
    }
    
    private func hasVideo() -> Bool {
        // Check hasVideo field first
        if let hasVideo = post.hasVideo {
            return hasVideo
        }
        
        // Check for video content in various fields
        return (post.video != nil && !post.video!.isEmpty) || 
               (post.videos != nil && !post.videos!.isEmpty) ||
               (post.media != nil && post.media!.contains { $0.contains("video") || $0.contains(".mp4") || $0.contains(".mov") || $0.contains(".avi") || $0.contains(".webm") })
    }
    
    private func getVideoUrl() -> String? {
        print("🔍 [SinglePostView] Getting video URL for post: \(post.id)")
        
        // 1. Main video field
        if let video = post.video, !video.isEmpty {
            let url = absoluteMediaURL(video)?.absoluteString
            print("🔍 [SinglePostView] Using main video: \(url ?? "nil")")
            return url
        }
        
        // 2. First video from videos array
        if let videos = post.videos, !videos.isEmpty {
            let url = absoluteMediaURL(videos.first!)?.absoluteString
            print("🔍 [SinglePostView] Using first video: \(url ?? "nil")")
            return url
        }
        
        // 3. Search media array for video files
        if let media = post.media {
            for mediaItem in media {
                if mediaItem.contains("video") || mediaItem.contains(".mp4") || mediaItem.contains(".mov") || mediaItem.contains(".avi") || mediaItem.contains(".webm") {
                    let url = absoluteMediaURL(mediaItem)?.absoluteString
                    print("🔍 [SinglePostView] Using media video: \(url ?? "nil")")
                    return url
                }
            }
        }
        
        print("🔍 [SinglePostView] No video URL found")
        return nil
    }
    
    // MARK: - Button Actions
    
    private func handleLike() {
        Task {
            do {
                if isLiked {
                    try await apiService.unlikePost(postId: post.id)
                } else {
                    try await apiService.likePost(postId: post.id)
                }
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                }
            } catch {
                print("Like/Unlike failed: \(error)")
            }
        }
    }
    
    private func sharePost() {
        print("🔍 [SinglePostView] Sharing post: \(post.id)")
        
        // Create shareable URL
        let baseURL = "https://sacavia.com"
        let postURL = "\(baseURL)/post/\(post.id)"
        
        // Create enhanced share content
        let shareTitle = "Check out this post by \(getUserName()) on Sacavia"
        let shareText = createEnhancedShareText()
        let hashtags = createHashtags()
        
        // Safely create URL
        guard let url = URL(string: postURL) else {
            print("🔍 [SinglePostView] Failed to create URL for sharing: \(postURL)")
            return
        }
        
        // Create comprehensive share content
        let shareContent = "\(shareTitle)\n\n\(shareText)\n\n\(hashtags)\n\n\(url.absoluteString)"
        
        // Use iOS native sharing with enhanced content
        let activityVC = UIActivityViewController(
            activityItems: [shareContent, url],
            applicationActivities: nil
        )
        
        // Exclude certain activities that don't work well with URLs
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .saveToCameraRoll,
            .addToReadingList,
            .openInIBooks
        ]
        
        // Configure for iPad presentation
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Present the share sheet safely
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                // Find the topmost presented view controller
                var topViewController = rootViewController
                while let presentedViewController = topViewController.presentedViewController {
                    topViewController = presentedViewController
                }
                
                print("🔍 [SinglePostView] Presenting share sheet from: \(type(of: topViewController))")
                topViewController.present(activityVC, animated: true) {
                    print("🔍 [SinglePostView] Share sheet presented successfully")
                    
                    // Track share event
                    self.trackShareEvent()
                }
            } else {
                print("🔍 [SinglePostView] Failed to present share sheet - no root view controller found")
            }
        }
    }
    
    private func createEnhancedShareText() -> String {
        var shareText = ""
        
        // Add post content
        if !post.content.isEmpty {
            let truncatedContent = post.content.count > 150 ? String(post.content.prefix(150)) + "..." : post.content
            shareText += truncatedContent
        }
        
        // Add location if available
        if let location = post.location {
            shareText += "\n📍 \(location.name)"
        }
        
        // Add tags if available
        if let tags = post.tags, !tags.isEmpty {
            let tagText = tags.prefix(3).joined(separator: ", ")
            shareText += "\n🏷️ \(tagText)"
        }
        
        return shareText
    }
    
    private func createHashtags() -> String {
        var hashtags: [String] = ["#Sacavia"]
        
        // Add tag hashtags
        if let tags = post.tags {
            for tag in tags.prefix(3) {
                let hashtag = "#\(tag.replacingOccurrences(of: " ", with: ""))"
                hashtags.append(hashtag)
            }
        }
        
        // Add location hashtag if available
        if let location = post.location {
            let locationHashtag = "#\(location.name.replacingOccurrences(of: " ", with: ""))"
            hashtags.append(locationHashtag)
        }
        
        return hashtags.joined(separator: " ")
    }
    
    private func trackShareEvent() {
        // You can add analytics tracking here
        print("📊 [SinglePostView] Post shared: \(post.id) by \(getUserName())")
        
        // Note: For ProfileView posts, we don't have access to FeedManager
        // You could add a notification or delegate pattern here if needed
    }
}

// MARK: - Profile Post Grid Item
struct ProfilePostGridItem: View {
    let post: ProfilePost
    let postsCacheBuster: UUID

    var body: some View {
        let _ = print("🔍 [ProfilePostGridItem] Rendering post: \(post.id)")
        return ZStack {
            // Media content
            if let imageUrl = getPostImageUrl() {
                let _ = print("🔍 [ProfilePostGridItem] Found image URL: \(imageUrl)")
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        let _ = print("🔍 [ProfilePostGridItem] Image loaded successfully")
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(let error):
                        let _ = print("🔍 [ProfilePostGridItem] Image failed to load: \(error)")
                        Rectangle()
                            .fill(Color.red.opacity(0.3))
                            .overlay(
                                VStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.red)
                                    Text("Failed to load")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            )
                    case .empty:
                        let _ = print("🔍 [ProfilePostGridItem] Image loading...")
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .overlay(ProgressView().scaleEffect(0.7))
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .overlay(ProgressView().scaleEffect(0.7))
                    }
                }
                .clipped()
            } else if hasVideo(), let videoURL = getVideoUrl() {
                VideoThumbnailView(videoURLString: videoURL)
                    .clipped()
            } else {
                let _ = print("🔍 [ProfilePostGridItem] No image or video found for post: \(post.id)")
                LinearGradient(
                    colors: [
                        Color(red: 255/255, green: 107/255, blue: 107/255).opacity(0.06),
                        Color(red: 78/255, green: 205/255, blue: 196/255).opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    VStack {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        Text(post.title ?? "Post \(post.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                    }
                )
            }

            // Top overlays (multi-image, video)
            HStack {
                if multipleImagesCount() > 1 {
                    Image(systemName: "square.on.square")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Capsule())
                }
                Spacer()
                if hasVideo() {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Capsule())
                }
            }
            .padding(6)

            // Bottom gradient overlay with title/content and counts
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                .overlay(
                    VStack(alignment: .leading, spacing: 4) {
                        if let title = post.title, !title.isEmpty {
                            Text(title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        } else if !post.content.isEmpty {
                            Text(post.content)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }

                        HStack(spacing: 10) {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                Text("\(post.likeCount)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }

                            if post.commentCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "message.fill")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                    Text("\(post.commentCount)")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }

                            Spacer()
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6),
                    alignment: .bottom
                )
            }
        }
        .frame(height: 120)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            let _ = print("🔍 [ProfilePostGridItem] Grid item appeared for post: \(post.id)")
        }
    }

    private func multipleImagesCount() -> Int {
        if let images = post.images, images.count > 1 { return images.count }
        if let photos = post.photos, photos.count > 1 { return photos.count }
        if let media = post.media, media.count > 1 { return media.count }
        return 0
    }

    private func getPostImageUrl() -> String? {
        print("🔍 [ProfilePostGridItem] Getting image URL for post: \(post.id)")
        print("🔍 [ProfilePostGridItem] Post data: featuredImage=\(post.featuredImage?.url ?? "nil"), image=\(post.image ?? "nil"), photos=\(post.photos?.count ?? 0), media=\(post.media?.count ?? 0), images=\(post.images?.count ?? 0), cover=\(post.cover ?? "nil")")

        if let featuredImage = post.featuredImage?.url, !featuredImage.isEmpty {
            let url = absoluteMediaURL(featuredImage)?.absoluteString
            print("🔍 [ProfilePostGridItem] Using featured image: \(url ?? "nil")")
            return url
        }
        if let cover = post.cover, !cover.isEmpty {
            let url = absoluteMediaURL(cover)?.absoluteString
            print("🔍 [ProfilePostGridItem] Using cover image: \(url ?? "nil")")
            return url
        }
        if let image = post.image, !image.isEmpty {
            let url = absoluteMediaURL(image)?.absoluteString
            print("🔍 [ProfilePostGridItem] Using main image: \(url ?? "nil")")
            return url
        }
        if let images = post.images, !images.isEmpty {
            let url = absoluteMediaURL(images.first!)?.absoluteString
            print("🔍 [ProfilePostGridItem] Using first image: \(url ?? "nil")")
            return url
        }
        if let photos = post.photos, !photos.isEmpty {
            let url = absoluteMediaURL(photos.first!)?.absoluteString
            print("🔍 [ProfilePostGridItem] Using first photo: \(url ?? "nil")")
            return url
        }
        if let media = post.media, !media.isEmpty {
            let url = absoluteMediaURL(media.first!)?.absoluteString
            print("🔍 [ProfilePostGridItem] Using first media: \(url ?? "nil")")
            return url
        }
        if let videoThumbnail = post.videoThumbnail, !videoThumbnail.isEmpty {
            let url = absoluteMediaURL(videoThumbnail)?.absoluteString
            print("🔍 [ProfilePostGridItem] Using video thumbnail: \(url ?? "nil")")
            return url
        }

        print("🔍 [ProfilePostGridItem] No image URL found")
        return nil
    }
    
    private func absoluteMediaURL(_ url: String) -> URL? {
        // If it's already a full URL, return it
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            return URL(string: url)
        }
        
        // Otherwise, construct the full URL
        let baseURL = "https://sacavia.com"
        return URL(string: "\(baseURL)\(url.hasPrefix("/") ? "" : "/")\(url)")
    }

    private func hasVideo() -> Bool {
        if let hasVideo = post.hasVideo { return hasVideo }
        return (post.video != nil && !post.video!.isEmpty) ||
               (post.videos != nil && !post.videos!.isEmpty) ||
               (post.media != nil && post.media!.contains { $0.contains("video") || $0.contains(".mp4") || $0.contains(".mov") || $0.contains(".avi") || $0.contains(".webm") })
    }

    private func getVideoUrl() -> String? {
        print("🔍 [ProfilePostGridItem] Getting video URL for post: \(post.id)")
        if let video = post.video, !video.isEmpty {
            let url = absoluteMediaURL(video)?.absoluteString
            print("🔍 [ProfilePostGridItem] Using main video: \(url ?? "nil")")
            return url
        }
        if let videos = post.videos, !videos.isEmpty {
            let url = absoluteMediaURL(videos.first!)?.absoluteString
            print("🔍 [ProfilePostGridItem] Using first video: \(url ?? "nil")")
            return url
        }
        if let media = post.media {
            for mediaItem in media {
                if mediaItem.contains("video") || mediaItem.contains(".mp4") || mediaItem.contains(".mov") || mediaItem.contains(".avi") || mediaItem.contains(".webm") {
                    let url = absoluteMediaURL(mediaItem)?.absoluteString
                    print("🔍 [ProfilePostGridItem] Using media video: \(url ?? "nil")")
                    return url
                }
            }
        }
        print("🔍 [ProfilePostGridItem] No video URL found")
        return nil
    }
}

