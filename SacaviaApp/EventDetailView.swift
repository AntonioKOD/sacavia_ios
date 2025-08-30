import SwiftUI

struct EventDetailView: View {
    let event: Event
    @StateObject private var eventsManager = EventsManager()
    @State private var showingInviteSheet = false
    @State private var showingParticipantsSheet = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showMoreOptions = false
    @State private var showReportContent = false
    @State private var selectedImageIndex = 0
    @Environment(\.presentationMode) var presentationMode
    
    init(event: Event) {
        self.event = event
    }
    
    // Brand colors matching the app design - Vivid Coral and Bright Teal
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B - Vivid Coral
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4 - Bright Teal
    private let accentColor = Color(red: 255/255, green: 230/255, blue: 109/255) // #FFE66D - Warm Yellow
    private let backgroundColor = Color(red: 243/255, green: 244/255, blue: 246/255) // #F3F4F6 - Whisper Gray
    private let cardBackground = Color.white
    
    var body: some View {
        ZStack {
            // Background gradient matching app design
            LinearGradient(
                gradient: Gradient(colors: [backgroundColor.opacity(0.3), Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
        ScrollView {
                VStack(spacing: 20) {
                    // Event Image Carousel
                    eventImageCarousel
                    
                    // Event Header Section
                    eventHeaderSection
                    
                    // Quick Info Section
                    quickInfoSection
                    
                    // Description Section
                    descriptionSection
                    
                    // Participants Section
                    participantsSection
                    
                    // Action Buttons Section
                    actionButtonsSection
                    
                    // Additional Details Section
                    additionalDetailsSection
                }
                .padding()
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Button(action: {
                showMoreOptions = true
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(primaryColor)
            }
        )

        .fullScreenCover(isPresented: $showingInviteSheet) {
            InviteView(event: event)
        }

        .fullScreenCover(isPresented: $showingParticipantsSheet) {
            ParticipantsView(event: event)
        }

        .confirmationDialog("More Options", isPresented: $showMoreOptions) {
            Button("Report Event") {
                showReportContent = true
            }
            Button("Share Event") {
                shareEvent()
            }
        }
        .fullScreenCover(isPresented: $showReportContent) {
            ReportContentView(
                contentType: "event",
                contentId: event.id,
                contentTitle: event.name
            )
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - View Components
    
    private var eventImageCarousel: some View {
        let allImages = getAllEventImages()
        
        return Group {
            if allImages.isEmpty {
                // Placeholder for no images
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 250)
                    .overlay(
                        VStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Event Image")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
                    .cornerRadius(12)
            } else if allImages.count == 1 {
                // Single image display
                AsyncImage(url: URL(string: allImages[0])) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                            ProgressView()
                            )
                    }
                    .frame(height: 250)
                    .clipped()
                .cornerRadius(12)
            } else {
                // Carousel for multiple images
                ZStack(alignment: .bottom) {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(allImages.indices, id: \.self) { index in
                            AsyncImage(url: URL(string: allImages[index])) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(ProgressView())
                            }
                            .frame(height: 250)
                            .clipped()
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 250)
                    .cornerRadius(12)
                    
                    // Custom page indicator
                    if allImages.count > 1 {
                        VStack {
                            Spacer()
                        HStack {
                            Spacer()
                                Text("\(selectedImageIndex + 1) / \(allImages.count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Capsule())
                                    .padding(.trailing, 16)
                                    .padding(.bottom, 16)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var eventHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Event name
            Text(event.name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
                .foregroundColor(.primary)
            
            // Category and type tags
                        HStack {
                if !event.category.isEmpty {
                            Text(event.category.capitalized)
                                .font(.caption)
                        .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        .background(primaryColor.opacity(0.15))
                        .foregroundColor(primaryColor)
                        .clipShape(Capsule())
                }
                
                if !event.eventType.isEmpty {
                            Text(event.eventType.capitalized)
                                .font(.caption)
                        .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        .background(secondaryColor.opacity(0.15))
                        .foregroundColor(secondaryColor)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                // Status badge
                Text(event.status.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(getStatusColor(event.status))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var quickInfoSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                InfoCard(
                    icon: "calendar",
                    title: "Date & Time",
                    value: formatEventDate(),
                    color: primaryColor
                )
                
                InfoCard(
                    icon: "location",
                    title: "Location",
                    value: event.location?.name.isEmpty == false ? event.location!.name : "TBD",
                    color: secondaryColor
                )
            }
            
            HStack(spacing: 12) {
                InfoCard(
                    icon: "person.circle",
                    title: "Organizer",
                    value: event.organizer?.name ?? "Unknown",
                    color: primaryColor
                )
                
                InfoCard(
                    icon: "person.3",
                    title: "Capacity",
                    value: (event.capacity ?? 0) > 0 ? "\(event.goingCount)/\(event.capacity!)" : "Unlimited",
                    color: secondaryColor
                )
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
                        Text("About this event")
                            .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                        
                        Text(event.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Participants")
                                .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("View All") {
                                showingParticipantsSheet = true
                            }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(primaryColor)
                        }
                        
                        // View Participants Button
                        Button(action: {
                            showingParticipantsSheet = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(primaryColor)
                                
                                Text("View Participants")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(primaryColor)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(primaryColor)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(primaryColor, lineWidth: 2)
                            )
                        }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // RSVP Button
                        Button(action: {
                            Task {
                                await toggleEventParticipation()
                            }
                        }) {
                HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: getParticipationButtonIcon())
                            .font(.system(size: 18, weight: .medium))
                                }
                                
                                Text(getParticipationButtonText())
                        .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [primaryColor, secondaryColor]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                            .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading)
                        
                        // Invite Button
                        Button(action: {
                            showingInviteSheet = true
                        }) {
                HStack(spacing: 12) {
                                Image(systemName: "person.badge.plus")
                        .font(.system(size: 18, weight: .medium))
                                Text("Invite People")
                        .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(Color.white)
                .foregroundColor(primaryColor)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(primaryColor, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var additionalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
                    // Tags
                    if !event.tags.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(event.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                        .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(accentColor.opacity(0.15))
                                .foregroundColor(accentColor)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            // Event Details
            VStack(alignment: .leading, spacing: 12) {
                Text("Event Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                DetailRow(icon: "clock", title: "Duration", value: formatEventDuration())
                DetailRow(icon: "dollarsign.circle", title: "Price", value: event.isFree ? "Free" : "Paid")
                DetailRow(icon: "calendar.badge.plus", title: "Created", value: formatDate(event.createdAt))
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Functions
    
    private func getAllEventImages() -> [String] {
        var images: [String] = []
        
        // Add main image if available
        if let mainImage = event.image?.url, !mainImage.isEmpty {
            images.append(mainImage)
        }
        
        // Add gallery images
        for galleryItem in event.gallery {
            if let imageUrl = galleryItem.url, !imageUrl.isEmpty {
                images.append(imageUrl)
            }
        }
        
        // Debug logging
        print("EventDetailView: Main image URL: \(event.image?.url ?? "nil")")
        print("EventDetailView: Gallery count: \(event.gallery.count)")
        print("EventDetailView: Total images found: \(images.count)")
        
        return images
    }
    
    private func formatEventDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let start = ISO8601DateFormatter().date(from: event.startDate) ?? Date()
        return formatter.string(from: start)
    }
        
    private func formatEventDuration() -> String {
        let start = ISO8601DateFormatter().date(from: event.startDate) ?? Date()
        let end = ISO8601DateFormatter().date(from: event.endDate) ?? Date()
        
        let duration = end.timeIntervalSince(start)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let date = ISO8601DateFormatter().date(from: dateString) ?? Date()
        return formatter.string(from: date)
    }
    
    private func getStatusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "published", "active":
            return .green
        case "draft":
            return .orange
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    private func getParticipationButtonIcon() -> String {
        switch event.userRsvpStatus {
        case "going":
            return "checkmark.circle.fill"
        default:
            return "plus.circle"
        }
    }
    
    private func getParticipationButtonText() -> String {
        switch event.userRsvpStatus {
        case "going":
            return "Going"
        default:
            return "Join Event"
        }
    }
    
    private func toggleEventParticipation() async {
        print("🔍 [EventDetailView] Starting RSVP toggle...")
        print("🔍 [EventDetailView] Current status: \(event.userRsvpStatus ?? "nil")")
        print("🔍 [EventDetailView] Event ID: \(event.id)")
        
        isLoading = true
        defer { isLoading = false }
        
        let newStatus: String
        switch event.userRsvpStatus {
        case "going":
            newStatus = "not_going"
        default:
            newStatus = "going"
        }
        
        print("🔍 [EventDetailView] New status: \(newStatus)")
        
        let success = await eventsManager.updateEventParticipation(
            eventId: event.id,
            status: newStatus
        )
        
        print("🔍 [EventDetailView] RSVP API call result: \(success)")
        
        if success {
            print("🔍 [EventDetailView] RSVP updated successfully to: \(newStatus)")
        } else {
            errorMessage = "Failed to update participation. Please try again."
            print("🔍 [EventDetailView] RSVP update failed")
        }
    }
    

    
    private func shareEvent() {
        guard let url = URL(string: "https://sacavia.com/events/\(event.id)") else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [
                event.name,
                event.description,
                url
            ],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
            Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
                
                Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}



struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Placeholder Views

struct InviteView: View {
    let event: Event
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var eventsManager = EventsManager()
    
    // Invite people states
    @State private var invitedUsers: [InvitedUser] = []
    @State private var searchText = ""
    @State private var isLoadingUsers = false
    @State private var availableUsers: [InvitedUser] = []
    @State private var isInviting = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    // Brand colors matching the app design
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B - Vivid Coral
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4 - Bright Teal
    private let backgroundColor = Color(red: 243/255, green: 244/255, blue: 246/255) // #F3F4F6 - Whisper Gray
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [backgroundColor.opacity(0.3), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Cancel")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("Invite People")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Invisible spacer to balance the layout
                            HStack(spacing: 8) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Cancel")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.clear)
                        }
                        
                        Text("Invite friends to \(event.name)")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Search Bar
                            VStack(alignment: .leading, spacing: 12) {
                        HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.secondary)
                                    TextField("Search people...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Selected Users
                            if !invitedUsers.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Selected (\(invitedUsers.count))")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Button("Clear All") {
                                            invitedUsers.removeAll()
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(primaryColor)
                                    }
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                        ForEach(invitedUsers) { user in
                                            HStack(spacing: 8) {
                                                if let avatar = user.avatar {
                                                    AsyncImage(url: URL(string: avatar)) { image in
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                    } placeholder: {
                                                        Image(systemName: "person.circle.fill")
                                                            .foregroundColor(.secondary)
                                                    }
                                                    .frame(width: 32, height: 32)
                                                    .clipShape(Circle())
                                                } else {
                                                    Image(systemName: "person.circle.fill")
                                                        .font(.system(size: 32))
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(user.name)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.primary)
                                                    if let email = user.email {
                                                        Text(email)
                                                            .font(.system(size: 12))
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                
                            Spacer()
                                                
                                                Button(action: {
                                                    invitedUsers.removeAll { $0.id == user.id }
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.red)
                                                }
                        }
                        .padding()
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Available Users
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Available People")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if isLoadingUsers {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                }
                                
                                if availableUsers.isEmpty && !isLoadingUsers {
                                    VStack(spacing: 16) {
                                        Image(systemName: "person.2")
                                            .font(.system(size: 40))
                                            .foregroundColor(.secondary)
                                        Text("No people found")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.secondary)
                                        Button("Load People") {
                                            loadAvailableUsers()
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(primaryColor)
                                        .cornerRadius(12)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                    } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(filteredAvailableUsers) { user in
                                            HStack(spacing: 12) {
                                                if let avatar = user.avatar {
                                                    AsyncImage(url: URL(string: avatar)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                                                        Image(systemName: "person.circle.fill")
                                                            .foregroundColor(.secondary)
                                                    }
                    .frame(width: 40, height: 40)
                                                    .clipShape(Circle())
                                    } else {
                                                    Image(systemName: "person.circle.fill")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(.primary)
                                                    if let email = user.email {
                                                        Text(email)
                                                            .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                                                    if !invitedUsers.contains(where: { $0.id == user.id }) {
                                                        invitedUsers.append(user)
                                                    }
                                                }) {
                                                    Image(systemName: "plus.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(primaryColor)
                                                }
                                                .disabled(invitedUsers.contains(where: { $0.id == user.id }))
                                            }
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Send Invites Button
                            if !invitedUsers.isEmpty {
                                VStack(spacing: 16) {
                                    Button(action: {
                        Task {
                            await sendInvites()
                        }
                                    }) {
                                        HStack(spacing: 12) {
                                            if isInviting {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                    .foregroundColor(.white)
                } else {
                                                Image(systemName: "paperplane.fill")
                                                    .font(.system(size: 18, weight: .medium))
                                            }
                                            
                                            Text(isInviting ? "Sending Invites..." : "Send Invites (\(invitedUsers.count))")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 24)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                        .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                                    }
                                    .disabled(isInviting)
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                }
            }
            .onAppear {
                if availableUsers.isEmpty {
                    loadAvailableUsers()
                }
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Invites sent successfully!")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var filteredAvailableUsers: [InvitedUser] {
        if searchText.isEmpty {
            return availableUsers.filter { user in
                !invitedUsers.contains(where: { $0.id == user.id })
            }
        } else {
            return availableUsers.filter { user in
                !invitedUsers.contains(where: { $0.id == user.id }) &&
                (user.name.localizedCaseInsensitiveContains(searchText) ||
                 (user.email?.localizedCaseInsensitiveContains(searchText) ?? false))
            }
        }
    }
    
    private func loadAvailableUsers() {
        isLoadingUsers = true
        
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/users?limit=50&page=1") else {
            isLoadingUsers = false
            return
        }
        
        guard let token = AuthManager.shared.token else {
            isLoadingUsers = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoadingUsers = false
                
                if let error = error {
                    print("Error loading users: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = json["success"] as? Bool, success,
                       let data = json["data"] as? [String: Any],
                       let users = data["users"] as? [[String: Any]] {
                        
                        self.availableUsers = users.compactMap { userData in
                            guard let id = userData["id"] as? String,
                                  let name = userData["name"] as? String else {
                                return nil
                            }
                            
                            let email = userData["email"] as? String
                            let avatar = userData["avatar"] as? String
                            
                            return InvitedUser(id: id, name: name, email: email, avatar: avatar)
                        }
                    }
                } catch {
                    print("Error parsing users: \(error)")
                }
            }
        }.resume()
    }
    
    private func sendInvites() async {
        isInviting = true
        defer { isInviting = false }
        
        // Create RSVP entries for invited users
        for user in invitedUsers {
            let success = await eventsManager.updateEventParticipation(
                eventId: event.id,
                status: "invited",
                invitedUserId: user.id
            )
            
            if !success {
                errorMessage = "Failed to send invite to \(user.name)"
                return
            }
        }
        
        showSuccess = true
    }
}

struct ParticipantsView: View {
    let event: Event
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var eventsManager = EventsManager()
    @State private var participants: [EventParticipant] = []
    @State private var isLoading = true
    @State private var selectedTab = 0 // 0 = Going, 1 = Invited
    
    // Brand colors matching the app design
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B - Vivid Coral
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4 - Bright Teal
    private let backgroundColor = Color(red: 243/255, green: 244/255, blue: 246/255) // #F3F4F6 - Whisper Gray
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [backgroundColor.opacity(0.3), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Event Participants")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("See who's joining \(event.name)")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                                                // Tab Selector
                        HStack(spacing: 0) {
                            Button(action: { selectedTab = 0 }) {
                                VStack(spacing: 8) {
                                    Text("Going")
                            .font(.headline)
                                        .fontWeight(.semibold)
                                    Text("\(goingParticipants.count)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(selectedTab == 0 ? Color.green.opacity(0.1) : Color.clear)
                                .foregroundColor(selectedTab == 0 ? .green : .secondary)
                            }
                            
                            Button(action: { selectedTab = 1 }) {
                                VStack(spacing: 8) {
                                    Text("Invited")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Text("\(invitedParticipants.count)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(selectedTab == 1 ? primaryColor.opacity(0.1) : Color.clear)
                                .foregroundColor(selectedTab == 1 ? primaryColor : .secondary)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 24)
                        
                        // Participants List
                        if isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading participants...")
                                    .font(.headline)
                        .foregroundColor(.secondary)
                }
                            .frame(minHeight: 200)
                        } else {
                            let currentParticipants = selectedTab == 0 ? goingParticipants : invitedParticipants
                            
                            if currentParticipants.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: selectedTab == 0 ? "person.3" : "envelope.badge")
                                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                                    
                                    Text(selectedTab == 0 ? "No one is going yet" : "No one invited yet")
                                        .font(.headline)
                                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                                    
                                    Text(selectedTab == 0 ? "Be the first to join this event!" : "Start inviting friends to this event!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(32)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .padding(.horizontal, 24)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(currentParticipants) { participant in
                                        ParticipantCard(participant: participant)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Participants")
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(primaryColor)
            )
            .onAppear {
                loadParticipants()
            }
        }
    }
    
    // Computed properties to filter participants
    private var goingParticipants: [EventParticipant] {
        participants.filter { $0.status == "going" }
    }
    
    private var invitedParticipants: [EventParticipant] {
        participants.filter { $0.status == "invited" }
    }
    
    private func loadParticipants() {
        Task {
            isLoading = true
            
            if let fetchedParticipants = await eventsManager.fetchEventParticipants(eventId: event.id) {
                await MainActor.run {
                    participants = fetchedParticipants
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    participants = []
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Participant Card Component

struct ParticipantCard: View {
    let participant: EventParticipant
    
    // Brand colors matching the app design
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B - Vivid Coral
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4 - Bright Teal
    private let backgroundColor = Color(red: 243/255, green: 244/255, blue: 246/255) // #F3F4F6 - Whisper Gray
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image
            AsyncImage(url: URL(string: participant.user?.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
            Circle()
                    .fill(backgroundColor)
                .overlay(
                        Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                            .font(.system(size: 24))
                )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                Text(participant.user?.name ?? "Unknown User")
                        .font(.headline)
                    .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Status Badge
                    statusBadge
                }
                
                // Additional Info
                if let invitedBy = participant.invitedBy {
                    Text("Invited by \(invitedBy.name)")
                    .font(.caption)
                        .foregroundColor(.secondary)
                } else if participant.status == "going" {
                    Text("Joined \(formatDate(participant.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Check-in status if applicable
                if participant.isCheckedIn {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Checked in")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var statusBadge: some View {
        Text(participant.status.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
                .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch participant.status {
        case "going":
            return .green
        case "invited":
            return primaryColor
        case "interested":
            return .orange
        default:
            return .gray
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    NavigationView {
        EventDetailView(event: Event(from: [
            "id": "sample-id",
            "name": "Sample Event",
            "description": "This is a sample event description that demonstrates the layout and design of the event detail view.",
            "category": "social",
            "type": "meetup",
            "status": "published",
            "startDate": "2024-12-25T19:00:00Z",
            "endDate": "2024-12-25T22:00:00Z",
            "location": [
                "name": "Sample Venue",
                "address": "123 Main St, City, State"
            ],
            "organizer": ["name": "John Doe"],
            "maxParticipants": 50,
            "interestedCount": 10,
            "goingCount": 15,
            "invitedCount": 5,
            "isFree": true,
            "tags": ["social", "meetup", "networking"],
            "createdAt": "2024-01-01T00:00:00Z",
            "updatedAt": "2024-01-01T00:00:00Z"
        ]))
    }
} 