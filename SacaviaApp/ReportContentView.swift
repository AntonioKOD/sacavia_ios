import SwiftUI

struct ReportContentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory = ""
    @State private var selectedReason = ""
    @State private var description = ""
    @State private var showingConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    @State private var currentStep = 1
    
    let contentType: String
    let contentId: String
    let contentTitle: String
    
    // Comprehensive reporting categories and reasons
    private let reportCategories = [
        ReportCategory(
            id: "inappropriate",
            title: "Inappropriate Content",
            icon: "exclamationmark.triangle.fill",
            color: .orange,
            reasons: [
                "explicit_content": "Explicit sexual content",
                "nudity": "Nudity or sexual imagery",
                "violence": "Graphic violence or gore",
                "self_harm": "Self-harm or suicide content",
                "drugs": "Illegal drugs or substance abuse",
                "weapons": "Weapons or dangerous items"
            ]
        ),
        ReportCategory(
            id: "harassment",
            title: "Harassment & Bullying",
            icon: "person.crop.circle.badge.exclamationmark",
            color: .red,
            reasons: [
                "hate_speech": "Hate speech or discrimination",
                "bullying": "Bullying or intimidation",
                "threats": "Threats of violence",
                "stalking": "Stalking or harassment",
                "doxxing": "Sharing private information",
                "targeted_abuse": "Targeted abuse or attacks"
            ]
        ),
        ReportCategory(
            id: "spam",
            title: "Spam & Misinformation",
            icon: "exclamationmark.bubble.fill",
            color: .yellow,
            reasons: [
                "fake_news": "False information or fake news",
                "scam": "Scam or fraudulent content",
                "spam": "Unwanted commercial content",
                "bot_activity": "Bot or automated activity",
                "clickbait": "Misleading clickbait",
                "repetitive": "Repetitive or duplicate content"
            ]
        ),
        ReportCategory(
            id: "copyright",
            title: "Copyright & Legal",
            icon: "c.circle.fill",
            color: .purple,
            reasons: [
                "copyright": "Copyright infringement",
                "trademark": "Trademark violation",
                "privacy": "Privacy violation",
                "impersonation": "Impersonation of others",
                "fake_account": "Fake or impersonated account",
                "legal_issue": "Other legal violation"
            ]
        ),
        ReportCategory(
            id: "community",
            title: "Community Guidelines",
            icon: "person.3.fill",
            color: .blue,
            reasons: [
                "offensive": "Offensive or inappropriate language",
                "inappropriate_location": "Inappropriate for location",
                "misleading": "Misleading or deceptive content",
                "quality": "Low quality or irrelevant content",
                "community_standards": "Violates community standards",
                "other_guidelines": "Other guideline violation"
            ]
        ),
        ReportCategory(
            id: "other",
            title: "Other Issues",
            icon: "questionmark.circle.fill",
            color: .gray,
            reasons: [
                "technical_issue": "Technical problem",
                "bug": "App or website bug",
                "accessibility": "Accessibility issue",
                "suggestion": "Feature suggestion",
                "other": "Other issue not listed"
            ]
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                if currentStep > 1 {
                    ProgressView(value: Double(currentStep), total: 3)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: currentStep == 1 ? "flag.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(currentStep == 1 ? .orange : .red)
                            
                            Text(currentStep == 1 ? "Report Content" : "Select Reason")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(currentStep == 1 ? "Help us keep the community safe by reporting content that violates our guidelines." : "Please select the specific reason for your report.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top)
                        
                        // Content Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content being reported:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(contentTitle)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        
                        if currentStep == 1 {
                            // Category Selection
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Select a category")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(reportCategories, id: \.id) { category in
                                        CategoryCard(
                                            category: category,
                                            isSelected: selectedCategory == category.id,
                                            onTap: {
                                                selectedCategory = category.id
                                                selectedReason = ""
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else if currentStep == 2 {
                            // Reason Selection
                            if let selectedCategoryData = reportCategories.first(where: { $0.id == selectedCategory }) {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Select specific reason")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .padding(.horizontal)
                                    
                                    VStack(spacing: 8) {
                                        ForEach(Array(selectedCategoryData.reasons.keys.sorted()), id: \.self) { key in
                                            ReasonCard(
                                                reason: selectedCategoryData.reasons[key] ?? key,
                                                isSelected: selectedReason == key,
                                                onTap: {
                                                    selectedReason = key
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        } else if currentStep == 3 {
                            // Description
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Additional details")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Help us understand the issue better (optional but recommended)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Provide more context about your report...", text: $description, axis: .vertical)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .lineLimit(4...8)
                                }
                                .padding(.horizontal)
                                
                                // Report Summary
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Report Summary")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let category = reportCategories.first(where: { $0.id == selectedCategory }),
                                       let reason = category.reasons[selectedReason] {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("Category:")
                                                    .fontWeight(.medium)
                                                Spacer()
                                                Text(category.title)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            HStack {
                                                Text("Reason:")
                                                    .fontWeight(.medium)
                                                Spacer()
                                                Text(reason)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Bottom Action Buttons
                VStack(spacing: 12) {
                    if currentStep < 3 {
                        Button(action: {
                            if currentStep == 1 && !selectedCategory.isEmpty {
                                currentStep = 2
                            } else if currentStep == 2 && !selectedReason.isEmpty {
                                currentStep = 3
                            }
                        }) {
                            HStack {
                                Text(currentStep == 1 ? "Next" : "Continue")
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canProceedToNext ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .fontWeight(.semibold)
                        }
                        .disabled(!canProceedToNext)
                    } else {
                        Button(action: {
                            showingConfirmation = true
                        }) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "flag")
                                }
                                Text(isSubmitting ? "Submitting..." : "Submit Report")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .fontWeight(.semibold)
                        }
                        .disabled(isSubmitting)
                    }
                    
                    if currentStep > 1 {
                        Button("Back") {
                            currentStep -= 1
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                }
                .padding(.horizontal)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Report Content")
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
        .confirmationDialog("Submit Report", isPresented: $showingConfirmation) {
            Button("Submit Report") {
                Task {
                    await submitReport()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to submit this report? Our moderation team will review it within 24 hours.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Report Submitted", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for your report. Our moderation team will review it within 24 hours and take appropriate action.")
        }
    }
    
    private var canProceedToNext: Bool {
        if currentStep == 1 {
            return !selectedCategory.isEmpty
        } else if currentStep == 2 {
            return !selectedReason.isEmpty
        }
        return false
    }
    
    private func submitReport() async {
        isSubmitting = true
        
        do {
            // Map detailed reason to backend format
            let mappedReason = mapReasonToBackendFormat(selectedReason)
            
            print("🔍 [ReportContentView] Submitting report:")
            print("  - Content Type: \(contentType)")
            print("  - Content ID: \(contentId)")
            print("  - Original Reason: \(selectedReason)")
            print("  - Mapped Reason: \(mappedReason)")
            print("  - Description: \(description.isEmpty ? "None" : description)")
            
            let success = try await APIService.shared.reportContent(
                contentType: contentType,
                contentId: contentId,
                reason: mappedReason,
                description: description.isEmpty ? nil : description
            )
            
            if success {
                showingSuccess = true
            } else {
                errorMessage = "Failed to submit report. Please try again."
                showingError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isSubmitting = false
    }
    
    // MARK: - Helper Functions
    
    private func mapReasonToBackendFormat(_ detailedReason: String) -> String {
        // Map detailed reasons to backend expected format
        switch detailedReason {
        // Inappropriate Content
        case "explicit_content", "nudity":
            return "inappropriate"
        case "violence", "self_harm", "drugs", "weapons":
            return "violence"
            
        // Harassment & Bullying
        case "hate_speech", "bullying", "threats", "stalking", "doxxing", "targeted_abuse":
            return "harassment"
            
        // Spam & Misinformation
        case "fake_news", "scam", "spam", "bot_activity", "clickbait", "repetitive":
            return "spam"
            
        // Copyright & Legal
        case "copyright", "trademark", "privacy", "impersonation", "fake_account", "legal_issue":
            return "copyright"
            
        // Community Guidelines
        case "offensive", "inappropriate_location", "misleading", "quality", "community_standards", "other_guidelines":
            return "inappropriate"
            
        // Other Issues
        case "technical_issue", "bug", "accessibility", "suggestion", "other":
            return "other"
            
        default:
            return "other"
        }
    }
}

// MARK: - Supporting Views

struct ReportCategory {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let reasons: [String: String]
}

struct CategoryCard: View {
    let category: ReportCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : category.color)
                
                Text(category.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(isSelected ? category.color : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReasonCard: View {
    let reason: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.system(size: 20))
                
                Text(reason)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ReportContentView(
        contentType: "post",
        contentId: "123",
        contentTitle: "Sample post content that might be inappropriate or violate community guidelines"
    )
}
