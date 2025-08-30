import Foundation
import SwiftUI

// MARK: - Data Structures

struct AppLocation: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let shortDescription: String?
    let slug: String
    let categories: [String]
    let tags: [String]
    let featuredImage: AppLocationGalleryItem?
    let gallery: [AppLocationGalleryItem]
    let address: AppLocationAddress?
    let contactInfo: AppLocationContactInfo?
    let businessHours: [AppLocationBusinessHour]
    let priceRange: String?
    let bestTimeToVisit: [String]
    let insiderTips: String?
    let accessibility: AppLocationAccessibility?
    let privacy: String
    let privateAccess: [String]?
    let isFeatured: Bool
    let isVerified: Bool
    let hasBusinessPartnership: Bool
    let partnershipDetails: AppLocationPartnershipDetails?
    let meta: AppLocationMeta?
    let createdAt: String
    let updatedAt: String
    
    init(from dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.name = dictionary["name"] as? String ?? ""
        self.description = dictionary["description"] as? String ?? ""
        self.shortDescription = dictionary["shortDescription"] as? String
        self.slug = dictionary["slug"] as? String ?? ""
        self.categories = dictionary["categories"] as? [String] ?? []
        self.tags = dictionary["tags"] as? [String] ?? []
        
        // Parse featured image
        if let imageData = dictionary["featuredImage"] as? [String: Any] {
            self.featuredImage = AppLocationGalleryItem(from: imageData)
        } else if let imageUrl = dictionary["featuredImage"] as? String {
            self.featuredImage = AppLocationGalleryItem(url: imageUrl, alt: nil)
        } else {
            self.featuredImage = nil
        }
        
        // Parse gallery
        if let galleryData = dictionary["gallery"] as? [[String: Any]] {
            self.gallery = galleryData.compactMap { AppLocationGalleryItem(from: $0) }
        } else {
            self.gallery = []
        }
        
        // Parse address
        if let addressData = dictionary["address"] as? [String: Any] {
            self.address = AppLocationAddress(from: addressData)
        } else {
            self.address = nil
        }
        
        // Parse contact info
        if let contactData = dictionary["contactInfo"] as? [String: Any] {
            self.contactInfo = AppLocationContactInfo(from: contactData)
        } else {
            self.contactInfo = nil
        }
        
        // Parse business hours
        if let hoursData = dictionary["businessHours"] as? [[String: Any]] {
            self.businessHours = hoursData.compactMap { AppLocationBusinessHour(from: $0) }
        } else {
            self.businessHours = []
        }
        
        self.priceRange = dictionary["priceRange"] as? String
        self.bestTimeToVisit = dictionary["bestTimeToVisit"] as? [String] ?? []
        self.insiderTips = dictionary["insiderTips"] as? String
        self.privacy = dictionary["privacy"] as? String ?? "public"
        self.privateAccess = dictionary["privateAccess"] as? [String]
        self.isFeatured = dictionary["isFeatured"] as? Bool ?? false
        self.isVerified = dictionary["isVerified"] as? Bool ?? false
        self.hasBusinessPartnership = dictionary["hasBusinessPartnership"] as? Bool ?? false
        
        // Parse accessibility
        if let accessibilityData = dictionary["accessibility"] as? [String: Any] {
            self.accessibility = AppLocationAccessibility(from: accessibilityData)
        } else {
            self.accessibility = nil
        }
        
        // Parse partnership details
        if let partnershipData = dictionary["partnershipDetails"] as? [String: Any] {
            self.partnershipDetails = AppLocationPartnershipDetails(from: partnershipData)
        } else {
            self.partnershipDetails = nil
        }
        
        // Parse meta
        if let metaData = dictionary["meta"] as? [String: Any] {
            self.meta = AppLocationMeta(from: metaData)
        } else {
            self.meta = nil
        }
        
        self.createdAt = dictionary["createdAt"] as? String ?? ""
        self.updatedAt = dictionary["updatedAt"] as? String ?? ""
    }
    
    // Add Codable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        shortDescription = try container.decodeIfPresent(String.self, forKey: .shortDescription)
        slug = try container.decode(String.self, forKey: .slug)
        categories = try container.decode([String].self, forKey: .categories)
        tags = try container.decode([String].self, forKey: .tags)
        featuredImage = try container.decodeIfPresent(AppLocationGalleryItem.self, forKey: .featuredImage)
        gallery = try container.decode([AppLocationGalleryItem].self, forKey: .gallery)
        address = try container.decodeIfPresent(AppLocationAddress.self, forKey: .address)
        contactInfo = try container.decodeIfPresent(AppLocationContactInfo.self, forKey: .contactInfo)
        businessHours = try container.decode([AppLocationBusinessHour].self, forKey: .businessHours)
        priceRange = try container.decodeIfPresent(String.self, forKey: .priceRange)
        bestTimeToVisit = try container.decode([String].self, forKey: .bestTimeToVisit)
        insiderTips = try container.decodeIfPresent(String.self, forKey: .insiderTips)
        accessibility = try container.decodeIfPresent(AppLocationAccessibility.self, forKey: .accessibility)
        privacy = try container.decode(String.self, forKey: .privacy)
        privateAccess = try container.decodeIfPresent([String].self, forKey: .privateAccess)
        isFeatured = try container.decode(Bool.self, forKey: .isFeatured)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        hasBusinessPartnership = try container.decode(Bool.self, forKey: .hasBusinessPartnership)
        partnershipDetails = try container.decodeIfPresent(AppLocationPartnershipDetails.self, forKey: .partnershipDetails)
        meta = try container.decodeIfPresent(AppLocationMeta.self, forKey: .meta)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(shortDescription, forKey: .shortDescription)
        try container.encode(slug, forKey: .slug)
        try container.encode(categories, forKey: .categories)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(featuredImage, forKey: .featuredImage)
        try container.encode(gallery, forKey: .gallery)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(contactInfo, forKey: .contactInfo)
        try container.encode(businessHours, forKey: .businessHours)
        try container.encodeIfPresent(priceRange, forKey: .priceRange)
        try container.encode(bestTimeToVisit, forKey: .bestTimeToVisit)
        try container.encodeIfPresent(insiderTips, forKey: .insiderTips)
        try container.encodeIfPresent(accessibility, forKey: .accessibility)
        try container.encode(privacy, forKey: .privacy)
        try container.encodeIfPresent(privateAccess, forKey: .privateAccess)
        try container.encode(isFeatured, forKey: .isFeatured)
        try container.encode(isVerified, forKey: .isVerified)
        try container.encode(hasBusinessPartnership, forKey: .hasBusinessPartnership)
        try container.encodeIfPresent(partnershipDetails, forKey: .partnershipDetails)
        try container.encodeIfPresent(meta, forKey: .meta)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, shortDescription, slug, categories, tags
        case featuredImage, gallery, address, contactInfo, businessHours
        case priceRange, bestTimeToVisit, insiderTips, accessibility, privacy
        case privateAccess, isFeatured, isVerified, hasBusinessPartnership
        case partnershipDetails, meta, createdAt, updatedAt
    }
}

