//
//  APIService.swift
//  SacaviaApp
//
//  Created by Antonio Kodheli on 7/16/25.
//

import Foundation
import UIKit
import SwiftUI

// MARK: - API Configuration
struct APIConfig {
    // Environment configuration - matches Utils.swift
    static let isDevelopment = false
    
    // Base URLs - automatically set based on environment
    static let baseURL = "https://sacavia.com"
    // Remove the pre-pended /api/mobile to avoid double prefixes
    static let webAPIURL = "\(baseURL)/api"
}

// MARK: - Comment Model
struct Comment: Identifiable, Codable, Hashable, Equatable {
    let id: String
    let parentId: String?
    let author: Author
    let content: String
    let createdAt: String
    var replies: [Comment]? // Optional, for threading
    
    // Computed property for backward compatibility
    var authorName: String {
        return author.name
    }
}

struct Author: Codable, Hashable, Equatable {
    let id: String
    let name: String
    let avatar: String?
}



// MARK: - API Service
class APIService: ObservableObject {
    // Singleton instance
    static let shared = APIService()
    
    // Use the same baseURL as Utils.swift to avoid double prefixes
    static let baseURL = baseAPIURL
    
    var token: String? {
        // Get token from AuthManager
        let authToken = AuthManager.shared.token
        print("🔍 [APIService] Token access - AuthManager.shared.token: \(authToken != nil ? "Available" : "Nil")")
        if let token = authToken {
            print("🔍 [APIService] Token prefix: \(String(token.prefix(20)))...")
        }
        return authToken
    }
    
    init() {}
    
    // MARK: - Test Methods
    
    func testConnection() async throws -> Bool {
        let url = URL(string: "\(APIService.baseURL)/api/mobile/test")!
        let request = URLRequest(url: url)
        
        print("🧪 [APIService] Testing connection to: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🧪 [APIService] Test response status: \(httpResponse.statusCode)")
        }
        
        let testResponse = try JSONDecoder().decode(TestResponse.self, from: data)
        print("🧪 [APIService] Test response: \(testResponse)")
        
