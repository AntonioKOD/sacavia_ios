import Foundation
import SwiftUI

// MARK: - Shared Types for Profile and User Data

struct ProfileImage: Codable {
    let url: String
}

struct UserLocation: Codable {
    let coordinates: UserCoordinates?
    let address: String?
    let city: String?
    let state: String?
    let country: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coordinates = try container.decodeIfPresent(UserCoordinates.self, forKey: .coordinates)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        country = try container.decodeIfPresent(String.self, forKey: .country)
    }
    
    enum CodingKeys: String, CodingKey {
        case coordinates, address, city, state, country
    }
}

struct UserCoordinates: Codable {
    let latitude: Double?
    let longitude: Double?
    
    init(latitude: Double?, longitude: Double?) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle empty coordinates object by checking if any keys exist
        let allKeys = container.allKeys
        if allKeys.isEmpty {
            latitude = nil
            longitude = nil
            return
        }
        
        // Try to decode latitude and longitude with fallbacks
        var decodedLatitude: Double? = nil
        var decodedLongitude: Double? = nil
        
        // Try Double first
        decodedLatitude = try? container.decode(Double.self, forKey: .latitude)
        decodedLongitude = try? container.decode(Double.self, forKey: .longitude)
        
        // If still nil, try String conversion
        if decodedLatitude == nil {
            if let latitudeString = try? container.decode(String.self, forKey: .latitude) {
                decodedLatitude = Double(latitudeString)
            }
        }
        
        if decodedLongitude == nil {
            if let longitudeString = try? container.decode(String.self, forKey: .longitude) {
                decodedLongitude = Double(longitudeString)
            }
        }
        
        // Assign the final values
        latitude = decodedLatitude
        longitude = decodedLongitude
    }
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

// Alias for backward compatibility
typealias Coordinates = UserCoordinates

// MARK: - Invite People Types

struct InvitedUser: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let email: String?
    let avatar: String?
    let isSelected: Bool
    
    init(id: String, name: String, email: String? = nil, avatar: String? = nil, isSelected: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.avatar = avatar
        self.isSelected = isSelected
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: InvitedUser, rhs: InvitedUser) -> Bool {
        return lhs.id == rhs.id
    }
}

struct LocationData: Codable {
    let coordinates: Coordinates?
    let address: String?
    let city: String?
    let state: String?
    let country: String?
    
    init(coordinates: Coordinates?, address: String?, city: String?, state: String?, country: String?) {
        self.coordinates = coordinates
        self.address = address
        self.city = city
        self.state = state
        self.country = country
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coordinates = try container.decodeIfPresent(Coordinates.self, forKey: .coordinates)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        country = try container.decodeIfPresent(String.self, forKey: .country)
    }
    
    enum CodingKeys: String, CodingKey {
        case coordinates, address, city, state, country
    }
}

struct AuthUser: Codable {
    let id: String
    let name: String
    let email: String? // Make email optional to handle missing field
    let username: String?
    let profileImage: ProfileImage? // Changed from String? to ProfileImage?
    let role: String
    let bio: String?
    let location: LocationData?
    let isVerified: Bool
    let followerCount: Int
    let following: [String]? // Array of user IDs the current user is following
    let followers: [String]? // Array of user IDs following the current user
    
    init(id: String, name: String, email: String? = nil, username: String? = nil, profileImage: ProfileImage? = nil, role: String = "user", bio: String? = nil, location: LocationData? = nil, isVerified: Bool = false, followerCount: Int = 0, following: [String]? = nil, followers: [String]? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.username = username
        self.profileImage = profileImage
        self.role = role
        self.bio = bio
        self.location = location
        self.isVerified = isVerified
        self.followerCount = followerCount
        self.following = following
        self.followers = followers
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        profileImage = try container.decodeIfPresent(ProfileImage.self, forKey: .profileImage) // Changed from String to ProfileImage
        role = try container.decode(String.self, forKey: .role)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        location = try container.decodeIfPresent(LocationData.self, forKey: .location)
        isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified) ?? false
        followerCount = try container.decodeIfPresent(Int.self, forKey: .followerCount) ?? 0
        following = try container.decodeIfPresent([String].self, forKey: .following)
        followers = try container.decodeIfPresent([String].self, forKey: .followers)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, username, profileImage, role, bio, location, isVerified, followerCount, following, followers
    }
}

