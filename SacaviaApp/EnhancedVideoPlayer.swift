import SwiftUI
import AVKit
import Combine

struct EnhancedVideoPlayer: View {
    let videoUrl: URL
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isLoading = true
    @State private var hasError = false
    @State private var isInView = false
    @State private var showControls = false
    @State private var playerItem: AVPlayerItem?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var errorMessage = "Video not available"
    
    // Audio and autoplay settings
    let enableAutoplay: Bool
    let enableAudio: Bool
    let loop: Bool
    
    init(videoUrl: URL, enableAutoplay: Bool = true, enableAudio: Bool = true, loop: Bool = true) {
        self.videoUrl = videoUrl
        self.enableAutoplay = enableAutoplay
        self.enableAudio = enableAudio
        self.loop = loop
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video Player
                if let player = player, !hasError {
                    VideoPlayer(player: player)
                        .onAppear {
                            print("🔍 [EnhancedVideoPlayer] VideoPlayer appeared")
                            setupAutoplay()
                        }
                        .onDisappear {
                            print("🔍 [EnhancedVideoPlayer] VideoPlayer disappeared")
                            pauseVideo()
                        }
                        .onTapGesture {
                            togglePlayPause()
                        }
                } else if isLoading {
                    // Loading state
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .foregroundColor(.white)
                        Text("Loading video...")
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 8)
                    }
                } else if hasError {
                    // Error state with detailed info
                    VStack(spacing: 8) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.red.opacity(0.7))
                        Text(errorMessage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button("Try Again") {
                            print("🔍 [EnhancedVideoPlayer] Retrying video load")
                            retryVideoLoad()
                        }
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.top, 4)
                    }
                }
                
                // Play/Pause overlay (only show when video is loaded and not playing)
                if let player = player, !hasError, !isLoading, !isPlaying {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: togglePlayPause) {
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
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanupPlayer()
        }
    }
    
    private func setupPlayer() {
        print("🔍 [EnhancedVideoPlayer] Setting up player for URL: \(videoUrl)")
        print("🔍 [EnhancedVideoPlayer] URL absolute string: \(videoUrl.absoluteString)")
        
        // Process URL to fix common issues
        let processedUrl = processVideoURL(videoUrl)
        print("🔍 [EnhancedVideoPlayer] Processed URL: \(processedUrl.absoluteString)")
        
        // Create player with audio enabled
        let playerItem = AVPlayerItem(url: processedUrl)
        self.playerItem = playerItem
        player = AVPlayer(playerItem: playerItem)
        
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("🔊 Failed to configure audio session: \(error)")
        }
        
        // Set up loop if enabled
        if loop {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { _ in
                player?.seek(to: .zero)
                player?.play()
            }
        }
        
        // Add observer for player item status
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            hasError = true
            isLoading = false
            errorMessage = "Video playback failed"
        }
        
        // Monitor player item status using Combine
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { status in
                print("🔍 [EnhancedVideoPlayer] Player status changed to: \(status.rawValue)")
                switch status {
                case .readyToPlay:
                    print("🔍 [EnhancedVideoPlayer] Player is ready to play")
                    isLoading = false
                    hasError = false
                    if enableAutoplay {
                        setupAutoplay()
                    }
                case .failed:
                    print("🔍 [EnhancedVideoPlayer] Player failed to load")
                    if let error = playerItem.error {
                        print("🔍 [EnhancedVideoPlayer] Player error: \(error)")
                        print("🔍 [EnhancedVideoPlayer] Player error description: \(error.localizedDescription)")
                        
                        // Set specific error message based on error type
                        if error.localizedDescription.contains("404") {
                            errorMessage = "Video not found"
                        } else if error.localizedDescription.contains("403") {
                            errorMessage = "Access denied"
                        } else if error.localizedDescription.contains("network") {
                            errorMessage = "Network error"
                        } else {
                            errorMessage = "Video loading failed"
                        }
                    }
                    if let playerError = player?.error {
                        print("🔍 [EnhancedVideoPlayer] AVPlayer error: \(playerError)")
                        print("🔍 [EnhancedVideoPlayer] AVPlayer error description: \(playerError.localizedDescription)")
                    }
                    hasError = true
                    isLoading = false
                case .unknown:
                    print("🔍 [EnhancedVideoPlayer] Player status is unknown")
                    break
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Set initial audio state
        player?.isMuted = !enableAudio
        
        isLoading = false
    }
    
    private func processVideoURL(_ url: URL) -> URL {
        var urlString = url.absoluteString
        
        // Fix common URL issues
        if urlString.contains("www.sacavia.com") {
            urlString = urlString.replacingOccurrences(of: "www.sacavia.com", with: "sacavia.com")
        }
        
        // Ensure proper API endpoint
        if urlString.contains("/api/media/") && !urlString.contains("/api/media/file/") {
            urlString = urlString.replacingOccurrences(of: "/api/media/", with: "/api/media/file/")
        }
        
        // Add proper headers for video streaming
        if let processedURL = URL(string: urlString) {
            return processedURL
        }
        
        return url
    }
    
    private func setupAutoplay() {
        guard enableAutoplay else { return }
        
        // Configure for autoplay with audio
        player?.isMuted = !enableAudio
        
        // Try to play with audio first
        player?.play()
        
        // If autoplay fails (common on iOS), try muted
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !isPlaying {
                player?.isMuted = true
                player?.play()
            }
        }
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            // Enable audio when user manually plays
            player.isMuted = !enableAudio
            player.play()
            isPlaying = true
        }
    }
    
    private func pauseVideo() {
        player?.pause()
        isPlaying = false
    }
    
    private func retryVideoLoad() {
        print("🔍 [EnhancedVideoPlayer] Retrying video load for URL: \(videoUrl)")
        hasError = false
        isLoading = true
        errorMessage = "Video not available"
        cleanupPlayer()
        setupPlayer()
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        playerItem = nil
        
        // Cancel all subscriptions
        cancellables.removeAll()
        
        // Remove observers
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Intersection Observer for TikTok-style Autoplay
struct AutoplayVideoPlayer: View {
    let videoUrl: URL
    @State private var isInView = false
    
    var body: some View {
        EnhancedVideoPlayer(
            videoUrl: videoUrl,
            enableAutoplay: isInView,
            enableAudio: true,
            loop: true
        )
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ViewOffsetKey.self, value: geometry.frame(in: .named("scroll")).minY)
            }
        )
        .onPreferenceChange(ViewOffsetKey.self) { offset in
            // Simple intersection detection
            let screenHeight = UIScreen.main.bounds.height
            let isVisible = offset > -screenHeight * 0.3 && offset < screenHeight * 0.7
            isInView = isVisible
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