struct AppLocationGalleryItem: Codable {
    let url: String?
    let alt: String?
    let caption: String?
    
    init(from dictionary: [String: Any]) {
        self.url = dictionary["url"] as? String ?? dictionary["image"] as? String
        self.alt = dictionary["alt"] as? String
        self.caption = dictionary["caption"] as? String
    }
    
    init(url: String?, alt: String?, caption: String? = nil) {
        self.url = url
        self.alt = alt
        self.caption = caption
    }
    
    private enum CodingKeys: String, CodingKey {
        case url, alt, caption
    }
}

struct AppLocationAddress: Codable {
    let street: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    let neighborhood: String?
    let coordinates: AppLocationCoordinates?
    
    init(from dictionary: [String: Any]) {
        self.street = dictionary["street"] as? String
        self.city = dictionary["city"] as? String
        self.state = dictionary["state"] as? String
        self.zip = dictionary["zip"] as? String
        self.country = dictionary["country"] as? String
        self.neighborhood = dictionary["neighborhood"] as? String
        
        if let coordsData = dictionary["coordinates"] as? [String: Any] {
            self.coordinates = AppLocationCoordinates(from: coordsData)
        } else {
            self.coordinates = nil
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case street, city, state, zip, country, neighborhood, coordinates
    }
}

struct AppLocationCoordinates: Codable {
    let latitude: Double
    let longitude: Double
    