struct UserPreferences: Codable {
    let categories: [String]
    let notifications: Bool
    let radius: Int
    let primaryUseCase: String?
    let budgetPreference: String?
    let travelRadius: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        categories = try container.decodeIfPresent([String].self, forKey: .categories) ?? []
        notifications = try container.decode(Bool.self, forKey: .notifications)
        radius = try container.decode(Int.self, forKey: .radius)
        primaryUseCase = try container.decodeIfPresent(String.self, forKey: .primaryUseCase)
        budgetPreference = try container.decodeIfPresent(String.self, forKey: .budgetPreference)
        travelRadius = try container.decodeIfPresent(String.self, forKey: .travelRadius)
    }
    
    enum CodingKeys: String, CodingKey {
        case categories, notifications, radius, primaryUseCase, budgetPreference, travelRadius
    }
}

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
    
    // Custom initializer for creating instances with specific values
    init(postsCount: Int, followersCount: Int, followingCount: Int, savedPostsCount: Int, likedPostsCount: Int, locationsCount: Int, reviewCount: Int, recommendationCount: Int, averageRating: Double?) {
        self.postsCount = postsCount
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.savedPostsCount = savedPostsCount
        self.likedPostsCount = likedPostsCount
        self.locationsCount = locationsCount
        self.reviewCount = reviewCount
        self.recommendationCount = recommendationCount
        self.averageRating = averageRating
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        postsCount = try container.decode(Int.self, forKey: .postsCount)
        followersCount = try container.decode(Int.self, forKey: .followersCount)
        followingCount = try container.decode(Int.self, forKey: .followingCount)
        savedPostsCount = try container.decode(Int.self, forKey: .savedPostsCount)
        likedPostsCount = try container.decode(Int.self, forKey: .likedPostsCount)
        locationsCount = try container.decode(Int.self, forKey: .locationsCount)
        reviewCount = try container.decode(Int.self, forKey: .reviewCount)
        recommendationCount = try container.decode(Int.self, forKey: .recommendationCount)
        averageRating = try container.decodeIfPresent(Double.self, forKey: .averageRating)
    }
    
    enum CodingKeys: String, CodingKey {
        case postsCount, followersCount, followingCount, savedPostsCount, likedPostsCount, locationsCount, reviewCount, recommendationCount, averageRating
    }
}

struct SocialLink: Codable {
    let platform: String
    let url: String
    let username: String?
}

// MARK: - Profile Types
struct ProfileUser: Codable, Identifiable {
    let id: String
    let name: String
    let email: String?
    let username: String?
    let profileImage: ProfileImage?
    let bio: String?
    let location: UserLocation?
    let role: String?
    let isCreator: Bool?
    let isVerified: Bool
    let stats: UserStats?
    let isFollowing: Bool?
    let joinedAt: String?
    let interests: [String]?
    let socialLinks: [SocialLink]?
    let following: [String]? // Array of user IDs
    let followers: [String]? // Array of user IDs
    
    // Custom initializer for creating instances with updated stats
    init(id: String, name: String, email: String?, username: String?, profileImage: ProfileImage?, bio: String?, location: UserLocation?, role: String?, isCreator: Bool?, isVerified: Bool, stats: UserStats?, isFollowing: Bool?, joinedAt: String?, interests: [String]?, socialLinks: [SocialLink]?, following: [String]?, followers: [String]?) {
        self.id = id
        self.name = name
        self.email = email
        self.username = username
        self.profileImage = profileImage
        self.bio = bio
        self.location = location
        self.role = role
        self.isCreator = isCreator
        self.isVerified = isVerified
        self.stats = stats
        self.isFollowing = isFollowing
        self.joinedAt = joinedAt
        self.interests = interests
        self.socialLinks = socialLinks
        self.following = following
        self.followers = followers
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        profileImage = try container.decodeIfPresent(ProfileImage.self, forKey: .profileImage)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        location = try container.decodeIfPresent(UserLocation.self, forKey: .location)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        isCreator = try container.decodeIfPresent(Bool.self, forKey: .isCreator)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        stats = try container.decodeIfPresent(UserStats.self, forKey: .stats)
        isFollowing = try container.decodeIfPresent(Bool.self, forKey: .isFollowing)
        joinedAt = try container.decodeIfPresent(String.self, forKey: .joinedAt)
        interests = try container.decodeIfPresent([String].self, forKey: .interests)
        socialLinks = try container.decodeIfPresent([SocialLink].self, forKey: .socialLinks)
        following = try container.decodeIfPresent([String].self, forKey: .following)
        followers = try container.decodeIfPresent([String].self, forKey: .followers)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, username, profileImage, bio, location, role, isCreator, isVerified, stats, isFollowing, joinedAt, interests, socialLinks, following, followers
    }
}

