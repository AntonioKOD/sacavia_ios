import Foundation

// MARK: - Blocked User Model
struct BlockedUser: Identifiable, Codable {
    let id: String
    let name: String
    let username: String?
    let email: String?
    let profileImage: ProfileImage?
    let bio: String?
    let blockedAt: String
    let reason: String?
    
    struct ProfileImage: Codable {
        let url: String
    }
}