        return testResponse.success
    }
    
    func testProfile() async throws -> ProfileUser {
        let url = URL(string: "\(APIService.baseURL)/api/mobile/test-profile")!
        let request = URLRequest(url: url)
        
        print("🧪 [APIService] Testing profile endpoint: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🧪 [APIService] Profile test response status: \(httpResponse.statusCode)")
        }
        
        let profileResponse = try JSONDecoder().decode(ProfileResponse.self, from: data)
        print("🧪 [APIService] Profile test response: \(profileResponse)")
        
        if profileResponse.success, let profileData = profileResponse.data {
            return profileData.user
        } else {
            throw APIError.serverError(profileResponse.error ?? "Failed to load test profile")
        }
    }
    
    // MARK: - Profile Methods
    
    func getUserProfile(userId: String? = nil) async throws -> (ProfileUser, [ProfilePost]) {
        var urlString: String
        
        if let userId = userId {
            // For other users, use the profile endpoint with userId as query parameter
            urlString = "\(APIService.baseURL)/api/mobile/users/profile?userId=\(userId)&includeFullData=true&postsLimit=10"
        } else {
            // For current user, use the profile endpoint
            urlString = "\(APIService.baseURL)/api/mobile/users/profile?includeFullData=true&postsLimit=10"
        }
        
        print("🔍 [APIService] Getting user profile from: \(urlString)")
        print("🔍 [APIService] Base URL: \(APIService.baseURL)")
        print("🔍 [APIService] User ID parameter: \(userId ?? "nil")")
        
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        // Print response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 [APIService] Profile response: \(responseString)")
            print("🔍 [APIService] Response length: \(responseString.count) characters")
        }
        
        print("🔍 [APIService] Attempting to decode JSON response...")
        let profileResponse = try JSONDecoder().decode(ProfileResponse.self, from: data)
        print("🔍 [APIService] JSON decoded successfully")
        print("🔍 [APIService] Response success: \(profileResponse.success)")
        print("🔍 [APIService] Has data: \(profileResponse.data != nil)")
        
        guard profileResponse.success, let profileData = profileResponse.data else {
            print("🔍 [APIService] Profile data not found or success is false")
            throw APIError.serverError("Profile data not found")
        }
        
        print("🔍 [APIService] Profile loaded successfully: \(profileData.user.name)")
        print("🔍 [APIService] Stats: posts=\(profileData.user.stats?.postsCount ?? 0), followers=\(profileData.user.stats?.followersCount ?? 0), following=\(profileData.user.stats?.followingCount ?? 0)")
        print("🔍 [APIService] Recent posts count: \(profileData.recentPosts?.count ?? 0)")
        print("🔍 [APIService] Profile ID: \(profileData.user.id)")
        print("🔍 [APIService] Profile username: \(profileData.user.username ?? "nil")")
        print("🔍 [APIService] Profile bio: \(profileData.user.bio ?? "nil")")
        print("🔍 [APIService] Full stats object: \(String(describing: profileData.user.stats))")
        print("🔍 [APIService] Stats breakdown:")
        print("  - Posts: \(profileData.user.stats?.postsCount ?? 0)")
        print("  - Followers: \(profileData.user.stats?.followersCount ?? 0)")
        print("  - Following: \(profileData.user.stats?.followingCount ?? 0)")
        print("  - Saved Posts: \(profileData.user.stats?.savedPostsCount ?? 0)")
        print("  - Liked Posts: \(profileData.user.stats?.likedPostsCount ?? 0)")
        print("  - Locations: \(profileData.user.stats?.locationsCount ?? 0)")
        print("  - Reviews: \(profileData.user.stats?.reviewCount ?? 0)")
        print("  - Recommendations: \(profileData.user.stats?.recommendationCount ?? 0)")
        print("  - Average Rating: \(profileData.user.stats?.averageRating ?? 0)")
        
        return (profileData.user, profileData.recentPosts ?? [])
    }
    
    func updateProfile(profileData: [String: Any]) async throws -> ProfileUser {
        let url = URL(string: "\(APIService.baseURL)/api/mobile/users/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        if let token = token {
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONSerialization.data(withJSONObject: profileData)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        let profileResponse = try JSONDecoder().decode(ProfileResponse.self, from: data)
        
        guard profileResponse.success, let profileData = profileResponse.data else {
            throw APIError.serverError("Profile data not found")
        }
        
        return profileData.user
    }
    
    func getUserStats(userId: String) async throws -> UserStats {
        let url = URL(string: "\(APIService.baseURL)/api/mobile/users/\(userId)/stats")!
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        let statsResponse = try JSONDecoder().decode(StatsResponse.self, from: data)
        
        guard statsResponse.success, let statsData = statsResponse.data else {
            throw APIError.serverError("Stats data not found")
        }
        
        return statsData.stats
    }
    
    func getUserPosts(userId: String, type: String = "all", page: Int = 1, limit: Int = 20) async throws -> [ProfilePost] {
        let urlString = "\(APIService.baseURL)/api/mobile/users/\(userId)/posts?type=\(type)&page=\(page)&limit=\(limit)"
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        let postsResponse = try JSONDecoder().decode(UserPostsResponse.self, from: data)
        
        guard postsResponse.success, let postsData = postsResponse.data else {
            throw APIError.serverError("Posts data not found")
        }
        
        return postsData.posts
    }
    
    func getUserPhotos(userId: String, type: String = "all", page: Int = 1, limit: Int = 20) async throws -> [UserPhoto] {
        let urlString = "\(APIService.baseURL)/api/mobile/users/\(userId)/photos?type=\(type)&page=\(page)&limit=\(limit)"
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        let photosResponse = try JSONDecoder().decode(PhotosResponse.self, from: data)
        
        guard photosResponse.success, let photosData = photosResponse.data else {
            throw APIError.serverError("Photos data not found")
        }
        
        return photosData.photos
    }
    
    func followUser(userId: String) async throws -> Bool {
        let url = URL(string: "\(APIService.baseURL)/api/mobile/users/\(userId)/follow")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add cookie token for mobile API (same as AuthManager.createAuthenticatedRequest)
        if let token = token {
            print("🔍 [APIService] Follow request - Cookie token set: \(String(token.prefix(20)))...")
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        } else {
            print("🔍 [APIService] Follow request - No token available")
            throw APIError.authenticationRequired
        }
        
        print("🔍 [APIService] Follow request URL: \(url)")
        print("🔍 [APIService] Follow request method: \(request.httpMethod ?? "Unknown")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("🔍 [APIService] Follow response status: \(httpResponse.statusCode)")
        
        // Print response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 [APIService] Follow response: \(responseString)")
        }
        
        if httpResponse.statusCode == 401 {
            print("🔍 [APIService] Follow request unauthorized (401)")
            throw APIError.unauthorized
        }
        
        // Handle 409 Conflict - user is already following the target user
        if httpResponse.statusCode == 409 {
            print("🔍 [APIService] User is already following target user (409 Conflict)")
            // Return true to indicate the desired state (following) is achieved
            return true
        }
        
        if httpResponse.statusCode != 200 {
            print("🔍 [APIService] Follow request failed with status: \(httpResponse.statusCode)")
            // Try to decode error response for better error message
            if let errorResponse = try? JSONDecoder().decode(FollowResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error ?? "HTTP \(httpResponse.statusCode)")
            } else {
                throw APIError.serverError("HTTP \(httpResponse.statusCode)")
            }
        }
        
        let followResponse = try JSONDecoder().decode(FollowResponse.self, from: data)
        print("🔍 [APIService] Follow response decoded successfully: \(followResponse.success)")
        
        return followResponse.success
    }
    
    func unfollowUser(userId: String) async throws -> Bool {
        let url = URL(string: "\(APIService.baseURL)/api/mobile/users/\(userId)/follow")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Add cookie token for mobile API (same as AuthManager.createAuthenticatedRequest)
        if let token = token {
            print("🔍 [APIService] Unfollow request - Cookie token set: \(String(token.prefix(20)))...")
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        } else {
            print("🔍 [APIService] Unfollow request - No token available")
            throw APIError.authenticationRequired
        }
        
        print("🔍 [APIService] Unfollow request URL: \(url)")
        print("🔍 [APIService] Unfollow request method: \(request.httpMethod ?? "Unknown")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("🔍 [APIService] Unfollow response status: \(httpResponse.statusCode)")
        
        // Print response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 [APIService] Unfollow response: \(responseString)")
        }
        
        if httpResponse.statusCode == 401 {
            print("🔍 [APIService] Unfollow request unauthorized (401)")
            throw APIError.unauthorized
        }
        
        // Handle 409 Conflict - user is not following the target user
        if httpResponse.statusCode == 409 {
            print("🔍 [APIService] User is not following target user (409 Conflict)")
            // Return false to indicate the operation failed because user is not following
            return false
        }
        
        if httpResponse.statusCode != 200 {
            print("🔍 [APIService] Unfollow request failed with status: \(httpResponse.statusCode)")
            // Try to decode error response for better error message
            if let errorResponse = try? JSONDecoder().decode(FollowResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error ?? "HTTP \(httpResponse.statusCode)")
            } else {
                throw APIError.serverError("HTTP \(httpResponse.statusCode)")
            }
        }
        
        let followResponse = try JSONDecoder().decode(FollowResponse.self, from: data)
        print("🔍 [APIService] Unfollow response decoded successfully: \(followResponse.success)")
        
        return followResponse.success
    }
    

    
    // MARK: - Post Creation (OPTIMIZED)
    
    func createPost(content: String, locationId: String? = nil, locationName: String? = nil, images: [UIImage] = [], videos: [Data] = [], progressHandler: ((Double) -> Void)? = nil) async throws -> Bool {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/posts") else {
            throw APIError.invalidURL
        }
        
        print("📱 APIService: Creating post with \(images.count) images and \(videos.count) videos")
        print("📱 APIService: Content: '\(content)'")
        print("📱 APIService: Location ID: \(locationId ?? "None")")
        print("📱 APIService: Location Name: \(locationName ?? "None")")
        
        // Validate input
        if images.isEmpty && videos.isEmpty && content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("📱 APIService: Error - No content or media provided")
            throw APIError.serverError("No content or media provided")
        }
        
        // Create request with cookie-based authentication (same as AuthManager)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add cookie token for mobile API (same as AuthManager.createAuthenticatedRequest)
        if let token = token {
            print("📱 APIService: Got valid token: \(String(token.prefix(20)))...")
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
            print("📱 APIService: Added cookie token for authentication")
        } else {
            print("📱 APIService: No valid token available")
            print("📱 APIService: AuthManager token: \(token?.prefix(20) ?? "None")")
            print("📱 APIService: AuthManager isAuthenticated: \(token == nil)")
            throw APIError.authenticationRequired
        }
        
        // Debug: Print all request headers
        print("📱 APIService: Request headers:")
        request.allHTTPHeaderFields?.forEach { key, value in
            if key == "Authorization" {
                print("   \(key): \(String(value.prefix(30)))...")
            } else {
                print("   \(key): \(value)")
            }
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add content
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"content\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(content)\r\n".data(using: .utf8)!)
        
        // Add location
        if let locationId = locationId {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"locationId\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(locationId)\r\n".data(using: .utf8)!)
        } else if let locationName = locationName {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"locationName\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(locationName)\r\n".data(using: .utf8)!)
        }
        
        // OPTIMIZATION: Process images with better compression and progress tracking
        print("📱 APIService: Processing \(images.count) images")
        let totalFiles = images.count + videos.count
        var processedFiles = 0
        
        for (index, image) in images.enumerated() {
            // OPTIMIZATION: Use adaptive compression based on image size
            let compressionQuality = getOptimalCompressionQuality(for: image)
            
            if let imageData = image.jpegData(compressionQuality: compressionQuality) {
                print("📱 APIService: Adding image \(index + 1) - \(imageData.count) bytes (compression: \(compressionQuality))")
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"images\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
                
                processedFiles += 1
                let progress = Double(processedFiles) / Double(totalFiles)
                progressHandler?(progress)
            } else {
                print("📱 APIService: Failed to convert image \(index + 1) to JPEG data")
                throw APIError.serverError("Failed to process image \(index + 1)")
            }
        }
        
        // OPTIMIZATION: Process videos with progress tracking
        print("📱 APIService: Processing \(videos.count) videos")
        for (index, videoData) in videos.enumerated() {
            print("📱 APIService: Adding video \(index + 1) - \(videoData.count) bytes")
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"videos\"; filename=\"video\(index).mp4\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
            body.append(videoData)
            body.append("\r\n".data(using: .utf8)!)
            
            processedFiles += 1
            let progress = Double(processedFiles) / Double(totalFiles)
            progressHandler?(progress)
        }
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        print("📱 APIService: Total request body size: \(body.count) bytes")
        request.httpBody = body
        
        // OPTIMIZATION: Set timeout for large uploads
        request.timeoutInterval = 120 // 2 minutes for large uploads
        
        print("📱 APIService: Sending request to \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("📱 APIService: Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("📱 APIService: Response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📱 APIService: Response body: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let success = result?["success"] as? Bool ?? false
            print("📱 APIService: Post creation \(success ? "succeeded" : "failed")")
            
            // Call progress handler with 100% completion
            progressHandler?(1.0)
            
            return success
        } else {
            print("📱 APIService: HTTP Error \(httpResponse.statusCode)")
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorData["message"] as? String {
                print("📱 APIService: Error message: \(message)")
                throw APIError.serverError(message)
            }
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
    }
    
    // OPTIMIZATION: Helper function to determine optimal compression quality
    private func getOptimalCompressionQuality(for image: UIImage) -> CGFloat {
        let imageSize = image.size
        let pixelCount = imageSize.width * imageSize.height
        
        // Use higher quality for smaller images, lower quality for larger images
        if pixelCount < 500_000 { // Less than 500K pixels
            return 0.9
        } else if pixelCount < 1_000_000 { // Less than 1M pixels
            return 0.8
        } else if pixelCount < 2_000_000 { // Less than 2M pixels
            return 0.7
        } else {
            return 0.6 // For very large images
        }
    }
    
    // MARK: - Location Search
    
    func searchLocations(query: String) async throws -> [SearchLocationData] {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/locations/search") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header
        if let token = token {
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        }
        
        let body = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        if httpResponse.statusCode == 200 {
            let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let success = result?["success"] as? Bool, success,
               let locations = result?["locations"] as? [[String: Any]] {
                return locations.compactMap { locationData in
                    guard let id = locationData["id"] as? String,
                          let name = locationData["name"] as? String else {
                        return nil
                    }
                    
                    let address = locationData["address"] as? String ?? ""
                    return SearchLocationData(id: id, name: name, address: address)
                }
            }
            return []
        } else {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Media Upload (OPTIMIZED)
    
    func uploadMedia(image: UIImage, progressHandler: ((Double) -> Void)? = nil) async throws -> String {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/upload/image") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add authentication header
        if let token = token {
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // OPTIMIZATION: Use adaptive compression
        let compressionQuality = getOptimalCompressionQuality(for: image)
        
        // Add image data
        if let imageData = image.jpegData(compressionQuality: compressionQuality) {
            print("📱 APIService: Uploading image with compression \(compressionQuality) - \(imageData.count) bytes")
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
            
            // Report progress
            progressHandler?(0.5)
        } else {
            throw APIError.serverError("Failed to process image")
        }
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        request.timeoutInterval = 60 // 1 minute timeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        if httpResponse.statusCode == 200 {
            let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let success = result?["success"] as? Bool, success,
               let data = result?["data"] as? [String: Any],
               let url = data["url"] as? String {
                
                // Report completion
                progressHandler?(1.0)
                
                return url
            }
            throw APIError.serverError("Invalid response format")
        } else {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Account Deletion
    
    func deleteAccount(password: String, reason: String? = nil) async throws -> Bool {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/users/delete-account") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw APIError.authenticationRequired
        }
        
        let body: [String: Any] = [
            "password": password,
            "reason": reason ?? "User requested account deletion"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode == 400 {
            let errorResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorResponse?["error"] as? String ?? "Account deletion failed"
            throw APIError.serverError(errorMessage)
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let success = result?["success"] as? Bool ?? false
        
        return success
    }
    
    // MARK: - Content Reporting
    
    func reportContent(contentType: String, contentId: String, reason: String, description: String? = nil) async throws -> Bool {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/reports") else {
            throw APIError.invalidURL
        }
        
        print("🔍 [APIService] Reporting content: \(contentType) - \(contentId)")
        print("🔍 [APIService] Report URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔍 [APIService] Authorization header set for report request")
        } else {
            print("🔍 [APIService] No token available for report request")
            throw APIError.authenticationRequired
        }
        
        let body: [String: Any] = [
            "contentType": contentType,
            "contentId": contentId,
            "reason": reason,
            "description": description ?? ""
        ]
        
        print("🔍 [APIService] Report request body: \(body)")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔍 [APIService] Invalid response type for report")
            throw APIError.invalidResponse
        }
        
        print("🔍 [APIService] Report response status: \(httpResponse.statusCode)")
        
        // Print response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 [APIService] Report response data: \(responseString)")
        }
        
        if httpResponse.statusCode == 401 {
            print("🔍 [APIService] Report request unauthorized")
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode == 400 {
            let errorResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorResponse?["error"] as? String ?? "Failed to report content"
            print("🔍 [APIService] Report request bad request: \(errorMessage)")
            throw APIError.serverError(errorMessage)
        }
        
        if httpResponse.statusCode == 500 {
            let errorResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorResponse?["error"] as? String ?? "Internal server error"
            print("🔍 [APIService] Report request server error: \(errorMessage)")
            throw APIError.serverError("Server error: \(errorMessage)")
        }
        
        if httpResponse.statusCode != 200 {
            print("🔍 [APIService] Report request failed with status: \(httpResponse.statusCode)")
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let success = result?["success"] as? Bool ?? false
        
        print("🔍 [APIService] Report request successful: \(success)")
        return success
    }
    
    // MARK: - User Blocking
    
    func blockUser(targetUserId: String, reason: String? = nil) async throws -> Bool {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/users/block") else {
            throw APIError.invalidURL
        }
        
        print("🔍 [APIService] Blocking user: \(targetUserId)")
        print("🔍 [APIService] Block URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔍 [APIService] Authorization header set: Bearer \(String(token.prefix(20)))...")
        } else {
            print("🔍 [APIService] No token available for block request")
            throw APIError.authenticationRequired
        }
        
        let body: [String: Any] = [
            "targetUserId": targetUserId,
            "reason": reason ?? ""
        ]
        
        print("🔍 [APIService] Request body: \(body)")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Debug all headers
        print("🔍 [APIService] All request headers:")
        for (key, value) in request.allHTTPHeaderFields ?? [:] {
            print("🔍 [APIService] \(key): \(value)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔍 [APIService] Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("🔍 [APIService] Block response status: \(httpResponse.statusCode)")
        
        // Print response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 [APIService] Block response: \(responseString)")
        }
        
        if httpResponse.statusCode == 401 {
            print("🔍 [APIService] Unauthorized (401) - authentication failed")
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode == 400 {
            let errorResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorResponse?["error"] as? String ?? "Failed to block user"
            print("🔍 [APIService] Bad request (400): \(errorMessage)")
            throw APIError.serverError(errorMessage)
        }
        
        if httpResponse.statusCode == 405 {
            print("🔍 [APIService] Method not allowed (405) - check if endpoint supports POST")
            throw APIError.serverError("Method not allowed - endpoint may not support POST")
        }
        
        if httpResponse.statusCode != 200 {
            print("🔍 [APIService] Unexpected status code: \(httpResponse.statusCode)")
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let success = result?["success"] as? Bool ?? false
        
        if success {
            print("🔍 [APIService] User blocked successfully, removing social connections")
            // Remove social connections after successful block
            try await removeSocialConnections(targetUserId: targetUserId)
        }
        
        return success
    }
    
    // Get list of blocked users
    func getBlockedUsers() async throws -> [String] {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/users/blocked") else {
            throw APIError.invalidURL
        }
        
        print("🔍 [APIService] Getting blocked users")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication header
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw APIError.authenticationRequired
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let blockedUsers = result?["blockedUsers"] as? [String] ?? []
        
        print("🔍 [APIService] Found \(blockedUsers.count) blocked users")
        return blockedUsers
    }
    
    // Remove social connections after blocking (unfollow each other)
    func removeSocialConnections(targetUserId: String) async throws {
        print("🔍 [APIService] Removing social connections with \(targetUserId)")
        
        // Unfollow the target user (remove from following list)
        do {
            _ = try await unfollowUser(userId: targetUserId)
            print("🔍 [APIService] Successfully unfollowed \(targetUserId)")
        } catch {
            print("🔍 [APIService] Error unfollowing \(targetUserId): \(error)")
            // Continue even if unfollow fails
        }
        
        // Note: The backend should handle removing the current user from the target user's followers list
        // This is typically done automatically when a user is blocked
    }
    
    func unblockUser(targetUserId: String) async throws -> Bool {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/users/block?targetUserId=\(targetUserId)") else {
            throw APIError.invalidURL
        }
        
        print("🔍 [APIService] Unblocking user: \(targetUserId)")
        print("🔍 [APIService] Unblock URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔍 [APIService] Authorization header set: Bearer \(String(token.prefix(20)))...")
        } else {
            print("🔍 [APIService] No token available for unblock request")
            throw APIError.authenticationRequired
        }
        
        // Debug all headers
        print("🔍 [APIService] All request headers:")
        for (key, value) in request.allHTTPHeaderFields ?? [:] {
            print("🔍 [APIService] \(key): \(value)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔍 [APIService] Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("🔍 [APIService] Unblock response status: \(httpResponse.statusCode)")
        
        // Print response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 [APIService] Unblock response: \(responseString)")
        }
        
        if httpResponse.statusCode == 401 {
            print("🔍 [APIService] Unauthorized (401) - authentication failed")
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode == 400 {
            let errorResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorResponse?["error"] as? String ?? "Failed to unblock user"
            print("🔍 [APIService] Bad request (400): \(errorMessage)")
            throw APIError.serverError(errorMessage)
        }
        
        if httpResponse.statusCode == 405 {
            print("🔍 [APIService] Method not allowed (405) - check if endpoint supports DELETE")
            throw APIError.serverError("Method not allowed - endpoint may not support DELETE")
        }
        
        if httpResponse.statusCode != 200 {
            print("🔍 [APIService] Unexpected status code: \(httpResponse.statusCode)")
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let success = result?["success"] as? Bool ?? false
        
        return success
    }
    

    
    // MARK: - Authentication Check
    
    func ensureAuthenticated() throws {
        if token == nil {
            throw APIError.authenticationRequired
        }
    }
    
    // MARK: - Test Cookie Header
    func testCookieHeader() {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/test") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = token {
            let cookieValue = "payload-token=\(token)"
            request.setValue(cookieValue, forHTTPHeaderField: "Cookie")
            print("🔍 [APIService] Test Cookie header set: \(cookieValue)")
        } else {
            print("🔍 [APIService] No token available for test")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 [APIService] Test response status: \(httpResponse.statusCode)")
            }
            if let data = data, let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 [APIService] Test response: \(jsonString)")
            }
        }.resume()
    }
    
    // Get list of blocked users with full details
    func getBlockedUsersDetails() async throws -> [BlockedUser] {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/users/blocked") else {
            throw APIError.invalidURL
        }
        
        print("🔍 [APIService] Getting blocked users with details")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication header
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw APIError.authenticationRequired
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        print("🔍 [APIService] Blocked users response: \(result ?? [:])")
        
        // Handle different response formats
        var dataDict: [String: Any]?
        
        if let data = result?["data"] as? [String: Any] {
            dataDict = data
        } else if let data = result as? [String: Any] {
            dataDict = data
        }
        
        guard let dataDict = dataDict else {
            print("🔍 [APIService] No data field in response")
            throw APIError.invalidResponse
        }
        
        print("🔍 [APIService] Data dict: \(dataDict)")
        
        // Try different possible field names for blocked users
        var blockedUsersDetails: [[String: Any]]?
        
        if let details = dataDict["blockedUsersDetails"] as? [[String: Any]] {
            blockedUsersDetails = details
        } else if let details = dataDict["blockedUsers"] as? [[String: Any]] {
            blockedUsersDetails = details
        } else if let details = dataDict["users"] as? [[String: Any]] {
            blockedUsersDetails = details
        }
        
        guard let blockedUsersDetails = blockedUsersDetails else {
            print("🔍 [APIService] No blocked users field found in data")
            print("🔍 [APIService] Available fields: \(dataDict.keys)")
            throw APIError.invalidResponse
        }
        
        let blockedUsers = try blockedUsersDetails.map { userDict in
            let jsonData = try JSONSerialization.data(withJSONObject: userDict)
            return try JSONDecoder().decode(BlockedUser.self, from: jsonData)
        }
        
        print("🔍 [APIService] Found \(blockedUsers.count) blocked users with details")
        return blockedUsers
    }
}

