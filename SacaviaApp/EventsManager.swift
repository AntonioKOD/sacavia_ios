import Foundation
import SwiftUI

// MARK: - Data Structures

struct Event: Identifiable, Codable {
    let id: String
    let name: String // Changed from title to name to match backend
    let description: String
    let slug: String
    let eventType: String
    let category: String
    let startDate: String
    let endDate: String
    let image: EventGalleryItem? // Changed from featuredImage to image
    let gallery: [EventGalleryItem]
    let location: EventLocation?
    let organizer: EventOrganizer?
    let capacity: Int? // Changed from maxParticipants to capacity
    let attendeeCount: Int // Changed from participantCount
    let interestedCount: Int
    let goingCount: Int
    let invitedCount: Int // Added missing field
    let isFree: Bool // Added missing field
    let price: Double? // Added missing field
    let currency: String? // Added missing field
    let status: String // Added missing field
    let tags: [String]
    let userRsvpStatus: String? // Changed from userParticipation
    let matchmakingSettings: [String: String]?
    let createdAt: String
    let updatedAt: String
    
    // Computed properties for backward compatibility
    var title: String { name }
    var featuredImage: String? { image?.url }
    var maxParticipants: Int? { capacity }
    var participantCount: Int { attendeeCount }
    var userParticipation: UserParticipation? {
        guard let status = userRsvpStatus else { return nil }
        return UserParticipation(status: status, joinedAt: createdAt)
    }
    
