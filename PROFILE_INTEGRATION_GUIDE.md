# iOS Profile Integration Guide

This guide explains how to integrate and use the comprehensive profile system in the Sacavia iOS app.

## Overview

The new profile system provides a complete user profile experience with:
- **Rich Profile Data**: User information, stats, achievements, and preferences
- **Social Features**: Follow/unfollow functionality, followers/following lists
- **Content Display**: Posts, photos, and reviews in organized tabs
- **Modern UI**: Beautiful, responsive design with smooth animations
- **Real-time Updates**: Live data from the mobile API endpoints

## Architecture

### Data Models

The profile system uses comprehensive data models that match the mobile API:

```swift
// Main profile data
struct UserProfile: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let username: String?
    let profileImage: ProfileImage?
    let coverImage: ProfileImage?
    let bio: String?
    let location: UserLocation?
    let role: String
    let isCreator: Bool
    let creatorLevel: String?
    let isVerified: Bool
    let preferences: UserPreferences
    let stats: UserStats
    let socialLinks: [SocialLink]
    let interests: [String]
    let isFollowing: Bool?
    let isFollowedBy: Bool?
    let joinedAt: String
    let lastLogin: String?
    let website: String?
}

// User statistics
struct UserStats: Codable {
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
    let savedPostsCount: Int
    let likedPostsCount: Int
    let locationsCount: Int
    let reviewCount: Int
    let recommendationCount: Int
    let averageRating: Double?
}

// User posts
struct UserPost: Codable, Identifiable {
    let id: String
    let type: String
    let title: String?
    let content: String
    let featuredImage: ProfileImage?
    let likeCount: Int
    let commentCount: Int
    let shareCount: Int
    let saveCount: Int
    let rating: Double?
    let location: PostLocation?
    let createdAt: String
    let updatedAt: String
    let isLiked: Bool?
    let isSaved: Bool?
}
```

### API Service

The `APIService` class provides methods for all profile-related operations:

```swift
class APIService {
    // Get user profile with optional user ID
    func getUserProfile(userId: String? = nil) async throws -> UserProfile
    
    // Update user profile
    func updateProfile(profileData: [String: Any]) async throws -> UserProfile
    
    // Get user statistics
    func getUserStats(userId: String) async throws -> UserStats
    
    // Get user posts with filtering
    func getUserPosts(userId: String, type: String = "all", page: Int = 1, limit: Int = 20) async throws -> [UserPost]
    
    // Get user photos
    func getUserPhotos(userId: String, type: String = "all", page: Int = 1, limit: Int = 20) async throws -> [UserPhoto]
    
    // Follow/unfollow users
    func followUser(userId: String) async throws -> Bool
    func unfollowUser(userId: String) async throws -> Bool
    
    // Get followers/following lists
    func getFollowers(userId: String, page: Int = 1, limit: Int = 50) async throws -> [FollowerUser]
    func getFollowing(userId: String, page: Int = 1, limit: Int = 50) async throws -> [FollowerUser]
}
```

## Usage

### Basic Profile View

```swift
// Show current user's profile
ProfileView()

// Show another user's profile
ProfileView(userId: "other-user-id")
```

### Integration in Tab Bar

```swift
TabView {
    // Other tabs...
    
    ProfileView()
        .tabItem {
            Image(systemName: "person.fill")
            Text("Profile")
        }
        .tag(4)
}
```

### Custom Profile View Model

```swift
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var posts: [UserPost] = []
    @Published var photos: [UserPhoto] = []
    @Published var isLoading = false
    @Published var error: String?
    
    var isOwnProfile: Bool {
        // Determine if viewing own profile
        return false
    }
    
    func loadProfile(userId: String?) async {
        // Load profile data
    }
    
    func loadPhotos(userId: String) async {
        // Load user photos
    }
    
    func toggleFollow() {
        // Handle follow/unfollow
    }
}
```

## Features

### 1. Profile Header

The profile header displays:
- **Cover Image**: Beautiful gradient fallback if no cover image
- **Profile Picture**: Circular image with fallback initials
- **User Info**: Name, username, verification badges, creator status
- **Bio**: User description
- **Location**: Formatted location information
- **Join Date**: When the user joined the platform

### 2. Statistics Section

Displays key metrics in an attractive grid:
- **Posts Count**: Total number of posts
- **Followers Count**: Number of followers
- **Following Count**: Number of users being followed
- **Additional Stats**: Reviews, locations, average rating

### 3. Action Buttons

Context-aware action buttons:
- **Edit Profile**: For own profile
- **Follow/Unfollow**: For other users' profiles
- **Followers/Following**: Show social connections

### 4. Content Tabs

Organized content display with four tabs:

#### Posts Tab
- Shows user's posts with rich formatting
- Displays images, engagement metrics
- Truncated content with "read more" functionality

#### Photos Tab
- Grid layout of user photos
- Tap to view full-size images
- Photos from posts, reviews, and location submissions

#### Reviews Tab
- Filtered view of review-type posts
- Star ratings and location information
- Engagement metrics

#### About Tab
- **Interests**: Tag-style display of user interests
- **Social Links**: Platform-specific icons and links
- **Preferences**: User preferences and settings

