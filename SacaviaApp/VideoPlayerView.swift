import SwiftUI
import AVKit

/**
 * VideoPlayerView - SwiftUI wrapper for robust video playback
 * 
 * Features:
 * - Uses VideoPlayerViewModel for robust playback
 * - Automatic retry on failure
 * - Proper error handling and user feedback
 * - Memory-efficient streaming
 * - Clean UI with loading and error states
 * 
 * Usage:
 * VideoPlayerView(videoUrl: URL(string: "https://sacavia.com/api/media/file/video.mp4")!)
 */

struct VideoPlayerView: View {
    // MARK: - Properties
    let videoUrl: URL
    let enableAutoplay: Bool
    let enableAudio: Bool
    let loop: Bool
    
    @StateObject private var viewModel: VideoPlayerViewModel
    @State private var showControls = false
    
    // MARK: - Initialization
    init(
        videoUrl: URL, 
        enableAutoplay: Bool = true, 
        enableAudio: Bool = true, 
        loop: Bool = true
    ) {
        self.videoUrl = videoUrl
        self.enableAutoplay = enableAutoplay
        self.enableAudio = enableAudio
        self.loop = loop
        
        // Initialize the view model with the video URL
        self._viewModel = StateObject(wrappedValue: VideoPlayerViewModel(
            videoUrl: videoUrl,
            enableAutoplay: enableAutoplay,
            enableAudio: enableAudio,
            loop: loop
        ))
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video Player
                if let player = viewModel.player, !viewModel.hasError {
                    PlayerContainerView(player: player)
                        .onTapGesture {
                            toggleControls()
                        }
                        .onAppear {
                            print("🎥 [VideoPlayerView] VideoPlayer appeared")
                        }
                        .onDisappear {
                            print("🎥 [VideoPlayerView] VideoPlayer disappeared")
                        }
                } else if viewModel.isLoading || viewModel.isRetrying {
                    // Loading state
                    loadingView
                } else if viewModel.hasError {
                    // Error state with retry option
                    errorView
                }
                
                // Play/Pause overlay (only show when video is loaded and not playing)
                if let _ = viewModel.player, 
                   !viewModel.hasError, 
                   !viewModel.isLoading, 
                   !viewModel.isPlaying {
                    playButtonOverlay
                }
                
                // Retry indicator
                if viewModel.isRetrying {
                    retryIndicator
                }
            }
        }
        .onAppear {
            print("🎥 [VideoPlayerView] View appeared")
        }
        .onDisappear {
            print("🎥 [VideoPlayerView] View disappeared")
            // Note: We don't cleanup here as the view model handles its own lifecycle
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .foregroundColor(.white)
            
            Text(viewModel.isRetrying ? "Retrying..." : "Loading video...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            if viewModel.retryCount > 0 {
                Text("Attempt \(viewModel.retryCount) of \(viewModel.maxRetries)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash")
                .font(.system(size: 40))
                .foregroundColor(.red.opacity(0.7))
            
            Text(viewModel.errorMessage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if viewModel.retryCount < viewModel.maxRetries {
                Button("Try Again") {
                    print("🎥 [VideoPlayerView] User requested retry")
                    viewModel.retry()
                }
                .foregroundColor(.blue)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
            } else {
                Text("Max retries reached")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
    }
    
    // MARK: - Play Button Overlay
    private var playButtonOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    print("🎥 [VideoPlayerView] Play button tapped")
                    viewModel.togglePlayPause()
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Retry Indicator
    private var retryIndicator: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                    
                    Text("Retrying...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                .padding(.top, 20)
                .padding(.trailing, 20)
            }
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
    }
}

// MARK: - Preview
#Preview {
    VideoPlayerView(
        videoUrl: URL(string: "https://sacavia.com/api/media/file/masons.steakhouse_1750884150_3663003369217883913_65761546932-11.mp4")!,
        enableAutoplay: true,
        enableAudio: true,
        loop: true
    )
    .frame(height: 300)
    .background(Color.black)
}