struct ProfilePost: Codable, Identifiable {
    let id: String
    let title: String?
    let content: String
    let caption: String?
    let type: String
    let featuredImage: ProfileImage?
    let image: String?
    let video: String?
    let videoThumbnail: String?
    let photos: [String]?
    let videos: [String]?
    let media: [String]?
    let likeCount: Int
    let commentCount: Int
    let shareCount: Int
    let saveCount: Int
    let rating: Double?
    let tags: [String]?
    let location: PostLocation?
    let createdAt: String
    let updatedAt: String
    let mimeType: String?
    
    // Custom initializer for creating from UserPost
    init(id: String, title: String?, content: String, caption: String?, type: String, featuredImage: ProfileImage?, image: String?, video: String?, videoThumbnail: String?, photos: [String]?, videos: [String]?, media: [String]?, likeCount: Int, commentCount: Int, shareCount: Int, saveCount: Int, rating: Double?, tags: [String]?, location: PostLocation?, createdAt: String, updatedAt: String, mimeType: String?) {
        self.id = id
        self.title = title
        self.content = content
        self.caption = caption
        self.type = type
        self.featuredImage = featuredImage
        self.image = image
        self.video = video
        self.videoThumbnail = videoThumbnail
        self.photos = photos
        self.videos = videos
        self.media = media
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.shareCount = shareCount
        self.saveCount = saveCount
        self.rating = rating
        self.tags = tags
        self.location = location
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.mimeType = mimeType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        type = try container.decode(String.self, forKey: .type)
        featuredImage = try container.decodeIfPresent(ProfileImage.self, forKey: .featuredImage)
        
        // Handle image field which can be string or object
        if let imageValue = try? container.decodeIfPresent(String.self, forKey: .image) {
            image = imageValue
        } else if let imageObject = try? container.decodeIfPresent(ImageObject.self, forKey: .image) {
            image = imageObject.url
        } else {
            image = nil
        }
        
        // Handle video field which can be string or object
        if let videoValue = try? container.decodeIfPresent(String.self, forKey: .video) {
            video = videoValue
        } else if let videoObject = try? container.decodeIfPresent(VideoObject.self, forKey: .video) {
            video = videoObject.url
        } else {
            video = nil
        }
        
        // Handle videoThumbnail field which can be string or object
        if let thumbnailValue = try? container.decodeIfPresent(String.self, forKey: .videoThumbnail) {
            videoThumbnail = thumbnailValue
        } else {
            videoThumbnail = nil
        }
        
        // Handle photos array as simple strings
        photos = try container.decodeIfPresent([String].self, forKey: .photos)
        
        videos = try container.decodeIfPresent([String].self, forKey: .videos)
        media = try container.decodeIfPresent([String].self, forKey: .media)
        likeCount = try container.decode(Int.self, forKey: .likeCount)
        commentCount = try container.decode(Int.self, forKey: .commentCount)
        shareCount = try container.decodeIfPresent(Int.self, forKey: .shareCount) ?? 0
        saveCount = try container.decodeIfPresent(Int.self, forKey: .saveCount) ?? 0
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        location = try container.decodeIfPresent(PostLocation.self, forKey: .location)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? createdAt
        mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, caption, type, featuredImage, image, video, videoThumbnail, photos, videos, media, likeCount, commentCount, shareCount, saveCount, rating, tags, location, createdAt, updatedAt, mimeType
    }
}

struct PhotoObject: Codable {
    let id: String
    let url: String
    let thumbnailURL: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id field - it might be missing in some cases
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else {
            id = "" // Default empty string if id is missing
        }
        
        // Handle url field - this is required
        if let urlValue = try? container.decode(String.self, forKey: .url) {
            url = urlValue
        } else {
            // If url is missing, try to decode the entire object as a string
            url = try container.decode(String.self, forKey: .url)
        }
        
