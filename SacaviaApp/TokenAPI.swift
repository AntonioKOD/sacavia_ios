import Foundation
import UIKit

// MARK: - Token API Models
struct DeviceTokenRegistration: Codable {
    let deviceToken: String
    let userId: String?
    let platform: String
    let deviceInfo: TokenDeviceInfo?
    let topics: [String]?
}

// Dummy type for requests without a body
struct EmptyRequest: Codable {}

struct TokenDeviceInfo: Codable {
    let model: String?
    let os: String?
    let appVersion: String?
    let buildNumber: String?
    let deviceId: String?
}

struct TokenRegistrationResponse: Codable {
    let success: Bool
    let message: String
    let tokenId: String?
    let deviceToken: String?
    let platform: String?
    let isActive: Bool?
    let user: String?
    let topics: [TopicInfo]?
}

struct TopicInfo: Codable {
    let topic: String
    let subscribedAt: String
}

struct TopicSubscription: Codable {
    let deviceToken: String
    let topics: [String]
    let userId: String?
}

struct TopicUnsubscription: Codable {
    let deviceToken: String
    let topics: [String]
    let userId: String?
    let all: Bool?
}

struct TopicResponse: Codable {
    let success: Bool
    let message: String
    let deviceToken: String?
    let subscribedTopics: [String]?
    let unsubscribedTopics: [String]?
    let totalTopics: Int?
    let remainingTopics: Int?
}

struct NotificationPayload: Codable {
    let type: String // "token", "topic", or "user"
    let target: String // token string, topic string, or userId
    let notification: NotificationContent
    let data: [String: String]?
    let apns: APNsPayload?
}

struct NotificationContent: Codable {
    let title: String
    let body: String
    let imageUrl: String?
}

struct APNsPayload: Codable {
    let payload: [String: Any]?
    let headers: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case payload, headers
    }
    
    init(payload: [String: Any]?, headers: [String: String]?) {
        self.payload = payload
        self.headers = headers
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        payload = nil // Handle custom decoding if needed
        headers = try container.decodeIfPresent([String: String].self, forKey: .headers)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(headers, forKey: .headers)
        // Handle custom encoding for payload if needed
    }
}

struct NotificationResponse: Codable {
    let success: Bool
    let message: String
    let messageId: String?
    let type: String?
    let target: String?
    let sentCount: Int?
    let failedCount: Int?
    let totalTokens: Int?
    let totalDevices: Int?
    let results: [TokenResult]?
}

struct TokenResult: Codable {
    let tokenId: String?
    let deviceToken: String?
    let platform: String?
    let success: Bool
    let messageId: String?
    let error: String?
}

// MARK: - Token API Service
class TokenAPI: ObservableObject {
    static let shared = TokenAPI()
    
    private let baseURL: String
    private let session: URLSession
    
    @Published var isConnected = false
    @Published var lastError: String?
    
    private init() {
        // Use your web app's base URL
        // Use the same base URL configuration as the rest of the app
        self.baseURL = "\(baseAPIURL)/api"
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        // Test connection on initialization
        testConnection()
    }
    
