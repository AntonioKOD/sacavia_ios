import SwiftUI
import PhotosUI

// MARK: - Edit Location View
struct EditLocationView: View {
    let locationId: String
    @Environment(\.presentationMode) var presentationMode
    @State private var activeTab = 0 // 0: Basic Info, 1: Details, 2: Contact, 3: Settings
    
    // Brand colors from web design
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    private let backgroundColor = Color(red: 243/255, green: 244/255, blue: 246/255) // #F3F4F6
    private let cardBackground = Color.white
    private let textPrimary = Color(red: 51/255, green: 51/255, blue: 51/255) // #333333
    private let textSecondary = Color(red: 102/255, green: 102/255, blue: 102/255) // #666666
    
    // Location data - will be loaded from API
    @State private var location: LocationDetailData?
    @State private var isLoading = true
    @State private var error: String?
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var saveSuccess = false
    
    // Form data - will be populated from location
    @State private var name = ""
    @State private var slug = ""
    @State private var description = ""
    @State private var shortDescription = ""
    @State private var selectedCategories: [String] = []
    @State private var tags: [String] = []
    @State private var newTag = ""
    
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
    
    // Address data
    @State private var address = AddFormLocationAddress()
    @State private var coordinates = AddFormLocationCoordinates()
    
    // Contact & Business data
    @State private var contactInfo = AddFormContactInfo()
    @State private var businessHours: [AddFormBusinessHour] = []
    @State private var priceRange = ""
    
    // Visitor information
    @State private var bestTimeToVisit: [String] = []
    @State private var insiderTips = ""
    @State private var accessibility = AddFormAccessibilityInfo()
    
    // Settings
    @State private var status = "draft"
    @State private var isFeatured = false
    @State private var isVerified = false
    @State private var hasPartnership = false
    @State private var partnershipDetails = AddFormPartnershipDetails()
    
    // Privacy settings
    @State private var privacy = "public"
    @State private var privateAccess: [String] = []
    
    // SEO metadata
    @State private var meta = AddFormSEOMetadata()
    
    // Categories
    @State private var allCategories: [LocationCategory] = []
    @State private var isLoadingCategories = false
    @State private var categoriesError: String?
    
