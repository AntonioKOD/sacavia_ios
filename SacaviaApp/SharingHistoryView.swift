import SwiftUI

// MARK: - Sharing History View
struct SharingHistoryView: View {
    @StateObject private var apiService = APIService()
    @State private var sharingHistory: [ShareHistoryItem] = []
    @State private var isLoading = false
    @State private var selectedFilter: ShareFilter = .all
    @State private var searchText = ""
    
    enum ShareFilter: String, CaseIterable {
        case all = "All"
        case sent = "Sent"
        case received = "Received"
        case recent = "Recent"
    }
    
    var filteredHistory: [ShareHistoryItem] {
        var filtered = sharingHistory
        
        // Filter by type
        switch selectedFilter {
        case .all:
            break
        case .sent:
            filtered = filtered.filter { $0.type == .sent }
        case .received:
            filtered = filtered.filter { $0.type == .received }
        case .recent:
            filtered = filtered.filter { Calendar.current.isDateInToday($0.createdAt) }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.locationName.lowercased().contains(searchText.lowercased()) ||
                item.message.lowercased().contains(searchText.lowercased()) ||
                item.recipientName.lowercased().contains(searchText.lowercased())
            }
        }
        
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search sharing history...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(ShareFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                            }) {
                                Text(filter.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedFilter == filter ? .blue : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedFilter == filter ? Color.blue.opacity(0.1) : Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                
                Divider()
                
                // History list
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading sharing history...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredHistory.isEmpty {
                    EmptySharingHistoryView(filter: selectedFilter)
                } else {
                    List {
                        ForEach(filteredHistory) { item in
                            ShareHistoryRowView(item: item) {
                                handleItemAction(item)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Sharing History")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadSharingHistory()
            }
        }
    }
    
    private func loadSharingHistory() {
        isLoading = true
        // TODO: Implement API call to fetch sharing history
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.sharingHistory = mockSharingHistory
            self.isLoading = false
        }
    }
    
    private func handleItemAction(_ item: ShareHistoryItem) {
        // TODO: Handle item actions (view location, resend, etc.)
        print("Action for item: \(item.id)")
    }
}

// MARK: - Share History Row View
struct ShareHistoryRowView: View {
    let item: ShareHistoryItem
    let onAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Type indicator
            VStack {
                Image(systemName: item.type == .sent ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundColor(item.type == .sent ? .blue : .green)
                    .font(.title2)
                
                Text(item.type == .sent ? "Sent" : "Received")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.locationName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formatDate(item.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !item.message.isEmpty {
                    Text(item.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    if item.type == .sent {
                        Text("To: \(item.recipientName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("From: \(item.senderName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(item.messageType.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            // Action button
            Button(action: onAction) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .font(.title3)
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

// MARK: - Empty Sharing History View
struct EmptySharingHistoryView: View {
    let filter: SharingHistoryView.ShareFilter
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(emptyTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyTitle: String {
        switch filter {
        case .all:
            return "No sharing history"
        case .sent:
            return "No sent shares"
        case .received:
            return "No received shares"
        case .recent:
            return "No recent activity"
        }
    }
    
    private var emptyMessage: String {
        switch filter {
        case .all:
            return "When you share locations with friends or receive shares, they'll appear here."
        case .sent:
            return "Start sharing locations with your friends to see them here."
        case .received:
            return "When friends share locations with you, they'll appear here."
        case .recent:
            return "No sharing activity today. Check back later!"
        }
    }
}

// MARK: - Data Models
struct ShareHistoryItem: Identifiable {
    let id: String
    let type: ShareType
    let locationName: String
    let locationId: String
    let message: String
    let messageType: String
    let senderName: String
    let recipientName: String
    let createdAt: Date
    let isRead: Bool
    
    enum ShareType {
        case sent
        case received
    }
}

// MARK: - Mock Data
private let mockSharingHistory: [ShareHistoryItem] = [
    ShareHistoryItem(
        id: "1",
        type: .sent,
        locationName: "Blue Bottle Coffee",
        locationId: "loc1",
        message: "Check out this amazing coffee place!",
        messageType: "recommendation",
        senderName: "You",
        recipientName: "John Doe",
        createdAt: Date().addingTimeInterval(-3600),
        isRead: true
    ),
    ShareHistoryItem(
        id: "2",
        type: .received,
        locationName: "Central Park",
        locationId: "loc2",
        message: "Let's meet here for a walk!",
        messageType: "meet_here",
        senderName: "Jane Smith",
        recipientName: "You",
        createdAt: Date().addingTimeInterval(-7200),
        isRead: false
    ),
    ShareHistoryItem(
        id: "3",
        type: .sent,
        locationName: "The French Laundry",
        locationId: "loc3",
        message: "Perfect for our anniversary dinner",
        messageType: "remember",
        senderName: "You",
        recipientName: "Mike Johnson",
        createdAt: Date().addingTimeInterval(-86400),
        isRead: true
    )
]

#Preview {
    SharingHistoryView()
}

