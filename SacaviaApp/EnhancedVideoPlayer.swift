import SwiftUI
import AVKit
import Combine

/**
 * EnhancedVideoPlayer - Legacy wrapper for backward compatibility
 * 
 * This is now a thin wrapper around the new robust VideoPlayerView
 * to maintain backward compatibility while providing improved functionality.
 */

struct EnhancedVideoPlayer: View {
    let videoUrl: URL
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
        // Use the new robust VideoPlayerView
        VideoPlayerView(
            videoUrl: videoUrl,
            enableAutoplay: enableAutoplay,
            enableAudio: enableAudio,
            loop: loop
        )
    }
}

// MARK: - Legacy AutoplayVideoPlayer (now uses new components)
struct LegacyAutoplayVideoPlayer: View {
    let videoUrl: URL
    @State private var isInView = false
    
    var body: some View {
        // Use the new AutoplayVideoPlayer from VideoPlayerView.swift
        AutoplayVideoPlayer(
            videoUrl: videoUrl,
            enableAudio: true,
            loop: true
        )
    }
}

// MARK: - Note: ViewOffsetKey is defined in VideoPlayerView.swift 