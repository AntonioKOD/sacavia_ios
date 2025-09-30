import SwiftUI
import MapKit
import UIKit

// Import AuthManager and baseAPIURL
// AuthManager is defined in AuthManager.swift
// baseAPIURL is defined in Utils.swift

// Supporting types and modals are now defined in SharedModals.swift

// MARK: - Response Models for EnhancedLocationDetailView
struct LocationDetailData: Decodable {
    let location: SearchLocation
    
    // Custom initializer for manual creation
    init(location: SearchLocation) {
        self.location = location
    }
}

struct LocationDetailResponse: Decodable {
    let success: Bool
    let data: LocationDetailData?
    let error: String?
}

// Enhanced Location Detail View - Unified for both search and map contexts
struct EnhancedLocationDetailView: View {
    let locationId: String
    @State private var location: LocationDetailData?
    @State private var reviews: [Review] = []
    @State private var tips: [InsiderTip] = []
    @State private var communityPhotos: [CommunityPhoto] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showReviewModal = false
    @State private var showTipModal = false
    @State private var showPhotoModal = false
    @State private var selectedGalleryIndex = 0
    @State private var selectedTab = 0 // 0: About, 1: Reviews, 2: Photos, 3: Tips
    @State private var showMoreOptions = false
    @State private var showReportContent = false
    @State private var showClaimModal = false
    @State private var showShareModal = false
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var auth: AuthManager

    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    // Check if location is unclaimed or can be claimed
    private var isUnclaimed: Bool {
        guard let location = location?.location else { return false }
        
        // If no ownership info exists, it's unclaimed
        guard let ownership = location.ownership else {
            print("🔍 [EnhancedLocationDetailView] No ownership info - treating as unclaimed")
            return true
        }
        
        // Check claim status
        let claimStatus = ownership.claimStatus
        let result = claimStatus == "unclaimed" || claimStatus == nil
        
        print("🔍 [EnhancedLocationDetailView] isUnclaimed check:")
        print("🔍 [EnhancedLocationDetailView] - Location: \(location.name)")
        print("🔍 [EnhancedLocationDetailView] - Ownership: \(claimStatus ?? "nil")")
        print("🔍 [EnhancedLocationDetailView] - CreatedBy: \(location.createdBy ?? "nil")")
        print("🔍 [EnhancedLocationDetailView] - Result: \(result)")
        return result
    }
    
    // Check if location is verified/claimed
    private var isVerified: Bool {
        guard let ownership = location?.location.ownership,
              let claimStatus = ownership.claimStatus else { return false }
        return ["approved", "verified"].contains(claimStatus)
    }
    
    // Check if location is pending claim
    private var isPendingClaim: Bool {
        guard let ownership = location?.location.ownership,
              let claimStatus = ownership.claimStatus else { return false }
        return claimStatus == "pending"
    }
    
    // Check if location has incomplete data (simple community submission)
    private var hasIncompleteData: Bool {
        guard let location = location?.location else { return true }
        
        // Check for missing key business information
        let hasContactInfo = location.contactInfo?.phone != nil || location.contactInfo?.website != nil
        let hasBusinessHours = location.businessHours != nil && !location.businessHours!.isEmpty
        let hasPriceRange = location.priceRange != nil && !location.priceRange!.isEmpty
        let hasDetailedDescription = location.description != nil && location.description!.count > 50
        
        // If missing multiple key fields, consider it incomplete
        let missingFields = [hasContactInfo, hasBusinessHours, hasPriceRange, hasDetailedDescription].filter { !$0 }.count
        return missingFields >= 2
    }
    
    // Get data completeness score (0-100)
    private var dataCompletenessScore: Int {
        guard let location = location?.location else { return 0 }
        
        var score = 0
        let maxScore = 100
        
        // Basic info (20 points)
        if location.name.count > 0 { score += 10 }
        if location.shortDescription != nil && !location.shortDescription!.isEmpty { score += 10 }
        
        // Contact info (20 points)
        if location.contactInfo?.phone != nil { score += 10 }
        if location.contactInfo?.website != nil { score += 10 }
        
        // Business details (20 points)
        if location.businessHours != nil && !location.businessHours!.isEmpty { score += 10 }
        if location.priceRange != nil && !location.priceRange!.isEmpty { score += 10 }
        
        // Rich content (20 points)
        if location.description != nil && location.description!.count > 50 { score += 10 }
        if location.gallery != nil && !location.gallery!.isEmpty { score += 10 }
        
        // Categories and tags (10 points)
        if location.categories != nil && !location.categories!.isEmpty { score += 5 }
        if location.tags != nil && !location.tags!.isEmpty { score += 5 }
        
        // Accessibility (5 points)
        if location.accessibility != nil { score += 5 }
        
        // Additional content (5 points) - for any other rich content
        if location.insiderTips != nil && !location.insiderTips!.isEmpty { score += 5 }
        
        return min(score, maxScore)
    }
    
