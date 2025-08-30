import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var showSignup = false
    @State private var showForgotPassword = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    
    // Modern minimalistic brand colors
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B - Vivid Coral
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4 - Bright Teal
    private let accentColor = Color(red: 255/255, green: 230/255, blue: 109/255) // #FFE66D - Warm Yellow
    private let backgroundColor = Color(red: 249/255, green: 250/255, blue: 251/255) // #F9FAFB - Ultra Light Gray
    private let textColor = Color(red: 17/255, green: 24/255, blue: 39/255) // #111827 - Very Dark Gray
    private let mutedTextColor = Color(red: 107/255, green: 114/255, blue: 128/255) // #6B7280 - Medium Gray
    private let borderColor = Color(red: 229/255, green: 231/255, blue: 235/255) // #E5E7EB - Light Border
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Clean minimal background
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Logo and header section - responsive spacing
                        VStack(spacing: min(48, geometry.size.height * 0.06)) {
                            // Responsive top spacer based on screen height
                            Spacer()
                                .frame(height: max(20, min(60, geometry.size.height * 0.08)))
                            
                            // Clean logo section without background
                            VStack(spacing: min(24, geometry.size.height * 0.03)) {
                                // Logo image - responsive size (made bigger for better visual impact)
                                Image("Logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: min(120, geometry.size.width * 0.28), 
                                           height: min(120, geometry.size.width * 0.28))
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                                    .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                                
                                // App name and tagline - responsive typography
                                VStack(spacing: min(8, geometry.size.height * 0.01)) {
                                    Text("Sacavia")
                                        .font(.system(size: min(36, geometry.size.width * 0.09), weight: .bold, design: .rounded))
                                        .foregroundColor(textColor)
                                        .tracking(-0.5)
                                    
                                    Text("Discover amazing places & connect with people")
                                        .font(.system(size: min(16, geometry.size.width * 0.04), weight: .medium))
                                        .foregroundColor(mutedTextColor)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .padding(.horizontal, 32)
                                }
                            }
                            
                            // Clean welcome message - responsive
                            VStack(spacing: min(8, geometry.size.height * 0.01)) {
                                Text("Welcome back")
                                    .font(.system(size: min(24, geometry.size.width * 0.06), weight: .semibold))
                                    .foregroundColor(textColor)
                                
                                Text("Sign in to continue your journey")
                                    .font(.system(size: min(15, geometry.size.width * 0.038), weight: .regular))
                                    .foregroundColor(mutedTextColor)
                            }
                        }
                        
                        // Login form - responsive spacing
                        VStack(spacing: min(24, geometry.size.height * 0.03)) {
                            // Email field - minimalistic design
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(textColor)
                                
                                HStack(spacing: 16) {
                                    Image(systemName: "envelope")
                                        .foregroundColor(mutedTextColor)
                                        .frame(width: 18)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    TextField("Enter your email", text: $email)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .font(.system(size: 16, weight: .regular))
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .focused($isEmailFocused)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            isPasswordFocused = true
                                        }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isEmailFocused ? primaryColor : borderColor, lineWidth: isEmailFocused ? 2 : 1)
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                                .animation(.easeInOut(duration: 0.2), value: isEmailFocused)
                            }
                            
                            // Password field - minimalistic design
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(textColor)
                                
                                HStack(spacing: 16) {
                                    Image(systemName: "lock")
                                        .foregroundColor(mutedTextColor)
                                        .frame(width: 18)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    if isPasswordVisible {
                                        TextField("Enter your password", text: $password)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .font(.system(size: 16, weight: .regular))
                                            .focused($isPasswordFocused)
                                            .submitLabel(.done)
                                            .onSubmit {
                                                handleLogin()
                                            }
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .font(.system(size: 16, weight: .regular))
                                            .focused($isPasswordFocused)
                                            .submitLabel(.done)
                                            .onSubmit {
                                                handleLogin()
                                            }
                                    }
                                    
                                    Button(action: {
                                        isPasswordVisible.toggle()
                                    }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                            .foregroundColor(mutedTextColor)
                                            .frame(width: 18)
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isPasswordFocused ? primaryColor : borderColor, lineWidth: isPasswordFocused ? 2 : 1)
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                                .animation(.easeInOut(duration: 0.2), value: isPasswordFocused)
                            }
                            
                            // Forgot password - minimal style
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showForgotPassword = true
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(primaryColor)
                            }
                            .padding(.top, -8)
                            
                            // Login button - modern and clean
                            Button(action: handleLogin) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.9)
                                    } else {
                                        Text("Sign In")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: primaryColor.opacity(0.25), radius: 16, x: 0, y: 8)
                            }
                            .disabled(authManager.isLoading)
                            .scaleEffect(authManager.isLoading ? 0.98 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: authManager.isLoading)
                            .padding(.top, 8)
                            
                            // Sign up section - minimal design
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .font(.system(size: 15))
                                    .foregroundColor(mutedTextColor)
                                
                                Button("Sign Up") {
                                    showSignup = true
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(primaryColor)
                            }
                            .padding(.top, min(24, geometry.size.height * 0.03))
                            .padding(.bottom, max(20, min(60, geometry.size.height * 0.08)))
                        }
                        .padding(.horizontal, min(32, geometry.size.width * 0.08))
                        .padding(.top, max(20, min(48, geometry.size.height * 0.06)))
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom) {
                    // Ensure content is visible above keyboard and bottom safe area
                    Color.clear.frame(height: max(keyboardHeight, 0))
                }
                .onTapGesture {
                    // Dismiss keyboard when tapping outside
                    isEmailFocused = false
                    isPasswordFocused = false
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)

        .alert("Login Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .fullScreenCover(isPresented: $showSignup) {
            SignupView()
        }
        .fullScreenCover(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .onAppear {
            // Set up keyboard notifications to prevent constraint conflicts
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { _ in
                keyboardHeight = 0
            }
            
            // Debug: Check current authentication state
            print("🔐 LoginView appeared - Auth state: \(authManager.isAuthenticated)")
            print("🔐 LoginView appeared - User: \(authManager.user?.name ?? "None")")
        }
    }
    
    private func handleLogin() {
        guard !email.isEmpty && !password.isEmpty else {
            alertMessage = "Please fill in all fields"
            showAlert = true
            return
        }
        
        print("🔐 Login attempt - Email: \(email)")
        print("🔐 Login attempt - AuthManager state before: \(authManager.isAuthenticated)")
        
        // Use AuthManager for authentication
        authManager.login(email: email, password: password, rememberMe: true) { error in
            if let error = error {
                print("❌ Login failed - Error: \(error)")
                alertMessage = error
                showAlert = true
            } else {
                // Login successful - AuthManager will handle the authentication state
                print("✅ Login successful - User authenticated: \(authManager.isAuthenticated)")
                print("✅ Login successful - User: \(authManager.user?.name ?? "None")")
            }
        }
    }
}

// Custom modifier to handle keyboard constraints
struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillShowNotification,
                    object: nil,
                    queue: .main
                ) { notification in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        keyboardHeight = keyboardFrame.height
                    }
                }
                
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillHideNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    keyboardHeight = 0
                }
            }
    }
}

extension View {
    func keyboardAdaptive() -> some View {
        modifier(KeyboardAdaptive())
    }
}

#Preview {
    LoginView()
} 