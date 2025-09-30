import SwiftUI
import PhotosUI

// MARK: - Simple Create Event View
struct SimpleCreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var eventsManager = EventsManager()
    
    // Essential form fields only
    @State private var eventName = ""
    @State private var eventDescription = ""
    @State private var eventDate = Date()
    @State private var eventLocation = ""
    @State private var selectedLocation: SearchLocation?
    @State private var eventImage: UIImage?
    @State private var showingImagePicker = false
    @State private var eventCapacity = ""
    @State private var isPrivateEvent = false
    @State private var eventDuration = 60 // Default 1 hour in minutes
    
    // Location search states
    @State private var locationSearchText = ""
    @State private var showingLocationSearch = false
    @State private var searchResults: [SearchLocation] = []
    @State private var isSearchingLocations = false
    
    // UI states
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Event")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Share your event with the community")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Event Image
                    VStack(spacing: 12) {
                        Text("Event Photo")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: { showingImagePicker = true }) {
                            if let image = eventImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(12)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 200)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 32))
                                                .foregroundColor(.secondary)
                                            Text("Add Event Photo")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    )
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Event Details Form
                    VStack(spacing: 20) {
                        // Event Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter event name", text: $eventName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        
                        // Event Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Tell people about your event", text: $eventDescription, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                                .lineLimit(3...6)
                        }
                        
                        // Event Date & Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date & Time")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            DatePicker("Event Date", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        // Event Location (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location (Optional)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                if let selectedLocation = selectedLocation {
                                    // Show selected location
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: "location.fill")
                                                .foregroundColor(secondaryColor)
                                            Text(selectedLocation.name)
                                                .font(.body)
                                                .fontWeight(.medium)
                                            Spacer()
                                            Button("Change") {
                                                self.selectedLocation = nil
                                                self.eventLocation = ""
                                            }
                                            .font(.caption)
                                            .foregroundColor(primaryColor)
                                        }
                                        
                                        if let address = selectedLocation.address, !address.isEmpty {
                                            Text(address)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                } else {
                                    // Show search field
                                    TextField("Search for a location or enter manually", text: $eventLocation)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .font(.body)
                                        .onTapGesture {
                                            showingLocationSearch = true
                                        }
                                    
                                    Button(action: {
                                        showingLocationSearch = true
                                    }) {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(primaryColor)
                                            .font(.title2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Event Capacity (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Capacity (Optional)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter maximum attendees", text: $eventCapacity)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                                .keyboardType(.numberPad)
                        }
                        
                        // Event Duration
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Duration")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("\(eventDuration) minutes")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Stepper(value: $eventDuration, in: 15...480, step: 15) {
                                    Text("Duration")
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // Event Privacy
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Privacy")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Button(action: { isPrivateEvent = false }) {
                                    HStack {
                                        Image(systemName: isPrivateEvent ? "circle" : "checkmark.circle.fill")
                                            .foregroundColor(isPrivateEvent ? .secondary : primaryColor)
                                        Text("Public")
                                            .foregroundColor(isPrivateEvent ? .secondary : .primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Spacer()
                                
                                Button(action: { isPrivateEvent = true }) {
                                    HStack {
                                        Image(systemName: isPrivateEvent ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(isPrivateEvent ? primaryColor : .secondary)
                                        Text("Private")
                                            .foregroundColor(isPrivateEvent ? .primary : .secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Create Button
                    Button(action: createEvent) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            
                            Text(isLoading ? "Creating Event..." : "Create Event")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isFormValid || isLoading)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .photosPicker(isPresented: $showingImagePicker, selection: Binding<PhotosPickerItem?>(
            get: { nil },
            set: { item in
                if let item = item {
                    loadImage(from: item)
                }
            }
        ), matching: .images)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your event has been created successfully!")
        }
        .sheet(isPresented: $showingLocationSearch) {
            LocationSearchSheet(
                searchText: $locationSearchText,
                searchResults: $searchResults,
                isSearching: $isSearchingLocations,
                onLocationSelected: { location in
                    selectedLocation = location
                    eventLocation = location.name
                    showingLocationSearch = false
                }
            )
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        return !eventName.isEmpty && 
               !eventDescription.isEmpty
               // Location is now optional - backend will create default if empty
    }
    
    // MARK: - Functions
    private func createEvent() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Calculate end date based on duration
                let endDate = eventDate.addingTimeInterval(TimeInterval(eventDuration * 60))
                
                // Prepare event data
                var eventData: [String: Any] = [
                    "name": eventName,
                    "title": eventName, // Backend expects both
                    "description": eventDescription,
                    "startDate": ISO8601DateFormatter().string(from: eventDate),
                    "endDate": ISO8601DateFormatter().string(from: endDate),
                    "durationMinutes": eventDuration,
                    "category": "social",
                    "eventType": "social_event",
                    "isFree": true,
                    "status": "published",
                    "privacy": isPrivateEvent ? "private" : "public",
                    "tags": []
                ]
                
                // Add capacity if provided
                if !eventCapacity.isEmpty, let capacity = Int(eventCapacity), capacity > 0 {
                    eventData["capacity"] = capacity
                    print("🔍 [SimpleCreateEventView] Event capacity: \(capacity)")
                }
                
                // Add location only if provided
                if let selectedLocation = selectedLocation {
                    print("🔍 [SimpleCreateEventView] Selected location ID: '\(selectedLocation.id)' (length: \(selectedLocation.id.count))")
                    print("🔍 [SimpleCreateEventView] Selected location name: '\(selectedLocation.name)'")
                    
                    // Validate that the location ID is a valid MongoDB ObjectId (24 character hex string)
                    if isValidObjectId(selectedLocation.id) {
                        // Backend expects the location ID in the 'location' field, not 'locationId'
                        eventData["location"] = selectedLocation.id
                        print("✅ [SimpleCreateEventView] Using valid location ID: \(selectedLocation.id)")
                    } else {
                        // If the ID is not valid, just use the location name as a string
                        eventData["location"] = selectedLocation.name
                        print("⚠️ [SimpleCreateEventView] Invalid location ID format: '\(selectedLocation.id)', using location name instead")
                    }
                } else if !eventLocation.isEmpty {
                    eventData["location"] = eventLocation
                    print("🔍 [SimpleCreateEventView] Using manual location: '\(eventLocation)'")
                }
                
                // Add image if selected
                if let image = eventImage {
                    print("🔍 [SimpleCreateEventView] Image selected, uploading...")
                    // Upload image first
                    if let imageId = await uploadEventImage(image: image) {
                        eventData["image"] = imageId
                        print("✅ [SimpleCreateEventView] Image uploaded with ID: \(imageId)")
                    } else {
                        print("❌ [SimpleCreateEventView] Image upload failed")
                    }
                } else {
                    print("🔍 [SimpleCreateEventView] No image selected")
                }
                
                // Debug: Print the event data being sent
                print("🔍 [SimpleCreateEventView] Event data being sent:")
                for (key, value) in eventData {
                    print("  \(key): \(value)")
                }
                
                // Create event
                let result = await eventsManager.createEvent(eventData: eventData)
                
                await MainActor.run {
                    isLoading = false
                    if result.success {
                        // Post notification to refresh events list
                        NotificationCenter.default.post(name: NSNotification.Name("EventCreated"), object: nil)
                        showSuccess = true
                        
                        // Auto-dismiss after successful creation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    } else {
                        errorMessage = result.errorMessage ?? "Failed to create event"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Error: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func uploadEventImage(image: UIImage) async -> String? {
        do {
            let apiService = APIService()
            let imageId = try await apiService.uploadMedia(image: image)
            print("🔍 [SimpleCreateEventView] Image uploaded successfully: \(imageId)")
            return imageId
        } catch {
            print("❌ [SimpleCreateEventView] Failed to upload image: \(error)")
            return nil
        }
    }
    
    private func loadImage(from item: PhotosPickerItem) {
        Task {
            print("🔍 [SimpleCreateEventView] Loading image from PhotosPicker...")
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                print("✅ [SimpleCreateEventView] Image loaded successfully, size: \(image.size)")
                await MainActor.run {
                    self.eventImage = image
                }
            } else {
                print("❌ [SimpleCreateEventView] Failed to load image from PhotosPicker")
            }
        }
    }
    
    private func isValidObjectId(_ id: String) -> Bool {
        // MongoDB ObjectId is a 24 character hex string
        return id.count == 24 && id.allSatisfy { $0.isHexDigit }
    }
    
}

// MARK: - Location Search Sheet
struct LocationSearchSheet: View {
    @Binding var searchText: String
    @Binding var searchResults: [SearchLocation]
    @Binding var isSearching: Bool
    let onLocationSelected: (SearchLocation) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search locations...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { _, newValue in
                            searchLocations(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                            searchResults = []
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                // Search Results
                if isSearching {
                    VStack {
                        Spacer()
                        ProgressView("Searching locations...")
                        Spacer()
                    }
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "location.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No locations found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else if searchResults.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "location")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Search for a location")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Enter a location name to find venues")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List(searchResults, id: \.id) { location in
                        LocationSearchRow(location: location) {
                            onLocationSelected(location)
                        }
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchLocations(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        Task {
            do {
                let results = try await APIService.shared.searchLocationsDetailed(query: query)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.searchResults = []
                    self.isSearching = false
                }
            }
        }
    }
}

// MARK: - Location Search Row
struct LocationSearchRow: View {
    let location: SearchLocation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Location icon
                Image(systemName: "location.fill")
                    .foregroundColor(Color(red: 78/255, green: 205/255, blue: 196/255))
                    .font(.title2)
                
                // Location info
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let address = location.address, !address.isEmpty {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    if let neighborhood = location.neighborhood, !neighborhood.isEmpty {
                        Text(neighborhood)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
}

// MARK: - Preview
struct SimpleCreateEventView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleCreateEventView()
    }
}
