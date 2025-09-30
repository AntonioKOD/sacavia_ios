import SwiftUI
import UIKit
import LinkPresentation

// MARK: - Share Types
enum ShareType {
    case location(Location)
    case post(ProfilePost)
    case achievement(String, String) // title, description
    case app
}

// MARK: - Share Content
struct ShareContent {
    let title: String
    let message: String
    let url: String
    let image: UIImage?
    let hashtags: [String]
}

// MARK: - Social Share Manager
class SocialShareManager: ObservableObject {
    static let shared = SocialShareManager()
    
    private init() {}
    
    // MARK: - Generate Share Content
    func generateShareContent(for type: ShareType, user: AuthUser?) -> ShareContent {
        switch type {
        case .location(let location):
            return generateLocationShareContent(location: location, user: user)
        case .post(let post):
            return generatePostShareContent(post: post, user: user)
        case .achievement(let title, let description):
            return generateAchievementShareContent(title: title, description: description, user: user)
        case .app:
            return generateAppShareContent(user: user)
        }
    }
    
    private func generateLocationShareContent(location: Location, user: AuthUser?) -> ShareContent {
        let userName = user?.name ?? "I"
        let title = "\(userName) discovered an amazing place!"
        let message = "Check out \(location.name) on Sacavia! \(location.shortDescription ?? "An incredible location worth visiting.")"
        let url = "https://sacavia.com/locations/\(location.id)"
        let hashtags = ["#Sacavia", "#Discover", "#Travel", "#Local"]
        
        return ShareContent(
            title: title,
            message: message,
            url: url,
            image: nil, // Will be generated from location image
            hashtags: hashtags
        )
    }
    
    private func generatePostShareContent(post: ProfilePost, user: AuthUser?) -> ShareContent {
        let userName = user?.name ?? "I"
        let title = "\(userName) shared a moment on Sacavia!"
        let message = "\(post.caption ?? "Check out this amazing moment!")"
        let url = "https://sacavia.com/u/\(user?.username ?? "user")/p/\(post.id)"
        let hashtags = ["#Sacavia", "#Moment", "#Share"]
        
        return ShareContent(
            title: title,
            message: message,
            url: url,
            image: nil, // Will be generated from post image
            hashtags: hashtags
        )
    }
    
    private func generateAchievementShareContent(title: String, description: String, user: AuthUser?) -> ShareContent {
        let userName = user?.name ?? "I"
        let shareTitle = "\(userName) just achieved: \(title)!"
        let message = "\(description) Join me on Sacavia to discover amazing places!"
        let url = "https://sacavia.com/achievements"
        let hashtags = ["#Sacavia", "#Achievement", "#Milestone"]
        
        return ShareContent(
            title: shareTitle,
            message: message,
            url: url,
            image: nil,
            hashtags: hashtags
        )
    }
    
    private func generateAppShareContent(user: AuthUser?) -> ShareContent {
        let userName = user?.name ?? "I"
        let title = "\(userName) loves using Sacavia!"
        let message = "Discover amazing places and connect with your community. Join me on Sacavia!"
        let url = "https://sacavia.com/download"
        let hashtags = ["#Sacavia", "#Discover", "#Community", "#Travel"]
        
        return ShareContent(
            title: title,
            message: message,
            url: url,
            image: nil,
            hashtags: hashtags
        )
    }
    
    // MARK: - Share Methods
    func shareLocation(_ location: Location, from view: UIViewController) {
        let content = generateShareContent(for: .location(location), user: AuthManager.shared.user)
        presentShareSheet(content: content, from: view)
    }
    
    func sharePost(_ post: ProfilePost, from view: UIViewController) {
        let content = generateShareContent(for: .post(post), user: AuthManager.shared.user)
        presentShareSheet(content: content, from: view)
    }
    
    func shareAchievement(title: String, description: String, from view: UIViewController) {
        let content = generateShareContent(for: .achievement(title, description), user: AuthManager.shared.user)
        presentShareSheet(content: content, from: view)
    }
    
    func shareApp(from view: UIViewController) {
        let content = generateShareContent(for: .app, user: AuthManager.shared.user)
        presentShareSheet(content: content, from: view)
    }
    
    // MARK: - Present Share Sheet
    private func presentShareSheet(content: ShareContent, from viewController: UIViewController) {
        var activityItems: [Any] = []
        
        // Add message
        let fullMessage = "\(content.message)\n\n\(content.url)\n\n\(content.hashtags.joined(separator: " "))"
        activityItems.append(fullMessage)
        
        // Add URL
        if let url = URL(string: content.url) {
            activityItems.append(url)
        }
        
        // Add image if available
        if let image = content.image {
            activityItems.append(image)
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Track sharing analytics
        trackShareEvent(content: content)
        
        viewController.present(activityViewController, animated: true)
    }
    
    // MARK: - Analytics
    private func trackShareEvent(content: ShareContent) {
        // Track sharing event for analytics
        print("📊 [SocialShare] User shared: \(content.title)")
        // TODO: Implement analytics tracking
    }
}

// MARK: - Share Button View
struct ShareButton: View {
    let shareType: ShareType
    let location: Location?
    let post: ProfilePost?
    let achievementTitle: String?
    let achievementDescription: String?
    
