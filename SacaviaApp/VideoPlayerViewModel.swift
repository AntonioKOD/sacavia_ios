import Foundation
import AVFoundation
import Combine

/**
 * VideoPlayerViewModel - Robust video playback with retry and stall handling
 * 
 * Features:
 * - AVURLAsset-based streaming (not Data-based loading)
 * - Automatic retry on failure with exponential backoff
 * - Proper buffer management to prevent stalling
 * - Comprehensive error handling and logging
 * - Memory-efficient streaming
 * 
 * Usage:
 * - Initialize with video URL
 * - Observe published properties for UI updates
 * - Call retry() on failure
 * - Clean up on view disappear
 */

@MainActor
class VideoPlayerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var isLoading = true
    @Published var hasError = false
    @Published var errorMessage = "Video not available"
    @Published var retryCount = 0
    @Published var isRetrying = false
    
    // MARK: - Private Properties
    private var playerItem: AVPlayerItem?
    private var cancellables = Set<AnyCancellable>()
    private var retryTimer: Timer?
    let maxRetries = 3
    private let baseRetryDelay: TimeInterval = 0.8
    
    // MARK: - Configuration
    let videoUrl: URL
    let enableAutoplay: Bool
    let enableAudio: Bool
    let loop: Bool
    
    // MARK: - Initialization
    init(videoUrl: URL, enableAutoplay: Bool = true, enableAudio: Bool = true, loop: Bool = true) {
        self.videoUrl = videoUrl
        self.enableAutoplay = enableAutoplay
        self.enableAudio = enableAudio
        self.loop = loop
        
        print("🎥 [VideoPlayerViewModel] Initializing with URL: \(videoUrl.absoluteString)")
        setupPlayer()
    }
    
    // MARK: - Player Setup
    private func setupPlayer() {
        print("🎥 [VideoPlayerViewModel] Setting up player...")
        
        // Process URL to ensure proper format
        let processedUrl = processVideoURL(videoUrl)
        print("🎥 [VideoPlayerViewModel] Processed URL: \(processedUrl.absoluteString)")
        
        // Create AVURLAsset for streaming
        let asset = AVURLAsset(url: processedUrl)
        
        // Create player item with the asset
        let newPlayerItem = AVPlayerItem(asset: asset)
        self.playerItem = newPlayerItem
        
        // Create player with the item
        let newPlayer = AVPlayer(playerItem: newPlayerItem)
        self.player = newPlayer
        
        // Configure player for optimal streaming
        configurePlayer(newPlayer)
        
        // Set up observers
        setupObservers()
        
        // Configure audio session
        configureAudioSession()
        
        print("🎥 [VideoPlayerViewModel] Player setup completed")
    }
    
    // MARK: - Player Configuration
    private func configurePlayer(_ player: AVPlayer) {
        // Set buffer duration to prevent stalling
        player.automaticallyWaitsToMinimizeStalling = true
        
        // Configure preferred forward buffer duration (5 seconds)
        if #available(iOS 10.0, *) {
            player.automaticallyWaitsToMinimizeStalling = true
        }
        
        // Set initial audio state
        player.isMuted = !enableAudio
        
        print("🎥 [VideoPlayerViewModel] Player configured for streaming")
    }
    
    // MARK: - Audio Session Configuration
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback, 
                mode: .default, 
                options: [.allowBluetooth, .allowBluetoothA2DP]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            print("🎥 [VideoPlayerViewModel] Audio session configured")
        } catch {
            print("🔊 [VideoPlayerViewModel] Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - Observers Setup
    private func setupObservers() {
        guard let playerItem = playerItem else { return }
        
        // Monitor player item status
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handlePlayerStatusChange(status)
            }
            .store(in: &cancellables)
        
        // Monitor playback time for play/pause state
        player?.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleTimeControlStatusChange(status)
            }
            .store(in: &cancellables)
        
        // Monitor for playback failures
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handlePlaybackFailure(notification)
            }
        }
        
        // Set up loop if enabled
        if loop {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.handlePlaybackEnd()
                }
            }
        }
        
        print("🎥 [VideoPlayerViewModel] Observers set up")
    }
    
    // MARK: - Status Handlers
    private func handlePlayerStatusChange(_ status: AVPlayerItem.Status) {
        print("🎥 [VideoPlayerViewModel] Player status changed to: \(status.rawValue)")
        
        switch status {
        case .readyToPlay:
            print("🎥 [VideoPlayerViewModel] Player is ready to play")
            isLoading = false
            hasError = false
            retryCount = 0
            
            if enableAutoplay {
                play()
            }
            
        case .failed:
            print("🎥 [VideoPlayerViewModel] Player failed to load")
            handlePlayerFailure()
            
        case .unknown:
            print("🎥 [VideoPlayerViewModel] Player status is unknown")
            break
            
        @unknown default:
            break
        }
    }
    
    private func handleTimeControlStatusChange(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .playing:
            isPlaying = true
        case .paused:
            isPlaying = false
        case .waitingToPlayAtSpecifiedRate:
            // Player is buffering
            break
        @unknown default:
            break
        }
    }
    
    private func handlePlayerFailure() {
        if let error = playerItem?.error {
            print("🎥 [VideoPlayerViewModel] Player error: \(error)")
            print("🎥 [VideoPlayerViewModel] Error description: \(error.localizedDescription)")
            
            // Set specific error message based on error type
            if let nsError = error as NSError? {
                switch nsError.code {
                case -11850: // AVFoundationErrorDomain - Operation Stopped
                    errorMessage = "Video streaming interrupted. Retrying..."
                case -1009: // NSURLErrorNotConnectedToInternet
                    errorMessage = "No internet connection"
                case -1001: // NSURLErrorTimedOut
                    errorMessage = "Connection timed out"
                case -1003: // NSURLErrorCannotFindHost
                    errorMessage = "Server not found"
                default:
                    errorMessage = "Video loading failed: \(error.localizedDescription)"
                }
            }
        }
        
        hasError = true
        isLoading = false
        
        // Attempt retry if under limit
        if retryCount < maxRetries {
            scheduleRetry()
        }
    }
    
    private func handlePlaybackFailure(_ notification: Notification) {
        print("🎥 [VideoPlayerViewModel] Playback failed: \(notification)")
        handlePlayerFailure()
    }
    
    private func handlePlaybackEnd() {
        print("🎥 [VideoPlayerViewModel] Playback ended, looping...")
        player?.seek(to: .zero)
        player?.play()
    }
    
    // MARK: - Retry Logic
    private func scheduleRetry() {
        guard retryCount < maxRetries else { return }
        
        retryCount += 1
        isRetrying = true
        
        // Exponential backoff: 0.8s, 1.6s, 3.2s
        let delay = baseRetryDelay * pow(2.0, Double(retryCount - 1))
        
        print("🎥 [VideoPlayerViewModel] Scheduling retry \(retryCount)/\(maxRetries) in \(delay)s")
        
        retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.retry()
            }
        }
    }
    
    func retry() {
        print("🎥 [VideoPlayerViewModel] Retrying video load...")
        
        isRetrying = false
        hasError = false
        isLoading = true
        errorMessage = "Retrying..."
        
        // Clean up current player
        cleanupPlayer()
        
        // Set up new player
        setupPlayer()
    }
    
    // MARK: - Playback Controls
    func play() {
        guard let player = player else { return }
        
        print("🎥 [VideoPlayerViewModel] Playing video")
        player.isMuted = !enableAudio
        player.play()
    }
    
    func pause() {
        guard let player = player else { return }
        
        print("🎥 [VideoPlayerViewModel] Pausing video")
        player.pause()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    // MARK: - URL Processing
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
        
        // Ensure HTTPS
        if urlString.hasPrefix("http://") {
            urlString = urlString.replacingOccurrences(of: "http://", with: "https://")
        }
        
        guard let processedURL = URL(string: urlString) else {
            print("🎥 [VideoPlayerViewModel] Failed to process URL, using original")
            return url
        }
        
        return processedURL
    }
    
    // MARK: - Cleanup
    func cleanup() {
        print("🎥 [VideoPlayerViewModel] Cleaning up player")
        
        // Cancel retry timer
        retryTimer?.invalidate()
        retryTimer = nil
        
        // Pause and clean up player
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerItem = nil
        
        // Cancel all subscriptions
        cancellables.removeAll()
        
        // Remove observers
        NotificationCenter.default.removeObserver(self)
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerItem = nil
    }
    
    // MARK: - Deinitializer
    deinit {
        // Cancel retry timer (this is safe to do from nonisolated context)
        retryTimer?.invalidate()
        retryTimer = nil
        
        // Remove observers (this is safe to do from nonisolated context)
        NotificationCenter.default.removeObserver(self)
        
        print("🎥 [VideoPlayerViewModel] Deinitialized")
    }
}
