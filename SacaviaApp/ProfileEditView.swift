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
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    // Username cooldown
    @State private var canChangeUsername = true
    @State private var usernameCooldownDays = 0
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Image Section
                Section {
                    HStack {
                        Spacer()
                        VStack {
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
                            
                            PhotosPicker(selection: $selectedImage, matching: .images) {
                                Text("Change Photo")
                                    .font(.caption)
                                    .foregroundColor(.blue)
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
                        Spacer()
                    }
                    .padding(.vertical)
                }
                
                // Basic Information Section
                Section("Basic Information") {
                    TextField("Name", text: $name)
                    
                    VStack(alignment: .leading) {
                        TextField("Username", text: $username)
                        if !canChangeUsername {
                            Text("You can change your username again in \(usernameCooldownDays) day(s)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Location Section
                Section("Location") {
                    TextField("City", text: $city)
                    TextField("State/Province", text: $state)
                    TextField("Country", text: $country)
                }
                
                // Interests Section
                Section("Interests") {
                    ForEach(interests, id: \.self) { interest in
                        HStack {
                            Text(interest)
                            Spacer()
                            Button("Remove") {
                                interests.removeAll { $0 == interest }
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        TextField("Add interest", text: $newInterest)
                        Button("Add") {
                            if !newInterest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                interests.append(newInterest.trimmingCharacters(in: .whitespacesAndNewlines))
                                newInterest = ""
                            }
                        }
                        .disabled(newInterest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                // Social Links Section
                Section("Social Links") {
                    ForEach(socialLinks.indices, id: \.self) { index in
                        VStack {
                            Picker("Platform", selection: $socialLinks[index].platform) {
                                Text("Instagram").tag("instagram")
                                Text("Twitter").tag("twitter")
                                Text("TikTok").tag("tiktok")
                                Text("YouTube").tag("youtube")
                                Text("Website").tag("website")
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            TextField("URL", text: $socialLinks[index].url)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .onDelete { indexSet in
                        socialLinks.remove(atOffsets: indexSet)
                    }
                    
                    Button("Add Social Link") {
                        socialLinks.append(ProfileSocialLink(platform: "instagram", url: ""))
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        authManager.resetProfileEditState()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {
                print("🔍 [ProfileEditView] onAppear called, hasLoadedProfileEditData: \(authManager.hasLoadedProfileEditData)")
                print("🔍 [ProfileEditView] Current profileImageIdForEdit: \(authManager.profileImageIdForEdit ?? "nil")")
                
                // Only load profile data if we haven't loaded it AND we don't have a newly uploaded image
                if !authManager.hasLoadedProfileEditData && authManager.profileImageIdForEdit == nil {
                    print("🔍 [ProfileEditView] Loading profile data for the first time...")
                    loadProfileData()
                } else if authManager.profileImageIdForEdit != nil {
                    print("🔍 [ProfileEditView] Skipping profile data load (have newly uploaded image)")
                    // Still need to load the form fields but not the profile image
                    loadFormDataOnly()
                } else {
                    print("🔍 [ProfileEditView] Skipping profile data load (already loaded)")
                }
            }
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
                    dismiss()
                }
            } message: {
                Text(successMessage ?? "")
            }

        }
    }
    
    private func loadFormDataOnly() {
        guard let token = authManager.token else { return }
        
        isLoading = true
        
        let url = URL(string: "\(baseAPIURL)/api/mobile/users/profile/edit")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Failed to load profile: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(ProfileEditResponse.self, from: data)
                    
                    if response.success, let userData = response.data?.user {
                        print("🔍 [ProfileEditView] Loading form data only (preserving uploaded image)...")
                        print("🔍 [ProfileEditView] Current profileImage is nil: \(profileImage == nil)")
                        
                        name = userData.name ?? ""
                        username = userData.username ?? ""
                        bio = userData.bio ?? ""
                        city = userData.location?.city ?? ""
                        state = userData.location?.state ?? ""
                        country = userData.location?.country ?? ""
                        interests = userData.interests ?? []
                        socialLinks = userData.socialLinks?.map { ProfileSocialLink(platform: $0.platform, url: $0.url) } ?? []
                        
                        // Set username cooldown
                        if let cooldown = response.data?.usernameCooldown {
                            canChangeUsername = cooldown.canChange
                            usernameCooldownDays = cooldown.daysRemaining
                        }
                        
                        // IMPORTANT: Don't load the profile image if we have a newly uploaded one
                        // The profileImage variable should already contain the new image from the upload
                        print("🔍 [ProfileEditView] Preserving current profileImage (not loading from server)")
                        
                        authManager.setHasLoadedProfileEditData(true)
                        print("✅ [ProfileEditView] Form data loaded successfully (preserved uploaded image)")
                    } else {
                        print("❌ [ProfileEditView] Failed to load form data: \(response.error ?? "Unknown error")")
                        errorMessage = response.error ?? "Failed to load profile"
                    }
                } catch {
                    errorMessage = "Failed to parse response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func loadProfileData() {
        guard let token = authManager.token else { return }
        
        isLoading = true
        
        let url = URL(string: "\(baseAPIURL)/api/mobile/users/profile/edit")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Failed to load profile: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(ProfileEditResponse.self, from: data)
                    
                    if response.success, let userData = response.data?.user {
                        print("🔍 [ProfileEditView] Loading profile data...")
                        print("🔍 [ProfileEditView] Received profileImage: id=\(userData.profileImage?.id ?? "nil"), url=\(userData.profileImage?.url ?? "nil")")
                        print("🔍 [ProfileEditView] Current profileImageIdForEdit before loading: \(authManager.profileImageIdForEdit ?? "nil")")
                        
                        name = userData.name ?? ""
                        username = userData.username ?? ""
                        bio = userData.bio ?? ""
                        city = userData.location?.city ?? ""
                        state = userData.location?.state ?? ""
                        country = userData.location?.country ?? ""
                        interests = userData.interests ?? []
                        socialLinks = userData.socialLinks?.map { ProfileSocialLink(platform: $0.platform, url: $0.url) } ?? []
                        
                        // Set profileImageIdForEdit from loaded data (this is the initial load)
                        authManager.setProfileImageIdForEdit(userData.profileImage?.id ?? userData.profileImage?.url)
                        print("🔍 [ProfileEditView] Set profileImageIdForEdit from loaded data: \(authManager.profileImageIdForEdit ?? "nil")")
                        
                        // Load profile image if available
                        if let imageUrl = userData.profileImage?.url {
                            print("🔍 [ProfileEditView] Loading profile image from URL: \(imageUrl)")
                            loadProfileImage(from: imageUrl)
                        }
                        
                        // Set username cooldown
                        if let cooldown = response.data?.usernameCooldown {
                            canChangeUsername = cooldown.canChange
                            usernameCooldownDays = cooldown.daysRemaining
                        }
                        
                        authManager.setHasLoadedProfileEditData(true)
                        print("✅ [ProfileEditView] Profile data loaded successfully")
                    } else {
                        print("❌ [ProfileEditView] Failed to load profile: \(response.error ?? "Unknown error")")
                        errorMessage = response.error ?? "Failed to load profile"
                    }
                } catch {
                    errorMessage = "Failed to parse response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func loadProfileImage(from urlString: String) {
        // Add cache-busting timestamp to ensure we get the fresh image
        let timestamp = Int(Date().timeIntervalSince1970)
        let cacheBustedUrl = urlString.contains("?") ? "\(urlString)&t=\(timestamp)" : "\(urlString)?t=\(timestamp)"
        
        guard let url = URL(string: cacheBustedUrl) else { 
            print("❌ [ProfileEditView] Invalid URL for profile image: \(urlString)")
            return 
        }
        
        print("🔍 [ProfileEditView] Loading profile image from cache-busted URL: \(cacheBustedUrl)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ [ProfileEditView] Error loading profile image: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    print("✅ [ProfileEditView] Profile image loaded successfully")
                    profileImage = image
                }
            } else {
                print("❌ [ProfileEditView] Failed to create image from data")
            }
        }.resume()
    }
    
    private func uploadProfileImage(data: Data) {
        guard let token = authManager.token else { return }
        
        print("🔍 [ProfileEditView] Starting image upload...")
        
        let url = URL(string: "\(baseAPIURL)/api/media")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add alt text
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"alt\"\r\n\r\n".data(using: .utf8)!)
        body.append("Profile image\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [ProfileEditView] Image upload error: \(error.localizedDescription)")
                    errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    print("❌ [ProfileEditView] No data received from upload")
                    errorMessage = "No data received from upload"
                    return
                }
                
                // Debug: Log the upload response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 [ProfileEditView] Upload response: \(responseString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(MediaUploadResponse.self, from: data)
                    if let doc = response.doc {
                        print("✅ [ProfileEditView] Image uploaded successfully, new ID: \(doc.id)")
                        print("🔍 [ProfileEditView] Previous profileImageIdForEdit was: \(authManager.profileImageIdForEdit ?? "nil")")
                        print("🔍 [ProfileEditView] Current profileImage is nil: \(profileImage == nil)")
                        authManager.setProfileImageIdForEdit(doc.id)
                        print("🔍 [ProfileEditView] New profileImageIdForEdit set to: \(authManager.profileImageIdForEdit ?? "nil")")
                        print("🔍 [ProfileEditView] Upload complete - profileImage should show new image")
                    } else {
                        print("❌ [ProfileEditView] Upload response missing doc")
                    }
                } catch {
                    print("❌ [ProfileEditView] Failed to parse upload response: \(error.localizedDescription)")
                    errorMessage = "Failed to parse upload response"
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
                            authManager.updateUserData(userData)
                            
                            // Don't refresh the profile image here - it will overwrite the newly uploaded image
                            // The profileImage variable already contains the correct new image
                            print("🔍 [ProfileEditView] Profile updated successfully - keeping current profileImage")
                        }
                        
                        // Don't reset state immediately - let the user see the success message first
                        // The state will be reset when they dismiss the view
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
    let name: String?
    let username: String?
    let bio: String?
    let location: ProfileLocationData?
    let interests: [String]?
    let socialLinks: [SocialLinkData]?
    let profileImage: String?
}

struct ProfileEditResponse: Codable {
    let success: Bool
    let data: ProfileEditData?
    let error: String?
}

struct ProfileEditData: Codable {
    let user: ProfileUserData
    let usernameCooldown: UsernameCooldown?
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
}

struct ProfileUpdateResponse: Codable {
    let success: Bool
    let message: String?
    let data: ProfileUpdateData?
    let error: String?
}

struct ProfileUpdateData: Codable {
    let user: ProfileUserData
}

struct MediaUploadResponse: Codable {
    let doc: MediaDoc?
}

struct MediaDoc: Codable {
    let id: String
}

#Preview {
    ProfileEditView()
} 