### 5. Social Features

#### Follow/Unfollow
```swift
// Follow a user
let success = try await APIService.shared.followUser(userId: "user-id")

// Unfollow a user
let success = try await APIService.shared.unfollowUser(userId: "user-id")
```

#### Followers/Following Lists
```swift
// Get followers
let followers = try await APIService.shared.getFollowers(userId: "user-id")

// Get following
let following = try await APIService.shared.getFollowing(userId: "user-id")
```

### 6. Photo Gallery

Full-screen photo gallery with:
- Grid layout of all user photos
- Tap to view individual photos
- Photos categorized by source (posts, reviews, locations)

## Customization

### Styling

The profile view uses SwiftUI's native styling with:
- **System Colors**: Adapts to light/dark mode
- **Custom Gradients**: Beautiful cover image fallbacks
- **Consistent Spacing**: Proper padding and margins
- **Smooth Animations**: Native SwiftUI transitions

### Layout Customization

```swift
// Custom stat card
StatCard(
    title: "Custom Metric",
    value: "42",
    icon: "star.fill",
    color: .purple
)

// Custom action button
Button(action: { /* custom action */ }) {
    HStack {
        Image(systemName: "custom.icon")
        Text("Custom Action")
    }
    .font(.system(size: 16, weight: .medium))
    .foregroundColor(.primary)
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
    .background(Color(.systemGray6))
    .cornerRadius(20)
}
```

### Data Customization

```swift
// Custom profile data transformation
extension UserProfile {
    var displayName: String {
        return username ?? name
    }
    
    var formattedJoinDate: String {
        // Custom date formatting
        return formatDate(joinedAt)
    }
    
    var primaryLocation: String {
        return location?.city ?? "Location not specified"
    }
}
```

## Error Handling

The profile system includes comprehensive error handling:

```swift
// Network errors
enum APIError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
```

## Performance Optimization

### Lazy Loading
- Photos load in batches with pagination
- Posts load on-demand
- Images use AsyncImage for efficient loading

### Caching
- Profile data cached locally
- Images cached by the system
- Network requests optimized

### Memory Management
- Efficient data structures
- Proper cleanup of resources
- Background task handling

## Testing

### Unit Tests
```swift
class ProfileViewModelTests: XCTestCase {
    func testLoadProfile() async {
        let viewModel = ProfileViewModel()
        await viewModel.loadProfile(userId: "test-user")
        
        XCTAssertNotNil(viewModel.profile)
        XCTAssertEqual(viewModel.profile?.name, "Test User")
    }
}
```

### UI Tests
```swift
class ProfileViewUITests: XCTestCase {
    func testProfileViewDisplays() {
        let app = XCUIApplication()
        app.launch()
        
        app.tabBars.buttons["Profile"].tap()
        
        XCTAssertTrue(app.staticTexts["Profile"].exists)
    }
}
```

## Best Practices

### 1. Authentication
- Always check authentication before making API calls
- Handle token expiration gracefully
- Provide clear error messages for auth failures

### 2. Data Loading
- Show loading states during API calls
- Implement pull-to-refresh functionality
- Handle empty states gracefully

### 3. User Experience
- Provide immediate feedback for user actions
- Use appropriate animations and transitions
- Maintain consistent navigation patterns

### 4. Performance
- Implement proper pagination for large datasets
- Cache frequently accessed data
- Optimize image loading and caching

### 5. Accessibility
- Provide proper accessibility labels
- Support VoiceOver navigation
- Use semantic colors and fonts

## Troubleshooting

### Common Issues

1. **Profile not loading**
   - Check authentication token
   - Verify API endpoint configuration
   - Check network connectivity

2. **Images not displaying**
   - Verify image URLs are valid
   - Check image format support
   - Ensure proper error handling

3. **Follow/unfollow not working**
   - Verify user permissions
   - Check API response format
   - Handle rate limiting

4. **Performance issues**
   - Implement proper pagination
   - Optimize image loading
   - Use background processing for heavy operations

### Debug Tips

```swift
// Enable debug logging
print("Profile loading for user: \(userId ?? "current user")")

// Check API responses
print("API Response: \(String(data: data, encoding: .utf8) ?? "Invalid data")")

// Monitor memory usage
print("Memory usage: \(ProcessInfo.processInfo.physicalMemory)")
```

## Future Enhancements

### Planned Features
- **Real-time Updates**: Live profile updates using WebSockets
- **Advanced Filtering**: Filter posts and photos by date, type, location
- **Social Interactions**: Like, comment, share from profile
- **Profile Analytics**: Detailed engagement metrics
- **Custom Themes**: User-selectable profile themes

### Integration Opportunities
- **Push Notifications**: Profile-related notifications
- **Deep Linking**: Direct links to specific profile sections
- **Sharing**: Share profile links with other users
- **Export**: Export profile data and content

## Conclusion

The new profile system provides a comprehensive, modern, and user-friendly way to display user information and content in the Sacavia iOS app. With its rich feature set, beautiful design, and robust architecture, it serves as a solid foundation for user engagement and social interaction.

For questions or support, refer to the API documentation or contact the development team. 