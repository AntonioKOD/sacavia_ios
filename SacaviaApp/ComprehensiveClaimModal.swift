import SwiftUI

// MARK: - Comprehensive Claim Modal
struct ComprehensiveClaimModal: View {
    let locationId: String
    let locationName: String
    @Binding var isPresented: Bool
    @State private var currentStep = 1
    @State private var isSubmitting = false
    @State private var error: String?
    @State private var success = false
    
    // Form data
    @State private var contactEmail = ""
    @State private var businessName = ""
    @State private var ownerName = ""
    @State private var ownerTitle = ""
    @State private var ownerPhone = ""
    @State private var businessWebsite = ""
    @State private var businessDescription = ""
    @State private var businessAddress = ClaimBusinessAddress()
    @State private var claimMethod = "email"
    @State private var businessLicense = ""
    @State private var taxId = ""
    @State private var locationData = ClaimLocationData()
    
    // Brand colors
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: 4)
                    .progressViewStyle(LinearProgressViewStyle(tint: primaryColor))
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                // Step indicator
                HStack {
                    Text("Step \(currentStep) of 4")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(stepTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(primaryColor)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case 1:
                            basicInfoStep
                        case 2:
                            businessDetailsStep
                        case 3:
                            verificationStep
                        case 4:
                            locationInfoStep
                        default:
                            basicInfoStep
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 1 {
                        Button("Previous") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isSubmitting)
                    }
                    
                    Spacer()
                    
                    if currentStep < 4 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSubmitting || !isCurrentStepValid)
                    } else {
                        Button("Submit Claim") {
                            submitClaim()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSubmitting || !isCurrentStepValid)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Claim Business")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        isPresented = false
                    }
                    .disabled(isSubmitting)
                }
            }
        }
        .alert("Success", isPresented: $success) {
            Button("OK") {
                success = false
                isPresented = false
            }
        } message: {
            Text("Your business claim has been submitted successfully! You will be notified once it's reviewed.")
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") {
                error = nil
            }
        } message: {
            if let error = error {
                Text(error)
            }
        }
    }
    
    // MARK: - Step 1: Basic Information
    private var basicInfoStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Business Information")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 16) {
                    // Business Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Business Name *")
                            .font(.system(size: 16, weight: .semibold))
                        TextField("Your Business Name", text: $businessName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Contact Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Business Email *")
                            .font(.system(size: 16, weight: .semibold))
                        TextField("business@example.com", text: $contactEmail)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Owner Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Owner/Manager Name *")
                            .font(.system(size: 16, weight: .semibold))
                        TextField("Your Full Name", text: $ownerName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Owner Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.system(size: 16, weight: .semibold))
                        TextField("Owner, Manager, etc.", text: $ownerTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Owner Phone
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number")
                            .font(.system(size: 16, weight: .semibold))
                        TextField("(555) 123-4567", text: $ownerPhone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Business Details
    private var businessDetailsStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Business Details")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 16) {
                    // Website
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Website")
                            .font(.system(size: 16, weight: .semibold))
                        TextField("https://yourbusiness.com", text: $businessWebsite)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                    
                    // Business Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Business Description")
                            .font(.system(size: 16, weight: .semibold))
                        TextField("Describe your business, services, and what makes it special...", text: $businessDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Business Address
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Business Address")
                            .font(.system(size: 16, weight: .semibold))
                        
                        VStack(spacing: 12) {
                            TextField("Street Address", text: $businessAddress.street)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            HStack(spacing: 12) {
                                TextField("City", text: $businessAddress.city)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField("State", text: $businessAddress.state)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            HStack(spacing: 12) {
                                TextField("ZIP Code", text: $businessAddress.zip)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField("Country", text: $businessAddress.country)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 3: Verification
    private var verificationStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Verification Method")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 16) {
                    // Verification Method
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verification Method *")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Picker("Verification Method", selection: $claimMethod) {
                            Text("Email Verification").tag("email")
                            Text("Phone Verification").tag("phone")
                            Text("Business License").tag("business_license")
                            Text("Tax ID").tag("tax_id")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Conditional fields based on verification method
                    if claimMethod == "business_license" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Business License Number")
                                .font(.system(size: 16, weight: .semibold))
                            TextField("Enter your business license number", text: $businessLicense)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    if claimMethod == "tax_id" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tax ID / EIN")
                                .font(.system(size: 16, weight: .semibold))
                            TextField("Enter your Tax ID or EIN", text: $taxId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 4: Location Information
    private var locationInfoStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Location Information")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 16) {
                    // Location Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location Name")
                            .font(.system(size: 16, weight: .semibold))
                        TextField("Location display name", text: $locationData.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Short Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Short Description")
                            .font(.system(size: 16, weight: .semibold))
                        TextField("Brief description for listings", text: $locationData.shortDescription)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Full Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Description")
                            .font(.system(size: 16, weight: .semibold))
                        TextField("Detailed description of your location...", text: $locationData.description, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Price Range
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Price Range")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Picker("Price Range", selection: $locationData.priceRange) {
                            Text("Free").tag("free")
                            Text("Budget").tag("budget")
                            Text("Moderate").tag("moderate")
                            Text("Expensive").tag("expensive")
                            Text("Luxury").tag("luxury")
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // Business Hours
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Business Hours")
                            .font(.system(size: 16, weight: .semibold))
                        
                        VStack(spacing: 8) {
                            ForEach(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], id: \.self) { day in
                                BusinessHoursRow(day: day, hours: $locationData.businessHours)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var stepTitle: String {
        switch currentStep {
        case 1: return "Basic Information"
        case 2: return "Business Details"
        case 3: return "Verification"
        case 4: return "Location Information"
        default: return "Basic Information"
        }
    }
    
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 1:
            return !contactEmail.isEmpty && !businessName.isEmpty && !ownerName.isEmpty
        case 2:
            return true // Business details are optional
        case 3:
            return true // Verification method is always valid
        case 4:
            return true // Location info is optional
        default:
            return false
        }
    }
    
    // MARK: - Actions
    private func submitClaim() {
        isSubmitting = true
        error = nil
        
        Task {
            do {
                let success = await submitComprehensiveClaim()
                await MainActor.run {
                    isSubmitting = false
                    if success {
                        self.success = true
                    } else {
                        error = "Failed to submit claim. Please try again."
                    }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    self.error = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func submitComprehensiveClaim() async -> Bool {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations/\(locationId)/claim") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication
        if let token = AuthManager.shared.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody: [String: Any] = [
            "contactEmail": contactEmail,
            "businessName": businessName,
            "ownerName": ownerName,
            "ownerTitle": ownerTitle,
            "ownerPhone": ownerPhone,
            "businessWebsite": businessWebsite,
            "businessDescription": businessDescription,
            "businessAddress": [
                "street": businessAddress.street,
                "city": businessAddress.city,
                "state": businessAddress.state,
                "zip": businessAddress.zip,
                "country": businessAddress.country
            ],
            "claimMethod": claimMethod,
            "businessLicense": businessLicense,
            "taxId": taxId,
            "locationData": [
                "name": locationData.name,
                "description": locationData.description,
                "shortDescription": locationData.shortDescription,
                "businessHours": locationData.businessHours.map { hour in
                    [
                        "day": hour.day,
                        "open": hour.open,
                        "close": hour.close,
                        "closed": hour.closed
                    ]
                },
                "amenities": locationData.amenities,
                "priceRange": locationData.priceRange
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 Comprehensive claim status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    return true
                } else {
                    print("📱 Claim failed with status: \(httpResponse.statusCode)")
                    return false
                }
            }
            
            return false
        } catch {
            print("📱 Claim error: \(error)")
            return false
        }
    }
}

// MARK: - Supporting Types
struct ClaimBusinessAddress {
    var street: String = ""
    var city: String = ""
    var state: String = ""
    var zip: String = ""
    var country: String = "US"
}

struct ClaimLocationData {
    var name: String = ""
    var description: String = ""
    var shortDescription: String = ""
    var businessHours: [ClaimBusinessHour] = [
        ClaimBusinessHour(day: "Monday", open: "09:00", close: "17:00", closed: false),
        ClaimBusinessHour(day: "Tuesday", open: "09:00", close: "17:00", closed: false),
        ClaimBusinessHour(day: "Wednesday", open: "09:00", close: "17:00", closed: false),
        ClaimBusinessHour(day: "Thursday", open: "09:00", close: "17:00", closed: false),
        ClaimBusinessHour(day: "Friday", open: "09:00", close: "17:00", closed: false),
        ClaimBusinessHour(day: "Saturday", open: "10:00", close: "16:00", closed: false),
        ClaimBusinessHour(day: "Sunday", open: "10:00", close: "16:00", closed: false)
    ]
    var amenities: [String] = []
    var priceRange: String = ""
}

struct ClaimBusinessHour {
    var day: String
    var open: String
    var close: String
    var closed: Bool
}

// MARK: - Business Hours Row
struct BusinessHoursRow: View {
    let day: String
    @Binding var hours: [ClaimBusinessHour]
    
    private var dayHours: Binding<ClaimBusinessHour> {
        Binding(
            get: { hours.first { $0.day == day } ?? ClaimBusinessHour(day: day, open: "09:00", close: "17:00", closed: false) },
            set: { newValue in
                if let index = hours.firstIndex(where: { $0.day == day }) {
                    hours[index] = newValue
                } else {
                    hours.append(newValue)
                }
            }
        )
    }
    
    var body: some View {
        HStack {
            Text(day)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 80, alignment: .leading)
            
            Toggle("Closed", isOn: dayHours.closed)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 255/255, green: 107/255, blue: 107/255)))
            
            if !dayHours.closed.wrappedValue {
                HStack(spacing: 8) {
                    TextField("Open", text: dayHours.open)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    
                    Text("to")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Close", text: dayHours.close)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                }
            }
        }
    }
}
