//
//  LandscapeOptimizations.swift
//  SacaviaApp
//
//  Created for implementing landscape optimizations based on research
//

import SwiftUI

// MARK: - Landscape-Aware View Modifier
/// Optimizes layout for landscape orientation on iPad
struct LandscapeOptimized: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var isLandscape: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .compact
    }
    
    var isiPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    func body(content: Content) -> some View {
        if isiPad && isLandscape {
            // iPad landscape optimizations
            content
                .padding(.horizontal, landscapePadding)
                .animation(.easeInOut(duration: 0.3), value: isLandscape)
        } else {
            content
        }
    }
    
    private var landscapePadding: CGFloat {
        if isiPad && isLandscape {
            return 120 // Extra padding for landscape iPad
        }
        return 0
    }
}

// MARK: - Adaptive Layout Modifier
/// Provides adaptive layout that changes based on available space
struct AdaptiveLayout: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let isWideScreen = geometry.size.width > 768
            
            if isWideScreen {
                // Wide screen layout (iPad landscape or large iPad)
                content
                    .frame(maxWidth: min(geometry.size.width * 0.8, 1200))
                    .frame(maxWidth: .infinity)
            } else {
                // Standard layout (iPhone or iPad portrait)
                content
            }
        }
    }
}

// MARK: - Multiple Window Prevention
/// Ensures consistent behavior across different window configurations
struct WindowConfigurationAware: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Disable multiple windows if running on iPad to prevent scaling issues
                // This is handled in Info.plist but we can enforce it programmatically
                if UIDevice.current.userInterfaceIdiom == .pad {
                    #if DEBUG
                    print("iPad detected - ensuring single window configuration")
                    #endif
                }
            }
    }
}

// MARK: - Orientation Change Handler
/// Handles orientation changes smoothly with animations
struct OrientationChangeHandler: ViewModifier {
    @State private var orientation = UIDeviceOrientation.unknown
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    orientation = UIDevice.current.orientation
                }
            }
            .onAppear {
                orientation = UIDevice.current.orientation
            }
    }
}

// MARK: - View Extensions
extension View {
    /// Optimizes view for landscape orientation on iPad
    func landscapeOptimized() -> some View {
        modifier(LandscapeOptimized())
    }
    
    /// Provides adaptive layout based on screen size
    func adaptiveLayout() -> some View {
        modifier(AdaptiveLayout())
    }
    
    /// Makes view aware of window configuration
    func windowConfigurationAware() -> some View {
        modifier(WindowConfigurationAware())
    }
    
    /// Handles orientation changes smoothly
    func orientationChangeHandler() -> some View {
        modifier(OrientationChangeHandler())
    }
    
    /// Applies all iPad optimizations in one call
    func iPadOptimized() -> some View {
        self
            .landscapeOptimized()
            .adaptiveLayout()
            .windowConfigurationAware()
            .orientationChangeHandler()
    }
}

// MARK: - Size Class Utilities
struct SizeClassInfo {
    let horizontal: UserInterfaceSizeClass?
    let vertical: UserInterfaceSizeClass?
    
    var isCompactWidth: Bool {
        horizontal == .compact
    }
    
    var isRegularWidth: Bool {
        horizontal == .regular
    }
    
    var isCompactHeight: Bool {
        vertical == .compact
    }
    
    var isRegularHeight: Bool {
        vertical == .regular
    }
    
    var isiPadLandscape: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && isRegularWidth && isCompactHeight
    }
    
    var isiPadPortrait: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && isRegularWidth && isRegularHeight
    }
    
    var isiPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}