import SwiftUI
import MapKit
import Foundation
import PhotosUI

// Set your backend base URL here (use your Mac's IP for device testing)
    let baseURL = baseAPIURL // <-- Production URL

// Models are now defined in SharedTypes.swift

// MARK: - Location Preview Model
struct LocationPreview: Codable, Identifiable {
    let id: String
    let name: String
    let imageUrl: String?
    let address: String?
    let rating: Double?
    let shortDescription: String?
    let isVerified: Bool?
    let reviewCount: Int?
    let categories: [String]?
    let isFeatured: Bool?
    let priceRange: String?
    let coordinates: MapCoordinates?
    let ownership: OwnershipInfo?
}


struct Location: Identifiable, Codable {
    let id: String
    let name: String
    let address: String?
    let coordinates: MapCoordinates
    let featuredImage: String?
    let imageUrl: String? // Add this field for backend compatibility
    let rating: Double?
    let description: String?
    let shortDescription: String?
    let slug: String?
    let gallery: [GalleryImage]?
    let categories: [String]?
    let tags: [String]?
    let priceRange: String?
    let businessHours: [BusinessHour]?
    let contactInfo: ContactInfo?
    let accessibility: Accessibility?
    let bestTimeToVisit: [BestTimeToVisit]?
    let insiderTips: [InsiderTip]?
    let isVerified: Bool?
    let isFeatured: Bool?
    let hasBusinessPartnership: Bool?
    let partnershipDetails: PartnershipDetails?
    let neighborhood: String?
    var isSaved: Bool?
    var isSubscribed: Bool?
    let createdBy: String?
    let createdAt: String?
    let updatedAt: String?
    let ownership: OwnershipInfo?
    let reviewCount: Int?
    let visitCount: Int?
    // For new sections
    let reviews: [Review]?
    let communityPhotos: [CommunityPhoto]? // <-- Add this field
    // Remove communityPhotos from here, use a separate array in the view
    
    // Computed property to get the image URL
    var displayImage: String? {
        return imageUrl ?? featuredImage
    }
    
    // Custom initializer for creating Location instances
    init(id: String, name: String, address: String?, coordinates: MapCoordinates, featuredImage: String?, imageUrl: String?, rating: Double?, description: String?, shortDescription: String?, slug: String?, gallery: [GalleryImage]?, categories: [String]?, tags: [String]?, priceRange: String?, businessHours: [BusinessHour]?, contactInfo: ContactInfo?, accessibility: Accessibility?, bestTimeToVisit: [BestTimeToVisit]?, insiderTips: [InsiderTip]?, isVerified: Bool?, isFeatured: Bool?, hasBusinessPartnership: Bool?, partnershipDetails: PartnershipDetails?, neighborhood: String?, isSaved: Bool?, isSubscribed: Bool?, createdBy: String?, createdAt: String?, updatedAt: String?, ownership: OwnershipInfo?, reviewCount: Int?, visitCount: Int?, reviews: [Review]?, communityPhotos: [CommunityPhoto]?) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinates = coordinates
        self.featuredImage = featuredImage
        self.imageUrl = imageUrl
        self.rating = rating
        self.description = description
        self.shortDescription = shortDescription
        self.slug = slug
        self.gallery = gallery
        self.categories = categories
        self.tags = tags
        self.priceRange = priceRange
        self.businessHours = businessHours
        self.contactInfo = contactInfo
        self.accessibility = accessibility
        self.bestTimeToVisit = bestTimeToVisit
        self.insiderTips = insiderTips
        self.isVerified = isVerified
        self.isFeatured = isFeatured
        self.hasBusinessPartnership = hasBusinessPartnership
        self.partnershipDetails = partnershipDetails
        self.neighborhood = neighborhood
        self.isSaved = isSaved
        self.isSubscribed = isSubscribed
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ownership = ownership
        self.reviewCount = reviewCount
        self.visitCount = visitCount
        self.reviews = reviews
        self.communityPhotos = communityPhotos
    }
    
    // Custom decoding to handle different coordinate formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        // Handle featuredImage - can be either a string or an object with url property
        if let featuredImageString = try? container.decode(String.self, forKey: .featuredImage) {
            featuredImage = featuredImageString
        } else if let featuredImageObject = try? container.decode(FeaturedImageObject.self, forKey: .featuredImage) {
            featuredImage = featuredImageObject.url
        } else {
            featuredImage = nil
        }
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        shortDescription = try container.decodeIfPresent(String.self, forKey: .shortDescription)
        slug = try container.decodeIfPresent(String.self, forKey: .slug)
        gallery = try container.decodeIfPresent([GalleryImage].self, forKey: .gallery)
        // Handle categories - can be either array of strings or array of objects with name property
        if let categoriesArray = try? container.decode([String].self, forKey: .categories) {
            categories = categoriesArray
        } else if let categoriesObjects = try? container.decode([LocationCategoryObject].self, forKey: .categories) {
            categories = categoriesObjects.compactMap { $0.name }
        } else {
            categories = nil
        }
        // Handle tags - can be either array of strings or array of objects with tag property
        if let tagsArray = try? container.decode([String].self, forKey: .tags) {
            tags = tagsArray
        } else if let tagsObjects = try? container.decode([TagObject].self, forKey: .tags) {
            tags = tagsObjects.compactMap { $0.tag }
        } else {
            tags = nil
        }
        priceRange = try container.decodeIfPresent(String.self, forKey: .priceRange)
        businessHours = try container.decodeIfPresent([BusinessHour].self, forKey: .businessHours)
        contactInfo = try container.decodeIfPresent(ContactInfo.self, forKey: .contactInfo)
        accessibility = try container.decodeIfPresent(Accessibility.self, forKey: .accessibility)
        bestTimeToVisit = try container.decodeIfPresent([BestTimeToVisit].self, forKey: .bestTimeToVisit)
        insiderTips = try container.decodeIfPresent([InsiderTip].self, forKey: .insiderTips)
        isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified)
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured)
        hasBusinessPartnership = try container.decodeIfPresent(Bool.self, forKey: .hasBusinessPartnership)
        partnershipDetails = try container.decodeIfPresent(PartnershipDetails.self, forKey: .partnershipDetails)
        neighborhood = try container.decodeIfPresent(String.self, forKey: .neighborhood)
        isSaved = try container.decodeIfPresent(Bool.self, forKey: .isSaved)
        isSubscribed = try container.decodeIfPresent(Bool.self, forKey: .isSubscribed)
        // Handle createdBy - can be either a string (user ID) or an object with user data
        if let createdByString = try? container.decode(String.self, forKey: .createdBy) {
            createdBy = createdByString
        } else if let createdByObject = try? container.decode(CreatedByObject.self, forKey: .createdBy) {
            createdBy = createdByObject.id
        } else {
            createdBy = nil
        }
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        ownership = try container.decodeIfPresent(OwnershipInfo.self, forKey: .ownership)
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount)
        visitCount = try container.decodeIfPresent(Int.self, forKey: .visitCount)
        reviews = try container.decodeIfPresent([Review].self, forKey: .reviews)
        communityPhotos = try container.decodeIfPresent([CommunityPhoto].self, forKey: .communityPhotos)
        
        // Handle coordinates - can be either a MapCoordinates object or separate latitude/longitude fields
        if let coords = try? container.decode(MapCoordinates.self, forKey: .coordinates) {
            coordinates = coords
        } else {
            // Try to decode latitude and longitude as separate fields (can be strings or numbers)
            let latitude: Double
            if let latitudeString = try? container.decode(String.self, forKey: .latitude) {
                latitude = Double(latitudeString) ?? 0.0
            } else {
                latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 0.0
            }
            
            let longitude: Double
            if let longitudeString = try? container.decode(String.self, forKey: .longitude) {
                longitude = Double(longitudeString) ?? 0.0
            } else {
                longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 0.0
            }
            
            coordinates = MapCoordinates(latitude: latitude, longitude: longitude)
        }
    }
    
    // Custom encoding to match the decoding logic
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(featuredImage, forKey: .featuredImage)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(shortDescription, forKey: .shortDescription)
        try container.encodeIfPresent(slug, forKey: .slug)
        try container.encodeIfPresent(gallery, forKey: .gallery)
        // Encode categories as array of strings
        try container.encodeIfPresent(categories, forKey: .categories)
        // Encode tags as array of strings
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(priceRange, forKey: .priceRange)
        try container.encodeIfPresent(businessHours, forKey: .businessHours)
        try container.encodeIfPresent(contactInfo, forKey: .contactInfo)
        try container.encodeIfPresent(accessibility, forKey: .accessibility)
        try container.encodeIfPresent(bestTimeToVisit, forKey: .bestTimeToVisit)
        try container.encodeIfPresent(insiderTips, forKey: .insiderTips)
        try container.encodeIfPresent(isVerified, forKey: .isVerified)
        try container.encodeIfPresent(isFeatured, forKey: .isFeatured)
        try container.encodeIfPresent(hasBusinessPartnership, forKey: .hasBusinessPartnership)
        try container.encodeIfPresent(partnershipDetails, forKey: .partnershipDetails)
        try container.encodeIfPresent(neighborhood, forKey: .neighborhood)
        try container.encodeIfPresent(isSaved, forKey: .isSaved)
        try container.encodeIfPresent(isSubscribed, forKey: .isSubscribed)
        // Encode createdBy as string (user ID)
        try container.encodeIfPresent(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(ownership, forKey: .ownership)
        try container.encodeIfPresent(reviewCount, forKey: .reviewCount)
        try container.encodeIfPresent(visitCount, forKey: .visitCount)
        try container.encodeIfPresent(reviews, forKey: .reviews)
        try container.encodeIfPresent(communityPhotos, forKey: .communityPhotos)
        
        // Encode coordinates as a MapCoordinates object
        try container.encode(coordinates, forKey: .coordinates)
    }
    
    // Coding keys to include latitude and longitude as separate fields
    private enum CodingKeys: String, CodingKey {
        case id, name, address, coordinates, featuredImage, imageUrl, rating, description, shortDescription, slug, gallery, categories, tags, priceRange, businessHours, contactInfo, accessibility, bestTimeToVisit, insiderTips, isVerified, isFeatured, hasBusinessPartnership, partnershipDetails, neighborhood, isSaved, isSubscribed, createdBy, createdAt, updatedAt, ownership, reviewCount, visitCount, reviews, communityPhotos, latitude, longitude
    }
}