    init(from dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.name = dictionary["name"] as? String ?? dictionary["title"] as? String ?? ""
        self.description = dictionary["description"] as? String ?? ""
        self.slug = dictionary["slug"] as? String ?? ""
        self.eventType = dictionary["eventType"] as? String ?? ""
        self.category = dictionary["category"] as? String ?? ""
        self.startDate = dictionary["startDate"] as? String ?? ""
        self.endDate = dictionary["endDate"] as? String ?? ""
        
        // Parse image
        if let imageData = dictionary["image"] as? [String: Any] {
            self.image = EventGalleryItem(from: imageData)
        } else if let imageUrl = dictionary["featuredImage"] as? String {
            self.image = EventGalleryItem(url: imageUrl, alt: nil)
        } else {
            self.image = nil
        }
        
        // Parse gallery
        if let galleryData = dictionary["gallery"] as? [[String: Any]] {
            self.gallery = galleryData.compactMap { EventGalleryItem(from: $0) }
        } else {
            self.gallery = []
        }
        
        // Parse location
        if let locationData = dictionary["location"] as? [String: Any] {
            self.location = EventLocation(from: locationData)
        } else {
            self.location = nil
        }
        
        // Parse organizer
        if let organizerData = dictionary["organizer"] as? [String: Any] {
            self.organizer = EventOrganizer(from: organizerData)
        } else {
            self.organizer = nil
        }
        
        self.capacity = dictionary["capacity"] as? Int ?? dictionary["maxParticipants"] as? Int
        self.attendeeCount = dictionary["attendeeCount"] as? Int ?? dictionary["participantCount"] as? Int ?? 0
        self.interestedCount = dictionary["interestedCount"] as? Int ?? 0
        self.goingCount = dictionary["goingCount"] as? Int ?? 0
        self.invitedCount = dictionary["invitedCount"] as? Int ?? 0
        self.isFree = dictionary["isFree"] as? Bool ?? true
        self.price = dictionary["price"] as? Double
        self.currency = dictionary["currency"] as? String
        self.status = dictionary["status"] as? String ?? "published"
        
        // Convert matchmakingSettings to [String: String] if it exists
        if let settings = dictionary["matchmakingSettings"] as? [String: Any] {
            self.matchmakingSettings = settings.compactMapValues { value in
                if let stringValue = value as? String {
                    return stringValue
                } else {
                    return String(describing: value)
                }
            }
        } else {
            self.matchmakingSettings = nil
        }
        
        self.tags = dictionary["tags"] as? [String] ?? []
        
        // Parse user participation
        if let participationData = dictionary["userParticipation"] as? [String: Any] {
            self.userRsvpStatus = participationData["status"] as? String
        } else {
            self.userRsvpStatus = nil
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
        slug = try container.decode(String.self, forKey: .slug)
        eventType = try container.decode(String.self, forKey: .eventType)
        category = try container.decode(String.self, forKey: .category)
        startDate = try container.decode(String.self, forKey: .startDate)
        endDate = try container.decode(String.self, forKey: .endDate)
        image = try container.decodeIfPresent(EventGalleryItem.self, forKey: .image)
        gallery = try container.decode([EventGalleryItem].self, forKey: .gallery)
        location = try container.decodeIfPresent(EventLocation.self, forKey: .location)
        organizer = try container.decodeIfPresent(EventOrganizer.self, forKey: .organizer)
        capacity = try container.decodeIfPresent(Int.self, forKey: .capacity)
        attendeeCount = try container.decode(Int.self, forKey: .attendeeCount)
        interestedCount = try container.decode(Int.self, forKey: .interestedCount)
        goingCount = try container.decode(Int.self, forKey: .goingCount)
        invitedCount = try container.decode(Int.self, forKey: .invitedCount)
        isFree = try container.decode(Bool.self, forKey: .isFree)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        currency = try container.decodeIfPresent(String.self, forKey: .currency)
        status = try container.decode(String.self, forKey: .status)
        tags = try container.decode([String].self, forKey: .tags)
        userRsvpStatus = try container.decodeIfPresent(String.self, forKey: .userRsvpStatus)
        matchmakingSettings = try container.decodeIfPresent([String: String].self, forKey: .matchmakingSettings)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(slug, forKey: .slug)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(category, forKey: .category)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encode(gallery, forKey: .gallery)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(organizer, forKey: .organizer)
        try container.encodeIfPresent(capacity, forKey: .capacity)
        try container.encode(attendeeCount, forKey: .attendeeCount)
        try container.encode(interestedCount, forKey: .interestedCount)
        try container.encode(goingCount, forKey: .goingCount)
        try container.encode(invitedCount, forKey: .invitedCount)
        try container.encode(isFree, forKey: .isFree)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encodeIfPresent(currency, forKey: .currency)
        try container.encode(status, forKey: .status)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(userRsvpStatus, forKey: .userRsvpStatus)
        try container.encodeIfPresent(matchmakingSettings, forKey: .matchmakingSettings)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, slug, eventType, category, startDate, endDate
        case image, gallery, location, organizer, capacity, attendeeCount
        case interestedCount, goingCount, invitedCount, isFree, price, currency
        case status, tags, userRsvpStatus, matchmakingSettings, createdAt, updatedAt
    }
    
    // Custom initializer for creating events with direct parameters
    init(id: String, name: String, description: String, startDate: String, endDate: String, image: EventGalleryItem?, category: String, eventType: String, location: EventLocation?, organizer: EventOrganizer?, capacity: Int?, attendeeCount: Int, interestedCount: Int, goingCount: Int, invitedCount: Int, isFree: Bool, price: Double?, currency: String?, status: String, tags: [String], userRsvpStatus: String?, matchmakingSettings: [String: String]?, createdAt: String, updatedAt: String) {
        self.id = id
        self.name = name
        self.description = description
        self.slug = name.lowercased().replacingOccurrences(of: " ", with: "-")
        self.eventType = eventType
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.image = image
        self.gallery = []
        self.location = location
        self.organizer = organizer
        self.capacity = capacity
        self.attendeeCount = attendeeCount
        self.interestedCount = interestedCount
        self.goingCount = goingCount
        self.invitedCount = invitedCount
        self.isFree = isFree
        self.price = price
        self.currency = currency
        self.status = status
        self.tags = tags
        self.userRsvpStatus = userRsvpStatus
        self.matchmakingSettings = matchmakingSettings
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct EventGalleryItem: Codable {
    let url: String?
    let alt: String?
    
    init(from dictionary: [String: Any]) {
        self.url = dictionary["url"] as? String ?? dictionary["image"] as? String
        self.alt = dictionary["alt"] as? String ?? dictionary["caption"] as? String
    }
    
    init(url: String?, alt: String?) {
        self.url = url
        self.alt = alt
    }
    
    // Add Codable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        alt = try container.decodeIfPresent(String.self, forKey: .alt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(alt, forKey: .alt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case url, alt
    }
}

struct EventLocation: Codable {
    let id: String
    let name: String
    let address: String?
    let coordinates: EventCoordinates?
    
    init(from dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.name = dictionary["name"] as? String ?? ""
        self.address = dictionary["address"] as? String
        
        if let coordsData = dictionary["coordinates"] as? [String: Any] {
            self.coordinates = EventCoordinates(from: coordsData)
        } else {
            self.coordinates = nil
        }
    }
    
    // Add Codable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        coordinates = try container.decodeIfPresent(EventCoordinates.self, forKey: .coordinates)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(coordinates, forKey: .coordinates)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, address, coordinates
    }
    
    // Custom initializer for creating locations with direct parameters
    init(id: String, name: String, description: String?, address: EventAddress?, coordinates: EventCoordinates?, featuredImage: EventGalleryItem?, categories: [EventCategory]) {
        self.id = id
        self.name = name
        self.address = address?.street
        self.coordinates = coordinates
    }
}

struct EventCoordinates: Codable {
    let latitude: Double
    let longitude: Double
    