    // Status badge view
    private var statusBadge: some View {
        Group {
            if isVerified {
                Text("Verified")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(12)
            } else if isPendingClaim {
                Text("Pending")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(12)
            } else {
                Text("Community-added")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.7))
                    .cornerRadius(12)
            }
        }
    }

    var body: some View {
        NavigationView {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading location details...")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Location Details")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
            } else if let error = error {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text("Error")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    Button("Retry") {
                        fetchLocationDetails()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Location Details")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
            } else if let location = location {
                ScrollView {
                    VStack(spacing: 0) {
                        // Compact header with image and basic info
                        compactHeaderView(for: location)
                        
                        // Quick action buttons
                        quickActionButtons
                        
                        // Friends sharing section
                        
                        // Tab navigation
                        tabNavigation
                        
                        // Tab content
                        tabContent(for: location)
                    }
                }
                .background(
                    LinearGradient(
                        colors: [Color(.systemGray6), Color.white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                )
                .navigationTitle("Location Details")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    },
                    trailing: HStack(spacing: 16) {
                        Button(action: { showShareModal = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(primaryColor)
                        }
                        Button(action: { toggleSaveLocation() }) {
                            Image(systemName: (location.location.isSaved ?? false) ? "bookmark.fill" : "bookmark")
                                .foregroundColor((location.location.isSaved ?? false) ? .orange : .primary)
                        }
                        Button(action: { showMoreOptions = true }) {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.primary)
                        }
                    }
                )
            } else {
                EmptyView()
                    .navigationTitle("Location Details")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
            }
        }
        .onAppear {
            fetchLocationDetails()
        }
        .fullScreenCover(isPresented: $showReviewModal) {
            WriteReviewModal(locationId: locationId) {
                fetchReviews()
                fetchTips()
                fetchCommunityPhotos()
            }
            .environmentObject(auth)
        }
        .fullScreenCover(isPresented: $showTipModal) {
            AddTipModal(locationId: locationId) {
                fetchTips()
            }
            .environmentObject(auth)
        }
        .fullScreenCover(isPresented: $showPhotoModal) {
            AddPhotoModal(locationId: locationId) {
                fetchReviews()
                fetchTips()
                fetchCommunityPhotos()
            }
            .environmentObject(auth)
        }
        .confirmationDialog("More Options", isPresented: $showMoreOptions) {
            Button("Report Location", role: .destructive) {
                showReportContent = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .fullScreenCover(isPresented: $showReportContent) {
            ReportContentView(
                contentType: "location",
                contentId: locationId,
                contentTitle: location?.location.name ?? "Location"
            )
        }
        .sheet(isPresented: $showClaimModal) {
            ClaimBusinessModal(
                locationId: locationId,
                locationName: location?.location.name ?? "Unknown Location",
                isPresented: $showClaimModal
            )
        }
        .sheet(isPresented: $showShareModal) {
            if let location = location {
                LocationShareModal(location: location.location, isPresented: $showShareModal)
            }
        }
    }
    
    // MARK: - Compact Header View
    private func compactHeaderView(for location: LocationDetailData) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Hero image carousel
            locationImageCarousel(for: location)
                .frame(height: 240)
                .clipped()
            
            // Bottom gradient to improve text contrast
            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.6)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 240)
            
            // Info overlay
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text(location.location.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // Status badge
                    statusBadge
                }
                
                if let address = location.location.address {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                }
                
                // Chips row
                HStack(spacing: 8) {
                    if let rating = location.location.rating {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    
                    if let categories = location.location.categories, let first = categories.first {
                        Text(first)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Quick Action Buttons
    private var quickActionButtons: some View {
        VStack(spacing: 16) {
            // Regular action buttons
            HStack(spacing: 16) {
                QuickActionButton(
                    icon: "location.fill",
                    title: "Directions",
                    color: primaryColor
                ) {
                    openInMaps()
                }
                
                QuickActionButton(
                    icon: location?.location.isSaved == true ? "bookmark.fill" : "bookmark",
                    title: location?.location.isSaved == true ? "Saved" : "Save",
                    color: location?.location.isSaved == true ? .orange : .blue
                ) {
                    print("🔍 [EnhancedLocationDetailView] Save button pressed")
                    print("🔍 [EnhancedLocationDetailView] Current isSaved state: \(location?.location.isSaved ?? false)")
                    toggleSaveLocation()
                }
                
                QuickActionButton(
                    icon: "star.fill",
                    title: "Review",
                    color: secondaryColor
                ) {
                    showReviewModal = true
                }
                
                QuickActionButton(
                    icon: "camera.fill",
                    title: "Photo",
                    color: .green
                ) {
                    showPhotoModal = true
                }
                
                QuickActionButton(
                    icon: "lightbulb.fill",
                    title: "Tip",
                    color: .orange
                ) {
                    showTipModal = true
                }
                
                // Regular claim button for complete locations
                if isUnclaimed && !hasIncompleteData {
                    QuickActionButton(
                        icon: "building.2.fill",
                        title: "Claim",
                        color: .orange
                    ) {
                        showClaimModal = true
                    }
                }
            }
            
            // Prominent claim button for incomplete locations
            if isUnclaimed && hasIncompleteData {
                Button(action: { showClaimModal = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Claim This Location")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("Add complete location information")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [primaryColor, primaryColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: primaryColor.opacity(0.3), radius: 6, x: 0, y: 3)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }
    
    
    // MARK: - Image Carousel
    private func locationImageCarousel(for location: LocationDetailData) -> some View {
        let allImages = getAllImages(for: location)
        
        return VStack {
            if allImages.isEmpty {
                // No images available - show placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    )
            } else if allImages.count == 1 {
                // Single image - no carousel needed
                AsyncImage(url: URL(string: allImages[0])) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 200)
                .clipped()
            } else {
                // Multiple images - show carousel
                ZStack(alignment: .bottom) {
                    TabView(selection: $selectedGalleryIndex) {
                        ForEach(allImages.indices, id: \.self) { index in
                            AsyncImage(url: URL(string: allImages[index])) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 30))
                                            .foregroundColor(.gray)
                                    )
                            }
                            .frame(height: 200)
                            .clipped()
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 200)
                    .allowsHitTesting(true)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                let threshold: CGFloat = 50
                                if value.translation.width > threshold {
                                    // Swipe right - go to previous image
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedGalleryIndex = selectedGalleryIndex > 0 ? selectedGalleryIndex - 1 : allImages.count - 1
                                    }
                                } else if value.translation.width < -threshold {
                                    // Swipe left - go to next image
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedGalleryIndex = selectedGalleryIndex < allImages.count - 1 ? selectedGalleryIndex + 1 : 0
                                    }
                                }
                            }
                    )
                    
                    // Custom page indicator and navigation
                    VStack {
                        Spacer()
                        
                        HStack {
                            // Previous button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedGalleryIndex = selectedGalleryIndex > 0 ? selectedGalleryIndex - 1 : allImages.count - 1
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .opacity(allImages.count > 1 ? 1 : 0)
                            .allowsHitTesting(true)
                            
                            Spacer()
                            
                            // Page indicator
                            HStack(spacing: 8) {
                                ForEach(0..<allImages.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == selectedGalleryIndex ? Color.white : Color.white.opacity(0.5))
                                        .frame(width: 8, height: 8)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                selectedGalleryIndex = index
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Capsule())
                            .allowsHitTesting(true)
                            
                            Spacer()
                            
                            // Next button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedGalleryIndex = selectedGalleryIndex < allImages.count - 1 ? selectedGalleryIndex + 1 : 0
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .opacity(allImages.count > 1 ? 1 : 0)
                            .allowsHitTesting(true)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    .allowsHitTesting(true)
                    
                    // Image counter (top right)
                    if allImages.count > 1 {
                        VStack {
                            HStack {
                                Spacer()
                                Text("\(selectedGalleryIndex + 1) / \(allImages.count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Capsule())
                                    .padding(.trailing, 16)
                                    .padding(.top, 16)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper function to get all images
    private func getAllImages(for location: LocationDetailData) -> [String] {
        var images: [String] = []
        
        // Debug: Print image data
        print("🔍 [EnhancedLocationDetailView] Getting images for location: \(location.location.name)")
        print("🔍 [EnhancedLocationDetailView] Featured image: \(location.location.featuredImage ?? "nil")")
        print("🔍 [EnhancedLocationDetailView] Gallery count: \(location.location.gallery?.count ?? 0)")
        
        // Add featured image first if available
        if let featuredImage = location.location.featuredImage, !featuredImage.isEmpty {
            let processedUrl = processImageUrl(featuredImage)
            if !processedUrl.isEmpty {
                images.append(processedUrl)
                print("🔍 [EnhancedLocationDetailView] Added featured image: \(processedUrl)")
            }
        }
        
        // Add gallery images
        if let gallery = location.location.gallery {
            for (index, galleryItem) in gallery.enumerated() {
                print("🔍 [EnhancedLocationDetailView] Gallery item \(index): image=\(galleryItem.image ?? "nil"), caption=\(galleryItem.caption ?? "nil")")
                if let imageUrl = galleryItem.image, !imageUrl.isEmpty {
                    let processedUrl = processImageUrl(imageUrl)
                    if !processedUrl.isEmpty && !images.contains(processedUrl) {
                        images.append(processedUrl)
                        print("🔍 [EnhancedLocationDetailView] Added gallery image: \(processedUrl)")
                    }
                }
            }
        }
        
        print("🔍 [EnhancedLocationDetailView] Total images found: \(images.count)")
        return images
    }
    
    // MARK: - Helper function to process image URLs
    private func processImageUrl(_ url: String) -> String {
        // Skip blob URLs as they're not accessible from iOS app
        if url.hasPrefix("blob:") {
            print("🔍 [EnhancedLocationDetailView] Skipping blob URL: \(url)")
            return ""
        }
        
        // Skip data URLs as they're embedded
        if url.hasPrefix("data:") {
            print("🔍 [EnhancedLocationDetailView] Skipping data URL")
            return ""
        }
        
        // Return valid HTTP/HTTPS URLs
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            return url
        }
        
        // If it's a relative URL, make it absolute
        if url.hasPrefix("/") {
            let baseURL = baseAPIURL // Use the configured base URL from Utils.swift
            return baseURL + url
        }
        
        return url
    }
    
    // MARK: - Tab Navigation
    private var tabNavigation: some View {
        HStack(spacing: 0) {
            ForEach(["About", "Reviews", "Photos", "Tips"], id: \.self) { tab in
                Button(action: {
                    selectedTab = ["About", "Reviews", "Photos", "Tips"].firstIndex(of: tab) ?? 0
                }) {
                    VStack(spacing: 4) {
                        Text(tab)
                            .font(.system(size: 14, weight: selectedTab == ["About", "Reviews", "Photos", "Tips"].firstIndex(of: tab) ? .semibold : .medium))
                            .foregroundColor(selectedTab == ["About", "Reviews", "Photos", "Tips"].firstIndex(of: tab) ? primaryColor : .gray)
                        
                        Rectangle()
                            .fill(selectedTab == ["About", "Reviews", "Photos", "Tips"].firstIndex(of: tab) ? primaryColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Tab Content
    private func tabContent(for location: LocationDetailData) -> some View {
        VStack(spacing: 0) {
            switch selectedTab {
            case 0:
                CompactAboutSectionView(
                    location: Location(from: location.location),
                    callNumber: { phone in callNumber(phone) },
                    sendEmail: { email in sendEmail(email) },
                    formatDate: { dateString in formatDate(dateString) }
                )
            case 1:
                CompactReviewsSectionView(reviews: reviews)
            case 2:
                CompactCommunityPhotosSectionView(communityPhotos: communityPhotos)
            case 3:
                CompactTipsSectionView(tips: tips)
            default:
                EmptyView()
            }
        }
        .background(Color(.systemGray6))
    }
    
    // MARK: - Helper Functions
    private func openInMaps() {
        guard let location = location else { return }
        let lat = location.location.coordinates?.latitude ?? 0
        let lon = location.location.coordinates?.longitude ?? 0
        if let url = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lon)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func toggleSaveLocation() {
        guard let location = location else { return }
        
        // Optimistic UI update
        let newSavedState = !(location.location.isSaved ?? false)
        
        print("🔍 [EnhancedLocationDetailView] Toggling save location:")
        print("🔍 [EnhancedLocationDetailView] Current isSaved: \(location.location.isSaved ?? false)")
        print("🔍 [EnhancedLocationDetailView] New isSaved: \(newSavedState)")
        
        // Update the local state immediately for responsive UI
        let updatedLocation = LocationDetailData(
            location: location.location.copy(isSaved: newSavedState)
        )
        self.location = updatedLocation
        
        // Make API call to toggle save state
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations/\(locationId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Debug token retrieval
        print("🔍 [EnhancedLocationDetailView] Getting token from auth manager...")
        if let token = auth.getValidToken() {
            print("🔍 [EnhancedLocationDetailView] Token retrieved successfully")
            print("🔍 [EnhancedLocationDetailView] Token prefix: \(String(token.prefix(20)))...")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔍 [EnhancedLocationDetailView] Authorization header set: Bearer \(String(token.prefix(20)))...")
        } else {
            print("🔍 [EnhancedLocationDetailView] No valid token available")
        }
        
        let body = [
            "action": newSavedState ? "save" : "unsave"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("🔍 [EnhancedLocationDetailView] Making request to: \(url)")
        print("🔍 [EnhancedLocationDetailView] Request headers: \(request.allHTTPHeaderFields ?? [:])")
        print("🔍 [EnhancedLocationDetailView] Request body: \(body)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🔍 [EnhancedLocationDetailView] Error toggling save location: \(error)")
                    // Revert the optimistic update on error
                    let revertedLocation = LocationDetailData(
                        location: location.location.copy(isSaved: !newSavedState)
                    )
                    self.location = revertedLocation
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("🔍 [EnhancedLocationDetailView] Save location HTTP status: \(httpResponse.statusCode)")
                    
                    if let data = data {
                        do {
                            let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            print("🔍 [EnhancedLocationDetailView] Save location response: \(response ?? [:])")
                        } catch {
                            print("🔍 [EnhancedLocationDetailView] Error parsing save location response: \(error)")
                        }
                    }
                    
                    if httpResponse.statusCode == 200 {
                        // Success - check interaction state to get the updated state
                        print("🔍 [EnhancedLocationDetailView] Save/unsave successful, checking interaction state")
                        self.checkLocationInteractionState()
                        
                        // Post notification to refresh saved view
                        NotificationCenter.default.post(
                            name: NSNotification.Name("LocationSaveStateChanged"),
                            object: nil,
                            userInfo: [
                                "locationId": self.locationId,
                                "isSaved": newSavedState
                            ]
                        )
                    } else {
                        // Revert the optimistic update on error
                        let revertedLocation = LocationDetailData(
                            location: location.location.copy(isSaved: !newSavedState)
                        )
                        self.location = revertedLocation
                    }
                }
            }
        }.resume()
    }
    
    private func callNumber(_ number: String) {
        if let url = URL(string: "tel://\(number)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func formatDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: iso) {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .short
            return df.string(from: date)
        }
        return iso
    }
    
    
    // MARK: - API Functions
    private func fetchLocationDetails(showLoading: Bool = true) {
        if showLoading {
            isLoading = true
        }
        error = nil
        
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations/\(locationId)") else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Debug token retrieval
        print("🔍 [EnhancedLocationDetailView] Getting token for location details...")
        if let token = auth.getValidToken() {
            print("🔍 [EnhancedLocationDetailView] Token retrieved successfully for location details")
            print("🔍 [EnhancedLocationDetailView] Token prefix: \(String(token.prefix(20)))...")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔍 [EnhancedLocationDetailView] Authorization header set for location details")
        } else {
            print("🔍 [EnhancedLocationDetailView] No valid token available for location details")
        }
        
        print("🔍 [EnhancedLocationDetailView] Making location details request to: \(url)")
        print("🔍 [EnhancedLocationDetailView] Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if showLoading {
                    isLoading = false
                }
                
                if let error = error {
                    if showLoading {
                        self.error = "Network error: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let data = data else {
                    if showLoading {
                        self.error = "No data received"
                    }
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(LocationDetailResponse.self, from: data)
                    
                    if response.success, let locationData = response.data {
                        print("🔍 [EnhancedLocationDetailView] Location data received:")
                        print("🔍 [EnhancedLocationDetailView] Location ID: \(locationData.location.id)")
                        print("🔍 [EnhancedLocationDetailView] Location name: \(locationData.location.name)")
                        print("🔍 [EnhancedLocationDetailView] isSaved: \(locationData.location.isSaved ?? false)")
                        print("🔍 [EnhancedLocationDetailView] isSubscribed: \(locationData.location.isSubscribed ?? false)")
                        
                        // Update the location state
                        let previousSavedState = self.location?.location.isSaved ?? false
                        let newSavedState = locationData.location.isSaved ?? false
                        print("🔍 [EnhancedLocationDetailView] Save state changed: \(previousSavedState) -> \(newSavedState)")
                        
                        self.location = locationData
                        self.fetchReviews()
                        self.fetchTips()
                        self.fetchCommunityPhotos()
                        
                        // After loading location details, check interaction state
                        self.checkLocationInteractionState()
                    } else {
                        if showLoading {
                            self.error = response.error ?? "Failed to load location details"
                        }
                    }
                } catch {
                    print("🔍 [EnhancedLocationDetailView] Decoding error: \(error)")
                    if showLoading {
                        self.error = "Failed to parse response: \(error.localizedDescription)"
                    }
                }
            }
        }.resume()
    }
    
    private func checkLocationInteractionState() {
        Task {
            do {
                let apiService = APIService.shared
                let response = try await apiService.checkLocationInteractionState(locationIds: [locationId])
                
                if response.success, let data = response.data {
                    // Find the interaction state for this location
                    if let interaction = data.interactions.first(where: { $0.locationId == locationId }) {
                        print("🔍 [EnhancedLocationDetailView] Interaction state received:")
                        print("🔍 [EnhancedLocationDetailView] isSaved: \(interaction.isSaved)")
                        print("🔍 [EnhancedLocationDetailView] isSubscribed: \(interaction.isSubscribed)")
                        print("🔍 [EnhancedLocationDetailView] saveCount: \(interaction.saveCount)")
                        print("🔍 [EnhancedLocationDetailView] subscriberCount: \(interaction.subscriberCount)")
                        
                        // Update the location with the correct interaction state
                        if let currentLocation = location {
                            let updatedLocation = LocationDetailData(
                                location: currentLocation.location.copy(
                                    isSaved: interaction.isSaved,
                                    isSubscribed: interaction.isSubscribed
                                )
                            )
                            
                            DispatchQueue.main.async {
                                self.location = updatedLocation
                            }
                        }
                    }
                }
            } catch {
                print("🔍 [EnhancedLocationDetailView] Error checking interaction state: \(error)")
            }
        }
    }
    
    private func fetchReviews() {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations/\(locationId)/reviews") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = auth.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let response = try? JSONDecoder().decode(ReviewsResponse.self, from: data),
                   response.success {
                    self.reviews = response.data.reviews
                }
            }
        }.resume()
    }
    
    private func fetchTips() {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations/\(locationId)/insider-tips") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = auth.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let response = try? JSONDecoder().decode(TipsResponse.self, from: data),
                   response.success {
                    self.tips = response.data.tips
                }
            }
        }.resume()
    }
    
    private func fetchCommunityPhotos() {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations/\(locationId)/community-photos") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = auth.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let response = try? JSONDecoder().decode(CommunityPhotosResponse.self, from: data),
                   response.success {
                    self.communityPhotos = response.data.photos
                }
            }
        }.resume()
    }
}

// Modal views are now defined in SharedModals.swift

// MARK: - Supporting Views

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.25), lineWidth: 1)
                    )
            )
        }
    }
}