// MARK: - Response Models

struct StatsResponse: Codable {
    let success: Bool
    let message: String
    let data: StatsData?
    let error: String?
    let code: String?
}

struct StatsData: Codable {
    let stats: UserStats
    let achievements: Achievements
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stats = try container.decode(UserStats.self, forKey: .stats)
        achievements = try container.decode(Achievements.self, forKey: .achievements)
    }
    
    enum CodingKeys: String, CodingKey {
        case stats, achievements
    }
}

struct Achievements: Codable {
    let isExpertReviewer: Bool
    let isVerified: Bool
    let isCreator: Bool
    let creatorLevel: String?
    let joinDate: String
    let daysActive: Int
}

struct PostsResponse: Codable {
    let success: Bool
    let message: String
    let data: PostsData?
    let error: String?
    let code: String?
}

struct Pagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrev: Bool
}

struct PostsPagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrev: Bool
}

struct PhotosPagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrev: Bool
}

struct UserPost: Codable, Identifiable {
    let id: String
    let type: String
    let content: String
    let featuredImage: ProfileImage?
    let likeCount: Int
    let commentCount: Int
    let createdAt: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        content = try container.decode(String.self, forKey: .content)
        featuredImage = try container.decodeIfPresent(ProfileImage.self, forKey: .featuredImage)
        likeCount = try container.decode(Int.self, forKey: .likeCount)
        commentCount = try container.decode(Int.self, forKey: .commentCount)
        createdAt = try container.decode(String.self, forKey: .createdAt)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, content, featuredImage, likeCount, commentCount, createdAt
    }
}

