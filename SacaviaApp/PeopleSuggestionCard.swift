import SwiftUI

struct PeopleSuggestionCard: View {
    let person: EnhancedFeedPerson
    let onFollow: (String) -> Void
    let onTap: (String) -> Void
    let showFollowButton: Bool // New parameter to control follow button visibility
    
    @State private var isFollowing: Bool
    @State private var isLoading = false
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    init(person: EnhancedFeedPerson, onFollow: @escaping (String) -> Void, onTap: @escaping (String) -> Void, showFollowButton: Bool = true) {
        self.person = person
        self.onFollow = onFollow
        self.onTap = onTap
        self.showFollowButton = showFollowButton
        self._isFollowing = State(initialValue: person.isFollowing)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            HStack(spacing: 12) {
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
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(person.name.prefix(1)).uppercased())
                                        .font(.system(size: 20, weight: .semibold))
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
                                        .font(.system(size: 12))
                                }
                                Spacer()
                            }
                            .frame(width: 50, height: 50)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(person.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if person.isCreator ?? false {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 10))
                        }
                        
                        Spacer()
                    }
                    
                    if let username = person.username {
                        Text("@\(username)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Mutual followers or distance
                    if person.mutualFollowers > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))
                            Text("\(person.mutualFollowers) mutual follower\(person.mutualFollowers == 1 ? "" : "s")")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                    } else if let distance = person.distance {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 12))
                            Text(formatDistance(distance))
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Bio preview
                    if let bio = person.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // Follow button (only show if showFollowButton is true)
                if showFollowButton {
                    Button(action: {
                        handleFollowAction()
                    }) {
                        Text(isFollowing ? "Following" : "Follow")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isFollowing ? .primary : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isFollowing ? Color(.systemGray5) : primaryColor)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isFollowing ? Color(.systemGray4) : Color.clear, lineWidth: 1)
                            )
                    }
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.6 : 1.0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .padding(.leading, 78)
        }
        .background(Color(.systemBackground))
    }
    
    private func handleFollowAction() {
        isLoading = true
        
        // Call the onFollow callback with the current state (before toggle)
        // This allows the parent to handle the actual API call
        onFollow(person.id)
        
        // Update local state immediately for better UX
        isFollowing.toggle()
        isLoading = false
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1 {
            return "Less than 1 mile away"
        } else if distance < 10 {
            return String(format: "%.1f miles away", distance)
        } else {
            return String(format: "%.0f miles away", distance)
        }
    }
}

struct PeopleSuggestionCategoryCard: View {
    let category: PeopleSuggestionCategory
    let onFollow: (String) -> Void
    let onTap: (String) -> Void
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        VStack(spacing: 0) {
            // Category header
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(primaryColor)
                    .font(.system(size: 16, weight: .medium))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(category.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("See All") {
                    // Navigate to full category view
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(primaryColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Users in this category
            LazyVStack(spacing: 0) {
                ForEach(category.users, id: \.id) { person in
                    PeopleSuggestionCard(
                        person: person,
                        onFollow: onFollow,
                        onTap: onTap
                    )
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack {
        PeopleSuggestionCard(
            person: EnhancedFeedPerson(
                id: "1",
                name: "John Doe",
                username: "johndoe",
                bio: "Travel enthusiast and food lover. Always exploring new places!",
                profileImage: nil,
                location: nil,
                distance: 2.5,
                mutualFollowers: 3,
                mutualFollowersList: ["user1", "user2", "user3"],
                followersCount: 150,
                followingCount: 120,
                isFollowing: false,
                isFollowedBy: false,
                isCreator: true,
                isVerified: true,
                suggestionScore: 85,
                createdAt: "2024-01-01",
                updatedAt: "2024-01-01",
                lastLogin: "2024-01-01"
            ),
            onFollow: { _ in },
            onTap: { _ in }
        )
        
        PeopleSuggestionCategoryCard(
            category: PeopleSuggestionCategory(
                category: "nearby",
                title: "People Near You",
                subtitle: "5 people nearby",
                icon: "location.fill",
                users: []
            ),
            onFollow: { _ in },
            onTap: { _ in }
        )
    }
} 