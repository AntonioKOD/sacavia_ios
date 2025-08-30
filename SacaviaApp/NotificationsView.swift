import SwiftUI

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var unreadCount: Int = 0
    @Published var hasUnreadNotifications: Bool = false
    
    private init() {}
    
    func updateUnreadCount(_ count: Int) {
        DispatchQueue.main.async {
            self.unreadCount = count
            self.hasUnreadNotifications = count > 0
        }
    }
    
    func markAllAsRead() {
        DispatchQueue.main.async {
            self.unreadCount = 0
            self.hasUnreadNotifications = false
        }
    }
    
    func decrementUnreadCount() {
        DispatchQueue.main.async {
            if self.unreadCount > 0 {
                self.unreadCount -= 1
                self.hasUnreadNotifications = self.unreadCount > 0
            }
        }
    }
}

struct NotificationItem: Identifiable, Decodable {
    let id: String
    let title: String
    let message: String?
    let type: AnyCodable?
    var read: Bool // Changed from AnyCodable to Bool for easier handling
    let createdAt: AnyCodable?
    let metadata: AnyCodable?
    let actionBy: AnyCodable?
    let relatedTo: AnyCodable?
}

// Most permissive AnyCodable
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self.value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(self.value, context)
        }
    }
}

struct UserSummary: Decodable {
    let id: String?
    let name: String?
    // Add other fields as needed, all optional
}

struct RelatedTo: Decodable {
    let relationTo: String?
    // Use a generic value for now
    let value: CodableValue?
}

struct CodableValue: Codable {}

struct NotificationsData: Decodable {
    let notifications: [NotificationItem]
}

struct NotificationsResponse: Decodable {
    let data: NotificationsData
}

