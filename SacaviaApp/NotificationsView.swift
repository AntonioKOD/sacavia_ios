import SwiftUI

// MARK: - Notifications View
struct NotificationsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var selectedFilter: NotificationFilter = .all
    @State private var isLoading = false
    @State private var showingMarkAllAlert = false
    @Environment(\.dismiss) private var dismiss
    
    // App colors
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    private let backgroundColor = Color(red: 249/255, green: 250/255, blue: 251/255) // #F9FAFB
    private let mutedTextColor = Color(red: 107/255, green: 114/255, blue: 128/255) // #6B7280
    
    enum NotificationFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case shares = "Shares"
        case tags = "Tags"
        case likes = "Likes"
        case comments = "Comments"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with title and actions
                headerView
                
                // Filter tabs
                filterTabsView
                
                // Notifications content
                if isLoading {
                    loadingView
                } else if filteredNotifications.isEmpty {
                    emptyView
                } else {
                    notificationsList
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [backgroundColor, Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
        }
        .onAppear {
            notificationManager.refreshNotifications()
            // Debug: Print notification data
            print("📱 [NotificationsView] Loaded \(notificationManager.notifications.count) notifications")
            for notification in notificationManager.notifications {
                print("📱 [NotificationsView] Notification: \(notification.type) - \(notification.message)")
                if let data = notification.data {
                    print("📱 [NotificationsView] Data: locationId=\(data.locationId ?? "nil"), locationName=\(data.locationName ?? "nil"), shareId=\(data.shareId ?? "nil")")
                }
            }
        }
        .alert("Mark All as Read", isPresented: $showingMarkAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Mark All", role: .destructive) {
                Task {
                    await notificationManager.markAllAsRead()
                }
            }
        } message: {
            Text("Are you sure you want to mark all notifications as read?")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Back button
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(primaryColor)
            }
            
            Spacer()
            
            Text("Notifications")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            if notificationManager.unreadCount > 0 {
                Button(action: { showingMarkAllAlert = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Mark All")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(primaryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(primaryColor.opacity(0.25), lineWidth: 1)
                    )
                }
            } else {
                // Invisible spacer to balance the layout when no "Mark All" button
                Text("")
                    .font(.subheadline)
                    .opacity(0)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .overlay(Divider().opacity(0.08), alignment: .bottom)
    }
    
    // MARK: - Filter Tabs View
    private var filterTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(NotificationFilter.allCases, id: \.self) { filter in
                    FilterTabView(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        unreadCount: filter == .unread ? notificationManager.unreadCount : nil,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(primaryColor)
                .scaleEffect(1.3)
            
            Text("Loading notifications...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [primaryColor.opacity(0.12), secondaryColor.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                    Image(systemName: "bell.slash")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(primaryColor)
                }
                VStack(spacing: 6) {
                    Text(emptyTitle)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(emptyMessage)
                        .font(.system(size: 14))
                        .foregroundColor(mutedTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
    }
    
    // MARK: - Notifications List
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredNotifications) { notification in
                    NotificationRowView(
                        notification: notification,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        mutedTextColor: mutedTextColor
                    ) {
                        handleNotificationTap(notification)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(Color.clear)
    }
    
    // MARK: - Computed Properties
    private var filteredNotifications: [AppNotification] {
        let notifications = notificationManager.notifications
        
        switch selectedFilter {
        case .all:
            return notifications
        case .unread:
            return notifications.filter { !$0.isRead }
        case .shares:
            return notifications.filter { $0.type == "location_shared" || $0.type == "location_share_reply" }
        case .tags:
            return notifications.filter { $0.type == "post_tagged" || $0.type == "review_tagged" }
        case .likes:
            return notifications.filter { $0.type == "like" }
        case .comments:
            return notifications.filter { $0.type == "comment" }
        }
    }
    
    private var emptyTitle: String {
        switch selectedFilter {
        case .all:
            return "No notifications yet"
        case .unread:
            return "All caught up!"
        case .shares:
            return "No shares yet"
        case .tags:
            return "No tags yet"
        case .likes:
            return "No likes yet"
        case .comments:
            return "No comments yet"
        }
    }
    
    private var emptyMessage: String {
        switch selectedFilter {
        case .all:
            return "When you get notifications about likes, comments, shares, and tags, they'll appear here."
        case .unread:
            return "You're all caught up! No unread notifications."
        case .shares:
            return "When someone shares a location with you, it'll appear here."
        case .tags:
            return "When someone tags you in a post or review, it'll appear here."
        case .likes:
            return "When someone likes your content, it'll appear here."
        case .comments:
            return "When someone comments on your content, it'll appear here."
        }
    }
    
    // MARK: - Actions
    private func handleNotificationTap(_ notification: AppNotification) {
        print("📱 [NotificationsView] Tapped notification: \(notification.type) - \(notification.message)")
        print("📱 [NotificationsView] Notification data: \(notification.data?.locationId ?? "nil")")
        print("📱 [NotificationsView] Full notification data: \(String(describing: notification.data))")
        
        // Mark as read if unread
        if !notification.isRead {
            Task {
                await notificationManager.markAsRead(notificationId: notification.id)
            }
        }
        
        // Handle navigation based on notification type
        switch notification.type {
        case "location_shared":
            // Navigate to location detail
            let locationId = notification.data?.locationId ?? notification.relatedTo?.value
            if let locationId = locationId {
                print("📱 [NotificationsView] Navigating to location: \(locationId)")
                // Close notifications sheet first
                dismiss()
                // Then navigate to location
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToLocation"),
                        object: nil,
                        userInfo: ["locationId": locationId]
                    )
                }
            }
        case "location_share_reply":
            // Navigate to location detail for reply
            let locationId = notification.data?.locationId ?? notification.relatedTo?.value
            if let locationId = locationId {
                print("📱 [NotificationsView] Navigating to location for reply: \(locationId)")
                // Close notifications sheet first
                dismiss()
                // Then navigate to location
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToLocation"),
                        object: nil,
                        userInfo: ["locationId": locationId]
                    )
                }
            }
        case "post_tagged":
            // Navigate to post detail
            if let postId = notification.data?.postId {
                print("📱 [NotificationsView] Navigating to tagged post: \(postId)")
                // Close notifications sheet first
                dismiss()
                // Then navigate to post
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToPost"),
                        object: nil,
                        userInfo: ["postId": postId]
                    )
                }
            }
        case "review_tagged":
            // Navigate to review detail
            if let reviewId = notification.data?.reviewId {
                print("📱 [NotificationsView] Navigating to tagged review: \(reviewId)")
                // Close notifications sheet first
                dismiss()
                // Then navigate to review
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToReview"),
                        object: nil,
                        userInfo: ["reviewId": reviewId]
                    )
                }
            }
        case "like", "comment":
            // Navigate to post detail
            if let postId = notification.data?.postId {
                print("📱 [NotificationsView] Navigating to post: \(postId)")
                // Close notifications sheet first
                dismiss()
                // Then navigate to post
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToPost"),
                        object: nil,
                        userInfo: ["postId": postId]
                    )
                }
            }
        default:
            print("📱 [NotificationsView] Unknown notification type: \(notification.type)")
        }
    }
}

