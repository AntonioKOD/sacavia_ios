import Foundation
import SwiftUI

class SavedViewModel: ObservableObject {
    @Published var savedLocations: [SavedLocation] = []
    @Published var savedPosts: [SavedPost] = []
    @Published var stats: SavedStats?
    @Published var isLoading = false
    @Published var error: String?
    
    private let authManager = AuthManager.shared
    // Use the baseAPIURL from Utils.swift for production (sacavia.com)
    private let apiBaseURL = baseAPIURL
    
    func loadSavedContent() {
        guard authManager.isAuthenticated else {
            self.error = "Please log in to view saved content"
            return
        }
        
        isLoading = true
        error = nil
        
        let url = URL(string: "\(apiBaseURL)/api/mobile/saved")!
        var request = authManager.createAuthenticatedRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.error = "No data received"
                    return
                }
                
                // Debug: Log the raw response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🔍 Raw API Response: \(jsonString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(SavedResponse.self, from: data)
                    
                    if response.success, let data = response.data {
                        self?.savedLocations = data.locations
                        self?.savedPosts = data.posts
                        self?.stats = data.stats
                    } else {
                        self?.error = response.error ?? "Failed to load saved content"
                    }
                } catch {
                    print("🔍 JSON Decoding Error: \(error)")
                    print("🔍 Error Details: \(error.localizedDescription)")
                    self?.error = "Failed to parse response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// MARK: - Data Models
struct SavedLocation: Codable, Identifiable {
    let id: String
    let name: String
    let slug: String
    let description: String?
    let shortDescription: String?
    let address: String?
    let coordinates: SavedCoordinates?
    let featuredImage: SavedImage?
    let categories: [SavedCategory]?
    let rating: Double?
    let reviewCount: Int?
    let isVerified: Bool?
    let isFeatured: Bool?
    let savedAt: String
}

struct SavedPost: Codable, Identifiable {
    let id: String
    let type: String
    let title: String?
    let content: String
    let author: SavedAuthor
    let location: SavedPostLocation?
    let media: [SavedMedia]?
    let engagement: SavedEngagement
    let rating: Double?
    let categories: [String]?
    let tags: [String]?
    let createdAt: String
    let savedAt: String
}

struct SavedAuthor: Codable {
    let id: String
    let name: String
    let profileImage: SavedImage?
    let isVerified: Bool?
}

struct SavedPostLocation: Codable {
    let id: String
    let name: String
    let address: String?
}

struct SavedMedia: Codable, Identifiable {
    let type: String
    let url: String
    let thumbnail: String?
    let alt: String?
    
    var id: String { url }
}

struct SavedEngagement: Codable {
    let likeCount: Int
    let commentCount: Int
    let saveCount: Int
}

struct SavedImage: Codable {
    let url: String
    let alt: String?
}

struct SavedCategory: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String?
}

struct SavedCoordinates: Codable {
    let latitude: Double
    let longitude: Double
}

struct SavedStats: Codable {
    let totalSaved: Int
    let savedLocations: Int
    let savedPosts: Int
}

struct SavedResponse: Codable {
    let success: Bool
    let message: String
    let data: SavedData?
    let error: String?
    let code: String?
}

struct SavedData: Codable {
    let locations: [SavedLocation]
    let posts: [SavedPost]
    let stats: SavedStats
} 