        // Handle thumbnailURL field - it's optional
        thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL)
    }
    
    // Custom initializer for creating from string URL (backward compatibility)
    init(id: String, url: String, thumbnailURL: String?) {
        self.id = id
        self.url = url
        self.thumbnailURL = thumbnailURL
    }
    
    enum CodingKeys: String, CodingKey {
        case id, url, thumbnailURL
    }
}

struct ImageObject: Codable {
    let id: String?
    let url: String
    let thumbnailURL: String?
    let filename: String?
    let mimeType: String?
    let filesize: Int?
    let width: Int?
    let height: Int?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        url = try container.decode(String.self, forKey: .url)
        thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL)
        filename = try container.decodeIfPresent(String.self, forKey: .filename)
        mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
        filesize = try container.decodeIfPresent(Int.self, forKey: .filesize)
        width = try container.decodeIfPresent(Int.self, forKey: .width)
        height = try container.decodeIfPresent(Int.self, forKey: .height)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, url, thumbnailURL, filename, mimeType, filesize, width, height
    }
}

struct VideoObject: Codable {
    let id: String?
    let url: String
    let thumbnailURL: String?
    let filename: String?
    let mimeType: String?
    let filesize: Int?
    let isVideo: Bool?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        url = try container.decode(String.self, forKey: .url)
        thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL)
        filename = try container.decodeIfPresent(String.self, forKey: .filename)
        mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
        filesize = try container.decodeIfPresent(Int.self, forKey: .filesize)
        isVideo = try container.decodeIfPresent(Bool.self, forKey: .isVideo)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, url, thumbnailURL, filename, mimeType, filesize, isVideo
    }
}

struct PostLocation: Codable {
    let id: String
    let name: String
}

// MARK: - API Response Types

struct User: Codable {
    let id: String
    let name: String
    let email: String
    let profileImage: ProfileImage?
    let location: UserLocation?
    let role: String
    let preferences: UserPreferences
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        profileImage = try container.decodeIfPresent(ProfileImage.self, forKey: .profileImage)
        location = try container.decodeIfPresent(UserLocation.self, forKey: .location)
        role = try container.decode(String.self, forKey: .role)
        preferences = try container.decode(UserPreferences.self, forKey: .preferences)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, profileImage, location, role, preferences
    }
}

struct RegisterResponse: Codable {
    let success: Bool
    let message: String
    let data: RegisterData?
    let error: String?
    let code: String?
}

struct RegisterData: Codable {
    let user: User
    let token: String
    let expiresIn: Int
}

// MARK: - Test Response

struct TestResponse: Codable {
    let success: Bool
    let message: String
    let timestamp: String
    let headers: [String: String]
}

// MARK: - Error Types

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)
    case networkError
    case authenticationRequired
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        case .networkError:
            return "Network error occurred"
        case .authenticationRequired:
            return "Authentication required. Please log in."
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

// MARK: - Data Models

struct SearchLocationData: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
}

// Enhanced location type for detailed location information
struct SearchLocation: Codable {
    let id: String
    let name: String
    let description: String?
    let shortDescription: String?
    let slug: String?
    let address: String?
    let coordinates: LocationCoordinates?
    let featuredImage: String?
    let gallery: [LocationGalleryItem]?
    let categories: [String]?
    let tags: [String]?
    let priceRange: String?
    let rating: Double?
    let reviewCount: Int?
    let visitCount: Int?
    let businessHours: [BusinessHour]?
    let contactInfo: LocationContactInfo?
    let accessibility: Accessibility?
    let bestTimeToVisit: [BestTimeToVisit]?
    let insiderTips: [LocationInsiderTip]?
    let isVerified: Bool?
    let isFeatured: Bool?
    let hasBusinessPartnership: Bool?
    let partnershipDetails: PartnershipDetails?
    let neighborhood: String?
    let isSaved: Bool?
    let isSubscribed: Bool?
    let createdBy: String?
    let createdAt: String?
    let updatedAt: String?
    