    // Form validation
    @State private var formErrors: [String: String] = [:]
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(error)
                } else if let location = location {
                    contentView
                }
            }
            .navigationTitle("Edit Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLocation()
                    }
                    .foregroundColor(primaryColor)
                    .disabled(isSaving)
                }
            }
        }
        .onAppear {
            loadLocationData()
            loadCategories()
        }
        .alert("Error", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            if let saveError = saveError {
                Text(saveError)
            }
        }
        .alert("Success", isPresented: $saveSuccess) {
            Button("OK") {
                saveSuccess = false
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Location updated successfully!")
        }
    }
    
    // MARK: - Views
    
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
            Text("Loading location details...")
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
            Spacer()
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("Tab", selection: $activeTab) {
                Text("Basic Info").tag(0)
                Text("Details").tag(1)
                Text("Contact").tag(2)
                Text("Settings").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Tab Content
            TabView(selection: $activeTab) {
                BasicInfoTab()
                    .tag(0)
                
                DetailsTab()
                    .tag(1)
                
                ContactTab()
                    .tag(2)
                
                SettingsTab()
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
    
    // MARK: - Tab Views
    
    @ViewBuilder
    private func BasicInfoTab() -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Name
                FormField(
                    title: "Location Name *",
                    content: TextField("Enter location name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                )
                
                // Slug
                FormField(
                    title: "URL Slug *",
                    content: TextField("url-friendly-name", text: $slug)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                )
                
                // Categories
                FormField(
                    title: "Categories (Select up to 3) *",
                    content: CategorySelector(
                        categories: allCategories,
                        selectedCategories: $selectedCategories,
                        maxSelections: 3
                    )
                )
                
                // Short Description
                FormField(
                    title: "Short Description",
                    content: TextField("Brief one-line description", text: $shortDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                )
                
                // Description
                FormField(
                    title: "Description *",
                    content: TextEditor(text: $description)
                        .frame(minHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Featured Image
                FormField(
                    title: "Featured Image",
                    content: FeaturedImagePicker()
                )
                
                // Tags
                FormField(
                    title: "Tags",
                    content: TagsInput()
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    @ViewBuilder
    private func DetailsTab() -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Address
                FormField(
                    title: "Address",
                    content: AddressForm()
                )
                
                // Price Range
                FormField(
                    title: "Price Range",
                    content: PriceRangePicker()
                )
                
                // Best Time to Visit
                FormField(
                    title: "Best Time to Visit",
                    content: BestTimeToVisitInput()
                )
                
                // Insider Tips
                FormField(
                    title: "Insider Tips",
                    content: TextEditor(text: $insiderTips)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Accessibility
                FormField(
                    title: "Accessibility",
                    content: AccessibilityForm()
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    @ViewBuilder
    private func ContactTab() -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Contact Information
                FormField(
                    title: "Contact Information",
                    content: ContactInfoForm()
                )
                
                // Social Media
                FormField(
                    title: "Social Media",
                    content: SocialMediaForm()
                )
                
                // Business Hours
                FormField(
                    title: "Business Hours",
                    content: BusinessHoursForm()
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    @ViewBuilder
    private func SettingsTab() -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status
                FormField(
                    title: "Status",
                    content: StatusPicker()
                )
                
                // Privacy Settings
                FormField(
                    title: "Privacy Settings",
                    content: PrivacySelector(
                        privacy: $privacy,
                        privateAccess: $privateAccess,
                        userId: "current-user-id", // TODO: Get actual user ID
                        onPrivacyChange: { newPrivacy, newAccess in
                            privacy = newPrivacy
                            privateAccess = newAccess
                        }
                    )
                )
                
                // Flags
                FormField(
                    title: "Settings",
                    content: SettingsFlags()
                )
                
                // Partnership Details
                if hasPartnership {
                    FormField(
                        title: "Partnership Details",
                        content: PartnershipDetailsForm()
                    )
                }
                
                // SEO Meta
                FormField(
                    title: "SEO & Meta",
                    content: SEOMetadataForm()
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func FormField<Content: View>(title: String, content: Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(textPrimary)
            
            content
        }
    }
    
    @ViewBuilder
    private func FeaturedImagePicker() -> some View {
        VStack(spacing: 12) {
            if let featuredImageData = featuredImageData,
               let uiImage = UIImage(data: featuredImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        Button(action: {
                            self.featuredImageData = nil
                            self.featuredImageId = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(8),
                        alignment: .topTrailing
                    )
            } else {
                PhotosPicker(selection: $featuredImageItem, matching: .images) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray)
                                Text("Tap to add featured image")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        )
                }
            }
            
            if featuredImageUploading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Uploading...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            if let error = featuredImageError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .onChange(of: featuredImageItem) { newItem in
            guard let newItem = newItem else { return }
            uploadFeaturedImage(item: newItem)
        }
    }
    
    @ViewBuilder
    private func TagsInput() -> some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Add a tag", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Add") {
                    addTag()
                }
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            if !tags.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                        HStack {
                            Text(tag)
                                .font(.caption)
                            Button(action: { removeTag(at: index) }) {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(secondaryColor.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadLocationData() {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations/\(locationId)") else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header
        if let token = AuthManager.shared.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.error = "No data received"
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(LocationDetailResponse.self, from: data)
                    if response.success, let locationData = response.data {
                        self.location = locationData
                        self.populateFormData(from: locationData)
                    } else {
                        self.error = response.error ?? "Failed to load location"
                    }
                } catch {
                    print("Location detail decoding error:", error)
                    self.error = "Failed to parse location data"
                }
            }
        }.resume()
    }
    
    private func populateFormData(from locationData: LocationDetailData) {
        let loc = locationData.location
        
        // Basic info
        name = loc.name
        slug = loc.slug ?? ""
        description = loc.description ?? ""
        shortDescription = loc.shortDescription ?? ""
        
        // Categories
        if let categories = loc.categories {
            selectedCategories = categories.compactMap { category in
                if let categoryString = category as? String {
                    return categoryString
                } else if let categoryDict = category as? [String: Any],
                          let id = categoryDict["id"] as? String {
                    return id
                }
                return nil
            }
        }
        
        // Tags
        if let tags = loc.tags {
            self.tags = tags.compactMap { tag in
                if let tagString = tag as? String {
                    return tagString
                } else if let tagDict = tag as? [String: Any],
                          let tagValue = tagDict["tag"] as? String {
                    return tagValue
                }
                return nil
            }
        }
        
        // Address
        if let address = loc.address {
            if let addressString = address as? String {
                // Parse string address (basic implementation)
                let components = addressString.components(separatedBy: ", ")
                self.address.street = components.first ?? ""
                self.address.city = components.count > 1 ? components[1] : ""
                self.address.state = components.count > 2 ? components[2] : ""
                self.address.zip = components.count > 3 ? components[3] : ""
            } else if let addressDict = address as? [String: Any] {
                self.address.street = addressDict["street"] as? String ?? ""
                self.address.city = addressDict["city"] as? String ?? ""
                self.address.state = addressDict["state"] as? String ?? ""
                self.address.zip = addressDict["zip"] as? String ?? ""
                self.address.country = addressDict["country"] as? String ?? "USA"
            }
        }
        
        // Contact info
        if let contactInfo = loc.contactInfo {
            self.contactInfo.phone = contactInfo.phone ?? ""
            self.contactInfo.email = contactInfo.email ?? ""
            self.contactInfo.website = contactInfo.website ?? ""
            
            if let socialMedia = contactInfo.socialMedia {
                self.contactInfo.socialMedia.facebook = socialMedia.facebook ?? ""
                self.contactInfo.socialMedia.twitter = socialMedia.twitter ?? ""
                self.contactInfo.socialMedia.instagram = socialMedia.instagram ?? ""
                self.contactInfo.socialMedia.linkedin = socialMedia.linkedin ?? ""
            }
        }
        
        // Business hours
        if let businessHours = loc.businessHours {
            self.businessHours = businessHours.map { hour in
                AddFormBusinessHour(
                    day: hour.day,
                    open: hour.open,
                    close: hour.close,
                    closed: hour.closed ?? false
                )
            }
        } else {
            // Default business hours
            self.businessHours = [
                AddFormBusinessHour(day: "Monday", open: "09:00", close: "17:00", closed: false),
                AddFormBusinessHour(day: "Tuesday", open: "09:00", close: "17:00", closed: false),
                AddFormBusinessHour(day: "Wednesday", open: "09:00", close: "17:00", closed: false),
                AddFormBusinessHour(day: "Thursday", open: "09:00", close: "17:00", closed: false),
                AddFormBusinessHour(day: "Friday", open: "09:00", close: "17:00", closed: false),
                AddFormBusinessHour(day: "Saturday", open: "10:00", close: "15:00", closed: false),
                AddFormBusinessHour(day: "Sunday", open: nil, close: nil, closed: true)
            ]
        }
        
        // Other fields
        priceRange = loc.priceRange ?? ""
        // Convert insider tips array to string (join with newlines)
        if let tips = loc.insiderTips, !tips.isEmpty {
            insiderTips = tips.compactMap { $0.tip }.joined(separator: "\n")
        } else {
            insiderTips = ""
        }
        
        // Accessibility
        if let accessibility = loc.accessibility {
            self.accessibility.wheelchairAccess = accessibility.wheelchairAccess ?? false
            self.accessibility.parking = accessibility.parking ?? false
            self.accessibility.other = accessibility.other ?? ""
        }
        
        // Settings
        status = "draft" // Default status since SearchLocation doesn't have status field
        isFeatured = loc.isFeatured ?? false
        isVerified = loc.isVerified ?? false
        hasPartnership = loc.hasBusinessPartnership ?? false
        
        // Partnership details
        if let partnershipDetails = loc.partnershipDetails {
            self.partnershipDetails.partnerName = partnershipDetails.partnerName ?? ""
            self.partnershipDetails.partnerContact = partnershipDetails.partnerContact ?? ""
            self.partnershipDetails.details = partnershipDetails.details ?? ""
        }
        
        // Privacy settings
        privacy = loc.privacy ?? "public"
        self.privateAccess = loc.privateAccess ?? []
        
        // SEO metadata - SearchLocation doesn't have meta field, so use defaults
        self.meta.title = ""
        self.meta.description = ""
        self.meta.keywords = ""
    }
    
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
                    } else {
                        self.categoriesError = "Failed to parse categories"
                    }
                } catch {
                    self.categoriesError = "Failed to parse response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // MARK: - Actions
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(at index: Int) {
        tags.remove(at: index)
    }
    
    private func uploadFeaturedImage(item: PhotosPickerItem) {
        featuredImageUploading = true
        featuredImageError = nil
        
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data = data {
                        self.featuredImageData = data
                        // Here you would upload to your server and get the image ID
                        // For now, we'll just set a placeholder
                        self.featuredImageId = "uploaded_image_id"
                    }
                case .failure(let error):
                    self.featuredImageError = error.localizedDescription
                }
                self.featuredImageUploading = false
            }
        }
    }
    
    private func validateForm() -> Bool {
        formErrors.removeAll()
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            formErrors["name"] = "Location name is required"
        }
        
        if slug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            formErrors["slug"] = "Slug is required"
        }
        
        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            formErrors["description"] = "Description is required"
        }
        
        if selectedCategories.isEmpty {
            formErrors["categories"] = "At least one category is required"
        }
        
        return formErrors.isEmpty
    }
    
    private func saveLocation() {
        guard validateForm() else {
            // Show validation errors
            return
        }
        
        isSaving = true
        saveError = nil
        
        // Create location data for API
        let locationData: [String: Any] = [
            "name": name,
            "slug": slug,
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
            "contactInfo": [
                "phone": contactInfo.phone,
                "email": contactInfo.email,
                "website": contactInfo.website,
                "socialMedia": [
                    "facebook": contactInfo.socialMedia.facebook,
                    "twitter": contactInfo.socialMedia.twitter,
                    "instagram": contactInfo.socialMedia.instagram,
                    "linkedin": contactInfo.socialMedia.linkedin
                ]
            ],
            "businessHours": businessHours.map { hour in
                [
                    "day": hour.day,
                    "open": hour.open ?? "",
                    "close": hour.close ?? "",
                    "closed": hour.closed
                ]
            },
            "priceRange": priceRange,
            "insiderTips": insiderTips,
            "accessibility": [
                "wheelchairAccess": accessibility.wheelchairAccess,
                "parking": accessibility.parking,
                "other": accessibility.other
            ],
            "status": status,
            "isFeatured": isFeatured,
            "isVerified": isVerified,
            "hasBusinessPartnership": hasPartnership,
            "partnershipDetails": hasPartnership ? [
                "partnerName": partnershipDetails.partnerName,
                "partnerContact": partnershipDetails.partnerContact,
                "details": partnershipDetails.details
            ] : nil,
            "meta": [
                "title": meta.title,
                "description": meta.description,
                "keywords": meta.keywords
            ],
            "privacy": privacy,
            "privateAccess": privateAccess
        ]
        
        Task {
            do {
                let success = await updateLocationAPI(locationData: locationData)
                await MainActor.run {
                    isSaving = false
                    if success {
                        saveSuccess = true
                    } else {
                        saveError = "Failed to update location. Please try again."
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func updateLocationAPI(locationData: [String: Any]) async -> Bool {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations/\(locationId)/edit") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: locationData)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 Update location status: \(httpResponse.statusCode)")
                return httpResponse.statusCode == 200 || httpResponse.statusCode == 201
            }
            
            return false
        } catch {
            print("📱 Error updating location: \(error)")
            return false
        }
    }
}

// MARK: - Supporting Data Structures

struct AddFormPartnershipDetails {
    var partnerName: String = ""
    var partnerContact: String = ""
    var details: String = ""
}

struct AddFormSEOMetadata {
    var title: String = ""
    var description: String = ""
    var keywords: String = ""
}

// MARK: - Supporting Views (Placeholder implementations)

struct CategorySelector: View {
    let categories: [LocationCategory]
    @Binding var selectedCategories: [String]
    let maxSelections: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(categories) { category in
                HStack {
                    Button(action: {
                        toggleCategory(category.id)
                    }) {
                        HStack {
                            Image(systemName: selectedCategories.contains(category.id) ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedCategories.contains(category.id) ? .blue : .gray)
                            Text(category.name)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    .disabled(!selectedCategories.contains(category.id) && selectedCategories.count >= maxSelections)
                }
            }
        }
    }
    
    private func toggleCategory(_ categoryId: String) {
        if selectedCategories.contains(categoryId) {
            selectedCategories.removeAll { $0 == categoryId }
        } else if selectedCategories.count < maxSelections {
            selectedCategories.append(categoryId)
        }
    }
}

struct AddressForm: View {
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var country = "USA"
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Street Address", text: $street)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                TextField("City", text: $city)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("State", text: $state)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack {
                TextField("ZIP Code", text: $zip)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Country", text: $country)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
}

struct PriceRangePicker: View {
    @State private var selectedPriceRange = ""
    
    let priceRanges = ["Free", "Budget ($)", "Moderate ($$)", "Expensive ($$$)", "Luxury ($$$$)"]
    
    var body: some View {
        Picker("Price Range", selection: $selectedPriceRange) {
            Text("Select price range").tag("")
            ForEach(priceRanges, id: \.self) { range in
                Text(range).tag(range)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
}

struct BestTimeToVisitInput: View {
    @State private var newSeason = ""
    @State private var seasons: [String] = []
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("e.g., Spring, Summer", text: $newSeason)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Add") {
                    addSeason()
                }
                .disabled(newSeason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            if !seasons.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(Array(seasons.enumerated()), id: \.offset) { index, season in
                        HStack {
                            Text(season)
                                .font(.caption)
                            Button(action: { removeSeason(at: index) }) {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private func addSeason() {
        let trimmedSeason = newSeason.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSeason.isEmpty && !seasons.contains(trimmedSeason) {
            seasons.append(trimmedSeason)
            newSeason = ""
        }
    }
    
    private func removeSeason(at index: Int) {
        seasons.remove(at: index)
    }
}

struct AccessibilityForm: View {
    @State private var wheelchairAccess = false
    @State private var parking = false
    @State private var other = ""
    
    var body: some View {
        VStack(spacing: 12) {
            Toggle("Wheelchair Accessible", isOn: $wheelchairAccess)
            Toggle("Parking Available", isOn: $parking)
            
            TextField("Other accessibility features", text: $other, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
}

struct ContactInfoForm: View {
    @State private var phone = ""
    @State private var email = ""
    @State private var website = ""
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Phone", text: $phone)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
            
            TextField("Website", text: $website)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.URL)
        }
    }
}

struct SocialMediaForm: View {
    @State private var facebook = ""
    @State private var twitter = ""
    @State private var instagram = ""
    @State private var linkedin = ""
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Facebook URL", text: $facebook)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.URL)
            
            TextField("Twitter URL", text: $twitter)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.URL)
            
            TextField("Instagram URL", text: $instagram)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.URL)
            
            TextField("LinkedIn URL", text: $linkedin)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.URL)
        }
    }
}

struct BusinessHoursForm: View {
    @State private var businessHours: [AddFormBusinessHour] = [
        AddFormBusinessHour(day: "Monday", open: "09:00", close: "17:00", closed: false),
        AddFormBusinessHour(day: "Tuesday", open: "09:00", close: "17:00", closed: false),
        AddFormBusinessHour(day: "Wednesday", open: "09:00", close: "17:00", closed: false),
        AddFormBusinessHour(day: "Thursday", open: "09:00", close: "17:00", closed: false),
        AddFormBusinessHour(day: "Friday", open: "09:00", close: "17:00", closed: false),
        AddFormBusinessHour(day: "Saturday", open: "10:00", close: "15:00", closed: false),
        AddFormBusinessHour(day: "Sunday", open: nil, close: nil, closed: true)
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(businessHours.enumerated()), id: \.offset) { index, hour in
                HStack {
                    Text(hour.day)
                        .frame(width: 80, alignment: .leading)
                        .font(.system(size: 14, weight: .medium))
                    
                    Toggle("Open", isOn: Binding(
                        get: { !hour.closed },
                        set: { businessHours[index].closed = !$0 }
                    ))
                    
                    if !hour.closed {
                        HStack {
                            TextField("Open", text: Binding(
                                get: { hour.open ?? "" },
                                set: { businessHours[index].open = $0 }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            
                            Text("to")
                                .font(.caption)
                            
                            TextField("Close", text: Binding(
                                get: { hour.close ?? "" },
                                set: { businessHours[index].close = $0 }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        }
                    } else {
                        Text("Closed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct StatusPicker: View {
    @State private var selectedStatus = "draft"
    
    let statuses = ["draft", "review", "published", "archived"]
    
    var body: some View {
        Picker("Status", selection: $selectedStatus) {
            ForEach(statuses, id: \.self) { status in
                Text(status.capitalized).tag(status)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
}

struct SettingsFlags: View {
    @State private var isFeatured = false
    @State private var isVerified = false
    @State private var hasPartnership = false
    
    var body: some View {
        VStack(spacing: 12) {
            Toggle("Featured Location", isOn: $isFeatured)
            Toggle("Verified Location", isOn: $isVerified)
            Toggle("Has Business Partnership", isOn: $hasPartnership)
        }
    }
}

struct PartnershipDetailsForm: View {
    @State private var partnerName = ""
    @State private var partnerContact = ""
    @State private var details = ""
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Partner Name", text: $partnerName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Partner Contact", text: $partnerContact)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
            
            TextField("Partnership Details", text: $details, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
}

struct SEOMetadataForm: View {
    @State private var title = ""
    @State private var description = ""
    @State private var keywords = ""
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Meta Title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Meta Description", text: $description, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
            
            TextField("Keywords", text: $keywords)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

#Preview {
    EditLocationView(locationId: "sample-location-id")
}
