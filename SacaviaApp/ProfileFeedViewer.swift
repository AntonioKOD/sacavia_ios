import SwiftUI
import AVKit

// MARK: - Profile Feed Viewer
struct ProfileFeedViewer: View {
    let username: String
    let initialItems: [NormalizedProfileFeedItem]
    let initialCursor: String?
    let isOpen: Bool
    let onClose: () -> Void
    let initialPostId: String?
    
    @State private var items: [NormalizedProfileFeedItem] = []
    @State private var cursor: String?
    @State private var activeIndex: Int = 0
    @State private var isLoading = false
    @State private var error: String?
    @State private var hasMore = true
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    @StateObject private var apiService = APIService()
    @Environment(\.dismiss) private var dismiss
    
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        print("🔍 [ProfileFeedViewer] Rendering viewer with \(items.count) items")
        print("🔍 [ProfileFeedViewer] Initial items count: \(initialItems.count)")
        print("🔍 [ProfileFeedViewer] Active index: \(activeIndex)")
        print("🔍 [ProfileFeedViewer] Is loading: \(isLoading)")
        
        return
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                    .opacity(0.95)
                
                VStack(spacing: 0) {
                    // Header
                    ProfileFeedViewerHeader(
                        currentIndex: activeIndex,
                        totalCount: items.count,
                        hasMore: hasMore,
                        onClose: onClose
                    )
                    
                    // Main content area
                    if items.isEmpty {
                        if isLoading {
                            // Show loading state
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Loading posts...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                        } else {
                            // Show empty state
                            VStack(spacing: 20) {
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("No posts available")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("This user hasn't shared any posts yet.")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                        }
                    } else {
                        GeometryReader { geometry in
                            TabView(selection: $activeIndex) {
                                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                    ProfileFeedViewerItem(
                                        item: item,
                                        index: index,
                                        totalCount: items.count,
                                        hasMore: hasMore,
                                        onLoadMore: loadMoreItems
                                    )
                                    .tag(index)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .onChange(of: activeIndex) { newIndex in
                                handleIndexChange(newIndex)
                            }
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isDragging = true
                                        dragOffset = value.translation.width
                                    }
                                    .onEnded { value in
                                        isDragging = false
                                        let threshold: CGFloat = 50
                                        
                                        if value.translation.width > threshold {
                                            // Swipe right - go to previous
                                            handlePrevious()
                                        } else if value.translation.width < -threshold {
                                            // Swipe left - go to next
                                            handleNext()
                                        }
                                        
                                        dragOffset = 0
                                    }
                            )
                        }
                    }
                }
                
                // Navigation arrows
                HStack {
                    Button(action: handlePrevious) {
                        Image(systemName: "chevron.left")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .opacity(activeIndex > 0 ? 1 : 0.3)
                    .disabled(activeIndex <= 0)
                    
                    Spacer()
                    
                    Button(action: handleNext) {
                        Image(systemName: "chevron.right")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .opacity((activeIndex < items.count - 1 || hasMore) ? 1 : 0.3)
                    .disabled(activeIndex >= items.count - 1 && !hasMore)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
                
                // Loading indicator
                if isLoading {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Spacer()
                        }
                        Spacer()
                    }
                }
                
                // Error message
                if let error = error {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title)
                                    .foregroundColor(.white)
                                Text("Error loading posts")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(error)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                Button("Retry") {
                                    loadMoreItems()
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(20)
                            }
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(16)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .onAppear {
                setupInitialState()
            }
            .onDisappear {
                cleanup()
            }
    }
    
    private func setupInitialState() {
        print("🔍 [ProfileFeedViewer] Setting up initial state")
        print("🔍 [ProfileFeedViewer] Username: \(username)")
        print("🔍 [ProfileFeedViewer] Initial items count: \(initialItems.count)")
        print("🔍 [ProfileFeedViewer] Initial cursor: \(initialCursor ?? "nil")")
        print("🔍 [ProfileFeedViewer] Initial post ID: \(initialPostId ?? "nil")")
        
        // If username is empty, we can't load data
        guard !username.isEmpty else {
            print("🔍 [ProfileFeedViewer] Username is empty, cannot load data")
            return
        }
        
        items = initialItems
        cursor = initialCursor
        
        print("🔍 [ProfileFeedViewer] After setting items - items.count: \(items.count)")
        print("🔍 [ProfileFeedViewer] After setting cursor - cursor: \(cursor ?? "nil")")
        
        // Find initial post index
        if let postId = initialPostId {
            if let index = items.firstIndex(where: { $0.id == postId }) {
                activeIndex = index
                print("🔍 [ProfileFeedViewer] Found initial post at index: \(index)")
            } else {
                activeIndex = 0
                print("🔍 [ProfileFeedViewer] Initial post not found, using index 0")
            }
        } else {
            activeIndex = 0
            print("🔍 [ProfileFeedViewer] No initial post ID, using index 0")
        }
        
        hasMore = cursor != nil
        
        // If we have no initial items, load data immediately
        if items.isEmpty {
            print("🔍 [ProfileFeedViewer] No initial items, loading data immediately...")
            // Use a small delay to ensure the view is fully rendered before loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.loadInitialData()
            }
        } else {
            print("🔍 [ProfileFeedViewer] Using provided initial items")
            // Even if we have initial items, ensure we have the correct post selected
            if let postId = initialPostId, !items.contains(where: { $0.id == postId }) {
                print("🔍 [ProfileFeedViewer] Initial post not found in provided items, loading fresh data...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.loadInitialData()
                }
            }
        }
        