    // Helper function to create a copy with updated fields
    func copy(
        id: String? = nil,
        name: String? = nil,
        description: String? = nil,
        shortDescription: String? = nil,
        slug: String? = nil,
        address: String? = nil,
        coordinates: LocationCoordinates? = nil,
        featuredImage: String? = nil,
        gallery: [LocationGalleryItem]? = nil,
        categories: [String]? = nil,
        tags: [String]? = nil,
        priceRange: String? = nil,
        rating: Double? = nil,
        reviewCount: Int? = nil,
        visitCount: Int? = nil,
        businessHours: [BusinessHour]? = nil,
        contactInfo: LocationContactInfo? = nil,
        accessibility: Accessibility? = nil,
        bestTimeToVisit: [BestTimeToVisit]? = nil,
        insiderTips: [LocationInsiderTip]? = nil,
        isVerified: Bool? = nil,
        isFeatured: Bool? = nil,
        hasBusinessPartnership: Bool? = nil,
                       partnershipDetails: PartnershipDetails? = nil,
        neighborhood: String? = nil,
        isSaved: Bool? = nil,
        isSubscribed: Bool? = nil,
        createdBy: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) -> SearchLocation {
        return SearchLocation(
            id: id ?? self.id,
            name: name ?? self.name,
            description: description ?? self.description,
            shortDescription: shortDescription ?? self.shortDescription,
            slug: slug ?? self.slug,
            address: address ?? self.address,
            coordinates: coordinates ?? self.coordinates,
            featuredImage: featuredImage ?? self.featuredImage,
            gallery: gallery ?? self.gallery,
            categories: categories ?? self.categories,
            tags: tags ?? self.tags,
            priceRange: priceRange ?? self.priceRange,
            rating: rating ?? self.rating,
            reviewCount: reviewCount ?? self.reviewCount,
            visitCount: visitCount ?? self.visitCount,
            businessHours: businessHours ?? self.businessHours,
            contactInfo: contactInfo ?? self.contactInfo,
            accessibility: accessibility ?? self.accessibility,
            bestTimeToVisit: bestTimeToVisit ?? self.bestTimeToVisit,
            insiderTips: insiderTips ?? self.insiderTips,
            isVerified: isVerified ?? self.isVerified,
            isFeatured: isFeatured ?? self.isFeatured,
            hasBusinessPartnership: hasBusinessPartnership ?? self.hasBusinessPartnership,
            partnershipDetails: partnershipDetails ?? self.partnershipDetails,
            neighborhood: neighborhood ?? self.neighborhood,
            isSaved: isSaved ?? self.isSaved,
            isSubscribed: isSubscribed ?? self.isSubscribed,
            createdBy: createdBy ?? self.createdBy,
            createdAt: createdAt ?? self.createdAt,
            updatedAt: updatedAt ?? self.updatedAt
        )
    }
}

// MARK: - Location Gallery and Contact Models

struct LocationGalleryItem: Codable {
    let image: String?
    let caption: String?
}

struct LocationContactInfo: Codable {
    let phone: String?
    let email: String?
    let website: String?
    let socialMedia: SocialMedia?
}

struct LocationInsiderTip: Codable {
    let category: String?
    let tip: String?
    let priority: String?
    let source: String?
    let submittedBy: String?
    let submittedAt: String?
    let status: String?
    let isVerified: Bool?
    let reviewedBy: String?
    let reviewedAt: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        tip = try container.decodeIfPresent(String.self, forKey: .tip)
        priority = try container.decodeIfPresent(String.self, forKey: .priority)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified)
        
        // Handle submittedBy - it can be either a string or a user object
        if let submittedByString = try? container.decode(String.self, forKey: .submittedBy) {
            submittedBy = submittedByString
        } else if let submittedByObject = try? container.decode([String: String].self, forKey: .submittedBy) {
            // If it's a user object, extract the name
            submittedBy = submittedByObject["name"] ?? submittedByObject["id"]
        } else {
            submittedBy = nil
        }
        
        // Handle reviewedBy - it can be either a string or a user object
        if let reviewedByString = try? container.decode(String.self, forKey: .reviewedBy) {
            reviewedBy = reviewedByString
        } else if let reviewedByObject = try? container.decode([String: String].self, forKey: .reviewedBy) {
            // If it's a user object, extract the name
            reviewedBy = reviewedByObject["name"] ?? reviewedByObject["id"]
        } else {
            reviewedBy = nil
        }
        
        // Handle submittedAt - it can be a string or a date
        if let submittedAtString = try? container.decode(String.self, forKey: .submittedAt) {
            submittedAt = submittedAtString
        } else {
            submittedAt = nil
        }
        
        // Handle reviewedAt - it can be a string or a date
        if let reviewedAtString = try? container.decode(String.self, forKey: .reviewedAt) {
            reviewedAt = reviewedAtString
        } else {
            reviewedAt = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case category, tip, priority, source, submittedBy, submittedAt, status, isVerified, reviewedBy, reviewedAt
    }
}

