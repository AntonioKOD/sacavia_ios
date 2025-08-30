import Foundation
import SwiftUI

class PeopleSuggestionsManager: ObservableObject {
    @Published var suggestions: [PeopleSuggestionCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentCategory: String = "all" // 'all', 'nearby', 'mutual', 'suggested'
    
    private let authManager = AuthManager.shared
    private let apiService = APIService()
    private var sessionId = UUID().uuidString // Track session for user frequency
    private var shownUserIds: Set<String> = [] // Track which users have been shown
    private var blockedUsers: Set<String> = [] // Track blocked users
    
    func fetchPeopleSuggestions(category: String = "all", page: Int = 1, limit: Int? = nil) {
        // Use category-specific limit if not provided
        let effectiveLimit = limit ?? getLimitForCategory(category)
        guard authManager.isAuthenticated,
              let _ = authManager.getValidToken() else {
            DispatchQueue.main.async {
                self.errorMessage = "Authentication required. Please log in."
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Load blocked users first
        Task {
            await loadBlockedUsers()
        }
        
        print("📱 People suggestions: Category: \(category), Limit: \(effectiveLimit)")
        
        // Use dedicated people suggestions endpoint
        var urlComponents = URLComponents(string: "\(baseAPIURL)/api/mobile/people-suggestions")!
        urlComponents.queryItems = [
            URLQueryItem(name: "category", value: category),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(effectiveLimit)"),
            URLQueryItem(name: "sessionId", value: sessionId)
        ]
        
        // Add random placement for "all" category
        if category == "all" {
            urlComponents.queryItems?.append(URLQueryItem(name: "randomPlacement", value: "true"))
        }
        
        guard let url = urlComponents.url else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Invalid URL"
            }
            return
        }
        
        let request = authManager.createAuthenticatedRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ People suggestions network error:", error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    print("❌ People suggestions: No data received")
                    self.errorMessage = "No data received"
                    return
                }
                
                // Check for authentication errors
                if let httpResponse = response as? HTTPURLResponse {
                    print("📱 People suggestions HTTP status:", httpResponse.statusCode)
                    
                    if httpResponse.statusCode == 401 {
                        self.errorMessage = "Authentication expired. Please log in again."
                        return
                    }
                    
                    if httpResponse.statusCode == 404 {
                        print("❌ People suggestions endpoint not found (404), using mock data")
                        self.loadMockData(category: category)
                        return
                    }
                    
                    if httpResponse.statusCode != 200 {
                        print("❌ People suggestions server error:", httpResponse.statusCode)
                        self.errorMessage = "Server error: \(httpResponse.statusCode)"
                        return
                    }
                }
                
                // Print response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📱 People suggestions raw response:", responseString)
                }
                
