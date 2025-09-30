import SwiftUI
import CoreLocation
import Foundation
// Import Utils for baseAPIURL constant

// Import the canonical Category model and other shared types
// (Assume SharedTypes.swift is in the same module or add the correct import if needed)

// Remove the local struct Category and CategoriesResponse
// Use the Category model from SharedTypes.swift

// MARK: - Username Validation Models
struct UsernameValidationResponse: Codable {
    let success: Bool
    let available: Bool?
    let error: String?
    let errorType: String?
    let code: String?
    let suggestions: [String]?
    let message: String?
}

struct EmailValidationResponse: Codable {
    let success: Bool
    let available: Bool?
    let error: String?
    let message: String?
    let errorType: String?
    let code: String?
    let email: String?
}

enum UsernameValidationState {
    case idle
    case checking
    case available
    case unavailable(String, [String])
    case invalid(String)
}

enum EmailValidationState {
    case idle
    case checking
    case valid
    case invalid(String)
    case alreadyExists
}

enum NameValidationState {
    case idle
    case valid
    case invalid(String)
}

struct SignupView: View {
    @State private var currentStep = 1
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @ObservedObject var auth = AuthManager.shared
    @Environment(\.dismiss) var dismiss
    
    // Step 1: Basic Info
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var usernameValidationState: UsernameValidationState = .idle
    @State private var emailValidationState: EmailValidationState = .idle
    @State private var nameValidationState: NameValidationState = .idle
    @State private var termsAccepted = false
    @State private var privacyAccepted = false
    @State private var receiveUpdates = true
    
    // Step 2: Interests
    @State private var selectedInterests: Set<String> = []
    @State private var categories: [Category] = []
    @State private var isLoadingCategories = false
    @State private var categoriesError: String?
    
    // Step 3: Preferences
    @State private var primaryUseCase = ""
    @State private var travelRadius = "5 miles"
    @State private var budgetPreference = ""
    
    // Location
    @StateObject private var locationManager = LocationManager()
    
    // State for email verification
    @State private var showVerifyEmail = false
    
    // Web app colors
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    private let backgroundColor = Color(red: 243/255, green: 244/255, blue: 246/255) // #F3F4F6
    private let textColor = Color(red: 51/255, green: 51/255, blue: 51/255) // #333333
    private let mutedTextColor = Color(red: 102/255, green: 102/255, blue: 102/255) // #666666
    
    private let useCaseOptions = [
        "explore",
        "plan",
        "share",
        "connect"
    ]
    
    private let budgetOptions = [
        "free",
        "budget",
        "moderate",
        "premium",
        "luxury"
    ]
    
    private let travelRadiusOptions = [
        "5 miles",
        "10 miles",
        "25 miles",
        "50+ miles"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        backgroundColor,
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom navigation bar for iPad
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(mutedTextColor)
                        }
                        .padding()
                        
                        Spacer()
                        
