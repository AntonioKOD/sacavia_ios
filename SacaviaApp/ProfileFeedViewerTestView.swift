import SwiftUI

// MARK: - Profile Feed Viewer Test View
struct ProfileFeedViewerTestView: View {
    @State private var showingViewer = false
    @State private var testItems: [NormalizedProfileFeedItem] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Profile Feed Viewer Test")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("This view tests the new Instagram-style profile feed viewer for iOS.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    Button("Load Test Data") {
                        loadTestData()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(red: 255/255, green: 107/255, blue: 107/255))
                    .cornerRadius(25)
                    
                    if !testItems.isEmpty {
                        Button("Open Feed Viewer") {
                            showingViewer = true
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(red: 78/255, green: 205/255, blue: 196/255))
                        .cornerRadius(25)
                    }
                }
                
                if isLoading {
                    ProgressView("Loading test data...")
                        .padding()
                }
                
                if !testItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Data Loaded:")
                            .font(.headline)
                        Text("\(testItems.count) items")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Show first few items as preview
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(Array(testItems.prefix(6).enumerated()), id: \.element.id) { index, item in
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(
                                        VStack {
                                            Image(systemName: item.cover?.type == "VIDEO" ? "video.fill" : "photo.fill")
                                                .font(.title2)
                                            Text("Item \(index + 1)")
                                                .font(.caption)
                                        }
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Features to Test:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Tap any grid tile to open the viewer")
                        Text("• Swipe left/right to navigate between posts")
                        Text("• Use navigation arrows for precise control")
                        Text("• Videos autoplay when in view")
                        Text("• Tap video to show/hide controls")
                        Text("• Mute/unmute video playback")
                        Text("• Infinite scroll loads more posts")
                        Text("• Close button returns to grid")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Feed Viewer Test")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $showingViewer) {
            ProfileFeedViewer(
                username: "test_user",
                initialItems: testItems,
                initialCursor: nil,
                isOpen: showingViewer,
                onClose: {
                    showingViewer = false
                },
                initialPostId: testItems.first?.id
            )
        }
    }
    
    private func loadTestData() {
        isLoading = true
        
        // Create mock test data
        testItems = [
            NormalizedProfileFeedItem(
                id: "test_1",
                caption: "This is a test post with an image. It demonstrates how the feed viewer displays content.",
                createdAt: "2024-01-15T10:30:00.000Z",
                cover: NormalizedCover(type: "IMAGE", url: "https://picsum.photos/400/400?random=1"),
                media: [
                    NormalizedMediaItem(
                        id: "media_1",
                        type: "IMAGE",
                        url: "https://picsum.photos/400/400?random=1",
                        thumbnailUrl: nil,
                        width: 400,
                        height: 400,
                        durationSec: nil
                    )
                ]
            ),
            NormalizedProfileFeedItem(
                id: "test_2",
                caption: "This is a video post. Videos should autoplay when they come into view and pause when you navigate away.",
                createdAt: "2024-01-14T15:45:00.000Z",
                cover: NormalizedCover(type: "VIDEO", url: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4"),
                media: [
                    NormalizedMediaItem(
                        id: "media_2",
                        type: "VIDEO",
                        url: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
                        thumbnailUrl: "https://picsum.photos/400/400?random=2",
                        width: 1280,
                        height: 720,
                        durationSec: 30
                    )
                ]
            ),
            NormalizedProfileFeedItem(
                id: "test_3",
                caption: "Another image post to test navigation between different types of content.",
                createdAt: "2024-01-13T09:20:00.000Z",
                cover: NormalizedCover(type: "IMAGE", url: "https://picsum.photos/400/400?random=3"),
                media: [
                    NormalizedMediaItem(
                        id: "media_3",
                        type: "IMAGE",
                        url: "https://picsum.photos/400/400?random=3",
                        thumbnailUrl: nil,
                        width: 400,
                        height: 400,
                        durationSec: nil
                    )
                ]
            ),
            NormalizedProfileFeedItem(
                id: "test_4",
                caption: "A post without any media content. This tests the placeholder display.",
                createdAt: "2024-01-12T14:10:00.000Z",
                cover: nil,
                media: []
            ),
            NormalizedProfileFeedItem(
                id: "test_5",
                caption: "Final test post with a longer caption to test how the viewer handles text content that might wrap to multiple lines. This should display properly in the viewer interface.",
                createdAt: "2024-01-11T11:55:00.000Z",
                cover: NormalizedCover(type: "IMAGE", url: "https://picsum.photos/400/400?random=5"),
                media: [
                    NormalizedMediaItem(
                        id: "media_5",
                        type: "IMAGE",
                        url: "https://picsum.photos/400/400?random=5",
                        thumbnailUrl: nil,
                        width: 400,
                        height: 400,
                        durationSec: nil
                    )
                ]
            )
        ]
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
        }
    }
}

#Preview {
    ProfileFeedViewerTestView()
}
































