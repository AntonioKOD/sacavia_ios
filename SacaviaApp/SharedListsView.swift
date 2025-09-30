import SwiftUI

// MARK: - Shared Lists View
struct SharedListsView: View {
    @StateObject private var apiService = APIService()
    @State private var sharedLists: [SharedList] = []
    @State private var isLoading = false
    @State private var showCreateList = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading shared lists...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sharedLists.isEmpty {
                    EmptySharedListsView {
                        showCreateList = true
                    }
                } else {
                    List {
                        ForEach(sharedLists) { list in
                            SharedListRowView(list: list)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Shared Lists")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateList = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateList) {
                CreateSharedListView { newList in
                    sharedLists.append(newList)
                }
            }
            .onAppear {
                loadSharedLists()
            }
        }
    }
    
    private func loadSharedLists() {
        isLoading = true
        // TODO: Implement API call to fetch shared lists
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.sharedLists = mockSharedLists
            self.isLoading = false
        }
    }
}

// MARK: - Shared List Row View
struct SharedListRowView: View {
    let list: SharedList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(list.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(list.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(list.locations.count) places")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(list.updatedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Collaborators
            HStack {
                Text("Collaborators:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: -8) {
                    ForEach(Array(list.collaborators.prefix(3))) { collaborator in
                        CollaboratorAvatarView(collaborator: collaborator)
                    }
                    
                    if list.collaborators.count > 3 {
                        CollaboratorCountView(count: list.collaborators.count - 3)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Create Shared List View
struct CreateSharedListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var listName = ""
    @State private var listDescription = ""
    @State private var selectedFriends: Set<String> = []
    @State private var friends: [User] = []
    @State private var isLoading = false
    
    let onListCreated: (SharedList) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("List Name")
                        .font(.headline)
                    
                    TextField("Enter list name", text: $listName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Description")
                        .font(.headline)
                    
                    TextField("Enter description", text: $listDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Collaborators")
                        .font(.headline)
                    
                    if friends.isEmpty {
                        Text("Loading friends...")
                            .foregroundColor(.secondary)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(friends) { friend in
                                UserSelectionRow(
                                    user: friend,
                                    isSelected: selectedFriends.contains(friend.id),
                                    onToggle: {
                                        if selectedFriends.contains(friend.id) {
                                            selectedFriends.remove(friend.id)
                                        } else {
                                            selectedFriends.insert(friend.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Create Shared List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createList()
                    }
                    .disabled(listName.isEmpty || isLoading)
                }
            }
            .onAppear {
                loadFriends()
            }
        }
    }
    
    private func loadFriends() {
        // TODO: Implement API call to fetch friends
        friends = mockFriends
    }
    
    private func createList() {
        isLoading = true
        
        let newList = SharedList(
            id: UUID().uuidString,
            name: listName,
            description: listDescription,
            locations: [],
            collaborators: friends.filter { selectedFriends.contains($0.id) },
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // TODO: Implement API call to create shared list
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.onListCreated(newList)
            self.dismiss()
        }
    }
}

// MARK: - Empty Shared Lists View
struct EmptySharedListsView: View {
    let onCreateList: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No shared lists yet")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Create collaborative lists with friends to share your favorite places")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onCreateList) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Your First List")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Data Models
struct SharedList: Identifiable {
    let id: String
    let name: String
    let description: String
    let locations: [SearchLocation]
    let collaborators: [User]
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Mock Data
private let mockSharedLists: [SharedList] = [
    SharedList(
        id: "1",
        name: "Best Coffee Shops",
        description: "Our favorite coffee spots in the city",
        locations: [],
        collaborators: mockFriends.prefix(3).map { $0 },
        createdAt: Date(),
        updatedAt: Date()
    ),
    SharedList(
        id: "2",
        name: "Date Night Spots",
        description: "Perfect places for romantic dinners",
        locations: [],
        collaborators: mockFriends.prefix(2).map { $0 },
        createdAt: Date(),
        updatedAt: Date()
    )
]

private let mockFriends: [User] = [
    User(id: "1", name: "John Doe", email: "john@example.com", profileImage: nil, location: nil, role: "user", preferences: UserPreferences()),
    User(id: "2", name: "Jane Smith", email: "jane@example.com", profileImage: nil, location: nil, role: "user", preferences: UserPreferences()),
    User(id: "3", name: "Mike Johnson", email: "mike@example.com", profileImage: nil, location: nil, role: "user", preferences: UserPreferences())
]

// MARK: - User Selection Row
struct UserSelectionRow: View {
    let user: User
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: user.profileImage?.url ?? "")) { image in
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
                Text(user.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(user.email)
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

// MARK: - Collaborator Avatar View
struct CollaboratorAvatarView: View {
    let collaborator: User
    
    var body: some View {
        AsyncImage(url: URL(string: collaborator.profileImage?.url ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Text(String(collaborator.name.prefix(1)).uppercased())
                        .font(.caption)
                        .foregroundColor(.white)
                )
        }
        .frame(width: 24, height: 24)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
    }
}

// MARK: - Collaborator Count View
struct CollaboratorCountView: View {
    let count: Int
    
    var body: some View {
        Text("+\(count)")
            .font(.caption2)
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
            .background(Color.gray)
            .clipShape(Circle())
    }
}
