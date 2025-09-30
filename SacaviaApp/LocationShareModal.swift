import SwiftUI
import UIKit

struct LocationShareModal: View {
    let location: SearchLocation
    @Binding var isPresented: Bool
    @State private var selectedFriends: Set<String> = []
    @State private var message: String = ""
    @State private var messageType: String = "quick"
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String?
    @State private var friends: [ShareFriend] = []
    @State private var isLoadingFriends: Bool = true
    
    // Quick reply templates
    private let quickReplies = [
        "Check this out!",
        "You should visit this place!",
        "Found an amazing spot!",
        "This looks interesting!"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Location info
                        locationInfoCard
                        
                        // Message section
                        messageSection
                        
                        // Friends selection
                        friendsSelectionSection
                    }
                    .padding()
                }
                
                // Bottom action button
                bottomActionButton
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showSuccess) {
            SuccessView(isPresented: $showSuccess)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .onAppear {
            fetchFriends()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.primary)
                
                Spacer()
                
                Text("Share Location")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Share") {
                    shareLocation()
                }
                .font(.headline)
                .foregroundColor(selectedFriends.isEmpty ? .gray : Color(red: 255/255, green: 107/255, blue: 107/255))
                .disabled(selectedFriends.isEmpty || isLoading)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .padding(.bottom, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Location Info Card
    private var locationInfoCard: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: location.featuredImage ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let address = location.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Message Section
    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a message (optional)")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Quick replies
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickReplies, id: \.self) { reply in
                        Button(reply) {
                            message = reply
                        }
                        .font(.caption)
                        .foregroundColor(message == reply ? .white : Color(red: 255/255, green: 107/255, blue: 107/255))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            message == reply ?
                            Color(red: 255/255, green: 107/255, blue: 107/255) :
                            Color(red: 255/255, green: 107/255, blue: 107/255).opacity(0.1)
                        )
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Custom message
            TextEditor(text: $message)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Friends Selection Section
    private var friendsSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Followers")
                .font(.headline)
                .fontWeight(.semibold)
            
            if isLoadingFriends {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading followers...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if friends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No Followers Found")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("You don't have any followers yet. Share your profile to get followers and share locations with them!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(friends, id: \.id) { friend in
                        FriendSelectionRow(
                            friend: friend,
                            isSelected: selectedFriends.contains(friend.id),
                            onToggle: {
                                toggleFriend(friend.id)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Action Button
    private var bottomActionButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: shareLocation) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("Share with \(selectedFriends.count) friend\(selectedFriends.count == 1 ? "" : "s")")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    selectedFriends.isEmpty ? Color.gray : Color(red: 255/255, green: 107/255, blue: 107/255)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedFriends.isEmpty || isLoading)
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helper Functions
    private func toggleFriend(_ friendId: String) {
        if selectedFriends.contains(friendId) {
            selectedFriends.remove(friendId)
        } else {
            selectedFriends.insert(friendId)
        }
    }
    
    private func shareLocation() {
        isLoading = true
        
        Task {
            do {
                let response = try await APIService.shared.shareLocation(
                    locationId: location.id,
                    recipientIds: Array(selectedFriends),
                    message: message.isEmpty ? "Check this out!" : message,
                    messageType: "check_out"
                )
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                    print("✅ [LocationShareModal] Successfully shared location with \(response.sharesCreated) friends")
                    
                    // Close the modal after successful sharing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isPresented = false
                    }
                }
            } catch {
                print("❌ [LocationShareModal] Error sharing location: \(error)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to share location. Please try again."
                }
            }
        }
    }
    
    private func fetchFriends() {
        isLoadingFriends = true
        
        Task {
            do {
                let fetchedFriends = try await APIService.shared.getFollowers()
                await MainActor.run {
                    self.friends = fetchedFriends
                    self.isLoadingFriends = false
                }
            } catch {
                print("❌ [LocationShareModal] Error fetching followers: \(error)")
                await MainActor.run {
                    self.friends = []
                    self.isLoadingFriends = false
                    self.errorMessage = "Failed to load followers. Please try again."
                }
            }
        }
    }
}

// MARK: - Friend Selection Row
struct FriendSelectionRow: View {
    let friend: ShareFriend
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: friend.profileImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("@\(friend.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            onToggle()
        }
    }
}

// MARK: - Success View
struct SuccessView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Location Shared!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your location has been shared with your friends.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Done") {
                isPresented = false
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(red: 255/255, green: 107/255, blue: 107/255))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Share Friend Model
// ShareFriend is now defined in SharedTypes.swift

// MARK: - Mock Friends Data (removed - now using real API data)
