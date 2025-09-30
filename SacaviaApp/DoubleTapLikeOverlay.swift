import SwiftUI

/// A reusable heart overlay that animates when `trigger` changes
/// and `isVisible` is true. Use for double-tap like feedback.
struct DoubleTapLikeOverlay: View {
    let trigger: Int
    let isVisible: Bool
    
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.0
    
    var body: some View {
        Group {
            if isVisible {
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(.red)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .onChange(of: trigger) { _, _ in
                        animate()
                    }
                    .onAppear { animate() }
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func animate() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            scale = 1.1
            opacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.25)) {
                scale = 0.9
                opacity = 0.0
            }
        }
    }
}