// ContactInfo, SocialMedia, and BusinessHour are already defined above

struct LocationCoordinates: Codable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Contact and Business Information

struct ContactInfo: Codable {
    let phone: String?
    let email: String?
    let website: String?
    let socialMedia: SocialMedia?
}

struct SocialMedia: Codable {
    let facebook: String?
    let twitter: String?
    let instagram: String?
    let linkedin: String?
}

struct BusinessHour: Codable {
    let day: String
    let open: String?
    let close: String?
    let closed: Bool?
}

struct Accessibility: Codable {
    let wheelchairAccess: Bool?
    let parking: Bool?
    let other: String?
}

struct BestTimeToVisit: Codable {
    let season: String
}

struct PartnershipDetails: Codable {
    let partnerName: String?
    let partnerContact: String?
    let details: String?
}

struct PostData: Identifiable, Codable {
    let id: String
    let content: String
    let author: AuthorData
    let media: [MediaData]?
    let location: SearchLocationData?
    let createdAt: String
    let updatedAt: String
}

struct AuthorData: Codable {
    let id: String
    let name: String
    let profileImage: String?
}

struct MediaData: Codable {
    let type: String
    let url: String
    let thumbnail: String?
    let alt: String?
}

// MARK: - Category Model
struct Category: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let icon: String?
    let color: String?
    let isActive: Bool?
    let parentCategory: String?
    let subcategories: [String]?
    let createdAt: String?
    let updatedAt: String?
    let slug: String?
    let type: String?
    let meta: [String: String]? // Simplified for API compatibility
    let source: String?
    let showInFilter: Bool?
    let foursquareIcon: [String: String]? // Simplified for API compatibility
}

// MARK: - Location Detail Models

struct Review: Identifiable, Codable {
    let id: String
    let title: String?
    let content: String
    let rating: Double
    let author: ReviewAuthor?
    let visitDate: String?
    let pros: [String]?
    let cons: [String]?
    let tips: String?
    let isVerifiedVisit: Bool?
    let helpfulCount: Int?
    let createdAt: String?
}

struct ReviewAuthor: Codable {
    let id: String?
    let name: String?
    let avatar: String?
}

struct InsiderTip: Identifiable, Codable {
    let id: String? // May be missing, use UUID if needed
    let category: String
    let tip: String
    let priority: String?
    let source: String?
    let submittedBy: String?
    let submittedAt: String?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case id, category, tip, priority, source, submittedBy, submittedAt, status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decode(String.self, forKey: .id)
        category = try container.decode(String.self, forKey: .category)
        tip = try container.decode(String.self, forKey: .tip)
        priority = try? container.decode(String.self, forKey: .priority)
        source = try? container.decode(String.self, forKey: .source)
        status = try? container.decode(String.self, forKey: .status)
        
        // Handle submittedBy - it can be either a string or a user object
        if let submittedByString = try? container.decode(String.self, forKey: .submittedBy) {
            submittedBy = submittedByString
        } else if let submittedByObject = try? container.decode([String: String].self, forKey: .submittedBy) {
            // If it's a user object, extract the name
            submittedBy = submittedByObject["name"] ?? submittedByObject["id"]
        } else {
            submittedBy = nil
        }
        
        // Handle submittedAt - it can be a string or a date
        if let submittedAtString = try? container.decode(String.self, forKey: .submittedAt) {
            submittedAt = submittedAtString
        } else {
            submittedAt = nil
        }
    }
}

struct CommunityPhoto: Identifiable, Codable {
    let id: String? // May be missing, use UUID if needed
    let photoUrl: String
    let caption: String?
    let submittedBy: String?
    let submittedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, photo, caption, submittedBy, submittedAt
    }

    // Memberwise initializer for manual construction
    init(id: String?, photoUrl: String, caption: String?, submittedBy: String?, submittedAt: String?) {
        self.id = id
        self.photoUrl = photoUrl
        self.caption = caption
        self.submittedBy = submittedBy
        self.submittedAt = submittedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decode(String.self, forKey: .id)
        caption = try? container.decode(String.self, forKey: .caption)
        submittedBy = try? container.decode(String.self, forKey: .submittedBy)
        submittedAt = try? container.decode(String.self, forKey: .submittedAt)
        // Convert media ID to URL
        if let photoId = try? container.decode(String.self, forKey: .photo) {
            photoUrl = "\(baseAPIURL)/api/media/\(photoId)"
        } else {
            photoUrl = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(caption, forKey: .caption)
        try container.encodeIfPresent(submittedBy, forKey: .submittedBy)
        try container.encodeIfPresent(submittedAt, forKey: .submittedAt)
        // Convert URL back to photo ID for encoding
        if !photoUrl.isEmpty {
            let photoId = photoUrl.replacingOccurrences(of: "\(baseAPIURL)/api/media/", with: "")
            try container.encode(photoId, forKey: .photo)
        }
    }
}

