import SwiftUI
import PhotosUI
import MapKit
import CoreLocation

// Category struct for location categories
struct LocationCategory: Identifiable, Decodable {
    let id: String
    let name: String
    let description: String?
    
    init(id: String, name: String, description: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
    }
}

// Mobile API response structures
struct MobileCategoriesResponse: Decodable {
    let success: Bool
    let message: String
    let data: MobileCategoriesData?
    let error: String?
    let code: String?
}

struct MobileCategoriesData: Decodable {
    let categories: [MobileCategory]
    let total: Int
}

struct MobileCategory: Decodable {
    let id: String
    let name: String
    let slug: String
    let description: String?
    let source: String?
    let foursquareIcon: FoursquareIcon?
    let subcategories: [String]?
    let parent: ParentCategory?
    let order: Int?
    let isActive: Bool?
}

struct ParentCategory: Decodable {
    let id: String?
    let name: String?
    let slug: String?
    let description: String?
    let source: String?
    let foursquareIcon: FoursquareIcon?
    let isActive: Bool?
}

struct FoursquareIcon: Decodable {
    let prefix: String?
    let suffix: String?
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
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var description = ""
    @State private var address = ""
    @State private var selectedCategories: [String] = []
    @State private var uploadedImages: [UIImage] = []
    @State private var isLoading = false
    @State private var isGeocoding = false
    @State private var error: String?
    @State private var success = false
    @State private var geocodingError: String?
    @State private var useManualCoordinates = false
    @State private var manualLatitude = ""
    @State private var manualLongitude = ""
    @State private var showingImagePicker = false
    @State private var usePinLocation = false
    @State private var showingMapPicker = false
    @State private var pinnedCoordinates: (latitude: Double, longitude: Double)?
    @State private var pinnedAddress: String?
    
    // Privacy settings
    @State private var privacy = "public"
    @State private var privateAccess: [String] = []
    