struct CompactAboutSectionView: View {
    let location: Location
    let callNumber: (String) -> Void
    let sendEmail: (String) -> Void
    let formatDate: (String) -> String
    
    // Check if location has incomplete data
    private var hasIncompleteData: Bool {
        let hasContactInfo = location.contactInfo?.phone != nil || location.contactInfo?.website != nil
        let hasBusinessHours = location.businessHours != nil && !location.businessHours!.isEmpty
        let hasPriceRange = location.priceRange != nil && !location.priceRange!.isEmpty
        let hasDetailedDescription = location.description != nil && location.description!.count > 50
        
        let missingFields = [hasContactInfo, hasBusinessHours, hasPriceRange, hasDetailedDescription].filter { !$0 }.count
        return missingFields >= 2
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Description - show description or shortDescription
            let descriptionText = location.description ?? location.shortDescription
            if let desc = descriptionText, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About This Place")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(desc)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            // Removed the entire "On the Map" section including the if condition
            
            // Address & Neighborhood
            if let address = location.address {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Address")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(address)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            if let neighborhood = location.neighborhood {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Neighborhood")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(neighborhood)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            // Business Hours
            if let businessHours = location.businessHours, !businessHours.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Business Hours")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(businessHours.indices, id: \.self) { idx in
                            let h = businessHours[idx]
                            Text("\(h.day): \(h.closed == true ? "Closed" : "\(h.open ?? "") - \(h.close ?? "")")")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Contact Info - only show if there's actual contact information
            if let contact = location.contactInfo,
               (contact.phone != nil || contact.email != nil || contact.website != nil) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contact")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        if let phone = contact.phone {
                            Button(action: { callNumber(phone) }) {
                                HStack {
                                    Image(systemName: "phone")
                                        .foregroundColor(.blue)
                                    Text(phone)
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                            }
                        }
                        
                        if let email = contact.email {
                            Button(action: { sendEmail(email) }) {
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.blue)
                                    Text(email)
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                            }
                        }
                        
