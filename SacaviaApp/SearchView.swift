import SwiftUI
import Foundation
// Import Utils for shared helpers
// import CategoryFilterTabs if needed

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var results: SearchResults?
    @State private var selectedLocation: LocationResult? = nil
    @State private var selectedUser: UserResult? = nil
    @State private var showUserSheet = false
    @State private var searchTask: Task<Void, Never>?
    @State private var blockedUsers: [String] = []

    @FocusState private var isSearchFocused: Bool
    @StateObject private var authManager = AuthManager.shared
    private let apiService = APIService()
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ModernSearchBar(query: $query, isFocused: $isSearchFocused, onSearch: search, primaryColor: primaryColor)
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                if isLoading {
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
                        Text("Searching...")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .transition(.opacity)
                } else if let error = error {
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
                        Button(action: search) {
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
                    .transition(.opacity)
                } else if let results = results {
                    let filteredUsers = results.users.filter { user in
                        user.id != authManager.user?.id && !blockedUsers.contains(user.id)
                    }
                    EnhancedSearchResultsList(
                        results: SearchResults(
                            guides: results.guides, 
                            locations: results.locations, 
                            users: filteredUsers,
                            aiInsights: results.aiInsights,
                            suggestedQueries: results.suggestedQueries
                        ),
                        onSelectLocation: { loc in
                            selectedLocation = loc
                        },
                        onSelectUser: { user in
                            selectedUser = user
                            showUserSheet = true
                        },
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor
                    )
                } else {
                    VStack(spacing: 24) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(primaryColor.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(primaryColor)
                        }
                        Text("Start typing to search for guides, locations, or users.")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                loadBlockedUsers()
            }
            .background(Color(.systemGray6))
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: 
                Button("Close") { 
                    dismiss()
                }
            )
            .fullScreenCover(isPresented: Binding(
                get: { showUserSheet && selectedUser != nil },
                set: { if !$0 { showUserSheet = false; selectedUser = nil } }
            )) {
                if let user = selectedUser {
                    ProfileView(userId: user.id)
                        .environmentObject(authManager)
                        .onAppear {
                            print("🔍 [SearchView] ProfileView appeared for user: \(user.id)")
                        }
                        .onDisappear {
                            print("🔍 [SearchView] ProfileView disappeared")
                        }
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { selectedLocation != nil },
                set: { if !$0 { selectedLocation = nil } }
            )) {
                if let location = selectedLocation {
                    EnhancedLocationDetailView(locationId: location.id)
                        .environmentObject(authManager)
                }
            }
            .onAppear {
                loadBlockedUsers()
            }
            .onChange(of: query) { _, _ in
                search()
            }
            .onDisappear {
                searchTask?.cancel()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LocationSaveStateChanged"))) { notification in
                // Refresh search results when a location save state changes to update saved status
                print("🔍 [SearchView] Received location save state change notification")
                if let results = results, !results.locations.isEmpty {
                    // Re-perform search to get updated save states
                    search()
                }
            }
        }
    }
    
    func search() {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Cancel previous search task
        searchTask?.cancel()
        
        // Create new debounced search task
        searchTask = Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                try Task.checkCancellation()
                
                await performSearch()
            } catch {
                // Task was cancelled or failed
                return
            }
        }
    }
    
    func loadBlockedUsers() {
        Task {
            do {
                let blocked = try await apiService.getBlockedUsers()
                await MainActor.run {
                    self.blockedUsers = blocked
                    print("🔍 [SearchView] Loaded \(blocked.count) blocked users")
                }
            } catch {
                print("🔍 [SearchView] Failed to load blocked users: \(error)")
            }
        }
    }
    
    // Block a user and update local state
    func blockUser(userId: String, reason: String? = nil) {
        Task {
            do {
                let success = try await apiService.blockUser(targetUserId: userId, reason: reason)
                if success {
                    await MainActor.run {
                        // Add to local blocked users list
                        if !self.blockedUsers.contains(userId) {
                            self.blockedUsers.append(userId)
                        }
                        // Remove from search results
                        if let currentResults = self.results {
                            let filteredUsers = currentResults.users.filter { $0.id != userId }
                            self.results = SearchResults(
                                guides: currentResults.guides,
                                locations: currentResults.locations,
                                users: filteredUsers,
                                aiInsights: currentResults.aiInsights,
                                suggestedQueries: currentResults.suggestedQueries
                            )
                        }
                        print("🔍 [SearchView] User \(userId) blocked and removed from search results")
                    }
                }
            } catch {
                print("🔍 [SearchView] Failed to block user \(userId): \(error)")
            }
        }
    }
    
    @MainActor
    func performSearch() async {
        isLoading = true
        error = nil
        
        let url = URL(string: "\(baseAPIURL)/api/mobile/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header
        if let token = authManager.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body: [String: Any] = ["query": query, "type": "all"]
        
        // Add coordinates if available
        if let userLocation = authManager.user?.location?.coordinates {
            body["coordinates"] = [
                "latitude": userLocation.latitude,
                "longitude": userLocation.longitude
            ]
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("🔍 Search request:", query)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 Search HTTP status:", httpResponse.statusCode)
                if httpResponse.statusCode != 200 {
                    self.error = "Search failed (HTTP \(httpResponse.statusCode))"
                    return
                }
            }
            
            // Print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 Search response:", responseString.prefix(500))
            }
            
            let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
            
            if !searchResponse.success {
                print("❌ Search API returned success: false")
                self.error = searchResponse.error ?? "Search failed"
                return
            }
            
            print("✅ Search decoded successfully:", searchResponse.data.guides.count, "guides,", searchResponse.data.locations.count, "locations,", searchResponse.data.users.count, "users")
            self.results = searchResponse.data
            
            // After getting search results, check interaction state for locations
            if !searchResponse.data.locations.isEmpty {
                self.checkLocationInteractionStates()
            }
            
        } catch {
            print("❌ Search error:", error)
            self.error = "Search failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func checkLocationInteractionStates() {
        Task {
            do {
                guard let results = results else { return }
                let locationIds = results.locations.map { $0.id }
                if locationIds.isEmpty { return }
                
                let apiService = APIService.shared
                let response = try await apiService.checkLocationInteractionState(locationIds: locationIds)
                
                if response.success, let data = response.data {
                    print("🔍 [SearchView] Received interaction states for \(data.interactions.count) locations")
                    
                    // Update search results with interaction states
                    DispatchQueue.main.async {
                        for interaction in data.interactions {
                            if self.results?.locations.firstIndex(where: { $0.id == interaction.locationId }) != nil {
                                // Note: LocationResult doesn't have isSaved/isSubscribed fields yet
                                // We would need to extend the model to include these fields
                                print("🔍 [SearchView] Location \(interaction.locationId) - isSaved: \(interaction.isSaved), isSubscribed: \(interaction.isSubscribed)")
                            }
                        }
                    }
                }
            } catch {
                print("🔍 [SearchView] Error checking location interaction states: \(error)")
            }
        }
    }
}