    // Brand colors
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B - Brand coral red
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4 - Brand teal
    private let backgroundColor = Color(red: 249/255, green: 250/255, blue: 251/255) // #F9FAFB
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header - matching web app style
                        VStack(spacing: 16) {
                            VStack(spacing: 8) {
                                Text("Add a Location")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Quick and easy - just the essentials to get your location on the map!")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.secondary)
                                    Text("Takes less than 1 minute to complete")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // Form Card - matching web app structure
                        VStack(spacing: 0) {
                            // Card Header with brand gradient
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "building.2")
                                        .foregroundColor(primaryColor)
                                    Text("Location Details")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                Text("Fill in the basic information about this location")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 16)
                            .background(
                                LinearGradient(
                                    colors: [primaryColor.opacity(0.1), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            
                            // Form Fields
                            VStack(spacing: 20) {
                                // Location Name
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Location Name *")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    TextField("e.g., Joe's Coffee Shop", text: $name)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(height: 48)
                                }
                                
                                // Description
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("What makes this place special? *")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    TextEditor(text: $description)
                                        .frame(minHeight: 80)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                    
                                    HStack {
                                        Spacer()
                                        Text("\(description.count)/200 characters")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Address
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "mappin")
                                            .foregroundColor(primaryColor)
                                        Text(usePinLocation ? "Location (Optional)" : "Full Address *")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                    }
                                    
                                    if usePinLocation {
                                        // Pin Location Display
                                        VStack(spacing: 12) {
                                            if let pinnedCoords = pinnedCoordinates, let pinnedAddr = pinnedAddress {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    HStack {
                                                        Image(systemName: "mappin.circle.fill")
                                                            .foregroundColor(primaryColor)
                                                        Text("Pinned Location")
                                                            .font(.system(size: 14, weight: .medium))
                                                        Spacer()
                                                        Button("Change") {
                                                            showingMapPicker = true
                                                        }
                                                        .font(.caption)
                                                        .foregroundColor(primaryColor)
                                                    }
                                                    
                                                    Text(pinnedAddr)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .padding(.leading, 20)
                                                    
                                                    Text("Lat: \(String(format: "%.4f", pinnedCoords.latitude)), Lng: \(String(format: "%.4f", pinnedCoords.longitude))")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                        .padding(.leading, 20)
                                                }
                                                .padding(14)
                                                .background(.ultraThinMaterial)
                                                .cornerRadius(12)
                                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                                            } else {
                                                Button(action: { showingMapPicker = true }) {
                                                    HStack(spacing: 8) {
                                                        Image(systemName: "mappin.and.ellipse")
                                                            .font(.system(size: 16, weight: .semibold))
                                                        Text("Pin Location on Map")
                                                            .font(.system(size: 16, weight: .semibold))
                                                    }
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 14)
                                                    .background(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .cornerRadius(12)
                                                    .shadow(color: primaryColor.opacity(0.25), radius: 8, x: 0, y: 4)
                                                }
                                            }
                                        }
                                    } else {
                                        TextField("e.g., 123 Main St, Boston, MA 02101", text: $address)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .frame(height: 48)
                                            .onChange(of: address) { _ in
                                                geocodingError = nil
                                                useManualCoordinates = false
                                            }
                                    }
                                    
                                    // Location Method Toggle
                                    HStack {
                                        Button(action: { 
                                            usePinLocation.toggle()
                                            if usePinLocation {
                                                address = ""
                                                geocodingError = nil
                                                useManualCoordinates = false
                                            } else {
                                                pinnedCoordinates = nil
                                                pinnedAddress = nil
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: usePinLocation ? "mappin.circle" : "text.cursor")
                                                Text(usePinLocation ? "Use Address Instead" : "Pin on Map Instead")
                                            }
                                            .font(.caption)
                                            .foregroundColor(secondaryColor)
                                        }
                                        
                                        Spacer()
                                        
                                        if !usePinLocation {
                                            Text("We'll automatically find the exact location from your address.")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    // Geocoding Error Display
                                    if let geocodingError = geocodingError {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(geocodingError)
                                                .font(.caption)
                                                .foregroundColor(primaryColor)
                                            
                                            Button("Enter coordinates manually") {
                                                useManualCoordinates = true
                                            }
                                            .font(.caption)
                                            .foregroundColor(primaryColor)
                                        }
                                        .padding(12)
                                        .background(primaryColor.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    
                                    // Manual Coordinates Input
                                    if useManualCoordinates {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Image(systemName: "mappin")
                                                    .foregroundColor(secondaryColor)
                                                Text("Enter coordinates manually")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(secondaryColor)
                                            }
                                            
                                            HStack(spacing: 12) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Latitude")
                                                        .font(.caption)
                                                        .foregroundColor(secondaryColor)
                                                    TextField("42.3601", text: $manualLatitude)
                                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                                        .keyboardType(.decimalPad)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Longitude")
                                                        .font(.caption)
                                                        .foregroundColor(secondaryColor)
                                                    TextField("-71.0589", text: $manualLongitude)
                                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                                        .keyboardType(.decimalPad)
                                                }
                                            }
                                            
                                            HStack {
                                                Button("Try address again") {
                                                    useManualCoordinates = false
                                                    geocodingError = nil
                                                    manualLatitude = ""
                                                    manualLongitude = ""
                                                }
                                                .font(.caption)
                                                .foregroundColor(secondaryColor)
                                                
                                                Spacer()
                                                
                                                Text("💡 Find coordinates on Google Maps")
                                                    .font(.caption)
                                                    .foregroundColor(secondaryColor)
                                            }
                                        }
                                        .padding(16)
                                        .background(secondaryColor.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                // Categories
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Category (Optional)")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    SimpleCategorySelector(
                                        selectedCategories: $selectedCategories, 
                                        selectedColor: secondaryColor,
                                        enableDatabaseSearch: true
                                    )
                                }
                                
                                // Photos
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "photo")
                                            .foregroundColor(primaryColor)
                                        Text("Photos (Optional)")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                    }
                                    
                                    HStack {
                                        Button(action: { 
                                            print("📸 [iOS] Photo picker button tapped")
                                            showingImagePicker = true 
                                        }) {
                                            HStack {
                                                Image(systemName: "plus")
                                                Text("Add Photos (\(uploadedImages.count)/3)")
                                            }
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                        }
                                        .disabled(uploadedImages.count >= 3)
                                        
                                        if uploadedImages.count > 0 {
                                            Text("\(uploadedImages.count) photo\(uploadedImages.count != 1 ? "s" : "") selected")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    // Image Previews
                                    if !uploadedImages.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(Array(uploadedImages.enumerated()), id: \.offset) { index, image in
                                                    ZStack(alignment: .topTrailing) {
                                                        Image(uiImage: image)
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: 80, height: 80)
                                                            .clipped()
                                                            .cornerRadius(8)
                                                        
                                                        Button(action: { removeImage(at: index) }) {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .foregroundColor(primaryColor)
                                                                .background(Color.white, in: Circle())
                                                        }
                                                        .offset(x: 8, y: -8)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 4)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        
                        // Privacy Settings
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Privacy Settings")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 8) {
                                // Public option
                                Button(action: {
                                    privacy = "public"
                                    privateAccess = []
                                }) {
                                    HStack {
                                        Image(systemName: privacy == "public" ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(privacy == "public" ? primaryColor : .gray)
                                        Text("Public - Everyone can see this location")
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                                
                                // Followers option
                                Button(action: {
                                    privacy = "followers"
                                    privateAccess = []
                                }) {
                                    HStack {
                                        Image(systemName: privacy == "followers" ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(privacy == "followers" ? primaryColor : .gray)
                                        Text("Followers - Only your followers can see this")
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                                
                                // Private option
                                Button(action: {
                                    privacy = "private"
                                    privateAccess = []
                                }) {
                                    HStack {
                                        Image(systemName: privacy == "private" ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(privacy == "private" ? primaryColor : .gray)
                                        Text("Private - Only you can see this location")
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)
                        
                        // Error Message
                        if let error = error {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(primaryColor)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(primaryColor)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(primaryColor.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                        }
                        
                        // Submit Button
                        Button(action: {
                            print("🔘 Button pressed! Form valid: \(isFormValid())")
                            submitLocation()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "plus")
                                }
                                Text(isLoading ? (isGeocoding ? "Finding Location..." : "Adding Location...") : "Add to Community")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: isFormValid() ? [primaryColor, secondaryColor] : [Color.gray, Color.gray.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: isFormValid() ? primaryColor.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading || !isFormValid())
                        .onAppear {
                            print("🔘 Button appeared. Form valid: \(isFormValid())")
                            print("🔘 Name: '\(name)', Description: '\(description)'")
                            print("🔘 Use Pin: \(usePinLocation), Pinned Coords: \(pinnedCoordinates != nil)")
                            print("🔘 Use Manual: \(useManualCoordinates), Address: '\(address)'")
                        }
                        .padding(.horizontal, 20)
                        
                        // Business Owner Info Card
                        VStack(spacing: 16) {
                            VStack(spacing: 8) {
                                Text("Business Owner?")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("If you own this business, you can claim it after it's added to get full control and add detailed information.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button("Find Your Business") {
                                // TODO: Navigate to map to find business
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(primaryColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(primaryColor, lineWidth: 1)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(primaryColor.opacity(0.05))
                            )
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            LocationImagePicker(images: $uploadedImages, maxImages: 3)
                .onAppear {
                    print("📸 [iOS] Photo picker sheet appeared")
                }
        }
        .sheet(isPresented: $showingMapPicker) {
            MapLocationPicker(
                coordinates: $pinnedCoordinates,
                address: $pinnedAddress
            )
        }
        .alert("Success", isPresented: $success) {
            Button("OK") {
                success = false
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Location added successfully!")
        }
    }
    
    // MARK: - Actions
    
    private func removeImage(at index: Int) {
        uploadedImages.remove(at: index)
    }
    
    private func submitLocation() {
        print("🚀 Submit button pressed!")
        print("🚀 Starting form validation...")
        
        guard validateForm() else { 
            print("❌ Form validation failed - stopping submission")
            return 
        }
        
        print("✅ Form validation passed - proceeding with submission")
        isLoading = true
        error = nil
        isGeocoding = true
        
        Task {
            do {
                print("🌐 Calling createLocationAPI...")
                let success = await createLocationAPI()
                print("🌐 API call completed with success: \(success)")
                
                await MainActor.run {
                    isLoading = false
                    isGeocoding = false
                    if success {
                        print("✅ Location created successfully!")
                        self.success = true
                    } else {
                        print("❌ Location creation failed")
                        error = "Failed to add location. Please try again."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    isGeocoding = false
                    self.error = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func isFormValid() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Basic validation - name and description are required
        if trimmedName.isEmpty || trimmedDescription.isEmpty {
            return false
        }
        
        // If using pin location, coordinates must be set
        if usePinLocation && pinnedCoordinates == nil {
            return false
        }
        
        // If using manual coordinates, both must be provided
        if useManualCoordinates && (manualLatitude.isEmpty || manualLongitude.isEmpty) {
            return false
        }
        
        // If using address (not pin, not manual), address must be provided
        if !usePinLocation && !useManualCoordinates && address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        
        return true
    }
    
    private func validateForm() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🔍 Validating form...")
        print("🔍 Name: '\(trimmedName)'")
        print("🔍 Description: '\(trimmedDescription)'")
        print("🔍 Address: '\(address)'")
        print("🔍 Use Pin Location: \(usePinLocation)")
        print("🔍 Use Manual Coordinates: \(useManualCoordinates)")
        print("🔍 Pinned Coordinates: \(pinnedCoordinates != nil ? "\(pinnedCoordinates!.latitude), \(pinnedCoordinates!.longitude)" : "nil")")
        
        if trimmedName.isEmpty {
            error = "Location name is required"
            return false
        }
        
        if trimmedDescription.isEmpty {
            error = "Description is required"
            return false
        }
        
        if !usePinLocation && !useManualCoordinates && address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            error = "Address is required"
            return false
        }
        
        if useManualCoordinates && (manualLatitude.isEmpty || manualLongitude.isEmpty) {
            error = "Please enter both latitude and longitude"
            return false
        }
        
        if usePinLocation && pinnedCoordinates == nil {
            error = "Please pin a location on the map"
            print("❌ Validation failed: Using pin location but no coordinates")
            return false
        }
        
        print("✅ Form validation passed")
        return true
    }
    
    private func createLocationAPI() async -> Bool {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations") else {
            print("❌ Invalid API URL: \(baseAPIURL)/api/mobile/locations")
            return false
        }
        
        print("🔍 Creating location at: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ Using authentication token: \(String(token.prefix(20)))...")
        } else {
            print("❌ No valid authentication token found")
            print("❌ AuthManager.shared.token: \(AuthManager.shared.token ?? "nil")")
            print("❌ AuthManager.shared.isAuthenticated: \(AuthManager.shared.isAuthenticated)")
        }
        
        do {
            // Prepare address components
            var addressComponents: [String: String] = [:]
            var coordinates: [String: Double] = [:]
            
            if usePinLocation, let pinnedCoords = pinnedCoordinates {
                // Use pinned coordinates
                coordinates = ["latitude": pinnedCoords.latitude, "longitude": pinnedCoords.longitude]
                print("📍 Using pinned coordinates: lat=\(pinnedCoords.latitude), lng=\(pinnedCoords.longitude)")
                
                // Parse the pinned address if available
                if let pinnedAddr = pinnedAddress {
                    addressComponents = parseAddressString(pinnedAddr)
                    print("📍 Using pinned address: \(pinnedAddr)")
                } else {
                    addressComponents = [
                        "street": "Pinned Location",
                        "city": "",
                        "state": "",
                        "zip": "",
                        "country": "US"
                    ]
                    print("📍 Using default address for pinned location")
                }
            } else if useManualCoordinates {
                if let lat = Double(manualLatitude), let lng = Double(manualLongitude) {
                    coordinates = ["latitude": lat, "longitude": lng]
                    addressComponents = [
                        "street": "Manual Coordinates",
                        "city": "",
                        "state": "",
                        "zip": "",
                        "country": "US"
                    ]
                }
            } else {
                // Parse address string - let the mobile API handle geocoding
                addressComponents = parseAddressString(address)
                print("📍 Using address for geocoding: \(address)")
            }
            
            // Upload photos first if any
            var mediaIds: [String] = []
            print("📸 [iOS] DEBUG: uploadedImages.count = \(uploadedImages.count)")
            if !uploadedImages.isEmpty {
                print("📸 [iOS] Uploading \(uploadedImages.count) photos...")
                mediaIds = await uploadPhotos(uploadedImages)
                print("📸 [iOS] Uploaded photos, got media IDs: \(mediaIds)")
            } else {
                print("📸 [iOS] No images to upload")
            }
            
            // Generate AI metadata
            let aiMetadata = await generateAIMetadata(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                categories: selectedCategories
            )
            
            // Create location data for mobile API
            var locationData: [String: Any] = [
                "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                "description": description.trimmingCharacters(in: .whitespacesAndNewlines),
                "address": addressComponents,
                "categories": selectedCategories,
                "meta": aiMetadata
            ]
            
            // Add photos to location data
            if !mediaIds.isEmpty {
                print("📸 [iOS] Adding photos to location data: \(mediaIds)")
                locationData["featuredImage"] = mediaIds[0]
                locationData["gallery"] = mediaIds.enumerated().map { index, mediaId in
                    [
                        "image": mediaId,
                        "caption": "Gallery image \(index + 1)",
                        "order": index
                    ]
                }
                print("📸 [iOS] Featured image set to: \(mediaIds[0])")
                let galleryData = mediaIds.enumerated().map { index, mediaId in
                    [
                        "image": mediaId,
                        "caption": "Gallery image \(index + 1)",
                        "order": index
                    ]
                }
                print("📸 [iOS] Gallery set to: \(galleryData)")
            } else {
                print("📸 [iOS] No media IDs to add to location data")
            }
            
            // Only include coordinates if we have them (let the API geocode if not provided)
            if !coordinates.isEmpty {
                locationData["coordinates"] = coordinates
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: locationData)
            request.httpBody = jsonData
            
            // Debug: Print the data being sent
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Sending location data: \(jsonString)")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 Create location status: \(httpResponse.statusCode)")
                
                // Log response data for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📱 Response data: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    print("✅ Location created successfully!")
                    
                    // Send notification to refresh the map
                    NotificationCenter.default.post(name: NSNotification.Name("LocationSaveStateChanged"), object: nil)
                    print("📱 Posted LocationSaveStateChanged notification")
                    
                    return true
                } else {
                    print("❌ Create location failed with status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ Error response: \(responseString)")
                    }
                    return false
                }
            }
            
            print("❌ No HTTP response received")
            return false
        } catch {
            print("❌ Error creating location: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            return false
        }
    }
    
    private func uploadPhotos(_ images: [UIImage]) async -> [String] {
        var mediaIds: [String] = []
        
        for (index, image) in images.enumerated() {
            print("📸 Uploading photo \(index + 1)/\(images.count)")
            
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("❌ Failed to convert image to JPEG data")
                continue
            }
            
            guard let url = URL(string: "\(baseAPIURL)/api/mobile/upload/image") else {
                print("❌ Invalid upload URL")
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            // Add authentication header
            if let token = AuthManager.shared.token {
                request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
                print("📸 [iOS] Added auth token to upload request")
            } else {
                print("📸 [iOS] No auth token available for upload")
                continue
            }
            
            // Create multipart form data
            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            
            // Add file data with correct key "image" (not "file")
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo_\(index).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
            
            // Add alt text
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"alt\"\r\n\r\n".data(using: .utf8)!)
            body.append("Photo \(index + 1)\r\n".data(using: .utf8)!)
            
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📸 [iOS] Upload response status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            print("📸 [iOS] Upload response JSON: \(json)")
                            
                            // Check for success field first
                            if let success = json["success"] as? Bool, success {
                                // Get the data object and extract the id
                                if let dataObj = json["data"] as? [String: Any],
                                   let mediaId = dataObj["id"] as? String {
                                    mediaIds.append(mediaId)
                                    print("✅ [iOS] Photo \(index + 1) uploaded successfully, ID: \(mediaId)")
                                } else {
                                    print("❌ [iOS] No 'data.id' field in upload response for photo \(index + 1)")
                                    print("❌ [iOS] Available keys in data: \(json.keys)")
                                }
                            } else {
                                print("❌ [iOS] Upload failed - success field is false")
                                if let error = json["error"] as? String {
                                    print("❌ [iOS] Error message: \(error)")
                                }
                            }
                        } else {
                            print("❌ [iOS] Failed to parse upload response for photo \(index + 1)")
                        }
                    } else {
                        print("❌ [iOS] Upload failed for photo \(index + 1) with status: \(httpResponse.statusCode)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("❌ [iOS] Response: \(responseString)")
                        }
                    }
                }
            } catch {
                print("❌ [iOS] Error uploading photo \(index + 1): \(error)")
            }
        }
        
        return mediaIds
    }
    
    private func generateAIMetadata(name: String, description: String, categories: [String]) async -> [String: Any] {
        print("🤖 Generating AI metadata for: \(name)")
        
        guard let url = URL(string: "\(baseAPIURL)/api/ai/generate-metadata") else {
            print("❌ Invalid AI metadata API URL")
            return generateFallbackMetadata(name: name, description: description, categories: categories)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "name": name,
            "description": description,
            "categories": categories
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🤖 AI metadata response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = json["success"] as? Bool,
                       success,
                       let metadata = json["metadata"] as? [String: Any] {
                        print("✅ AI metadata generated successfully")
                        return metadata
                    }
                }
            }
            
            print("❌ AI metadata generation failed, using fallback")
            return generateFallbackMetadata(name: name, description: description, categories: categories)
            
        } catch {
            print("❌ Error generating AI metadata: \(error)")
            return generateFallbackMetadata(name: name, description: description, categories: categories)
        }
    }
    
    private func generateFallbackMetadata(name: String, description: String, categories: [String]) -> [String: Any] {
        let title = "\(name) - Discover on Sacavia"
        let metaDescription = "\(String(description.prefix(120))) Discover more places to explore on Sacavia."
        
        // Core Sacavia keywords
        let coreKeywords = ["sacavia", "explore", "discover", "things to do", "places to go", "local places"]
        
        // Extract meaningful words from name and description
        let nameWords = name.lowercased().components(separatedBy: " ").filter { word in
            word.count > 2 && !["the", "and", "or", "of", "in", "at", "on"].contains(word)
        }
        
        let descriptionWords = description.lowercased().components(separatedBy: " ").prefix(5).filter { word in
            word.count > 2 && !["the", "and", "or", "of", "in", "at", "on", "a", "an"].contains(word)
        }
        
        // Combine all keywords
        let allKeywords = (coreKeywords + nameWords + Array(descriptionWords) + categories).filter { $0.count > 2 }
        let uniqueKeywords = Array(Set(allKeywords)).prefix(10)
        let keywords = uniqueKeywords.joined(separator: ", ")
        
        return [
            "title": title,
            "description": metaDescription,
            "keywords": keywords
        ]
    }
    
    private func geocodeAddress(_ address: String) async -> [String: Double]? {
        // This would integrate with Mapbox or similar geocoding service
        // For now, return nil to trigger manual coordinate input
        return nil
    }
    
    private func parseAddressString(_ addressString: String) -> [String: String] {
        let parts = addressString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        if parts.count >= 2 {
            return [
                "street": parts[0],
                "city": parts[1],
                "state": parts.count > 2 ? parts[2] : "",
                "zip": parts.count > 3 ? parts[3] : "",
                "country": parts.count > 4 ? parts[4] : "US"
            ]
        } else {
            return [
                "street": addressString,
                "city": "",
                "state": "",
                "zip": "",
                "country": "US"
            ]
        }
    }
}

// MARK: - Location Image Picker
struct LocationImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    let maxImages: Int
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        print("📸 [iOS] Creating UIImagePickerController")
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        // Check if photo library is available
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            print("📸 [iOS] Photo library is available")
            picker.sourceType = .photoLibrary
        } else {
            print("❌ [iOS] Photo library is not available")
            picker.sourceType = .camera
        }
        
        picker.allowsEditing = false
        print("📸 [iOS] UIImagePickerController created with source: \(picker.sourceType.rawValue)")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        print("📸 [iOS] Creating Coordinator for LocationImagePicker")
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: LocationImagePicker
        
        init(_ parent: LocationImagePicker) {
            print("📸 [iOS] Coordinator initialized")
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("📸 [iOS] imagePickerController didFinishPickingMediaWithInfo called")
            print("📸 [iOS] Info keys: \(info.keys)")
            
            if let image = info[.originalImage] as? UIImage {
                print("📸 [iOS] Image selected, current count: \(parent.images.count), max: \(parent.maxImages)")
                if parent.images.count < parent.maxImages {
                    parent.images.append(image)
                    print("📸 [iOS] Image added to array, new count: \(parent.images.count)")
                } else {
                    print("📸 [iOS] Max images reached, not adding image")
                }
            } else {
                print("📸 [iOS] Failed to get image from picker")
                print("📸 [iOS] Available info keys: \(info.keys)")
                if let originalImage = info[.originalImage] {
                    print("📸 [iOS] Original image type: \(type(of: originalImage))")
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("📸 [iOS] Image picker cancelled")
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Simple Category Selector
struct SimpleCategorySelector: View {
    @Binding var selectedCategories: [String]
    @State private var allCategories: [LocationCategory] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var showingSearch = false
    let selectedColor: Color
    let enableDatabaseSearch: Bool
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Search Button
            if enableDatabaseSearch {
                Button(action: { showingSearch = true }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text(selectedCategories.isEmpty ? "Search categories..." : "\(selectedCategories.count) categories selected")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading categories...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Only show selected categories, not all available categories
                if !selectedCategories.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(selectedCategories, id: \.self) { categoryId in
                            if let category = allCategories.first(where: { $0.id == categoryId }) {
                                Button(action: {
                                    toggleCategory(category.id)
                                }) {
                                    Text(category.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedColor)
                                        )
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if enableDatabaseSearch {
                loadCategories()
            }
        }
        .sheet(isPresented: $showingSearch) {
            CategorySearchView(
                selectedCategories: $selectedCategories,
                selectedColor: selectedColor
            )
        }
    }
    
    private func toggleCategory(_ categoryId: String) {
        if selectedCategories.contains(categoryId) {
            selectedCategories.removeAll { $0 == categoryId }
        } else {
            selectedCategories.append(categoryId)
        }
    }
    
    private func loadCategories() {
        print("🔍 Starting to load categories...")
        isLoading = true
        // Load categories from API
        Task {
            do {
                let categories = await fetchCategoriesFromAPI()
                await MainActor.run {
                    self.allCategories = categories
                    self.isLoading = false
                    print("📱 Loaded \(categories.count) categories from database")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("❌ Failed to load categories: \(error)")
                }
            }
        }
    }
    
    private func fetchCategoriesFromAPI() async -> [LocationCategory] {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/categories") else {
            print("❌ Invalid categories API URL: \(baseAPIURL)/api/mobile/categories")
            return []
        }
        
        print("🔍 Creating location at: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = AuthManager.shared.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 Categories API response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    // Parse the mobile API response format
                    let response = try JSONDecoder().decode(MobileCategoriesResponse.self, from: data)
                    if response.success, let categoriesData = response.data {
                        let categories = categoriesData.categories.map { category in
                            LocationCategory(
                                id: category.id,
                                name: category.name,
                                description: category.description
                            )
                        }
                        print("✅ Successfully parsed \(categories.count) categories")
                        return categories
                    } else {
                        print("❌ API response not successful: \(response.message ?? "Unknown error")")
                    }
                } else {
                    print("❌ Categories API failed with status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ Error response: \(responseString)")
                    }
                }
            }
        } catch {
            print("❌ Error fetching categories: \(error)")
        }
        
        return []
    }
}

// MARK: - Draggable Pin View
struct DraggablePinView: View {
    let coordinate: CLLocationCoordinate2D
    let region: MKCoordinateRegion
    let onCoordinateChanged: (CLLocationCoordinate2D) -> Void
    let pinColor: Color = Color.red

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            let screenCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let pinPosition = screenCenter.applying(.init(translationX: dragOffset.width, y: dragOffset.height))
            
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(pinColor)
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                )
                .scaleEffect(isDragging ? 1.3 : 1.0)
                .shadow(radius: isDragging ? 8 : 4)
                .position(pinPosition)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            isDragging = false
                            
                            // Convert final position to coordinate
                            let finalPosition = screenCenter.applying(.init(translationX: value.translation.width, y: value.translation.height))
                            let newCoordinate = convertScreenPointToCoordinate(
                                screenPoint: finalPosition,
                                screenSize: geometry.size,
                                region: region
                            )
                            
                            onCoordinateChanged(newCoordinate)
                            dragOffset = .zero
                        }
                )
                .animation(.easeInOut(duration: 0.2), value: isDragging)
        }
    }
    
    private func convertScreenPointToCoordinate(screenPoint: CGPoint, screenSize: CGSize, region: MKCoordinateRegion) -> CLLocationCoordinate2D {
        let mapViewHeight = screenSize.height - 120
        let mapViewWidth = screenSize.width
        
        let mapCenterX = mapViewWidth / 2
        let mapCenterY = (mapViewHeight / 2) + 60
        
        let offsetX = screenPoint.x - mapCenterX
        let offsetY = screenPoint.y - mapCenterY
        
        let latitudeOffset = -offsetY * (region.span.latitudeDelta / mapViewHeight)
        let longitudeOffset = offsetX * (region.span.longitudeDelta / mapViewWidth)
        
        let latitude = region.center.latitude + latitudeOffset
        let longitude = region.center.longitude + longitudeOffset
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Map Location Picker
struct MapLocationPicker: View {
    @Binding var coordinates: (latitude: Double, longitude: Double)?
    @Binding var address: String?
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var locationManager = MapLocationManager()
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var isLoading = false
    @State private var showingLocationPermissionAlert = false
    @State private var reverseGeocodedAddress = ""
    @State private var isPinModeEnabled = true

    // Brand colors
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255)
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255)
    @State private var hasCenteredOnUser = false
    
    // Throttling for reverse geocoding
    @State private var lastGeocodeTime: Date = Date.distantPast
    @State private var geocodeWorkItem: DispatchWorkItem?
    private let geocodeThrottleInterval: TimeInterval = 2.0 // 2 seconds between geocoding calls
    
    var body: some View {
        NavigationView {
            ZStack {
                // Real Map View with enhanced interaction
                Map(coordinateRegion: $region, 
                    interactionModes: [.pan, .zoom],
                    showsUserLocation: true,
                    userTrackingMode: .none,
                    annotationItems: selectedCoordinate != nil ? [MapAnnotation(coordinate: selectedCoordinate!)] : []) { annotation in
                    MapPin(coordinate: annotation.coordinate, tint: .red)
                }
                .overlay(
                    // Visual indicator when pin mode is disabled
                    !isPinModeEnabled ? 
                    Color.black.opacity(0.1)
                        .allowsHitTesting(false)
                        .overlay(
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text("Navigation Mode - Drag to explore")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(8)
                                        .padding(.trailing, 16)
                                        .padding(.bottom, 120)
                                }
                            }
                        ) : nil
                )
                .onTapGesture { tapLocation in
                    if isPinModeEnabled {
                        print("🎯 Tap detected at: \(tapLocation)")
                        let coordinate = convertTapToCoordinate(tapLocation: tapLocation)
                        selectedCoordinate = coordinate
                        reverseGeocodedAddress = "Pinned Location"
                    }
                }
                
                // Draggable pin overlay
                if let coordinate = selectedCoordinate {
                    DraggablePinView(
                        coordinate: coordinate,
                        region: region,
                        onCoordinateChanged: { newCoordinate in
                            selectedCoordinate = newCoordinate
                            reverseGeocodedAddress = "Dragged Location"
                        }
                    )
                }
                
                // Control buttons (polished)
                VStack {
                    Spacer()
                    HStack {
                        // Pin mode toggle
                        Button(action: { isPinModeEnabled.toggle() }) {
                            Image(systemName: isPinModeEnabled ? "mappin.circle.fill" : "mappin.circle")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 0.5))
                                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                        }
                        .padding(.leading, 16)

                        Spacer()

                        // Center on user location button
                        Button(action: centerOnUserLocation) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 0.5))
                                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.bottom, 100)
                }
                
                // Instructions overlay
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isPinModeEnabled ? "Pin Mode Active" : "Navigation Mode")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text(isPinModeEnabled ? 
                                 "Tap anywhere on the map to pin a location" : 
                                 "Drag the map to explore different areas, then enable pin mode to select a location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                
                // Selected location info overlay
                if let coord = selectedCoordinate {
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                Text("Selected Location")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            
                            if !reverseGeocodedAddress.isEmpty {
                                Text(reverseGeocodedAddress)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Text("Note: All pinned locations will be reviewed and may be removed if inappropriate")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.leading)
                            
                            HStack {
                                Text("Lat: \(String(format: "%.6f", coord.latitude))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Lng: \(String(format: "%.6f", coord.longitude))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Use These Coordinates") {
                                coordinates = (latitude: coord.latitude, longitude: coord.longitude)
                                address = reverseGeocodedAddress.isEmpty ? "Pinned Location" : reverseGeocodedAddress
                                presentationMode.wrappedValue.dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .shadow(radius: 8)
                        .padding()
                    }
                }
                
                // Loading overlay
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Getting location...")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top)
                    }
                }
            }
            .navigationTitle("Pin Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.fill")
                    }
                    .disabled(locationManager.authorizationStatus != CLAuthorizationStatus.authorizedWhenInUse &&
                              locationManager.authorizationStatus != CLAuthorizationStatus.authorizedAlways)
                }
            }
            .onAppear {
                isLoading = true
                locationManager.requestLocation()
                centerOnUserLocation()
            }
            .onReceive(locationManager.$location) { loc in
                if !hasCenteredOnUser, let loc = loc {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        region.center = loc.coordinate
                        region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    }
                    selectedCoordinate = loc.coordinate
                    reverseGeocodedAddress = "My Current Location"
                    hasCenteredOnUser = true
                    isLoading = false
                }
            }
            .onReceive(locationManager.$authorizationStatus) { status in
                if status == .denied || status == .restricted {
                    isLoading = false
                    showingLocationPermissionAlert = true
                }
            }
            .onDisappear {
                // Cancel any pending geocoding work
                geocodeWorkItem?.cancel()
            }
            .alert("Location Permission Required", isPresented: $showingLocationPermissionAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable location access in Settings to use this feature.")
            }
        }
    }
    
    private func centerOnUserLocation() {
        guard let userLocation = locationManager.location else {
            if locationManager.authorizationStatus == CLAuthorizationStatus.denied || locationManager.authorizationStatus == CLAuthorizationStatus.restricted {
                showingLocationPermissionAlert = true
            }
            return
        }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            region.center = userLocation.coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        }
        
        // Auto-select user's location
        selectedCoordinate = userLocation.coordinate
        reverseGeocodedAddress = "My Current Location"
        hasCenteredOnUser = true
        isLoading = false
    }
    
    private func throttledReverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        // Cancel any pending geocoding work
        geocodeWorkItem?.cancel()
        
        // Check if enough time has passed since last geocoding
        let timeSinceLastGeocode = Date().timeIntervalSince(lastGeocodeTime)
        if timeSinceLastGeocode < geocodeThrottleInterval {
            // Schedule geocoding for later
            let workItem = DispatchWorkItem {
                self.reverseGeocodeCoordinate(coordinate)
            }
            geocodeWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + (geocodeThrottleInterval - timeSinceLastGeocode), execute: workItem)
        } else {
            // Geocode immediately
            reverseGeocodeCoordinate(coordinate)
        }
    }
    
    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        lastGeocodeTime = Date()
        isLoading = true
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("Reverse geocoding error: \(error)")
                    reverseGeocodedAddress = "Unknown Location"
                    return
                }
                
                if let placemark = placemarks?.first {
                    var addressComponents: [String] = []
                    
                    if let name = placemark.name {
                        addressComponents.append(name)
                    }
                    if let thoroughfare = placemark.thoroughfare {
                        addressComponents.append(thoroughfare)
                    }
                    if let locality = placemark.locality {
                        addressComponents.append(locality)
                    }
                    if let administrativeArea = placemark.administrativeArea {
                        addressComponents.append(administrativeArea)
                    }
                    if let country = placemark.country {
                        addressComponents.append(country)
                    }
                    
                    reverseGeocodedAddress = addressComponents.joined(separator: ", ")
                } else {
                    reverseGeocodedAddress = "Unknown Location"
                }
            }
        }
    }
    
    // MARK: - Coordinate Conversion
    
    private func convertTapToCoordinate(tapLocation: CGPoint) -> CLLocationCoordinate2D {
        // Get the screen size (approximate for the map view)
        let screenSize = UIScreen.main.bounds.size
        let mapViewHeight = screenSize.height - 120 // Account for UI elements
        let mapViewWidth = screenSize.width
        
        // Calculate the offset from the center of the map
        let centerX = mapViewWidth / 2
        let centerY = mapViewHeight / 2
        
        let deltaX = tapLocation.x - centerX
        let deltaY = tapLocation.y - centerY
        
        // Convert screen coordinates to map coordinates
        let latitudeOffset = -(deltaY / mapViewHeight) * region.span.latitudeDelta
        let longitudeOffset = (deltaX / mapViewWidth) * region.span.longitudeDelta
        
        let latitude = region.center.latitude + latitudeOffset
        let longitude = region.center.longitude + longitudeOffset
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Map Annotation
struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Map Location Manager
class MapLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.location = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.locationManager.requestLocation()
            }
        }
    }
}