struct UserPhoto: Codable, Identifiable {
    let id: String
    let url: String
    let createdAt: String
}

struct PhotosResponse: Codable {
    let success: Bool
    let message: String
    let data: PhotosData?
    let error: String?
    let code: String?
}

struct PhotosData: Codable {
    let photos: [UserPhoto]
    let pagination: PhotosPagination
    let stats: PhotoStats
}

struct PhotoStats: Codable {
    let totalPhotos: Int
    let totalPostPhotos: Int
    let totalReviewPhotos: Int
    let totalLocationPhotos: Int
}

// MARK: - Profile Types
// ProfileUser is defined in SharedTypes.swift

struct ProfileResponse: Codable {
    let success: Bool
    let message: String
    let data: ProfileData?
    let error: String?
}

struct ProfileData: Codable {
    let user: ProfileUser
    let recentPosts: [ProfilePost]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decode(ProfileUser.self, forKey: .user)
        recentPosts = try container.decodeIfPresent([ProfilePost].self, forKey: .recentPosts)
    }
    
    enum CodingKeys: String, CodingKey {
        case user, recentPosts
    }
}

// ProfilePost is defined in SharedTypes.swift

// MARK: - User Posts Response Models
struct UserPostsResponse: Codable {
    let success: Bool
    let message: String
    let data: UserPostsData?
    let error: String?
    let code: String?
}

