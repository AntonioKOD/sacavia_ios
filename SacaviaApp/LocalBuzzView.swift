import SwiftUI
import AVKit
import UIKit
import Foundation

struct LocalBuzzView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var feedManager: FeedManager
    @StateObject private var apiService = APIService()
    @StateObject private var peopleSuggestionsManager = PeopleSuggestionsManager()
    @State private var showingProfile = false
    @State private var selectedUserId: String?
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4

    var body: some View {
        VStack(spacing: 0) {
            // Filter tabs always visible at the top
            FilterTabs(
                feedManager: feedManager,
                peopleSuggestionsManager: peopleSuggestionsManager,
                primaryColor: primaryColor
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
            
            // Content
            if feedManager.filter == .people {
                SimplePeopleSuggestionsView()
            } else {
                FeedContent(
                    feedManager: feedManager,
                    apiService: apiService,
                    peopleSuggestionsManager: peopleSuggestionsManager,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    onProfileTap: { userId in
                        print("🔍 [LocalBuzzView] Profile tap handler called with userId: \(userId)")
                        print("🔍 [LocalBuzzView] Before setting - selectedUserId: \(selectedUserId ?? "nil")")
                        print("🔍 [LocalBuzzView] Before setting - showingProfile: \(showingProfile)")
                        selectedUserId = userId
                        print("🔍 [LocalBuzzView] After setting selectedUserId: \(selectedUserId ?? "nil")")
                        showingProfile = true
                        print("🔍 [LocalBuzzView] After setting showingProfile: \(showingProfile)")
                        
                        // Add a small delay to check if state persists
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            print("🔍 [LocalBuzzView] After 0.1s - selectedUserId: \(selectedUserId ?? "nil")")
                            print("🔍 [LocalBuzzView] After 0.1s - showingProfile: \(showingProfile)")
                        }
                    }
                )
            }
        }
        .background(Color(.systemGray6))
        .onAppear {
            Task {
                // Load blocked users first
                await feedManager.loadBlockedUsers()
                // Then refresh feed with interaction sync
                await feedManager.refreshFeedWithInteractionSync(filter: feedManager.filter)
            }
            if feedManager.filter == .all {
                peopleSuggestionsManager.fetchPeopleSuggestions(category: "all")
            }
        }
        .fullScreenCover(isPresented: Binding<Bool>(
            get: { showingProfile && selectedUserId != nil },
            set: { newValue in 
                if !newValue {
                    showingProfile = false
                    selectedUserId = nil
                }
            }
        )) {
            if let userId = selectedUserId {
                ProfileView(userId: userId)
                    .onAppear {
                        print("🔍 [LocalBuzzView] ProfileView appeared for userId: \(userId)")
                    }
                    .onDisappear {
                        print("🔍 [LocalBuzzView] ProfileView disappeared")
                        showingProfile = false
                        selectedUserId = nil
                    }
            }
        }
    }
}

// MARK: - Simple Feed Content
struct FeedContent: View {
    @ObservedObject var feedManager: FeedManager
    let apiService: APIService
    @ObservedObject var peopleSuggestionsManager: PeopleSuggestionsManager
    let primaryColor: Color
    let secondaryColor: Color
    let onProfileTap: (String) -> Void
    
    var body: some View {
        Group {
            if feedManager.isLoading {
                LoadingView()
            } else if let error = feedManager.errorMessage {
                ErrorView(error: error, onRetry: { feedManager.fetchFeed(filter: feedManager.filter) })
            } else if feedManager.items.isEmpty {
                FeedEmptyView()
            } else {
                FeedList(
                    feedManager: feedManager,
                    apiService: apiService,
                    peopleSuggestionsManager: peopleSuggestionsManager,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    onProfileTap: onProfileTap
                )
            }
        }
    }
}

// MARK: - Simple Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading...")
                .font(.body)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - Simple Error View
