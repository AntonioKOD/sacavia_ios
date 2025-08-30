import SwiftUI
import Foundation
// Import shared helpers
// import CategoryFilterTabs (if needed)

struct EnhancedPeopleSuggestionsView: View {
    @StateObject private var suggestionsManager = PeopleSuggestionsManager()
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedCategory: String = "all"
    @State private var showProfile: Bool = false
    @State private var selectedUserId: String = ""
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category filter tabs
                CategoryFilterTabs(selectedCategory: $selectedCategory, categories: ["all", "nearby", "mutual", "suggested"])
                
                if suggestionsManager.isLoading {
                    PeopleLoadingView(primaryColor: primaryColor)
                } else if let error = suggestionsManager.errorMessage {
                    PeopleErrorView(error: error, primaryColor: primaryColor) {
                        suggestionsManager.refreshSuggestions()
                    }
                } else if suggestionsManager.suggestions.isEmpty {
                    EmptyStateView(primaryColor: primaryColor)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            if selectedCategory == "all" {
                                // For "all" category, use random placement
                                ForEach(suggestionsManager.suggestions) { category in
                                    PeopleSuggestionCategoryView(
                                        category: category,
                                        primaryColor: primaryColor,
                                        secondaryColor: secondaryColor,
                                        onFollowUser: { userId in
                                            suggestionsManager.followUser(userId)
                                        },
                                        onUnfollowUser: { userId in
                                            suggestionsManager.unfollowUser(userId)
                                        },
                                        onViewProfile: { userId in
                                            selectedUserId = userId
                                            showProfile = true
                                        }
                                    )
                                    
                                    // Add random spacing based on position
                                    if let position = category.position {
                                        switch position {
                                        case "middle":
                                            Spacer(minLength: 40)
                                        case "bottom":
                                            Spacer(minLength: 80)
                                        default:
                                            Spacer(minLength: 20)
                                        }
                                    }
                                }
                            } else {
                                // For specific categories, show normally
                                ForEach(suggestionsManager.suggestions) { category in
                                    PeopleSuggestionCategoryView(
                                        category: category,
                                        primaryColor: primaryColor,
                                        secondaryColor: secondaryColor,
                                        onFollowUser: { userId in
                                            suggestionsManager.followUser(userId)
                                        },
                                        onUnfollowUser: { userId in
                                            suggestionsManager.unfollowUser(userId)
                                        },
                                        onViewProfile: { userId in
                                            selectedUserId = userId
                                            showProfile = true
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            suggestionsManager.testAPIEndpoint()
                        }) {
                            Image(systemName: "network")
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: {
                            suggestionsManager.refreshSuggestions()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(primaryColor)
                        }
                        .help("Refresh suggestions with new randomization")
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(userId: selectedUserId)
                    .environmentObject(authManager)
            }
            .onAppear {
                if suggestionsManager.suggestions.isEmpty {
                    suggestionsManager.fetchPeopleSuggestions()
                }
            }
        }
    }
}

// MARK: - People Suggestion Category View
struct PeopleSuggestionCategoryView: View {
    let category: PeopleSuggestionCategory
    let primaryColor: Color
    let secondaryColor: Color
    let onFollowUser: (String) -> Void
    let onUnfollowUser: (String) -> Void
    let onViewProfile: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category header
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(primaryColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(category.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Users grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(category.users) { user in
                    EnhancedPersonCard(
                        user: user,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        onFollowUser: onFollowUser,
                        onUnfollowUser: onUnfollowUser,
                        onViewProfile: onViewProfile
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Enhanced Person Card
struct EnhancedPersonCard: View {
    let user: EnhancedFeedPerson
    let primaryColor: Color
    let secondaryColor: Color
    let onFollowUser: (String) -> Void
    let onUnfollowUser: (String) -> Void
    let onViewProfile: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Profile image and basic info
            HStack(spacing: 12) {
                // Profile image
                if let profileImageUrl = user.profileImage, let imageUrl = absoluteMediaURL(profileImageUrl) {
                    AsyncImage(url: imageUrl) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [primaryColor.opacity(0.8), secondaryColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text(getInitials(user.name))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                } else {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [primaryColor.opacity(0.8), secondaryColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text(getInitials(user.name))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(user.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if user.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(primaryColor)
                        }
                        
                        if user.isCreator == true {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(secondaryColor)
                        }
                    }
                    
                    if let username = user.username {
                        Text("@\(username)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            
            // Mutual followers or distance info
            if user.mutualFollowers > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    Text("\(user.mutualFollowers) mutual")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            } else if let distance = user.distance {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    Text(String(format: "%.1f mi", distance))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            // Bio
            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: {
                    onViewProfile(user.id)
                }) {
                    Text("View")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                        )
                }
                
                Spacer()
                
                Button(action: {
                    if user.isFollowing {
                        onUnfollowUser(user.id)
                    } else {
                        onFollowUser(user.id)
                    }
                }) {
                    Text(user.isFollowing ? "Following" : "Follow")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(user.isFollowing ? .gray : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    user.isFollowing 
                                        ? Color.gray.opacity(0.1)
                                        : primaryColor
                                )
                        )
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

// MARK: - People Loading View
struct PeopleLoadingView: View {
    let primaryColor: Color
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(primaryColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(primaryColor)
            }
            Text("Finding people for you...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

// MARK: - People Error View
struct PeopleErrorView: View {
    let error: String
    let primaryColor: Color
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
            }
            Text("Oops! Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text(error)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(action: retryAction) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(primaryColor)
                    .cornerRadius(25)
            }
            Spacer()
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let primaryColor: Color
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(primaryColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.3")
                    .font(.system(size: 32))
                    .foregroundColor(primaryColor)
            }
            Text("No people found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text("We couldn't find any new people to suggest right now. This might be because you're already following everyone nearby, or try adjusting your location settings.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
} 