    // MARK: - Connection Testing
    func testConnection() {
        let url = URL(string: "\(baseURL)/push/status")!
        
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isConnected = false
                    self?.lastError = error.localizedDescription
                    print("❌ [TokenAPI] Connection test failed: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    self?.isConnected = httpResponse.statusCode == 200
                    if httpResponse.statusCode != 200 {
                        self?.lastError = "HTTP \(httpResponse.statusCode)"
                    }
                    print("📱 [TokenAPI] Connection test: \(self?.isConnected == true ? "✅ Success" : "❌ Failed")")
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Device Token Registration
    func registerDeviceToken(
        deviceToken: String,
        userId: String? = nil,
        platform: String = "ios",
        deviceInfo: TokenDeviceInfo? = nil,
        topics: [String]? = nil
    ) async -> Result<TokenRegistrationResponse, Error> {
        
        let registration = DeviceTokenRegistration(
            deviceToken: deviceToken,
            userId: userId,
            platform: platform,
            deviceInfo: deviceInfo,
            topics: topics
        )
        
        return await performRequest(
            endpoint: "/push/register",
            method: "POST",
            body: registration
        )
    }
    
    // MARK: - Device Token Deactivation
    func deactivateDeviceToken(
        deviceToken: String,
        userId: String? = nil
    ) async -> Result<TokenRegistrationResponse, Error> {
        
        let deactivation = [
            "deviceToken": deviceToken,
            "userId": userId
        ].compactMapValues { $0 }
        
        return await performRequest(
            endpoint: "/push/register",
            method: "DELETE",
            body: deactivation
        )
    }
    
    // MARK: - Get Device Token Info
    func getDeviceTokenInfo(
        deviceToken: String,
        userId: String? = nil
    ) async -> Result<TokenRegistrationResponse, Error> {
        
        var queryItems: [String] = []
        queryItems.append("deviceToken=\(deviceToken)")
        if let userId = userId {
            queryItems.append("userId=\(userId)")
        }
        
        let queryString = queryItems.joined(separator: "&")
        let endpoint = "/push/register?\(queryString)"
        
        return await performRequest<EmptyRequest, TokenRegistrationResponse>(
            endpoint: endpoint,
            method: "GET",
            body: EmptyRequest()
        )
    }
    
    // MARK: - Subscribe to Topics
    func subscribeToTopics(
        deviceToken: String,
        topics: [String],
        userId: String? = nil
    ) async -> Result<TopicResponse, Error> {
        
        let subscription = TopicSubscription(
            deviceToken: deviceToken,
            topics: topics,
            userId: userId
        )
        
        return await performRequest(
            endpoint: "/push/subscribe",
            method: "POST",
            body: subscription
        )
    }
    
    // MARK: - Unsubscribe from Topics
    func unsubscribeFromTopics(
        deviceToken: String,
        topics: [String],
        userId: String? = nil
    ) async -> Result<TopicResponse, Error> {
        
        let unsubscription = TopicUnsubscription(
            deviceToken: deviceToken,
            topics: topics,
            userId: userId,
            all: false
        )
        
        return await performRequest(
            endpoint: "/push/unsubscribe",
            method: "POST",
            body: unsubscription
        )
    }
    
    // MARK: - Unsubscribe from All Topics
    func unsubscribeFromAllTopics(
        deviceToken: String,
        userId: String? = nil
    ) async -> Result<TopicResponse, Error> {
        
        let unsubscription = TopicUnsubscription(
            deviceToken: deviceToken,
            topics: [],
            userId: userId,
            all: true
        )
        
        return await performRequest(
            endpoint: "/push/unsubscribe",
            method: "POST",
            body: unsubscription
        )
    }
    
    // MARK: - Get Current Topics
    func getCurrentTopics(
        deviceToken: String,
        userId: String? = nil
    ) async -> Result<TopicResponse, Error> {
        
        var queryItems: [String] = []
        queryItems.append("deviceToken=\(deviceToken)")
        if let userId = userId {
            queryItems.append("userId=\(userId)")
        }
        
        let queryString = queryItems.joined(separator: "&")
        let endpoint = "/push/unsubscribe?\(queryString)"
        
        return await performRequest<EmptyRequest, TopicResponse>(
            endpoint: endpoint,
            method: "GET",
            body: EmptyRequest()
        )
    }
    
    // MARK: - Send Notification
    func sendNotification(
        type: String,
        target: String,
        title: String,
        body: String,
        data: [String: String]? = nil,
        apns: APNsPayload? = nil
    ) async -> Result<NotificationResponse, Error> {
        
        let notification = NotificationPayload(
            type: type,
            target: target,
            notification: NotificationContent(
                title: title,
                body: body,
                imageUrl: nil
            ),
            data: data,
            apns: apns
        )
        
        return await performRequest(
            endpoint: "/push/send",
            method: "POST",
            body: notification
        )
    }
    
    // MARK: - Get Available Topics
    func getAvailableTopics() async -> Result<[String], Error> {
        let endpoint = "/push/send?action=topics"
        
        let result: Result<TopicResponse, Error> = await performRequest<EmptyRequest, TopicResponse>(
            endpoint: endpoint,
            method: "GET",
            body: EmptyRequest()
        )
        
        switch result {
        case .success(let response):
            if response.success, let topics = response.subscribedTopics {
                return .success(topics)
            } else {
                return .failure(TokenAPIError.invalidResponse("Failed to get topics"))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Helper Methods
    private func performRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil
    ) async -> Result<U, Error> {
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return .failure(TokenAPIError.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header if available
        if let token = AuthManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                let jsonData = try JSONEncoder().encode(body)
                request.httpBody = jsonData
            } catch {
                return .failure(TokenAPIError.encodingError(error))
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(TokenAPIError.invalidResponse("Invalid response type"))
            }
            
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                do {
                    let decodedResponse = try JSONDecoder().decode(U.self, from: data)
                    return .success(decodedResponse)
                } catch {
                    return .failure(TokenAPIError.decodingError(error))
                }
            } else {
                // Try to decode error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    return .failure(TokenAPIError.serverError(errorResponse.message))
                } else {
                    return .failure(TokenAPIError.httpError(httpResponse.statusCode))
                }
            }
        } catch {
            return .failure(TokenAPIError.networkError(error))
        }
    }
}

// MARK: - Error Types
enum TokenAPIError: LocalizedError {
    case invalidURL
    case encodingError(Error)
    case decodingError(Error)
    case networkError(Error)
    case httpError(Int)
    case serverError(String)
    case invalidResponse(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        }
    }
}

// MARK: - Error Response Model
// ErrorResponse is defined in APIService.swift

// MARK: - Device Info Helper
extension TokenAPI {
    static func getCurrentDeviceInfo() -> TokenDeviceInfo {
        let device = UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        
        return TokenDeviceInfo(
            model: device.model,
            os: "\(device.systemName) \(device.systemVersion)",
            appVersion: appVersion,
            buildNumber: buildNumber,
            deviceId: device.identifierForVendor?.uuidString
        )
    }
}