struct ErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text("Something went wrong")
                .font(.headline)
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Try Again", action: onRetry)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            Spacer()
        }
    }
}

// MARK: - Simple Empty View
struct FeedEmptyView: View {
    @State private var showingAddLocation = false
    @State private var showingAddBusiness = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Location Encouragement Card
            LocationEncouragementView(
                variant: .default,
                onAddLocation: { showingAddLocation = true },
                onAddBusiness: { showingAddBusiness = true }
            )
            
            // Original empty state
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("No posts yet")
                    .font(.headline)
                Text("Be the first to share something!")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .fullScreenCover(isPresented: $showingAddLocation) {
            EnhancedAddLocationView()
        }
        .fullScreenCover(isPresented: $showingAddBusiness) {
            EnhancedAddLocationView()
        }
    }
}

// MARK: - Simple Feed List
struct FeedList: View {
    @ObservedObject var feedManager: FeedManager
    let apiService: APIService
    @ObservedObject var peopleSuggestionsManager: PeopleSuggestionsManager
    let primaryColor: Color
    let secondaryColor: Color
    let onProfileTap: (String) -> Void
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if feedManager.filter == .all {
                    // Mixed feed - Use unified approach for posts
                    ForEach(Array(mixedItems.enumerated()), id: \.offset) { index, item in
                        switch item {
                        case .feedItem(let feedItem):
                            switch feedItem {
                            case .post(let post):
                                // Unified post processing - same as Posts tab
                                SimplePostCard(post: post, apiService: apiService, primaryColor: primaryColor, onProfileTap: onProfileTap)
                                    .environmentObject(feedManager)
                                    .onAppear {
                                        print("🔍 [FeedList] All tab - Post appeared: \(post.id)")
                                        print("🔍 [FeedList] All tab - Post media count: \(post.media?.count ?? 0)")
                                        if let media = post.media {
                                            for (i, m) in media.enumerated() {
                                                print("🔍 [FeedList] All tab - Media \(i): type=\(m.type), url=\(m.url)")
                                            }
                                        }
                                    }
                            case .place(let place):
                                SimplePlaceCard(place: place, primaryColor: primaryColor)
                            case .person(_):
                                EmptyView()
                            }
                        case .peopleSuggestion(let suggestion):
                            SimplePeopleCard(suggestion: suggestion, primaryColor: primaryColor, onProfileTap: onProfileTap)
                                .environmentObject(authManager)
                        }
                    }
                } else {
                    // Regular feed - Same unified approach
                    ForEach(feedManager.items) { item in
                        switch item {
                        case .post(let post):
                            SimplePostCard(post: post, apiService: apiService, primaryColor: primaryColor, onProfileTap: onProfileTap)
                                .environmentObject(feedManager)
                                .onAppear {
                                    print("🔍 [FeedList] Posts tab - Post appeared: \(post.id)")
                                    print("🔍 [FeedList] Posts tab - Post media count: \(post.media?.count ?? 0)")
                                    if let media = post.media {
                                        for (i, m) in media.enumerated() {
                                            print("🔍 [FeedList] Posts tab - Media \(i): type=\(m.type), url=\(m.url)")
                                        }
                                    }
                                }
                        case .place(let place):
                            SimplePlaceCard(place: place, primaryColor: primaryColor)
                        case .person(_):
                            EmptyView()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .coordinateSpace(name: "scroll")
    }
    
    private var mixedItems: [MixedFeedItem] {
        var items: [MixedFeedItem] = []
        
        for item in feedManager.items {
            items.append(.feedItem(item))
        }
        
        for suggestion in peopleSuggestionsManager.suggestions {
            let position = suggestion.position ?? "middle"
            let insertIndex: Int
            
            switch position {
            case "top":
                insertIndex = min(2, items.count)
            case "middle":
                insertIndex = max(2, items.count / 2)
            case "bottom":
                insertIndex = max(items.count - 2, items.count)
            default:
                insertIndex = items.count
            }
            
            items.insert(.peopleSuggestion(suggestion), at: min(insertIndex, items.count))
        }
        
        return items
    }
}

// MARK: - Filter Tabs
struct FilterTabs: View {
    @ObservedObject var feedManager: FeedManager
    @ObservedObject var peopleSuggestionsManager: PeopleSuggestionsManager
    let primaryColor: Color
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FeedFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            feedManager.filter = filter
                            Task {
                                await feedManager.refreshFeedWithInteractionSync(filter: filter)
                            }
                            if filter == .all {
                                peopleSuggestionsManager.fetchPeopleSuggestions(category: "all")
                            }
                        }
                    }) {
                        Text(filter.rawValue.capitalized)
                            .font(.system(size: 14, weight: feedManager.filter == filter ? .semibold : .medium))
                            .foregroundColor(feedManager.filter == filter ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(feedManager.filter == filter ? primaryColor : Color.gray.opacity(0.1))
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Simple Post Card
struct SimplePostCard: View {
    let post: FeedPost
    let apiService: APIService
    let primaryColor: Color
    let onProfileTap: (String) -> Void
    @EnvironmentObject var feedManager: FeedManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showComments = false
    @State private var currentImageIndex = 0
    @State private var showReportContent = false
    @State private var showingDeleteConfirmation = false
    @State private var postToDelete: FeedPost?
    
    @State private var showHeart = false
    @State private var heartTrigger = 0
    
    private var isLiked: Bool { post.engagement.isLiked }
    private var isSaved: Bool { post.engagement.isSaved }
    private var likeCount: Int { post.engagement.likeCount }
    private var commentCount: Int { post.engagement.commentCount }
    
    var imageMedia: [FeedMedia] { post.media?.filter { $0.type == "image" } ?? [] }
    var videoMedia: [FeedMedia] { post.media?.filter { $0.type == "video" } ?? [] }
    var hasMultipleImages: Bool { imageMedia.count > 1 }
    var hasVideo: Bool { !videoMedia.isEmpty }
    
    var cleanCaption: String? {
        let caption = post.caption.trimmingCharacters(in: .whitespacesAndNewlines)
        if caption.isEmpty || caption.lowercased().contains("shared from sacavia") {
            return nil
        }
        return caption
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // Profile image
                Group {
                    if let url = post.author.profileImage?.url, let imageUrl = absoluteMediaURL(url) {
                        AsyncImage(url: imageUrl) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(primaryColor.opacity(0.2))
                                .overlay(
                                    Text(getInitials(post.author.name))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(primaryColor)
                                )
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(primaryColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(getInitials(post.author.name))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(primaryColor)
                            )
                    }
                }
                .onTapGesture {
                    print("🔍 [LocalBuzzView] Profile image tapped for user: \(post.author.id)")
                    onProfileTap(post.author.id)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(formatDate(post.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .onTapGesture {
                    print("🔍 [LocalBuzzView] Profile name tapped for user: \(post.author.id)")
                    onProfileTap(post.author.id)
                }
                
                Spacer()
                
                // More options button
                Menu {
                    Button("Share") {
                        print("🔍 [LocalBuzzView] Share post menu item tapped")
                        sharePost(post: post)
                    }
                    
                    // Show delete option only for current user's posts
                    if authManager.user?.id == post.author.id {
                        Button("Delete", role: .destructive) {
                            print("🔍 [LocalBuzzView] Delete post menu item tapped")
                            deletePost(post: post)
                        }
                    } else {
                        Button("Block User", role: .destructive) {
                            print("🔍 [LocalBuzzView] Block user menu item tapped")
                            blockUserFromPost(post: post)
                        }
                        Button("Report", role: .destructive) {
                            print("🔍 [LocalBuzzView] Report post menu item tapped")
                            reportPost(post: post)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44) // Ensure minimum touch target
                }
                .buttonStyle(PlainButtonStyle()) // Ensure proper button interaction
                .onTapGesture {
                    print("🔍 [LocalBuzzView] Post menu button tapped")
                }
            }
            
            // Media content
            if hasVideo {
                ZStack {
                    if let firstVideo = videoMedia.first, let videoUrl = absoluteMediaURL(firstVideo.url) {
                        AutoplayVideoPlayer(videoUrl: videoUrl, enableAudio: true, loop: true)
                            .frame(height: 250)
                            .cornerRadius(12)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "video.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("Video not available")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    DoubleTapLikeOverlay(trigger: heartTrigger, isVisible: showHeart)
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    doubleTapLike()
                }
            } else if !imageMedia.isEmpty {
                ZStack {
                    TabView(selection: $currentImageIndex) {
                        ForEach(Array(imageMedia.enumerated()), id: \.offset) { index, media in
                            if let imageUrl = absoluteMediaURL(media.url) {
                                AsyncImage(url: imageUrl) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle().fill(Color.gray.opacity(0.1))
                                }
                                .frame(height: 250)
                                .clipped()
                                .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: hasMultipleImages ? .automatic : .never))
                    .frame(height: 250)
                    .cornerRadius(12)

                    DoubleTapLikeOverlay(trigger: heartTrigger, isVisible: showHeart)
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    doubleTapLike()
                }
            }
            
            // Location (if provided and not private)
            if let location = post.location, let name = location.name, !(location.privacy?.lowercased() == "private") {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.secondary)
                    Text(name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
            }
            
            // Caption
            if let caption = cleanCaption, !caption.isEmpty {
                Text(caption)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
            }
            
            // Categories
            if !post.categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(post.categories.prefix(3), id: \.self) { category in
                            Text(category)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(primaryColor)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            // Actions
            HStack(spacing: 24) {
                Button(action: handleLike) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .primary)
                        Text("\(likeCount)")
                            .font(.system(size: 14))
                    }
                }
                .frame(minHeight: 44) // Ensure minimum touch target
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showComments = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.primary)
                        Text("\(commentCount)")
                            .font(.system(size: 14))
                    }
                }
                .frame(minHeight: 44) // Ensure minimum touch target
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: handleSave) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isSaved ? primaryColor : .primary)
                }
                .frame(width: 44, height: 44) // Ensure minimum touch target
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .fullScreenCover(isPresented: $showComments) {
            SimpleCommentModal(
                postId: post.id,
                commentCount: Binding.constant(commentCount),
                apiService: apiService,
                primaryColor: primaryColor
            )
        }

        .fullScreenCover(isPresented: $showReportContent) {
            ReportContentView(
                contentType: "post",
                contentId: post.id,
                contentTitle: post.caption
            )
        }
        .alert("Delete Post", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                postToDelete = nil
            }
            Button("Delete", role: .destructive) {
                confirmDeletePost()
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
    }
    
    private func doubleTapLike() {
        // Trigger animation
        heartTrigger += 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showHeart = true
        }
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // Perform like if not already liked
        if !isLiked {
            Task {
                do {
                    try await apiService.likePost(postId: post.id)
                    feedManager.updatePostLikeState(postId: post.id, isLiked: true)
                } catch {
                    print("Double-tap like failed: \(error)")
                }
            }
        }
        // Auto hide overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.2)) {
                showHeart = false
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
    
    private func handleLike() {
        Task {
            do {
                if isLiked {
                    try await apiService.unlikePost(postId: post.id)
                } else {
                    try await apiService.likePost(postId: post.id)
                }
                feedManager.updatePostLikeState(postId: post.id, isLiked: !isLiked)
            } catch {
                print("Like/Unlike failed: \(error)")
            }
        }
    }
    
    private func handleSave() {
        Task {
            do {
                if isSaved {
                    try await apiService.unsavePost(postId: post.id)
                } else {
                    try await apiService.savePost(postId: post.id)
                }
                feedManager.updatePostSaveState(postId: post.id, isSaved: !isSaved)
            } catch {
                print("Save/Unsave failed: \(error)")
            }
        }
    }
    
    // MARK: - Post Actions
    
    private func sharePost(post: FeedPost) {
        print("🔍 [LocalBuzzView] Sharing post: \(post.id)")
        
        // Create shareable URL
        let baseURL = "https://sacavia.com"
        let postURL = "\(baseURL)/post/\(post.id)"
        
        // Create enhanced share content
        let shareTitle = "Check out this post by \(post.author.name) on Sacavia"
        let shareText = createEnhancedShareText(for: post)
        let hashtags = createHashtags(for: post)
        
        // Safely create URL
        guard let url = URL(string: postURL) else {
            print("🔍 [LocalBuzzView] Failed to create URL for sharing: \(postURL)")
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
                
                print("🔍 [LocalBuzzView] Presenting share sheet from: \(type(of: topViewController))")
                topViewController.present(activityVC, animated: true) {
                    print("🔍 [LocalBuzzView] Share sheet presented successfully")
                    
                    // Track share event (you could add analytics here)
                    self.trackShareEvent(for: post)
                }
            } else {
                print("🔍 [LocalBuzzView] Failed to present share sheet - no root view controller found")
            }
        }
    }
    
    private func createEnhancedShareText(for post: FeedPost) -> String {
        var shareText = ""
        
        // Add post content
        if !post.caption.isEmpty {
            let truncatedCaption = post.caption.count > 150 ? String(post.caption.prefix(150)) + "..." : post.caption
            shareText += truncatedCaption
        }
        
        // Add location if available
        if let location = post.location, let locationName = location.name, !(location.privacy?.lowercased() == "private") {
            shareText += "\n📍 \(locationName)"
        }
        
        // Add categories if available
        if !post.categories.isEmpty {
            let categoryText = post.categories.prefix(3).joined(separator: ", ")
            shareText += "\n🏷️ \(categoryText)"
        }
        
        return shareText
    }
    
    private func createHashtags(for post: FeedPost) -> String {
        var hashtags: [String] = ["#Sacavia"]
        
        // Add category hashtags
        for category in post.categories.prefix(3) {
            let hashtag = "#\(category.replacingOccurrences(of: " ", with: ""))"
            hashtags.append(hashtag)
        }
        
        // Add location hashtag if available
        if let location = post.location, let locationName = location.name, !(location.privacy?.lowercased() == "private") {
            let locationHashtag = "#\(locationName.replacingOccurrences(of: " ", with: ""))"
            hashtags.append(locationHashtag)
        }
        
        return hashtags.joined(separator: " ")
    }
    
    private func trackShareEvent(for post: FeedPost) {
        // You can add analytics tracking here
        print("📊 [LocalBuzzView] Post shared: \(post.id) by \(post.author.name)")
        
        // Update share count in the feed manager
        Task {
            await feedManager.incrementShareCount(postId: post.id)
        }
    }
    
    private func reportPost(post: FeedPost) {
        print("🔍 [LocalBuzzView] Reporting post: \(post.id)")
        showReportContent = true
    }
    
    private func blockUserFromPost(post: FeedPost) {
        print("🔍 [LocalBuzzView] Blocking user from post: \(post.author.id)")
        // Show BlockUserView for the post author
        // Note: This would need to be implemented with a sheet or fullScreenCover
        // For now, we'll just add the user to the blocked list
        feedManager.addBlockedUser(post.author.id)
    }
    
    private func deletePost(post: FeedPost) {
        print("🔍 [LocalBuzzView] Requesting to delete post: \(post.id)")
        postToDelete = post
        showingDeleteConfirmation = true
    }
    
    private func confirmDeletePost() {
        guard let post = postToDelete else { return }
        print("🔍 [LocalBuzzView] Confirming deletion of post: \(post.id)")
        Task {
            await feedManager.deletePost(postId: post.id)
        }
        postToDelete = nil
    }
}


