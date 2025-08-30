//
//  ContentView.swift
//  SacaviaApp
//
//  Created by Antonio Kodheli on 7/16/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var feedManager = FeedManager()
    @State private var selectedTab: BottomTabBar.Tab = .feed
    @State private var showSearch = false
    @State private var showNotifications = false
    @State private var showCreatePost = false
    @State private var notificationRefreshTimer: Timer?
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
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
                                showSearch: $showSearch
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
                            TabView(selection: $selectedTab) {
                                LocalBuzzView()
                                    .environmentObject(feedManager)
                                    .iPadContentOptimized()
                                    .tag(BottomTabBar.Tab.feed)
                                
                                LocationsMapTabView()
                                    .tag(BottomTabBar.Tab.map)
                                
                                // Empty view for create tab (handled by bottom bar button)
                                Color.clear
                                    .tag(BottomTabBar.Tab.create)
                                
                                EventsView()
                                    .iPadContentOptimized()
                                    .tag(BottomTabBar.Tab.events)
                                
                                ProfileView()
                                    .iPadContentOptimized()
                                    .tag(BottomTabBar.Tab.profile)
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .animation(.easeInOut(duration: 0.3), value: selectedTab)
                            .clipped()
                            
                            // Bottom tab bar positioned at bottom
                            BottomTabBar(selectedTab: $selectedTab) {
                                // Create post action
                                showCreatePost = true
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
        .fullScreenCover(isPresented: $showCreatePost) {
            CreatePostView()
        }
        .fullScreenCover(isPresented: $showSearch) {
            SearchView()
        }
        .fullScreenCover(isPresented: $showNotifications) {
            NotificationsView()
        }
        .onAppear {
            setupNotificationRefreshTimer()
            fetchInitialNotificationCount()
            loadLocations()
        }
        .onDisappear {
            stopNotificationRefreshTimer()
        }
        .onChange(of: showNotifications) { _, isPresented in
            if !isPresented {
                // Refresh notification count when closing notifications
                fetchInitialNotificationCount()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationRefreshTimer() {
        notificationRefreshTimer?.invalidate()
        notificationRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            fetchInitialNotificationCount()
        }
    }
    
    private func stopNotificationRefreshTimer() {
        notificationRefreshTimer?.invalidate()
        notificationRefreshTimer = nil
    }
    
    private func fetchInitialNotificationCount() {
        // Placeholder - implement notification count fetching
        // notificationManager.refreshUnreadCount()
    }
    
    private func loadLocations() {
        // Load location data if needed
    }
}

// MARK: - Custom Top Navigation Bar
struct CustomTopNavBar: View {
    @Binding var showNotifications: Bool
    @Binding var showSearch: Bool
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject var feedManager: FeedManager
    
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
                Button(action: { showNotifications = true }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .frame(width: 50, height: 50) // Increased size for better touch target
                            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                        
                        Image(systemName: "bell")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(mutedTextColor)
                        
                        // Notification badge - clean design
                        if notificationManager.hasUnreadNotifications {
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
                Button(action: { showSearch = true }) {
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
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [backgroundColor.opacity(0.3), Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header with title and create button
                HStack {
                    Spacer()
                    
                    Text("Events")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Create event button
                    Button(action: {
                        showingCreateEvent = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(primaryColor)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Header with search and actions
                VStack(spacing: 16) {
                    // Search Bar with enhanced design
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(primaryColor)
                                .font(.system(size: 16, weight: .medium))
                            
                            TextField("Search events...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 16))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white)
                                .shadow(color: primaryColor.opacity(0.1), radius: 8, x: 0, y: 2)
                        )
                        
                        // Filter button
                        Button(action: {
                            showingFilters.toggle()
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(primaryColor)
                                        .shadow(color: primaryColor.opacity(0.3), radius: 6, x: 0, y: 3)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Filter Picker with enhanced design
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filterOptions, id: \.0) { filter in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedFilter = filter.0
                                        eventsManager.fetchEvents(type: filter.0) { _, _ in }
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: filter.2)
                                            .font(.system(size: 14, weight: .medium))
                                        
                                        Text(filter.1)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(selectedFilter == filter.0 ? .white : primaryColor)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedFilter == filter.0 ? primaryColor : Color.white)
                                            .shadow(color: selectedFilter == filter.0 ? primaryColor.opacity(0.3) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    )
                                }
                                .scaleEffect(selectedFilter == filter.0 ? 1.05 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedFilter)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                
                // Events Content
                if eventsManager.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: primaryColor))
                        
                        Text("Discovering amazing events...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(primaryColor)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if eventsManager.events.isEmpty {
                    VStack(spacing: 24) {
                        // Empty state illustration
                        ZStack {
                            Circle()
                                .fill(backgroundColor)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 50, weight: .light))
                                .foregroundColor(primaryColor)
                        }
                        
                        VStack(spacing: 12) {
                            Text("No events found")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(primaryColor)
                            
                            Text("Check back later or create your own event to get started!")
                                .font(.system(size: 16))
                                .foregroundColor(Color.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        // Create Event Button
                        Button(action: {
                            showingCreateEvent = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                
                                Text("Create Event")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingCreateEvent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredEvents) { event in
                                EnhancedEventCard(event: event)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventView()
        }
        .onAppear {
            // Load events when the view appears
            if eventsManager.events.isEmpty {
                eventsManager.fetchEvents(type: selectedFilter) { _, _ in }
            }
        }
        .refreshable {
            // Pull to refresh functionality
            eventsManager.fetchEvents(type: selectedFilter) { _, _ in }
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
    @State private var selectedLocation: EventLocation?
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
    
    // MARK: - Tab Views
    
    private var basicInfoTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar.badge.plus.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(primaryColor)
                        Text("Event Details")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Text("Tell us about your event")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                
                // Event Name Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(primaryColor)
                        Text("Event Name")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    TextField("Enter a catchy event name", text: $eventName)
                        .textFieldStyle(CreateEventTextFieldStyle())
                        .font(.system(size: 16))
                }
                
                // Description Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(primaryColor)
                        Text("Description")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    TextField("Describe what people can expect at your event", text: $eventDescription, axis: .vertical)
                        .textFieldStyle(CreateEventTextFieldStyle())
                        .font(.system(size: 16))
                        .lineLimit(4...8)
                }
                
                // Category Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "tag.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(primaryColor)
                        Text("Category")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(categories, id: \.0) { category in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    eventCategory = category.0
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: category.2)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(eventCategory == category.0 ? .white : primaryColor)
                                    
                                    Text(category.1)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(eventCategory == category.0 ? .white : .primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(categoryBackground(for: category.0))
                                .overlay(categoryBorder(for: category.0))
                                .shadow(color: categoryShadow(for: category.0), radius: 8, x: 0, y: 4)
                                .scaleEffect(eventCategory == category.0 ? 1.02 : 1.0)
                            }
                        }
                    }
                }
                
                // Event Image Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "photo.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(accentColor)
                        Text("Event Image")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        VStack(spacing: 12) {
                            if let eventImage = eventImage {
                                Image(uiImage: eventImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(12)
                                    .overlay(
                                        VStack {
                                            if eventImageUploading {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(1.2)
                                                    .background(Color.black.opacity(0.5))
                                                    .clipShape(Circle())
                                                    .padding(8)
                                            }
                                        }
                                    )
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 40))
                                        .foregroundColor(accentColor)
                                    
                                    Text("Add Event Image")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Text("Upload a photo to make your event stand out")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                )
                            }
                        }
                    }
                    .disabled(eventImageUploading)
                }
                
                // Event Type Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(secondaryColor)
                        Text("Event Type")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(eventTypes, id: \.0) { type in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    eventType = type.0
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: type.2)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(eventType == type.0 ? .white : secondaryColor)
                                    
                                    Text(type.1)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(eventType == type.0 ? .white : .primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(eventTypeBackground(for: type.0))
                                .overlay(eventTypeBorder(for: type.0))
                                .shadow(color: eventTypeShadow(for: type.0), radius: 8, x: 0, y: 4)
                                .scaleEffect(eventType == type.0 ? 1.02 : 1.0)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var detailsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date & Time
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(primaryColor)
                        Text("Date & Time")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    VStack(spacing: 12) {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        
                        DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
                

                
                // Capacity
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(primaryColor)
                        Text("Capacity")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    TextField("Max attendees (optional)", text: $capacity)
                        .textFieldStyle(CreateEventTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                // Tags
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(primaryColor)
                        Text("Tags")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    HStack {
                        TextField("Add a tag", text: $currentTag)
                            .textFieldStyle(CreateEventTextFieldStyle())
                        
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(secondaryColor)
                        }
                        .disabled(currentTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    if !tags.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.system(size: 12, weight: .medium))
                                    Button(action: { removeTag(tag) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 12))
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(secondaryColor)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var locationTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Location Selection
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(primaryColor)
                        Text("Location")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Button(action: {
                        showingLocationPicker = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedLocation?.name ?? "Select Location")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(selectedLocation == nil ? .secondary : .primary)
                                
                                if let address = selectedLocation?.address {
                                    Text(address)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
                
                // Privacy Settings
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(primaryColor)
                        Text("Privacy")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: { privacy = "public" }) {
                            HStack {
                                Image(systemName: privacy == "public" ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(privacy == "public" ? primaryColor : .secondary)
                                Text("Public Event")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(privacy == "public" ? primaryColor : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        Button(action: { privacy = "private" }) {
                            HStack {
                                Image(systemName: privacy == "private" ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(privacy == "private" ? primaryColor : .secondary)
                                Text("Private Event")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(privacy == "private" ? primaryColor : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var settingsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Event Settings
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(primaryColor)
                        Text("Event Settings")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    VStack(spacing: 12) {
                        Toggle("Require Approval", isOn: $requiresApproval)
                            .toggleStyle(CustomToggleStyle())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age Restriction")
                                .font(.system(size: 14, weight: .medium))
                            
                            Picker("Age Restriction", selection: $ageRestriction) {
                                ForEach(ageRestrictions, id: \.0) { restriction in
                                    Text(restriction.1).tag(restriction.0)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                
                // Event Status
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundColor(primaryColor)
                        Text("Event Status")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: { status = "published" }) {
                            HStack {
                                Image(systemName: status == "published" ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(status == "published" ? primaryColor : .secondary)
                                Text("Published")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(status == "published" ? primaryColor : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        Button(action: { status = "draft" }) {
                            HStack {
                                Image(systemName: status == "draft" ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(status == "draft" ? primaryColor : .secondary)
                                Text("Draft")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(status == "draft" ? primaryColor : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var invitePeopleTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(primaryColor)
                        Text("Invite People")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Text("Invite friends and contacts to your event")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                
                // Search Bar
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search people...", text: $searchText)
                            .textFieldStyle(CreateEventTextFieldStyle())
                    }
                }
                
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
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onAppear {
            if availableUsers.isEmpty {
                loadAvailableUsers()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !eventDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedLocation != nil &&
        !eventImageUploading
    }
    
    private func addTag() {
        let trimmedTag = currentTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            currentTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    // MARK: - Invite People Helper Methods
    
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
    
    private func uploadEventImage(image: UIImage) {
        eventImageUploading = true
        
        Task {
            do {
                let imageId = try await uploadImageToAPI(image: image, filename: "event-image.jpg")
                await MainActor.run {
                    eventImageId = imageId
                    eventImageUploading = false
                }
            } catch {
                await MainActor.run {
                    eventImageUploading = false
                    errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func uploadImageToAPI(image: UIImage, filename: String) async throws -> String {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/upload/image") else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        guard let token = AuthManager.shared.token else {
            throw NSError(domain: "No authentication token", code: -1, userInfo: nil)
        }
        
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "Failed to compress image", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add end boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "Upload failed", code: -1, userInfo: nil)
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? ""
        print("Image upload response: \(responseString)")
        
        // Parse response to get image ID
        if let responseData = responseString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
           let success = json["success"] as? Bool, success,
           let data = json["data"] as? [String: Any],
           let imageId = data["id"] as? String {
            return imageId
        }
        
        throw NSError(domain: "Failed to parse upload response", code: -1, userInfo: nil)
    }
    
    // MARK: - Helper Functions for Complex Expressions
    
    @ViewBuilder
    private func categoryBackground(for categoryId: String) -> some View {
        if eventCategory == categoryId {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [primaryColor, primaryColor.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        }
    }
    
    private func categoryBorder(for categoryId: String) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(eventCategory == categoryId ? primaryColor : Color.gray.opacity(0.2), lineWidth: 1.5)
    }
    
    private func categoryShadow(for categoryId: String) -> Color {
        eventCategory == categoryId ? primaryColor.opacity(0.3) : Color.black.opacity(0.05)
    }
    
    @ViewBuilder
    private func eventTypeBackground(for typeId: String) -> some View {
        if eventType == typeId {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [secondaryColor, secondaryColor.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        }
    }
    
    private func eventTypeBorder(for typeId: String) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(eventType == typeId ? secondaryColor : Color.gray.opacity(0.2), lineWidth: 1.5)
    }
    
    private func eventTypeShadow(for typeId: String) -> Color {
        eventType == typeId ? secondaryColor.opacity(0.3) : Color.black.opacity(0.05)
    }
    
    private func createEvent() {
        guard isFormValid else { return }
        
        isLoading = true
        
        var eventData: [String: Any] = [
            "name": eventName.trimmingCharacters(in: .whitespacesAndNewlines),
            "description": eventDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            "category": eventCategory,
            "eventType": eventType,
            "startDate": ISO8601DateFormatter().string(from: startDate),
            "endDate": ISO8601DateFormatter().string(from: endDate),
            "isFree": true, // Always free for now
            "location": selectedLocation?.id ?? "",
            "requiresApproval": requiresApproval,
            "ageRestriction": ageRestriction,
            "tags": tags,
            "privacy": privacy,
            "status": status
        ]
        
        // Add invited users if any
        if !invitedUsers.isEmpty {
            eventData["invitedUsers"] = invitedUsers.map { $0.id }
        }
        
        // Add image if uploaded
        if !eventImageId.isEmpty {
            eventData["image"] = eventImageId
        }
        
        Task {
            let result = await eventsManager.createEvent(eventData: eventData)
            
            await MainActor.run {
                isLoading = false
                if result.success {
                    dismiss()
                } else {
                    // Check if it's a time conflict error
                    if let errorMessage = result.errorMessage,
                       errorMessage.contains("Event time conflict detected") {
                        // Extract the relevant part of the time conflict message
                        let conflictMessage = errorMessage.contains("Another event") ? 
                            errorMessage.components(separatedBy: "Another event")[1].trimmingCharacters(in: .whitespacesAndNewlines) :
                            errorMessage
                        self.errorMessage = "⚠️ Time Conflict: Another event \(conflictMessage)"
                    } else {
                        // Show as regular error for other issues
                        self.errorMessage = result.errorMessage ?? "Failed to create event. Please try again."
                    }
                    showError = true
                }
            }
        }
    }
}

// MARK: - Custom Styles

struct CreateEventTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 20)
                .fill(configuration.isOn ? Color(red: 255/255, green: 107/255, blue: 107/255) : Color.gray.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        configuration.isOn.toggle()
                    }
                }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Location Picker View
struct LocationPickerView: View {
    @Binding var selectedLocation: EventLocation?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var locations: [EventLocation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Brand colors
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B - Vivid Coral
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4 - Bright Teal
    private let backgroundColor = Color(red: 243/255, green: 244/255, blue: 246/255) // #F3F4F6 - Whisper Gray
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
            VStack {
                if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading locations...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            Text("Error loading locations")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(errorMessage)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Retry") {
                                loadLocations()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(primaryColor)
                            .cornerRadius(12)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if locations.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "mappin.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No locations found")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Try searching for a different location or check your connection")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredLocations, id: \.id) { location in
                        Button(action: {
                            selectedLocation = location
                            dismiss()
                        }) {
                                HStack(spacing: 12) {
                                    // Location icon
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(primaryColor)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                Text(location.name)
                                    .font(.headline)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                        
                                if let address = location.address {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        // Categories removed as EventLocation doesn't have categories property
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .listRowBackground(Color.white)
                            .listRowSeparator(.hidden)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
            }
            .searchable(text: $searchText, prompt: "Search locations...")
        }
        .onAppear {
            loadLocations()
        }
    }
    
    private var filteredLocations: [EventLocation] {
        if searchText.isEmpty {
            return locations
        } else {
            return locations.filter { location in
                location.name.localizedCaseInsensitiveContains(searchText) ||
                (location.address?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    private func loadLocations() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations?limit=50&page=1") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        guard let token = AuthManager.shared.token else {
            errorMessage = "Authentication required"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No response data"
                    return
                }
                
                do {
                    let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    if let success = result?["success"] as? Bool, success,
                       let data = result?["data"] as? [String: Any],
                       let locationsData = data["locations"] as? [[String: Any]] {
                        
                        self.locations = locationsData.compactMap { locationData in
                            // Convert AppLocation to EventLocation
                            guard let id = locationData["id"] as? String,
                                  let name = locationData["name"] as? String else {
                                return nil
                            }
                            
                            let description = locationData["description"] as? String ?? ""
                            
                            // Parse address
                            var address: EventAddress?
                            if let addressData = locationData["address"] as? [String: Any] {
                                address = EventAddress(
                                    street: addressData["street"] as? String ?? "",
                                    city: addressData["city"] as? String ?? "",
                                    state: addressData["state"] as? String ?? "",
                                    zip: addressData["zip"] as? String ?? "",
                                    country: addressData["country"] as? String ?? ""
                                )
                            }
                            
                            // Parse coordinates
                            var coordinates: EventCoordinates?
                            if let coordsData = locationData["coordinates"] as? [String: Any] {
                                coordinates = EventCoordinates(
                                    latitude: coordsData["latitude"] as? Double ?? 0,
                                    longitude: coordsData["longitude"] as? Double ?? 0
                                )
                            }
                            
                            return EventLocation(
                                id: id,
                                name: name,
                                description: description,
                                address: address,
                                coordinates: coordinates,
                                featuredImage: nil,
                                categories: []
                            )
                        }
                    } else {
                        let message = result?["message"] as? String ?? "Failed to load locations"
                        errorMessage = message
                    }
                } catch {
                    errorMessage = "Failed to parse response"
                }
            }
        }.resume()
    }
}

// MARK: - RSVP Button
struct RSVPButton: View {
    let title: String
    let color: Color
    let status: String
    @State private var isSelected = false
    
    var body: some View {
        Button(action: {
            isSelected.toggle()
            // Here you would call the RSVP API
        }) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

// MARK: - Helper Functions for Events

extension EnhancedEventCard {
    private func getEventStatusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "active", "published":
            return .green
        case "cancelled":
            return .red
        case "draft":
            return .orange
        case "postponed":
            return .yellow
        default:
            return .gray
        }
    }
    
    private func getRSVPColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "going":
            return .green
        case "interested":
            return .orange
        case "invited":
            return secondaryColor
        case "not_going":
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Event Image Picker
struct EventImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onImageSelected: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: EventImagePicker
        
        init(_ parent: EventImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
                parent.onImageSelected(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
                parent.onImageSelected(originalImage)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