    init(from dictionary: [String: Any]) {
        self.latitude = dictionary["latitude"] as? Double ?? 0.0
        self.longitude = dictionary["longitude"] as? Double ?? 0.0
    }
    
    // Add Codable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
    
    // Custom initializer for creating coordinates with direct parameters
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct EventOrganizer: Codable {
    let id: String
    let name: String
    let avatar: String?
    
    init(from dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.name = dictionary["name"] as? String ?? ""
        self.avatar = dictionary["avatar"] as? String
    }
    
    // Add Codable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(avatar, forKey: .avatar)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, avatar
    }
    
    // Custom initializer for creating organizers with direct parameters
    init(id: String, name: String, profileImage: EventGalleryItem?) {
        self.id = id
        self.name = name
        self.avatar = profileImage?.url
    }
}

struct UserParticipation: Codable {
    let status: String
    let joinedAt: String
    
    init(status: String, joinedAt: String) {
        self.status = status
        self.joinedAt = joinedAt
    }
    
    init(from dictionary: [String: Any]) {
        self.status = dictionary["status"] as? String ?? ""
        self.joinedAt = dictionary["joinedAt"] as? String ?? ""
    }
    
    // Add Codable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)
        joinedAt = try container.decode(String.self, forKey: .joinedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try container.encode(joinedAt, forKey: .joinedAt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case status, joinedAt
    }
}

// MARK: - Additional Data Structures for Event Detail View

struct EventCategory: Codable {
    let name: String
    
    init(name: String) {
        self.name = name
    }
}

struct EventType: Codable {
    let name: String
    
    init(name: String) {
        self.name = name
    }
}

struct EventAddress: Codable {
    let street: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    
    init(street: String?, city: String?, state: String?, zip: String?, country: String?) {
        self.street = street
        self.city = city
        self.state = state
        self.zip = zip
        self.country = country
    }
}

struct EventUser: Codable {
    let id: String
    let name: String
    let avatar: String?
    
    init(id: String, name: String, avatar: String?) {
        self.id = id
        self.name = name
        self.avatar = avatar
    }
    
    // Add Codable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(avatar, forKey: .avatar)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, avatar
    }
}

// MARK: - EventsManager Class

class EventsManager: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authManager = AuthManager.shared
    private let baseURL = baseAPIURL
    
