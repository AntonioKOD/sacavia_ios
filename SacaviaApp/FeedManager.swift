import Foundation
import SwiftUI

// MARK: - Polymorphic Feed Item Enum

enum FeedItem: Identifiable {
    case post(FeedPost)
    case place(FeedPlace)
    case person(FeedPerson)

    var id: String {
        switch self {
        case .post(let post): return post.id
        case .place(let place): return place.id
        case .person(let person): return person.id
        }
    }

    static func from(_ dict: [String: Any]) -> FeedItem? {
        guard let type = dict["type"] as? String else { 
            print("⚠️ No type field in feed item:", dict.keys)
            return nil 
        }
        
        print("🔍 Processing feed item type:", type)
        
        do {
            let data = try JSONSerialization.data(withJSONObject: dict)
            let decoder = JSONDecoder()
            switch type {
            case "post":
                let post = try decoder.decode(FeedPost.self, from: data)
                print("✅ Successfully decoded post:", post.id)
                return .post(post)
            case "place_recommendation":
                do {
                    let place = try decoder.decode(FeedPlace.self, from: data)
                    print("✅ Successfully decoded place:", place.id)
                    return .place(place)
                } catch {
                    print("❌ FeedPlace decode error:", error)
                    print("📋 FeedPlace raw dict keys:", dict.keys)
                    return nil
                }
            case "people_suggestion":
                // Handle people_suggestion items which contain a users array
                if let users = dict["users"] as? [[String: Any]], let firstUser = users.first {
                    print("👥 Processing people_suggestion with users array (count: \(users.count))")
                    do {
                        let userData = try JSONSerialization.data(withJSONObject: firstUser)
                        let person = try decoder.decode(FeedPerson.self, from: userData)
                        print("✅ Successfully decoded person from users array:", person.id)
                        return .person(person)
                    } catch {
                        print("❌ FeedPerson decode error (from users array):", error)
                        print("📋 First user keys:", firstUser.keys)
                        return nil
                    }
                } else {
                    // Fallback: try to decode as single person
                    print("👤 Processing people_suggestion as single person")
                    do {
                        let person = try decoder.decode(FeedPerson.self, from: data)
                        print("✅ Successfully decoded single person:", person.id)
                        return .person(person)
                    } catch {
                        print("❌ FeedPerson decode error (single person):", error)
                        print("📋 Person dict keys:", dict.keys)
                        return nil
                    }
                }
            default:
                print("❓ Unknown feed item type:", type)
                return nil
            }
        } catch {
            print("❌ FeedItem decode error:", error)
            print("📋 FeedItem raw dict keys:", dict.keys)
            return nil
        }
    }
}

struct AnyDecodable: Decodable {
    let value: Any
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) { value = intVal; return }
        if let doubleVal = try? container.decode(Double.self) { value = doubleVal; return }
        if let boolVal = try? container.decode(Bool.self) { value = boolVal; return }
        if let stringVal = try? container.decode(String.self) { value = stringVal; return }
        if let dictVal = try? container.decode([String: AnyDecodable].self) { value = dictVal.mapValues { $0.value }; return }
        if let arrVal = try? container.decode([AnyDecodable].self) { value = arrVal.map { $0.value }; return }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown type")
    }
}

// MARK: - Feed Models

struct FeedPost: Codable, Identifiable {
    let id: String
    let caption: String
    let author: FeedAuthor
    let location: FeedLocation?
    let media: [FeedMedia]?
    let engagement: FeedEngagement
    let categories: [String]
    let tags: [String]
    let createdAt: String
    let updatedAt: String
    let rating: Double?
    let isPromoted: Bool?
    // Add privacy for location if available
    var locationPrivacy: String? {
        location?.privacy
    }
}

struct FeedPlace: Decodable, Identifiable {
    let id: String
    let name: String?
    let description: String?
    let photo: String? // <-- new main photo field
    let image: String?
    let rating: Double?
    let categories: [String]?
    let location: FeedCoordinates?
    let address: String?
    let createdAt: String?
    let updatedAt: String?
    let isPromoted: Bool?
    let privacy: String?
    
    // Remove the type field since it's not in the individual place objects
    // The type is only in the wrapper object
}

struct CategoryObject: Codable {
    let name: String?
    let slug: String?
}

struct AddressObject: Codable {
    let street: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    var fullAddress: String {
        [street, city, state, zip, country].compactMap { $0 }.joined(separator: ", ")
    }
}

