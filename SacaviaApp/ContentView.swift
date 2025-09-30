//
//  ContentView.swift
//  SacaviaApp
//
//  Created by Antonio Kodheli on 7/16/25.
//

import SwiftUI

// MARK: - Navigation Items
struct LocationNavigationItem: Identifiable {
    let id: String
    let locationId: String
    
    init(locationId: String) {
        self.id = locationId
        self.locationId = locationId
    }
}

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var feedManager = FeedManager()
    @StateObject private var crashHandler = CrashHandler.shared
    @State private var selectedTab: BottomTabBar.Tab = .feed
    @State private var showSearch = false
    @State private var showNotifications = false
    @State private var showCreatePost = false
    @State private var notificationRefreshTimer: Timer?
    
    // Navigation state for notifications
    @State private var navigateToLocationId: LocationNavigationItem?
    @State private var navigateToPostId: String?
    @State private var navigateToReviewId: String?
    @State private var navigateToUserId: String?
    @State private var navigateToEventId: String?
    
    // Location share reply state
    @State private var showLocationShareReply = false
    @State private var replyLocationId: String = ""
    @State private var replyShareId: String = ""
    @State private var replyLocationName: String = ""
    @State private var replySenderName: String = ""
    
    // Single sheet presentation state
    @State private var currentSheet: SheetType? = nil
    
    enum SheetType: Identifiable {
        case search
        case notifications
        case createPost
        case locationShareReply
        
        var id: String {
            switch self {
            case .search: return "search"
            case .notifications: return "notifications"
            case .createPost: return "createPost"
            case .locationShareReply: return "locationShareReply"
            }
        }
    }
    
    var body: some View {
        Group {
            if crashHandler.hasCrashed {
                CrashErrorView {
                    crashHandler.reset()
                }
            } else if authManager.isAuthenticated {
                ZStack {
                    // Background with proper safe area handling
                    Color.white
                        .ignoresSafeArea(.all)
                    
                    // Main content stack with proper safe area constraints  
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            // Custom top navigation bar - ensure visibility
                            CustomTopNavBar(
                                showNotifications: $showNotifications,
                                showSearch: $showSearch,
                                currentSheet: $currentSheet
                            )
                            .environmentObject(feedManager)
                            .zIndex(1) // Ensure it appears above content
                            .padding(.top, 35) // Increased to ensure clearance from iPhone system UI elements (notch/dynamic island)
                            .padding(.bottom, 12)
                            .background(
                                Rectangle()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    .ignoresSafeArea(.container, edges: .horizontal)
                            )
                            
                            // Content area with proper constraints
                            let safeTabSelection = Binding<BottomTabBar.Tab>(
                                get: { selectedTab == .create ? .events : selectedTab },
                                set: { newValue in selectedTab = (newValue == .create ? .events : newValue) }
                            )
                            TabView(selection: safeTabSelection) {
                                LocalBuzzView()
                                    .environmentObject(feedManager)
                                    .iPadContentOptimized()
                                    .tag(BottomTabBar.Tab.feed)
                                
                                LocationsMapTabView()
                                    .tag(BottomTabBar.Tab.map)
                                
                                EventsView()
                                    .iPadContentOptimized()
                                    .tag(BottomTabBar.Tab.events)
                                
                                ProfileView(userId: authManager.user?.id)
                                    .iPadContentOptimized()
                                    .tag(BottomTabBar.Tab.profile)
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .animation(.easeInOut(duration: 0.3), value: selectedTab)
                            .clipped()
                            
                            // Bottom tab bar positioned at bottom
                            BottomTabBar(selectedTab: $selectedTab) {
                                // Create post action
                                currentSheet = .createPost
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    
                    // Floating Action Button overlay
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            FloatingActionButton()
                                .padding(.trailing, 16)
                                .padding(.bottom, 40) // Much closer to bottom bar - significantly reduced
                        }
                    }
                    .iPadContentOptimized() // Apply iPad-specific content optimizations
                }
            } else {
                LoginView()
            }
        }
        .fullScreenCover(item: $currentSheet) { sheetType in
            switch sheetType {
            case .search:
                SearchView()
            case .notifications:
                NotificationsView()
            case .createPost:
                CreatePostView()
            case .locationShareReply:
                LocationShareReplyView(
                    locationId: replyLocationId,
                    shareId: replyShareId,
                    locationName: replyLocationName,
                    senderName: replySenderName
                )
            }
        }
        .sheet(item: $navigateToLocationId) { locationItem in
            EnhancedLocationDetailView(locationId: locationItem.locationId)
        }
        .onAppear {
            setupNotificationRefreshTimer()
            fetchInitialNotificationCount()
            loadLocations()
            setupNotificationObservers()
        }
        .onDisappear {
            stopNotificationRefreshTimer()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationRefreshTimer() {
        notificationRefreshTimer?.invalidate()
        notificationRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            notificationManager.refreshNotifications()
        }
    }
    
    private func stopNotificationRefreshTimer() {
        notificationRefreshTimer?.invalidate()
        notificationRefreshTimer = nil
    }
    
    private func fetchInitialNotificationCount() {
        notificationManager.refreshNotifications()
    }
    
    private func loadLocations() {
        // Load location data if needed
    }
    
    private func setupNotificationObservers() {
        // Listen for navigation notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToLocation"),
            object: nil,
            queue: .main
        ) { notification in
            if let locationId = notification.userInfo?["locationId"] as? String {
                navigateToLocationId = LocationNavigationItem(locationId: locationId)
                // Navigate to locations tab and show location detail
                selectedTab = .map
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToPost"),
            object: nil,
            queue: .main
        ) { notification in
            if let postId = notification.userInfo?["postId"] as? String {
                navigateToPostId = postId
                // Navigate to feed tab and show post detail
                selectedTab = .feed
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToReview"),
            object: nil,
            queue: .main
        ) { notification in
            if let reviewId = notification.userInfo?["reviewId"] as? String {
                navigateToReviewId = reviewId
                // Navigate to feed tab and show review detail
                selectedTab = .feed
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToProfile"),
            object: nil,
            queue: .main
        ) { notification in
            if let userId = notification.userInfo?["userId"] as? String {
                navigateToUserId = userId
                // Navigate to profile tab
                selectedTab = .profile
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToEvent"),
            object: nil,
            queue: .main
        ) { notification in
            if let eventId = notification.userInfo?["eventId"] as? String {
                navigateToEventId = eventId
                // Navigate to events tab
                selectedTab = .events
            }
        }
        
        // Listen for location share reply notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenLocationShareReply"),
            object: nil,
            queue: .main
        ) { notification in
            print("📱 [ContentView] Received OpenLocationShareReply notification")
            print("📱 [ContentView] userInfo: \(notification.userInfo ?? [:])")
            
            if let locationId = notification.userInfo?["locationId"] as? String,
               let shareId = notification.userInfo?["shareId"] as? String,
               let locationName = notification.userInfo?["locationName"] as? String,
               let senderName = notification.userInfo?["senderName"] as? String {
                print("📱 [ContentView] Setting reply data - locationId: '\(locationId)', shareId: '\(shareId)'")
                replyLocationId = locationId
                replyShareId = shareId
                replyLocationName = locationName
                replySenderName = senderName
                currentSheet = .locationShareReply
            } else {
                print("📱 [ContentView] Missing required data in notification")
            }
        }
    }
}

// MARK: - Custom Top Navigation Bar
struct CustomTopNavBar: View {
    @Binding var showNotifications: Bool
    @Binding var showSearch: Bool
    @Binding var currentSheet: ContentView.SheetType?
    @EnvironmentObject var feedManager: FeedManager
    @StateObject private var notificationManager = NotificationManager.shared
    
    // Modern minimalistic brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    let backgroundColor = Color(red: 249/255, green: 250/255, blue: 251/255) // #F9FAFB
    let mutedTextColor = Color(red: 107/255, green: 114/255, blue: 128/255) // #6B7280
    
    var body: some View {
        HStack(spacing: 16) {
            // Clean app logo without background - made bigger for better visibility
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 55, height: 55)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            
            Spacer()
            
            // Modern action buttons
            HStack(spacing: 16) {
                // Notifications button - enhanced design with larger touch target
                Button(action: { currentSheet = .notifications }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .frame(width: 50, height: 50) // Increased size for better touch target
                            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                        
                        Image(systemName: "bell")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(mutedTextColor)
                        
                        // Notification badge - clean design
                        if notificationManager.unreadCount > 0 {
                            VStack {
                                HStack {
                                    Spacer()
                                    Circle()
                                        .fill(primaryColor)
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Text("\(min(notificationManager.unreadCount, 99))")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                        .offset(x: 10, y: -10)
                                }
                                Spacer()
                            }
                            .frame(width: 50, height: 50)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle()) // Ensure proper button interaction
                
                // Search button - enhanced with larger touch target
                Button(action: { currentSheet = .search }) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .frame(width: 50, height: 50) // Increased size for better touch target
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                        .overlay(
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(mutedTextColor)
                        )
                }
                .buttonStyle(PlainButtonStyle()) // Ensure proper button interaction
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8) // Ensure adequate top safe area padding for visibility
        .padding(.bottom, 12) // Bottom spacing for content separation  
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(Color.white)
                .frame(maxWidth: .infinity)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .clipped() // Ensure content stays within bounds
    }
}

// MARK: - Placeholder Views (replace with your actual views)

struct EventsView: View {
    @StateObject private var eventsManager = EventsManager()
    @State private var selectedFilter = "all"
    @State private var showingCreateEvent = false
    @State private var searchText = ""
    @State private var showingFilters = false
    
    // Brand colors matching the actual app branding from globals.css
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // Vivid Coral #FF6B6B
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // Bright Teal #4ECDC4
    private let accentColor = Color(red: 255/255, green: 230/255, blue: 109/255) // Warm Yellow #FFE66D
    private let backgroundColor = Color(red: 243/255, green: 244/255, blue: 246/255) // Whisper Gray #F3F4F6
    
    private let filterOptions = [
        ("all", "All Events", "calendar"),
        ("upcoming", "Upcoming", "clock"),
        ("today", "Today", "sun.max"),
        ("thisWeek", "This Week", "calendar.badge.clock"),
        ("myEvents", "My Events", "person.2")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with title and add button
            HStack {
                Text("Events")
                    .font(.title2).fontWeight(.bold)
                Spacer()
                Button(action: { showingCreateEvent = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(primaryColor)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

            // Search and filter row
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search events...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))

                Picker("Filter", selection: $selectedFilter) {
                    ForEach(filterOptions, id: \.0) { option in
                        Text(option.1).tag(option.0)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.white)

            // Content list
            Group {
                if eventsManager.isLoading {
                    VStack(spacing: 12) {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: primaryColor))
                        Text("Loading events...").foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredEvents.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus").font(.system(size: 40)).foregroundColor(primaryColor)
                        Text("No events found").font(.headline)
                        Text("Try adjusting your search or create a new event.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredEvents) { event in
                        EnhancedEventCard(event: event)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        eventsManager.refreshEvents(type: selectedFilter)
                    }
                    .overlay(
                        // Show refresh indicator when refreshing
                        eventsManager.isRefreshing ? 
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: primaryColor))
                            Text("Refreshing events...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white.opacity(0.8))
                        : nil
                    )
                }
            }
            .background(LinearGradient(gradient: Gradient(colors: [backgroundColor.opacity(0.3), Color.white]), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea())
        }
        .sheet(isPresented: $showingCreateEvent) { 
            SimpleCreateEventView()
        }
        .onChange(of: showingCreateEvent) { _, isShowing in
            // Refresh events when create event sheet is dismissed
            if !isShowing {
                eventsManager.refreshEvents(type: selectedFilter)
                print("🔄 [EventsView] Events list refreshed after create event sheet dismissal")
            }
        }
        .onAppear {
            if eventsManager.events.isEmpty {
                eventsManager.fetchEvents(type: selectedFilter) { _, _ in }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EventCreated"))) { _ in
            // Refresh events list when a new event is created
            eventsManager.refreshEvents(type: selectedFilter)
            print("🔄 [EventsView] Events list refreshed after new event creation")
        }
    }
    
    private var filteredEvents: [Event] {
        if searchText.isEmpty {
            return eventsManager.events
        } else {
            return eventsManager.events.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText) ||
                event.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Events Hero Header
struct HeroEventsHeader: View {
    let totalCount: Int
    let primaryColor: Color
    let secondaryColor: Color
    let onCreate: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [primaryColor.opacity(0.18), secondaryColor.opacity(0.18)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(primaryColor.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Discover Events")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(totalCount == 0 ? "No events yet — be the first to create one!" : "\(totalCount) events around you")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onCreate) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Create")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [primaryColor, secondaryColor]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: primaryColor.opacity(0.25), radius: 8, x: 0, y: 4)
                }
            }
            .padding(18)
        }
    }
}

// Enhanced Event Card with brand design
struct EnhancedEventCard: View {
    let event: Event
    @State private var showingEventDetail = false
    @State private var isPressed = false
    
    // Brand colors matching the actual app branding
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // Vivid Coral #FF6B6B
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // Bright Teal #4ECDC4
    private let accentColor = Color(red: 255/255, green: 230/255, blue: 109/255) // Warm Yellow #FFE66D
    private let backgroundColor = Color(red: 243/255, green: 244/255, blue: 246/255) // Whisper Gray #F3F4F6
    
    var body: some View {
        Button(action: {
            showingEventDetail = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Event Image with overlay
                ZStack(alignment: .topLeading) {
                    if let imageUrl = event.image?.url {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [backgroundColor, Color.white]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Image(systemName: "calendar")
                                        .font(.system(size: 40, weight: .light))
                                        .foregroundColor(primaryColor)
                                )
                        }
                        .frame(height: 180)
                        .clipped()
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [backgroundColor, Color.white]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 180)
                            .overlay(
                                Image(systemName: "calendar")
                                    .font(.system(size: 40, weight: .light))
                                    .foregroundColor(primaryColor)
                            )
                    }
                    
                    // Bottom gradient overlay for better text contrast
                    VStack { Spacer() }
                        .frame(height: 180)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.45)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 0))
                        )
                        .clipped()
                    
                    // Title + price/free badge overlay
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Text(event.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Spacer()
                            if let price = event.price, !event.isFree {
                                PriceBadge(price: price, currency: event.currency)
                            } else {
                                FreeBadge()
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                    .frame(height: 180)
                    
                    // Date badge
                    VStack(spacing: 0) {
                        Text(formatMonth(event.startDate))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(primaryColor)
                        
                        Text(formatDay(event.startDate))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(primaryColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.top, 16)
                    .padding(.leading, 16)
                    
                    // Category badge
                    VStack {
                        Text(event.category.capitalized)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(secondaryColor)
                                    .shadow(color: secondaryColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 16)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                // Event Info
                VStack(alignment: .leading, spacing: 12) {
                    // Title and status
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(primaryColor)
                            .lineLimit(2)
                        
                        HStack {
                            Image(systemName: "clock")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryColor)
                            
                            Text(formatEventTime(event.startDate, event.endDate))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.gray)
                            
                            Spacer()
                            
                            if let capacity = event.capacity {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.3")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(secondaryColor)
                                    
                                    Text("\(event.attendeeCount)/\(capacity)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(secondaryColor)
                                }
                            }
                        }
                    }
                    
                    // Location
                    if let location = event.location {
                        HStack(spacing: 8) {
                            Image(systemName: "location")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryColor)
                            
                            Text(location.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.gray)
                                .lineLimit(1)
                        }
                    }
                    
                    // Organizer
                    if let organizer = event.organizer {
                        HStack(spacing: 8) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryColor)
                            
                            Text("by \(organizer.name)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.gray)
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            // Handle RSVP
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Join")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(secondaryColor)
                            )
                        }
                        
                        Button(action: {
                            // Handle share
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Share")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(primaryColor)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(primaryColor, lineWidth: 1.5)
                            )
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // Handle save
                        }) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(accentColor)
                        }
                    }
                }
                .padding(20)
                .background(Color.white)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .sheet(isPresented: $showingEventDetail) {
            EventDetailView(event: event)
        }
    }
    
    private func formatMonth(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM"
            return formatter.string(from: date).uppercased()
        }
        return "JAN"
    }
    
    private func formatDay(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "d"
            return formatter.string(from: date)
        }
        return "1"
    }
    
    private func formatEventTime(_ startDate: String, _ endDate: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let start = formatter.date(from: startDate) {
            formatter.dateFormat = "h:mm a"
            let startTime = formatter.string(from: start)
            
            if let end = formatter.date(from: endDate) {
                let endTime = formatter.string(from: end)
                return "\(startTime) - \(endTime)"
            }
            
            return startTime
        }
        
        return "TBD"
    }
}

