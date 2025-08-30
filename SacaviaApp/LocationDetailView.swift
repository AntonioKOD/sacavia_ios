import SwiftUI

struct LocationDetailView: View {
    let locationId: String
    @State private var location: LocationDetailData?
    @State private var isLoading = true
    @State private var error: String?
    @State private var selectedTab = 0 // 0: About, 1: Reviews, 2: Photos, 3: Tips
    @State private var reviews: [Review] = []
    @State private var tips: [InsiderTip] = []
    @State private var communityPhotos: [CommunityPhoto] = []
    @State private var showReviewModal = false
    @State private var showTipModal = false
    @State private var showPhotoModal = false
    @State private var selectedGalleryIndex = 0
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var auth: AuthManager
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
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
                } else if let error = error {
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
                } else if let location = location {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Hero Section with Image Gallery
                            if let featuredImage = location.location.featuredImage {
                                ZStack(alignment: .bottom) {
                                    AsyncImage(url: URL(string: featuredImage)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [primaryColor.opacity(0.1), secondaryColor.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .overlay(
                                                Image(systemName: "mappin.and.ellipse")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(primaryColor.opacity(0.6))
                                            )
                                    }
                                    .frame(height: 280)
                                    .clipped()
                                    
                                    // Gradient overlay
                                    LinearGradient(
                                        colors: [Color.clear, Color.black.opacity(0.4)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(height: 280)
                                }
                            }
                            
                            // Content Section
                            VStack(alignment: .leading, spacing: 20) {
                                // Header Info
                                VStack(alignment: .leading, spacing: 12) {
                                    // Title and Badges
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(location.location.name)
                                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                                .foregroundColor(.primary)
                                                .lineLimit(2)
                                            
                                            if let address = location.location.address {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "location.fill")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(primaryColor.opacity(0.8))
                                                    
                                                    Text(address)
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(2)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Rating and Verification Badges
                                        VStack(spacing: 8) {
                                            if let rating = location.location.rating {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "star.fill")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.yellow)
                                                    
                                                    Text(String(format: "%.1f", rating))
                                                        .font(.system(size: 18, weight: .bold))
                                                        .foregroundColor(.primary)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.yellow.opacity(0.15))
                                                        .overlay(
                                                            Capsule()
                                                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                                        )
                                                )
                                            }
                                            
                                            HStack(spacing: 8) {
                                                if location.location.isVerified == true {
                                                    Image(systemName: "checkmark.seal.fill")
                                                        .foregroundColor(.green)
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .background(
                                                            Circle()
                                                                .fill(Color.white)
                                                                .frame(width: 24, height: 24)
                                                        )
                                                        .shadow(color: .green.opacity(0.3), radius: 2, x: 0, y: 1)
                                                }
                                                
                                                if location.location.isFeatured == true {
                                                    Image(systemName: "star.circle.fill")
                                                        .foregroundColor(.yellow)
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .background(
                                                            Circle()
                                                                .fill(Color.white)
                                                                .frame(width: 24, height: 24)
                                                        )
                                                        .shadow(color: .yellow.opacity(0.3), radius: 2, x: 0, y: 1)
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Categories
                                    if let categories = location.location.categories, !categories.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 10) {
                                                ForEach(categories, id: \.self) { category in
                                                    Text(category)
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 14)
                                                        .padding(.vertical, 8)
                                                        .background(
                                                            Capsule()
                                                                .fill(
                                                                    LinearGradient(
                                                                        colors: [secondaryColor, secondaryColor.opacity(0.8)],
                                                                        startPoint: .leading,
                                                                        endPoint: .trailing
                                                                    )
                                                                )
                                                                .shadow(color: secondaryColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                                        )
                                                }
                                            }
                                            .padding(.horizontal, 2)
                                        }
                                    }
                                }
                                
                                // Action Buttons
                                HStack(spacing: 12) {
                                    Button(action: { openInMaps() }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "location.fill")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("Directions")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(primaryColor)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
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
                                                            lineWidth: 2
                                                        )
                                                )
                                                .shadow(color: primaryColor.opacity(0.2), radius: 6, x: 0, y: 3)
                                        )
                                    }
                                    
                                    Button(action: { showReviewModal = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("Review")
                                                .font(.system(size: 16, weight: .semibold))
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
                                    
                                    Spacer()
                                    
                                    Button(action: { showPhotoModal = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("Add Photo")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [secondaryColor, secondaryColor.opacity(0.8)]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .shadow(color: secondaryColor.opacity(0.4), radius: 6, x: 0, y: 3)
                                        )
                                    }
                                }
                                
                                // Tab Picker
                                Picker("Tab", selection: $selectedTab) {
                                    Text("About").tag(0)
                                    Text("Reviews").tag(1)
                                    Text("Photos").tag(2)
                                    Text("Tips").tag(3)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.vertical, 8)
                                
                                // Tab Content
                                TabView(selection: $selectedTab) {
                                    // About Tab
                                    AboutTabView(location: location.location)
                                        .tag(0)
                                    
                                    // Reviews Tab
                                    ReviewsTabView(reviews: reviews)
                                        .tag(1)
                                    
                                    // Photos Tab
                                    PhotosTabView(communityPhotos: communityPhotos)
                                        .tag(2)
                                    
                                    // Tips Tab
                                    TipsTabView(tips: tips)
                                        .tag(3)
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                .frame(minHeight: 400)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                    .edgesIgnoringSafeArea(.top)
                }
            }
            .navigationTitle(location?.location.name ?? "Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(primaryColor)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            fetchLocationDetails()
        }
        .sheet(isPresented: $showReviewModal) {
            WriteReviewModal(locationId: locationId) {
                // Refresh data after review submission
                fetchLocationDetails()
            }
            .environmentObject(auth)
        }
        .sheet(isPresented: $showTipModal) {
            AddTipModal(locationId: locationId) {
                // Refresh data after tip submission
                fetchLocationDetails()
            }
            .environmentObject(auth)
        }
        .sheet(isPresented: $showPhotoModal) {
            AddPhotoModal(locationId: locationId) {
                // Refresh data after photo submission
                fetchLocationDetails()
            }
            .environmentObject(auth)
        }
    }
    
    private func fetchLocationDetails() {
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
                    if response.success {
                        self.location = response.data
                        // Fetch additional data
                        self.fetchReviews()
                        self.fetchTips()
                        self.fetchCommunityPhotos()
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
    
    private func fetchReviews() {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations/\(locationId)/reviews") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(ReviewsResponse.self, from: data),
                  result.success else { return }
            DispatchQueue.main.async { self.reviews = result.data.reviews }
        }.resume()
    }
    
    private func fetchTips() {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations/\(locationId)/insider-tips") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(InsiderTipsResponse.self, from: data),
                  result.success else { return }
            DispatchQueue.main.async { self.tips = result.data.tips }
        }.resume()
    }
    
    private func fetchCommunityPhotos() {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations/\(locationId)/community-photos") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(CommunityPhotosResponse.self, from: data),
                  result.success else { return }
            DispatchQueue.main.async { self.communityPhotos = result.data.photos }
        }.resume()
    }
    
    private func openInMaps() {
        guard let coordinates = location?.location.coordinates else { return }
        let lat = coordinates.latitude
        let lon = coordinates.longitude
        if let url = URL(string: "http://maps.apple.com/?ll=\(lat),\(lon)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Tab Views
struct AboutTabView: View {
    let location: SearchLocation
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Description
                if let description = location.description {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About This Place")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(description)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                }
                
                // Contact Information
                if let contactInfo = location.contactInfo {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact Information")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 8) {
                            if let phone = contactInfo.phone {
                                ContactRow(icon: "phone.fill", text: phone, action: { callNumber(phone) })
                            }
                            
                            if let email = contactInfo.email {
                                ContactRow(icon: "envelope.fill", text: email, action: { sendEmail(email) })
                            }
                            
                            if let website = contactInfo.website {
                                ContactRow(icon: "globe", text: website, action: { openWebsite(website) })
                            }
                        }
                    }
                }
                
                // Business Hours
                if let businessHours = location.businessHours, !businessHours.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Business Hours")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 6) {
                            ForEach(businessHours.indices, id: \.self) { index in
                                let hour = businessHours[index]
                                HStack {
                                    Text(hour.day)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    if hour.closed == true {
                                        Text("Closed")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("\(hour.open ?? "") - \(hour.close ?? "")")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                
                // Additional Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Additional Information")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        if let priceRange = location.priceRange {
                            InfoRow(icon: "dollarsign.circle.fill", text: "Price Range: \(priceRange)")
                        }
                        
                        if let neighborhood = location.neighborhood {
                            InfoRow(icon: "mappin.circle.fill", text: "Neighborhood: \(neighborhood)")
                        }
                        
                        if let coordinates = location.coordinates {
                            InfoRow(icon: "location.circle.fill", text: "Coordinates: \(String(format: "%.4f", coordinates.latitude)), \(String(format: "%.4f", coordinates.longitude))")
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
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
    
    private func openWebsite(_ website: String) {
        let urlString = website.hasPrefix("http") ? website : "https://\(website)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct ContactRow: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 78/255, green: 205/255, blue: 196/255))
                    .frame(width: 20)
                
                Text(text)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 78/255, green: 205/255, blue: 196/255))
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ReviewsTabView: View {
    let reviews: [Review]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if reviews.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No reviews yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("Be the first to share your experience!")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                } else {
                    ForEach(reviews) { review in
                        ReviewCard(review: review)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.author?.name ?? "Anonymous")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let title = review.title {
                        Text(title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.yellow)
                    
                    Text(String(format: "%.1f", review.rating))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            
            // Content
            Text(review.content)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.primary)
                .lineLimit(nil)
            
            // Pros and Cons
            if let pros = review.pros, !pros.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pros:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                    
                    ForEach(pros, id: \.self) { pro in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.green)
                            
                            Text(pro)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            
            if let cons = review.cons, !cons.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cons:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                    
                    ForEach(cons, id: \.self) { con in
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                            
                            Text(con)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            
            if let tips = review.tips {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tips:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Text(tips)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.primary)
                        .italic()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct PhotosTabView: View {
    let communityPhotos: [CommunityPhoto]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if communityPhotos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No community photos yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("Share your photos of this place!")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .gridCellColumns(2)
                    .padding(.vertical, 40)
                } else {
                    ForEach(communityPhotos) { photo in
                        PhotoCard(photo: photo)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct PhotoCard: View {
    let photo: CommunityPhoto
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = URL(string: photo.photoUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.gray.opacity(0.5))
                        )
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            if let caption = photo.caption {
                Text(caption)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

struct TipsTabView: View {
    let tips: [InsiderTip]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if tips.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "lightbulb.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No insider tips yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("Share your local knowledge!")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                } else {
                    ForEach(tips) { tip in
                        TipCard(tip: tip)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct TipCard: View {
    let tip: InsiderTip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(tip.category)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: 78/255, green: 205/255, blue: 196/255))
                    )
                
                Spacer()
                
                if let priority = tip.priority {
                    Text(priority)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.1))
                        )
                }
            }
            
            Text(tip.tip)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.primary)
                .lineLimit(nil)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// LocationDetailData and LocationDetailResponse are defined in EnhancedLocationDetailView.swift

// MARK: - Additional Data Models (using types from SharedTypes.swift)

// Modal views are now defined in EnhancedLocationDetailView.swift