// MARK: - Enhanced Search Results List
struct EnhancedSearchResultsList: View {
    let results: SearchResults
    let onSelectLocation: (LocationResult) -> Void
    let onSelectUser: (UserResult) -> Void
    let primaryColor: Color
    let secondaryColor: Color
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !results.guides.isEmpty {
                    EnhancedSectionHeader(title: "Guides", color: primaryColor, icon: "book.fill")
                    ForEach(results.guides) { guide in
                        EnhancedGuideCard(guide: guide, primaryColor: primaryColor) {
                            // TODO: Implement guide detail navigation
                        }
                    }
                }
                
                if !results.locations.isEmpty {
                    EnhancedSectionHeader(title: "Locations", color: secondaryColor, icon: "mappin.and.ellipse")
                    ForEach(results.locations) { location in
                        EnhancedLocationCard(location: location, secondaryColor: secondaryColor) {
                            onSelectLocation(location)
                        }
                    }
                }
                
                if !results.users.isEmpty {
                    EnhancedSectionHeader(title: "People", color: .blue, icon: "person.3.fill")
                    VStack(spacing: 12) {
                        ForEach(results.users) { user in
                            // Enhanced people search results with Instagram/Facebook-like design
                            if let enhancedPerson = convertToEnhancedPerson(user) {
                                PeopleSuggestionCard(
                                    person: enhancedPerson,
                                    onFollow: { userId in
                                        handleFollowUser(userId)
                                    },
                                    onTap: { userId in
                                        onSelectUser(user)
                                    },
                                    showFollowButton: false // Hide follow button in search results
                                )
                            } else {
                                // Fallback to original design
                                EnhancedUserCard(
                                    user: user,
                                    primaryColor: primaryColor,
                                    secondaryColor: secondaryColor
                                ) {
                                    onSelectUser(user)
                                }
                            }
                        }
                    }
                }
                