// MARK: - Event Price Badges
struct PriceBadge: View {
    let price: Double
    let currency: String?
    
    var body: some View {
        Text(formattedPrice)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
    }
    
    private var formattedPrice: String {
        if let currency = currency, !currency.isEmpty {
            return "\(currency.uppercased()) \(String(format: "%.2f", price))"
        } else {
            return "$\(String(format: "%.2f", price))"
        }
    }
}

struct FreeBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "gift.fill")
                .font(.system(size: 10, weight: .bold))
            Text("Free")
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Event Card
struct EventCard: View {
    let event: Event
    @State private var showingEventDetail = false
    
    var body: some View {
        Button(action: {
            showingEventDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Event Image
                if let imageUrl = event.image?.url {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "calendar")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 160)
                        .overlay(
                            Image(systemName: "calendar")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                        .cornerRadius(12)
                }
                
                // Event Info
                VStack(alignment: .leading, spacing: 8) {
                    // Title and Category
                    HStack {
                        Text(event.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Text(event.category)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    
                    // Date and Time
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                        Text(formatEventDate(event.startDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let price = event.price {
                            Text(event.isFree ? "Free" : "$\(String(format: "%.2f", price))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(event.isFree ? .green : .primary)
                        } else {
                            Text("Free")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Location
                    if let location = event.location {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.secondary)
                            Text(location.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    // Attendance and RSVP Status
                    HStack {
                        // Attendance counts
                        HStack(spacing: 16) {
                            Label("\(event.goingCount)", systemImage: "person.fill")
                            Label("\(event.interestedCount)", systemImage: "person")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // RSVP Status
                        if let rsvpStatus = event.userRsvpStatus {
                            Text(rsvpStatus.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(rsvpStatusColor(rsvpStatus))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingEventDetail) {
            NavigationView {
                EventDetailView(event: event)
            }
        }
    }
    
    private func formatEventDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return "Date TBD"
    }
    
    private func rsvpStatusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "going":
            return .green
        case "interested":
            return .orange
        case "not_going":
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Create Event View  
public struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var eventsManager = EventsManager()
    
    // Form states
    @State private var eventName = ""
    @State private var eventDescription = ""
    @State private var eventCategory = "social"
    @State private var eventType = "social_event"
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isFree = true
    @State private var capacity = ""
    @State private var requiresApproval = false
    @State private var ageRestriction = "all"
    @State private var tags: [String] = []
    @State private var currentTag = ""
    @State private var privacy = "public"
    @State private var status = "published"
    
    // Image upload states
    @State private var eventImage: UIImage?
    @State private var eventImageUploading = false
    @State private var eventImageId: String = ""
    @State private var showingImagePicker = false
    
    // UI states
    @State private var showingLocationPicker = false
    @State private var selectedLocation: Location?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var activeTab = 0
    
    // Invite people states
    @State private var showingInvitePeople = false
    @State private var invitedUsers: [InvitedUser] = []
    @State private var searchText = ""
    @State private var isLoadingUsers = false
    @State private var availableUsers: [InvitedUser] = []
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // Vivid Coral #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // Bright Teal #4ECDC4
    let accentColor = Color(red: 255/255, green: 230/255, blue: 109/255) // Warm Yellow #FFE66D
    let backgroundColor = Color(red: 243/255, green: 244/255, blue: 246/255) // Whisper Gray #F3F4F6
    
    // Data options
    private let categories = [
        ("social", "Social", "person.2.fill"),
        ("entertainment", "Entertainment", "music.note"),
        ("education", "Education", "book.fill"),
        ("business", "Business", "briefcase.fill"),
        ("other", "Other", "ellipsis.circle.fill")
    ]
    
    // MARK: - Computed Properties
    private var basicInfoTab: some View {
        VStack(spacing: 20) {
            // Event name
            VStack(alignment: .leading, spacing: 8) {
                Text("Event Name")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Enter event name", text: $eventName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
            }
            
            // Event description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Describe your event", text: $eventDescription, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                    .lineLimit(3...6)
            }
            
            // Category and type
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Picker("Category", selection: $eventCategory) {
                        ForEach(categories, id: \.0) { category in
                            HStack {
                                Image(systemName: category.2)
                                Text(category.1)
                            }
                            .tag(category.0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Picker("Type", selection: $eventType) {
                        ForEach(eventTypes, id: \.0) { type in
                            HStack {
                                Image(systemName: type.2)
                                Text(type.1)
                            }
                            .tag(type.0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var detailsTab: some View {
        VStack(spacing: 20) {
            // Date and time
            VStack(alignment: .leading, spacing: 16) {
                Text("Date & Time")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("End")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                }
            }
            
            // Capacity and restrictions
            VStack(alignment: .leading, spacing: 16) {
                Text("Capacity & Restrictions")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Capacity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Unlimited", text: $capacity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age Restriction")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Age", selection: $ageRestriction) {
                            ForEach(ageRestrictions, id: \.0) { restriction in
                                Text(restriction.1).tag(restriction.0)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
            
            // Privacy settings
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Privacy", selection: $privacy) {
                    Text("Public").tag("public")
                    Text("Private").tag("private")
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Toggle("Requires Approval", isOn: $requiresApproval)
                    .font(.body)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var locationTab: some View {
        VStack(spacing: 20) {
            if let location = selectedLocation {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Selected Location")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.name)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            if let address = location.address {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Change") {
                            showingLocationPicker = true
                        }
                        .font(.caption)
                        .foregroundColor(primaryColor)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "location.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No Location Selected")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Choose a location for your event")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Select Location") {
                        showingLocationPicker = true
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(primaryColor)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var settingsTab: some View {
        VStack(spacing: 20) {
            // Event image
            VStack(alignment: .leading, spacing: 12) {
                Text("Event Image")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let image = eventImage {
                    HStack {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Event Image")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            if eventImageUploading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Uploading...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Tap to change")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Remove") {
                            eventImage = nil
                            eventImageId = ""
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                } else {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo")
                                .font(.title2)
                            Text("Add Event Image")
                                .font(.body)
                        }
                        .foregroundColor(primaryColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            
            // Tags
            VStack(alignment: .leading, spacing: 12) {
                Text("Tags")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Add a tag", text: $currentTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Add") {
                            if !currentTag.isEmpty && !tags.contains(currentTag) {
                                tags.append(currentTag)
                                currentTag = ""
                            }
                        }
                        .disabled(currentTag.isEmpty)
                    }
                    
                    if !tags.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack {
                                    Text(tag)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    
                                    Button(action: {
                                        tags.removeAll { $0 == tag }
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(primaryColor)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var invitePeopleTab: some View {
        VStack(spacing: 20) {
            // Search for users
            VStack(alignment: .leading, spacing: 12) {
                Text("Invite People")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    TextField("Search users...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) { _ in
                            // TODO: Implement user search
                        }
                    
                    Button("Search") {
                        // TODO: Implement user search
                    }
                    .disabled(searchText.isEmpty)
                }
            }
            
            // Invited users
            if !invitedUsers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Invited Users")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(invitedUsers, id: \.id) { user in
                            HStack {
                                AsyncImage(url: URL(string: user.avatar ?? "")) { image in
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
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Text(user.email ?? "No email")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Remove") {
                                    invitedUsers.removeAll { $0.id == user.id }
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        return !eventName.isEmpty && 
               !eventDescription.isEmpty && 
               selectedLocation != nil
    }
    
    // MARK: - Functions
    private func createEvent() {
        guard isFormValid else { return }
        
        isLoading = true
        
        // TODO: Implement event creation API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isLoading = false
            self.dismiss()
        }
    }
    
    private func uploadEventImage(image: UIImage) {
        eventImageUploading = true
        
        // TODO: Implement image upload
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.eventImageUploading = false
            self.eventImageId = "uploaded_image_id"
        }
    }
    
    private let eventTypes = [
        ("social_event", "Social Event", "person.2.fill"),
        ("meetup", "Meetup", "person.3.fill"),
        ("workshop", "Workshop", "hammer.fill"),
        ("concert", "Concert", "music.mic"),
        ("other_event", "Other", "calendar.badge.plus")
    ]
    

    
    private let ageRestrictions = [
        ("all", "All Ages"),
        ("13+", "13+"),
        ("16+", "16+"),
        ("18+", "18+"),
        ("21+", "21+")
    ]
    
    public var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            Button(action: {
                                dismiss()
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
                            
                            Text("Create Event")
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
                        
                        // Tab indicators
                        HStack(spacing: 0) {
                            ForEach(0..<5, id: \.self) { index in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        activeTab = index
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Text(tabTitle(for: index))
                                            .font(.system(size: 14, weight: activeTab == index ? .semibold : .medium))
                                            .foregroundColor(activeTab == index ? primaryColor : .secondary)
                                        
                                        Rectangle()
                                            .fill(activeTab == index ? primaryColor : Color.clear)
                                            .frame(height: 2)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Content
                    TabView(selection: $activeTab) {
                        // Basic Info Tab
                        basicInfoTab
                            .tag(0)
                        
                        // Details Tab
                        detailsTab
                            .tag(1)
                        
                        // Location Tab
                        locationTab
                            .tag(2)
                        
                        // Settings Tab
                        settingsTab
                            .tag(3)
                        
                        // Invite People Tab
                        invitePeopleTab
                            .tag(4)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: activeTab)
                    
                    // Bottom Actions
                    VStack(spacing: 16) {
                        // Progress indicator
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { index in
                                Circle()
                                    .fill(index <= activeTab ? primaryColor : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            if activeTab > 0 {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        activeTab -= 1
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Previous")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                }
                            }
                            
                            Spacer()
                            
                            if activeTab < 4 {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        activeTab += 1
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Text("Next")
                                            .font(.system(size: 16, weight: .semibold))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                            } else {
                                Button(action: createEvent) {
                                    HStack(spacing: 8) {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                        Text(isLoading ? "Creating..." : "Create Event")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                                    .disabled(isLoading || !isFormValid)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -2)
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(selectedLocation: $selectedLocation)
            }
            .sheet(isPresented: $showingImagePicker) {
                EventImagePicker(image: $eventImage, onImageSelected: { image in
                    if let image = image {
                        uploadEventImage(image: image)
                    }
                })
            }
        }
    }
    
    // MARK: - Tab Title Helper
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0:
            return "Basic Info"
        case 1:
            return "Details"
        case 2:
            return "Location"
        case 3:
            return "Settings"
        case 4:
            return "Invite"
        default:
            return "Tab \(index)"
        }
    }
    
    // ... Remaining implementation unchanged ...
}

// MARK: - LocationPickerView
struct LocationPickerView: View {
    @Binding var selectedLocation: Location?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Location Picker")
                    .font(.title)
                    .padding()
                
                Text("Select a location for your event")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Select Location") {
                    // TODO: Implement location selection
                    selectedLocation = Location(
                        id: "1",
                        name: "Sample Location",
                        address: "123 Main St",
                        coordinates: MapCoordinates(latitude: 0, longitude: 0),
                        featuredImage: nil,
                        imageUrl: nil,
                        rating: nil,
                        description: nil,
                        shortDescription: nil,
                        slug: nil,
                        gallery: nil,
                        categories: nil,
                        tags: nil,
                        priceRange: nil,
                        businessHours: nil,
                        contactInfo: nil,
                        accessibility: nil,
                        bestTimeToVisit: nil,
                        insiderTips: nil,
                        isVerified: nil,
                        isFeatured: nil,
                        hasBusinessPartnership: nil,
                        partnershipDetails: nil,
                        neighborhood: nil,
                        isSaved: nil,
                        isSubscribed: nil,
                        createdBy: nil,
                        createdAt: nil,
                        updatedAt: nil,
                        ownership: nil,
                        reviewCount: nil,
                        visitCount: nil,
                        reviews: nil,
                        communityPhotos: nil
                    )
                    dismiss()
                }
                .font(.body)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(12)
                
                Spacer()
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - EventImagePicker
struct EventImagePicker: View {
    @Binding var image: UIImage?
    let onImageSelected: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Select Event Image")
                    .font(.title)
                    .padding()
                
                Text("Choose an image for your event")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Select Image") {
                    // TODO: Implement image picker
                    let sampleImage = UIImage(systemName: "photo")?.withTintColor(.blue, renderingMode: .alwaysOriginal)
                    image = sampleImage
                    onImageSelected(sampleImage)
                    dismiss()
                }
                .font(.body)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(12)
                
                Spacer()
            }
            .navigationTitle("Event Image")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

