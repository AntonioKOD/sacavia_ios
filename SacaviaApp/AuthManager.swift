import Foundation
import Combine

// MARK: - Notification Names
extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
}

// MARK: - Codable Models

struct DeviceInfo: Codable {
    let deviceId: String?
    let platform: String?
    let appVersion: String?
    
    init(deviceId: String?, platform: String?, appVersion: String?) {
        self.deviceId = deviceId
        self.platform = platform
        self.appVersion = appVersion
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
    let rememberMe: Bool
    let deviceInfo: DeviceInfo?
}

struct SignupRequest: Codable {
    let name: String
    let email: String
    let password: String
    let confirmPassword: String
    let username: String
    let location: LocationRequest?
    let preferences: PreferencesRequest?
    let deviceInfo: DeviceInfo?
    let termsAccepted: Bool
    let privacyAccepted: Bool
}

struct EnhancedSignupRequest: Codable {
    let name: String
    let username: String
    let email: String
    let password: String
    let confirmPassword: String
    let coords: Coordinates?
    let preferences: Preferences?
    let additionalData: AdditionalData?
    let deviceInfo: DeviceInfo?
    let termsAccepted: Bool
    let privacyAccepted: Bool
    
    init(name: String, username: String, email: String, password: String, confirmPassword: String, coords: Coordinates?, preferences: Preferences?, additionalData: AdditionalData?, deviceInfo: DeviceInfo?, termsAccepted: Bool, privacyAccepted: Bool) {
        self.name = name
        self.username = username
        self.email = email
        self.password = password
        self.confirmPassword = confirmPassword
        self.coords = coords
        self.preferences = preferences
        self.additionalData = additionalData
        self.deviceInfo = deviceInfo
        self.termsAccepted = termsAccepted
        self.privacyAccepted = privacyAccepted
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        password = try container.decode(String.self, forKey: .password)
        confirmPassword = try container.decode(String.self, forKey: .confirmPassword)
        coords = try container.decodeIfPresent(Coordinates.self, forKey: .coords)
        preferences = try container.decodeIfPresent(Preferences.self, forKey: .preferences)
        additionalData = try container.decodeIfPresent(AdditionalData.self, forKey: .additionalData)
        deviceInfo = try container.decodeIfPresent(DeviceInfo.self, forKey: .deviceInfo)
        termsAccepted = try container.decode(Bool.self, forKey: .termsAccepted)
        privacyAccepted = try container.decode(Bool.self, forKey: .privacyAccepted)
    }
    
    enum CodingKeys: String, CodingKey {
        case name, username, email, password, confirmPassword, coords, preferences, additionalData, deviceInfo, termsAccepted, privacyAccepted
    }
}

struct Preferences: Codable {
    let categories: [String]
    let notifications: Bool
    let radius: Int
}

struct AdditionalData: Codable {
    let interests: [String]
    let receiveUpdates: Bool
    let onboardingData: OnboardingData?
}

struct OnboardingData: Codable {
    let primaryUseCase: String?
    let travelRadius: String?
    let budgetPreference: String?
    let onboardingCompleted: Bool
    let signupStep: Int
}

struct LocationRequest: Codable {
    let coordinates: Coordinates?
    let address: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coordinates = try container.decodeIfPresent(Coordinates.self, forKey: .coordinates)
        address = try container.decodeIfPresent(String.self, forKey: .address)
    }
    
    enum CodingKeys: String, CodingKey {
        case coordinates, address
    }
}

// Coordinates is defined in SharedTypes.swift

struct PreferencesRequest: Codable {
    let categories: [String]
    let notifications: Bool
    let radius: Int
}

struct AuthResponse: Codable {
    let success: Bool
    let message: String
    let data: AuthData?
    let error: String?
    let code: String?
    let errorType: String?
    let suggestions: [String]?
}

struct AuthData: Codable {
    let user: AuthUser
    let token: String?
    let expiresIn: Int?
    let emailVerificationRequired: Bool?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decode(AuthUser.self, forKey: .user)
        token = try container.decodeIfPresent(String.self, forKey: .token)
        expiresIn = try container.decodeIfPresent(Int.self, forKey: .expiresIn)
        emailVerificationRequired = try container.decodeIfPresent(Bool.self, forKey: .emailVerificationRequired)
    }
    
    enum CodingKeys: String, CodingKey {
        case user, token, expiresIn, emailVerificationRequired
    }
}

