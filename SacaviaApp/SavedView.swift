import SwiftUI
import AVKit

struct SavedView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SavedViewModel()
    @State private var selectedTab = 0
    
    // Brand colors matching FloatingActionButton
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                HStack(spacing: 0) {
                    SavedTabButton(
                        title: "All",
                        count: viewModel.stats?.totalSaved ?? 0,
                        isSelected: selectedTab == 0,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 0
                        }
                    }
                    
                    SavedTabButton(
                        title: "Locations",
                        count: viewModel.stats?.savedLocations ?? 0,
                        isSelected: selectedTab == 1,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 1
                        }
                    }
                    
                    SavedTabButton(
                        title: "Posts",
                        count: viewModel.stats?.savedPosts ?? 0,
                        isSelected: selectedTab == 2,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 2
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Content
                if viewModel.isLoading {
                    SavedLoadingView(primaryColor: primaryColor)
                } else if let error = viewModel.error {
                    SavedErrorView(error: error, primaryColor: primaryColor) {
                        viewModel.loadSavedContent()
                    }
                } else {
                    TabView(selection: $selectedTab) {
                        // All Content Tab
                        AllSavedContentView(
                            locations: viewModel.savedLocations,
                            posts: viewModel.savedPosts,
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor
                        )
                        .tag(0)
                        
                        // Locations Tab
                        SavedLocationsView(
                            locations: viewModel.savedLocations,
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor
                        )
                        .tag(1)
                        
                        // Posts Tab
                        SavedPostsView(
                            posts: viewModel.savedPosts,
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor
                        )
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.loadSavedContent()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(primaryColor)
                    }
                }
            }
            .onAppear {
                viewModel.loadSavedContent()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LocationSaveStateChanged"))) { notification in
                // Refresh saved content when a location save state changes
                print("🔍 [SavedView] Received location save state change notification")
                viewModel.loadSavedContent()
            }
        }
    }
}

// MARK: - Tab Button
struct SavedTabButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let primaryColor: Color
    let secondaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Text("\(count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? primaryColor : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? primaryColor.opacity(0.1) : Color.gray.opacity(0.1))
                    )
                
                // Selection indicator
                Rectangle()
                    .fill(isSelected ? primaryColor : Color.clear)
                    .frame(height: 2)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - All Saved Content View
struct AllSavedContentView: View {
    let locations: [SavedLocation]
    let posts: [SavedPost]
    let primaryColor: Color
    let secondaryColor: Color
    
    var allContent: [SavedContentItem] {
        var items: [SavedContentItem] = []
        
        // Add locations
        items.append(contentsOf: locations.map { SavedContentItem.location($0) })
        
        // Add posts
        items.append(contentsOf: posts.map { SavedContentItem.post($0) })
        
        // Sort by saved date (most recent first)
        return items.sorted { item1, item2 in
            let date1 = item1.savedDate
            let date2 = item2.savedDate
            return date1 > date2
        }
    }
    