// MARK: - Simple Place Card
struct SimplePlaceCard: View {
    @EnvironmentObject var authManager: AuthManager
    let place: FeedPlace
    let primaryColor: Color
    @State private var showLocationDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                Circle()
                    .fill(primaryColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(primaryColor)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name ?? "Unknown Place")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let category = place.categories?.first {
                        Text(category)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Image
            if let imageUrl = absoluteMediaURL(place.photo ?? place.image ?? "") {
                AsyncImage(url: imageUrl) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.1))
                }
                .frame(height: 200)
                .cornerRadius(12)
            }
            
            // Description
            if let description = place.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(3)
            }
            
            // Categories
            if let categories = place.categories, !categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories.prefix(3), id: \.self) { category in
                            Text(category)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(primaryColor)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            showLocationDetail = true
        }
        .fullScreenCover(isPresented: $showLocationDetail) {
            EnhancedLocationDetailView(locationId: place.id)
                .environmentObject(authManager)
        }
    }
}

// MARK: - Simple People Card
struct SimplePeopleCard: View {
    let suggestion: PeopleSuggestionCategory
    let primaryColor: Color
    let onProfileTap: (String) -> Void
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: suggestion.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(suggestion.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Users
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(suggestion.users.prefix(4)) { user in
                    SimpleUserCard(
                        user: user,
                        primaryColor: primaryColor,
                        onViewProfile: onProfileTap
                    )
                    .environmentObject(authManager)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Simple User Card
struct SimpleUserCard: View {
    let user: EnhancedFeedPerson
    let primaryColor: Color
    let onViewProfile: (String) -> Void
    @State private var isFollowing: Bool
    @State private var isLoading = false
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var apiService = APIService()
    
    init(user: EnhancedFeedPerson, primaryColor: Color, onViewProfile: @escaping (String) -> Void) {
        self.user = user
        self.primaryColor = primaryColor
        self.onViewProfile = onViewProfile
        self._isFollowing = State(initialValue: user.isFollowing)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let profileImageUrl = user.profileImage, let imageUrl = absoluteMediaURL(profileImageUrl) {
                    AsyncImage(url: imageUrl) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(primaryColor.opacity(0.2))
                            .overlay(
                                Text(getInitials(user.name))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(primaryColor)
                            )
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(primaryColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(getInitials(user.name))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(primaryColor)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if user.mutualFollowers > 0 {
                        Text("\(user.mutualFollowers) mutual")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            HStack(spacing: 6) {
                Button(action: { 
                    print("🔍 [SimpleUserCard] View button tapped for user: \(user.id)")
                    onViewProfile(user.id) 
                }) {
                    Text("View")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
                .frame(minHeight: 32) // Ensure minimum touch target
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: handleFollow) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 20, height: 20)
                    } else {
                        Text(isFollowing ? "Following" : "Follow")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(isFollowing ? .secondary : .white)
                    }
                }
                .disabled(isLoading)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(isFollowing ? Color.gray.opacity(0.1) : primaryColor)
                .cornerRadius(6)
                .frame(minHeight: 32) // Ensure minimum touch target
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
    
    private func handleFollow() {
        guard !isLoading else { return }
        
        isLoading = true
        let newFollowState = !isFollowing
        
        // Optimistic update
        isFollowing = newFollowState
        
        Task {
            do {
                if newFollowState {
                    // Follow user
                    let success = try await apiService.followUser(userId: user.id)
                    if success {
                        print("✅ Successfully followed user: \(user.id)")
                        // Update AuthManager state for real-time updates
                        AuthManager.shared.updateFollowState(targetUserId: user.id, isFollowing: true)
                    } else {
                        print("❌ Follow failed for user: \(user.id)")
                    }
                } else {
                    // Unfollow user
                    let success = try await apiService.unfollowUser(userId: user.id)
                    if success {
                        print("✅ Successfully unfollowed user: \(user.id)")
                        // Update AuthManager state for real-time updates
                        AuthManager.shared.updateFollowState(targetUserId: user.id, isFollowing: false)
                    } else {
                        print("❌ Unfollow failed for user: \(user.id)")
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                print("❌ Follow/Unfollow failed for user \(user.id): \(error)")
                
                // Revert optimistic update on error
                await MainActor.run {
                    isFollowing = !newFollowState
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Simple Comment Modal
struct SimpleCommentModal: View {
    let postId: String
    @Binding var commentCount: Int
    let apiService: APIService
    let primaryColor: Color
    @State private var comments: [Comment] = []
    @State private var isLoading: Bool = false
    @State private var newCommentText: String = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView("Loading comments...")
                        .padding(.top, 40)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(comments) { comment in
                                SimpleCommentView(comment: comment, primaryColor: primaryColor)
                                Divider()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
                
                Divider()
                VStack(spacing: 12) {
                    // TikTok-style comment input
                    MentionInputView(
                        text: $newCommentText,
                        placeholder: "Add a comment...",
                        maxLength: 500
                    )
                    
                    // Send button - TikTok style
                    HStack {
                        Spacer()
                        Button(action: submitComment) {
                            HStack(spacing: 6) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Send")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : primaryColor)
                            )
                        }
                        .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onAppear {
                fetchComments()
            }
        }
    }

    private func fetchComments() {
        isLoading = true
        Task {
            do {
                let fetchedComments = try await apiService.fetchComments(postId: postId)
                comments = fetchedComments
            } catch {
                print("Failed to fetch comments: \(error)")
            }
            isLoading = false
        }
    }

    private func submitComment() {
        guard !newCommentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let content = newCommentText
        newCommentText = ""
        commentCount += 1
        
        Task {
            do {
                try await apiService.addComment(postId: postId, content: content, parentId: nil)
                fetchComments()
            } catch {
                print("Failed to submit comment: \(error)")
            }
        }
    }
}

// MARK: - Simple Comment View
struct SimpleCommentView: View {
    let comment: Comment
    let primaryColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(primaryColor.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(comment.authorName.prefix(2).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(primaryColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(.system(size: 14, weight: .semibold))
                    Text(formatTimeAgo(comment.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                MentionDisplayView(text: comment.content)
                    .font(.system(size: 14))
            }
            
            Spacer()
        }
    }
    
    private func formatTimeAgo(_ dateString: String) -> String {
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

// MARK: - Mixed Feed Item
enum MixedFeedItem {
    case feedItem(FeedItem)
    case peopleSuggestion(PeopleSuggestionCategory)
}

// MARK: - Enhanced People Suggestions Helpers
extension LocalBuzzView {
    func convertToEnhancedPerson(_ person: FeedPerson) -> EnhancedFeedPerson? {
        return EnhancedFeedPerson(
            id: person.id,
            name: person.name ?? "Unknown User",
            username: person.username,
            bio: person.bio ?? "",
            profileImage: person.profileImage,
            location: person.location,
            distance: person.distance,
            mutualFollowers: person.mutualFollowers ?? 0,
            mutualFollowersList: person.mutualFollowersList,
            followersCount: person.followersCount ?? 0,
            followingCount: person.followingCount ?? 0,
            isFollowing: person.isFollowing ?? false,
            isFollowedBy: person.isFollowedBy ?? false,
            isCreator: person.isCreator ?? false,
            isVerified: person.isVerified ?? false,
            suggestionScore: Double(person.suggestionScore ?? 0),
            createdAt: person.createdAt ?? "",
            updatedAt: person.updatedAt ?? "",
            lastLogin: person.lastLogin
        )
    }
    
    func handleFollowUser(_ userId: String) {
        Task {
            do {
                _ = try await apiService.followUser(userId: userId)
                print("Successfully followed user: \(userId)")
            } catch {
                print("Error following user: \(error)")
            }
        }
    }
} 