struct UserPostsData: Codable {
    let posts: [ProfilePost]
    let pagination: UserPostsPagination
    let user: ProfileUser
}

struct UserPostsPagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrev: Bool
}

struct PostsData: Codable {
    let posts: [UserPost]
    let pagination: PostsPagination
    let stats: PostsStats
}

struct PostsStats: Codable {
    let totalPosts: Int
    let totalReviews: Int
    let totalRecommendations: Int
    let averageRating: Double?
}

struct FollowResponse: Codable {
    let success: Bool
    let message: String
    let data: FollowData?
    let error: String?
    let code: String?
}

struct FollowData: Codable {
    let isFollowing: Bool
    let followersCount: Int
    let userId: String
}



// MARK: - Existing Response Models (keep your existing models)

struct LoginResponse: Codable {
    let success: Bool
    let message: String
    let data: LoginData?
    let error: String?
    let code: String?
}

struct LoginData: Codable {
    let user: User
    let token: String
    let expiresIn: Int
}

// Using User type from SharedTypes.swift

extension APIService {
    func fetchCategories() async throws -> [Category] {
        guard let url = URL(string: "\(baseAPIURL)/api/categories") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let docs = json?["docs"] as? [[String: Any]] else {
            throw APIError.serverError("Malformed categories response")
        }
        let categoriesData = try JSONSerialization.data(withJSONObject: docs)
        let categories = try JSONDecoder().decode([Category].self, from: categoriesData)
        return categories
    }
} 