    init(from dictionary: [String: Any]) {
        self.latitude = dictionary["latitude"] as? Double ?? 0.0
        self.longitude = dictionary["longitude"] as? Double ?? 0.0
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

struct AppLocationContactInfo: Codable {
    let phone: String?
    let email: String?
    let website: String?
    let socialMedia: AppLocationSocialMedia?
    
    init(from dictionary: [String: Any]) {
        self.phone = dictionary["phone"] as? String
        self.email = dictionary["email"] as? String
        self.website = dictionary["website"] as? String
        
        if let socialData = dictionary["socialMedia"] as? [String: Any] {
            self.socialMedia = AppLocationSocialMedia(from: socialData)
        } else {
            self.socialMedia = nil
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case phone, email, website, socialMedia
    }
}

struct AppLocationSocialMedia: Codable {
    let facebook: String?
    let twitter: String?
    let instagram: String?
    let linkedin: String?
    
    init(from dictionary: [String: Any]) {
        self.facebook = dictionary["facebook"] as? String
        self.twitter = dictionary["twitter"] as? String
        self.instagram = dictionary["instagram"] as? String
        self.linkedin = dictionary["linkedin"] as? String
    }
    
    private enum CodingKeys: String, CodingKey {
        case facebook, twitter, instagram, linkedin
    }
}

struct AppLocationBusinessHour: Codable {
    let day: String
    let open: String?
    let close: String?
    let closed: Bool
    
    init(from dictionary: [String: Any]) {
        self.day = dictionary["day"] as? String ?? ""
        self.open = dictionary["open"] as? String
        self.close = dictionary["close"] as? String
        self.closed = dictionary["closed"] as? Bool ?? false
    }
    
    init(day: String, open: String, close: String, closed: Bool) {
        self.day = day
        self.open = open
        self.close = close
        self.closed = closed
    }
    
    private enum CodingKeys: String, CodingKey {
        case day, open, close, closed
    }
}

struct AppLocationAccessibility: Codable {
    let wheelchairAccess: Bool
    let parking: Bool
    let other: String?
    
    init(from dictionary: [String: Any]) {
        self.wheelchairAccess = dictionary["wheelchairAccess"] as? Bool ?? false
        self.parking = dictionary["parking"] as? Bool ?? false
        self.other = dictionary["other"] as? String
    }
    
    private enum CodingKeys: String, CodingKey {
        case wheelchairAccess, parking, other
    }
}

struct AppLocationPartnershipDetails: Codable {
    let partnerName: String?
    let partnerContact: String?
    let details: String?
    
    init(from dictionary: [String: Any]) {
        self.partnerName = dictionary["partnerName"] as? String
        self.partnerContact = dictionary["partnerContact"] as? String
        self.details = dictionary["details"] as? String
    }
    
    private enum CodingKeys: String, CodingKey {
        case partnerName, partnerContact, details
    }
}

struct AppLocationMeta: Codable {
    let title: String?
    let description: String?
    let keywords: String?
    
    init(from dictionary: [String: Any]) {
        self.title = dictionary["title"] as? String
        self.description = dictionary["description"] as? String
        self.keywords = dictionary["keywords"] as? String
    }
    
    private enum CodingKeys: String, CodingKey {
        case title, description, keywords
    }
}

// MARK: - AppLocationManager Class

class AppLocationManager: ObservableObject {
    @Published var locations: [AppLocation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authManager = AuthManager.shared
    private let baseURL = baseAPIURL
    
    func fetchLocations(type: String = "all", completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/api/mobile/locations?type=\(type)&limit=20&page=1") else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Invalid URL"
                completion(false, "Invalid URL")
            }
            return
        }
        
        var request = authManager.createAuthenticatedRequest(url: url, method: "GET")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    completion(false, error.localizedDescription)
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No response data"
                    completion(false, "No response data")
                    return
                }
                
                do {
                    let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    if let success = result?["success"] as? Bool, success,
                       let data = result?["data"] as? [String: Any],
                       let locationsData = data["locations"] as? [[String: Any]] {
                        
                        self?.locations = locationsData.compactMap { locationData in
                            AppLocation(from: locationData)
                        }
                        
                        completion(true, nil)
                    } else {
                        let message = result?["message"] as? String ?? "Failed to load locations"
                        self?.errorMessage = message
                        completion(false, message)
                    }
                } catch {
                    self?.errorMessage = "Failed to parse response"
                    completion(false, "Failed to parse response")
                }
            }
        }.resume()
    }
    
    func createLocation(locationData: [String: Any]) async -> Bool {
        guard let token = AuthManager.shared.token else {
            print("No authentication token available")
            return false
        }
        
        do {
            let url = URL(string: "\(baseURL)/api/mobile/locations")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let jsonData = try JSONSerialization.data(withJSONObject: locationData)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Create location response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Create location response: \(responseString ?? "No response")")
                    return true
                } else {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Create location error response: \(responseString ?? "No response")")
                }
            }
            
            return false
        } catch {
            print("Error creating location: \(error)")
            return false
        }
    }
    
    func refreshLocations(type: String = "all") {
        fetchLocations(type: type) { _, _ in }
    }
} 