        print("🔍 [ProfileFeedViewer] Setup complete - items: \(items.count), activeIndex: \(activeIndex), hasMore: \(hasMore)")
    }
    
    private func handleIndexChange(_ newIndex: Int) {
        // Load more items if we're near the end
        if newIndex >= items.count - 3 && hasMore && !isLoading {
            loadMoreItems()
        }
    }
    
    private func handlePrevious() {
        if activeIndex > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                activeIndex -= 1
            }
        }
    }
    
    private func handleNext() {
        if activeIndex < items.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                activeIndex += 1
            }
        } else if hasMore && !isLoading {
            loadMoreItems()
        }
    }
    
    private func loadMoreItems() {
        guard hasMore && !isLoading, let currentCursor = cursor else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let response = try await apiService.getNormalizedProfileFeed(username: username, cursor: currentCursor)
                
                await MainActor.run {
                    items.append(contentsOf: response.items)
                    cursor = response.nextCursor
                    hasMore = response.nextCursor != nil
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func loadInitialData() {
        guard !isLoading else { return }
        guard !username.isEmpty else { 
            print("🔍 [ProfileFeedViewer] Cannot load data - username is empty")
            return 
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let response = try await apiService.getNormalizedProfileFeed(username: username, cursor: nil)
                
                await MainActor.run {
                    items = response.items
                    cursor = response.nextCursor
                    hasMore = response.nextCursor != nil
                    isLoading = false
                    
                    // Find the initial post if we have one
                    if let postId = initialPostId {
                        if let index = items.firstIndex(where: { $0.id == postId }) {
                            activeIndex = index
                            print("🔍 [ProfileFeedViewer] Found initial post at index: \(index) after loading")
                        } else {
                            activeIndex = 0
                            print("🔍 [ProfileFeedViewer] Initial post not found after loading, using index 0")
                        }
                    } else {
                        activeIndex = 0
                    }
                    
                    print("🔍 [ProfileFeedViewer] Initial data loaded - items: \(items.count), activeIndex: \(activeIndex)")
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func cleanup() {
        // Clean up any resources if needed
    }
}

// MARK: - Profile Feed Viewer Header
struct ProfileFeedViewerHeader: View {
    let currentIndex: Int
    let totalCount: Int
    let hasMore: Bool
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Post counter
            Text("\(currentIndex + 1) of \(totalCount)\(hasMore ? "+" : "")")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(16)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
}

// MARK: - Profile Feed Viewer Item
struct ProfileFeedViewerItem: View {
    let item: NormalizedProfileFeedItem
    let index: Int
    let totalCount: Int
    let hasMore: Bool
    let onLoadMore: () -> Void
    
    @State private var isVideoPlaying = false
    @State private var player: AVPlayer?
    
    var body: some View {
        print("🔍 [ProfileFeedViewerItem] Rendering item \(index): \(item.id)")
        print("🔍 [ProfileFeedViewerItem] Item has cover: \(item.cover != nil)")
        print("🔍 [ProfileFeedViewerItem] Item has media: \(item.media.count) items")
        
        return VStack(spacing: 0) {
            // Media content
            ZStack {
                if let cover = item.cover {
                    if cover.type == "IMAGE" {
                        AsyncImage(url: URL(string: absoluteMediaURL(cover.url)?.absoluteString ?? cover.url)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                )
                        }
                    } else {
                        // Video content
                        VideoPlayerView(
                            videoUrl: absoluteMediaURL(cover.url) ?? URL(string: cover.url)!,
                            enableAutoplay: isVideoPlaying,
                            enableAudio: true,
                            loop: true
                        )
                    }
                } else {
                    // No media - show placeholder
                    VStack(spacing: 20) {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        Text("No media available")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.2))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Content info
            VStack(alignment: .leading, spacing: 16) {
                // Caption
                if !item.caption.isEmpty {
                    Text(item.caption)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                }
                
                // Date and metadata
                HStack {
                    Text(formatDate(item.createdAt))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    // Media type indicator
                    if let cover = item.cover {
                        HStack(spacing: 4) {
                            Image(systemName: cover.type == "VIDEO" ? "video.fill" : "photo.fill")
                                .font(.caption)
                            Text(cover.type == "VIDEO" ? "Video" : "Photo")
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .background(
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onAppear {
            print("🔍 [ProfileFeedViewerItem] Rendering item: \(item.id), cover: \(item.cover?.type ?? "nil")")
            // Start video playback if it's a video
            if let cover = item.cover, cover.type == "VIDEO" {
                isVideoPlaying = true
            }
        }
        .onDisappear {
            // Pause video when item disappears
            isVideoPlaying = false
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
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
        
        return dateString.prefix(10).description
    }
}