// MARK: - Response Models

struct ReviewsResponse: Codable {
    let success: Bool
    let data: ReviewsData
}

struct ReviewsData: Codable {
    let reviews: [Review]
}

struct TipsResponse: Codable {
    let success: Bool
    let data: TipsData
}

struct TipsData: Codable {
    let tips: [InsiderTip]
}

struct CommunityPhotosResponse: Codable {
    let success: Bool
    let data: CommunityPhotosData
}

struct CommunityPhotosData: Codable {
    let photos: [CommunityPhoto]
}

// MARK: - Location Detail Response Models
// LocationDetailData and LocationDetailResponse are defined in EnhancedLocationDetailView.swift 

// Extension moved to LocationsMapTabView.swift to avoid compilation issues
// extension Location {
//     init(from searchLocation: SearchLocation) {
//         self.id = searchLocation.id
//         self.name = searchLocation.name
//         self.address = searchLocation.address
//         self.coordinates = MapCoordinates(
//             latitude: searchLocation.coordinates?.latitude ?? 0,
//             longitude: searchLocation.coordinates?.longitude ?? 0
//         )
//         self.featuredImage = searchLocation.featuredImage
//         self.imageUrl = nil
//         self.rating = searchLocation.rating
//         self.description = searchLocation.description
//         self.shortDescription = nil
//         self.slug = nil
//         self.gallery = nil
//         self.categories = searchLocation.categories
//         self.tags = nil
//         self.priceRange = nil
//         self.businessHours = nil
//         self.contactInfo = nil
//         self.accessibility = nil
//         self.bestTimeToVisit = nil
//         self.insiderTips = nil
//         self.isVerified = searchLocation.isVerified
//         self.isFeatured = searchLocation.isFeatured
//         self.hasBusinessPartnership = nil
//         self.partnershipDetails = nil
//         self.neighborhood = nil
//         self.isSaved = nil
//         self.isSubscribed = nil
//         self.createdBy = nil
//         self.createdAt = searchLocation.createdAt
//         self.updatedAt = searchLocation.updatedAt
//         self.reviewCount = searchLocation.reviewCount
//         self.visitCount = nil
//         self.reviews = nil
//         self.communityPhotos = nil
//     }
// } 