struct FeedPerson: Decodable, Identifiable {
    let id: String
    let name: String?
    let username: String?
    let bio: String?
    let profileImage: String?
    let location: FeedCoordinates?
    let distance: Double?
    let mutualFollowers: Int?
    let mutualFollowersList: [String]?
    let followersCount: Int?
    let followingCount: Int?
    let isFollowing: Bool?
    let isFollowedBy: Bool?
    let isCreator: Bool?
    let isVerified: Bool?
    let suggestionScore: Int?
    let createdAt: String?
    let updatedAt: String?
    let lastLogin: String?
    
    // Remove the type field since it's not in the individual user objects
    // The type is only in the wrapper object
}

struct FeedAuthor: Codable {
    let id: String
    let name: String
    let profileImage: FeedProfileImage?
}

struct FeedProfileImage: Codable {
    let url: String
}

struct FeedLocation: Codable {
    let id: String?
    let name: String?
    let coordinates: FeedCoordinates?
    let privacy: String?
}

struct FeedCoordinates: Codable {
    let latitude: Double
    let longitude: Double
}

struct FeedMedia: Codable {
    let type: String // "image" or "video"
    let url: String
    let thumbnail: String?
    let duration: Double?
    let alt: String?
}

struct FeedEngagement: Codable {
    let likeCount: Int
    let commentCount: Int
    let shareCount: Int
    let saveCount: Int
    let isLiked: Bool
    let isSaved: Bool
}

struct FeedPagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrev: Bool
    let nextCursor: String?
}

struct FeedMeta: Codable {
    let feedType: String
    let appliedFilters: FeedAppliedFilters
    let recommendations: [String]?
}

struct FeedAppliedFilters: Codable {
    let category: String?
    let sortBy: String
}

struct FeedResponse: Decodable {
    let success: Bool
    let message: String
    let data: FeedData?
    let error: String?
    let code: String?
}

// MARK: - Feed Item Types for People Suggestions

struct PeopleSuggestionItem: Decodable {
    let type: String // "people_suggestion"
    let category: String // "nearby", "mutual", "suggested"
    let title: String
    let subtitle: String
    let users: [EnhancedFeedPerson]
}

struct FeedData: Decodable {
    let posts: [AnyDecodable] // Raw posts that can be any type
    let pagination: FeedPagination
    let meta: FeedMeta

    enum CodingKeys: String, CodingKey {
        case posts, pagination, meta
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.posts = try container.decode([AnyDecodable].self, forKey: .posts)
        self.pagination = try container.decode(FeedPagination.self, forKey: .pagination)
        self.meta = try container.decode(FeedMeta.self, forKey: .meta)
    }
}

enum FeedFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case posts = "Posts"
    case places = "Places"
    case people = "People"
    var id: String { self.rawValue }
    var includeTypes: String? {
        switch self {
        case .all:
            return nil // Do not send includeTypes param for All
        case .posts:
            return "post"
        case .places:
            return "place_recommendation"
        case .people:
            return "people_suggestion"
        }
    }
}

