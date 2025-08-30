import SwiftUI

struct SimplePeopleSuggestionsView: View {
    @StateObject private var peopleSuggestionsManager = PeopleSuggestionsManager()
    @EnvironmentObject var authManager: AuthManager
    @State private var showProfile: Bool = false
    @State private var selectedUserId: String = ""
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        VStack(spacing: 0) {
            if peopleSuggestionsManager.isLoading {
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
            } else if let error = peopleSuggestionsManager.errorMessage {
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
                    Text(error)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: { peopleSuggestionsManager.refreshSuggestions() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Try Again")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                    }
                    Spacer()
                }
            } else if peopleSuggestionsManager.suggestions.isEmpty {
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
                    Text("We couldn't find any new people to suggest right now. This might be because you're already following everyone nearby, or try adjusting your location settings.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Refresh button at the top
                        HStack {
                            Spacer()
                            Button(action: { peopleSuggestionsManager.refreshSuggestions() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Refresh")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(primaryColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(primaryColor.opacity(0.1))
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        ForEach(peopleSuggestionsManager.suggestions) { category in
                            // Show all categories: nearby, mutual, and suggested
                            if category.category == "nearby" || category.category == "mutual" || category.category == "suggested" {
                                VStack(alignment: .leading, spacing: 12) {
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
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                    
                                    // Users in this category
                                    LazyVStack(spacing: 0) {
                                        ForEach(category.users, id: \.id) { person in
                                            PeopleSuggestionCard(
                                                person: person,
                                                onFollow: { userId in
                                                    // Handle follow/unfollow action based on current state
                                                    if person.isFollowing {
                                                        peopleSuggestionsManager.unfollowUser(userId)
                                                    } else {
                                                        peopleSuggestionsManager.followUser(userId)
                                                    }
                                                },
                                                onTap: { userId in
                                                    selectedUserId = userId
                                                    showProfile = true
                                                }
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
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 100) // Add padding for tab bar
                }
            }
        }
        .background(Color(.systemGray6))
        .onAppear {
            // Fetch all categories for the People tab
            peopleSuggestionsManager.fetchPeopleSuggestions(category: "all")
        }
        .navigationDestination(isPresented: $showProfile) {
            ProfileView(userId: selectedUserId)
                .environmentObject(authManager)
        }
    }
} 