struct GalleryImage: Codable {
    let image: String?
    let caption: String?
    
    // Custom decoding to handle image as either string or object
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        
        // Handle image - can be either a string or an object with url property
        if let imageString = try? container.decode(String.self, forKey: .image) {
            image = imageString
        } else if let imageObject = try? container.decode(FeaturedImageObject.self, forKey: .image) {
            image = imageObject.url
        } else {
            image = nil
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case image, caption
    }
    
    // Custom encoding to match the decoding logic
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(caption, forKey: .caption)
    }
}

// Using BusinessHour, ContactInfo, SocialMedia, and Accessibility from SharedTypes.swift

// Using BestTimeToVisit from SharedTypes.swift

// PartnershipDetails struct moved to SharedTypes.swift

struct MapCoordinates: Codable {
    let latitude: Double
    let longitude: Double
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle latitude - can be string or number
        if let latitudeString = try? container.decode(String.self, forKey: .latitude) {
            latitude = Double(latitudeString) ?? 0.0
            print("[DEBUG] Converted latitude string '\(latitudeString)' to \(latitude)")
        } else {
            latitude = try container.decode(Double.self, forKey: .latitude)
        }
        
        // Handle longitude - can be string or number
        if let longitudeString = try? container.decode(String.self, forKey: .longitude) {
            longitude = Double(longitudeString) ?? 0.0
            print("[DEBUG] Converted longitude string '\(longitudeString)' to \(longitude)")
        } else {
            longitude = try container.decode(Double.self, forKey: .longitude)
        }
        
        // Validate coordinates
        if latitude == 0.0 && longitude == 0.0 {
            print("[WARNING] Coordinates are (0,0) - this might be invalid data")
        }
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

// Helper struct for featured image object
struct FeaturedImageObject: Codable {
    let url: String?
}

// Helper struct for location category object (to avoid conflict with FeedManager.CategoryObject)
struct LocationCategoryObject: Codable {
    let name: String?
}

// Helper struct for tag object
struct TagObject: Codable {
    let tag: String?
}

// Helper struct for createdBy object
struct CreatedByObject: Codable {
    let id: String?
    let name: String?
    let email: String?
}

// MARK: - Cluster Model
struct LocationCluster: Identifiable, Equatable {
    let id = UUID()
    let locations: [Location]
    let center: CLLocationCoordinate2D
    let count: Int
    
    static func == (lhs: LocationCluster, rhs: LocationCluster) -> Bool {
        return lhs.id == rhs.id
    }
    
    var primaryLocation: Location {
        return locations.first ?? createFallbackLocation()
    }
    
    private func createFallbackLocation() -> Location {
        // Create a minimal fallback location
        let fallbackLocation = Location(
            id: "",
            name: "Unknown Location",
            address: nil,
            coordinates: MapCoordinates(latitude: 0, longitude: 0),
            featuredImage: nil,
            imageUrl: nil,
            rating: nil,
            description: nil,
            shortDescription: nil,
            slug: nil,
            gallery: nil,
            categories: nil,
            tags: nil,
            priceRange: nil,
            businessHours: nil,
            contactInfo: nil,
            accessibility: nil,
            bestTimeToVisit: nil,
            insiderTips: nil,
            isVerified: nil,
            isFeatured: nil,
            hasBusinessPartnership: nil,
            partnershipDetails: nil,
            neighborhood: nil,
            isSaved: nil,
            isSubscribed: nil,
            createdBy: nil,
            createdAt: nil,
            updatedAt: nil,
            ownership: nil,
            reviewCount: nil,
            visitCount: nil,
            reviews: nil,
            communityPhotos: nil
        )
        return fallbackLocation
    }
}

class LocationsViewModel: ObservableObject {
    @Published var locations: [Location] = []
    @Published var clusters: [LocationCluster] = []
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var previewLocation: LocationPreview? = nil
    @Published var showPreviewSheet = false
    @Published var showClusterSheet = false
    @Published var selectedCluster: LocationCluster? = nil

    func fetchLocations() {
        isLoading = true
        error = nil
        let url = URL(string: "\(baseURL)/api/mobile/locations?limit=50")!
        var request = URLRequest(url: url)
        
        // Add authentication headers if user is logged in
        if let token = AuthManager.shared.token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
            print("[DEBUG] Added auth headers with token:", token.prefix(20) + "...")
            print("[DEBUG] Full request URL:", url.absoluteString)
        } else {
            print("[DEBUG] No auth token available - user may not be logged in")
            print("[DEBUG] AuthManager.shared.isAuthenticated:", AuthManager.shared.isAuthenticated)
        }
        