// MARK: - Category Search View
struct CategorySearchView: View {
    @Binding var selectedCategories: [String]
    let selectedColor: Color
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var allCategories: [LocationCategory] = []
    @State private var isLoading = false
    
    var filteredCategories: [LocationCategory] {
        if searchText.isEmpty {
            return allCategories
        } else {
            return allCategories.filter { category in
                category.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search categories...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding()
                
                // Categories List
                if isLoading {
                    Spacer()
                    ProgressView("Loading categories...")
                    Spacer()
                } else {
                    if filteredCategories.isEmpty {
                        VStack {
                            Text("No categories found")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else {
                        List(filteredCategories, id: \.id) { category in
                            Button(action: {
                                toggleCategory(category.id)
                            }) {
                                HStack {
                                    Text(category.name)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedCategories.contains(category.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(selectedColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadCategories()
        }
    }
    
    private func toggleCategory(_ categoryId: String) {
        if selectedCategories.contains(categoryId) {
            selectedCategories.removeAll { $0 == categoryId }
        } else {
            selectedCategories.append(categoryId)
        }
    }
    
    private func loadCategories() {
        isLoading = true
        Task {
            do {
                let categories = await fetchCategoriesFromAPI()
                await MainActor.run {
                    self.allCategories = categories
                    self.isLoading = false
                    print("📱 CategorySearchView loaded \(categories.count) categories from database")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("❌ CategorySearchView failed to load categories: \(error)")
                }
            }
        }
    }
    
    private func fetchCategoriesFromAPI() async -> [LocationCategory] {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/categories") else {
            print("❌ Invalid categories API URL: \(baseAPIURL)/api/mobile/categories")
            return []
        }
        
        print("🔍 Creating location at: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = AuthManager.shared.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 Categories API response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    // Parse the mobile API response format
                    let response = try JSONDecoder().decode(MobileCategoriesResponse.self, from: data)
                    if response.success, let categoriesData = response.data {
                        let categories = categoriesData.categories.map { category in
                            LocationCategory(
                                id: category.id,
                                name: category.name,
                                description: category.description
                            )
                        }
                        print("✅ Successfully parsed \(categories.count) categories")
                        return categories
                    } else {
                        print("❌ API response not successful: \(response.message ?? "Unknown error")")
                    }
                } else {
                    print("❌ Categories API failed with status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ Error response: \(responseString)")
                    }
                }
            }
        } catch {
            print("❌ Error fetching categories: \(error)")
        }
        
        return []
    }
}

