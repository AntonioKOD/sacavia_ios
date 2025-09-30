import SwiftUI
import CoreLocation

struct PlannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiService = APIService()
    @State private var input = ""
    @State private var isLoading = false
    @State private var plan: Plan?
    @State private var errorMessage: String?
    @State private var userLocation: CLLocation?
    @State private var locationManager = CLLocationManager()
    @State private var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @State private var showSuggestions = false
    @State private var selectedLocationId: String?
    @State private var showLocationDetail = false
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(primaryColor)
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                    .foregroundColor(primaryColor)
                                
                                Text("Gem Agent")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            Text("Your Personal Local Assistant")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(primaryColor)
                    }
                    .padding(.horizontal)
                    
                    // Description
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "message.circle.fill")
                                .font(.title3)
                                .foregroundColor(primaryColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Just tell me what you want to do!")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Examples: 'I want to take the kids in Boston', 'romantic dinner date', 'fun afternoon with friends'")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Input Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "text.bubble.fill")
                                    .foregroundColor(primaryColor)
                                    .font(.title3)
                                
                                Text("What would you like to do?")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            TextField("Tell me what you're looking for...", text: $input, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal)
                        
                        // Quick Suggestions
                        if showSuggestions {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Quick Suggestions")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(quickSuggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            input = suggestion
                                            showSuggestions = false
                                        }) {
                                            Text(suggestion)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(primaryColor)
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Toggle Suggestions Button
                        Button(action: { withAnimation { showSuggestions.toggle() } }) {
                            HStack {
                                Image(systemName: showSuggestions ? "chevron.up" : "lightbulb.fill")
                                    .font(.caption)
                                Text(showSuggestions ? "Hide suggestions" : "Show suggestions")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(primaryColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(primaryColor.opacity(0.1))
                            .cornerRadius(20)
                        }
                        
                        // Location Status
                        if locationPermissionStatus == .denied || locationPermissionStatus == .restricted {
                            LocationWarningCard()
                        } else if locationPermissionStatus == .authorizedWhenInUse || locationPermissionStatus == .authorizedAlways {
                            LocationEnabledCard()
                        }
                        
                        // Generate Button
                        Button(action: generatePlan) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                
                                Text(isLoading ? "Finding the best places..." : "Get Personalized Suggestions")
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
                            .cornerRadius(16)
                            .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                        .padding(.horizontal)
                        
                        // Error Message
                        if let errorMessage = errorMessage {
                            ErrorCard(message: errorMessage)
                        }
                        
                        // Plan Display
                        if let plan = plan {
                            SimplePlanDisplayView(plan: plan) { locationId in
                    selectedLocationId = locationId
                    showLocationDetail = true
                }
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .onAppear {
            setupLocationManager()
        }
        .sheet(isPresented: $showLocationDetail) {
            if let locationId = selectedLocationId {
                EnhancedLocationDetailView(locationId: locationId)
            }
        }
    }
    
    // Enhanced quick suggestions with intent-based categories
    private let quickSuggestions = [
        // Single suggestion prompts
        "Find me just a date spot",
        "Show me one good restaurant",
        "Recommend me a coffee shop",
        "Where should I go for lunch?",
        
        // Multiple options prompts
        "Show me some dinner options",
        "Give me choices for family fun",
        "What are my options for tonight?",
        "Show me different activities",
        
        // Activity-specific prompts
        "I want to take the kids out",
        "Romantic dinner date",
        "Fun with friends",
        "Solo adventure",
        "Business meeting",
        "Cultural experience"
    ]
    
    private func setupLocationManager() {
        locationManager.delegate = LocationManagerDelegate.shared
        locationPermissionStatus = locationManager.authorizationStatus
        
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
        
        // Update location if already available
        if let location = locationManager.location {
            userLocation = location
        }
        
        // Check location status periodically
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let newStatus = locationManager.authorizationStatus
            if newStatus != locationPermissionStatus {
                locationPermissionStatus = newStatus
                
                if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                    locationManager.startUpdatingLocation()
                }
            }
        }
    }
    
    private func generatePlan() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        plan = nil
        
        let coordinates = userLocation.map { Coordinates(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
        
        // Smart context detection based on user input
        let detectedContext = detectContextFromInput(input)
        
        print("🔍 [PlannerView] Generating plan with:")
        print("  - Input: \(input)")
        print("  - Detected Context: \(detectedContext)")
        print("  - Coordinates: \(coordinates?.latitude ?? 0), \(coordinates?.longitude ?? 0)")
        
        Task {
            do {
                let response = try await apiService.generatePlan(
                    input: input,
                    context: detectedContext, // Use smart context detection
                    coordinates: coordinates
                )
                
                print("🔍 [PlannerView] Received response:")
                print("  - Success: \(response.success)")
                print("  - Nearby locations found: \(response.nearbyLocationsFound ?? 0)")
                print("  - Verified locations used: \(response.verifiedLocationsUsed ?? 0)")
                print("  - User location: \(response.userLocation ?? "Unknown")")
                
                if let plan = response.plan {
                    print("  - Plan title: \(plan.title)")
                    print("  - Plan steps: \(plan.steps.count)")
                    print("  - Verified location count: \(plan.verifiedLocationCount ?? 0)")
                    print("  - Location IDs: \(plan.locationIds ?? [])")
                }
                
                await MainActor.run {
                    isLoading = false
                    
                    if let error = response.error {
                        errorMessage = error
                        print("❌ [PlannerView] Error: \(error)")
                    } else if let plan = response.plan {
                        self.plan = plan
                        print("✅ [PlannerView] Plan generated successfully")
                    } else {
                        errorMessage = "Failed to generate plan. Please try again."
                        print("❌ [PlannerView] No plan received")
                    }
                }
            } catch {
                print("❌ [PlannerView] API call failed: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to generate plan: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Smart Context Detection
    
    private func detectContextFromInput(_ input: String) -> String {
        let inputLower = input.lowercased()
        
        // Family/kids context
        if inputLower.contains("kid") || inputLower.contains("child") || inputLower.contains("family") || 
           inputLower.contains("children") || inputLower.contains("baby") || inputLower.contains("toddler") {
            return "family"
        }
        
        // Date/romantic context
        if inputLower.contains("date") || inputLower.contains("romantic") || inputLower.contains("couple") || 
           inputLower.contains("anniversary") || inputLower.contains("valentine") || inputLower.contains("dinner") {
            return "date"
        }
        
        // Solo context
        if inputLower.contains("solo") || inputLower.contains("alone") || inputLower.contains("me time") || 
           inputLower.contains("quiet") || inputLower.contains("peaceful") {
            return "solo"
        }
        
        // Group/friends context
        if inputLower.contains("friend") || inputLower.contains("group") || inputLower.contains("party") || 
           inputLower.contains("social") || inputLower.contains("hangout") || inputLower.contains("meetup") {
            return "friends"
        }
        
        // Business context
        if inputLower.contains("business") || inputLower.contains("meeting") || inputLower.contains("work") || 
           inputLower.contains("professional") || inputLower.contains("office") {
            return "business"
        }
        
        // Celebration context
        if inputLower.contains("birthday") || inputLower.contains("celebration") || inputLower.contains("party") || 
           inputLower.contains("anniversary") || inputLower.contains("graduation") {
            return "celebration"
        }
        
        // Cultural context
        if inputLower.contains("museum") || inputLower.contains("art") || inputLower.contains("culture") || 
           inputLower.contains("theater") || inputLower.contains("gallery") || inputLower.contains("history") {
            return "cultural"
        }
        
        // Default to casual if no specific context detected
        return "casual"
    }
}

// MARK: - Simple Components

struct LocationWarningCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.slash.fill")
                .font(.title3)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Location Access Required")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Enable location access in Settings to get personalized recommendations with real locations near you.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct LocationEnabledCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.fill")
                .font(.title3)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Location Enabled")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Will use nearby verified locations for personalized suggestions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ErrorCard: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct SimplePlanDisplayView: View {
    let plan: Plan
    let onLocationTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(Color(red: 255/255, green: 107/255, blue: 107/255))
                    
                    Text("Gem Agent")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                if let summary = plan.summary {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 28)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Suggestions
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Here are my suggestions:")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Show suggestion count
                    if plan.steps.count == 1 {
                        Text("1 focused recommendation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if plan.steps.count <= 3 {
                        Text("\(plan.steps.count) curated options")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(plan.steps.count) diverse choices")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                ForEach(Array(plan.steps.enumerated()), id: \.offset) { index, step in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            // Suggestion bubble
                            ZStack {
                                Circle()
                                    .fill(Color(red: 78/255, green: 205/255, blue: 196/255).opacity(0.2))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 78/255, green: 205/255, blue: 196/255))
                            }
                            
                            // Suggestion content
                            Text(step)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        
                        // View Location Button
                        if let locationIds = plan.locationIds, index < locationIds.count {
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    onLocationTap(locationIds[index])
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "location.fill")
                                            .font(.caption)
                                        
                                        Text("View Location")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(red: 78/255, green: 205/255, blue: 196/255))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            // Enhanced location info with smart messaging
            if let usedRealLocations = plan.usedRealLocations, usedRealLocations {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("I found some great verified places near you!")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                            
                            // Smart messaging based on suggestion count
                            if plan.steps.count == 1 {
                                Text("Perfect match for your request")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else if plan.steps.count <= 3 {
                                Text("Curated selection just for you")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Diverse options to choose from")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    if let verifiedCount = plan.verifiedLocationCount, verifiedCount > 0 {
                        Text("✨ \(verifiedCount) verified location\(verifiedCount == 1 ? "" : "s") included")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if let nearbyCount = plan.nearbyLocationsFound, nearbyCount > 0 {
                        Text("📍 Based on \(nearbyCount) location\(nearbyCount == 1 ? "" : "s") in your area")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
}

// MARK: - Location Manager Delegate
class LocationManagerDelegate: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = LocationManagerDelegate()
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // This will be handled by the view's onAppear and state updates
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Location updates will be handled by the view's state
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

#Preview {
    PlannerView()
} 