import SwiftUI

// MARK: - Claim Business Modal
struct ClaimBusinessModal: View {
    let locationId: String
    let locationName: String
    @Binding var isPresented: Bool
    @State private var email = ""
    @State private var isSubmitting = false
    @State private var error: String?
    @State private var success = false
    
    // Brand colors
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(primaryColor.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "building.2")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(primaryColor)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Claim This Business")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Claim ownership of **\(locationName)** to manage your business listing, respond to reviews, and access exclusive features.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(secondaryColor)
                            Text("Business Email")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        TextField("Enter your business email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    if let error = error {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: submitClaim) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle")
                            }
                            Text(isSubmitting ? "Submitting..." : "Submit Claim")
                        }
                        .font(.system(size: 16, weight: .semibold))
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
                    .disabled(isSubmitting || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button(action: { isPresented = false }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .disabled(isSubmitting)
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
            Text("Check your email to verify ownership and complete the claim process.")
        }
    }
    
    // MARK: - Actions
    
    private func submitClaim() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Basic email validation
        let emailRegex = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        if trimmedEmail.range(of: emailRegex, options: .regularExpression, range: nil, locale: nil) == nil {
            error = "Please enter a valid email address"
            return
        }
        
        isSubmitting = true
        error = nil
        
        Task {
            do {
                let success = await initiateClaim(email: trimmedEmail)
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
    
    private func initiateClaim(email: String) async -> Bool {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations/\(locationId)/claim/initiate") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication
        if let token = AuthManager.shared.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody = ["email": email]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 Claim initiation status: \(httpResponse.statusCode)")
                return httpResponse.statusCode == 200 || httpResponse.statusCode == 201
            }
            
            return false
        } catch {
            print("📱 Error initiating claim: \(error)")
            return false
        }
    }
}

// MARK: - Claim Status View
struct ClaimStatusView: View {
    let locationId: String
    @State private var claimStatus: ClaimStatusData?
    @State private var isLoading = true
    @State private var error: String?
    
    // Brand colors
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(error)
                } else if let claimStatus = claimStatus {
                    claimStatusView(claimStatus)
                }
            }
            .navigationTitle("Claim Status")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadClaimStatus()
        }
    }
    
    private var loadingView: some View {
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
            Text("Loading claim status...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
            Spacer()
        }
    }
    
    private func errorView(_ error: String) -> some View {
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
            Spacer()
        }
    }
    
    private func claimStatusView(_ claim: ClaimStatusData) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(statusColor(claim.claimStatus).opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: statusIcon(claim.claimStatus))
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(statusColor(claim.claimStatus))
                    }
                    
                    VStack(spacing: 8) {
                        Text(statusTitle(claim.claimStatus))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(statusDescription(claim.claimStatus))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Business Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("Business Information")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        BusinessInfoRow(icon: "building.2", title: "Business Name", value: claim.businessInfo.businessName)
                        BusinessInfoRow(icon: "envelope", title: "Contact Email", value: claim.businessInfo.contactEmail)
                        BusinessInfoRow(icon: "person", title: "Owner Name", value: claim.businessInfo.ownerName)
                        
                        if let title = claim.businessInfo.ownerTitle {
                            BusinessInfoRow(icon: "briefcase", title: "Owner Title", value: title)
                        }
                        
                        if let phone = claim.businessInfo.ownerPhone {
                            BusinessInfoRow(icon: "phone", title: "Owner Phone", value: phone)
                        }
                        
                        if let website = claim.businessInfo.businessWebsite {
                            BusinessInfoRow(icon: "globe", title: "Website", value: website)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Timeline
                VStack(alignment: .leading, spacing: 16) {
                    Text("Timeline")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        TimelineItem(
                            title: "Claim Submitted",
                            date: formatDate(claim.submittedAt),
                            isCompleted: true
                        )
                        
                        if let reviewedAt = claim.reviewedAt {
                            TimelineItem(
                                title: "Review Completed",
                                date: formatDate(reviewedAt),
                                isCompleted: true
                            )
                        } else {
                            TimelineItem(
                                title: "Under Review",
                                date: "Estimated: \(claim.estimatedReviewTime)",
                                isCompleted: false
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Rejection Reason (if applicable)
                if claim.claimStatus == "rejected", let reason = claim.rejectionReason {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rejection Reason")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(reason)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Action Button
                if claim.claimStatus == "approved" {
                    NavigationLink(destination: EditLocationView(locationId: locationId)) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Manage Your Business")
                        }
                        .font(.system(size: 16, weight: .semibold))
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
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Functions
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "pending":
            return .orange
        case "approved":
            return .green
        case "rejected":
            return .red
        default:
            return .gray
        }
    }
    
    private func statusIcon(_ status: String) -> String {
        switch status {
        case "pending":
            return "clock"
        case "approved":
            return "checkmark.circle"
        case "rejected":
            return "xmark.circle"
        default:
            return "questionmark.circle"
        }
    }
    
    private func statusTitle(_ status: String) -> String {
        switch status {
        case "pending":
            return "Claim Under Review"
        case "approved":
            return "Claim Approved!"
        case "rejected":
            return "Claim Rejected"
        default:
            return "Unknown Status"
        }
    }
    
    private func statusDescription(_ status: String) -> String {
        switch status {
        case "pending":
            return "Your business claim is being reviewed. We'll notify you once the review is complete."
        case "approved":
            return "Congratulations! Your business claim has been approved. You can now manage your business listing."
        case "rejected":
            return "Unfortunately, your business claim was not approved. Please review the reason below and contact support if needed."
        default:
            return "Unable to determine claim status."
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        return dateString
    }
    
    private func loadClaimStatus() {
        guard let url = URL(string: "\(baseAPIURL)/api/mobile/locations/\(locationId)/claim") else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication
        if let token = AuthManager.shared.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.error = "No data received"
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(ClaimStatusResponse.self, from: data)
                    if response.success {
                        self.claimStatus = response.data
                    } else {
                        self.error = response.error ?? "Failed to load claim status"
                    }
                } catch {
                    print("Claim status decoding error:", error)
                    self.error = "Failed to parse claim status data"
                }
            }
        }.resume()
    }
}

// MARK: - Supporting Views

struct BusinessInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 78/255, green: 205/255, blue: 196/255))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

struct TimelineItem: View {
    let title: String
    let date: String
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(date)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Data Models

struct ClaimStatusData: Codable {
    let id: String
    let locationId: String
    let locationName: String
    let locationSlug: String?
    let claimStatus: String
    let submittedAt: String
    let reviewedAt: String?
    let estimatedReviewTime: String
    let businessInfo: BusinessInfo
    let verificationInfo: VerificationInfo
    let rejectionReason: String?
    let reviewerNotes: String?
}

struct BusinessInfo: Codable {
    let businessName: String
    let contactEmail: String
    let ownerName: String
    let ownerTitle: String?
    let ownerPhone: String?
    let businessWebsite: String?
    let businessDescription: String?
    let businessAddress: BusinessAddress?
}

struct BusinessAddress: Codable {
    let street: String
    let city: String
    let state: String
    let zip: String
    let country: String
}

struct VerificationInfo: Codable {
    let claimMethod: String
    let businessLicense: String?
    let taxId: String?
    let additionalDocuments: [String]?
}

struct ClaimStatusResponse: Codable {
    let success: Bool
    let data: ClaimStatusData?
    let error: String?
}

#Preview {
    ClaimBusinessModal(
        locationId: "sample-location-id",
        locationName: "Sample Business",
        isPresented: .constant(true)
    )
}
