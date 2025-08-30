import SwiftUI

struct BlockUserView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var feedManager: FeedManager
    @State private var reason = ""
    @State private var showingConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isBlocking = false
    @State private var showingSuccess = false
    
    let targetUserId: String
    let targetUserName: String
    let onUserBlocked: ((String) -> Void)?
    
    private let reasons = [
        "Harassment or bullying",
        "Inappropriate content",
        "Spam or unwanted messages",
        "Fake account",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Warning Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.slash.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        Text("Block User")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Blocking \(targetUserName) will prevent them from seeing your content and interacting with you.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // What happens when you block
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What happens when you block someone:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BlockEffectItem(icon: "eye.slash", text: "They won't see your posts or profile")
                            BlockEffectItem(icon: "message.slash", text: "They can't message or comment on your content")
                            BlockEffectItem(icon: "person.2.slash", text: "You won't see their posts or profile")
                            BlockEffectItem(icon: "arrow.uturn.backward", text: "You can unblock them anytime")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Reason Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reason for blocking (optional)")
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
                    
                    // Block Button
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        HStack {
                            if isBlocking {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "person.slash")
                            }
                            Text(isBlocking ? "Blocking..." : "Block \(targetUserName)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .fontWeight(.semibold)
                    }
                    .disabled(isBlocking)
                    .padding(.horizontal)
                    
                    // Cancel Button
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Block User")
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
        .confirmationDialog("Block User", isPresented: $showingConfirmation) {
            Button("Block \(targetUserName)", role: .destructive) {
                Task {
                    await blockUser()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to block \(targetUserName)? This action can be undone later.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("User Blocked", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("\(targetUserName) has been blocked successfully.")
        }
    }
    
    private func blockUser() async {
        isBlocking = true
        
        do {
            let success = try await APIService.shared.blockUser(
                targetUserId: targetUserId,
                reason: reason.isEmpty ? nil : reason
            )
            
            if success {
                showingSuccess = true
                // Add user to blocked list in FeedManager
                feedManager.addBlockedUser(targetUserId)
                // Call callback to update profile
                onUserBlocked?(targetUserId)
                // Refresh blocked users list in FeedManager
                Task {
                    await feedManager.refreshBlockedUsers()
                }
                // Post notification that user was blocked
                NotificationCenter.default.post(name: NSNotification.Name("UserBlocked"), object: nil)
            } else {
                errorMessage = "Failed to block user. Please try again."
                showingError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isBlocking = false
    }
}

struct BlockEffectItem: View {
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
    BlockUserView(
        targetUserId: "123",
        targetUserName: "John Doe",
        onUserBlocked: nil
    )
}
