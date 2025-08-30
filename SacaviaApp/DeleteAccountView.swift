import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var password = ""
    @State private var reason = ""
    @State private var showingConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isDeleting = false
    @State private var showingSuccess = false
    
    private let reasons = [
        "I no longer use this app",
        "Privacy concerns",
        "Too many notifications",
        "Found a better alternative",
        "Technical issues",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Warning Header
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        Text("Delete Account")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("This action cannot be undone. All your data, including posts, guides, events, and saved content will be permanently deleted.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Password Verification
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter your password to confirm")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(.horizontal)
                    
                    // Reason Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why are you deleting your account?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("Reason", selection: $reason) {
                            Text("Select a reason").tag("")
                            ForEach(reasons, id: \.self) { reason in
                                Text(reason).tag(reason)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Custom Reason (if "Other" is selected)
                    if reason == "Other" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Please specify")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your reason", text: $reason, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Data Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What will be deleted:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DataItem(icon: "doc.text", text: "All your posts and reviews")
                            DataItem(icon: "book", text: "Published guides and content")
                            DataItem(icon: "calendar", text: "Created events")
                            DataItem(icon: "heart", text: "Saved locations and posts")
                            DataItem(icon: "person.2", text: "Followers and following relationships")
                            DataItem(icon: "star", text: "Achievements and badges")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Delete Button
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        HStack {
                            if isDeleting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "trash")
                            }
                            Text(isDeleting ? "Deleting..." : "Delete Account")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .fontWeight(.semibold)
                    }
                    .disabled(password.isEmpty || reason.isEmpty || isDeleting)
                    .padding(.horizontal)
                    
                    // Cancel Button
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .confirmationDialog("Delete Account", isPresented: $showingConfirmation) {
            Button("Delete My Account", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you absolutely sure? This action cannot be undone and all your data will be permanently lost.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Account Deleted", isPresented: $showingSuccess) {
            Button("OK") {
                // Navigate to login screen
                authManager.logout()
            }
        } message: {
            Text("Your account has been successfully deleted. You will be logged out.")
        }
    }
    
    private func deleteAccount() async {
        isDeleting = true
        
        do {
            let success = try await APIService.shared.deleteAccount(
                password: password,
                reason: reason
            )
            
            if success {
                showingSuccess = true
            } else {
                errorMessage = "Failed to delete account. Please try again."
                showingError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isDeleting = false
    }
}

struct DataItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.red)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    DeleteAccountView()
}