        URLSession.shared.dataTask(with: request) { data, response, err in
            DispatchQueue.main.async {
                self.isLoading = false
                
                // Debug: Print response status
                if let httpResponse = response as? HTTPURLResponse {
                    print("[DEBUG] HTTP Status:", httpResponse.statusCode)
                    print("[DEBUG] Response headers:", httpResponse.allHeaderFields)
                }
                
                if let err = err {
                    self.error = err.localizedDescription
                    print("[DEBUG] Network error:", err)
                    return
                }
                guard let data = data else {
                    self.error = "No data received"
                    print("[DEBUG] No data received")
                    return
                }
                
                // Debug: Print the raw response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[DEBUG] Raw API response:", responseString)
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    print("[DEBUG] Parsed JSON:", json ?? "nil")
                    
                    // Check if response has the new structure (locations at root level)
                    if let locationsArr = json?["locations"] as? [[String: Any]] {
                        print("[DEBUG] Found locations at root level, count:", locationsArr.count)
                        
                        // Debug: Print first location to see the structure
                        if let firstLocation = locationsArr.first {
                            print("[DEBUG] First location:", firstLocation)
                            print("[DEBUG] First location rating:", firstLocation["rating"])
                            print("[DEBUG] First location reviewCount:", firstLocation["reviewCount"])
                            print("[DEBUG] First location coordinates:", firstLocation["coordinates"])
                            print("[DEBUG] First location ownership:", firstLocation["ownership"])
                            print("[DEBUG] First location featuredImage:", firstLocation["featuredImage"])
                            print("[DEBUG] First location categories:", firstLocation["categories"])
                            
                            // Debug: Print the raw ownership data structure
                            if let ownershipData = firstLocation["ownership"] {
                                print("[DEBUG] Raw ownership data type:", type(of: ownershipData))
                                print("[DEBUG] Raw ownership data:", ownershipData)
                            } else {
                                print("[DEBUG] No ownership data in raw JSON for location:", firstLocation["name"] ?? "unknown")
                            }
                            
                            // Debug coordinate structure
                            if let coords = firstLocation["coordinates"] as? [String: Any] {
                                print("[DEBUG] Coordinates structure:", coords)
                                print("[DEBUG] Latitude type:", type(of: coords["latitude"]))
                                print("[DEBUG] Longitude type:", type(of: coords["longitude"]))
                            }
                        }
                        
                        let locationsData = try JSONSerialization.data(withJSONObject: locationsArr)
                        self.locations = try JSONDecoder().decode([Location].self, from: locationsData)
                        
                        // Debug: Print decoded locations
                        print("[DEBUG] Decoded locations count:", self.locations.count)
                        if let firstLocation = self.locations.first {
                            print("[DEBUG] First decoded location rating:", firstLocation.rating)
                            print("[DEBUG] First decoded location reviewCount:", firstLocation.reviewCount)
                            print("[DEBUG] First decoded location coordinates: lat=\(firstLocation.coordinates.latitude), lng=\(firstLocation.coordinates.longitude)")
                            print("[DEBUG] First decoded location ownership:", firstLocation.ownership?.claimStatus ?? "nil")
                            print("[DEBUG] First decoded location featuredImage:", firstLocation.featuredImage ?? "nil")
                            print("[DEBUG] First decoded location categories:", firstLocation.categories)
                            
                            // Debug: Print all ownership details
                            if let ownership = firstLocation.ownership {
                                print("[DEBUG] Full ownership object:", ownership)
                            } else {
                                print("[DEBUG] Ownership is nil for location:", firstLocation.name)
                            }
                        }
                        
                        // After loading locations, check interaction state for saved/subscribed status
                        self.checkLocationInteractionStates()
                        
                        // Create clusters from loaded locations
                        self.createClusters(from: self.locations)
                    } else {
                        // Fallback to old structure (data.locations)
                        guard let dataDict = json?["data"] as? [String: Any] else {
                            self.error = "No data field in response"
                            return
                        }
                        print("[DEBUG] Data dict:", dataDict)
                        
                        guard let locationsArr = dataDict["locations"] as? [[String: Any]] else {
                            self.error = "No locations array in response"
                            return
                        }
                        print("[DEBUG] Locations array count:", locationsArr.count)
                        
                        let locationsData = try JSONSerialization.data(withJSONObject: locationsArr)
                        self.locations = try JSONDecoder().decode([Location].self, from: locationsData)
                        
                        // Create clusters from loaded locations
                        self.createClusters(from: self.locations)
                    }
                } catch {
                    print("[DEBUG] Decoding error:", error)
                    self.error = error.localizedDescription
                }
            }
        }.resume()
    }
    
    private func checkLocationInteractionStates() {
        Task {
            do {
                let locationIds = locations.map { $0.id }
                if locationIds.isEmpty { return }
                
                let apiService = APIService.shared
                let response = try await apiService.checkLocationInteractionState(locationIds: locationIds)
                
                if response.success, let data = response.data {
                    print("[DEBUG] Received interaction states for \(data.interactions.count) locations")
                    
                    // Update locations with interaction states
                    DispatchQueue.main.async {
                        for interaction in data.interactions {
                            if let index = self.locations.firstIndex(where: { $0.id == interaction.locationId }) {
                                self.locations[index].isSaved = interaction.isSaved
                                self.locations[index].isSubscribed = interaction.isSubscribed
                            }
                        }
                    }
                }
            } catch {
                print("[DEBUG] Error checking location interaction states: \(error)")
            }
        }
    }
    
    // MARK: - Location Preview Functions
    func fetchLocationPreview(locationId: String, completion: @escaping (LocationPreview?) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/mobile/locations/\(locationId)/preview") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        
        // Add authentication headers if user is logged in
        if let token = AuthManager.shared.token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[PREVIEW] Network error:", error)
                    completion(nil)
                    return
                }
                
                guard let data = data else {
                    print("[PREVIEW] No data received")
                    completion(nil)
                    return
                }
                
                // Debug: Print the raw response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[PREVIEW] Raw API response:", responseString)
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    if let success = json?["success"] as? Bool, success,
                       let dataDict = json?["data"] as? [String: Any] {
                        
                        let previewData = try JSONSerialization.data(withJSONObject: dataDict)
                        let preview = try JSONDecoder().decode(LocationPreview.self, from: previewData)
                        completion(preview)
                    } else {
                        print("[PREVIEW] API returned success: false or no data")
                        completion(nil)
                    }
                } catch {
                    print("[PREVIEW] Decoding error:", error)
                    completion(nil)
                }
            }
        }.resume()
    }
    
    // MARK: - Clustering Logic
    private func createClusters(from locations: [Location]) {
        let clusterRadius: CLLocationDistance = 200 // 200 meters - only cluster very close locations
        var processedLocations = Set<String>()
        var newClusters: [LocationCluster] = []
        
        // Filter out locations with invalid coordinates
        let validLocations = locations.filter { location in
            let lat = location.coordinates.latitude
            let lng = location.coordinates.longitude
            return lat != 0 && lng != 0 && 
                   lat >= -90 && lat <= 90 && 
                   lng >= -180 && lng <= 180 &&
                   !lat.isNaN && !lng.isNaN
        }
        
        print("[DEBUG] Creating clusters from \(validLocations.count) valid locations out of \(locations.count) total (cluster radius: 200m)")
        
        // Debug: Print first few valid locations
        for (index, location) in validLocations.prefix(3).enumerated() {
            print("[DEBUG] Valid location \(index + 1): \(location.name) at [\(location.coordinates.latitude), \(location.coordinates.longitude)]")
        }
        
        for location in validLocations {
            if processedLocations.contains(location.id) { continue }
            
            var nearbyLocations = [location]
            processedLocations.insert(location.id)
            
            // Find nearby locations
            for otherLocation in validLocations {
                if otherLocation.id == location.id || processedLocations.contains(otherLocation.id) { continue }
                
                let distance = calculateDistance(
                    from: CLLocationCoordinate2D(latitude: location.coordinates.latitude, longitude: location.coordinates.longitude),
                    to: CLLocationCoordinate2D(latitude: otherLocation.coordinates.latitude, longitude: otherLocation.coordinates.longitude)
                )
                
                // Only cluster if locations are very close (within 200 meters)
                if distance <= clusterRadius {
                    nearbyLocations.append(otherLocation)
                    processedLocations.insert(otherLocation.id)
                }
            }
            
            // Create cluster center
            let totalLat = nearbyLocations.reduce(0) { $0 + $1.coordinates.latitude }
            let totalLon = nearbyLocations.reduce(0) { $0 + $1.coordinates.longitude }
            let centerLat = totalLat / Double(nearbyLocations.count)
            let centerLon = totalLon / Double(nearbyLocations.count)
            let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
            
            let cluster = LocationCluster(
                locations: nearbyLocations,
                center: center,
                count: nearbyLocations.count
            )
            
            newClusters.append(cluster)
        }
        
        self.clusters = newClusters
        print("[DEBUG] Created \(newClusters.count) clusters from \(validLocations.count) valid locations")
        
        // Debug: Print cluster details
        for (index, cluster) in newClusters.enumerated() {
            print("[DEBUG] Cluster \(index + 1): \(cluster.count) locations at [\(cluster.center.latitude), \(cluster.center.longitude)]")
            if cluster.count == 1 {
                print("[DEBUG]   Single location: \(cluster.primaryLocation.name)")
            } else {
                print("[DEBUG]   Multiple locations: \(cluster.locations.map { $0.name }.joined(separator: ", "))")
            }
        }
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    func showClusterPreview(for cluster: LocationCluster) {
        selectedCluster = cluster
        showClusterSheet = true
    }
    
    func showPreview(for locationId: String) {
        fetchLocationPreview(locationId: locationId) { preview in
            if let preview = preview {
                self.previewLocation = preview
                self.showPreviewSheet = true
            } else {
                // Fallback: if preview fails, show full detail
                if let location = self.locations.first(where: { $0.id == locationId }) {
                    // This will be handled by the parent view
                    print("[PREVIEW] Preview failed, should show full detail for:", location.name)
                }
            }
        }
    }
}

// MARK: - Networking for Location Detail

extension LocationsViewModel {
    func fetchReviews(for locationId: String, completion: @escaping ([Review]) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/mobile/locations/\(locationId)/reviews") else { completion([]); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(ReviewsResponse.self, from: data),
                  result.success else { completion([]); return }
            DispatchQueue.main.async { completion(result.data.reviews) }
        }.resume()
    }
    func fetchInsiderTips(for locationId: String, completion: @escaping ([InsiderTip]) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/mobile/locations/\(locationId)/insider-tips") else { completion([]); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(InsiderTipsResponse.self, from: data),
                  result.success else { completion([]); return }
            DispatchQueue.main.async { completion(result.data.tips) }
        }.resume()
    }
    func fetchCommunityPhotos(for locationId: String, completion: @escaping ([CommunityPhoto]) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/mobile/locations/\(locationId)/community-photos") else { completion([]); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { print("[COMMUNITY PHOTOS] No data"); completion([]); return }
            print("[COMMUNITY PHOTOS] Raw API response:", String(data: data, encoding: .utf8) ?? "nil")
            if let result = try? JSONDecoder().decode(CommunityPhotosResponse.self, from: data), result.success {
                DispatchQueue.main.async { completion(result.data.photos) }
            } else {
                print("[COMMUNITY PHOTOS] Failed to decode or not success")
                completion([])
            }
        }.resume()
    }
    // POST: Add Review
    func submitReview(for locationId: String, review: ReviewSubmission, token: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/mobile/locations/\(locationId)/reviews") else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONEncoder().encode(review)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(GenericSuccessResponse.self, from: data),
                  result.success else { completion(false); return }
            DispatchQueue.main.async { completion(true) }
        }.resume()
    }
    // POST: Add Insider Tip
    func submitInsiderTip(for locationId: String, tip: InsiderTipSubmission, token: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/mobile/locations/\(locationId)/insider-tips") else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie") // <-- Add this line
        request.httpBody = try? JSONEncoder().encode(tip)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(GenericSuccessResponse.self, from: data),
                  result.success else { completion(false); return }
            DispatchQueue.main.async { completion(true) }
        }.resume()
    }
    // POST: Add Community Photo
    func submitCommunityPhoto(for locationId: String, photo: CommunityPhotoSubmission, token: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/mobile/locations/\(locationId)/community-photos") else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONEncoder().encode(photo)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(GenericSuccessResponse.self, from: data),
                  result.success else { completion(false); return }
            DispatchQueue.main.async { completion(true) }
        }.resume()
    }
}