                if results.guides.isEmpty && results.locations.isEmpty && results.users.isEmpty {
                    EmptySearchResultsView(primaryColor: primaryColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
}

// MARK: - Enhanced Section Header
struct EnhancedSectionHeader: View {
    let title: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Enhanced Guide Card
struct EnhancedGuideCard: View {
    let guide: GuideResult
    let primaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(primaryColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(primaryColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(guide.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("Travel Guide")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Location Card
struct EnhancedLocationCard: View {
    let location: LocationResult
    let secondaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(secondaryColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(secondaryColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("Location")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced User Card
struct EnhancedUserCard: View {
    let user: UserResult
    let primaryColor: Color
    let secondaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 45, height: 45)
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
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 45, height: 45)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text("@\(user.username ?? "user")")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                
                // View profile button
                HStack {
                    Text("View Profile")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - AI Search Insights View
struct AISearchInsightsView: View {
    let insights: AISearchInsights
    let primaryColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(primaryColor)
                
                Text("AI Assistant")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Summary
            Text(insights.summary)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            // Recommendations
            if !insights.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Tips:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    ForEach(insights.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(primaryColor)
                            
                            Text(recommendation)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(primaryColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(primaryColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Suggested Queries View
struct SuggestedQueriesView: View {
    let queries: [String]
    let primaryColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryColor)
                
                Text("Try these searches:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(queries, id: \.self) { query in
                    Button(action: {
                        // TODO: Implement query selection
                        print("Selected query: \(query)")
                    }) {
                        Text(query)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(primaryColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(primaryColor.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(primaryColor.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Empty Search Results View
struct EmptySearchResultsView: View {
    let primaryColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No results found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Try searching for something else or check your spelling.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 40)
    }
}

// MARK: - Modern Search Bar
struct ModernSearchBar: View {
    @Binding var query: String
    @FocusState.Binding var isFocused: Bool
    let onSearch: () -> Void
    let primaryColor: Color
    
    var body: some View {
        HStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(primaryColor)
                TextField("Search guides, locations, people...", text: $query, onCommit: onSearch)
                    .focused($isFocused)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                if !query.isEmpty {
                    Button(action: { query = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(isFocused ? 0.12 : 0.05), radius: isFocused ? 8 : 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? primaryColor : Color.clear, lineWidth: 2)
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Legacy Components (for backward compatibility)
struct ModernSearchResultsList: View {
    let results: SearchResults
    let onSelectLocation: (LocationResult) -> Void
    let onSelectUser: (UserResult) -> Void
    let primaryColor: Color
    let secondaryColor: Color
    
    var body: some View {
        EnhancedSearchResultsList(
            results: results,
            onSelectLocation: onSelectLocation,
            onSelectUser: onSelectUser,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor
        )
    }
}

struct SectionHeader: View {
    let title: String
    let color: Color
    let icon: String
    
    var body: some View {
        EnhancedSectionHeader(title: title, color: color, icon: icon)
    }
}

struct CardButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    
    var body: some View {
        Button(action: action) {
            label()
                .padding(14)
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchResultsList: View {
    let results: SearchResults
    let onSelectLocation: (LocationResult) -> Void
    let onSelectUser: (UserResult) -> Void
    
    var body: some View {
        EnhancedSearchResultsList(
            results: results,
            onSelectLocation: onSelectLocation,
            onSelectUser: onSelectUser,
            primaryColor: Color(red: 255/255, green: 107/255, blue: 107/255),
            secondaryColor: Color(red: 78/255, green: 205/255, blue: 196/255)
        )
    }
}

// MARK: - Data Models
struct SearchResults: Decodable {
    let guides: [GuideResult]
    let locations: [LocationResult]
    let users: [UserResult]
    let aiInsights: AISearchInsights?
    let suggestedQueries: [String]?
}

struct AISearchInsights: Decodable {
    let summary: String
    let recommendations: [String]
    let context: String
    let totalResults: Int
}

struct GuideResult: Decodable, Identifiable { 
    let id: String
    let title: String
    let description: String?
    let featuredImage: String?
    let createdAt: String?
}

struct LocationResult: Decodable, Identifiable { 
    let id: String
    let name: String
    let address: String?
    let featuredImage: String?
    let createdAt: String?
}

struct UserResult: Decodable, Identifiable {
    let id: String
    let name: String
    let username: String?
    let email: String?
    let profileImage: String?
    let bio: String?
    let location: LocationCoordinates?
    let distance: Double?
    let mutualFollowers: Int?
    let mutualFollowersList: [String]?
    let followersCount: Int?
    let followingCount: Int?
    let isFollowing: Bool?
    let isFollowedBy: Bool?
    let relevanceScore: Int?
    let createdAt: String?
}

// Wrapper for backend response
struct SearchResponse: Decodable {
    let success: Bool
    let data: SearchResults
    let error: String?
}

// LocationDetailResponse and LocationDetailData are defined in LocationDetailView.swift

// SearchLocation and LocationCoordinates are defined in SharedTypes.swift

// MARK: - Enhanced People Suggestions Helpers for SearchView
extension EnhancedSearchResultsList {
    func convertToEnhancedPerson(_ user: UserResult) -> EnhancedFeedPerson? {
        // Map UserResult to EnhancedFeedPerson (fill with available fields)
        // Convert LocationCoordinates to FeedCoordinates if needed
        let feedLocation: FeedCoordinates? = user.location.map { location in
            FeedCoordinates(latitude: location.latitude, longitude: location.longitude)
        }
        
        return EnhancedFeedPerson(
            id: user.id,
            name: user.name,
            username: user.username,
            bio: user.bio ?? "",
            profileImage: user.profileImage,
            location: feedLocation,
            distance: user.distance,
            mutualFollowers: user.mutualFollowers ?? 0,
            mutualFollowersList: user.mutualFollowersList,
            followersCount: user.followersCount ?? 0,
            followingCount: user.followingCount ?? 0,
            isFollowing: user.isFollowing ?? false,
            isFollowedBy: user.isFollowedBy ?? false,
            isCreator: false, // Not provided in search results
            isVerified: false, // Not provided in search results
            suggestionScore: Double(user.relevanceScore ?? 0),
            createdAt: user.createdAt,
            updatedAt: nil,
            lastLogin: nil
        )
    }
    
    func handleFollowUser(_ userId: String) {
        // Implement follow/unfollow logic if needed
        print("Follow user: \(userId)")
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
} 