import SwiftUI
import PhotosUI

// Category struct for location categories
struct LocationCategory: Identifiable {
    let id: String
    let name: String
    let description: String?
    
    init(id: String, name: String, description: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
    }
}

// Business Hour struct
struct AddFormBusinessHour {
    var day: String
    var open: String?
    var close: String?
    var closed: Bool
}

// Address struct to match backend API
struct AddFormLocationAddress {
    var street: String = ""
    var city: String = ""
    var state: String = ""
    var zip: String = ""
    var country: String = "USA"
    var neighborhood: String = ""
}

// Coordinates struct
struct AddFormLocationCoordinates {
    var latitude: Double = 0.0
    var longitude: Double = 0.0
}

// Contact Info struct
struct AddFormContactInfo {
    var phone: String = ""
    var email: String = ""
    var website: String = ""
    var socialMedia: AddFormSocialMedia = AddFormSocialMedia()
}

struct AddFormSocialMedia {
    var facebook: String = ""
    var twitter: String = ""
    var instagram: String = ""
    var linkedin: String = ""
}

// Accessibility struct
struct AddFormAccessibilityInfo {
    var wheelchairAccess: Bool = false
    var parking: Bool = false
    var other: String = ""
}

struct AddLocationView: View {
    var body: some View {
        EnhancedAddLocationView()
    }
}

struct LegacyAddLocationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var step = 0
    
    // Brand colors from web design
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B - Vivid Coral
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4 - Bright Teal
    private let accentColor = Color(red: 255/255, green: 230/255, blue: 109/255) // #FFE66D - Warm Yellow
    private let backgroundColor = Color(red: 243/255, green: 244/255, blue: 246/255) // #F3F4F6 - Whisper Gray
    private let cardBackground = Color.white
    private let textPrimary = Color(red: 51/255, green: 51/255, blue: 51/255) // #333333 - Dark Charcoal
    private let textSecondary = Color(red: 102/255, green: 102/255, blue: 102/255) // #666666 - Medium Gray
    
    // Core location data
    @State private var name = ""
    @State private var slug = ""
    @State private var description = ""
    @State private var shortDescription = ""
    @State private var selectedCategories: [String] = []
    @State private var tags: [String] = []
    @State private var newTag = ""
    
    // Address data
    @State private var address = AddFormLocationAddress()
    @State private var coordinates = AddFormLocationCoordinates()
    
    // Media data
    @State private var featuredImageItem: PhotosPickerItem? = nil
    @State private var featuredImageData: Data? = nil
    @State private var featuredImageId: String = ""
    @State private var featuredImageUploading = false
    @State private var featuredImageError: String? = nil
    @State private var galleryItems: [PhotosPickerItem] = []
    @State private var galleryImagesData: [Data] = []
    @State private var galleryImageIds: [String] = []
    @State private var galleryUploading: [Bool] = []
    @State private var galleryErrors: [String?] = []
    @State private var galleryCaptions: [String] = []
    
    // Contact & Business data
    @State private var contactInfo = AddFormContactInfo()
    @State private var businessHours: [AddFormBusinessHour] = [
        AddFormBusinessHour(day: "Monday", open: "09:00", close: "17:00", closed: false),
        AddFormBusinessHour(day: "Tuesday", open: "09:00", close: "17:00", closed: false),
        AddFormBusinessHour(day: "Wednesday", open: "09:00", close: "17:00", closed: false),
        AddFormBusinessHour(day: "Thursday", open: "09:00", close: "17:00", closed: false),
        AddFormBusinessHour(day: "Friday", open: "09:00", close: "17:00", closed: false),
        AddFormBusinessHour(day: "Saturday", open: "10:00", close: "15:00", closed: false),
        AddFormBusinessHour(day: "Sunday", open: nil, close: nil, closed: true)
    ]
    @State private var priceRange = ""
    
    // Visitor information
    @State private var bestTimeToVisit: [String] = []
    @State private var insiderTips = ""
    @State private var accessibility = AddFormAccessibilityInfo()
    
    // Privacy & Settings
    @State private var privacy = "public"
    @State private var privateAccess: [String] = []
    @State private var isFeatured = false
    @State private var isVerified = false
    @State private var hasPartnership = false
    @State private var partnerName = ""
    @State private var partnerContact = ""
    @State private var partnershipDetails = ""
    
    // SEO metadata
    @State private var metaTitle = ""
    @State private var metaDescription = ""
    @State private var metaKeywords = ""
    
    // State
    @State private var isLoading = false
    @State private var error: String?
    @State private var success = false
    @State private var isCheckingDuplicate = false
    @State private var duplicateCheckResult: String?
    @State private var allCategories: [LocationCategory] = []
    @State private var categorySearchText: String = ""
    @State private var isLoadingCategories = false
    @State private var categoriesError: String?
    
    // Slug auto-generation
    private var autoSlug: String { 
        name.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
    
    // Load categories from API
    private func loadCategories() {
        isLoadingCategories = true
        categoriesError = nil
        
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/categories") else {
            categoriesError = "Invalid URL"
            isLoadingCategories = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication
        if let token = AuthManager.shared.token {
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoadingCategories = false
                
                if let error = error {
                    self.categoriesError = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.categoriesError = "No data received"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = json["success"] as? Bool,
                       success,
                       let dataDict = json["data"] as? [String: Any],
                       let categoriesArray = dataDict["categories"] as? [[String: Any]] {
                        
                        self.allCategories = categoriesArray.compactMap { categoryDict in
                            guard let id = categoryDict["id"] as? String,
                                  let name = categoryDict["name"] as? String else {
                                return nil
                            }
                            
                            let description = categoryDict["description"] as? String
                            return LocationCategory(id: id, name: name, description: description)
                        }
                        
                        print("📱 AddLocationView: Loaded \(self.allCategories.count) categories")
                    } else {
                        self.categoriesError = "Failed to parse categories"
                    }
                } catch {
                    self.categoriesError = "Failed to parse response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    

    
    var body: some View {
        Text("Legacy AddLocationView - Should not be used")
            .foregroundColor(.red)
    }
    
    private func submitLocation() {
        isLoading = true
        error = nil
        
        // Create location data for API
        let locationData: [String: Any] = [
            "name": name,
            "slug": slug.isEmpty ? autoSlug : slug,
            "description": description,
            "shortDescription": shortDescription,
            "categories": selectedCategories,
            "tags": tags,
            "address": [
                "street": address.street,
                "city": address.city,
                "state": address.state,
                "zip": address.zip,
                "country": address.country,
                "neighborhood": address.neighborhood
            ],
            "coordinates": [
                "latitude": coordinates.latitude,
                "longitude": coordinates.longitude
            ],
            "contactInfo": [
                "phone": contactInfo.phone,
                "email": contactInfo.email,
                "website": contactInfo.website
            ],
            "privacy": privacy,
            "isFeatured": isFeatured,
            "isVerified": isVerified
        ]
        
        Task {
            do {
                let success = await createLocationAPI(locationData: locationData)
                await MainActor.run {
                    isLoading = false
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                        error = "Failed to create location. Please try again."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    self.error = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func createLocationAPI(locationData: [String: Any]) async -> Bool {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: locationData)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 Create location status: \(httpResponse.statusCode)")
                return httpResponse.statusCode == 200 || httpResponse.statusCode == 201
            }
            
            return false
        } catch {
            print("📱 Error creating location: \(error)")
            return false
        }
    }
}