// MARK: - Response Models
struct InsiderTipsResponse: Codable { let success: Bool; let data: InsiderTipsData }
struct InsiderTipsData: Codable { let tips: [InsiderTip] }
struct GenericSuccessResponse: Codable { let success: Bool }

// MARK: - Submission Models
struct ReviewSubmission: Codable {
    let title: String
    let content: String
    let rating: Double
    let visitDate: String?
    let pros: [String]?
    let cons: [String]?
    let tips: String?
}
// InsiderTipSubmission is now defined in EnhancedLocationDetailView.swift
struct CommunityPhotoSubmission: Codable {
    let photoUrl: String
    let caption: String?
}

struct LocationsMapTabView: View {
    @StateObject private var viewModel = LocationsViewModel()
    @State private var selectedTab = 0 // 0 = List, 1 = Map
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.36, longitude: -71.06),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    @State private var selectedLocation: Location? = nil
    @State private var selectedCluster: LocationCluster? = nil
    @State private var showingAddLocation = false
    @State private var showingAddBusiness = false
    @EnvironmentObject var auth: AuthManager
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4

    var body: some View {
        VStack(spacing: 0) {
            tabPickerView
            mainContentView
        }
        .background(Color(.systemGray6))
        .onAppear {
            viewModel.fetchLocations()
        }
        .onChange(of: viewModel.clusters) { clusters in
            print("[DEBUG] Clusters updated: \(clusters.count) clusters")
            print("[DEBUG] Map region: center=[\(region.center.latitude), \(region.center.longitude)], span=[\(region.span.latitudeDelta), \(region.span.longitudeDelta)]")
            for (index, cluster) in clusters.enumerated() {
                print("[DEBUG] Cluster \(index + 1): \(cluster.count) locations at [\(cluster.center.latitude), \(cluster.center.longitude)]")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LocationSaveStateChanged"))) { notification in
            // Refresh locations when a location save state changes to update saved status
            print("🔍 [LocationsMapTabView] Received location save state change notification")
            viewModel.fetchLocations()
        }
    }
    
    private var tabPickerView: some View {
        HStack(spacing: 0) {
            CustomTabButton(
                title: "List",
                icon: "list.bullet",
                isSelected: selectedTab == 0,
                primaryColor: primaryColor
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = 0
                }
            }
            
            CustomTabButton(
                title: "Map",
                icon: "map",
                isSelected: selectedTab == 1,
                primaryColor: primaryColor
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = 1
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var mainContentView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(error)
            } else {
                contentView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(primaryColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(primaryColor)
            }
            Text("Discovering amazing places...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
            Spacer()
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
            }
            Text("Oops! Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)
            Text(error)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { viewModel.fetchLocations() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Try Again")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [primaryColor, secondaryColor]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            Spacer()
        }
    }
    
    private var contentView: some View {
        Group {
            if viewModel.locations.isEmpty {
                emptyStateView
            } else {
                tabContent
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Location Encouragement Card
            LocationEncouragementView(
                variant: .default,
                onAddLocation: { showingAddLocation = true },
                onAddBusiness: { showingAddBusiness = true }
            )
            
            // Original empty state
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(primaryColor.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 32))
                        .foregroundColor(primaryColor)
                }
                Text("No locations found")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Start exploring and discovering amazing places around you")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .fullScreenCover(isPresented: $showingAddLocation) {
            EnhancedAddLocationView()
        }
        .fullScreenCover(isPresented: $showingAddBusiness) {
            EnhancedAddLocationView()
        }
    }
    
    private var tabContent: some View {
        Group {
            if selectedTab == 0 {
                listView
            } else {
                mapView
            }
        }
        .fullScreenCover(isPresented: $showingAddLocation) {
            EnhancedAddLocationView()
        }
        .fullScreenCover(isPresented: $showingAddBusiness) {
            EnhancedAddLocationView()
        }
        .sheet(item: $selectedLocation) { location in
            EnhancedLocationDetailView(locationId: location.id)
                .environmentObject(auth)
        }
        .sheet(item: $selectedCluster) { cluster in
            ClusterPreviewSheet(
                cluster: cluster,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                onLocationSelect: { location in
                    selectedLocation = location
                    selectedCluster = nil
                }
            )
        }
        .sheet(isPresented: $viewModel.showPreviewSheet) {
            if let preview = viewModel.previewLocation {
                LocationPreviewSheet(
                    preview: preview,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor
                ) {
                    // When "View Details" is tapped, show full detail
                    if let location = viewModel.locations.first(where: { $0.id == preview.id }) {
                        viewModel.showPreviewSheet = false
                        selectedLocation = location
                    }
                }
                .presentationDetents([.height(220)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(.regularMaterial)
            }
        }
        .sheet(isPresented: $viewModel.showClusterSheet) {
            if let cluster = viewModel.selectedCluster {
                ClusterPreviewSheet(
                    cluster: cluster,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor
                ) { location in
                    // When a location is selected from cluster, show full detail
                    viewModel.showClusterSheet = false
                    selectedLocation = location
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(.regularMaterial)
            }
        }
    }
    
    private var listView: some View {
        // Modern List View
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.locations) { location in
                    LocationCard(
                        location: location,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor
                    ) {
                        selectedTab = 1
                        selectedLocation = location
                        region.center = CLLocationCoordinate2D(
                            latitude: location.coordinates.latitude,
                            longitude: location.coordinates.longitude
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 100) // Add bottom padding to prevent overlap with navbar
        }
    }
    
    
    
    private var mapView: some View {
        // Map View with proper annotation system for fixed pin positioning
        MapViewRepresentable(
            region: $region,
            clusters: viewModel.clusters,
            primaryColor: primaryColor,
            onClusterTap: { cluster in
                if cluster.count == 1 {
                    // Single location - show preview
                    viewModel.showPreview(for: cluster.primaryLocation.id)
                } else {
                    // Multiple locations - show cluster preview
                    viewModel.showClusterPreview(for: cluster)
                }
            }
        )
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - MapViewRepresentable
struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let clusters: [LocationCluster]
    let primaryColor: Color
    let onClusterTap: (LocationCluster) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        mapView.setRegion(region, animated: true)
        
        // Remove existing annotations
        mapView.removeAnnotations(mapView.annotations)
        
        // Add new annotations
        for cluster in clusters {
            let annotation = ClusterAnnotation(cluster: cluster, primaryColor: primaryColor)
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let clusterAnnotation = annotation as? ClusterAnnotation else { return nil }
            
            let identifier = "ClusterAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
                // Remove existing subviews
                annotationView?.subviews.forEach { $0.removeFromSuperview() }
            }
            
            // Create custom view for the annotation
            let customView = createCustomAnnotationView(for: clusterAnnotation)
            annotationView?.addSubview(customView)
            
            // Center the custom view
            customView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                customView.centerXAnchor.constraint(equalTo: annotationView!.centerXAnchor),
                customView.centerYAnchor.constraint(equalTo: annotationView!.centerYAnchor)
            ])
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let clusterAnnotation = view.annotation as? ClusterAnnotation else { return }
            parent.onClusterTap(clusterAnnotation.cluster)
        }
        
        private func createCustomAnnotationView(for annotation: ClusterAnnotation) -> UIView {
            let containerView = UIView()
            
            if annotation.cluster.count == 1 {
                // Check if this is an unclaimed location
                let location = annotation.cluster.locations.first!
                let isUnclaimed = location.ownership?.claimStatus == "unclaimed"
                let isVerified = location.ownership?.claimStatus == "approved" || location.ownership?.claimStatus == "verified"
                
                // Debug: Print ownership information
                print("🗺️ Map annotation for location: \(location.name)")
                print("🗺️ Ownership: \(location.ownership?.claimStatus ?? "nil")")
                print("🗺️ Is unclaimed: \(isUnclaimed)")
                print("🗺️ Is verified: \(isVerified)")
                
                // Single location marker - consistent styling based on category color
                let circleView = UIView()
                circleView.backgroundColor = UIColor(annotation.primaryColor)
                circleView.layer.cornerRadius = 10
                circleView.layer.borderWidth = 2
                circleView.layer.borderColor = UIColor.white.cgColor
                
                let shadowColor = UIColor(annotation.primaryColor)
                circleView.layer.shadowColor = shadowColor.cgColor
                circleView.layer.shadowOpacity = 0.3
                circleView.layer.shadowRadius = 4
                circleView.layer.shadowOffset = CGSize(width: 0, height: 2)
                
                // Use consistent icon for all locations
                let iconName = "mappin.circle.fill"
                let iconView = UIImageView(image: UIImage(systemName: iconName))
                iconView.tintColor = UIColor.white
                iconView.contentMode = UIView.ContentMode.scaleAspectFit
                
                containerView.addSubview(circleView)
                containerView.addSubview(iconView)
                
                circleView.translatesAutoresizingMaskIntoConstraints = false
                iconView.translatesAutoresizingMaskIntoConstraints = false
                
                NSLayoutConstraint.activate([
                    circleView.widthAnchor.constraint(equalToConstant: 20),
                    circleView.heightAnchor.constraint(equalToConstant: 20),
                    circleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                    circleView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                    
                    iconView.widthAnchor.constraint(equalToConstant: 12),
                    iconView.heightAnchor.constraint(equalToConstant: 12),
                    iconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                    iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                ])
            } else {
                // Cluster marker - smaller size
                let circleView = UIView()
                circleView.backgroundColor = UIColor(annotation.primaryColor)
                circleView.layer.cornerRadius = 12
                circleView.layer.borderWidth = 2
                circleView.layer.borderColor = UIColor.white.cgColor
                circleView.layer.shadowColor = UIColor(annotation.primaryColor).cgColor
                circleView.layer.shadowOpacity = 0.3
                circleView.layer.shadowRadius = 5
                circleView.layer.shadowOffset = CGSize(width: 0, height: 2)
                
                let label = UILabel()
                label.text = "\(annotation.cluster.count)"
                label.textColor = .white
                label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
                label.textAlignment = .center
                
                containerView.addSubview(circleView)
                containerView.addSubview(label)
                
                circleView.translatesAutoresizingMaskIntoConstraints = false
                label.translatesAutoresizingMaskIntoConstraints = false
                
                NSLayoutConstraint.activate([
                    circleView.widthAnchor.constraint(equalToConstant: 24),
                    circleView.heightAnchor.constraint(equalToConstant: 24),
                    circleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                    circleView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                    
                    label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                ])
            }
            
            return containerView
        }
    }
}

// MARK: - ClusterAnnotation
class ClusterAnnotation: NSObject, MKAnnotation {
    let cluster: LocationCluster
    let primaryColor: Color
    let coordinate: CLLocationCoordinate2D
    
    init(cluster: LocationCluster, primaryColor: Color) {
        self.cluster = cluster
        self.primaryColor = primaryColor
        self.coordinate = cluster.center
        super.init()
    }
}

// MARK: - Cluster Preview Sheet
struct ClusterPreviewSheet: View {
    let cluster: LocationCluster
    let primaryColor: Color
    let secondaryColor: Color
    let onLocationSelect: (Location) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(cluster.count) Locations Found")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Tap any location to view details")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Cluster icon
                        ZStack {
                            Circle()
                                .fill(primaryColor)
                                .frame(width: 40, height: 40)
                            
                            Text("\(cluster.count)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                // Location List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(cluster.locations, id: \.id) { location in
                            LocationClusterItem(
                                location: location,
                                primaryColor: primaryColor,
                                secondaryColor: secondaryColor
                            ) {
                                onLocationSelect(location)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100) // Add bottom padding for safe area
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Cluster Location Item
struct LocationClusterItem: View {
    let location: Location
    let primaryColor: Color
    let secondaryColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Location Image
                AsyncImage(url: URL(string: location.displayImage ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Location Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if let address = location.address {
                        Text(address)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Categories
                    if let categories = location.categories, !categories.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(categories.prefix(2), id: \.self) { category in
                                Text(category)
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(primaryColor.opacity(0.1))
                                    .foregroundColor(primaryColor)
                                    .clipShape(Capsule())
                            }
                            
                            if categories.count > 2 {
                                Text("+\(categories.count - 2)")
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.secondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    // Rating
                    if let rating = location.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            if let reviewCount = location.reviewCount {
                                Text("(\(reviewCount))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Tab Button
struct CustomTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let primaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? primaryColor : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Location Card
struct LocationCard: View {
    let location: Location
    let primaryColor: Color
    let secondaryColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 8)
                
                VStack(alignment: .leading, spacing: 0) {
                    // Image section
                    if let imageUrl = location.displayImage, let url = URL(string: imageUrl) {
                        ZStack(alignment: .bottom) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle().fill(Color.gray.opacity(0.1))
                                    .overlay(
                                        Image(systemName: "mappin.and.ellipse")
                                            .font(.system(size: 32))
                                            .foregroundColor(.gray)
                                    )
                            }
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            
                            LinearGradient(
                                colors: [Color.clear, Color.black.opacity(0.18)],
                                startPoint: .center, endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .frame(height: 200)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)
                    }
                    
                    // Content section
                    VStack(alignment: .leading, spacing: 16) {
                        // Title and verification badges
                        HStack {
                            Text(location.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            if location.isVerified == true {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(primaryColor)
                                    .font(.caption)
                            }
                            
                            if location.isFeatured == true {
                                Image(systemName: "star.circle.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                            
                            Spacer()
                        }
                        
                        // Address
                        if let address = location.address {
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(address)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        // Rating and reviews
                        if let rating = location.rating {
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", rating))
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                if let reviewCount = location.reviewCount {
                                    Text("(\(reviewCount) reviews)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        // Categories
                        if let categories = location.categories, !categories.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(categories.prefix(5), id: \.self) { category in
                                        Text(category)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [secondaryColor, secondaryColor.opacity(0.8)],
                                                            startPoint: .leading, endPoint: .trailing
                                                        )
                                                    )
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Tags
                        if let tags = location.tags, !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(tags.prefix(6), id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(primaryColor)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .stroke(primaryColor, lineWidth: 1)
                                                    .background(Capsule().fill(Color.white))
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 18)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
    }
}

// Helper for background blur
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// Location detail sheet for map marker tap
struct LocationDetailSheet: View {
    let location: Location
    @ObservedObject var viewModel: LocationsViewModel
    @State private var reviews: [Review] = []
    @State private var tips: [InsiderTip] = []
    @State private var communityPhotos: [CommunityPhoto] = [] // This is the new array
    @State private var showReviewModal = false
    @State private var showTipModal = false
    @State private var showPhotoModal = false
    @State private var selectedGalleryIndex = 0
    @State private var selectedTab = 0 // 0: About, 1: Reviews, 2: Photos, 3: Tips
    @EnvironmentObject var auth: AuthManager
    var body: some View {
        VStack(spacing: 0) {
            // Gallery
            if let gallery = location.gallery, !gallery.isEmpty {
                TabView(selection: $selectedGalleryIndex) {
                    ForEach(gallery.indices, id: \.self) { idx in
                        if let url = gallery[idx].image, let imageUrl = URL(string: url) {
                            AsyncImage(url: imageUrl) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.1)
                            }
                            .tag(idx)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 220)
            }
            // Quick stats overlay (name, badges, rating, review count)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(location.name).font(.title2).bold()
                    if location.isVerified == true {
                        Label("Verified", systemImage: "checkmark.seal.fill").foregroundColor(.green).font(.caption)
                    }
                    if location.isFeatured == true {
                        Label("Featured", systemImage: "star.circle.fill").foregroundColor(.yellow).font(.caption)
                    }
                }
                if let shortDesc = location.shortDescription {
                    Text(shortDesc).font(.subheadline).foregroundColor(.secondary)
                }
                // Combined average rating and review count
                if let rating = location.rating, let reviewCount = location.reviewCount {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                        Text("(") + Text("\(reviewCount)") + Text(" reviews)")
                            .font(.caption).foregroundColor(.gray)
                    }
                } else if let rating = location.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                    }
                } else if let reviewCount = location.reviewCount {
                    Text("(") + Text("\(reviewCount)") + Text(" reviews)")
                        .font(.caption).foregroundColor(.gray)
                }
                if let price = location.priceRange {
                    Text("Price: \(price)").font(.caption)
                }
                // Categories as badges
                if let categories = location.categories, !categories.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).font(.caption2).padding(6).background(Color.blue.opacity(0.1)).cornerRadius(8)
                        }
                    }
                }
                // Tags as chips
                if let tags = location.tags, !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags, id: \.self) { tag in
                            Text("#\(tag)").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
            }.padding(.top, 8)
            // Action buttons
            HStack(spacing: 12) {
                Button("Directions") { openInMaps() }
                Button("Review") { showReviewModal = true }
                Button("Add Photo") { showPhotoModal = true }
                Button("Add Tip") { showTipModal = true }
            }.padding(.vertical, 8)
            // Tabs
            Picker("Tab", selection: $selectedTab) {
                Text("About").tag(0)
                Text("Reviews").tag(1)
                Text("Photos").tag(2)
                Text("Tips").tag(3)
            }.pickerStyle(SegmentedPickerStyle()).padding(.horizontal)
            // Tab content
            TabView(selection: $selectedTab) {
                // About
                AboutSectionView(location: location, callNumber: callNumber, sendEmail: sendEmail, formatDate: formatDate)
                    .tag(0)
                // Reviews
                ReviewsSectionView(reviews: reviews)
                    .tag(1)
                // Community Photos (use the new array)
                CommunityPhotosSectionView(communityPhotos: communityPhotos)
                    .tag(2)
                // Insider Tips
                TipsSectionView(tips: tips)
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .onAppear {
            viewModel.fetchReviews(for: location.id) { self.reviews = $0 }
            viewModel.fetchInsiderTips(for: location.id) { self.tips = $0 }
            // Prefer communityPhotos from location if present and non-empty
            if let locCommunityPhotos = location.communityPhotos, !locCommunityPhotos.isEmpty {
                // Only show approved photos
                let approved = locCommunityPhotos.filter { $0.photoUrl != nil && !$0.photoUrl.isEmpty } // Ensure photoUrl is not nil or empty
                self.communityPhotos = approved.map { cp in
                    let photoIdOrUrl = cp.photoUrl
                    // If photoIdOrUrl is a full URL, use it; otherwise, construct the media URL
                    let url: String
                    if photoIdOrUrl.hasPrefix("http") {
                        url = photoIdOrUrl
                    } else {
                        url = "\(baseURL)/api/media/" + photoIdOrUrl
                    }
                    return CommunityPhoto(
                        id: cp.id,
                        photoUrl: url,
                        caption: cp.caption,
                        submittedBy: cp.submittedBy,
                        submittedAt: cp.submittedAt
                    )
                }
            } else {
                // Fallback to API fetch if not present
                viewModel.fetchCommunityPhotos(for: location.id) { self.communityPhotos = $0 }
            }
        }
        .sheet(isPresented: $showReviewModal) {
            WriteReviewModal(locationId: location.id) {
                viewModel.fetchReviews(for: location.id) { self.reviews = $0 }
                viewModel.fetchInsiderTips(for: location.id) { self.tips = $0 }
                viewModel.fetchCommunityPhotos(for: location.id) { self.communityPhotos = $0 }
            }
            .environmentObject(auth)
        }
        .sheet(isPresented: $showTipModal) {
            AddTipModal(locationId: location.id) {
                viewModel.fetchInsiderTips(for: location.id) { self.tips = $0 }
            }
            .environmentObject(auth)
        }
        .sheet(isPresented: $showPhotoModal) {
            AddPhotoModal(locationId: location.id) {
                viewModel.fetchReviews(for: location.id) { self.reviews = $0 }
                viewModel.fetchInsiderTips(for: location.id) { self.tips = $0 }
                viewModel.fetchCommunityPhotos(for: location.id) { self.communityPhotos = $0 }
            }
            .environmentObject(auth)
        }
    }
    // Section header helper
    @ViewBuilder
    func SectionHeader(_ title: String) -> some View {
        Text(title).font(.headline).padding(.top, 8)
    }
    // Open in Maps helper
    func openInMaps() {
        let lat = location.coordinates.latitude
        let lon = location.coordinates.longitude
        
        print("[DEBUG] Opening directions for location: \(location.name)")
        print("[DEBUG] Coordinates: lat=\(lat), lng=\(lon)")
        
        // Validate coordinates
        if lat == 0.0 && lon == 0.0 {
            print("[ERROR] Invalid coordinates (0,0) for location: \(location.name)")
            return
        }
        
        if lat < -90 || lat > 90 || lon < -180 || lon > 180 {
            print("[ERROR] Coordinates out of range for location: \(location.name)")
            return
        }
        
        if let url = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lon)") {
            print("[DEBUG] Opening directions URL: \(url)")
            UIApplication.shared.open(url)
        } else {
            print("[ERROR] Failed to create directions URL for coordinates: \(lat), \(lon)")
        }
    }
    // Call helper
    func callNumber(_ number: String) {
        if let url = URL(string: "tel://\(number)") {
            UIApplication.shared.open(url)
        }
    }
    // Email helper
    func sendEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    // Date formatter
    func formatDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: iso) {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .short
            return df.string(from: date)
        }
        return iso
    }
}

// MARK: - Location Preview Sheet
struct LocationPreviewSheet: View {
    let preview: LocationPreview
    let primaryColor: Color
    let secondaryColor: Color
    let onViewDetails: () -> Void
    @State private var showClaimModal = false
    @State private var showComprehensiveClaimModal = false
    
    // Check if location is unclaimed
    private var isUnclaimed: Bool {
        preview.ownership?.claimStatus == "unclaimed"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced drag indicator with gradient
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 40, height: 6)
                .padding(.top, 10)
                .padding(.bottom, 6)
            
            // Content with enhanced styling
            VStack(alignment: .leading, spacing: 16) {
                // Header with image and basic info
                HStack(alignment: .top, spacing: 14) {
                    // Enhanced location image with shadow and border
                    if let imageUrl = preview.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ZStack {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [primaryColor.opacity(0.15), secondaryColor.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(primaryColor.opacity(0.7))
                            }
                        }
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [primaryColor.opacity(0.3), secondaryColor.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    } else {
                        ZStack {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [primaryColor.opacity(0.15), secondaryColor.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(primaryColor.opacity(0.7))
                        }
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [primaryColor.opacity(0.3), secondaryColor.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    
                    // Enhanced location info with better typography
                    VStack(alignment: .leading, spacing: 6) {
                        // Title and badges with improved layout
                        HStack(alignment: .top) {
                            Text(preview.name)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Spacer(minLength: 8)
                            
                            // Enhanced verification badges
                            HStack(spacing: 6) {
                                if preview.isVerified == true {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 14, weight: .semibold))
                                        .background(
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 20, height: 20)
                                        )
                                        .shadow(color: .green.opacity(0.3), radius: 2, x: 0, y: 1)
                                }
                                
                                if preview.isFeatured == true {
                                    Image(systemName: "star.circle.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 14, weight: .semibold))
                                        .background(
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 20, height: 20)
                                        )
                                        .shadow(color: .yellow.opacity(0.3), radius: 2, x: 0, y: 1)
                                }
                                
                                // Unclaimed location indicator
                                if isUnclaimed {
                                    Image(systemName: "hand.raised.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 14, weight: .semibold))
                                        .background(
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 20, height: 20)
                                        )
                                        .shadow(color: .orange.opacity(0.3), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                        
                        // Enhanced address with icon
                        if let address = preview.address {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(primaryColor.opacity(0.8))
                                
                                Text(address)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        // Unclaimed location notice
                        if isUnclaimed {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.orange)
                                
                                Text("This location needs more information - help by claiming it!")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.orange)
                                    .lineLimit(2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.orange.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        // Enhanced rating and reviews with better styling
                        if let rating = preview.rating {
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.yellow)
                                    
                                    Text(String(format: "%.1f", rating))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.yellow.opacity(0.15))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.yellow.opacity(0.3), lineWidth: 0.5)
                                        )
                                )
                                
                                if let reviewCount = preview.reviewCount {
                                    Text("(\(reviewCount) reviews)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // Enhanced categories with better styling
                if let categories = preview.categories, !categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories.prefix(3), id: \.self) { category in
                                Text(category)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [secondaryColor, secondaryColor.opacity(0.8)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: secondaryColor.opacity(0.3), radius: 3, x: 0, y: 2)
                                    )
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                
                // Enhanced action buttons with better styling
                HStack(spacing: 12) {
                    if isUnclaimed {
                        // Claim Location button (primary action for unclaimed locations)
                        Button(action: {
                            showComprehensiveClaimModal = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Claim Location")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.orange.opacity(0.4), radius: 6, x: 0, y: 3)
                            )
                        }
                        
                        // View Details button for unclaimed locations
                        Button(action: onViewDetails) {
                            HStack(spacing: 6) {
                                Text("View Details")
                                    .font(.system(size: 13, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: primaryColor.opacity(0.4), radius: 6, x: 0, y: 3)
                            )
                        }
                        
                        Spacer()
                        
                        // Directions button (secondary action)
                        Button(action: {
                            openInMaps()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Directions")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(primaryColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [primaryColor, primaryColor.opacity(0.8)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                                    .shadow(color: primaryColor.opacity(0.2), radius: 4, x: 0, y: 2)
                            )
                        }
                    } else {
                        // Standard buttons for claimed locations
                        // Enhanced Directions button
                        Button(action: {
                            openInMaps()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Directions")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(primaryColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [primaryColor, primaryColor.opacity(0.8)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                                    .shadow(color: primaryColor.opacity(0.2), radius: 4, x: 0, y: 2)
                            )
                        }
                        
                        Spacer()
                        
                        // Enhanced View Details button with gradient
                        Button(action: onViewDetails) {
                            HStack(spacing: 6) {
                                Text("View Details")
                                    .font(.system(size: 14, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: primaryColor.opacity(0.4), radius: 6, x: 0, y: 3)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.98)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 25, x: 0, y: -8)
        )
        .frame(maxHeight: 220) // Slightly increased height for better spacing
        .sheet(isPresented: $showClaimModal) {
            ClaimBusinessModal(
                locationId: preview.id,
                locationName: preview.name,
                isPresented: $showClaimModal
            )
        }
        .sheet(isPresented: $showComprehensiveClaimModal) {
            ComprehensiveClaimModal(
                locationId: preview.id,
                locationName: preview.name,
                isPresented: $showComprehensiveClaimModal
            )
        }
    }
    
    // Open in Maps helper
    func openInMaps() {
        guard let coordinates = preview.coordinates else { 
            print("[ERROR] No coordinates available for preview: \(preview.name)")
            return 
        }
        let lat = coordinates.latitude
        let lon = coordinates.longitude
        
        print("[DEBUG] Opening directions for preview: \(preview.name)")
        print("[DEBUG] Coordinates: lat=\(lat), lng=\(lon)")
        
        // Validate coordinates
        if lat == 0.0 && lon == 0.0 {
            print("[ERROR] Invalid coordinates (0,0) for preview: \(preview.name)")
            return
        }
        
        if lat < -90 || lat > 90 || lon < -180 || lon > 180 {
            print("[ERROR] Coordinates out of range for preview: \(preview.name)")
            return
        }
        
        if let url = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lon)") {
            print("[DEBUG] Opening directions URL: \(url)")
            UIApplication.shared.open(url)
        } else {
            print("[ERROR] Failed to create directions URL for coordinates: \(lat), \(lon)")
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Add AboutSectionView subview to break up the large About tab content
struct AboutSectionView: View {
    let location: Location
    let callNumber: (String) -> Void
    let sendEmail: (String) -> Void
    let formatDate: (String) -> String
    @ViewBuilder
    func SectionHeader(_ title: String) -> some View {
        Text(title).font(.headline).padding(.top, 8)
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Description
                if let desc = location.description {
                    SectionHeader("About This Place")
                    Text(desc)
                }
                // Address & Neighborhood
                if let address = location.address {
                    SectionHeader("Address")
                    Text(address)
                }
                if let neighborhood = location.neighborhood {
                    SectionHeader("Neighborhood")
                    Text(neighborhood)
                }
                // Business Hours
                if let businessHours = location.businessHours, !businessHours.isEmpty {
                    SectionHeader("Business Hours")
                    VStack(alignment: .leading) {
                        ForEach(businessHours.indices, id: \ .self) { idx in
                            let h = businessHours[idx]
                            Text("\(h.day ?? ""): \(h.closed == true ? "Closed" : "\(h.open ?? "") - \(h.close ?? "")")")
                        }
                    }
                }
                // Contact Info
                if let contact = location.contactInfo {
                    SectionHeader("Contact")
                    VStack(alignment: .leading, spacing: 4) {
                        if let phone = contact.phone {
                            Button(action: { callNumber(phone) }) {
                                Label(phone, systemImage: "phone")
                            }
                        }
                        if let email = contact.email {
                            Button(action: { sendEmail(email) }) {
                                Label(email, systemImage: "envelope")
                            }
                        }
                        if let website = contact.website, let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)") {
                            Link(destination: url) {
                                Label(website, systemImage: "globe")
                            }
                        }
                        if let social = contact.socialMedia {
                            if let ig = social.instagram, let url = URL(string: "https://instagram.com/\(ig)") {
                                Link("Instagram", destination: url)
                            }
                            if let fb = social.facebook, let url = URL(string: "https://facebook.com/\(fb)") {
                                Link("Facebook", destination: url)
                            }
                            if let tw = social.twitter, let url = URL(string: "https://twitter.com/\(tw)") {
                                Link("Twitter", destination: url)
                            }
                            if let li = social.linkedin, let url = URL(string: "https://linkedin.com/company/\(li)") {
                                Link("LinkedIn", destination: url)
                            }
                        }
                    }
                }
                // Accessibility
                if let accessibility = location.accessibility {
                    SectionHeader("Accessibility")
                    HStack(spacing: 8) {
                        if accessibility.wheelchairAccess == true {
                            Label("Wheelchair Accessible", systemImage: "figure.roll")
                        }
                        if accessibility.parking == true {
                            Label("Parking Available", systemImage: "car")
                        }
                        if let other = accessibility.other {
                            Text(other)
                        }
                    }
                }
                // Best Time to Visit
                if let bestTime = location.bestTimeToVisit, !bestTime.isEmpty {
                    SectionHeader("Best Time to Visit")
                    Text(bestTime.map { $0.season }.joined(separator: ", "))
                }
                // Partnership Info
                if location.hasBusinessPartnership == true, let partnership = location.partnershipDetails {
                    SectionHeader("Business Partnership")
                    VStack(alignment: .leading) {
                        if let name = partnership.partnerName { Text("Partner: \(name)") }
                        if let details = partnership.details { Text(details) }
                    }
                }
                // Meta Info
                SectionHeader("Meta Info")
                VStack(alignment: .leading, spacing: 2) {
                    if let createdBy = location.createdBy { Text("Created by: \(createdBy)") }
                    if let createdAt = location.createdAt { Text("Created at: \(formatDate(createdAt))") }
                    if let updatedAt = location.updatedAt { Text("Updated at: \(formatDate(updatedAt))") }
                    HStack(spacing: 8) {
                        Label(location.isSaved == true ? "Saved" : "Not Saved", systemImage: location.isSaved == true ? "bookmark.fill" : "bookmark")
                        Label(location.isSubscribed == true ? "Subscribed" : "Not Subscribed", systemImage: location.isSubscribed == true ? "bell.fill" : "bell")
                    }.font(.caption)
                }
            }
        }
    }
}

// Add ReviewsSectionView, CommunityPhotosSectionView, and TipsSectionView subviews
struct ReviewsSectionView: View {
    let reviews: [Review]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(reviews) { review in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(review.author?.name ?? "").bold()
                            Text("★ \(String(format: "%.1f", review.rating))")
                        }
                        if let title = review.title {
                            Text(title).font(.headline)
                        }
                        MentionDisplayView(text: review.content)
                        if let pros = review.pros, !pros.isEmpty {
                            Text("Pros: \(pros.joined(separator: ", "))").font(.caption)
                        }
                        if let cons = review.cons, !cons.isEmpty {
                            Text("Cons: \(cons.joined(separator: ", "))").font(.caption)
                        }
                        if let tips = review.tips {
                            Text("Tip: \(tips)").font(.caption)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
}

struct CommunityPhotosSectionView: View {
    let communityPhotos: [CommunityPhoto]
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(communityPhotos) { photo in
                    if let url = URL(string: photo.photoUrl) {
                        VStack {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.1)
                            }
                            .frame(width: 120, height: 120)
                            .clipped()
                            .cornerRadius(8)
                            if let caption = photo.caption {
                                Text(caption).font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TipsSectionView: View {
    let tips: [InsiderTip]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(tips) { tip in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tip.category).font(.caption).foregroundColor(.blue)
                        Text(tip.tip)
                        if let priority = tip.priority {
                            Text("Priority: \(priority)").font(.caption2)
                        }
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
}

/*
// Modal views are defined in LocationDetailView.swift - commenting out duplicates
struct WriteReviewModal: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var rating: Double = 4.0
    @State private var visitDate: Date = Date()
    @State private var pros: String = ""
    @State private var cons: String = ""
    @State private var tips: String = ""
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var success = false
    
    // These should be passed in from the parent
    var locationId: String = ""
    var onSubmit: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Title", text: $title)
                }
                Section(header: Text("Content")) {
                    MentionInputView(
                        text: $content,
                        placeholder: "Write your review...",
                        maxLength: 1000
                    )
                    .frame(height: 100)
                }
                Section(header: Text("Rating")) {
                    Slider(value: $rating, in: 1...5, step: 0.5)
                    Text(String(format: "%.1f", rating))
                }
                Section(header: Text("Visit Date")) {
                    DatePicker("Visit Date", selection: $visitDate, displayedComponents: .date)
                }
                Section(header: Text("Pros (comma separated)")) {
                    TextField("Pros", text: $pros)
                }
                Section(header: Text("Cons (comma separated)")) {
                    TextField("Cons", text: $cons)
                }
                Section(header: Text("Tips (optional)")) {
                    TextField("Tips", text: $tips)
                }
                if let error = error {
                    Section { Text(error).foregroundColor(.red) }
                }
                if success {
                    Section { Text("Review submitted!").foregroundColor(.green) }
                }
            }
            .navigationBarTitle("Write a Review", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() }, trailing: Button(isLoading ? "Submitting..." : "Submit") {
                submitReview()
            }.disabled(isLoading || title.isEmpty || content.isEmpty))
        }
    }
    
    func submitReview() {
        isLoading = true
        error = nil
        success = false
        let urlString = "\(baseURL)/api/mobile/locations/\(locationId)/reviews"
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let tokenShared = AuthManager.shared.token ?? "nil"
        print("AuthManager.shared.token:", tokenShared)
        if let token = AuthManager.shared.token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        }
        print("Request headers before sending:", request.allHTTPHeaderFields ?? [:])
        let dateFormatter = ISO8601DateFormatter()
        let body: [String: Any] = [
            "title": title,
            "content": content,
            "rating": rating,
            "visitDate": dateFormatter.string(from: visitDate),
            "pros": pros.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            "cons": cons.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            "tips": tips.isEmpty ? nil : tips,
            "reviewType": "location",
            "location": locationId
        ].compactMapValues { $0 }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, err in
            DispatchQueue.main.async {
                isLoading = false
                if let err = err {
                    error = err.localizedDescription
                    print("Review submission error:", err)
                    return
                }
                guard let data = data else {
                    error = "No data received"
                    print("No data received")
                    return
                }
                print("API response:", String(data: data, encoding: .utf8) ?? "nil")
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let successVal = json["success"] as? Bool, successVal {
                        success = true
                        onSubmit?()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                        error = (json["error"] as? String) ?? "Unknown error"
                    }
                } else {
                    error = "Unknown error"
                }
            }
        }.resume()
    }
}
*/

/*
struct AddTipModal: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var auth: AuthManager
    @State private var category: String = ""
    @State private var tip: String = ""
    @State private var priority: String = "medium"
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var success = false
    var locationId: String = ""
    var onSubmit: (() -> Void)? = nil
    let categories = [
        "timing": "⏰ Best Times to Visit",
        "food": "🍽️ Food & Drinks",
        "secrets": "💡 Local Secrets",
        "protips": "🎯 Pro Tips",
        "access": "🚗 Getting There",
        "savings": "💰 Money Saving",
        "recommendations": "📱 What to Order/Try",
        "hidden": "🎪 Hidden Features"
    ]
    let priorities = [
        "high": "🔥 Essential",
        "medium": "⭐ Helpful",
        "low": "💡 Nice to Know"
    ]
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(categories.keys.sorted(), id: \.self) { key in
                            Text(categories[key] ?? key).tag(key)
                        }
                    }
                }
                Section(header: Text("Tip")) {
                    TextEditor(text: $tip).frame(height: 80)
                }
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities.keys.sorted(), id: \.self) { key in
                            Text(priorities[key] ?? key).tag(key)
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                }
                if let error = error {
                    Section { Text(error).foregroundColor(.red) }
                }
                if success {
                    Section { Text("Tip submitted!").foregroundColor(.green) }
                }
            }
            .navigationBarTitle("Add Insider Tip", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() }, trailing: Button(isLoading ? "Submitting..." : "Submit") {
                submitTip()
            }.disabled(isLoading || category.isEmpty || tip.isEmpty))
        }
    }
    func submitTip() {
        isLoading = true
        error = nil
        success = false
        guard let token = AuthManager.shared.token, !token.isEmpty else {
            error = "You must be logged in to submit a tip"
            isLoading = false
            return
        }
        let tipSubmission = InsiderTipSubmission(category: category, tip: tip, priority: priority)
        LocationsViewModel().submitInsiderTip(for: locationId, tip: tipSubmission, token: token) { ok in
            DispatchQueue.main.async {
                isLoading = false
                if ok {
                    success = true
                    onSubmit?()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    error = "Failed to submit tip. Please try again."
                }
            }
        }
    }
}
*/

/*
struct AddPhotoModal: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var auth: AuthManager
    @State private var selectedImage: UIImage? = nil
    @State private var imagePickerPresented = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var caption: String = ""
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var success = false
    var locationId: String = ""
    var onSubmit: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Photo")) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                    } else {
                        HStack {
                            Button("Camera") {
                                imagePickerSource = .camera
                                imagePickerPresented = true
                            }
                            Spacer()
                            Button("Photo Library") {
                                imagePickerSource = .photoLibrary
                                imagePickerPresented = true
                            }
                        }
                    }
                }
                Section(header: Text("Caption (optional)")) {
                    TextField("Caption", text: $caption)
                }
                if let error = error {
                    Section { Text(error).foregroundColor(.red) }
                }
                if success {
                    Section { Text("Photo submitted!").foregroundColor(.green) }
                }
            }
            .navigationBarTitle("Add Community Photo", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() }, trailing: Button(isLoading ? "Submitting..." : "Submit") {
                submitPhoto()
            }.disabled(isLoading || selectedImage == nil))
            .sheet(isPresented: $imagePickerPresented) {
                ImagePicker(image: $selectedImage, sourceType: imagePickerSource)
            }
        }
    }
    
    func submitPhoto() {
        guard let image = selectedImage else { error = "Please select a photo"; return }
        isLoading = true
        error = nil
        success = false
        // 1. Upload image to backend
        uploadImage(image: image) { result in
            switch result {
            case .success(let photoUrl):
                // 2. Submit photoUrl and caption to community-photos endpoint
                let urlString = "\(baseURL)/api/mobile/locations/\(locationId)/community-photos"
                guard let url = URL(string: urlString) else {
                    error = "Invalid URL"; isLoading = false; return
                }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                if let token = AuthManager.shared.token, !token.isEmpty {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
                }
                let body: [String: Any] = [
                    "photoUrl": photoUrl,
                    "caption": caption.isEmpty ? nil : caption
                ].compactMapValues { $0 }
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                URLSession.shared.dataTask(with: request) { data, response, err in
                    DispatchQueue.main.async {
                        isLoading = false
                        if let err = err {
                            error = err.localizedDescription
                            return
                        }
                        guard let data = data else {
                            error = "No data received"
                            return
                        }
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let successVal = json["success"] as? Bool, successVal {
                            success = true
                            onSubmit?()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        } else {
                            let msg = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                            error = msg?["error"] as? String ?? "Unknown error"
                        }
                    }
                }.resume()
            case .failure(let uploadError):
                isLoading = false
                error = uploadError.localizedDescription
            }
        }
    }
    
    // Helper to upload image to backend and get URL
    func uploadImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            completion(.failure(NSError(domain: "Image conversion failed", code: 0)));
            return
        }
        let url = URL(string: "\(baseURL)/api/mobile/upload/image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = AuthManager.shared.token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        }
        var body = Data()
        // Add image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        // Add locationId
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"locationId\"\r\n\r\n".data(using: .utf8)!)
        body.append(locationId.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        // Add caption (optional)
        if !caption.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".data(using: .utf8)!)
            body.append(caption.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        // Add category (optional, default to 'other')
        let category = "other"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        body.append(category.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { data, response, err in
            if let err = err {
                print("[UPLOAD] Error:", err)
                completion(.failure(err)); return
            }
            guard let data = data else {
                print("[UPLOAD] No data received from upload API")
                completion(.failure(NSError(domain: "No data", code: 0)));
                return
            }
            print("[UPLOAD] Raw API response:", String(data: data, encoding: .utf8) ?? "nil")
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let url = json["url"] as? String {
                completion(.success(url))
            } else {
                let msg = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                let errorMsg = msg?["error"] as? String ?? "Image upload failed"
                print("[UPLOAD] Error message from API:", errorMsg)
                completion(.failure(NSError(domain: errorMsg, code: 0)))
            }
        }.resume()
    }
}
*/

// ImagePicker is now defined in EnhancedLocationDetailView.swift

struct AddToBucketListModal: View {
    var body: some View { Text("Add To Bucket List Modal") }
}

// MARK: - Location Extension for SearchLocation Conversion
extension Location {
    init(from searchLocation: SearchLocation) {
        self.id = searchLocation.id
        self.name = searchLocation.name
        self.address = searchLocation.address
        self.coordinates = MapCoordinates(
            latitude: searchLocation.coordinates?.latitude ?? 0,
            longitude: searchLocation.coordinates?.longitude ?? 0
        )
        self.featuredImage = searchLocation.featuredImage
        self.imageUrl = nil
        self.rating = searchLocation.rating
        self.description = searchLocation.description
        self.shortDescription = nil
        self.slug = nil
        self.gallery = nil
        self.categories = searchLocation.categories
        self.tags = nil
        self.priceRange = searchLocation.priceRange
        // businessHours is now already [BusinessHour]? so no conversion needed
        self.businessHours = searchLocation.businessHours
        
        // Convert LocationContactInfo to ContactInfo
        if let locationContactInfo = searchLocation.contactInfo {
            self.contactInfo = ContactInfo(
                phone: locationContactInfo.phone,
                email: locationContactInfo.email,
                website: locationContactInfo.website,
                socialMedia: locationContactInfo.socialMedia
            )
        } else {
            self.contactInfo = nil
        }
        self.accessibility = nil
        self.bestTimeToVisit = nil
        self.insiderTips = nil
        self.isVerified = searchLocation.isVerified
        self.isFeatured = searchLocation.isFeatured
        self.hasBusinessPartnership = nil
        self.partnershipDetails = nil
        self.neighborhood = searchLocation.neighborhood
        self.isSaved = nil
        self.isSubscribed = nil
        self.createdBy = nil
        self.createdAt = searchLocation.createdAt
        self.updatedAt = searchLocation.updatedAt
        self.ownership = nil
        self.reviewCount = searchLocation.reviewCount
        self.visitCount = nil
        self.reviews = nil
        self.communityPhotos = nil
    }
} 
