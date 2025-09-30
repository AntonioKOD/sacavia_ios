import SwiftUI
import AVFoundation

/// A lightweight container that renders an AVPlayer without any system controls,
/// similar to Instagram's inline video. Uses AVPlayerLayer under the hood.
struct PlayerContainerView: View {
    let player: AVPlayer
    
    var body: some View {
        PlayerLayerRepresentable(player: player)
            .background(Color.black)
            .clipped()
    }
}

private struct PlayerLayerRepresentable: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerContainerUIView {
        let view = PlayerContainerUIView()
        view.backgroundColor = .black
        view.player = player
        return view
    }
    
    func updateUIView(_ uiView: PlayerContainerUIView, context: Context) {
        // Keep the same instance but update the player if it changes
        if uiView.player !== player {
            uiView.player = player
        }
    }
}

private final class PlayerContainerUIView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    
    var player: AVPlayer? {
        get { playerLayer.player }
        set {
            playerLayer.player = newValue
            playerLayer.videoGravity = .resizeAspectFill // Fill like Instagram
        }
    }
}