                        Text("Create Account")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        // Invisible button for balance
                        Button(action: {}) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.clear)
                        }
                        .padding()
                    }
                    .background(Color.white.opacity(0.9))
                    
                    // Progress indicator matching web app
                    VStack(spacing: 8) {
                        HStack {
                            Text("Step \(currentStep) of 3")
                                .font(.caption)
                                .foregroundColor(mutedTextColor)
                            Spacer()
                            Text("\(Int((Double(currentStep) / 3.0) * 100))% complete")
                                .font(.caption)
                                .foregroundColor(mutedTextColor)
                        }
                        
                        // Progress bar with web app gradient - iPad optimized
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: min(geometry.size.width * 0.8, 600) * (Double(currentStep) / 3.0), height: 8)
                                .cornerRadius(4)
                                .animation(.easeInOut(duration: 0.3), value: currentStep)
                        }
                    }
                    .padding()
                    
                    // Step content with proper iPad sizing
                    ScrollView {
                        VStack(spacing: 20) {
                            switch currentStep {
                            case 1:
                                basicInfoStep
                            case 2:
                                interestsStep
                            case 3:
                                preferencesStep
                            default:
                                EmptyView()
                            }
                        }
                        .padding()
                        .frame(maxWidth: min(geometry.size.width * 0.9, 800))
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Navigation buttons
                    navigationButtons
                        .frame(maxWidth: min(geometry.size.width * 0.9, 800))
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .onAppear {
            locationManager.requestLocation()
            if categories.isEmpty {
                fetchCategories()
            }
        }
        .fullScreenCover(isPresented: $showVerifyEmail) {
            VerifyEmailView(onDismiss: { 
                showVerifyEmail = false
                dismiss() // Dismiss the entire SignupView sheet
            })
        }
    }
    
    // MARK: - Step Views
    
    private var basicInfoStep: some View {
        VStack(spacing: 16) {
            Text("Create your account")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
            
            Text("Enter your details to get started")
                .font(.subheadline)
                .foregroundColor(mutedTextColor)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                NameTextField(
                    title: "Full Name",
                    text: $name,
                    placeholder: "Enter your full name",
                    validationState: $nameValidationState
                )
                
                UsernameTextField(
                    title: "Username",
                    text: $username,
                    placeholder: "Choose a username",
                    validationState: $usernameValidationState
                )
                
                EmailTextField(
                    title: "Email",
                    text: $email,
                    placeholder: "your@email.com",
                    validationState: $emailValidationState
                )
                
                CustomSecureField(title: "Password", text: $password, placeholder: "Create a secure password", icon: "lock")
                
                // Password strength indicator
                if !password.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password strength:")
                            .font(.caption)
                            .foregroundColor(mutedTextColor)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<4, id: \.self) { index in
                                Rectangle()
                                    .fill(passwordStrengthColor(for: index))
                                    .frame(height: 4)
                                    .cornerRadius(2)
                            }
                        }
                        
                        Text(passwordStrengthText)
                            .font(.caption)
                            .foregroundColor(passwordStrengthColor(for: 3))
                    }
                }
                
                CustomSecureField(title: "Confirm Password", text: $confirmPassword, placeholder: "Confirm your password")
                
                if !confirmPassword.isEmpty && password != confirmPassword {
                    Text("Passwords don't match")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            VStack(spacing: 12) {
                HStack {
                    Toggle("I accept the Terms of Service", isOn: $termsAccepted)
                    Button("View Terms") {
                        if let url = URL(string: "https://sacavia.com/terms") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(primaryColor)
                }
                
                HStack {
                    Toggle("I accept the Privacy Policy", isOn: $privacyAccepted)
                    Button("View Privacy") {
                        if let url = URL(string: "https://sacavia.com/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(primaryColor)
                }
                
                Toggle("Receive updates from Sacavia", isOn: $receiveUpdates)
            }
            .padding(.vertical)
        }
    }
    
    private var interestsStep: some View {
        VStack(spacing: 16) {
            Text("What interests you?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
            
            Text("Select your interests for personalized recommendations")
                .font(.subheadline)
                .foregroundColor(mutedTextColor)
                .multilineTextAlignment(.center)
            
            if isLoadingCategories {
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading categories...")
                        .foregroundColor(mutedTextColor)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = categoriesError {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text("Failed to load categories")
                        .font(.headline)
                        .foregroundColor(textColor)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(mutedTextColor)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        fetchCategories()
                    }
                    .foregroundColor(primaryColor)
                }
                .padding()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(categories, id: \.id) { category in
                        InterestButton(
                            title: category.name,
                            emoji: getEmojiForCategory(category.slug ?? ""),
                            isSelected: selectedInterests.contains(category.id),
                            action: {
                                if selectedInterests.contains(category.id) {
                                    selectedInterests.remove(category.id)
                                } else {
                                    selectedInterests.insert(category.id)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var preferencesStep: some View {
        VStack(spacing: 16) {
            Text("Your preferences")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
            
            Text("Tell us about your exploration style")
                .font(.subheadline)
                .foregroundColor(mutedTextColor)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                // Primary use case
                VStack(alignment: .leading, spacing: 8) {
                    Text("How will you primarily explore with Sacavia?")
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(useCaseOptions, id: \.self) { option in
                            PreferenceButton(
                                title: getUseCaseDisplayName(option),
                                emoji: getUseCaseEmoji(option),
                                isSelected: primaryUseCase == option,
                                action: { primaryUseCase = option }
                            )
                        }
                    }
                }
                
                // Travel radius
                VStack(alignment: .leading, spacing: 8) {
                    Text("Travel radius preference")
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(travelRadiusOptions, id: \.self) { option in
                            PreferenceButton(
                                title: option,
                                emoji: "🚗", // Default emoji for options
                                isSelected: travelRadius == option,
                                action: { travelRadius = option }
                            )
                        }
                    }
                }
                
                // Budget preference
                VStack(alignment: .leading, spacing: 8) {
                    Text("Budget preference")
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(budgetOptions, id: \.self) { option in
                            PreferenceButton(
                                title: getBudgetDisplayName(option),
                                emoji: getBudgetEmoji(option),
                                isSelected: budgetPreference == option,
                                action: { budgetPreference = option }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 1 {
                Button("Back") {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .foregroundColor(.primary)
                .padding()
            }
            
            Spacer()
            
            Button(action: {
                if currentStep < 3 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    handleSignup()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(currentStep == 3 ? "Complete Setup" : "Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    if !isLoading {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [primaryColor, secondaryColor]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(!canProceed() || isLoading)
            .opacity(canProceed() ? 1.0 : 0.5)
            .padding()
        }
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -4)
    }
    
    // MARK: - Helper Functions
    
    private func fetchCategories() {
        isLoadingCategories = true
        categoriesError = nil
        
        guard let url = URL(string: "\(baseAPIURL)/api/categories") else {
            categoriesError = "Invalid URL"
            isLoadingCategories = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoadingCategories = false
                
                if let error = error {
                    self.categoriesError = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.categoriesError = "No data received"
                    return
                }
                
                do {
                    struct CategoriesResponse: Decodable { 
                        let docs: [Category] 
                    }
                    let response = try JSONDecoder().decode(CategoriesResponse.self, from: data)
                    self.categories = response.docs
                } catch {
                    self.categoriesError = "Failed to decode categories: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func getEmojiForCategory(_ slug: String) -> String {
        let emojiMap: [String: String] = [
            "coffee": "☕️",
            "restaurants": "🍽️",
            "nature": "🌲",
            "photography": "📸",
            "nightlife": "🌙",
            "shopping": "🛍️",
            "arts": "🎨",
            "sports": "⚽️",
            "markets": "🛒",
            "events": "🎪"
        ]
        return emojiMap[slug] ?? "📍"
    }
    
    private func canProceed() -> Bool {
        switch currentStep {
        case 1:
            let usernameValid: Bool
            switch usernameValidationState {
            case .available:
                usernameValid = true
            default:
                usernameValid = false
            }
            
            let emailValid: Bool
            switch emailValidationState {
            case .valid:
                emailValid = true
            default:
                emailValid = false
            }
            
            let nameValid: Bool
            switch nameValidationState {
            case .valid:
                nameValid = true
            default:
                nameValid = false
            }
            
            return !name.isEmpty && !email.isEmpty && !password.isEmpty && 
                   !confirmPassword.isEmpty && password == confirmPassword && 
                   !username.isEmpty && usernameValid && emailValid && nameValid &&
                   termsAccepted && privacyAccepted
        case 2:
            return !selectedInterests.isEmpty
        case 3:
            return !primaryUseCase.isEmpty && !travelRadius.isEmpty && !budgetPreference.isEmpty
        default:
            return false
        }
    }
    
    private func passwordStrengthColor(for index: Int) -> Color {
        let strength = passwordStrength
        if index < strength {
            switch strength {
            case 1: return .red
            case 2: return .orange
            case 3: return .yellow
            case 4: return .green
            default: return .gray
            }
        }
        return .gray.opacity(0.3)
    }
    
    private var passwordStrength: Int {
        var strength = 0
        if password.count >= 8 { strength += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { strength += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { strength += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { strength += 1 }
        return strength
    }
    
    private var passwordStrengthText: String {
        switch passwordStrength {
        case 0, 1: return "Weak"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Strong"
        default: return "Weak"
        }
    }
    
    private func parseTravelRadius(_ radiusString: String) -> Int {
        switch radiusString {
        case "5 miles": return 5
        case "10 miles": return 10
        case "25 miles": return 25
        case "50+ miles": return 50
        default: return 5
        }
    }
    
    private func getUseCaseDisplayName(_ useCase: String) -> String {
        switch useCase {
        case "explore": return "Explore"
        case "plan": return "Plan"
        case "share": return "Share"
        case "connect": return "Connect"
        default: return useCase
        }
    }
    
    private func getUseCaseEmoji(_ useCase: String) -> String {
        switch useCase {
        case "explore": return "🔍"
        case "plan": return "📋"
        case "share": return "📤"
        case "connect": return "🤝"
        default: return "📍"
        }
    }
    
    private func getBudgetDisplayName(_ budget: String) -> String {
        switch budget {
        case "free": return "Free"
        case "budget": return "Budget"
        case "moderate": return "Moderate"
        case "premium": return "Premium"
        case "luxury": return "Luxury"
        default: return budget
        }
    }
    
    private func getBudgetEmoji(_ budget: String) -> String {
        switch budget {
        case "free": return "🆓"
        case "budget": return "💰"
        case "moderate": return "💳"
        case "premium": return "💎"
        case "luxury": return "👑"
        default: return "💰"
        }
    }
    
    private func handleSignup() {
        isLoading = true
        errorMessage = nil
        
        let signupRequest = EnhancedSignupRequest(
            name: name,
            username: username,
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            coords: locationManager.location.map { coordinates in
                Coordinates(
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude
                )
            },
            preferences: Preferences(
                categories: Array(selectedInterests),
                notifications: true,
                radius: parseTravelRadius(travelRadius)
            ),
            additionalData: AdditionalData(
                interests: Array(selectedInterests),
                receiveUpdates: receiveUpdates,
                onboardingData: OnboardingData(
                    primaryUseCase: primaryUseCase,
                    travelRadius: travelRadius,
                    budgetPreference: budgetPreference,
                    onboardingCompleted: true,
                    signupStep: 3
                )
            ),
            deviceInfo: DeviceInfo(
                deviceId: UIDevice.current.identifierForVendor?.uuidString,
                platform: "ios",
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.9.81"
            ),
            termsAccepted: termsAccepted,
            privacyAccepted: privacyAccepted
        )
        
        auth.signup(request: signupRequest) { error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error
                    self.showError = true
                } else {
                    self.showVerifyEmail = true
                }
            }
        }
    }
}


// MARK: - Supporting Views

struct UsernameTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @Binding var validationState: UsernameValidationState
    
    @FocusState private var isFocused: Bool
    @State private var validationTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
            
            HStack(spacing: 10) {
                TextField(placeholder, text: $text)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                    .focused($isFocused)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .onChange(of: text) { _ in
                        validateUsername()
                    }
                
                // Validation status indicator
                validationStatusIcon
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
            
            // Validation message and suggestions
            validationMessage
        }
    }
    
    private var validationStatusIcon: some View {
        Group {
            switch validationState {
            case .idle:
                EmptyView()
            case .checking:
                ProgressView()
                    .scaleEffect(0.8)
            case .available:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .unavailable:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .invalid:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var borderColor: Color {
        switch validationState {
        case .available:
            return .green
        case .unavailable, .invalid:
            return .red
        case .checking:
            return Color(red: 255/255, green: 107/255, blue: 107/255)
        case .idle:
            return isFocused ? Color(red: 255/255, green: 107/255, blue: 107/255) : Color.gray.opacity(0.18)
        }
    }
    
    private var validationMessage: some View {
        Group {
            switch validationState {
            case .idle:
                EmptyView()
            case .checking:
                Text("Checking availability...")
                    .font(.caption)
                    .foregroundColor(.blue)
            case .available:
                Text("Username is available!")
                    .font(.caption)
                    .foregroundColor(.green)
            case .unavailable(let error, let suggestions):
                VStack(alignment: .leading, spacing: 8) {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    if !suggestions.isEmpty {
                        Text("Suggestions:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 4) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button(action: {
                                    text = suggestion
                                }) {
                                    Text(suggestion)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            case .invalid(let error):
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private func validateUsername() {
        // Cancel previous timer
        validationTimer?.invalidate()
        
        // Reset state if empty
        if text.isEmpty {
            validationState = .idle
            return
        }
        
        // Set checking state
        validationState = .checking
        
        // Debounce validation
        validationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            performValidation()
        }
    }
    
    private func performValidation() {
        guard !text.isEmpty else {
            validationState = .idle
            return
        }
        
        let urlString = "\(baseAPIURL)/api/mobile/users/check-username?username=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            validationState = .invalid("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.validationState = .invalid("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self.validationState = .invalid("No data received")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(UsernameValidationResponse.self, from: data)
                    
                    if response.success, response.available == true {
                        self.validationState = .available
                    } else if let error = response.error {
                        if let suggestions = response.suggestions, !suggestions.isEmpty {
                            self.validationState = .unavailable(error, suggestions)
                        } else {
                            self.validationState = .invalid(error)
                        }
                    } else {
                        self.validationState = .invalid("Unknown error")
                    }
                } catch {
                    self.validationState = .invalid("Failed to parse response")
                }
            }
        }.resume()
    }
}

struct EmailTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @Binding var validationState: EmailValidationState
    
    @FocusState private var isFocused: Bool
    @State private var validationTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
            HStack(spacing: 10) {
                Image(systemName: "envelope")
                    .foregroundColor(isFocused ? Color(red: 255/255, green: 107/255, blue: 107/255) : Color.gray.opacity(0.7))
                    .frame(width: 20)
                TextField(placeholder, text: $text)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
                    .onChange(of: text) { _ in
                        validateEmail()
                    }
                
                // Validation status icon
                validationStatusIcon
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            
            // Validation message
            if case .invalid(let message) = validationState {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
            } else if case .alreadyExists = validationState {
                Text("This email is already registered")
                    .font(.caption)
                    .foregroundColor(.red)
            } else if case .valid = validationState {
                Text("Email looks good!")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    private var borderColor: Color {
        switch validationState {
        case .idle:
            return isFocused ? Color(red: 255/255, green: 107/255, blue: 107/255) : Color.gray.opacity(0.3)
        case .checking:
            return Color.orange
        case .valid:
            return .green
        case .invalid, .alreadyExists:
            return .red
        }
    }
    
    private var validationStatusIcon: some View {
        Group {
            switch validationState {
            case .idle:
                EmptyView()
            case .checking:
                ProgressView()
                    .scaleEffect(0.8)
                    .foregroundColor(.orange)
            case .valid:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .invalid, .alreadyExists:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func validateEmail() {
        // Cancel previous timer
        validationTimer?.invalidate()
        
        // Reset state if empty
        if text.isEmpty {
            validationState = .idle
            return
        }
        
        // Basic email format validation first
        if !isValidEmailFormat(text) {
            validationState = .invalid("Please enter a valid email address")
            return
        }
        
        // Set checking state
        validationState = .checking
        
        // Debounce validation
        validationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            performEmailValidation()
        }
    }
    
    private func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func performEmailValidation() {
        guard !text.isEmpty && isValidEmailFormat(text) else {
            validationState = .invalid("Please enter a valid email address")
            return
        }
        
        let urlString = "\(baseAPIURL)/api/mobile/users/check-email?email=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            validationState = .invalid("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.validationState = .invalid("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self.validationState = .invalid("No data received")
                    return
                }
                
                do {
                    // First try to decode as EmailValidationResponse
                    let response = try JSONDecoder().decode(EmailValidationResponse.self, from: data)
                    
                    if response.success, response.available == true {
                        self.validationState = .valid
                    } else if response.available == false {
                        self.validationState = .alreadyExists
                    } else if let error = response.error {
                        self.validationState = .invalid(error)
                    } else if let message = response.message {
                        self.validationState = .invalid(message)
                    } else {
                        self.validationState = .invalid("Email validation failed")
                    }
                } catch {
                    // If EmailValidationResponse fails, try UsernameValidationResponse as fallback
                    do {
                        let response = try JSONDecoder().decode(UsernameValidationResponse.self, from: data)
                        
                        if response.success, response.available == true {
                            self.validationState = .valid
                        } else if response.available == false {
                            self.validationState = .alreadyExists
                        } else if let error = response.error {
                            self.validationState = .invalid(error)
                        } else {
                            self.validationState = .invalid("Email validation failed")
                        }
                    } catch {
                        // If both fail, show the raw response for debugging
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("🔍 [EmailValidation] Failed to parse response: \(responseString)")
                            self.validationState = .invalid("Invalid response format")
                        } else {
                            self.validationState = .invalid("Failed to parse response")
                        }
                    }
                }
            }
        }.resume()
    }
}

struct NameTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @Binding var validationState: NameValidationState
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
            HStack(spacing: 10) {
                Image(systemName: "person")
                    .foregroundColor(isFocused ? Color(red: 255/255, green: 107/255, blue: 107/255) : Color.gray.opacity(0.7))
                    .frame(width: 20)
                TextField(placeholder, text: $text)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                    .focused($isFocused)
                    .onChange(of: text) { _ in
                        validateName()
                    }
                
                // Validation status icon
                validationStatusIcon
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            
            // Validation message
            if case .invalid(let message) = validationState {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
            } else if case .valid = validationState {
                Text("Name looks good!")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    private var borderColor: Color {
        switch validationState {
        case .idle:
            return isFocused ? Color(red: 255/255, green: 107/255, blue: 107/255) : Color.gray.opacity(0.3)
        case .valid:
            return .green
        case .invalid:
            return .red
        }
    }
    
    private var validationStatusIcon: some View {
        Group {
            switch validationState {
            case .idle:
                EmptyView()
            case .valid:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .invalid:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func validateName() {
        let trimmedName = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            validationState = .idle
        } else if trimmedName.count < 2 {
            validationState = .invalid("Name must be at least 2 characters")
        } else if trimmedName.count > 50 {
            validationState = .invalid("Name must be less than 50 characters")
        } else if !isValidNameFormat(trimmedName) {
            validationState = .invalid("Name contains invalid characters")
        } else {
            validationState = .valid
        }
    }
    
    private func isValidNameFormat(_ name: String) -> Bool {
        // Allow letters, spaces, hyphens, and apostrophes
        let nameRegex = "^[a-zA-Z\\s\\-']+$"
        let namePredicate = NSPredicate(format: "SELF MATCHES %@", nameRegex)
        return namePredicate.evaluate(with: name)
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var icon: String? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(isFocused ? Color(red: 255/255, green: 107/255, blue: 107/255) : Color.gray.opacity(0.7))
                        .frame(width: 20)
                }
                TextField(placeholder, text: $text)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                    .focused($isFocused)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color(red: 255/255, green: 107/255, blue: 107/255) : Color.gray.opacity(0.18), lineWidth: 2)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
        }
    }
}

struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var icon: String? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(isFocused ? Color(red: 255/255, green: 107/255, blue: 107/255) : Color.gray.opacity(0.7))
                        .frame(width: 20)
                }
                SecureField(placeholder, text: $text)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                    .focused($isFocused)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color(red: 255/255, green: 107/255, blue: 107/255) : Color.gray.opacity(0.18), lineWidth: 2)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
        }
    }
}

// In InterestButton and PreferenceButton, ensure text and icons use .primary or a dark color unless selected (then use brand color)
struct InterestButton: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.title2)
                    .foregroundColor(isSelected ? Color(red: 78/255, green: 205/255, blue: 196/255) : .primary)
                
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color(red: 78/255, green: 205/255, blue: 196/255).opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(red: 78/255, green: 205/255, blue: 196/255) : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct PreferenceButton: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.title2)
                    .foregroundColor(isSelected ? Color(red: 78/255, green: 205/255, blue: 196/255) : .primary)
                
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color(red: 78/255, green: 205/255, blue: 196/255).opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(red: 78/255, green: 205/255, blue: 196/255) : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first?.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}

// MARK: - Preview

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}

// In VerifyEmailView, ensure all text is dark except for the button (which is on a gradient background)
struct VerifyEmailView: View {
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 243/255, green: 244/255, blue: 246/255),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "envelope.badge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(red: 255/255, green: 107/255, blue: 107/255))
                
                Text("Verify Your Email")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                
                Text("We've sent a verification link to your email. Please check your inbox and follow the instructions to activate your account.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                    .padding(.horizontal)
                
                Button(action: onDismiss) {
                    Text("Back to Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 255/255, green: 107/255, blue: 107/255),
                                    Color(red: 78/255, green: 205/255, blue: 196/255)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color(red: 255/255, green: 107/255, blue: 107/255).opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
} 