    func fetchEvents(type: String = "all", completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/api/mobile/events?type=\(type)&limit=20&page=1") else {
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
                       let eventsData = data["events"] as? [[String: Any]] {
                        
                        self?.events = eventsData.compactMap { eventData in
                            Event(from: eventData)
                        }
                        
                        completion(true, nil)
                    } else {
                        let message = result?["message"] as? String ?? "Failed to load events"
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
    
    func refreshEvents(type: String = "all") {
        fetchEvents(type: type) { _, _ in }
    }
    
    // MARK: - Event Creation
    
    func createEvent(eventData: [String: Any]) async -> (success: Bool, errorMessage: String?) {
        guard let token = AuthManager.shared.token else {
            print("No authentication token available")
            return (false, "No authentication token available")
        }
        
        do {
            let url = URL(string: "\(baseURL)/api/mobile/events")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let jsonData = try JSONSerialization.data(withJSONObject: eventData)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Create event response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Create event response: \(responseString ?? "No response")")
                    return (true, nil)
                } else {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Create event error response: \(responseString ?? "No response")")
                    
                    // Parse error message from response
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? String {
                        return (false, error)
                    } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let message = json["message"] as? String {
                        return (false, message)
                    } else {
                        return (false, "Failed to create event. Please try again.")
                    }
                }
            }
            
            return (false, "Network error occurred")
        } catch {
            print("Error creating event: \(error)")
            return (false, "Network error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Event Participation
    
    func updateEventParticipation(eventId: String, status: String, invitedUserId: String? = nil) async -> Bool {
        print("🔍 [EventsManager] Starting updateEventParticipation...")
        print("🔍 [EventsManager] Event ID: \(eventId)")
        print("🔍 [EventsManager] Status: \(status)")
        print("🔍 [EventsManager] Invited User ID: \(invitedUserId ?? "nil")")
        
        guard let token = AuthManager.shared.token else {
            print("❌ [EventsManager] No authentication token available")
            return false
        }
        
        print("🔍 [EventsManager] Token available: \(token.prefix(20))...")
        
        do {
            let url = URL(string: "\(baseURL)/api/mobile/events/\(eventId)/rsvp")!
            print("🔍 [EventsManager] API URL: \(url)")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            var requestBody: [String: Any] = ["status": status]
            if let invitedUserId = invitedUserId {
                requestBody["invitedUserId"] = invitedUserId
            }
            
            print("🔍 [EventsManager] Request body: \(requestBody)")
            
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            print("🔍 [EventsManager] Making API request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 [EventsManager] RSVP response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    let responseString = String(data: data, encoding: .utf8)
                    print("🔍 [EventsManager] RSVP success response: \(responseString ?? "No response")")
                    return true
                } else {
                    let responseString = String(data: data, encoding: .utf8)
                    print("❌ [EventsManager] RSVP error response: \(responseString ?? "No response")")
                }
            }
            
            return false
        } catch {
            print("❌ [EventsManager] Error updating event participation: \(error)")
            return false
        }
    }
    
    // MARK: - Event Participants
    

    
    // MARK: - Event Invites
    
    func inviteUsersToEvent(eventId: String, userIds: [String]) async -> Bool {
        guard let token = AuthManager.shared.token else {
            print("No authentication token available")
            return false
        }
        
        do {
            let url = URL(string: "\(baseURL)/api/mobile/events/\(eventId)/invite")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let requestBody = ["userIds": userIds]
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Invite users response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Invite users response: \(responseString ?? "No response")")
                    return true
                } else {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Invite users error response: \(responseString ?? "No response")")
                }
            }
            
            return false
        } catch {
            print("Error inviting users to event: \(error)")
            return false
        }
    }
    
    // MARK: - User Search and Discovery
    
