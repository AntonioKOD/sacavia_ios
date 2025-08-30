import SwiftUI

struct SwipeablePeopleSuggestionsView: View {
    @StateObject private var peopleSuggestionsManager = PeopleSuggestionsManager()
    @State private var showProfile: Bool = false
    @State private var selectedUserId: String = ""
    @Binding var selectedFeedFilter: FeedFilter
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(primaryColor)
                    .font(.system(size: 16, weight: .medium))
                
                Text("People You May Know")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("See All") {
                    selectedFeedFilter = .people
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(primaryColor)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            if peopleSuggestionsManager.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(primaryColor)
                    Text("Finding people...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            } else if peopleSuggestionsManager.suggestions.isEmpty {
                HStack {
                    Image(systemName: "person.3")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    Text("No people suggestions available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            } else {
                // Swipeable people cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(peopleSuggestionsManager.suggestions.prefix(3)) { category in
                            ForEach(category.users.prefix(5), id: \.id) { person in
                                SwipeablePeopleCard(
                                    person: person,
                                    onFollow: { userId in
                                        peopleSuggestionsManager.followUser(userId)
                                    },
                                    onTap: { userId in
                                        selectedUserId = userId
                                        showProfile = true
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            peopleSuggestionsManager.fetchPeopleSuggestions()
        }
        .navigationDestination(isPresented: $showProfile) {
            // TODO: Fix ProfileView access - temporarily using placeholder
            VStack {
                Text("Profile for User")
                    .font(.title2)
                    .padding()
                Text("User ID: \(selectedUserId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SwipeablePeopleCard: View {
    let person: EnhancedFeedPerson
    let onFollow: (String) -> Void
    let onTap: (String) -> Void
    
    @State private var isFollowing: Bool
    @State private var isLoading = false
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    
    init(person: EnhancedFeedPerson, onFollow: @escaping (String) -> Void, onTap: @escaping (String) -> Void) {
        self.person = person
        self.onFollow = onFollow
        self.onTap = onTap
        self._isFollowing = State(initialValue: person.isFollowing)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Profile image
            Button(action: { onTap(person.id) }) {
                ZStack {
                    if let profileImage = person.profileImage {
                        AsyncImage(url: URL(string: profileImage)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color(.systemGray5)
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(person.name.prefix(1)).uppercased())
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    // Verified badge
                    if person.isVerified ?? false {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                    .background(Circle().fill(.white))
                                    .font(.system(size: 14))
                            }
                            Spacer()
                        }
                        .frame(width: 60, height: 60)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // User info
            VStack(spacing: 2) {
                Text(person.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let username = person.username {
                    Text("@\(username)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Mutual followers or distance
                if person.mutualFollowers > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 10))
                        Text("\(person.mutualFollowers)")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                } else if let distance = person.distance {
                    HStack(spacing: 2) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                        Text(formatDistance(distance))
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Follow button
            Button(action: {
                handleFollowAction()
            }) {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isFollowing ? .primary : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isFollowing ? Color(.systemGray5) : primaryColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFollowing ? Color(.systemGray4) : Color.clear, lineWidth: 1)
                    )
            }
            .disabled(isLoading)
            .opacity(isLoading ? 0.6 : 1.0)
        }
        .frame(width: 100)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func handleFollowAction() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isFollowing.toggle()
            onFollow(person.id)
            isLoading = false
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1 {
            return "<1mi"
        } else if distance < 10 {
            return String(format: "%.1f", distance)
        } else {
            return String(format: "%.0f", distance)
        }
    }
} 