    @State private var showingShareSheet = false
    
    // Colors
    private let primaryColor = Color(red: 0.0, green: 0.5, blue: 1.0)
    private let secondaryColor = Color(red: 0.0, green: 0.8, blue: 0.6)
    
    init(location: Location) {
        self.shareType = .location(location)
        self.location = location
        self.post = nil
        self.achievementTitle = nil
        self.achievementDescription = nil
    }
    
    init(post: ProfilePost) {
        self.shareType = .post(post)
        self.location = nil
        self.post = post
        self.achievementTitle = nil
        self.achievementDescription = nil
    }
    
    init(achievementTitle: String, achievementDescription: String) {
        self.shareType = .achievement(achievementTitle, achievementDescription)
        self.location = nil
        self.post = nil
        self.achievementTitle = achievementTitle
        self.achievementDescription = achievementDescription
    }
    
    init(app: Bool) {
        self.shareType = .app
        self.location = nil
        self.post = nil
        self.achievementTitle = nil
        self.achievementDescription = nil
    }
    
    var body: some View {
        Button(action: {
            showingShareSheet = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                Text("Share")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: primaryColor.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheetView(shareType: shareType)
        }
    }
}

// MARK: - Share Sheet View
struct ShareSheetView: UIViewControllerRepresentable {
    let shareType: ShareType
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let shareManager = SocialShareManager.shared
        let content = shareManager.generateShareContent(for: shareType, user: AuthManager.shared.user)
        
        var activityItems: [Any] = []
        
        // Add message
        let fullMessage = "\(content.message)\n\n\(content.url)\n\n\(content.hashtags.joined(separator: " "))"
        activityItems.append(fullMessage)
        
        // Add URL
        if let url = URL(string: content.url) {
            activityItems.append(url)
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Share Card Generator
class ShareCardGenerator {
    static func generateLocationCard(location: Location, user: User?) -> UIImage? {
        // Create a beautiful shareable card for the location
        let cardSize = CGSize(width: 1200, height: 630) // Optimal for social media
        let renderer = UIGraphicsImageRenderer(size: cardSize)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Background gradient
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor,
                    UIColor(red: 0.0, green: 0.8, blue: 0.6, alpha: 1.0).cgColor
                ] as CFArray,
                locations: [0.0, 1.0]
            )!
            
            cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: cardSize.width, y: cardSize.height),
                options: []
            )
            
            // Add location name
            let titleText = location.name
            let titleFont = UIFont.systemFont(ofSize: 48, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.white
            ]
            
            let titleSize = titleText.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (cardSize.width - titleSize.width) / 2,
                y: cardSize.height / 2 - 60,
                width: titleSize.width,
                height: titleSize.height
            )
            
            titleText.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Add app branding
            let appText = "Discover on Sacavia"
            let appFont = UIFont.systemFont(ofSize: 24, weight: .medium)
            let appAttributes: [NSAttributedString.Key: Any] = [
                .font: appFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            
            let appSize = appText.size(withAttributes: appAttributes)
            let appRect = CGRect(
                x: (cardSize.width - appSize.width) / 2,
                y: cardSize.height / 2 + 20,
                width: appSize.width,
                height: appSize.height
            )
            
            appText.draw(in: appRect, withAttributes: appAttributes)
        }
    }
    
    static func generatePostCard(post: ProfilePost, user: User?) -> UIImage? {
        // Create a beautiful shareable card for the post
        let cardSize = CGSize(width: 1200, height: 630)
        let renderer = UIGraphicsImageRenderer(size: cardSize)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            cgContext.setFillColor(UIColor.systemBackground.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: cardSize))
            
            // Add post content
            let captionText = post.caption ?? "Check out this moment!"
            let captionFont = UIFont.systemFont(ofSize: 36, weight: .medium)
            let captionAttributes: [NSAttributedString.Key: Any] = [
                .font: captionFont,
                .foregroundColor: UIColor.label
            ]
            
            let captionSize = captionText.size(withAttributes: captionAttributes)
            let captionRect = CGRect(
                x: (cardSize.width - captionSize.width) / 2,
                y: cardSize.height / 2 - 30,
                width: captionSize.width,
                height: captionSize.height
            )
            
            captionText.draw(in: captionRect, withAttributes: captionAttributes)
            
            // Add app branding
            let appText = "Shared on Sacavia"
            let appFont = UIFont.systemFont(ofSize: 20, weight: .medium)
            let appAttributes: [NSAttributedString.Key: Any] = [
                .font: appFont,
                .foregroundColor: UIColor.secondaryLabel
            ]
            
            let appSize = appText.size(withAttributes: appAttributes)
            let appRect = CGRect(
                x: (cardSize.width - appSize.width) / 2,
                y: cardSize.height / 2 + 40,
                width: appSize.width,
                height: appSize.height
            )
            
            appText.draw(in: appRect, withAttributes: appAttributes)
        }
    }
}
