import SwiftUI
import UserNotifications
import Foundation

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    private let baseAPIURL = "https://sacavia.com"
    
    private init() {
        // Note: Permission request is handled by PushNotificationManager to avoid conflicts
        print("📱 [NotificationManager] Initialized - permission handled by PushNotificationManager")
    }
    
    // MARK: - Fetch Notifications
    func fetchNotifications() async {
        guard let user = AuthManager.shared.user,
              let token = AuthManager.shared.token else {
            print("📱 No user or token available for notifications")
            return
        }
        
        print("📱 Fetching notifications for user: \(user.name ?? "Unknown")")
        print("📱 Using token: \(String(token.prefix(20)))...")
        
        let url = URL(string: "\(baseAPIURL)/api/notifications")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 Notification API Response Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    let notificationResponse = try JSONDecoder().decode(NotificationListResponse.self, from: data)
                    print("📱 Fetched \(notificationResponse.notifications.count) notifications")
                    print("📱 Unread count: \(notificationResponse.unreadCount)")
                    
                DispatchQueue.main.async {
                    print("📱 Successfully fetched \(notificationResponse.notifications.count) notifications")
                    self.notifications = notificationResponse.notifications
                    self.updateUnreadCount()
                    print("📱 Updated notifications array with \(self.notifications.count) items")
                    print("📱 Updated unread count to \(self.unreadCount)")
                }
                } else {
                    print("📱 API Error: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📱 Response: \(responseString)")
                    }
                }
            }
        } catch {
            print("📱 Error fetching notifications: \(error)")
        }
    }
    
    // MARK: - Mark as Read
    func markAsRead(notificationId: String) async {
        guard let token = AuthManager.shared.token else {
            return
        }
        
        let url = URL(string: "\(baseAPIURL)/api/notifications")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["notificationId": notificationId] as [String: Any]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    if let index = self.notifications.firstIndex(where: { $0.id == notificationId }) {
                        self.notifications[index].isRead = true
                        self.updateUnreadCount()
                    }
                }
            }
        } catch {
            print("Error marking notification as read: \(error)")
        }
    }
    
    // MARK: - Mark All as Read
    func markAllAsRead() async {
        guard let token = AuthManager.shared.token else {
            return
        }
        
        let url = URL(string: "\(baseAPIURL)/api/notifications")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["markAllRead": true] as [String: Any]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    for index in self.notifications.indices {
                        self.notifications[index].isRead = true
                    }
                    self.updateUnreadCount()
                }
            }
        } catch {
            print("Error marking all notifications as read: \(error)")
        }
    }
    
    // MARK: - Delete Notification
    func deleteNotification(notificationId: String) async {
        guard let token = AuthManager.shared.token else {
            return
        }
        
        let url = URL(string: "\(baseAPIURL)/api/notifications?id=\(notificationId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self.notifications.removeAll { $0.id == notificationId }
                    self.updateUnreadCount()
                }
            }
        } catch {
            print("Error deleting notification: \(error)")
        }
    }
    
    // MARK: - Local Notifications
    func scheduleLocalNotification(title: String, body: String, userInfo: [String: Any] = [:]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    func refreshNotifications() {
        Task {
            await fetchNotifications()
        }
    }
}

// MARK: - Data Models
struct AppNotification: Identifiable, Codable {
    let id: String
    let type: String
    let title: String
    let message: String
    let data: NotificationData?
    var isRead: Bool
    let createdAt: String
    let sender: NotificationSender?
    let relatedTo: RelatedTo?
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, message, data, createdAt, relatedTo
        case isRead = "read"  // Map backend 'read' field to 'isRead'
        case sender = "actionBy"  // Map backend 'actionBy' field to 'sender'
    }
}

struct RelatedTo: Codable {
    let relationTo: String?
    let value: String?
}

struct NotificationData: Codable {
    let locationId: String?
    let locationName: String?
    let locationAddress: String?
    let locationCategory: String?
    let locationImage: String?
    let postId: String?
    let reviewId: String?
    let shareId: String?
    let senderName: String?
    let senderId: String?
    let messageType: String?
    let replyMessage: String?
    let replyType: String?
    let originalShareId: String?
    let replierName: String?
    let replierId: String?
    let originalSenderId: String?
}

struct NotificationSender: Codable {
    let id: String
    let name: String
    let avatar: String?
}

struct NotificationListResponse: Codable {
    let notifications: [AppNotification]
    let totalPages: Int
    let totalDocs: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
    let unreadCount: Int
}