// MARK: - Profile Event Model
struct ProfileEvent: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let slug: String?
    let eventType: String?
    let category: String?
    let startDate: String?
    let endDate: String?
    let image: EventImage?
    let gallery: [EventGalleryItem]?
    let location: EventLocation?
    let organizer: EventOrganizer?
    let capacity: Int?
    let attendeeCount: Int
    let interestedCount: Int?
    let goingCount: Int?
    let invitedCount: Int?
    let isFree: Bool?
    let price: Double?
    let currency: String?
    let status: EventStatus
    let isMatchmaking: Bool?
    let matchmakingSettings: [String: String]?
    let ageRestriction: String?
    let requiresApproval: Bool?
    let tags: [String]?
    let userRsvpStatus: String?
    let createdAt: String
    let updatedAt: String
    
    var formattedDate: String {
        guard let startDate = startDate else { return "TBD" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: startDate) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return startDate
    }
    
    // Custom coding keys to handle optional fields
    enum CodingKeys: String, CodingKey {
        case id, name, description, slug, eventType, category, startDate, endDate
        case image, gallery, location, organizer, capacity, attendeeCount
        case interestedCount, goingCount, invitedCount, isFree, price, currency
        case status, isMatchmaking, matchmakingSettings, ageRestriction
        case requiresApproval, tags, userRsvpStatus, createdAt, updatedAt
    }
    
    // Custom initializer to handle optional fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        slug = try container.decodeIfPresent(String.self, forKey: .slug)
        eventType = try container.decodeIfPresent(String.self, forKey: .eventType)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        image = try container.decodeIfPresent(EventImage.self, forKey: .image)
        gallery = try container.decodeIfPresent([EventGalleryItem].self, forKey: .gallery)
        location = try container.decodeIfPresent(EventLocation.self, forKey: .location)
        organizer = try container.decodeIfPresent(EventOrganizer.self, forKey: .organizer)
        capacity = try container.decodeIfPresent(Int.self, forKey: .capacity)
        attendeeCount = try container.decode(Int.self, forKey: .attendeeCount)
        interestedCount = try container.decodeIfPresent(Int.self, forKey: .interestedCount)
        goingCount = try container.decodeIfPresent(Int.self, forKey: .goingCount)
        invitedCount = try container.decodeIfPresent(Int.self, forKey: .invitedCount)
        isFree = try container.decodeIfPresent(Bool.self, forKey: .isFree)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        currency = try container.decodeIfPresent(String.self, forKey: .currency)
        status = try container.decode(EventStatus.self, forKey: .status)
        isMatchmaking = try container.decodeIfPresent(Bool.self, forKey: .isMatchmaking)
        matchmakingSettings = try container.decodeIfPresent([String: String].self, forKey: .matchmakingSettings)
        ageRestriction = try container.decodeIfPresent(String.self, forKey: .ageRestriction)
        requiresApproval = try container.decodeIfPresent(Bool.self, forKey: .requiresApproval)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        userRsvpStatus = try container.decodeIfPresent(String.self, forKey: .userRsvpStatus)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
    
    // Custom encoder to handle optional fields
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(slug, forKey: .slug)
        try container.encodeIfPresent(eventType, forKey: .eventType)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(gallery, forKey: .gallery)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(organizer, forKey: .organizer)
        try container.encodeIfPresent(capacity, forKey: .capacity)
        try container.encode(attendeeCount, forKey: .attendeeCount)
        try container.encodeIfPresent(interestedCount, forKey: .interestedCount)
        try container.encodeIfPresent(goingCount, forKey: .goingCount)
        try container.encodeIfPresent(invitedCount, forKey: .invitedCount)
        try container.encodeIfPresent(isFree, forKey: .isFree)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encodeIfPresent(currency, forKey: .currency)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(isMatchmaking, forKey: .isMatchmaking)
        try container.encodeIfPresent(matchmakingSettings, forKey: .matchmakingSettings)
        try container.encodeIfPresent(ageRestriction, forKey: .ageRestriction)
        try container.encodeIfPresent(requiresApproval, forKey: .requiresApproval)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(userRsvpStatus, forKey: .userRsvpStatus)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - Event Image Model
struct EventImage: Codable {
    let url: String
    let alt: String?
}

enum EventStatus: String, Codable {
    case draft = "draft"
    case published = "published"
    case cancelled = "cancelled"
    case completed = "completed"
    
    var color: Color {
        switch self {
        case .draft:
            return .gray
        case .published:
            return .green
        case .cancelled:
            return .red
        case .completed:
            return .blue
        }
    }
}

// MARK: - Location Interaction State Models

struct LocationInteractionState: Codable {
    let locationId: String
    let isSaved: Bool
    let isSubscribed: Bool
    let saveCount: Int
    let subscriberCount: Int
}

struct LocationInteractionStateData: Codable {
    let interactions: [LocationInteractionState]
    let totalLocations: Int
    let totalSaved: Int
    let totalSubscribed: Int
}

struct LocationInteractionStateResponse: Codable {
    let success: Bool
    let message: String
    let data: LocationInteractionStateData?
    let error: String?
    let code: String?
}

// MARK: - Event Participants Types

struct EventParticipant: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let eventId: String
    let status: String
    let createdAt: String
    let user: EventParticipantUser?
    let invitedBy: EventParticipantUser?
    let checkInTime: String?
    let isCheckedIn: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: EventParticipant, rhs: EventParticipant) -> Bool {
        return lhs.id == rhs.id
    }
}

struct EventParticipantUser: Codable {
    let id: String
    let name: String
    let avatar: String?
}

struct EventParticipantsData: Codable {
    let participants: [EventParticipant]
    let totalCount: Int
}

struct EventParticipantsResponse: Codable {
    let success: Bool
    let message: String
    let data: EventParticipantsData?
    let error: String?
    let code: String?
}

struct EventResponse: Codable {
    let success: Bool
    let message: String
    let data: Event?
    let error: String?
    let code: String?
}