    func searchUsers(query: String, limit: Int = 20) async -> [AuthUser]? {
        guard let token = AuthManager.shared.token else {
            print("No authentication token available")
            return nil
        }
        
        do {
            let url = URL(string: "\(baseURL)/api/mobile/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&type=users&limit=\(limit)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Search users response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Search users response: \(responseString ?? "No response")")
                    
                    // Parse the response to extract users
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let data = json["data"] as? [String: Any],
                       let results = data["results"] as? [String: Any],
                       let users = results["users"] as? [[String: Any]] {
                        
                        return users.compactMap { (userData: [String: Any]) -> AuthUser? in
                            guard let id = userData["id"] as? String,
                                  let name = userData["name"] as? String else {
                                return nil
                            }
                            
                            let email = userData["email"] as? String ?? ""
                            let username = userData["username"] as? String
                            let profileImage = userData["profileImage"] as? String
                            let bio = userData["bio"] as? String
                            let isVerified = userData["isVerified"] as? Bool ?? false
                            let followerCount = userData["followerCount"] as? Int ?? 0
                            
                            return AuthUser(
                                id: id,
                                name: name,
                                email: email,
                                username: username,
                                profileImage: profileImage != nil ? ProfileImage(url: profileImage!) : nil, // Changed from profileImage to ProfileImage object
                                bio: bio,
                                isVerified: isVerified,
                                followerCount: followerCount
                            )
                        }
                    }
                } else {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Search users error response: \(responseString ?? "No response")")
                }
            }
            