                do {
                    // Try to decode as PeopleSuggestionsResponse first
                    let response = try JSONDecoder().decode(PeopleSuggestionsResponse.self, from: data)
                    
                    if response.success, let suggestionsData = response.data {
                        print("✅ People suggestions decoded successfully: \(suggestionsData.suggestions.count) categories")
                        
                        // Log filtering information if available
                        if let meta = response.data?.meta, let filtering = meta.filtering {
                            print("📊 People suggestions filtering: Excluded \(filtering.excludedAlreadyFollowed) already followed users")
                            print("📊 People suggestions filtering: \(filtering.totalUsersBeforeFilter) total users → \(filtering.totalUsersAfterFilter) after filtering")
                        }
                        
                        // Filter out blocked users first, then apply shown users filter
                        let filteredSuggestions = self.filterBlockedUsers(suggestionsData.suggestions)
                        
                        if page == 1 {
                            self.suggestions = self.filterShownUsers(filteredSuggestions)
                        } else {
                            // Append new suggestions for pagination
                            self.suggestions.append(contentsOf: self.filterShownUsers(filteredSuggestions))
                        }
                        self.currentCategory = category
                        self.errorMessage = nil
                    } else {
                        print("❌ People suggestions API returned success: false")
                        self.errorMessage = response.error ?? "Failed to fetch suggestions"
                    }
                } catch {
                    print("❌ People suggestions decoding error:", error)
                    
                    // Try to decode with a more flexible approach
                    do {
                        // Try to decode the raw JSON to understand the structure
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let dataDict = json["data"] as? [String: Any],
                           let suggestionsArray = dataDict["suggestions"] as? [[String: Any]] {
                            
                            print("🔄 Attempting manual JSON parsing...")
                            
                            var parsedSuggestions: [PeopleSuggestionCategory] = []
                            
                            for suggestionDict in suggestionsArray {
                                if let category = suggestionDict["category"] as? String,
                                   let title = suggestionDict["title"] as? String,
                                   let subtitle = suggestionDict["subtitle"] as? String,
                                   let icon = suggestionDict["icon"] as? String,
                                   let usersArray = suggestionDict["users"] as? [[String: Any]] {
                                    
                                    var parsedUsers: [EnhancedFeedPerson] = []
                                    
                                    for userDict in usersArray {
                                        if let userId = userDict["id"] as? String,
                                           let userName = userDict["name"] as? String {
                                            
                                            let user = EnhancedFeedPerson(
                                                id: userId,
                                                name: userName,
                                                username: userDict["username"] as? String,
                                                bio: userDict["bio"] as? String,
                                                profileImage: userDict["profileImage"] as? String,
                                                location: nil, // Simplified for now
                                                distance: userDict["distance"] as? Double,
                                                mutualFollowers: userDict["mutualFollowers"] as? Int ?? 0,
                                                mutualFollowersList: userDict["mutualFollowersList"] as? [String],
                                                followersCount: userDict["followersCount"] as? Int ?? 0,
                                                followingCount: userDict["followingCount"] as? Int ?? 0,
                                                isFollowing: userDict["isFollowing"] as? Bool ?? false,
                                                isFollowedBy: userDict["isFollowedBy"] as? Bool ?? false,
                                                isCreator: userDict["isCreator"] as? Bool,
                                                isVerified: userDict["isVerified"] as? Bool,
                                                suggestionScore: userDict["suggestionScore"] as? Double ?? 0.0,
                                                createdAt: userDict["createdAt"] as? String,
                                                updatedAt: userDict["updatedAt"] as? String,
                                                lastLogin: userDict["lastLogin"] as? String
                                            )
                                            parsedUsers.append(user)
                                        }
                                    }
                                    
                                    let suggestion = PeopleSuggestionCategory(
                                        category: category,
                                        title: title,
                                        subtitle: subtitle,
                                        icon: icon,
                                        users: parsedUsers
                                    )
                                    parsedSuggestions.append(suggestion)
                                }
                            }
                            
                            if !parsedSuggestions.isEmpty {
                                print("✅ Manual parsing successful: \(parsedSuggestions.count) categories")
                                
                                // Filter out blocked users from manually parsed suggestions
                                let filteredSuggestions = self.filterBlockedUsers(parsedSuggestions)
                                
                                if page == 1 {
                                    self.suggestions = filteredSuggestions
                                } else {
                                    self.suggestions.append(contentsOf: filteredSuggestions)
                                }
                                self.currentCategory = category
                                self.errorMessage = nil
                                return
                            }
                        }
                    } catch {
                        print("❌ Manual parsing also failed:", error)
                    }
                    
                    // Only use mock data if we're in development/testing mode
                    #if DEBUG
                    print("🔄 Using mock data for development")
                    self.loadMockData(category: category)
                    #else
                    self.errorMessage = "Failed to parse response"
                    #endif
                }
            }
        }.resume()
    }
    
    private func getIconForCategory(_ category: String) -> String {
        switch category {
        case "nearby":
            return "location.fill"
        case "mutual":
            return "person.2.fill"
        case "suggested":
            return "sparkles"
        default:
            return "person.fill"
        }
    }
    
    func followUser(_ userId: String) {
        // Implement follow user functionality
        guard authManager.isAuthenticated,
              let token = authManager.getValidToken() else {
            print("🔴 Not authenticated or no valid token!")
            return
        }
        print("🔑 Token in AuthManager: \(token)")
        
        let url = URL(string: "\(baseAPIURL)/api/mobile/users/\(userId)/follow")!
        var request = authManager.createAuthenticatedRequest(url: url)
        request.httpMethod = "POST"
        
        // Debug print: log outgoing Cookie header
        print("🍪 Cookie header being sent: \(request.value(forHTTPHeaderField: "Cookie") ?? "none")")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Follow user error:", error)
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔵 Follow user HTTP status: \(httpResponse.statusCode)")
                }
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("🔵 Follow user response: \(responseString)")
                }
                // Update local state to reflect the follow action
                self.updateFollowStatus(userId: userId, isFollowing: true)
                
                // Update AuthManager state for real-time updates
                AuthManager.shared.updateFollowState(targetUserId: userId, isFollowing: true)
            }
        }.resume()
    }
    
    func unfollowUser(_ userId: String) {
        // Implement unfollow user functionality
        guard authManager.isAuthenticated,
              let _ = authManager.getValidToken() else {
            return
        }
        
        let url = URL(string: "\(baseAPIURL)/api/mobile/users/\(userId)/follow")!
        var request = authManager.createAuthenticatedRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Unfollow user error:", error)
                    return
                }
                
                // Update local state to reflect the unfollow action
                self.updateFollowStatus(userId: userId, isFollowing: false)
                
                // Update AuthManager state for real-time updates
                AuthManager.shared.updateFollowState(targetUserId: userId, isFollowing: false)
            }
        }.resume()
    }
    
    private func updateFollowStatus(userId: String, isFollowing: Bool) {
        // Update the follow status in the suggestions array
        for i in 0..<suggestions.count {
            for j in 0..<suggestions[i].users.count {
                if suggestions[i].users[j].id == userId {
                    // Create a new user with updated follow status
                    let updatedUser = EnhancedFeedPerson(
                        id: suggestions[i].users[j].id,
                        name: suggestions[i].users[j].name,
                        username: suggestions[i].users[j].username,
                        bio: suggestions[i].users[j].bio,
                        profileImage: suggestions[i].users[j].profileImage,
                        location: suggestions[i].users[j].location,
                        distance: suggestions[i].users[j].distance,
                        mutualFollowers: suggestions[i].users[j].mutualFollowers,
                        mutualFollowersList: suggestions[i].users[j].mutualFollowersList,
                        followersCount: suggestions[i].users[j].followersCount,
                        followingCount: suggestions[i].users[j].followingCount,
                        isFollowing: isFollowing,
                        isFollowedBy: suggestions[i].users[j].isFollowedBy,
                        isCreator: suggestions[i].users[j].isCreator,
                        isVerified: suggestions[i].users[j].isVerified,
                        suggestionScore: suggestions[i].users[j].suggestionScore,
                        createdAt: suggestions[i].users[j].createdAt,
                        updatedAt: suggestions[i].users[j].updatedAt,
                        lastLogin: suggestions[i].users[j].lastLogin
                    )
                    
                    // Create a new category with the updated user
                    var updatedUsers = suggestions[i].users
                    updatedUsers[j] = updatedUser
                    let updatedCategory = PeopleSuggestionCategory(
                        category: suggestions[i].category,
                        title: suggestions[i].title,
                        subtitle: suggestions[i].subtitle,
                        icon: suggestions[i].icon,
                        users: updatedUsers
                    )
                    
                    // Update the suggestions array
                    suggestions[i] = updatedCategory
                    return
                }
            }
        }
    }
    
    func refreshSuggestions() {
        print("🔄 Refreshing people suggestions with new randomization...")
        // Reset session for fresh randomization
        sessionId = UUID().uuidString
        shownUserIds.removeAll()
        fetchPeopleSuggestions(category: currentCategory, page: 1)
    }
    
    // Refresh blocked users and refilter suggestions
    func refreshBlockedUsers() async {
        await loadBlockedUsers()
        // Refilter current suggestions
        let filteredSuggestions = filterBlockedUsers(suggestions)
        await MainActor.run {
            self.suggestions = filteredSuggestions
            print("🔍 [PeopleSuggestionsManager] Refreshed blocked users and refiltered suggestions")
        }
    }
    
    // Block a user and update local state
    func blockUser(userId: String, reason: String? = nil) async {
        do {
            let success = try await apiService.blockUser(targetUserId: userId, reason: reason)
            if success {
                // Add to local blocked users set
                await MainActor.run {
                    self.blockedUsers.insert(userId)
                    // Remove the user from current suggestions
                    self.suggestions = self.suggestions.compactMap { category in
                        let filteredUsers = category.users.filter { $0.id != userId }
                        if filteredUsers.isEmpty {
                            return nil
                        }
                        return PeopleSuggestionCategory(
                            category: category.category,
                            title: category.title,
                            subtitle: category.subtitle,
                            icon: category.icon,
                            users: filteredUsers,
                            position: category.position,
                            maxFrequency: category.maxFrequency
                        )
                    }
                    print("🔍 [PeopleSuggestionsManager] User \(userId) blocked and removed from suggestions")
                }
            }
        } catch {
            print("🔍 [PeopleSuggestionsManager] Failed to block user \(userId): \(error)")
        }
    }
    
    // Load blocked users from API
    private func loadBlockedUsers() async {
        do {
            let blockedUserIds = try await apiService.getBlockedUsers()
            await MainActor.run {
                self.blockedUsers = Set(blockedUserIds)
                print("🔍 [PeopleSuggestionsManager] Loaded \(blockedUserIds.count) blocked users")
            }
        } catch {
            print("🔍 [PeopleSuggestionsManager] Failed to load blocked users: \(error)")
            // Continue without blocking if we can't load blocked users
        }
    }
    
    // Filter out blocked users from suggestions
    private func filterBlockedUsers(_ suggestions: [PeopleSuggestionCategory]) -> [PeopleSuggestionCategory] {
        return suggestions.compactMap { category in
            let filteredUsers = category.users.filter { user in
                !blockedUsers.contains(user.id)
            }
            
            if filteredUsers.isEmpty {
                return nil // Remove category if no users remain
            }
            
            return PeopleSuggestionCategory(
                category: category.category,
                title: category.title,
                subtitle: category.subtitle,
                icon: category.icon,
                users: filteredUsers,
                position: category.position,
                maxFrequency: category.maxFrequency
            )
        }
    }
    
    // Track shown users and filter out those shown too many times
    private func filterShownUsers(_ suggestions: [PeopleSuggestionCategory]) -> [PeopleSuggestionCategory] {
        var filteredSuggestions: [PeopleSuggestionCategory] = []
        var userFrequencyCount: [String: Int] = [:]
        
        for suggestion in suggestions {
            var filteredUsers: [EnhancedFeedPerson] = []
            
            for user in suggestion.users {
                let currentCount = userFrequencyCount[user.id] ?? 0
                let maxFrequency = suggestion.maxFrequency ?? 2
                
                if currentCount < maxFrequency {
                    filteredUsers.append(user)
                    userFrequencyCount[user.id] = currentCount + 1
                    shownUserIds.insert(user.id)
                }
            }
            
            if !filteredUsers.isEmpty {
                let filteredSuggestion = PeopleSuggestionCategory(
                    category: suggestion.category,
                    title: suggestion.title,
                    subtitle: suggestion.subtitle,
                    icon: suggestion.icon,
                    users: filteredUsers,
                    position: suggestion.position,
                    maxFrequency: suggestion.maxFrequency
                )
                filteredSuggestions.append(filteredSuggestion)
            }
        }
        
        print("📊 User frequency filtering: \(userFrequencyCount.count) unique users tracked")
        return filteredSuggestions
    }
    
    // MARK: - API Testing
    func testAPIEndpoint() {
        print("🧪 Testing people suggestions API endpoint...")
        
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/people-suggestions") else {
            print("❌ Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = authManager.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ Added auth token to request")
        } else {
            print("❌ No auth token available")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ API test failed:", error.localizedDescription)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 API test HTTP status:", httpResponse.statusCode)
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("📱 API test response:", responseString)
                    
                    // Try to decode the response to test parsing
                    do {
                        _ = try JSONDecoder().decode(PeopleSuggestionsResponse.self, from: data)
                        print("✅ API test response parsed successfully")
                    } catch {
                        print("❌ API test response parsing failed:", error)
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Mock Data for Testing
    private func loadMockData(category: String) {
        let mockSuggestions = [
            PeopleSuggestionCategory(
                category: "nearby",
                title: "People Near You",
                subtitle: "Discover people in your area",
                icon: "location.fill",
                users: [
                    EnhancedFeedPerson(
                        id: "1",
                        name: "Sarah Johnson",
                        username: "sarahj",
                        bio: "Adventure seeker and coffee lover ☕️",
                        profileImage: nil,
                        location: nil,
                        distance: 0.5,
                        mutualFollowers: 3,
                        mutualFollowersList: ["user2", "user3", "user4"],
                        followersCount: 245,
                        followingCount: 189,
                        isFollowing: false,
                        isFollowedBy: false,
                        isCreator: true,
                        isVerified: true,
                        suggestionScore: 85,
                        createdAt: "2024-01-15T10:30:00Z",
                        updatedAt: "2024-01-20T14:22:00Z",
                        lastLogin: "2024-01-25T09:15:00Z"
                    ),
                    EnhancedFeedPerson(
                        id: "2",
                        name: "Mike Chen",
                        username: "mikechen",
                        bio: "Photographer capturing life's moments 📸",
                        profileImage: nil,
                        location: nil,
                        distance: 1.2,
                        mutualFollowers: 1,
                        mutualFollowersList: ["user1"],
                        followersCount: 892,
                        followingCount: 156,
                        isFollowing: true,
                        isFollowedBy: false,
                        isCreator: false,
                        isVerified: false,
                        suggestionScore: 72,
                        createdAt: "2023-11-08T16:45:00Z",
                        updatedAt: "2024-01-18T11:30:00Z",
                        lastLogin: "2024-01-24T20:10:00Z"
                    )
                ]
            ),
            PeopleSuggestionCategory(
                category: "mutual",
                title: "Mutual Connections",
                subtitle: "People you might know",
                icon: "person.2.fill",
                users: [
                    EnhancedFeedPerson(
                        id: "3",
                        name: "Emma Davis",
                        username: "emmad",
                        bio: "Foodie and travel enthusiast ✈️",
                        profileImage: nil,
                        location: nil,
                        distance: nil,
                        mutualFollowers: 7,
                        mutualFollowersList: ["user1", "user2", "user5", "user6", "user7", "user8", "user9"],
                        followersCount: 156,
                        followingCount: 203,
                        isFollowing: false,
                        isFollowedBy: true,
                        isCreator: false,
                        isVerified: false,
                        suggestionScore: 95,
                        createdAt: "2023-09-22T12:15:00Z",
                        updatedAt: "2024-01-19T08:45:00Z",
                        lastLogin: "2024-01-25T13:20:00Z"
                    ),
                    EnhancedFeedPerson(
                        id: "4",
                        name: "Alex Rodriguez",
                        username: "alexrod",
                        bio: "Tech enthusiast and startup founder 💻",
                        profileImage: nil,
                        location: nil,
                        distance: nil,
                        mutualFollowers: 4,
                        mutualFollowersList: ["user1", "user3", "user10", "user11"],
                        followersCount: 567,
                        followingCount: 89,
                        isFollowing: false,
                        isFollowedBy: false,
                        isCreator: true,
                        isVerified: true,
                        suggestionScore: 88,
                        createdAt: "2023-12-03T14:20:00Z",
                        updatedAt: "2024-01-21T16:30:00Z",
                        lastLogin: "2024-01-25T10:45:00Z"
                    )
                ]
            ),
            PeopleSuggestionCategory(
                category: "suggested",
                title: "Recommended for You",
                subtitle: "Based on your interests",
                icon: "sparkles",
                users: [
                    EnhancedFeedPerson(
                        id: "5",
                        name: "Lisa Wang",
                        username: "lisawang",
                        bio: "Yoga instructor and wellness advocate 🧘‍♀️",
                        profileImage: nil,
                        location: nil,
                        distance: 2.1,
                        mutualFollowers: 0,
                        mutualFollowersList: [],
                        followersCount: 1234,
                        followingCount: 67,
                        isFollowing: false,
                        isFollowedBy: false,
                        isCreator: true,
                        isVerified: true,
                        suggestionScore: 91,
                        createdAt: "2023-08-14T09:30:00Z",
                        updatedAt: "2024-01-22T12:15:00Z",
                        lastLogin: "2024-01-25T07:30:00Z"
                    ),
                    EnhancedFeedPerson(
                        id: "6",
                        name: "David Kim",
                        username: "davidkim",
                        bio: "Music producer and DJ 🎵",
                        profileImage: nil,
                        location: nil,
                        distance: 3.5,
                        mutualFollowers: 2,
                        mutualFollowersList: ["user12", "user13"],
                        followersCount: 2341,
                        followingCount: 445,
                        isFollowing: false,
                        isFollowedBy: false,
                        isCreator: false,
                        isVerified: false,
                        suggestionScore: 78,
                        createdAt: "2023-10-11T18:45:00Z",
                        updatedAt: "2024-01-23T19:20:00Z",
                        lastLogin: "2024-01-24T22:15:00Z"
                    )
                ]
            )
        ]
        
        DispatchQueue.main.async {
            self.suggestions = mockSuggestions
            self.currentCategory = category
        }
    }
    
    // Helper function to get appropriate limit for different categories
    func getLimitForCategory(_ category: String) -> Int {
        switch category {
        case "all":
            return 8  // Show more in "all" tab for variety
        case "nearby", "mutual", "suggested":
            return 30  // Show many more in individual category tabs
        default:
            return 30
        }
    }
} 