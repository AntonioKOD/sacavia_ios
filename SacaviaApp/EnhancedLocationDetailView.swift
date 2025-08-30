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
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var auth: AuthManager

    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4

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
                        
                        // Tab navigation
                        tabNavigation
                        
                        // Tab content
                        tabContent(for: location)
                    }
                }
                .navigationTitle("Location Details")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    },
                    trailing: Button(action: { showMoreOptions = true }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.primary)
                    }
                )
            } else {
                EmptyView()
                    .navigationTitle("Location Details")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(trailing: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    })
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
    }
    
    // MARK: - Compact Header View
    private func compactHeaderView(for location: LocationDetailData) -> some View {
        VStack(spacing: 0) {
            // Image carousel section
            locationImageCarousel(for: location)
            
            // Location info overlay
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(location.location.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let rating = location.location.rating {
                            HStack(spacing: 4) {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                        .font(.system(size: 12))
                                        .foregroundColor(.yellow)
                                }
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Category badge
                    if let categories = location.location.categories, !categories.isEmpty {
                        Text(categories[0])
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(primaryColor)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                
                if let address = location.location.address {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    // MARK: - Quick Action Buttons
    private var quickActionButtons: some View {
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
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }
    
    // MARK: - Image Carousel
    private func locationImageCarousel(for location: LocationDetailData) -> some View {
        let allImages = getAllImages(for: location)
        
        return Group {
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
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    
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
        
        // Add featured image first if available
        if let featuredImage = location.location.featuredImage, !featuredImage.isEmpty {
            images.append(featuredImage)
        }
        
        // Add gallery images
        if let gallery = location.location.gallery {
            for galleryItem in gallery {
                if let imageUrl = galleryItem.image, !imageUrl.isEmpty && !images.contains(imageUrl) {
                    images.append(imageUrl)
                }
            }
        }
        
        return images
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
        if let url = URL(string: "http://maps.apple.com/?ll=\(lat),\(lon)") {
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
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

struct CompactAboutSectionView: View {
    let location: Location
    let callNumber: (String) -> Void
    let sendEmail: (String) -> Void
    let formatDate: (String) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Description
            if let desc = location.description {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About This Place")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(desc)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
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
            
            // Contact Info
            if let contact = location.contactInfo {
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