// MARK: - Enhanced Video Player with Intersection Observer
/**
 * AutoplayVideoPlayer - Instagram-style autoplay based on scroll position
 * 
 * Features:
 * - Automatically plays when in view
 * - Pauses and mutes when out of view (Instagram-style behavior)
 * - Resets video to beginning when going out of view
 * - Optimized for feed-style scrolling
 */

struct AutoplayVideoPlayer: View {
    let videoUrl: URL
    let enableAudio: Bool
    let loop: Bool
    
    @State private var isInView = false
    @StateObject private var viewModel: VideoPlayerViewModel
    
    init(
        videoUrl: URL,
        enableAudio: Bool = true,
        loop: Bool = true
    ) {
        self.videoUrl = videoUrl
        self.enableAudio = enableAudio
        self.loop = loop
        
        // Initialize view model with autoplay disabled initially
        self._viewModel = StateObject(wrappedValue: VideoPlayerViewModel(
            videoUrl: videoUrl,
            enableAutoplay: false,
            enableAudio: enableAudio,
            loop: loop
        ))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video Player
                if let player = viewModel.player, !viewModel.hasError {
                    PlayerContainerView(player: player)
                        .onTapGesture {
                            // Toggle play/pause on tap
                            viewModel.togglePlayPause()
                        }
                } else if viewModel.isLoading || viewModel.isRetrying {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        if viewModel.isRetrying {
                            Text("Retrying...")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                } else if viewModel.hasError {
                    // Error state
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Failed to load video")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        if viewModel.retryCount < viewModel.maxRetries {
                            Button("Try Again") {
                                viewModel.retry()
                            }
                            .foregroundColor(.blue)
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
                
                if let player = viewModel.player, !viewModel.hasError {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                player.isMuted.toggle()
                                print("🎥 [AutoplayVideoPlayer] Toggled mute: \(player.isMuted)")
                            }) {
                                Image(systemName: player.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                        }
                        Spacer()
                    }
                }
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ViewOffsetKey.self, value: geometry.frame(in: .named("scroll")).minY)
            }
        )
        .onPreferenceChange(ViewOffsetKey.self) { offset in
            // Instagram-style intersection detection
            let screenHeight = UIScreen.main.bounds.height
            let isVisible = offset > -screenHeight * 0.2 && offset < screenHeight * 0.8
            
            if isVisible != isInView {
                isInView = isVisible
                print("🎥 [AutoplayVideoPlayer] Visibility changed: \(isInView), offset: \(offset), screenHeight: \(screenHeight)")
                
                if isInView {
                    // Video came into view - play with audio
                    print("🎥 [AutoplayVideoPlayer] Video in view - playing with audio")
                    if let player = viewModel.player {
                        player.isMuted = !enableAudio  // Set audio state based on enableAudio
                        player.play()
                        print("🎥 [AutoplayVideoPlayer] Player muted: \(player.isMuted), enableAudio: \(enableAudio)")
                    }
                } else {
                    // Video went out of view - pause, mute, and reset (Instagram-style)
                    print("🎥 [AutoplayVideoPlayer] Video out of view - pausing, muting, and resetting")
                    if let player = viewModel.player {
                        player.pause()
                        player.isMuted = true
                        player.seek(to: .zero)
                    }
                }
            }
        }
        .onAppear {
            print("🎥 [AutoplayVideoPlayer] View appeared")
            // If video is in view when it first appears, start playing
            if isInView {
                print("🎥 [AutoplayVideoPlayer] Video in view on appear - starting playback")
                if let player = viewModel.player {
                    player.isMuted = !enableAudio
                    player.play()
                    print("🎥 [AutoplayVideoPlayer] Player muted: \(player.isMuted), enableAudio: \(enableAudio)")
                }
            }
        }
        .onDisappear {
            print("🎥 [AutoplayVideoPlayer] View disappeared - cleaning up")
            // Clean up when view disappears completely
            if let player = viewModel.player {
                player.pause()
                player.isMuted = true
                player.seek(to: .zero)
            }
        }
    }
}

// MARK: - Preference Key for View Offset
struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
