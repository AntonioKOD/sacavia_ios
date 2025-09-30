import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    
    // Form fields
    @State private var name: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var country: String = ""
    @State private var interests: [String] = []
    @State private var newInterest: String = ""
    @State private var socialLinks: [ProfileSocialLink] = []
    
    // UI states
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var isUploadingImage = false
    @State private var uploadProgress: Double = 0.0
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    // Username cooldown
    @State private var canChangeUsername = true
    @State private var usernameCooldownDays = 0
    private let bioCharacterLimit: Int = 160
    
    var body: some View {
        NavigationView {
            Form {
                profileImageSection
                profileDetailsSection
                locationSection
                interestsSection
                socialLinksSection
                saveButtonSection
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(isSaving || isUploadingImage)
                }
            }
            .onAppear(perform: loadProfileData)
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Success", isPresented: .constant(successMessage != nil)) {
                Button("OK") {
                    successMessage = nil
                }
            } message: {
                Text(successMessage ?? "")
            }
        }
    }
    
    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        Section {
            HStack {
                Spacer()
                VStack {
                    profileImageView
                    uploadButtonView
                }
                Spacer()
            }
        }
    }
    
    private var profileImageView: some View {
        ZStack {
            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
            
            // Upload progress overlay
            if isUploadingImage {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 100, height: 100)
                    .overlay(
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            
                            Text("\(Int(uploadProgress * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    )
            }
        }
    }
    
    private var uploadButtonView: some View {
        Group {
            if isUploadingImage {
                Text("Uploading...")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    Text("Change Photo")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .disabled(isUploadingImage)
            }
        }
        .onChange(of: selectedImage) { item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        print("🔍 [ProfileEditView] Setting new profileImage from PhotosPicker")
                        profileImage = image
                        uploadProfileImage(data: data)
                    }
                }
            }
        }
    }
    
    // MARK: - Profile Details Section
    private var profileDetailsSection: some View {
        Section("Profile") {
            LabeledContent("Name") {
                TextField("Your full name", text: $name)
                    .textContentType(.name)
            }
            
            LabeledContent("Username") {
                HStack(spacing: 6) {
                    Text("@")
                        .foregroundColor(.secondary)
                    TextField("username", text: $username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .disabled(!canChangeUsername)
            
            if !canChangeUsername {
                Text("You can change your username again in \(usernameCooldownDays) days.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            LabeledContent("Bio") {
                VStack(alignment: .trailing, spacing: 6) {
                    ZStack(alignment: .topLeading) {
                        if bio.isEmpty {
                            Text("Tell people about yourself")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        TextEditor(text: $bio)
                            .frame(minHeight: 88, maxHeight: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                            )
                    }
                    Text("\(bio.count)/\(bioCharacterLimit)")
                        .font(.caption2)
                        .foregroundColor(bio.count > bioCharacterLimit ? .red : .secondary)
                }
            }
        }
        .onChange(of: username) { newValue in
            let filtered = newValue.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "." }
            if filtered != newValue {
                username = filtered
            }
        }
        .onChange(of: bio) { newValue in
            if newValue.count > bioCharacterLimit {
                bio = String(newValue.prefix(bioCharacterLimit))
            }
        }
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        Section {
            LabeledContent("City") {
                TextField("City", text: $city)
                    .textContentType(.addressCity)
            }
            LabeledContent("State/Region") {
                TextField("State or region", text: $state)
                    .textContentType(.addressState)
            }
            LabeledContent("Country") {
                TextField("Country", text: $country)
                    .textContentType(.countryName)
            }
        } header: {
            Text("Location")
        } footer: {
            Text("Your location helps personalize your experience.")
        }
    }
    
    // MARK: - Interests Section
    private var interestsSection: some View {
        Section {
            if interests.isEmpty {
                Text("Add a few interests to personalize your feed.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(interests, id: \.self) { interest in
                    Text(interest)
                }
                .onDelete(perform: removeInterests)
            }
            
            HStack(spacing: 8) {
                TextField("Add new interest", text: $newInterest)
                Button {
                    addInterest()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .disabled(newInterest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } header: {
            Text("Interests")
        } footer: {
            Text("Keep it short and relevant. You can remove interests anytime.")
        }
    }
    
    // MARK: - Social Links Section
    private var socialLinksSection: some View {
        Section {
            ForEach(socialLinks) { link in
                HStack {
                    Text(link.platform.capitalized)
                    Spacer()
                    Text(link.url)
                        .foregroundColor(.blue)
                }
            }
            .onDelete(perform: removeSocialLink)
            
            Button("Add Social Link") {
                // TODO: Implement add social link functionality
            }
        } header: {
            Text("Social Links")
        } footer: {
            Text("Add links to your other profiles or websites.")
        }
    }
    
    // MARK: - Save Button Section
    private var saveButtonSection: some View {
        Section {
            Button(action: saveProfile) {
                HStack {
                    Spacer()
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save Profile").fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(isSaving || isUploadingImage)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadProfileData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let (profileData, usernameCooldown) = try await APIService.shared.getProfileEditData()
                
                await MainActor.run {
                    self.name = profileData.user.name ?? ""
                    self.username = profileData.user.username ?? ""
                    self.bio = profileData.user.bio ?? ""
                    self.city = profileData.user.location?.city ?? ""
                    self.state = profileData.user.location?.state ?? ""
                    self.country = profileData.user.location?.country ?? ""
                    self.interests = profileData.user.interests ?? []
                    self.socialLinks = profileData.user.socialLinks?.map { ProfileSocialLink(platform: $0.platform, url: $0.url) } ?? []
                    
                    self.canChangeUsername = usernameCooldown.canChangeUsername
                    self.usernameCooldownDays = usernameCooldown.daysUntilNextChange
                    
                    // Load profile image if available
                    if let imageUrl = profileData.user.profileImage?.url {
                        loadProfileImage(from: imageUrl)
                    } else {
                        profileImage = nil
                    }
                    
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load profile data: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func addInterest() {
        let trimmedInterest = newInterest.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedInterest.isEmpty && !interests.contains(trimmedInterest) {
            interests.append(trimmedInterest)
            newInterest = ""
        }
    }
    
    private func removeInterests(at offsets: IndexSet) {
        interests.remove(atOffsets: offsets)
    }
    
    private func removeSocialLink(at offsets: IndexSet) {
        socialLinks.remove(atOffsets: offsets)
    }
    
    private func loadProfileImage(from urlString: String) {
        // Add cache-busting timestamp to ensure we get the fresh image
        let timestamp = Int(Date().timeIntervalSince1970)
        let cacheBustedUrl = urlString.contains("?") ? "\(urlString)&t=\(timestamp)" : "\(urlString)?t=\(timestamp)"
        
        guard let url = URL(string: cacheBustedUrl) else {
            print("❌ [ProfileEditView] Invalid image URL: \(urlString)")
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.profileImage = image
                        print("✅ [ProfileEditView] Loaded profile image from URL")
                    }
                }
            } catch {
                print("❌ [ProfileEditView] Failed to load profile image: \(error)")
            }
        }
    }
    
    private func uploadProfileImage(data: Data) {
        guard let token = authManager.token else { return }
        
        isUploadingImage = true
        uploadProgress = 0.0
        errorMessage = nil
        
        let url = URL(string: "\(baseAPIURL)/api/mobile/upload/image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        print("🔍 [ProfileEditView] Uploading to: \(url)")
        print("🔍 [ProfileEditView] Using token: \(token.prefix(20))...")
        print("🔍 [ProfileEditView] File size: \(data.count) bytes")
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isUploadingImage = false
                uploadProgress = 0.0
                
                // Debug: Log response details
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔍 [ProfileEditView] Upload response status: \(httpResponse.statusCode)")
                }
                
                if let error = error {
                    print("❌ [ProfileEditView] Upload error: \(error.localizedDescription)")
                    errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    print("❌ [ProfileEditView] No data received")
                    errorMessage = "No data received"
                    return
                }
                
                // Debug: Log raw response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 [ProfileEditView] Upload response: \(responseString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(MediaUploadResponse.self, from: data)
                    
                    print("🔍 [ProfileEditView] Decoded upload response success: \(response.success)")
                    print("🔍 [ProfileEditView] Decoded upload response data: \(response.data != nil)")
                    
                    if response.success, let mediaDoc = response.data {
                        // Store the media ID for the profile update
                        authManager.profileImageIdForEdit = mediaDoc.id
                        print("✅ [ProfileEditView] Image uploaded successfully with ID: \(mediaDoc.id)")
                        print("✅ [ProfileEditView] Media URL: \(mediaDoc.url)")
                        successMessage = "Image uploaded successfully"
                        
                        // Post notification that image was uploaded
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ProfileImageUpdated"),
                            object: nil,
                            userInfo: ["message": "Profile image uploaded", "mediaId": mediaDoc.id, "mediaUrl": mediaDoc.url]
                        )
                        print("📢 [ProfileEditView] Posted ProfileImageUpdated notification")
                    } else {
                        print("❌ [ProfileEditView] Upload failed: \(response.error ?? "Unknown error")")
                        errorMessage = response.error ?? "Upload failed"
                    }
                } catch {
                    print("❌ [ProfileEditView] Failed to parse upload response: \(error.localizedDescription)")
                    print("❌ [ProfileEditView] Parse error details: \(error)")
                    errorMessage = "Failed to parse upload response"
                    isUploadingImage = false
                    uploadProgress = 0.0
                }
            }
        }.resume()
    }
    
    private func saveProfile() {
        guard let token = authManager.token else { return }
        
        isSaving = true
        
        // Debug: Log what we're about to send
        print("🔍 [ProfileEditView] About to save profile with profileImageIdForEdit: \(authManager.profileImageIdForEdit ?? "nil")")
        print("🔍 [ProfileEditView] Current profileImage is nil: \(profileImage == nil)")
        
        let url = URL(string: "\(baseAPIURL)/api/mobile/users/profile/edit")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let profileData = ProfileUpdateRequest(
            name: name,
            username: username,
            bio: bio,
            location: ProfileLocationData(
                city: city.isEmpty ? nil : city,
                state: state.isEmpty ? nil : state,
                country: country.isEmpty ? nil : country
            ),
            interests: interests,
            socialLinks: socialLinks.map { SocialLinkData(platform: $0.platform, url: $0.url) },
            profileImage: authManager.profileImageIdForEdit
        )
        
        // Debug: Log the full request data
        print("🔍 [ProfileEditView] Full profile data being sent:")
        if let jsonData = try? JSONEncoder().encode(profileData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("🔍 [ProfileEditView] JSON: \(jsonString)")
        }
        
        do {
            request.httpBody = try JSONEncoder().encode(profileData)
        } catch {
            errorMessage = "Failed to encode profile data"
            isSaving = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSaving = false
                
                // Debug: Log the response
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔍 [ProfileEditView] Response status: \(httpResponse.statusCode)")
                }
                
                if let error = error {
                    print("❌ [ProfileEditView] Network error: \(error.localizedDescription)")
                    errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    print("❌ [ProfileEditView] No data received")
                    errorMessage = "No data received"
                    return
                }
                
                // Debug: Log the response data
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 [ProfileEditView] Response data: \(responseString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(ProfileUpdateResponse.self, from: data)
                    
                    if response.success {
                        print("✅ [ProfileEditView] Profile updated successfully")
                        successMessage = "Profile updated successfully"
                        
                        // Update auth manager with new user data
                        if let userData = response.data?.user {
                            print("🔍 [ProfileEditView] Updating AuthManager with user data:")
                            print("🔍 [ProfileEditView] User name: \(userData.name ?? "nil")")
                            print("🔍 [ProfileEditView] User profile image URL: \(userData.profileImage?.url ?? "nil")")
                            print("🔍 [ProfileEditView] User bio: \(userData.bio ?? "nil")")
                            
                            authManager.updateUserData(userData)
                            
                            // Don't refresh the profile image here - it will overwrite the newly uploaded image
                            // The profileImage variable already contains the correct new image
                            print("🔍 [ProfileEditView] Profile updated successfully - keeping current profileImage")
                            
                            // Test notification to verify the system is working
                            NotificationCenter.default.post(
                                name: NSNotification.Name("TestNotification"),
                                object: nil,
                                userInfo: ["message": "Profile save test"]
                            )
                            print("📢 [ProfileEditView] Posted TestNotification")
                            
                            // Also post a ProfileUpdated notification for testing
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ProfileUpdated"),
                                object: nil,
                                userInfo: ["message": "Profile updated test", "userData": userData]
                            )
                            print("📢 [ProfileEditView] Posted ProfileUpdated test notification")
                        } else {
                            print("❌ [ProfileEditView] No user data in response")
                        }
                        
                        // Auto-dismiss after successful save
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            print("🔍 [ProfileEditView] Auto-dismissing after successful save")
                            print("🔍 [ProfileEditView] This should trigger ProfileView refresh")
                            dismiss()
                        }
                    } else {
                        print("❌ [ProfileEditView] API returned error: \(response.error ?? "Unknown error")")
                        errorMessage = response.error ?? "Failed to update profile"
                    }
                } catch {
                    print("❌ [ProfileEditView] Failed to parse response: \(error.localizedDescription)")
                    errorMessage = "Failed to parse response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// MARK: - Data Models

struct ProfileSocialLink: Identifiable {
    let id = UUID()
    var platform: String
    var url: String
}

struct SocialLinkData: Codable {
    let platform: String
    let url: String
}

struct ProfileLocationData: Codable {
    let city: String?
    let state: String?
    let country: String?
}

struct ProfileUpdateRequest: Codable {
    let name: String
    let username: String
    let bio: String
    let location: ProfileLocationData
    let interests: [String]
    let socialLinks: [SocialLinkData]
    let profileImage: String?
}

struct ProfileUpdateResponse: Codable {
    let success: Bool
    let data: ProfileUpdateData?
    let error: String?
}

struct ProfileUpdateData: Codable {
    let user: ProfileUserData
}

struct ProfileUserData: Codable {
    let id: String
    let name: String?
    let username: String?
    let bio: String?
    let location: ProfileLocationData?
    let interests: [String]?
    let socialLinks: [SocialLinkData]?
    let profileImage: ProfileImageData?
}

struct ProfileImageData: Codable {
    let id: String?
    let url: String?
}

struct UsernameCooldown: Codable {
    let canChange: Bool
    let nextChangeDate: String?
    let daysRemaining: Int
    
    // Computed properties for backward compatibility
    var canChangeUsername: Bool { canChange }
    var daysUntilNextChange: Int { daysRemaining }
}

struct ProfileEditData: Codable {
    let user: ProfileUserData
    let usernameCooldown: UsernameCooldown
}

struct MediaUploadResponse: Codable {
    let success: Bool
    let data: MediaDoc?
    let error: String?
}

struct MediaDoc: Codable {
    let id: String
    let url: String
}

// MARK: - API Service Extension

extension APIService {
    func getProfileEditData() async throws -> (ProfileEditData, UsernameCooldown) {
        guard let token = token else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(APIService.baseURL)/api/mobile/users/profile/edit")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("🔍 [APIService] Getting profile edit data from: \(url)")
        print("🔍 [APIService] Using token: \(token.prefix(20))...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("🔍 [APIService] Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ [APIService] HTTP error: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ [APIService] Response body: \(responseString)")
            }
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        // Debug: Log the raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 [APIService] Raw response: \(responseString)")
        }
        
        let profileResponse = try JSONDecoder().decode(ProfileEditResponse.self, from: data)
        
        print("🔍 [APIService] Decoded response success: \(profileResponse.success)")
        print("🔍 [APIService] Decoded response data: \(profileResponse.data != nil)")
        
        guard profileResponse.success, let profileData = profileResponse.data else {
            print("❌ [APIService] Profile data not found or success is false")
            print("❌ [APIService] Success: \(profileResponse.success)")
            print("❌ [APIService] Error: \(profileResponse.error ?? "No error message")")
            throw APIError.serverError("Profile data not found")
        }
        
        print("✅ [APIService] Profile data loaded successfully")
        print("🔍 [APIService] User data: \(profileData.user.name ?? "No name")")
        print("🔍 [APIService] Username cooldown: \(profileData.usernameCooldown)")
        
        return (profileData, profileData.usernameCooldown)
    }
}

struct ProfileEditResponse: Codable {
    let success: Bool
    let data: ProfileEditData?
    let error: String?
}

// MARK: - Base URL

extension ProfileEditView {
    private var baseAPIURL: String {
        #if DEBUG
        return "http://localhost:3000"
        #else
        return "https://sacavia.com"
        #endif
    }
}
