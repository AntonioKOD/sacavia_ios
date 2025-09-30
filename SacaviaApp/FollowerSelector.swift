import SwiftUI

struct Follower: Identifiable, Codable {
    let id: String
    let name: String
    let username: String?
    let profileImage: String?
    let avatar: String?
}

struct FollowerSelector: View {
    @Binding var selectedFollowers: [String]
    let userId: String
    let onSelectionChange: ([String]) -> Void
    
    @State private var followers: [Follower] = []
    @State private var loading = true
    @State private var searchText = ""
    @State private var errorMessage: String?
    
    @Environment(\.presentationMode) var presentationMode
    
    var filteredFollowers: [Follower] {
        if searchText.isEmpty {
            return followers
        } else {
            return followers.filter { follower in
                follower.name.localizedCaseInsensitiveContains(searchText) ||
                (follower.username?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if loading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    contentView
                }
            }
            .navigationTitle("Select Friends")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSelectionChange(selectedFollowers)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            fetchFollowers()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading friends...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Error Loading Friends")
                .font(.system(size: 18, weight: .semibold))
            
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Try Again") {
                fetchFollowers()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(red: 1.0, green: 0.42, blue: 0.42))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search friends...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Selection Summary
            if !selectedFollowers.isEmpty {
                HStack {
                    Text("\(selectedFollowers.count) friend\(selectedFollowers.count == 1 ? "" : "s") selected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.42))
                    
                    Spacer()
                    
                    Button("Clear All") {
                        selectedFollowers.removeAll()
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            
            // Friends List
            if filteredFollowers.isEmpty {
                emptyStateView
            } else {
                friendsListView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No Friends Found" : "No Results")
                .font(.system(size: 18, weight: .medium))
            
            Text(searchText.isEmpty ? 
                 "You don't have any friends yet. Add friends to share private locations with them." :
                 "No friends match your search.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var friendsListView: some View {
        List {
            ForEach(filteredFollowers) { follower in
                FollowerRow(
                    follower: follower,
                    isSelected: selectedFollowers.contains(follower.id),
                    onToggle: {
                        toggleFollower(follower.id)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func toggleFollower(_ followerId: String) {
        if selectedFollowers.contains(followerId) {
            selectedFollowers.removeAll { $0 == followerId }
        } else {
            selectedFollowers.append(followerId)
        }
    }
    
    private func fetchFollowers() {
        loading = true
        errorMessage = nil
        
        // For demo purposes, use mock data if userId is test-user
        if userId == "test-user" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.followers = [
                    Follower(
                        id: "mock-friend-1",
                        name: "John Doe",
                        username: "johndoe",
                        profileImage: nil,
                        avatar: nil
                    ),
                    Follower(
                        id: "mock-friend-2",
                        name: "Jane Smith",
                        username: "janesmith",
                        profileImage: nil,
                        avatar: nil
                    ),
                    Follower(
                        id: "mock-friend-3",
                        name: "Mike Johnson",
                        username: "mikej",
                        profileImage: nil,
                        avatar: nil
                    ),
                    Follower(
                        id: "mock-friend-4",
                        name: "Sarah Wilson",
                        username: "sarahw",
                        profileImage: nil,
                        avatar: nil
                    )
                ]
                self.loading = false
            }
            return
        }
        
        // Real API call
        guard let url = URL(string: "\(baseAPIURL)/api/users/friends?userId=\(userId)") else {
            errorMessage = "Invalid URL"
            loading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.loading = false
                
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid response"
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    if let data = data {
                        do {
                            let friendsData = try JSONDecoder().decode([Follower].self, from: data)
                            self.followers = friendsData
                        } catch {
                            self.errorMessage = "Failed to parse friends data"
                        }
                    } else {
                        self.errorMessage = "No data received"
                    }
                } else {
                    self.errorMessage = "Server error: \(httpResponse.statusCode)"
                }
            }
        }.resume()
    }
}

struct FollowerRow: View {
    let follower: Follower
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(red: 1.0, green: 0.42, blue: 0.42) : Color.gray, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.42))
                    }
                }
                
                // Profile Image
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 44, height: 44)
                    
                    if let profileImage = follower.profileImage ?? follower.avatar,
                       !profileImage.isEmpty {
                        AsyncImage(url: URL(string: profileImage)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Text(getInitials(follower.name))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                    } else {
                        Text(getInitials(follower.name))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Name and Username
                VStack(alignment: .leading, spacing: 2) {
                    Text(follower.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let username = follower.username, !username.isEmpty {
                        Text("@\(username)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(red: 1.0, green: 0.42, blue: 0.42).opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color(red: 1.0, green: 0.42, blue: 0.42) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getInitials(_ name: String) -> String {
        return String(name
            .split(separator: " ")
            .map { String($0.prefix(1)) }
            .joined()
            .uppercased()
            .prefix(2))
    }
}

// MARK: - Preview
struct FollowerSelector_Previews: PreviewProvider {
    @State static var selectedFollowers: [String] = ["mock-friend-1"]
    
    static var previews: some View {
        FollowerSelector(
            selectedFollowers: $selectedFollowers,
            userId: "test-user",
            onSelectionChange: { newSelection in
                print("Selection changed: \(newSelection)")
            }
        )
    }
}
