import SwiftUI

struct BlockingTestView: View {
    @State private var testUserId = "test_user_123"
    @State private var testUserName = "Test User"
    @State private var showingBlockUser = false
    @State private var showingBlockedUsers = false
    @State private var blockResult = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Blocking System Test")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    Text("Test User ID: \(testUserId)")
                        .font(.headline)
                    
                    Text("Test User Name: \(testUserName)")
                        .font(.headline)
                    
                    if !blockResult.isEmpty {
                        Text("Result: \(blockResult)")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                VStack(spacing: 12) {
                    Button("Test Block User") {
                        showingBlockUser = true
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(25)
                    
                    Button("View Blocked Users") {
                        showingBlockedUsers = true
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
                    
                    Button("Test API Block") {
                        testBlockAPI()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(25)
                    .disabled(isLoading)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Blocking Test")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $showingBlockUser) {
            BlockUserView(
                targetUserId: testUserId,
                targetUserName: testUserName,
                onUserBlocked: { blockedUserId in
                    blockResult = "User \(blockedUserId) blocked successfully!"
                }
            )
        }
        .fullScreenCover(isPresented: $showingBlockedUsers) {
            BlockedUsersListView()
        }
    }
    
    private func testBlockAPI() {
        isLoading = true
        blockResult = "Testing API..."
        
        Task {
            do {
                let success = try await APIService.shared.blockUser(
                    targetUserId: testUserId,
                    reason: "Test blocking"
                )
                
                await MainActor.run {
                    if success {
                        blockResult = "API Block successful!"
                    } else {
                        blockResult = "API Block failed"
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    blockResult = "API Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    BlockingTestView()
}
