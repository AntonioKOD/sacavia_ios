import SwiftUI
import PhotosUI

// Safe array access extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct EnhancedAddLocationView: View {
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
    @State private var featuredImageUploading: Bool = false
    @State private var featuredImageError: String? = nil
    @State private var galleryItems: [PhotosPickerItem] = []
    @State private var galleryImagesData: [Data] = []
    @State private var galleryImageIds: [String] = []
    @State private var galleryUploading: [Bool] = []
    @State private var galleryErrors: [String?] = []
    @State private var galleryCaptions: [String] = []
    @State private var tempGallerySelection: PhotosPickerItem?
    
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
    
    // State management
    @State private var isLoading = false
    @State private var error: String?
    @State private var allCategories: [LocationCategory] = []
    @State private var isLoadingCategories = false
    @State private var categoriesError: String?
    
    // Computed properties
    private var autoSlug: String {
        name.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Progress Indicator
                progressView
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        stepContent
                        
                        // Navigation Buttons
                        navigationButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadCategories()
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            if let error = error {
                Text(error)
            }
        }
        .overlay(loadingOverlay)
    }
    
    // MARK: - Computed Views
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryColor)
                        .padding(8)
                        .background(Circle().fill(primaryColor.opacity(0.1)))
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Add Location")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(textPrimary)
                    Text("Share amazing places with the community")
                        .font(.caption)
                        .foregroundColor(textSecondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(primaryColor)
                        .padding(8)
                        .background(Circle().fill(primaryColor.opacity(0.1)))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [cardBackground, backgroundColor],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var progressView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<8, id: \.self) { index in
                    Rectangle()
                        .fill(index <= step ? primaryColor : Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                }
            }
            .padding(.horizontal, 20)
            
            Text("Step \(step + 1) of 8")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(textSecondary)
        }
        .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: basicInfoStep
        case 1: mediaStep
        case 2: addressStep
        case 3: contactBusinessStep
        case 4: visitorInfoStep
        case 5: privacyStep
        case 6: settingsStep
        case 7: reviewSubmitStep
        default: EmptyView()
        }
    }
    
    private var loadingOverlay: some View {
        Group {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Creating location...")
                            .font(.headline)
                            .foregroundColor(textPrimary)
                    }
                    .padding(24)
                    .background(cardBackground)
                    .cornerRadius(16)
                }
            }
        }
    }
    
    // MARK: - Step Views
    
    private var basicInfoStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                stepNumber: "1",
                title: "Basic Information",
                subtitle: "Tell us about your location"
            )
            
            VStack(spacing: 20) {
                EnhancedTextField(
                    title: "Location Name",
                    placeholder: "Enter location name",
                    text: $name,
                    isRequired: true
                )
                .onChange(of: name) { _, newValue in
                    if slug.isEmpty {
                        slug = autoSlug
                    }
                }
                
                EnhancedTextField(
                    title: "URL Slug",
                    placeholder: "location-slug",
                    text: $slug,
                    isRequired: true
                )
                
                EnhancedTextField(
                    title: "Short Description",
                    placeholder: "Brief description for previews",
                    text: $shortDescription
                )
                
                EnhancedTextEditor(
                    title: "Description",
                    placeholder: "Detailed description of the location",
                    text: $description,
                    height: 120
                )
                
                categoriesSection
                tagsSection
            }
        }
    }
    
    private var mediaStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                stepNumber: "2",
                title: "Media",
                subtitle: "Add photos to showcase your location"
            )
            
            VStack(spacing: 20) {
                featuredImageSection
                
                // Gallery section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gallery Photos (Optional)")
                        .fontWeight(.semibold)
                        .foregroundColor(textPrimary)
                    
                    Text("Add up to 5 additional photos to showcase your location")
                        .font(.caption)
                        .foregroundColor(textSecondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Add Photo Button
                            if galleryItems.count < 5 {
                                PhotosPicker(selection: $tempGallerySelection, matching: .images) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .foregroundColor(primaryColor)
                                        Text("Add Photo")
                                            .font(.caption)
                                            .foregroundColor(primaryColor)
                                    }
                                    .frame(width: 100, height: 100)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(primaryColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                                    )
                                }
                            }
                            
                            // Display gallery images
                            ForEach(galleryImagesData.indices, id: \.self) { index in
                                if let imageData = galleryImagesData[safe: index],
                                   let uiImage = UIImage(data: imageData) {
                                    ZStack {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipped()
                                            .cornerRadius(12)
                                        
                                        // Upload progress overlay
                                        if index < galleryUploading.count && galleryUploading[index] {
                                            Color.black.opacity(0.5)
                                                .cornerRadius(12)
                                            
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        }
                                        
                                        // Success indicator
                                        if index < galleryImageIds.count && 
                                           !galleryImageIds[index].isEmpty && 
                                           index < galleryUploading.count && 
                                           !galleryUploading[index] {
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.caption)
                                                        .foregroundColor(.green)
                                                    Spacer()
                                                }
                                                .padding(4)
                                            }
                                        }
                                        
                                        // Error indicator
                                        if index < galleryErrors.count, 
                                           let error = galleryErrors[index], 
                                           !error.isEmpty {
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Image(systemName: "exclamationmark.triangle.fill")
                                                        .font(.caption)
                                                        .foregroundColor(.red)
                                                    Spacer()
                                                }
                                                .padding(4)
                                            }
                                        }
                                        
                                        // Remove button
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Button(action: {
                                                    // Remove from all arrays
                                                    if index < galleryItems.count {
                                                        galleryItems.remove(at: index)
                                                    }
                                                    if index < galleryImagesData.count {
                                                        galleryImagesData.remove(at: index)
                                                    }
                                                    if index < galleryImageIds.count {
                                                        galleryImageIds.remove(at: index)
                                                    }
                                                    if index < galleryUploading.count {
                                                        galleryUploading.remove(at: index)
                                                    }
                                                    if index < galleryErrors.count {
                                                        galleryErrors.remove(at: index)
                                                    }
                                                    if index < galleryCaptions.count {
                                                        galleryCaptions.remove(at: index)
                                                    }
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.caption)
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.6))
                                                        .clipShape(Circle())
                                                }
                                                .padding(4)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .onChange(of: tempGallerySelection) { _, newItem in
                    if let newItem = newItem {
                        galleryItems.append(newItem)
                        // Load image data and upload
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    galleryImagesData.append(data)
                                    galleryImageIds.append("") // Placeholder for image ID
                                    galleryUploading.append(false)
                                    galleryErrors.append(nil)
                                    galleryCaptions.append("") // Add empty caption placeholder
                                    tempGallerySelection = nil // Reset selection
                                    
                                    // Upload the gallery image
                                    let index = galleryImagesData.count - 1
                                    uploadGalleryImage(data: data, index: index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var addressStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                stepNumber: "3",
                title: "Address",
                subtitle: "Where is your location?"
            )
            
            VStack(spacing: 16) {
                EnhancedTextField(
                    title: "Street Address",
                    placeholder: "123 Main St",
                    text: $address.street,
                    isRequired: true
                )
                
                HStack(spacing: 12) {
                    EnhancedTextField(
                        title: "City",
                        placeholder: "City",
                        text: $address.city,
                        isRequired: true
                    )
                    
                    EnhancedTextField(
                        title: "State",
                        placeholder: "State",
                        text: $address.state,
                        isRequired: true
                    )
                }
                
                HStack(spacing: 12) {
                    EnhancedTextField(
                        title: "ZIP Code",
                        placeholder: "12345",
                        text: $address.zip
                    )
                    
                    EnhancedTextField(
                        title: "Country",
                        placeholder: "Country",
                        text: $address.country,
                        isRequired: true
                    )
                }
                
                EnhancedTextField(
                    title: "Neighborhood",
                    placeholder: "Optional neighborhood",
                    text: $address.neighborhood
                )
            }
        }
    }
    
    private var contactBusinessStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                stepNumber: "4",
                title: "Contact & Business",
                subtitle: "How can people reach you?"
            )
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Contact Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(textPrimary)
                    
                    EnhancedTextField(
                        title: "Phone",
                        placeholder: "+1 (555) 123-4567",
                        text: $contactInfo.phone
                    )
                    
                    EnhancedTextField(
                        title: "Email",
                        placeholder: "contact@location.com",
                        text: $contactInfo.email
                    )
                    
                    EnhancedTextField(
                        title: "Website",
                        placeholder: "https://website.com",
                        text: $contactInfo.website
                    )
                }
                
                socialMediaSection
                businessInfoSection
            }
        }
    }
    
    private var visitorInfoStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                stepNumber: "5",
                title: "Visitor Information",
                subtitle: "Help visitors plan their visit"
            )
            
            VStack(spacing: 20) {
                bestTimeSection
                
                EnhancedTextEditor(
                    title: "Insider Tips",
                    placeholder: "Share helpful tips for visitors...",
                    text: $insiderTips,
                    height: 100
                )
                
                accessibilitySection
            }
        }
    }
    
    private var privacyStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                stepNumber: "6",
                title: "Privacy",
                subtitle: "Who can see your location?"
            )
            
            VStack(spacing: 20) {
                privacyOptions
                
                if privacy == "private" {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Private Access")
                            .fontWeight(.semibold)
                            .foregroundColor(textPrimary)
                        
                        Text("This location will only be visible to you and people you invite.")
                            .font(.caption)
                            .foregroundColor(textSecondary)
                        
                        Text("Note: Private location sharing features will be available in a future update.")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var settingsStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                stepNumber: "7",
                title: "Settings",
                subtitle: "Additional options"
            )
            
            VStack(spacing: 20) {
                locationSettings
            }
        }
    }
    
    private var reviewSubmitStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                stepNumber: "8",
                title: "Review & Submit",
                subtitle: "Review your location before submitting"
            )
            
            VStack(alignment: .leading, spacing: 16) {
                ReviewSection(title: "Basic Information") {
                    ReviewRow(label: "Name", value: name)
                    ReviewRow(label: "Description", value: shortDescription.isEmpty ? "None" : shortDescription)
                    ReviewRow(label: "Categories", value: "\(selectedCategories.count) selected")
                }
                
                ReviewSection(title: "Address") {
                    let fullAddress = [address.street, address.city, address.state, address.zip]
                        .filter { !$0.isEmpty }
                        .joined(separator: ", ")
                    ReviewRow(label: "Address", value: fullAddress.isEmpty ? "Not provided" : fullAddress)
                }
                
                ReviewSection(title: "Contact") {
                    ReviewRow(label: "Phone", value: contactInfo.phone.isEmpty ? "Not provided" : contactInfo.phone)
                    ReviewRow(label: "Email", value: contactInfo.email.isEmpty ? "Not provided" : contactInfo.email)
                    ReviewRow(label: "Website", value: contactInfo.website.isEmpty ? "Not provided" : contactInfo.website)
                }
                
                ReviewSection(title: "Settings") {
                    ReviewRow(label: "Privacy", value: privacy.capitalized)
                    ReviewRow(label: "Featured", value: isFeatured ? "Yes" : "No")
                    ReviewRow(label: "Verified", value: isVerified ? "Yes" : "No")
                }
            }
        }
    }
    
    // MARK: - Helper Views and Sections
    
    private func stepHeader(stepNumber: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step \(stepNumber)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(primaryColor.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(textPrimary)
                }
                
                Spacer()
                
                Text("\(stepNumber)/8")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(primaryColor)
                    .cornerRadius(12)
            }
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if step > 0 {
                Button(action: { step -= 1 }) {
                    Text("Back")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(backgroundColor)
                        .foregroundColor(primaryColor)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(primaryColor.opacity(0.3), lineWidth: 1.5)
                        )
                }
            }
            
            Spacer()
            
            Button(action: nextAction) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if step == 7 && (featuredImageUploading || galleryUploading.contains(true)) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    if step == 7 && (featuredImageUploading || galleryUploading.contains(true)) {
                        Text("Uploading Images...")
                    } else if step == 7 && isLoading {
                        Text("Creating Location...")
                    } else {
                        Text(step == 7 ? "Submit" : "Next")
                    }
                }
                .fontWeight(.bold)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    step == 7 && (featuredImageUploading || galleryUploading.contains(true)) ?
                        LinearGradient(colors: [Color.gray, Color.gray], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(
                            colors: [primaryColor, accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: primaryColor.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .disabled(isLoading || !canProceed || (step == 7 && (featuredImageUploading || galleryUploading.contains(true))))
        }
    }
    
    // MARK: - Section implementations (simplified for now)
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Categories")
                    .fontWeight(.semibold)
                    .foregroundColor(textPrimary)
                Text("(Select up to 3)")
                    .font(.caption)
                    .foregroundColor(textSecondary)
            }
            
            if isLoadingCategories {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let categoriesError = categoriesError {
                Text("Error loading categories: \(categoriesError)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allCategories.prefix(10), id: \.id) { category in
                            Button(action: {
                                if selectedCategories.contains(category.id) {
                                    selectedCategories.removeAll { $0 == category.id }
                                } else if selectedCategories.count < 3 {
                                    selectedCategories.append(category.id)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: selectedCategories.contains(category.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.caption)
                                    Text(category.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    selectedCategories.contains(category.id) 
                                        ? primaryColor.opacity(0.1) 
                                        : Color.gray.opacity(0.1)
                                )
                                .foregroundColor(
                                    selectedCategories.contains(category.id) 
                                        ? primaryColor 
                                        : textSecondary
                                )
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            selectedCategories.contains(category.id) 
                                                ? primaryColor 
                                                : Color.gray.opacity(0.3), 
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                if selectedCategories.count > 0 {
                    Text("Selected: \(selectedCategories.count)/3")
                        .font(.caption)
                        .foregroundColor(textSecondary)
                }
            }
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .fontWeight(.semibold)
                .foregroundColor(textPrimary)
            
            HStack {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Add") {
                    if !newTag.isEmpty {
                        tags.append(newTag)
                        newTag = ""
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(primaryColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            if !tags.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(tags.indices, id: \.self) { index in
                        HStack {
                            Text(tags[index])
                                .font(.caption)
                                .lineLimit(1)
                            Button("×") {
                                tags.remove(at: index)
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(secondaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                }
            }
        }
    }
    
    private var featuredImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Image")
                .fontWeight(.semibold)
                .foregroundColor(textPrimary)
            
            if let featuredImageData = featuredImageData, let uiImage = UIImage(data: featuredImageData) {
                ZStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                    
                    // Upload progress overlay
                    if featuredImageUploading {
                        Color.black.opacity(0.5)
                            .cornerRadius(12)
                        
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Uploading...")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Success indicator
                    if !featuredImageId.isEmpty && !featuredImageUploading {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Uploaded")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                        }
                    }
                    
                    // Error indicator
                    if let error = featuredImageError {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Upload failed")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                        }
                    }
                    
                    // Remove button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                self.featuredImageItem = nil
                                self.featuredImageData = nil
                                self.featuredImageId = ""
                                self.featuredImageError = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                        Spacer()
                    }
                }
            } else {
                PhotosPicker(selection: $featuredImageItem, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32))
                            .foregroundColor(primaryColor)
                        Text("Add Featured Image")
                            .font(.headline)
                            .foregroundColor(primaryColor)
                        Text("This will be the main image for your location")
                            .font(.caption)
                            .foregroundColor(textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(primaryColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
                .onChange(of: featuredImageItem) { _, newItem in
                    Task {
                        if let newItem = newItem {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    self.featuredImageData = data
                                    // Upload the image and get the ID
                                    self.uploadFeaturedImage(data: data)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var socialMediaSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Social Media (Optional)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(textPrimary)
            
            VStack(spacing: 12) {
                EnhancedTextField(
                    title: "Facebook",
                    placeholder: "facebook.com/yourpage",
                    text: $contactInfo.socialMedia.facebook
                )
                
                EnhancedTextField(
                    title: "Instagram",
                    placeholder: "@yourusername",
                    text: $contactInfo.socialMedia.instagram
                )
                
                EnhancedTextField(
                    title: "Twitter",
                    placeholder: "@yourusername",
                    text: $contactInfo.socialMedia.twitter
                )
                
                EnhancedTextField(
                    title: "LinkedIn",
                    placeholder: "linkedin.com/company/yourcompany",
                    text: $contactInfo.socialMedia.linkedin
                )
            }
        }
    }
    
    private var businessInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Business Information")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(textPrimary)
            
            // Price Range Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Price Range")
                    .fontWeight(.semibold)
                    .foregroundColor(textPrimary)
                
                HStack(spacing: 12) {
                    ForEach([
                        ("Free", "free"),
                        ("$", "budget"), 
                        ("$$", "moderate"), 
                        ("$$$", "expensive"), 
                        ("$$$$", "luxury")
                    ], id: \.0) { (display, value) in
                        Button(action: {
                            priceRange = value
                        }) {
                            Text(display)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    priceRange == value 
                                        ? primaryColor 
                                        : Color.gray.opacity(0.1)
                                )
                                .foregroundColor(
                                    priceRange == value 
                                        ? .white 
                                        : textSecondary
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                }
            }
            
            // Business Hours Section
            businessHoursSection
        }
    }
    
    private var businessHoursSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Business Hours")
                .fontWeight(.semibold)
                .foregroundColor(textPrimary)
            
            VStack(spacing: 8) {
                ForEach(businessHours.indices, id: \.self) { index in
                    HStack {
                        Text(businessHours[index].day)
                            .frame(width: 80, alignment: .leading)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        if businessHours[index].closed {
                            Text("Closed")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            HStack(spacing: 4) {
                                TextField("09:00", text: Binding(
                                    get: { businessHours[index].open ?? "" },
                                    set: { businessHours[index].open = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 60)
                                
                                Text("to")
                                    .font(.caption)
                                    .foregroundColor(textSecondary)
                                
                                TextField("17:00", text: Binding(
                                    get: { businessHours[index].close ?? "" },
                                    set: { businessHours[index].close = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 60)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            businessHours[index].closed.toggle()
                            if businessHours[index].closed {
                                businessHours[index].open = nil
                                businessHours[index].close = nil
                            } else {
                                businessHours[index].open = "09:00"
                                businessHours[index].close = "17:00"
                            }
                        }) {
                            Text(businessHours[index].closed ? "Open" : "Close")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(businessHours[index].closed ? primaryColor : Color.gray.opacity(0.2))
                                .foregroundColor(businessHours[index].closed ? .white : textPrimary)
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    private var bestTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Time to Visit")
                .fontWeight(.semibold)
                .foregroundColor(textPrimary)
            
            VStack(spacing: 8) {
                ForEach(["Spring", "Summer", "Fall", "Winter"], id: \.self) { season in
                    HStack {
                        Button(action: {
                            if bestTimeToVisit.contains(season) {
                                bestTimeToVisit.removeAll { $0 == season }
                            } else {
                                bestTimeToVisit.append(season)
                            }
                        }) {
                            HStack {
                                Image(systemName: bestTimeToVisit.contains(season) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(bestTimeToVisit.contains(season) ? primaryColor : Color.gray)
                                Text(season)
                                    .foregroundColor(textPrimary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accessibility")
                .fontWeight(.semibold)
                .foregroundColor(textPrimary)
            
            VStack(spacing: 8) {
                HStack {
                    Toggle("Wheelchair Accessible", isOn: $accessibility.wheelchairAccess)
                    Spacer()
                }
                
                HStack {
                    Toggle("Parking Available", isOn: $accessibility.parking)
                    Spacer()
                }
                
                EnhancedTextField(
                    title: "Other Features",
                    placeholder: "Other accessibility features",
                    text: $accessibility.other
                )
            }
        }
    }
    
    private var privacyOptions: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack {
                    Button(action: { privacy = "public" }) {
                        HStack {
                            Image(systemName: privacy == "public" ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(privacy == "public" ? primaryColor : Color.gray)
                            VStack(alignment: .leading) {
                                Text("Public")
                                    .fontWeight(.semibold)
                                    .foregroundColor(textPrimary)
                                Text("Anyone can see and visit your location")
                                    .font(.caption)
                                    .foregroundColor(textSecondary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                
                HStack {
                    Button(action: { privacy = "private" }) {
                        HStack {
                            Image(systemName: privacy == "private" ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(privacy == "private" ? primaryColor : Color.gray)
                            VStack(alignment: .leading) {
                                Text("Private")
                                    .fontWeight(.semibold)
                                    .foregroundColor(textPrimary)
                                Text("Only you and invited users can see it")
                                    .font(.caption)
                                    .foregroundColor(textSecondary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
            }
        }
    }
    
    private var locationSettings: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    Toggle("Featured Location", isOn: $isFeatured)
                    Spacer()
                    Text("Promote your location")
                        .font(.caption)
                        .foregroundColor(textSecondary)
                }
                
                HStack {
                    Toggle("Verified Location", isOn: $isVerified)
                    Spacer()
                    Text("Mark as verified")
                        .font(.caption)
                        .foregroundColor(textSecondary)
                }
            }
        }
    }
    
    // MARK: - Actions and Logic
    
    private var canProceed: Bool {
        switch step {
        case 0:
            return !name.isEmpty && !slug.isEmpty
        case 2:
            return !address.street.isEmpty && !address.city.isEmpty && !address.state.isEmpty
        default:
            return true
        }
    }
    
    private func nextAction() {
        if step == 7 {
            submitLocation()
        } else {
            step += 1
        }
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
                        
                        print("📱 EnhancedAddLocationView: Loaded \(self.allCategories.count) categories")
                    } else {
                        self.categoriesError = "Failed to parse categories"
                    }
                } catch {
                    self.categoriesError = "Failed to parse response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // MARK: - Image Upload Functions
    
    private func uploadFeaturedImage(data: Data) {
        featuredImageUploading = true
        featuredImageError = nil
        
        Task {
            do {
                let imageId = await uploadImageToAPI(imageData: data, filename: "featured-image.jpg")
                await MainActor.run {
                    featuredImageUploading = false
                    if let imageId = imageId {
                        featuredImageId = imageId
                        print("📱 Featured image uploaded successfully: \(imageId)")
                    } else {
                        featuredImageError = "Failed to upload featured image"
                    }
                }
            } catch {
                await MainActor.run {
                    featuredImageUploading = false
                    featuredImageError = "Upload error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func uploadGalleryImage(data: Data, index: Int) {
        guard index < galleryUploading.count else { return }
        
        galleryUploading[index] = true
        galleryErrors[index] = nil
        
        Task {
            do {
                let imageId = await uploadImageToAPI(imageData: data, filename: "gallery-image-\(index).jpg")
                await MainActor.run {
                    if index < galleryUploading.count {
                        galleryUploading[index] = false
                        if let imageId = imageId {
                            galleryImageIds[index] = imageId
                            print("📱 Gallery image \(index) uploaded successfully: \(imageId)")
                        } else {
                            galleryErrors[index] = "Failed to upload image"
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    if index < galleryUploading.count {
                        galleryUploading[index] = false
                        galleryErrors[index] = "Upload error: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func uploadImageToAPI(imageData: Data, filename: String) async -> String? {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/upload/image") else {
            print("📱 Invalid media upload URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add authentication
        if let token = AuthManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 Media upload status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    // Parse response to get media ID from mobile upload endpoint
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = json["success"] as? Bool,
                       success,
                       let dataDict = json["data"] as? [String: Any],
                       let mediaId = dataDict["id"] as? String {
                        print("📱 Media upload successful: \(mediaId)")
                        return mediaId
                    } else {
                        let responseString = String(data: data, encoding: .utf8)
                        print("📱 Media upload success but failed to parse: \(responseString ?? "No response")")
                    }
                } else {
                    let responseString = String(data: data, encoding: .utf8)
                    print("📱 Media upload error response: \(responseString ?? "No response")")
                }
            }
            
            return nil
        } catch {
            print("📱 Media upload error: \(error)")
            return nil
        }
    }
    
    private func submitLocation() {
        // Check if any images are still uploading
        if featuredImageUploading || galleryUploading.contains(true) {
            error = "Please wait for all images to finish uploading before submitting."
            return
        }
        
        isLoading = true
        error = nil
        
        // Create comprehensive location data for API
        let locationData: [String: Any] = [
            "name": name,
            "slug": slug.isEmpty ? autoSlug : slug,
            "description": description,
            "shortDescription": shortDescription,
            "categories": selectedCategories,
            "tags": tags.map { tag in ["tag": tag] }, // Fix tags format for backend
            "featuredImage": featuredImageId.isEmpty ? nil : featuredImageId,
            "gallery": galleryImageIds.enumerated().compactMap { (index, imageId) -> [String: Any]? in
                guard !imageId.isEmpty else { return nil }
                return [
                    "image": imageId,
                    "caption": index < galleryCaptions.count ? galleryCaptions[index] : ""
                ]
            },
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
                    "open": hour.closed ? nil : (hour.open?.isEmpty == false ? hour.open : nil),
                    "close": hour.closed ? nil : (hour.close?.isEmpty == false ? hour.close : nil),
                    "closed": hour.closed
                ]
            },
            "priceRange": priceRange.isEmpty ? nil : priceRange,
            "bestTimeToVisit": bestTimeToVisit.map { season in ["season": season] },
            "insiderTips": insiderTips.isEmpty ? [] : [
                [
                    "category": "protips",
                    "tip": insiderTips,
                    "priority": "medium",
                    "isVerified": false,
                    "source": "user_submitted",
                    "status": "pending"
                ]
            ],
            "accessibility": [
                "wheelchairAccess": accessibility.wheelchairAccess,
                "parking": accessibility.parking,
                "other": accessibility.other.isEmpty ? nil : accessibility.other
            ],
            "privacy": privacy,
            "privateAccess": privacy == "private" ? privateAccess : [],
            "isFeatured": isFeatured,
            "isVerified": isVerified,
            "hasBusinessPartnership": false // Set default value
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
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    return true
                } else {
                    let responseString = String(data: data, encoding: .utf8)
                    print("📱 Create location error: \(responseString ?? "No response")")
                }
            }
            
            return false
        } catch {
            print("📱 Error creating location: \(error)")
            return false
        }
    }
}

// MARK: - Enhanced Components

struct EnhancedTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let isRequired: Bool
    
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255)
    private let textPrimary = Color(red: 51/255, green: 51/255, blue: 51/255)
    private let backgroundColor = Color(red: 243/255, green: 244/255, blue: 246/255)
    
    init(title: String, placeholder: String, text: Binding<String>, isRequired: Bool = false) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isRequired = isRequired
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(textPrimary)
                if isRequired {
                    Text("*")
                        .foregroundColor(primaryColor)
                }
            }
            
            TextField(placeholder, text: $text)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(backgroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(primaryColor.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct EnhancedTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let height: CGFloat
    
    private let textPrimary = Color(red: 51/255, green: 51/255, blue: 51/255)
    private let backgroundColor = Color(red: 243/255, green: 244/255, blue: 246/255)
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(textPrimary)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                
                TextEditor(text: $text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(backgroundColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(primaryColor.opacity(0.3), lineWidth: 1)
                    )
            }
            .frame(height: height)
        }
    }
}

struct ReviewSection<Content: View>: View {
    let title: String
    let content: Content
    
    private let textPrimary = Color(red: 51/255, green: 51/255, blue: 51/255)
    private let cardBackground = Color.white
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(textPrimary)
            
            content
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ReviewRow: View {
    let label: String
    let value: String
    
    private let textPrimary = Color(red: 51/255, green: 51/255, blue: 51/255)
    private let textSecondary = Color(red: 102/255, green: 102/255, blue: 102/255)
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}
