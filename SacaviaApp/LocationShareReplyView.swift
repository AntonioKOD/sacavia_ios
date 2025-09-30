import SwiftUI

struct LocationShareReplyView: View {
    let locationId: String
    let shareId: String
    let locationName: String
    let senderName: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var replyMessage: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var selectedTemplate: String? = nil
    
    // App colors matching the brand
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    private let backgroundColor = Color(red: 249/255, green: 250/255, blue: 251/255) // #F9FAFB
    private let mutedTextColor = Color(red: 107/255, green: 114/255, blue: 128/255) // #6B7280
    private let cardBackgroundColor = Color.white
    
    // Predefined reply templates with emojis
    private let replyTemplates = [
        ("Thanks for sharing! 🎉", "grateful"),
        ("Looks amazing! I'll check it out ✨", "excited"),
        ("Great recommendation! 👍", "appreciative"),
        ("Thanks! I'll definitely visit this place 🏃‍♂️", "committed"),
        ("Perfect timing! I was looking for something like this 🎯", "perfect"),
        ("Awesome! I'll add it to my list 📝", "organized")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Location info card
                        locationInfoCard
                        
                        // Quick reply templates
                        quickReplySection
                        
                        // Custom reply section
                        customReplySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Submit button
                submitButton
            }
            .background(backgroundColor)
            .navigationBarHidden(true)
        }
        .alert("Reply Sent!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your reply has been sent to \(senderName)")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Back button
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(primaryColor)
            }
            
            Spacer()
            
            Text("Reply")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Placeholder for symmetry
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
            }
            .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(cardBackgroundColor)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Location Info Card
    private var locationInfoCard: some View {
        VStack(spacing: 16) {
            // Location icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [primaryColor.opacity(0.1), secondaryColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(primaryColor)
            }
            
            VStack(spacing: 8) {
                Text("Reply to \(senderName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("They shared \(locationName) with you")
                    .font(.subheadline)
                    .foregroundColor(mutedTextColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Quick Reply Section
    private var quickReplySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Replies")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(replyTemplates.enumerated()), id: \.offset) { index, template in
                    let (text, _) = template
                    Button(action: {
                        replyMessage = text
                        selectedTemplate = text
                    }) {
                        Text(text)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTemplate == text ? .white : primaryColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedTemplate == text ? primaryColor : primaryColor.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(primaryColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Reply Section
    private var customReplySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Reply")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $replyMessage)
                    .frame(minHeight: 120)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: replyMessage) { newValue in
                        if !newValue.isEmpty {
                            selectedTemplate = nil
                        }
                        // Limit to 500 characters
                        if newValue.count > 500 {
                            replyMessage = String(newValue.prefix(500))
                        }
                    }
                
                Text("\(replyMessage.count)/500")
                    .font(.caption)
                    .foregroundColor(replyMessage.count > 450 ? primaryColor : mutedTextColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.2))
            
            Button(action: submitReply) {
                HStack(spacing: 12) {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(isSubmitting ? "Sending..." : "Send Reply")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(replyMessage.isEmpty ? Color.gray : primaryColor)
                )
            }
            .disabled(replyMessage.isEmpty || isSubmitting)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(cardBackgroundColor)
        }
    }
    
    private func submitReply() {
        let trimmedMessage = replyMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedMessage.isEmpty else { 
            errorMessage = "Please enter a reply message."
            return 
        }
        
        guard trimmedMessage.count <= 500 else {
            errorMessage = "Reply message is too long. Please keep it under 500 characters."
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                let success = await sendReply()
                await MainActor.run {
                    isSubmitting = false
                    if success {
                        showSuccess = true
                    } else {
                        errorMessage = "Failed to send reply. Please try again."
                    }
                }
            }
        }
    }
    
    private func sendReply() async -> Bool {
        guard let token = AuthManager.shared.token else {
            await MainActor.run {
                errorMessage = "Authentication required"
            }
            return false
        }
        
        print("📱 [LocationShareReplyView] Received parameters - locationId: '\(locationId)', shareId: '\(shareId)'")
        
        let url = URL(string: "https://sacavia.com/api/locations/\(locationId)/share/reply")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "shareId": shareId,
            "replyMessage": replyMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            "replyType": "text"
        ] as [String: Any]
        
        print("📱 [LocationShareReplyView] Sending reply to: \(url)")
        print("📱 [LocationShareReplyView] Body: \(body)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 [LocationShareReplyView] Response status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📱 [LocationShareReplyView] Response: \(responseString)")
                }
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            print("Error sending reply: \(error)")
            return false
        }
    }
}

#Preview {
    LocationShareReplyView(
        locationId: "123",
        shareId: "456",
        locationName: "Central Park",
        senderName: "John Doe"
    )
}
