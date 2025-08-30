//
//  ScalingModifiers.swift
//  SacaviaApp
//
//  Created for fixing iPad scaling issues
//

import SwiftUI

// MARK: - iPad Scaling Modifier
/// Prevents content from stretching too much horizontally on iPad by adding appropriate margins
struct AddResponsiveSpace: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .safeAreaPadding(.horizontal, horizontalPadding(for: geometry.size.width))
        }
    }
    
    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        // Based on research: Add padding for larger screens to prevent stretching
        if width > 1100 {
            return 200 // Large iPad screens
        } else if width > 800 {
            return 100 // Regular iPad screens
        } else {
            return 0 // iPhone screens
        }
    }
}

// MARK: - Device-Specific Content Modifier
/// Provides device-specific content handling for better scaling
struct DeviceSpecificContent: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                #if DEBUG
                print("Size Classes - H: \(horizontalSizeClass?.description ?? "nil"), V: \(verticalSizeClass?.description ?? "nil")")
                print("Device: \(UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone")")
                #endif
            }
    }
}

// MARK: - Launch Screen Aware Modifier
/// Ensures proper scaling behavior by being aware of launch screen state
struct LaunchScreenAware: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Ensure native resolution is used
                if UIDevice.current.userInterfaceIdiom == .pad {
                    // iPad-specific optimizations
                    NotificationCenter.default.post(name: .iPadOptimizationEnabled, object: nil)
                }
            }
    }
}

// MARK: - iPad Sheet Presentation Modifier
/// Ensures sheets appear as proper sheets on iPad instead of full-screen modals
struct iPadSheetPresentation: ViewModifier {
    let detents: Set<PresentationDetent>
    let showDragIndicator: Bool
    
    init(detents: Set<PresentationDetent> = [.medium, .large], showDragIndicator: Bool = true) {
        self.detents = detents
        self.showDragIndicator = showDragIndicator
    }
    
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .presentationDetents(detents)
                .presentationDragIndicator(showDragIndicator ? .visible : .hidden)
                .presentationCornerRadius(20)
                .presentationBackground(.regularMaterial)
                .presentationCompactAdaptation(.sheet)
                .interactiveDismissDisabled(false)
        } else {
            content
        }
    }
}

// MARK: - iPad Compact Sheet Modifier
/// For smaller sheets that should appear as compact sheets on iPad
struct iPadCompactSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(.regularMaterial)
                .presentationCompactAdaptation(.sheet)
                .interactiveDismissDisabled(false)
        } else {
            content
        }
    }
}

// MARK: - iPad Large Sheet Modifier
/// For full-screen sheets that should still appear as sheets on iPad
struct iPadLargeSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(.regularMaterial)
                .presentationCompactAdaptation(.sheet)
                .interactiveDismissDisabled(false)
        } else {
            content
        }
    }
}

// MARK: - iPad Full Screen Optimization
/// Optimizes full-screen views for iPad without adding excessive padding
struct iPadFullScreenOptimizedModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
        } else {
            content
        }
    }
}

// MARK: - iPad Content Optimization
/// Optimizes content views for iPad with appropriate spacing
struct iPadContentOptimizedModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            GeometryReader { geometry in
                content
                    .frame(maxWidth: min(geometry.size.width * 0.9, 800))
                    .frame(maxWidth: .infinity)
            }
        } else {
            content
        }
    }
}

// MARK: - iPad Full Screen Sheet Modifier
/// Forces full-screen content to appear as a large sheet on iPad
struct iPadFullScreenSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(.regularMaterial)
                .presentationCompactAdaptation(.sheet)
                .interactiveDismissDisabled(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            content
        }
    }
}

// MARK: - Simple iPad Sheet Modifier
/// Simple, direct approach for iPad sheet presentation
struct SimpleIPadSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(.regularMaterial)
        } else {
            content
        }
    }
}

// MARK: - iPad Signup Optimization
/// Specifically optimizes signup view for iPad to prevent content cutoff
struct iPadSignupOptimizedModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(.regularMaterial)
                .presentationCompactAdaptation(.sheet)
                .interactiveDismissDisabled(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 20)
                }
        } else {
            content
        }
    }
}

// MARK: - iPad Full Page Sheet Modifier
/// Makes modals appear as full-page sheets on iPad, taking up most of the screen
struct iPadFullPageSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .presentationDetents([.fraction(0.95)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(.regularMaterial)
                .presentationCompactAdaptation(.sheet)
                .interactiveDismissDisabled(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            content
        }
    }
}