                        if let website = contact.website {
                            Button(action: {
                                if let url = URL(string: website) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "globe")
                                        .foregroundColor(.blue)
                                    Text(website)
                                        .foregroundColor(.blue)
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
    }
}

struct CompactReviewsSectionView: View {
    let reviews: [Review]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reviews")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            if reviews.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    Text("No reviews yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(reviews.prefix(5), id: \.id) { review in
                        CompactReviewCard(review: review)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.white)
    }
}

struct CompactReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let author = review.author, let authorName = author.name {
                    Text(authorName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(review.rating) ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Text(review.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            if let createdAt = review.createdAt {
                Text(formatDateString(createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDateString(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct CompactCommunityPhotosSectionView: View {
    let communityPhotos: [CommunityPhoto]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Community Photos")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            if communityPhotos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "camera")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    Text("No photos yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(communityPhotos.prefix(9), id: \.id) { photo in
                        AsyncImage(url: URL(string: photo.photoUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(height: 100)
                        .clipped()
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.white)
    }
    
    // MARK: - Share Functions
    private func shareToFriend(_ friend: ShareFriend) {
        // Quick share to a specific friend
        // In a real app, this would make an API call to share the location
        print("📱 Sharing location with friend: \(friend.name)")
        
        // For now, just show a success message or haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

struct CompactTipsSectionView: View {
    let tips: [InsiderTip]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insider Tips")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            if tips.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    Text("No tips yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(tips.prefix(10), id: \.id) { tip in
                        CompactTipCard(tip: tip)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.white)
    }
}

struct CompactTipCard: View {
    let tip: InsiderTip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                
                Text(tip.category.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                
                Spacer()
            }
            
            Text(tip.tip)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(4)
            
            if let submittedAt = tip.submittedAt {
                Text(formatDateString(submittedAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDateString(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// AddPhotoModal is now defined in SharedModals.swift

// MARK: - Social Share Sheet
struct SocialShareSheet: View {
    let location: SearchLocation
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 255/255, green: 107/255, blue: 107/255))
                    
                    Text("Share Location")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Share this amazing place with your friends and followers")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Location Info Card
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: location.featuredImage ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(location.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                        
                        if let address = location.address {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                // Share Options
                VStack(spacing: 16) {
                    Text("Choose how to share")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        // Instagram
                        SocialShareButton(
                            title: "Instagram",
                            icon: "camera.fill",
                            color: .purple,
                            action: shareToInstagram
                        )
                        
                        // Twitter
                        SocialShareButton(
                            title: "Twitter",
                            icon: "bird.fill",
                            color: .blue,
                            action: shareToTwitter
                        )
                        
                        // Facebook
                        SocialShareButton(
                            title: "Facebook",
                            icon: "f.circle.fill",
                            color: .blue,
                            action: shareToFacebook
                        )
                        
                        // Share Anywhere
                        SocialShareButton(
                            title: "Share Anywhere",
                            icon: "square.and.arrow.up",
                            color: .gray,
                            action: shareToAnywhere
                        )
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // MARK: - Share Functions
    private func shareToInstagram() {
        let content = generateShareContent()
        let instagramHook = "instagram://share"
        
        if let url = URL(string: instagramHook), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // Fallback to web Instagram
            if let webUrl = URL(string: "https://www.instagram.com/") {
                UIApplication.shared.open(webUrl)
            }
        }
    }
    
    private func shareToTwitter() {
        let content = generateShareContent()
        let tweetText = "\(content.message) \(content.url) \(content.hashtags.joined(separator: " "))"
        let twitterUrl = "twitter://post?message=\(tweetText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: twitterUrl), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // Fallback to web Twitter
            if let webUrl = URL(string: "https://twitter.com/intent/tweet?text=\(tweetText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")") {
                UIApplication.shared.open(webUrl)
            }
        }
    }
    
    private func shareToFacebook() {
        let content = generateShareContent()
        
        // Fallback to web Facebook
        if let webUrl = URL(string: "https://www.facebook.com/sharer/sharer.php?u=\(content.url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(webUrl)
        }
    }
    
    private func shareToAnywhere() {
        let content = generateShareContent()
        let shareText = "\(content.message)\n\n\(content.url)\n\n\(content.hashtags.joined(separator: " "))"
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // Configure for iPad presentation
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Present the share sheet
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        }
    }
    
    private func generateShareContent() -> ShareContent {
        let shareManager = SocialShareManager.shared
        return shareManager.generateShareContent(for: .location(Location(from: location)), user: AuthManager.shared.user)
    }
}

// MARK: - Social Share Button
struct SocialShareButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Friends Share Modal
struct FriendsShareModal: View {
    let location: SearchLocation
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedFriends: Set<String> = []
    @State private var message: String = ""
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String?
    @State private var friends: [ShareFriend] = []
    @State private var isLoadingFriends: Bool = true
    
    // Quick reply templates
    private let quickReplies = [
        "Check this out!",
        "You should visit this place!",
        "Found an amazing spot!",
        "This looks interesting!"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Location info
                        locationInfoCard
                        
                        // Message section
                        messageSection
                        
                        // Friends selection
                        friendsSelectionSection
                    }
                    .padding()
                }
                
                // Bottom action button
                bottomActionButton
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showSuccess) {
            SuccessView(isPresented: $showSuccess)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .onAppear {
            fetchFriends()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.primary)
                
                Spacer()
                
                Text("Send to Followers")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Send") {
                    sendToFriends()
                }
                .font(.headline)
                .foregroundColor(selectedFriends.isEmpty ? .gray : Color(red: 255/255, green: 107/255, blue: 107/255))
                .disabled(selectedFriends.isEmpty || isLoading)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .padding(.bottom, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Location Info Card
    private var locationInfoCard: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: location.featuredImage ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let address = location.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Message Section
    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a message (optional)")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Quick replies
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickReplies, id: \.self) { reply in
                        Button(reply) {
                            message = reply
                        }
                        .font(.caption)
                        .foregroundColor(message == reply ? .white : Color(red: 255/255, green: 107/255, blue: 107/255))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            message == reply ? 
                            Color(red: 255/255, green: 107/255, blue: 107/255) :
                            Color(red: 255/255, green: 107/255, blue: 107/255).opacity(0.1)
                        )
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Custom message
            TextEditor(text: $message)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Friends Selection Section
    private var friendsSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Friends")
                .font(.headline)
                .fontWeight(.semibold)
            
            if isLoadingFriends {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading friends...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if friends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No Friends Found")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("You don't have any mutual friends yet. Start following people to share locations with them!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(friends, id: \.id) { friend in
                        FriendSelectionRow(
                            friend: friend,
                            isSelected: selectedFriends.contains(friend.id),
                            onToggle: {
                                toggleFriend(friend.id)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Action Button
    private var bottomActionButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: sendToFriends) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("Send to \(selectedFriends.count) friend\(selectedFriends.count == 1 ? "" : "s")")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    selectedFriends.isEmpty ? Color.gray : Color(red: 255/255, green: 107/255, blue: 107/255)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedFriends.isEmpty || isLoading)
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helper Functions
    private func toggleFriend(_ friendId: String) {
        if selectedFriends.contains(friendId) {
            selectedFriends.remove(friendId)
        } else {
            selectedFriends.insert(friendId)
        }
    }
    
    private func sendToFriends() {
        isLoading = true
        
        Task {
            do {
                let response = try await APIService.shared.shareLocation(
                    locationId: location.id,
                    recipientIds: Array(selectedFriends),
                    message: message.isEmpty ? "Check this out!" : message,
                    messageType: "check_out"
                )
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                    print("✅ [FriendsShareModal] Successfully shared location with \(response.sharesCreated) followers")
                    
                    // Close the modal after successful sharing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } catch {
                print("❌ [FriendsShareModal] Error sharing location: \(error)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to share location. Please try again."
                }
            }
        }
    }
    
    private func fetchFriends() {
        isLoadingFriends = true
        
        Task {
            do {
                let fetchedFriends = try await APIService.shared.getFollowers()
                await MainActor.run {
                    self.friends = fetchedFriends
                    self.isLoadingFriends = false
                }
            } catch {
                print("❌ [FriendsShareModal] Error fetching followers: \(error)")
                await MainActor.run {
                    self.friends = []
                    self.isLoadingFriends = false
                }
            }
        }
    }
}