// MARK: - Filter Tab View
struct FilterTabView: View {
    let filter: NotificationsView.NotificationFilter
    let isSelected: Bool
    let unreadCount: Int?
    let primaryColor: Color
    let secondaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                if let count = unreadCount, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(primaryColor)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isSelected {
                        LinearGradient(gradient: Gradient(colors: [primaryColor, secondaryColor]), startPoint: .leading, endPoint: .trailing)
                    } else {
                        Color.clear
                    }
                }
            )
            .background(
                Group {
                    if !isSelected { Color(.systemGray6) } else { Color.clear }
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.black.opacity(0.06), lineWidth: isSelected ? 0 : 1)
            )
            .shadow(color: isSelected ? primaryColor.opacity(0.2) : Color.clear, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notification: AppNotification
    let primaryColor: Color
    let secondaryColor: Color
    let mutedTextColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                // Card background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)

                // Unread accent bar
                if !notification.isRead {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(primaryColor.opacity(0.12))
                        .frame(maxWidth: .infinity)
                    Rectangle()
                        .fill(primaryColor)
                        .frame(width: 4)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }

                // Content
                HStack(spacing: 12) {
                    // Avatar
                    AsyncImage(url: URL(string: notification.sender?.avatar ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(LinearGradient(colors: [primaryColor.opacity(0.25), secondaryColor.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(LinearGradient(colors: [primaryColor, secondaryColor], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                    )

                    // Text content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(notification.sender?.name ?? "Unknown")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(mutedTextColor.opacity(0.6))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.message)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(3)

                            // Location shares context
                            if notification.type == "location_shared" || notification.type == "location_share_reply" {
                                if let locationName = notification.data?.locationName {
                                    HStack(spacing: 6) {
                                        Image(systemName: "location.fill")
                                            .font(.caption)
                                            .foregroundColor(secondaryColor)
                                        Text(locationName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(secondaryColor)
                                            .lineLimit(1)

                                        if let locationAddress = notification.data?.locationAddress, !locationAddress.isEmpty {
                                            Text("•")
                                                .font(.caption)
                                                .foregroundColor(mutedTextColor)
                                            Text(locationAddress)
                                                .font(.caption)
                                                .foregroundColor(mutedTextColor)
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(.top, 2)
                                }
                            }

                            // Reply context for share replies
                            if notification.type == "location_share_reply" {
                                if let replyMessage = notification.data?.replyMessage {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrowshape.turn.up.left.fill")
                                            .font(.caption)
                                            .foregroundColor(Color.orange)
                                        Text(replyMessage)
                                            .font(.caption)
                                            .foregroundColor(Color.orange)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }

                        HStack {
                            Text(formatDate(notification.createdAt))
                                .font(.caption)
                                .foregroundColor(mutedTextColor)

                            Spacer()

                            if notification.type == "location_shared" {
                                HStack(spacing: 8) {
                                    // Quick Reply button (unchanged action)
                                    Button(action: {
                                        // Handle reply action
                                        print("📱 [NotificationsView] Reply button tapped")
                                        print("📱 [NotificationsView] Available data: locationId=\(notification.data?.locationId ?? "nil"), shareId=\(notification.data?.shareId ?? "nil"), locationName=\(notification.data?.locationName ?? "nil")")
                                        print("📱 [NotificationsView] RelatedTo: relationTo=\(notification.relatedTo?.relationTo ?? "nil"), value=\(notification.relatedTo?.value ?? "nil")")

                                        let locationId = notification.data?.locationId ?? notification.relatedTo?.value

                                        print("📱 [NotificationsView] Extracted locationId: '\(locationId ?? "nil")'")
                                        print("📱 [NotificationsView] shareId from data: '\(notification.data?.shareId ?? "nil")'")

                                        if let locationId = locationId,
                                           let shareId = notification.data?.shareId {
                                            print("📱 [NotificationsView] Posting OpenLocationShareReply with locationId='\(locationId)', shareId='\(shareId)'")
                                            NotificationCenter.default.post(
                                                name: NSNotification.Name("OpenLocationShareReply"),
                                                object: nil,
                                                userInfo: [
                                                    "locationId": locationId,
                                                    "shareId": shareId,
                                                    "locationName": notification.data?.locationName ?? "Location",
                                                    "senderName": notification.sender?.name ?? "Friend"
                                                ]
                                            )
                                        } else {
                                            print("📱 [NotificationsView] Missing required data for reply - locationId: \(locationId ?? "nil"), shareId: \(notification.data?.shareId ?? "nil")")
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrowshape.turn.up.left.fill")
                                                .font(.caption)
                                            Text("Quick Reply")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .clipShape(Capsule())
                                        .shadow(color: primaryColor.opacity(0.25), radius: 3, x: 0, y: 1)
                                    }

                                    // Notification type badge
                                    Text(notificationTypeBadge)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(notificationTypeColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(notificationTypeColor.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            } else {
                                Text(notificationTypeBadge)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(notificationTypeColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(notificationTypeColor.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var notificationTypeBadge: String {
        switch notification.type {
        case "location_shared":
            return "Share"
        case "location_share_reply":
            return "Reply"
        case "post_tagged":
            return "Tag"
        case "review_tagged":
            return "Tag"
        case "like":
            return "Like"
        case "comment":
            return "Comment"
        default:
            return "Notification"
        }
    }
    
    private var notificationTypeColor: Color {
        switch notification.type {
        case "location_shared":
            return secondaryColor
        case "location_share_reply":
            return Color.orange
        case "post_tagged", "review_tagged":
            return primaryColor
        case "like":
            return Color.red
        case "comment":
            return Color.blue
        default:
            return mutedTextColor
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = formatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        } else {
            // Fallback: try ISO8601 format
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: dateString) {
                let relativeFormatter = RelativeDateTimeFormatter()
                relativeFormatter.unitsStyle = .abbreviated
                return relativeFormatter.localizedString(for: date, relativeTo: Date())
            }
            return "Unknown"
        }
    }
}

#Preview {
        NotificationsView()
}