// MARK: - iPad Ultra Full Page Sheet Modifier
/// Makes modals appear as ultra full-page sheets on iPad, taking up almost the entire screen
struct iPadUltraFullPageSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .presentationDetents([.fraction(0.98)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(.regularMaterial)
                .presentationCompactAdaptation(.sheet)
                .interactiveDismissDisabled(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            content
        }
    }
}

// MARK: - iPad Adaptive Full Page Sheet Modifier
/// Makes modals appear as adaptive full-page sheets on iPad with multiple detent options
struct iPadAdaptiveFullPageSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .presentationDetents([.large, .fraction(0.9), .fraction(0.95)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(.regularMaterial)
                .presentationCompactAdaptation(.sheet)
                .interactiveDismissDisabled(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            content
        }
    }
}

// MARK: - Direct Full Page Sheet Modifier
/// Applies full-page sheet presentation directly to sheet content
struct DirectFullPageSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentationDetents([.fraction(0.98)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
            .presentationBackground(.regularMaterial)
            .presentationCompactAdaptation(.sheet)
    }
}

// MARK: - Extension for Easy Use
extension View {
    /// Adds responsive horizontal spacing to prevent content stretching on larger screens
    func addResponsiveSpace() -> some View {
        modifier(AddResponsiveSpace())
    }
    
    /// Adds device-specific content handling
    func deviceSpecificContent() -> some View {
        modifier(DeviceSpecificContent())
    }
    
    /// Makes view aware of launch screen scaling requirements
    func launchScreenAware() -> some View {
        modifier(LaunchScreenAware())
    }
    
    /// Makes sheet appear as proper sheet on iPad with medium/large detents
    func iPadSheet() -> some View {
        modifier(iPadSheetPresentation())
    }
    
    /// Makes sheet appear as compact sheet on iPad
    func iPadCompactSheet() -> some View {
        modifier(iPadCompactSheetModifier())
    }
    
    /// Makes sheet appear as large sheet on iPad
    func iPadLargeSheet() -> some View {
        modifier(iPadLargeSheetModifier())
    }
    
    /// Custom sheet presentation with specific detents
    func iPadSheet(detents: Set<PresentationDetent>, showDragIndicator: Bool = true) -> some View {
        modifier(iPadSheetPresentation(detents: detents, showDragIndicator: showDragIndicator))
    }
    
    /// Optimizes full-screen views for iPad
    func iPadFullScreenOptimized() -> some View {
        modifier(iPadFullScreenOptimizedModifier())
    }
    
    /// Optimizes content views for iPad
    func iPadContentOptimized() -> some View {
        modifier(iPadContentOptimizedModifier())
    }
    
    /// Forces full-screen content to appear as a large sheet on iPad
    func iPadFullScreenSheet() -> some View {
        modifier(iPadFullScreenSheetModifier())
    }
    
    /// Specifically optimizes signup view for iPad to prevent content cutoff
    func iPadSignupOptimized() -> some View {
        modifier(iPadSignupOptimizedModifier())
    }
    
    /// Simple iPad sheet presentation
    func simpleIPadSheet() -> some View {
        modifier(SimpleIPadSheetModifier())
    }
    
    /// Makes modals appear as full-page sheets on iPad (95% of screen)
    func iPadFullPageSheet() -> some View {
        modifier(iPadFullPageSheetModifier())
    }
    
    /// Makes modals appear as ultra full-page sheets on iPad (98% of screen)
    func iPadUltraFullPageSheet() -> some View {
        modifier(iPadUltraFullPageSheetModifier())
    }
    
    /// Makes modals appear as adaptive full-page sheets on iPad with multiple detent options
    func iPadAdaptiveFullPageSheet() -> some View {
        modifier(iPadAdaptiveFullPageSheetModifier())
    }

    /// Applies full-page sheet presentation directly to sheet content
    func directFullPageSheet() -> some View {
        modifier(DirectFullPageSheetModifier())
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let iPadOptimizationEnabled = Notification.Name("iPadOptimizationEnabled")
}

// MARK: - UserInterfaceSizeClass Extension for Debugging
extension UserInterfaceSizeClass {
    var description: String {
        switch self {
        case .compact:
            return "compact"
        case .regular:
            return "regular"
        @unknown default:
            return "unknown"
        }
    }
}