    var body: some View {
        if allContent.isEmpty {
            EmptySavedView(primaryColor: primaryColor, secondaryColor: secondaryColor)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(allContent, id: \.id) { item in
                        switch item {
                        case .location(let location):
                            SavedLocationCard(
                                location: location,
                                primaryColor: primaryColor,
                                secondaryColor: secondaryColor
                            )
                        case .post(let post):
                            SavedPostCard(
                                post: post,
                                primaryColor: primaryColor,
                                secondaryColor: secondaryColor
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .coordinateSpace(name: "scroll")
        }
    }
}

// MARK: - Saved Locations View
struct SavedLocationsView: View {
    let locations: [SavedLocation]
    let primaryColor: Color
    let secondaryColor: Color
    
    var body: some View {
        if locations.isEmpty {
            EmptySavedView(message: "No saved locations yet", primaryColor: primaryColor, secondaryColor: secondaryColor)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(locations, id: \.id) { location in
                        SavedLocationCard(
                            location: location,
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
    }
}

// MARK: - Saved Posts View
struct SavedPostsView: View {
    let posts: [SavedPost]
    let primaryColor: Color
    let secondaryColor: Color
    
    var body: some View {
        if posts.isEmpty {
            EmptySavedView(message: "No saved posts yet", primaryColor: primaryColor, secondaryColor: secondaryColor)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(posts, id: \.id) { post in
                        SavedPostCard(
                            post: post,
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
    }
}

// MARK: - Saved Location Card
struct SavedLocationCard: View {
    let location: SavedLocation
    let primaryColor: Color
    let secondaryColor: Color
    
    var body: some View {
        NavigationLink(destination: LocationDetailView(locationId: location.id)) {
            VStack(alignment: .leading, spacing: 12) {
                // Image
                if let imageUrl = location.featuredImage?.url {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Title and verification badge
                    HStack {
                        Text(location.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if location.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(primaryColor)
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        // Saved indicator
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(primaryColor)
                            .font(.caption)
                    }
                    
                    // Address
                    if let address = location.address {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    // Categories
                    if let categories = location.categories, !categories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories.prefix(3), id: \.id) { category in
                                    Text(category.name)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(primaryColor.opacity(0.1))
                                        )
                                        .foregroundColor(primaryColor)
                                }
                            }
                        }
                    }
                    
                    // Rating and reviews
                    HStack {
                        if let rating = location.rating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if let reviewCount = location.reviewCount {
                            Text("(\(reviewCount) reviews)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Saved date
                        Text(formatSavedDate(location.savedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: primaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatSavedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        
        return "Recently"
    }
}

// MARK: - Saved Post Card
struct SavedPostCard: View {
    let post: SavedPost
    let primaryColor: Color
    let secondaryColor: Color
    
    var firstMedia: SavedMedia? {
        post.media?.first
    }
    
    var firstImageUrl: URL? {
        if let first = firstMedia, first.type == "image" {
            return URL(string: first.url)
        }
        return nil
    }
    
    var firstVideoUrl: URL? {
        if let first = firstMedia, first.type == "video" {
            return URL(string: first.url)
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 8)
            
            VStack(alignment: .leading, spacing: 0) {
                // Clean header
                HStack(spacing: 14) {
                    // Profile image (slightly larger)
                    if let avatarUrl = post.author.profileImage?.url, let imageUrl = URL(string: avatarUrl) {
                        AsyncImage(url: imageUrl) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ZStack {
                                Circle().fill(
                                    LinearGradient(
                                        colors: [primaryColor.opacity(0.8), secondaryColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                Text(getInitials(post.author.name))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: 2)
                                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                        )
                    } else {
                        ZStack {
                            Circle().fill(
                                LinearGradient(
                                    colors: [primaryColor.opacity(0.8), secondaryColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            Text(getInitials(post.author.name))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: 2)
                                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(post.author.name)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            if post.author.isVerified == true {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(primaryColor)
                                    .font(.caption)
                            }
                        }
                        
                        if let location = post.location {
                            Text(location.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Saved indicator
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(primaryColor)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                
                // Modern media content
                if let videoUrl = firstVideoUrl {
                    ZStack(alignment: .center) {
                        AutoplayVideoPlayer(videoUrl: videoUrl, enableAudio: true, loop: true)
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 420)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.22)],
                            startPoint: .center, endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .frame(maxHeight: 420)
                        
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                            )
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                } else if let imageUrl = firstImageUrl {
                    ZStack(alignment: .bottom) {
                        AsyncImage(url: imageUrl) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.1))
                        }
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.18)],
                            startPoint: .center, endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .frame(height: 320)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                }
                
                // Content section
                VStack(alignment: .leading, spacing: 18) {
                    if let title = post.title {
                        Text(title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                    }
                    
                    Text(post.content)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(4)
                        .lineSpacing(4)
                    
                    if let categories = post.categories, !categories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(categories.prefix(5), id: \.self) { category in
                                    Text(category)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [primaryColor, secondaryColor],
                                                        startPoint: .leading, endPoint: .trailing
                                                    )
                                                )
                                        )
                                }
                            }
                        }
                    }
                    
                    if let tags = post.tags, !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tags.prefix(8), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(primaryColor)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
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
                
                Divider().padding(.horizontal, 16)
                
                // Action bar
                HStack(spacing: 36) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.red)
                        Text("\(post.engagement.likeCount)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                        Text("\(post.engagement.commentCount)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Rating
                    if let rating = post.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Saved date
                    Text(formatSavedDate(post.savedAt))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 2)
    }
    
    private func formatSavedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            let now = Date()
            let timeInterval = now.timeIntervalSince(date)
            
            if timeInterval < 60 {
                return "Just now"
            } else if timeInterval < 3600 {
                let minutes = Int(timeInterval / 60)
                return "\(minutes)m ago"
            } else if timeInterval < 86400 {
                let hours = Int(timeInterval / 3600)
                return "\(hours)h ago"
            } else {
                let days = Int(timeInterval / 86400)
                return "\(days)d ago"
            }
        }
        
        return "Recently"
    }
}

// MARK: - Empty State View
struct EmptySavedView: View {
    let message: String
    let primaryColor: Color
    let secondaryColor: Color
    
    init(message: String = "No saved content yet", primaryColor: Color, secondaryColor: Color) {
        self.message = message
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 60))
                .foregroundColor(primaryColor)
            
            Text(message)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Save locations and posts to see them here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Loading View
struct SavedLoadingView: View {
    let primaryColor: Color
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(primaryColor)
            
            Text("Loading saved content...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Error View
struct SavedErrorView: View {
    let error: String
    let primaryColor: Color
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(primaryColor)
            
            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [primaryColor, primaryColor.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Supporting Types
enum SavedContentItem {
    case location(SavedLocation)
    case post(SavedPost)
    
    var id: String {
        switch self {
        case .location(let location):
            return "location_\(location.id)"
        case .post(let post):
            return "post_\(post.id)"
        }
    }
    
    var savedDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        switch self {
        case .location(let location):
            return formatter.date(from: location.savedAt) ?? Date()
        case .post(let post):
            return formatter.date(from: post.savedAt) ?? Date()
        }
    }
}

// MARK: - Preview
struct SavedView_Previews: PreviewProvider {
    static var previews: some View {
        SavedView()
    }
} 