            return nil
        } catch {
            print("Error searching users: \(error)")
            return nil
        }
    }
    
    func getFollowers(userId: String) async -> [AuthUser]? {
        guard let token = AuthManager.shared.token else {
            print("No authentication token available")
            return nil
        }
        
        do {
            let url = URL(string: "\(baseURL)/api/mobile/users/\(userId)/followers")!
            print("🔍 EventsManager: Getting followers for user: \(userId)")
            print("🔍 EventsManager: URL: \(url)")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Get followers response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Get followers response: \(responseString ?? "No response")")
                    
                    // Parse the response to extract followers
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let data = json["data"] as? [String: Any],
                       let followers = data["followers"] as? [[String: Any]] {
                        
                        print("🔍 EventsManager: Found \(followers.count) followers in response")
                        
                        let parsedFollowers = followers.compactMap { (followerData: [String: Any]) -> AuthUser? in
                            guard let id = followerData["id"] as? String,
                                  let name = followerData["name"] as? String else {
                                print("🔍 EventsManager: Failed to parse follower data: \(followerData)")
                                return nil
                            }
                            
                            let email = followerData["email"] as? String
                            
                            let username = followerData["username"] as? String
                            let profileImage = followerData["profileImage"] as? String
                            let bio = followerData["bio"] as? String
                            let isVerified = followerData["isVerified"] as? Bool ?? false
                            let followerCount = followerData["followerCount"] as? Int ?? 0
                            
                            return AuthUser(
                                id: id,
                                name: name,
                                email: email,
                                username: username,
                                profileImage: profileImage != nil ? ProfileImage(url: profileImage!) : nil, // Changed from profileImage to ProfileImage object
                                bio: bio,
                                isVerified: isVerified,
                                followerCount: followerCount
                            )
                        }
                        
                        print("🔍 EventsManager: Successfully parsed \(parsedFollowers.count) followers")
                        return parsedFollowers
                    }
                } else {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Get followers error response: \(responseString ?? "No response")")
                }
            }
            
            return nil
        } catch {
            print("Error getting followers: \(error)")
            return nil
        }
    }
    
    func getFollowing(userId: String) async -> [AuthUser]? {
        guard let token = AuthManager.shared.token else {
            print("No authentication token available")
            return nil
        }
        
        do {
            let url = URL(string: "\(baseURL)/api/mobile/users/\(userId)/following")!
            print("🔍 EventsManager: Getting following for user: \(userId)")
            print("🔍 EventsManager: URL: \(url)")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Get following response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Get following response: \(responseString ?? "No response")")
                    
                    // Parse the response to extract following users
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let data = json["data"] as? [String: Any],
                       let following = data["following"] as? [[String: Any]] {
                        
                        print("🔍 EventsManager: Found \(following.count) following users in response")
                        
                        let parsedFollowing = following.compactMap { (followingData: [String: Any]) -> AuthUser? in
                            guard let id = followingData["id"] as? String,
                                  let name = followingData["name"] as? String else {
                                print("🔍 EventsManager: Failed to parse following data: \(followingData)")
                                return nil
                            }
                            
                            let email = followingData["email"] as? String
                            
                            let username = followingData["username"] as? String
                            let profileImage = followingData["profileImage"] as? String
                            let bio = followingData["bio"] as? String
                            let isVerified = followingData["isVerified"] as? Bool ?? false
                            let followerCount = followingData["followerCount"] as? Int ?? 0
                            
                            return AuthUser(
                                id: id,
                                name: name,
                                email: email,
                                username: username,
                                profileImage: profileImage != nil ? ProfileImage(url: profileImage!) : nil, // Changed from profileImage to ProfileImage object
                                bio: bio,
                                isVerified: isVerified,
                                followerCount: followerCount
                            )
                        }
                        
                        print("🔍 EventsManager: Successfully parsed \(parsedFollowing.count) following users")
                        return parsedFollowing
                    }
                } else {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Get following error response: \(responseString ?? "No response")")
                }
            }
            
            return nil
        } catch {
            print("Error getting following: \(error)")
            return nil
        }
    }
    
    // MARK: - Event Participants
    
    func fetchEventParticipants(eventId: String) async -> [EventParticipant]? {
        guard let token = AuthManager.shared.token else {
            print("No authentication token available")
            return nil
        }
        
        do {
            let url = URL(string: "\(baseURL)/api/mobile/events/\(eventId)/participants")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Participants response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    let decoder = JSONDecoder()
                    let participantsResponse = try decoder.decode(EventParticipantsResponse.self, from: data)
                    
                    if participantsResponse.success, let participantsData = participantsResponse.data {
                        print("Successfully fetched \(participantsData.participants.count) participants")
                        return participantsData.participants
                    } else {
                        print("Participants API error: \(participantsResponse.message)")
                        return nil
                    }
                } else {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Participants error response: \(responseString ?? "No response")")
                    return nil
                }
            }
            
            return nil
        } catch {
            print("Error fetching event participants: \(error)")
            return nil
        }
    }
    
    // MARK: - Single Event Fetching
    
            func fetchEvent(eventId: String) async -> Event? {
            guard let token = AuthManager.shared.token else {
                print("No authentication token available")
                return nil
            }
            
            do {
                let url = URL(string: "\(baseURL)/api/mobile/events/\(eventId)")!
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Single event response status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        // Try to decode as JSON first to see the actual response
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("Single event raw response: \(jsonString)")
                        }
                        
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .useDefaultKeys
                        
                        do {
                            let eventResponse = try decoder.decode(EventResponse.self, from: data)
                            
                            if eventResponse.success, let eventData = eventResponse.data {
                                print("Successfully fetched event: \(eventData.name)")
                                return eventData
                            } else {
                                print("Single event API error: \(eventResponse.message)")
                                return nil
                            }
                        } catch let decodeError {
                            print("Error decoding single event response: \(decodeError)")
                            // Try to decode just the basic fields
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let dataDict = json["data"] as? [String: Any] {
                                print("Attempting to create Event from dictionary")
                                return Event(from: dataDict)
                            }
                            return nil
                        }
                    } else {
                        let responseString = String(data: data, encoding: .utf8)
                        print("Single event error response: \(responseString ?? "No response")")
                        return nil
                    }
                }
                
                return nil
            } catch {
                print("Error fetching single event: \(error)")
                return nil
            }
        }
} 