// AuthUser is defined in SharedTypes.swift

// LocationData is defined in SharedTypes.swift

// MARK: - Profile Data Models (using types from ProfileEditView.swift)

// MARK: - AuthManager Class

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var user: AuthUser?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    
    // Profile edit state management
    @Published var profileImageIdForEdit: String? = nil
    @Published var hasLoadedProfileEditData: Bool = false

    // Use the baseURL from Utils.swift instead of hardcoded production URL
    private let baseURL = "\(baseAPIURL)/api/mobile/auth"
    private let tokenKey = "authToken"
    private let userKey = "userData"
    private var tokenValidationTimer: Timer?
    
    // Add a private backing property for token
    private var _token: String?
    
    // Public token property with logging
    var token: String? {
        get {
            print("🔐 [AuthManager] Token accessed - Value: \(_token != nil ? "Available" : "Nil")")
            if let token = _token {
                print("🔐 [AuthManager] Token prefix: \(String(token.prefix(20)))...")
            }
            return _token
        }
        set {
            print("🔐 [AuthManager] Token set - Value: \(newValue != nil ? "Available" : "Nil")")
            if let token = newValue {
                print("🔐 [AuthManager] Token prefix: \(String(token.prefix(20)))...")
            }
            _token = newValue
        }
    }

    private init() {
        loadStoredAuth()
        startTokenValidationTimer()
    }
    
    deinit {
        tokenValidationTimer?.invalidate()
    }

    // MARK: - Token Management
    
    private func loadStoredAuth() {
        let storedToken = UserDefaults.standard.string(forKey: tokenKey)
        print("🔐 [AuthManager] Loading stored auth - Token from UserDefaults: \(storedToken != nil ? "Available" : "Nil")")
        if let token = storedToken {
            print("🔐 [AuthManager] Token prefix: \(String(token.prefix(20)))...")
        }
        
        self.token = storedToken
        if let userData = UserDefaults.standard.data(forKey: userKey),
           let storedUser = try? JSONDecoder().decode(AuthUser.self, from: userData) {
            self.user = storedUser
            print("🔐 [AuthManager] User data loaded from UserDefaults")
        } else {
            print("🔐 [AuthManager] No user data found in UserDefaults")
        }
        self.isAuthenticated = token != nil && user != nil
        print("🔐 [AuthManager] isAuthenticated: \(isAuthenticated)")
        
        // Validate token on app launch
        if isAuthenticated {
            validateToken()
            // Refresh current user's complete profile data
            Task {
                await refreshCurrentUserProfile()
            }
        }
    }
    
    private func saveAuthData() {
        if let token = token {
            UserDefaults.standard.set(token, forKey: tokenKey)
            print("🔐 [AuthManager] Token saved to UserDefaults - Prefix: \(String(token.prefix(20)))...")
        } else {
            print("🔐 [AuthManager] No token to save")
        }
        if let user = user,
           let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
            print("🔐 [AuthManager] User data saved to UserDefaults")
        } else {
            print("🔐 [AuthManager] No user data to save")
        }
    }
    
    private func clearStoredAuth() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
    }
    
    // MARK: - User Data Updates
    
    func updateUserData(_ userData: ProfileUserData) {
        // Create a new AuthUser with updated data
        let authLocation: LocationData?
        if let profileLocation = userData.location {
            authLocation = LocationData(
                coordinates: nil,
                address: nil,
                city: profileLocation.city,
                state: profileLocation.state,
                country: profileLocation.country
            )
        } else {
            authLocation = nil
        }
        
        let updatedUser = AuthUser(
            id: userData.id,
            name: userData.name ?? "",
            email: user?.email ?? "",
            username: userData.username,
            profileImage: userData.profileImage != nil ? ProfileImage(url: userData.profileImage!.url ?? "") : nil, // Convert ProfileImageData to ProfileImage
            role: user?.role ?? "user",
            bio: userData.bio,
            location: authLocation,
            isVerified: user?.isVerified ?? false,
            followerCount: user?.followerCount ?? 0,
            following: user?.following, // Preserve existing following list
            followers: user?.followers // Preserve existing followers list
        )
        
        DispatchQueue.main.async {
            print("🔐 [AuthManager] Updating user on main thread")
            print("🔐 [AuthManager] New user data: \(userData.name ?? "nil")")
            print("🔐 [AuthManager] New profile image URL: \(userData.profileImage?.url ?? "nil")")
            print("🔐 [AuthManager] Current user before update: \(self.user?.name ?? "nil")")
            print("🔐 [AuthManager] Current profile image before update: \(self.user?.profileImage?.url ?? "nil")")
            
            self.user = updatedUser
            self.saveAuthData()
            
            print("🔐 [AuthManager] User updated successfully")
            print("🔐 [AuthManager] New user after update: \(self.user?.name ?? "nil")")
            print("🔐 [AuthManager] New profile image after update: \(self.user?.profileImage?.url ?? "nil")")
            
            // Post notification for profile update
            NotificationCenter.default.post(
                name: NSNotification.Name("ProfileUpdated"),
                object: nil,
                userInfo: ["userData": userData]
            )
            print("📢 [AuthManager] Posted ProfileUpdated notification")
            
            // Post specific notification for profile image update
            NotificationCenter.default.post(
                name: NSNotification.Name("ProfileImageUpdated"),
                object: nil,
                userInfo: ["userData": userData]
            )
            print("📢 [AuthManager] Posted ProfileImageUpdated notification")
            
            // Test notification to verify the system is working
            NotificationCenter.default.post(
                name: NSNotification.Name("TestNotification"),
                object: nil,
                userInfo: ["message": "AuthManager test notification"]
            )
            print("📢 [AuthManager] Posted TestNotification")
        }
    }
    
    func updateUserFollowingList(following: [String]) {
        print("🔐 [AuthManager] updateUserFollowingList called with following count: \(following.count)")
        print("🔐 [AuthManager] Following list: \(following)")
        
        guard let currentUser = user else { 
            print("🔐 [AuthManager] No current user found")
            return 
        }
        
        // Remove duplicates from the following list
        let deduplicatedFollowing = Array(Set(following))
        if deduplicatedFollowing.count != following.count {
            print("🔐 [AuthManager] Removed \(following.count - deduplicatedFollowing.count) duplicates from following list")
        }
        
        let updatedUser = AuthUser(
            id: currentUser.id,
            name: currentUser.name,
            email: currentUser.email,
            username: currentUser.username,
            profileImage: currentUser.profileImage,
            role: currentUser.role,
            bio: currentUser.bio,
            location: currentUser.location,
            isVerified: currentUser.isVerified,
            followerCount: currentUser.followerCount,
            following: deduplicatedFollowing,
            followers: currentUser.followers
        )
        
        DispatchQueue.main.async {
            self.user = updatedUser
            self.saveAuthData()
            print("🔐 [AuthManager] Updated user following list, count: \(deduplicatedFollowing.count)")
            
            // Post notification to trigger UI updates
            NotificationCenter.default.post(name: NSNotification.Name("FollowingListUpdated"), object: nil)
        }
    }
    
    // Refresh current user's complete profile data including following/followers lists
    func refreshCurrentUserProfile() async {
        guard let currentUserId = user?.id else { return }
        
        do {
            let apiService = APIService()
            let (profileData, _) = try await apiService.getUserProfile(userId: currentUserId)
            
            // Create updated AuthUser with complete data
            let authLocation: LocationData?
            if let profileLocation = profileData.location {
                authLocation = LocationData(
                    coordinates: nil,
                    address: nil,
                    city: profileLocation.city,
                    state: profileLocation.state,
                    country: profileLocation.country
                )
            } else {
                authLocation = nil
            }
            
            let updatedUser = AuthUser(
                id: profileData.id,
                name: profileData.name,
                email: user?.email ?? "",
                username: profileData.username,
                profileImage: profileData.profileImage,
                role: profileData.role ?? "user",
                bio: profileData.bio,
                location: authLocation,
                isVerified: profileData.isVerified,
                followerCount: profileData.stats?.followersCount ?? 0,
                following: profileData.following,
                followers: profileData.followers
            )
            
            DispatchQueue.main.async {
                self.user = updatedUser
                self.saveAuthData()
                print("🔐 [AuthManager] Refreshed current user profile with following: \(profileData.following?.count ?? 0), followers: \(profileData.followers?.count ?? 0)")
            }
        } catch {
            print("🔐 [AuthManager] Failed to refresh current user profile: \(error)")
        }
    }
    
    private func startTokenValidationTimer() {
        // Validate token every 5 minutes
        tokenValidationTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                if self?.isAuthenticated == true {
                    self?.validateToken()
                }
            }
        }
    }
    
    private func validateToken() {
        guard let token = token, !token.isEmpty else {
            handleTokenInvalid()
            return
        }
        
        // Quick validation by checking if token is expired
        if let payload = decodeToken(token), let exp = payload["exp"] as? TimeInterval {
            let currentTime = Date().timeIntervalSince1970
            if currentTime >= exp {
                handleTokenInvalid()
                return
            }
        }
        
        // Optional: Make a lightweight API call to validate token
        validateTokenWithServer()
    }
    
    private func validateTokenWithServer() {
        guard let token = token else { return }
        
        let url = URL(string: "\(baseAPIURL)/api/auth-check")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Token validation error: \(error)")
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let authenticated = json["authenticated"] as? Bool else {
                    return
                }
                
                if !authenticated {
                    self?.handleTokenInvalid()
                }
            }
        }.resume()
    }
    
    private func handleTokenInvalid() {
        DispatchQueue.main.async {
            self.logout()
        }
    }
    
    private func decodeToken(_ token: String) -> [String: Any]? {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3,
              let payloadData = Data(base64Encoded: parts[1].padding(toLength: ((parts[1].count + 3) / 4) * 4, withPad: "=", startingAt: 0)) else {
            return nil
        }
        
        return try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
    }

    // MARK: - Authentication Methods
    
    func login(email: String, password: String, rememberMe: Bool, completion: @escaping (String?) -> Void) {
        isLoading = true
        let url = URL(string: "\(baseURL)/login")!
        let deviceInfo = DeviceInfo(deviceId: UUID().uuidString, platform: "ios", appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.9.81")
        let body = LoginRequest(email: email, password: password, rememberMe: rememberMe, deviceInfo: deviceInfo)
        
        print("🔐 Login attempt - URL: \(url)")
        print("🔐 Login request body - Email: \(email), RememberMe: \(rememberMe)")
        print("🔐 Base URL being used: \(baseURL)")
        print("🔐 Full URL: \(url)")
        
        postAuthRequest(url: url, body: body) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    print("🔐 Login response: \(response)")
                    if response.success, let data = response.data {
                        if let token = data.token {
                            print("🔐 Login successful - Token: \(String(token.prefix(20)))...")
                            self?.token = token
                        } else {
                            print("🔐 Login successful - No token provided")
                        }
                        self?.user = data.user
                        self?.isAuthenticated = true
                        self?.saveAuthData()
                        
                        // Post notification for successful login
                        NotificationCenter.default.post(name: .userDidLogin, object: nil)
                        
                        // Fetch complete user data
                        self?.fetchCurrentUser { userSuccess, userError in
                            if !userSuccess {
                                print("Warning: Failed to fetch complete user data: \(userError ?? "Unknown error")")
                            }
                            completion(nil)
                        }
                    } else {
                        print("🔐 Login failed - Message: \(response.message)")
                        print("🔐 Login failed - Error: \(response.error ?? "No error message")")
                        print("🔐 Login failed - Code: \(response.code ?? "No error code")")
                        print("🔐 Login failed - Error Type: \(response.errorType ?? "No error type")")
                        // Handle specific error types
                        if let errorType = response.errorType {
                            switch errorType {
                            case "unverified_email":
                                completion("Please verify your email before logging in. Check your inbox for a verification link.")
                            case "user_not_found":
                                completion("Account not found. Please check your email or sign up.")
                            case "incorrect_credentials":
                                completion("Incorrect email or password. Please try again.")
                            default:
                                completion(response.message)
                            }
                        } else {
                            completion(response.message)
                        }
                    }
                case .failure(let error):
                    print("🔐 Login error: \(error)")
                    print("🔐 Login error type: \(type(of: error))")
                    if let decodingError = error as? DecodingError {
                        print("🔐 Decoding error details: \(decodingError)")
                    }
                    completion(error.localizedDescription)
                }
            }
        }
    }

    func signup(request: EnhancedSignupRequest, completion: @escaping (String?) -> Void) {
        isLoading = true
        // Use the correct endpoint
        let url = URL(string: "\(baseAPIURL)/api/mobile/auth/register")!
        
        postAuthRequest(url: url, body: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    if response.success {
                        completion(nil)
                    } else {
                        // Handle specific username validation errors
                        if let code = response.code {
                            switch code {
                            case "USERNAME_TAKEN":
                                if let suggestions = response.suggestions, !suggestions.isEmpty {
                                    let suggestionText = suggestions.prefix(3).joined(separator: ", ")
                                    completion("\(response.message ?? "Username already taken"). Try: \(suggestionText)")
                                } else {
                                    completion(response.message)
                                }
                            case "INVALID_USERNAME_FORMAT":
                                completion("Username can only contain lowercase letters, numbers, hyphens, and underscores")
                            case "USERNAME_TOO_SHORT":
                                completion("Username must be at least 3 characters long")
                            case "USERNAME_TOO_LONG":
                                completion("Username must be less than 30 characters")
                            case "RESERVED_USERNAME":
                                completion("This username is reserved and cannot be used")
                            default:
                                completion(response.message)
                            }
                        } else {
                            completion(response.message)
                        }
                    }
                case .failure(let error):
                    completion(error.localizedDescription)
                }
            }
        }
    }

    func logout() {
        // Call logout API if we have a token
        if let token = token {
            let url = URL(string: "\(baseURL)/logout")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
            
            URLSession.shared.dataTask(with: request) { _, _, _ in
                // Ignore response - we're logging out anyway
            }.resume()
        }
        
        // Clear local data on main thread
        DispatchQueue.main.async {
            self.user = nil
            self.token = nil
            self.isAuthenticated = false
            self.clearStoredAuth()
            
            // Post notification for logout
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
        }
    }

    func fetchCurrentUser(completion: @escaping (Bool, String?) -> Void) {
        guard let token = self.token, !token.isEmpty else {
            completion(false, "No token available")
            return
        }
        
        let url = URL(string: "\(baseAPIURL)/api/mobile/users/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                
                guard let data = data else {
                    completion(false, "No data received")
                    return
                }
                
                print("/api/users/me API response:", String(data: data, encoding: .utf8) ?? "nil")
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let userDict = json?["user"] as? [String: Any],
                       let id = userDict["id"] as? String,
                       let name = userDict["name"] as? String,
                       let email = userDict["email"] as? String {
                        
                        // Create enhanced user object
                        let profileImage = userDict["profileImage"] as? [String: Any]
                        let profileImageUrl = profileImage?["url"] as? String
                        
                        // Parse location data
                        var locationData: LocationData?
                        if let locationDict = userDict["location"] as? [String: Any] {
                            let coordinatesDict = locationDict["coordinates"] as? [String: Any]
                            let coordinates: Coordinates?
                            if let coordDict = coordinatesDict,
                               let lat = coordDict["latitude"] as? Double,
                               let lng = coordDict["longitude"] as? Double {
                                coordinates = Coordinates(latitude: lat, longitude: lng)
                            } else {
                                coordinates = nil
                            }
                            
                            locationData = LocationData(
                                coordinates: coordinates,
                                address: locationDict["address"] as? String,
                                city: locationDict["city"] as? String,
                                state: locationDict["state"] as? String,
                                country: locationDict["country"] as? String
                            )
                        }
                        
                        let enhancedUser = AuthUser(
                            id: id,
                            name: name,
                            email: email,
                            profileImage: profileImageUrl != nil ? ProfileImage(url: profileImageUrl!) : nil, // Changed from profileImageUrl to ProfileImage object
                            role: userDict["role"] as? String ?? "user",
                            bio: userDict["bio"] as? String,
                            location: locationData
                        )
                        
                        DispatchQueue.main.async {
                            self?.user = enhancedUser
                            self?.saveAuthData()
                            completion(true, nil)
                        }
                    } else if let errorMsg = json?["error"] as? String {
                        DispatchQueue.main.async {
                            completion(false, errorMsg)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(false, "Failed to parse user data")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(false, error.localizedDescription)
                    }
                }
            }
        }.resume()
    }

    // MARK: - Authenticated Request Helper
    
    func createAuthenticatedRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpShouldHandleCookies = false // Prevent URLSession from managing cookies automatically
        
        if let token = token {
            request.setValue("payload-token=\(token)", forHTTPHeaderField: "Cookie")
        }
        
        return request
    }
    
    func getValidToken() -> String? {
        print("🔐 AuthManager: getValidToken called")
        print("🔐 AuthManager: token exists: \(token != nil)")
        print("🔐 AuthManager: token empty: \(token?.isEmpty ?? true)")
        
        guard let token = token, !token.isEmpty else { 
            print("🔐 AuthManager: No token available")
            return nil 
        }
        
        print("🔐 AuthManager: Token found: \(String(token.prefix(20)))...")
        
        // Quick validation
        if let payload = decodeToken(token), let exp = payload["exp"] as? TimeInterval {
            let currentTime = Date().timeIntervalSince1970
            print("🔐 AuthManager: Token expires at: \(Date(timeIntervalSince1970: exp))")
            print("🔐 AuthManager: Current time: \(Date(timeIntervalSince1970: currentTime))")
            print("🔐 AuthManager: Token expired: \(currentTime >= exp)")
            
            if currentTime >= exp {
                print("🔐 AuthManager: Token is expired, handling invalidation")
                handleTokenInvalid()
                return nil
            }
        } else {
            print("🔐 AuthManager: Could not decode token or get expiration")
        }
        
        print("🔐 AuthManager: Returning valid token")
        return token
    }

    // MARK: - Network Testing
    
    func testNetworkConnectivity(completion: @escaping (Bool, String?) -> Void) {
        let testURL = URL(string: "\(baseAPIURL)/api/auth-check")!
        var request = URLRequest(url: testURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        print("🌐 Testing network connectivity to: \(testURL)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🌐 Network test failed: \(error)")
                    completion(false, error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("🌐 Network test response: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 200 {
                        completion(true, nil)
                    } else {
                        completion(false, "Server returned status \(httpResponse.statusCode)")
                    }
                } else {
                    completion(false, "Invalid response")
                }
            }
        }.resume()
    }
    
    // MARK: - POST Request Helpers
    
    private func postAuthRequest<T: Codable>(url: URL, body: T, _ completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // Increase timeout for debugging
        
        do {
            let bodyData = try JSONEncoder().encode(body)
            request.httpBody = bodyData
            print("🔐 Request body encoded successfully: \(String(data: bodyData, encoding: .utf8) ?? "nil")")
        } catch {
            print("🔐 Failed to encode request body: \(error)")
            completion(.failure(error))
            return
        }
        
        print("🔐 Making request to: \(url)")
        print("🔐 Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("🔐 Response received")
            if let error = error { 
                print("🔐 Network error: \(error)")
                completion(.failure(error))
                return 
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔐 HTTP Status: \(httpResponse.statusCode)")
                print("🔐 Response headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let data = data else { 
                print("🔐 No data received")
                completion(.failure(NSError(domain: "No data", code: 0)))
                return 
            }
            
            print("🔐 Response data size: \(data.count) bytes")
            print("🔐 Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            do {
                let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
                print("🔐 Successfully decoded response: \(decoded)")
                completion(.success(decoded))
            } catch {
                print("🔐 Decoding error: \(error)")
                print("🔐 Decoding error type: \(type(of: error))")
                
                // Try to get more details about the decoding error
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("🔐 Missing key: \(key.stringValue), context: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("🔐 Type mismatch: expected \(type), context: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("🔐 Value not found: expected \(type), context: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("🔐 Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("🔐 Unknown decoding error")
                    }
                }
                
                // Try to parse as JSON to see what we actually received
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🔐 Raw JSON response: \(jsonString)")
                }
                
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Profile Edit State Management
    
    func setProfileImageIdForEdit(_ imageId: String?) {
        print("🔐 [AuthManager] Setting profileImageIdForEdit: \(imageId ?? "nil")")
        print("🔐 [AuthManager] Previous value was: \(profileImageIdForEdit ?? "nil")")
        profileImageIdForEdit = imageId
        print("🔐 [AuthManager] New value is: \(profileImageIdForEdit ?? "nil")")
    }
    
    // MARK: - Real-time Follow State Management
    
    func updateFollowState(targetUserId: String, isFollowing: Bool) {
        print("🔐 [AuthManager] updateFollowState called - targetUserId: \(targetUserId), isFollowing: \(isFollowing)")
        
        guard let currentUser = user else { 
            print("🔐 [AuthManager] No current user found")
            return 
        }
        
        var updatedFollowing = currentUser.following ?? []
        
        if isFollowing {
            // Add to following list if not already there
            if !updatedFollowing.contains(targetUserId) {
                updatedFollowing.append(targetUserId)
                print("🔐 [AuthManager] Added \(targetUserId) to following list")
            }
        } else {
            // Remove from following list
            updatedFollowing.removeAll { $0 == targetUserId }
            print("🔐 [AuthManager] Removed \(targetUserId) from following list")
        }
        
        // Update the user with new following list
        let updatedUser = AuthUser(
            id: currentUser.id,
            name: currentUser.name,
            email: currentUser.email,
            username: currentUser.username,
            profileImage: currentUser.profileImage,
            role: currentUser.role,
            bio: currentUser.bio,
            location: currentUser.location,
            isVerified: currentUser.isVerified,
            followerCount: currentUser.followerCount,
            following: updatedFollowing,
            followers: currentUser.followers
        )
        
        DispatchQueue.main.async {
            self.user = updatedUser
            self.saveAuthData()
            print("🔐 [AuthManager] Updated follow state - following count: \(updatedFollowing.count)")
            
            // Post notification to trigger UI updates
            NotificationCenter.default.post(name: NSNotification.Name("FollowStateUpdated"), object: [
                "targetUserId": targetUserId,
                "isFollowing": isFollowing
            ])
        }
    }
    
    func updateFollowersCount(delta: Int) {
        print("🔐 [AuthManager] updateFollowersCount called with delta: \(delta)")
        
        guard let currentUser = user else { 
            print("🔐 [AuthManager] No current user found")
            return 
        }
        
        let newFollowerCount = max(0, currentUser.followerCount + delta)
        
        let updatedUser = AuthUser(
            id: currentUser.id,
            name: currentUser.name,
            email: currentUser.email,
            username: currentUser.username,
            profileImage: currentUser.profileImage,
            role: currentUser.role,
            bio: currentUser.bio,
            location: currentUser.location,
            isVerified: currentUser.isVerified,
            followerCount: newFollowerCount,
            following: currentUser.following,
            followers: currentUser.followers
        )
        
        DispatchQueue.main.async {
            self.user = updatedUser
            self.saveAuthData()
            print("🔐 [AuthManager] Updated followers count: \(newFollowerCount)")
            
            // Post notification to trigger UI updates
            NotificationCenter.default.post(name: NSNotification.Name("FollowersCountUpdated"), object: [
                "newCount": newFollowerCount,
                "delta": delta
            ])
        }
    }
    
    func clearProfileImageIdForEdit() {
        print("🔐 [AuthManager] Clearing profileImageIdForEdit")
        profileImageIdForEdit = nil
    }
    
    func setHasLoadedProfileEditData(_ loaded: Bool) {
        print("🔐 [AuthManager] Setting hasLoadedProfileEditData: \(loaded)")
        hasLoadedProfileEditData = loaded
    }
    
    func resetProfileEditState() {
        print("🔐 [AuthManager] Resetting profile edit state")
        profileImageIdForEdit = nil
        hasLoadedProfileEditData = false
    }
} 