class FeedManager: ObservableObject {
    @Published var items: [FeedItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filter: FeedFilter = .all
    @Published var blockedUserIds: Set<String> = []
    
    private let authManager = AuthManager.shared
    private var postDeletionObserver: NSObjectProtocol?
    private var postCreationObserver: NSObjectProtocol?
    
    init() {
        // Set up notification observer for post deletions from other parts of the app
        postDeletionObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PostDeleted"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let userInfo = notification.userInfo,
               let postId = userInfo["postId"] as? String {
                print("🔍 [FeedManager] Received post deletion notification for post: \(postId)")
                
                // Remove the post from the feed items
                self?.items.removeAll { item in
                    switch item {
                    case .post(let post):
                        return post.id == postId
                    default:
                        return false
                    }
                }
                
                print("🗑️ [FeedManager] Removed post \(postId) from feed")
            }
        }
        
        // Set up notification observer for post creation
        postCreationObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PostCreated"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let userInfo = notification.userInfo,
               let success = userInfo["success"] as? Bool, success {
                print("🔍 [FeedManager] Received post creation notification")
                
                // Refresh the feed to show the new post
                Task {
                    await self?.refreshFeedWithInteractionSync()
                    print("🔄 [FeedManager] Feed refreshed after post creation")
                }
            }
        }
    }
    
    deinit {
        // Remove notification observers
        if let observer = postDeletionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = postCreationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Engagement State Management
    func updatePostLikeState(postId: String, isLiked: Bool) {
        DispatchQueue.main.async {
            for i in 0..<self.items.count {
                switch self.items[i] {
                case .post(let post):
                    if post.id == postId {
                        // Create updated post with new like state
                        let updatedPost = FeedPost(
                            id: post.id,
                            caption: post.caption,
                            author: post.author,
                            location: post.location,
                            media: post.media,
                            engagement: FeedEngagement(
                                likeCount: post.engagement.likeCount + (isLiked ? 1 : -1),
                                commentCount: post.engagement.commentCount,
                                shareCount: post.engagement.shareCount,
                                saveCount: post.engagement.saveCount,
                                isLiked: isLiked,
                                isSaved: post.engagement.isSaved
                            ),
                            categories: post.categories,
                            tags: post.tags,
                            createdAt: post.createdAt,
                            updatedAt: post.updatedAt,
                            rating: post.rating,
                            isPromoted: post.isPromoted
                        )
                        self.items[i] = .post(updatedPost)
                        print("📱 Updated like state for post \(postId): isLiked=\(isLiked)")
                        break
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func restoreEngagementStates(from previousStates: [(String, Bool, Bool)]) {
        let stateDict = Dictionary(uniqueKeysWithValues: previousStates.map { ($0.0, ($0.1, $0.2)) })
        
        for i in 0..<self.items.count {
            switch self.items[i] {
            case .post(let post):
                if let (wasLiked, wasSaved) = stateDict[post.id] {
                    // Only update if the state was different from the backend
                    if post.engagement.isLiked != wasLiked || post.engagement.isSaved != wasSaved {
                        let updatedPost = FeedPost(
                            id: post.id,
                            caption: post.caption,
                            author: post.author,
                            location: post.location,
                            media: post.media,
                            engagement: FeedEngagement(
                                likeCount: wasLiked ? max(1, post.engagement.likeCount) : post.engagement.likeCount,
                                commentCount: post.engagement.commentCount,
                                shareCount: post.engagement.shareCount,
                                saveCount: wasSaved ? max(1, post.engagement.saveCount) : post.engagement.saveCount,
                                isLiked: wasLiked,
                                isSaved: wasSaved
                            ),
                            categories: post.categories,
                            tags: post.tags,
                            createdAt: post.createdAt,
                            updatedAt: post.updatedAt,
                            rating: post.rating,
                            isPromoted: post.isPromoted
                        )
                        self.items[i] = .post(updatedPost)
                        print("📱 Restored engagement state for post \(post.id): isLiked=\(wasLiked), isSaved=\(wasSaved)")
                    }
                }
            default:
                break
            }
        }
    }
    
    func updatePostSaveState(postId: String, isSaved: Bool) {
        DispatchQueue.main.async {
            for i in 0..<self.items.count {
                switch self.items[i] {
                case .post(let post):
                    if post.id == postId {
                        // Create updated post with new save state
                        let updatedPost = FeedPost(
                            id: post.id,
                            caption: post.caption,
                            author: post.author,
                            location: post.location,
                            media: post.media,
                            engagement: FeedEngagement(
                                likeCount: post.engagement.likeCount,
                                commentCount: post.engagement.commentCount,
                                shareCount: post.engagement.shareCount,
                                saveCount: post.engagement.saveCount + (isSaved ? 1 : -1),
                                isLiked: post.engagement.isLiked,
                                isSaved: isSaved
                            ),
                            categories: post.categories,
                            tags: post.tags,
                            createdAt: post.createdAt,
                            updatedAt: post.updatedAt,
                            rating: post.rating,
                            isPromoted: post.isPromoted
                        )
                        self.items[i] = .post(updatedPost)
                        print("📱 Updated save state for post \(postId): isSaved=\(isSaved)")
                        break
                    }
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Interaction State Syncing
    
    func syncInteractionStates() async {
        // Get all post IDs from current feed
        let postIds = items.compactMap { item -> String? in
            switch item {
            case .post(let post):
                return post.id
            default:
                return nil
            }
        }
        
        guard !postIds.isEmpty else {
            print("📱 No posts to sync interaction states for")
            return
        }
        
        print("📱 Syncing interaction states for \(postIds.count) posts: \(postIds)")
        
        do {
            let apiService = APIService()
            let response = try await apiService.checkInteractionState(postIds: postIds)
            
            guard let data = response.data else {
                print("📱 No interaction state data received")
                return
            }
            
            print("📱 Received interaction data for \(data.interactions.count) posts")
            print("📱 Total liked: \(data.totalLiked), Total saved: \(data.totalSaved)")
            
            // Update feed items with correct interaction states
            DispatchQueue.main.async {
                var updatedCount = 0
                for interaction in data.interactions {
                    for i in 0..<self.items.count {
                        switch self.items[i] {
                        case .post(let post):
                            if post.id == interaction.postId {
                                print("📱 Checking post \(interaction.postId): current isLiked=\(post.engagement.isLiked), server isLiked=\(interaction.isLiked)")
                                
                                // Only update if the state is different
                                if post.engagement.isLiked != interaction.isLiked || 
                                   post.engagement.isSaved != interaction.isSaved ||
                                   post.engagement.likeCount != interaction.likeCount ||
                                   post.engagement.saveCount != interaction.saveCount {
                                    
                                    let updatedPost = FeedPost(
                                        id: post.id,
                                        caption: post.caption,
                                        author: post.author,
                                        location: post.location,
                                        media: post.media,
                                        engagement: FeedEngagement(
                                            likeCount: interaction.likeCount,
                                            commentCount: post.engagement.commentCount,
                                            shareCount: post.engagement.shareCount,
                                            saveCount: interaction.saveCount,
                                            isLiked: interaction.isLiked,
                                            isSaved: interaction.isSaved
                                        ),
                                        categories: post.categories,
                                        tags: post.tags,
                                        createdAt: post.createdAt,
                                        updatedAt: post.updatedAt,
                                        rating: post.rating,
                                        isPromoted: post.isPromoted
                                    )
                                    self.items[i] = .post(updatedPost)
                                    updatedCount += 1
                                    print("📱 ✅ Updated interaction state for post \(interaction.postId): isLiked=\(interaction.isLiked), isSaved=\(interaction.isSaved)")
                                } else {
                                    print("📱 ⏭️ No update needed for post \(interaction.postId): states match")
                                }
                                break
                            }
                        default:
                            break
                        }
                    }
                }
                print("📱 Updated \(updatedCount) posts with new interaction states")
            }
            
            print("📱 Successfully synced interaction states for \(data.interactions.count) posts")
            
        } catch {
            print("📱 Failed to sync interaction states: \(error)")
        }
    }
    
    // MARK: - Enhanced Feed Refresh with Interaction State Sync
    
    func refreshFeedWithInteractionSync(filter: FeedFilter? = nil) async {
        print("📱 Starting enhanced feed refresh with interaction sync")
        
        // Check authentication first
        guard authManager.isAuthenticated,
              let _ = authManager.getValidToken() else {
            print("📱 Authentication required for feed refresh")
            return
        }
        
        // Clear current feed to force fresh data
        DispatchQueue.main.async {
            self.items = []
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // First, fetch the feed normally
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.fetchFeed(filter: filter)
                continuation.resume()
            }
        }
        
        // Wait a bit for the feed to load
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds to ensure feed loads
        
        // Then sync interaction states
        await syncInteractionStates()
        
        print("📱 Enhanced feed refresh completed")
    }
    
    // MARK: - Force Refresh After Login
    
    func forceRefreshAfterLogin() async {
        print("📱 Force refreshing feed after login")
        
        // Clear everything and start fresh
        DispatchQueue.main.async {
            self.items = []
            self.isLoading = false
            self.errorMessage = nil
        }
        
        // Wait a moment for the UI to update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Refresh with interaction sync
        await refreshFeedWithInteractionSync()
    }
    
    // MARK: - Clear Feed After Logout
    
    func clearFeedAfterLogout() {
        print("📱 Clearing feed after logout")
        
        DispatchQueue.main.async {
            self.items = []
            self.isLoading = false
            self.errorMessage = nil
        }
    }

    func fetchFeed(filter: FeedFilter? = nil) {
        // Check authentication first
        guard authManager.isAuthenticated,
              let token = authManager.getValidToken() else {
            DispatchQueue.main.async {
                self.errorMessage = "Authentication required. Please log in."
            }
            return
        }
        
        print("📱 [FeedManager] Fetching feed with token: \(token.prefix(10))...")
        
        // Store current engagement states before fetching
        let currentEngagementStates = self.items.compactMap { item -> (String, Bool, Bool)? in
            switch item {
            case .post(let post):
                return (post.id, post.engagement.isLiked, post.engagement.isSaved)
            default:
                return nil
            }
        }
        
        let filterToUse = filter ?? self.filter
        var urlString = "\(baseAPIURL)/api/mobile/posts/feed"
        if let includeTypes = filterToUse.includeTypes {
            urlString += "?includeTypes=\(includeTypes)"
        }
        print("Fetching feed from:", urlString) // Debug print
        guard let url = URL(string: urlString) else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Use authenticated request
        let request = authManager.createAuthenticatedRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                
                // Check for authentication errors
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 401 {
                    self.errorMessage = "Authentication expired. Please log in again."
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    print("📱 Feed response JSON:", json?.keys ?? [])
                    
                    guard let dataDict = json?["data"] as? [String: Any] else {
                        print("❌ No data field in response")
                        self.errorMessage = "Malformed response - no data field"
                        return
                    }
                    
                    guard let postsArray = dataDict["posts"] as? [[String: Any]] else {
                        print("❌ No posts array in data")
                        self.errorMessage = "Malformed response - no posts array"
                        return
                    }
                    
                    print("📱 Processing \(postsArray.count) feed items")
                    
                    let allItems = postsArray.compactMap { dict in
                        let item = FeedItem.from(dict)
                        if item == nil {
                            print("⚠️ Failed to decode feed item:", dict["type"] ?? "unknown type")
                        }
                        return item
                    }
                    
                    print("📱 Successfully decoded \(allItems.count) items out of \(postsArray.count)")
                    
                    // Only filter out private places in the places tab
                    if filterToUse == .places {
                        self.items = allItems.filter { item in
                            switch item {
                            case .place(let place):
                                return place.privacy?.lowercased() != "private"
                            default:
                                return false // Only show places in the places tab
                            }
                        }
                    } else {
                        self.items = allItems
                    }
                    
                    print("📱 Final items count: \(self.items.count)")
                    
                    // Restore engagement states for posts that were previously updated
                    self.restoreEngagementStates(from: currentEngagementStates)
                } catch {
                    print("❌ Feed decoding error:", error)
                    self.errorMessage = error.localizedDescription
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Blocking Functionality
    
    func loadBlockedUsers() async {
        do {
            let apiService = APIService()
            let blockedUsers = try await apiService.getBlockedUsers()
            DispatchQueue.main.async {
                self.blockedUserIds = Set(blockedUsers)
                print("🔒 Loaded \(blockedUsers.count) blocked users")
            }
        } catch {
            print("🔒 Failed to load blocked users: \(error)")
        }
    }
    
    func addBlockedUser(_ userId: String) {
        DispatchQueue.main.async {
            self.blockedUserIds.insert(userId)
            print("🔒 Added user \(userId) to blocked list")
            self.filterOutBlockedContent()
        }
    }
    
    func removeBlockedUser(_ userId: String) {
        DispatchQueue.main.async {
            self.blockedUserIds.remove(userId)
            print("🔒 Removed user \(userId) from blocked list")
        }
    }
    
    func filterOutBlockedContent() {
        DispatchQueue.main.async {
            let originalCount = self.items.count
            self.items = self.items.filter { item in
                switch item {
                case .post(let post):
                    return !self.blockedUserIds.contains(post.author.id)
                case .place(let place):
                    // Places don't have authors, so they're not filtered by blocking
                    return true
                case .person(let person):
                    return !self.blockedUserIds.contains(person.id)
                }
            }
            let filteredCount = self.items.count
            if originalCount != filteredCount {
                print("🔒 Filtered out \(originalCount - filteredCount) items from blocked users")
            }
        }
    }
    
    func isUserBlocked(_ userId: String) -> Bool {
        return blockedUserIds.contains(userId)
    }
    
    func refreshBlockedUsers() async {
        await loadBlockedUsers()
    }
    
    // MARK: - Post Deletion
    
    func deletePost(postId: String) async {
        do {
            let apiService = APIService()
            try await apiService.deletePost(postId: postId)
            
            // Remove the post from the local feed
            DispatchQueue.main.async {
                self.items.removeAll { item in
                    switch item {
                    case .post(let post):
                        return post.id == postId
                    default:
                        return false
                    }
                }
                print("🗑️ Successfully deleted post \(postId) from feed")
                
                // Notify other parts of the app about the post deletion
                NotificationCenter.default.post(
                    name: NSNotification.Name("PostDeleted"),
                    object: nil,
                    userInfo: ["postId": postId]
                )
                print("📢 [FeedManager] Posted PostDeleted notification for post: \(postId)")
            }
        } catch {
            print("🗑️ Failed to delete post \(postId): \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to delete post. Please try again."
            }
        }
    }
    
    // MARK: - Share Count Management
    
    func incrementShareCount(postId: String) async {
        print("📊 [FeedManager] Incrementing share count for post: \(postId)")
        
        // Update the share count in the local feed
        for i in 0..<items.count {
            switch items[i] {
            case .post(let post):
                if post.id == postId {
                    let updatedPost = FeedPost(
                        id: post.id,
                        caption: post.caption,
                        author: post.author,
                        location: post.location,
                        media: post.media,
                        engagement: FeedEngagement(
                            likeCount: post.engagement.likeCount,
                            commentCount: post.engagement.commentCount,
                            shareCount: post.engagement.shareCount + 1,
                            saveCount: post.engagement.saveCount,
                            isLiked: post.engagement.isLiked,
                            isSaved: post.engagement.isSaved
                        ),
                        categories: post.categories,
                        tags: post.tags,
                        createdAt: post.createdAt,
                        updatedAt: post.updatedAt,
                        rating: post.rating,
                        isPromoted: post.isPromoted
                    )
                    items[i] = .post(updatedPost)
                    print("📊 [FeedManager] Updated share count for post \(postId): \(post.engagement.shareCount + 1)")
                    break
                }
            default:
                break
            }
        }
    }
} 

// MARK: - Enhanced People Suggestions Models

struct EnhancedFeedPerson: Decodable, Identifiable {
    let id: String
    let name: String
    let username: String?
    let bio: String?
    let profileImage: String?
    let location: FeedCoordinates?
    let distance: Double?
    let mutualFollowers: Int
    let mutualFollowersList: [String]?
    let followersCount: Int
    let followingCount: Int
    let isFollowing: Bool
    let isFollowedBy: Bool
    let isCreator: Bool?
    let isVerified: Bool?
    let suggestionScore: Double // Changed from Int to Double to handle precision
    let createdAt: String?
    let updatedAt: String?
    let lastLogin: String?
}

struct PeopleSuggestionCategory: Decodable, Identifiable {
    let id = UUID() // Generate unique ID for SwiftUI
    let category: String // 'nearby', 'mutual', 'suggested'
    let title: String
    let subtitle: String
    let icon: String
    let users: [EnhancedFeedPerson]
    let position: String? // 'top', 'middle', 'bottom' for random placement
    let maxFrequency: Int? // Max times a user can be shown per session
    
    // Custom initializer for manual parsing
    init(category: String, title: String, subtitle: String, icon: String, users: [EnhancedFeedPerson], position: String? = nil, maxFrequency: Int? = nil) {
        self.category = category
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.users = users
        self.position = position
        self.maxFrequency = maxFrequency
    }
}

struct PeopleSuggestionsResponse: Decodable {
    let success: Bool
    let data: PeopleSuggestionsData?
    let error: String?
}

struct PeopleSuggestionsData: Decodable {
    let suggestions: [PeopleSuggestionCategory]
    let pagination: PeopleSuggestionsPagination
    let meta: PeopleSuggestionsMeta
}

struct PeopleSuggestionsPagination: Decodable {
    let page: Int
    let limit: Int
    let total: Int
    let hasMore: Bool
}

struct PeopleSuggestionsMeta: Decodable {
    let category: String?
    let userLocation: FeedCoordinates?
    let totalNearby: Int
    let totalMutual: Int
    let totalSuggested: Int
    let filtering: PeopleSuggestionsFiltering?
}

struct PeopleSuggestionsFiltering: Decodable {
    let excludedAlreadyFollowed: Int
    let totalUsersBeforeFilter: Int
    let totalUsersAfterFilter: Int
}

// Enhanced search user model
struct EnhancedSearchUser: Decodable, Identifiable {
    let id: String
    let name: String
    let username: String?
    let email: String
    let profileImage: String?
    let bio: String?
    let location: FeedCoordinates?
    let distance: Double?
    let mutualFollowers: Int
    let mutualFollowersList: [String]?
    let followersCount: Int
    let followingCount: Int
    let isFollowing: Bool
    let isFollowedBy: Bool
    let relevanceScore: Int
    let createdAt: String
}

// Fallback response structure for backward compatibility
struct PeopleSuggestionsFallbackResponse: Decodable {
    let success: Bool
    let data: [PeopleSuggestionCategory]?
    let error: String?
} 