struct NotificationsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var notifications: [NotificationItem] = []
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var showingSettings = false
    @State private var markedAsReadIds: Set<String> = [] // Track which notifications have been marked as read
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // No filter tabs, just a simple header
                // Content area
                if isLoading {
                    VStack(spacing: 24) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(primaryColor.opacity(0.1))
                                .frame(width: 80, height: 80)
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(primaryColor)
                        }
                        Text("Loading notifications...")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else if let error = error {
                    VStack(spacing: 24) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(.orange)
                        }
                        Text("Oops! Something went wrong")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button(action: fetchNotifications) {
                            Text("Try Again")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(primaryColor)
                                .cornerRadius(25)
                        }
                        Spacer()
                    }
                } else if notifications.isEmpty {
                    VStack(spacing: 24) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(primaryColor.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "bell.slash")
                                .font(.system(size: 32))
                                .foregroundColor(primaryColor)
                        }
                        Text("No notifications yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("We'll notify you when something interesting happens!")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            notificationCardsView
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color(.systemGray6))
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { 
                        presentationMode.wrappedValue.dismiss() 
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(primaryColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if !notifications.isEmpty {
                            Button("Mark All Read") {
                                markAllNotificationsAsRead()
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(primaryColor)
                        }
                        
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(primaryColor)
                        }
                    }
                }
            }
            .onAppear {
                fetchNotifications()
            }
            .onDisappear {
                // Update the notification count when view disappears
                updateNotificationCount()
            }
                    .fullScreenCover(isPresented: $showingSettings) {
            NotificationSettingsView()
        }
        }
    }
    
    func fetchNotifications() {
        isLoading = true
        error = nil
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/notifications") else {
            self.error = "Invalid notifications URL"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = AuthManager.shared.token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, err in
            DispatchQueue.main.async {
                isLoading = false
                if let err = err {
                    self.error = err.localizedDescription
                    return
                }
                guard let data = data else {
                    self.error = "No data received"
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let decodedResponse = try decoder.decode(NotificationsResponse.self, from: data)
                    let notifs = decodedResponse.data.notifications
                    notifications = notifs
                    
                    // Mark unread notifications as read when view appears
                    for notification in notifications {
                        if !notification.read && !markedAsReadIds.contains(notification.id) {
                            markNotificationAsRead(id: notification.id)
                        }
                    }
                    
                    // Update notification count
                    updateNotificationCount()
                } catch {
                    self.error = error.localizedDescription
                }
            }
        }.resume()
    }
    
    func updateNotificationCount() {
        let unreadCount = notifications.filter { !$0.read }.count
        notificationManager.updateUnreadCount(unreadCount)
    }
    
    // Improved mark as read function with proper state management
    func markNotificationAsRead(id: String) {
        // Don't mark again if already marked
        guard !markedAsReadIds.contains(id) else { return }
        
        // Update local state immediately for better UX
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].read = true
        }
        markedAsReadIds.insert(id)
        
        // Update notification count
        updateNotificationCount()
        
        // Call backend
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/notifications/mark-read/")?.appendingPathComponent(id) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token = AuthManager.shared.token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to mark notification as read: \(error.localizedDescription)")
                    // Optionally revert the local state if the backend call failed
                    // For now, we'll keep the optimistic update for better UX
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Successfully marked notification \(id) as read")
                    } else {
                        print("Failed to mark notification as read: HTTP \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }
    
    // Mark all notifications as read
    func markAllNotificationsAsRead() {
        // Update local state immediately for better UX
        for index in notifications.indices {
            notifications[index].read = true
            markedAsReadIds.insert(notifications[index].id)
        }
        
        // Update notification count
        updateNotificationCount()
        
        // Call backend to mark all as read
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/notifications/mark-all-read") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token = AuthManager.shared.token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to mark all notifications as read: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Successfully marked all notifications as read")
                    } else {
                        print("Failed to mark all notifications as read: HTTP \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }

    // Computed property for notification cards
    var notificationCardsView: some View {
        ForEach(notifications.indices, id: \.self) { idx in
            NotificationCard(
                notification: notifications[idx],
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                isRead: notifications[idx].read
            ) {
                // Only mark as read if it's not already read
                if !notifications[idx].read {
                    markNotificationAsRead(id: notifications[idx].id)
                }
            }
        }
    }
}

// NotificationCard now takes isRead and onTap
struct NotificationCard: View {
    let notification: NotificationItem
    let primaryColor: Color
    let secondaryColor: Color
    let isRead: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 44, height: 44)
                    Image(systemName: iconForNotificationType)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(notification.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if let message = notification.message, !message.isEmpty {
                        Text(message)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    if let createdAt = notification.createdAt {
                        Text(formatTimeAgo(createdAt))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                if !isRead {
                    Circle()
                        .fill(primaryColor)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .onTapGesture {
            onTap()
        }
    }
    private var iconForNotificationType: String {
        let type = notification.type as? String ?? ""
        switch type {
        case "like": return "heart.fill"
        case "comment": return "bubble.left.fill"
        case "mention": return "at"
        case "follow": return "person.badge.plus"
        case "event": return "calendar"
        case "location": return "mappin.circle.fill"
        default: return "bell.fill"
        }
    }
    private var iconBackgroundColor: Color {
        let type = notification.type as? String ?? ""
        switch type {
        case "like": return .red
        case "comment": return .blue
        case "mention": return .orange
        case "follow": return .green
        case "event": return .purple
        case "location": return primaryColor
        default: return secondaryColor
        }
    }
    private func formatTimeAgo(_ createdAt: AnyCodable) -> String {
        // Extract the date string from AnyCodable
        guard let dateString = createdAt.value as? String else {
            return "Unknown time"
        }
        
        // Try multiple date formats to handle different server responses
        let dateFormatters = [
            // ISO 8601 with fractional seconds
            createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"),
            // ISO 8601 without fractional seconds
            createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ssZ"),
            // ISO 8601 with space instead of T
            createDateFormatter(format: "yyyy-MM-dd HH:mm:ssZ"),
            // Simple date format
            createDateFormatter(format: "yyyy-MM-dd HH:mm:ss"),
            // Fallback to ISO8601DateFormatter
            nil // Will use ISO8601DateFormatter
        ]
        
        for formatter in dateFormatters {
            if let formatter = formatter {
                if let date = formatter.date(from: dateString) {
                    return formatRelativeTime(from: date)
                }
            } else {
                // Use ISO8601DateFormatter as fallback
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let date = isoFormatter.date(from: dateString) {
                    return formatRelativeTime(from: date)
                }
                
                // Try without fractional seconds
                isoFormatter.formatOptions = [.withInternetDateTime]
                if let date = isoFormatter.date(from: dateString) {
                    return formatRelativeTime(from: date)
                }
            }
        }
        
        // If all parsing attempts fail, return the original string or a fallback
        print("Failed to parse date: \(dateString)")
        return "Recently"
    }
    
    private func createDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    private func formatRelativeTime(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        // Convert to different time units
        let minutes = Int(timeInterval / 60)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        let weeks = Int(timeInterval / 604800)
        let months = Int(timeInterval / 2592000)
        let years = Int(timeInterval / 31536000)
        
        // Return appropriate relative time string
        if years > 0 {
            return years == 1 ? "1 year ago" : "\(years) years ago"
        } else if months > 0 {
            return months == 1 ? "1 month ago" : "\(months) months ago"
        } else if weeks > 0 {
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else if days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
} 