extension APIService {
    func likePost(postId: String) async throws {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/posts/\(postId)/like") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token = token { request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie") }
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw APIError.invalidResponse }
    }
    func unlikePost(postId: String) async throws {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/posts/\(postId)/like") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if let token = token { request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie") }
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw APIError.invalidResponse }
    }
    func savePost(postId: String) async throws {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/posts/\(postId)/save") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token = token { request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie") }
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw APIError.invalidResponse }
    }
    func unsavePost(postId: String) async throws {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/posts/\(postId)/save") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if let token = token { request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie") }
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw APIError.invalidResponse }
    }
    func fetchComments(postId: String) async throws -> [Comment] {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/posts/comments?postId=\(postId)") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = token { request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie") }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw APIError.invalidResponse }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        print("📝 Comments API response:", json as Any)
        
        // The backend returns { success: true, data: { comments: [...] } }
        guard let dataObj = json?["data"] as? [String: Any],
              let commentsArr = dataObj["comments"] as? [[String: Any]] else { 
            print("📝 No comments found in response")
            return [] 
        }
        
        let commentsData = try JSONSerialization.data(withJSONObject: commentsArr)
        let comments: [Comment] = try JSONDecoder().decode([Comment].self, from: commentsData)
        print("📝 Parsed \(comments.count) comments")
        return comments
    }
    func addComment(postId: String, content: String, parentId: String?) async throws {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/posts/comments") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token { request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie") }
        let body: [String: Any] = ["postId": postId, "content": content, "parentId": parentId as Any]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw APIError.invalidResponse }
    }
    
    // MARK: - Interaction State Methods
    
    func checkInteractionState(postIds: [String]) async throws -> InteractionStateResponse {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/posts/interaction-state") else { throw APIError.invalidURL }
        
        print("🔍 [APIService] Checking interaction state for \(postIds.count) posts")
        print("🔍 [APIService] URL: \(url)")
        print("🔍 [APIService] Token available: \(token != nil)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token { 
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔍 [APIService] Authorization header set for interaction state")
        } else {
            print("🔍 [APIService] No token available for interaction state")
        }
        
        let body = ["postIds": postIds]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🔍 [APIService] Request body: \(body)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔍 [APIService] Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("🔍 [APIService] Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            print("🔍 [APIService] Error response: \(String(data: data, encoding: .utf8) ?? "No data")")
            throw APIError.invalidResponse
        }
        
        let interactionResponse = try JSONDecoder().decode(InteractionStateResponse.self, from: data)
        print("🔍 [APIService] Successfully decoded response with \(interactionResponse.data?.interactions.count ?? 0) interactions")
        return interactionResponse
    }
    
    // MARK: - Events API
    func fetchUserEvents(userId: String, completion: @escaping (Result<[ProfileEvent], Error>) -> Void) {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/events?type=created&limit=20") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                do {
                    let eventsResponse = try JSONDecoder().decode(EventsResponse.self, from: data)
                    if eventsResponse.success, let eventsData = eventsResponse.data {
                        completion(.success(eventsData.events))
                    } else {
                        completion(.failure(APIError.serverError(eventsResponse.error ?? "Failed to load events")))
                    }
                } catch {
                    print("🔍 [APIService] Decoding error: \(error)")
                    print("🔍 [APIService] Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Followers API
    func fetchFollowers(userId: String, completion: @escaping (Result<[FollowerUser], Error>) -> Void) {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/users/\(userId)/followers") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        print("🔍 [APIService] Fetching followers for user: \(userId)")
        print("🔍 [APIService] URL: \(url)")
        print("🔍 [APIService] Full URL: \(url.absoluteString)")
        
        // Debug token access
        let currentToken = token
        print("🔍 [APIService] Token available: \(currentToken != nil)")
        if let token = currentToken {
            print("🔍 [APIService] Token prefix: \(String(token.prefix(20)))...")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = currentToken {
            // Use Authorization header like EventsManager (which works)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔍 [APIService] Authorization header set for followers: Bearer \(String(token.prefix(20)))...")
            
            // Debug all headers
            print("🔍 [APIService] All request headers:")
            for (key, value) in request.allHTTPHeaderFields ?? [:] {
                print("🔍 [APIService] \(key): \(value)")
            }
        } else {
            print("🔍 [APIService] No token available for followers request")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🔍 [APIService] Followers network error: \(error)")
                    completion(.failure(error))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔍 [APIService] Followers response status: \(httpResponse.statusCode)")
                }
                
                guard let data = data else {
                    print("🔍 [APIService] No data received for followers")
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                // Print raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🔍 [APIService] Followers raw response: \(jsonString)")
                }
                
                do {
                    // Try to decode as FollowersResponse first (with success field)
                    let followersResponse = try JSONDecoder().decode(FollowersResponse.self, from: data)
                    if followersResponse.success, let followersData = followersResponse.data {
                        print("🔍 [APIService] Successfully loaded \(followersData.followers.count) followers")
                        completion(.success(followersData.followers))
                    } else {
                        print("🔍 [APIService] Followers API error: \(followersResponse.error ?? "Unknown error")")
                        completion(.failure(APIError.serverError(followersResponse.error ?? "Failed to load followers")))
                    }
                } catch {
                    print("🔍 [APIService] Followers decoding error: \(error)")
                    
                    // Try manual parsing like EventsManager
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let data = json["data"] as? [String: Any],
                           let followers = data["followers"] as? [[String: Any]] {
                            
                            print("🔍 [APIService] Manually parsed \(followers.count) followers")
                            
                            let parsedFollowers = followers.compactMap { (followerData: [String: Any]) -> FollowerUser? in
                                guard let id = followerData["id"] as? String,
                                      let name = followerData["name"] as? String else {
                                    return nil
                                }
                                
                                return FollowerUser(
                                    id: id,
                                    name: name,
                                    username: followerData["username"] as? String,
                                    email: followerData["email"] as? String ?? "",
                                    profileImage: followerData["profileImage"] as? String,
                                    bio: followerData["bio"] as? String,
                                    isVerified: followerData["isVerified"] as? Bool,
                                    followerCount: followerData["followerCount"] as? Int
                                )
                            }
                            
                            print("🔍 [APIService] Successfully parsed \(parsedFollowers.count) followers manually")
                            completion(.success(parsedFollowers))
                        } else {
                            print("🔍 [APIService] Failed to parse followers manually")
                            completion(.failure(APIError.serverError("Failed to parse followers response")))
                        }
                    } catch {
                        print("🔍 [APIService] Manual parsing also failed: \(error)")
                        completion(.failure(error))
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Following API
    func fetchFollowing(userId: String, completion: @escaping (Result<[FollowerUser], Error>) -> Void) {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/users/\(userId)/following") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        print("🔍 [APIService] Fetching following for user: \(userId)")
        print("🔍 [APIService] URL: \(url)")
        print("🔍 [APIService] Full URL: \(url.absoluteString)")
        
        // Debug token access
        let currentToken = token
        print("🔍 [APIService] Token available: \(currentToken != nil)")
        if let token = currentToken {
            print("🔍 [APIService] Token prefix: \(String(token.prefix(20)))...")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = currentToken {
            // Use Authorization header like EventsManager (which works)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔍 [APIService] Authorization header set for following: Bearer \(String(token.prefix(20)))...")
            
            // Debug all headers
            print("🔍 [APIService] All request headers:")
            for (key, value) in request.allHTTPHeaderFields ?? [:] {
                print("🔍 [APIService] \(key): \(value)")
            }
        } else {
            print("🔍 [APIService] No token available for following request")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🔍 [APIService] Following network error: \(error)")
                    completion(.failure(error))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔍 [APIService] Following response status: \(httpResponse.statusCode)")
                }
                
                guard let data = data else {
                    print("🔍 [APIService] No data received for following")
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                // Print raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🔍 [APIService] Following raw response: \(jsonString)")
                }
                
                do {
                    let followingResponse = try JSONDecoder().decode(FollowingResponse.self, from: data)
                    if followingResponse.success, let followingData = followingResponse.data {
                        print("🔍 [APIService] Successfully loaded \(followingData.following.count) following")
                        completion(.success(followingData.following))
                    } else {
                        print("🔍 [APIService] Following API error: \(followingResponse.error ?? "Unknown error")")
                        completion(.failure(APIError.serverError(followingResponse.error ?? "Failed to load following")))
                    }
                } catch {
                    print("🔍 [APIService] Following decoding error: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Planner API
    func generatePlan(input: String, context: String, coordinates: Coordinates?) async throws -> PlannerResponse {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/ai-planner") else { throw APIError.invalidURL }
        
        let request = PlannerRequest(input: input, context: context, coordinates: coordinates)
        let jsonData = try JSONEncoder().encode(request)
        
        print("🔍 [APIService] Making AI planner request to: \(url)")
        print("🔍 [APIService] Request data: \(String(data: jsonData, encoding: .utf8) ?? "Unable to encode")")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token { 
            urlRequest.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie") 
            print("🔍 [APIService] Using auth token: \(token.prefix(20))...")
        } else {
            print("🔍 [APIService] No auth token available")
        }
        urlRequest.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🔍 [APIService] Response status: \(httpResponse.statusCode)")
            print("🔍 [APIService] Response headers: \(httpResponse.allHeaderFields)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { 
            print("❌ [APIService] Invalid response status")
            if let responseData = String(data: data, encoding: .utf8) {
                print("❌ [APIService] Response body: \(responseData)")
            }
            throw APIError.invalidResponse 
        }
        
        print("🔍 [APIService] Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
        
        let plannerResponse = try JSONDecoder().decode(PlannerResponse.self, from: data)
        print("🔍 [APIService] Successfully decoded planner response")
        return plannerResponse
    }
}

extension Date {
    func iso8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
} 

// MARK: - Planner Models
struct PlannerRequest: Codable {
    let input: String
    let context: String
    let coordinates: Coordinates?
    
    init(input: String, context: String, coordinates: Coordinates?) {
        self.input = input
        self.context = context
        self.coordinates = coordinates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        input = try container.decode(String.self, forKey: .input)
        context = try container.decode(String.self, forKey: .context)
        coordinates = try container.decodeIfPresent(Coordinates.self, forKey: .coordinates)
    }
    
    enum CodingKeys: String, CodingKey {
        case input, context, coordinates
    }
}

struct PlannerResponse: Codable {
    let success: Bool
    let plan: Plan?
    let nearbyLocationsFound: Int?
    let userLocation: String?
    let usedRealLocations: Bool?
    let verifiedLocationsUsed: Int?
    let error: String?
    let code: String?
}

struct Plan: Codable {
    let title: String
    let summary: String?
    let steps: [String]
    let context: String?
    let usedRealLocations: Bool?
    let locationIds: [String]?
    let verifiedLocationCount: Int?
    let generatedAt: String?
    let nearbyLocationsFound: Int?
    let userLocation: String?
    let verifiedLocationsUsed: Int?
    let coordinates: Coordinates?
    let nearbyLocationsCount: Int?
    let locationFetchError: String?
    let parseError: Bool?
    let error: Bool?
}

// MARK: - Interaction State Models
struct InteractionStateResponse: Codable {
    let success: Bool
    let message: String
    let data: InteractionStateData?
    let error: String?
    let code: String?
}

struct InteractionStateData: Codable {
    let interactions: [PostInteractionState]
    let totalPosts: Int
    let totalLiked: Int
    let totalSaved: Int
}

struct PostInteractionState: Codable {
    let postId: String
    let isLiked: Bool
    let isSaved: Bool
    let likeCount: Int
    let saveCount: Int
} 

// MARK: - Events Response Models
struct EventsResponse: Codable {
    let success: Bool
    let data: EventsData?
    let error: String?
}

struct EventsData: Codable {
    let events: [ProfileEvent]
    let pagination: EventsPagination?
    let meta: EventsMeta?
}

struct EventsPagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let hasMore: Bool
}

struct EventsMeta: Codable {
    let type: String?
    let category: String?
    let eventType: String?
    let isMatchmaking: Bool?
    let coordinates: EventCoordinates?
}

// MARK: - Followers Response Models
struct FollowersResponse: Codable {
    let success: Bool
    let message: String
    let data: FollowersData?
    let error: String?
}

struct FollowersData: Codable {
    let followers: [FollowerUser]
    let totalCount: Int
}

struct FollowerUser: Codable, Identifiable {
    let id: String
    let name: String
    let username: String?
    let email: String
    let profileImage: String?
    let bio: String?
    let isVerified: Bool?
    let followerCount: Int?
}

// MARK: - Following Response Models
struct FollowingResponse: Codable {
    let success: Bool
    let message: String
    let data: FollowingData?
    let error: String?
}

struct FollowingData: Codable {
    let following: [FollowerUser]
    let totalCount: Int
} 

// MARK: - Location Interaction State API
extension APIService {
    func checkLocationInteractionState(locationIds: [String]) async throws -> LocationInteractionStateResponse {
        guard let url = URL(string: "\(APIService.baseURL)/api/mobile/locations/interaction-state") else { 
            throw APIError.invalidURL 
        }
        
        print("🔍 [APIService] Checking location interaction state for \(locationIds.count) locations")
        print("🔍 [APIService] URL: \(url)")
        print("🔍 [APIService] Token available: \(token != nil)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔍 [APIService] Authorization header set for location interaction state")
        } else {
            print("🔍 [APIService] No token available for location interaction state")
        }
        
        let body = ["locationIds": locationIds]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🔍 [APIService] Request body: \(body)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔍 [APIService] Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("🔍 [APIService] Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            print("🔍 [APIService] Error response: \(String(data: data, encoding: .utf8) ?? "No data")")
            throw APIError.invalidResponse
        }
        
        let interactionResponse = try JSONDecoder().decode(LocationInteractionStateResponse.self, from: data)
        print("🔍 [APIService] Successfully decoded response with \(interactionResponse.data?.interactions.count ?? 0) interactions")
        return interactionResponse
    }
} 


