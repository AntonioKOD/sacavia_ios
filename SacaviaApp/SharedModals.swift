import SwiftUI
import UIKit

// MARK: - Supporting Types

struct InsiderTipSubmission: Codable {
    let category: String
    let tip: String
    let priority: String
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Modal Views

struct WriteReviewModal: View {
    let locationId: String
    let onSuccess: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var auth: AuthManager
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var rating: Double = 4.0
    @State private var visitDate: Date = Date()
    @State private var pros: String = ""
    @State private var cons: String = ""
    @State private var tips: String = ""
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var success = false
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    private var isSubmitDisabled: Bool {
        isLoading || title.isEmpty || content.isEmpty
    }
    
    private var submitButtonOpacity: Double {
        isSubmitDisabled ? 0.6 : 1.0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(primaryColor)
                        
                        Text("Write a Review")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Share your experience with the community")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.headline)
                                .fontWeight(.semibold)
                            TextField("Give your review a title", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Rating
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Rating")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack {
                                ForEach(1...5, id: \.self) { star in
                                    StarButton(star: star, rating: $rating)
                                }
                                
                                Spacer()
                                
                                Text(String(format: "%.1f", rating))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(primaryColor)
                            }
                        }
                        
                        // Content
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Review")
                                .font(.headline)
                                .fontWeight(.semibold)
                            TextEditor(text: $content)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        // Visit Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Visit Date")
                                .font(.headline)
                                .fontWeight(.semibold)
                            DatePicker("Visit Date", selection: $visitDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                        
                        // Pros & Cons
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pros")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                TextField("What you loved", text: $pros)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cons")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                TextField("What could be better", text: $cons)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        // Tips
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Insider Tips (Optional)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            TextField("Any tips for future visitors", text: $tips)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Error/Success Messages
                        if let error = error {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if success {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Review submitted successfully!")
                                    .foregroundColor(.green)
                                Spacer()
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Submit Button
                    Button(action: submitReview) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            Text(isLoading ? "Submitting..." : "Submit Review")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(GradientBackground(primaryColor: primaryColor, secondaryColor: secondaryColor))
                        .cornerRadius(12)
                        .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isSubmitDisabled)
                    .opacity(submitButtonOpacity)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Write Review")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    func submitReview() {
        isLoading = true
        error = nil
        success = false
        
        let urlString = "\(baseAPIURL)/api/mobile/locations/\(locationId)/reviews"
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = auth.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let body: [String: Any] = [
            "title": title,
            "content": content,
            "rating": rating,
            "visitDate": dateFormatter.string(from: visitDate),
            "pros": pros.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            "cons": cons.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            "tips": tips.isEmpty ? nil : tips,
            "reviewType": "location",
            "location": locationId
        ].compactMapValues { $0 }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, err in
            DispatchQueue.main.async {
                isLoading = false
                
                if let err = err {
                    error = err.localizedDescription
                    return
                }
                
                guard let data = data else {
                    error = "No data received"
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let successVal = json["success"] as? Bool, successVal {
                        success = true
                        onSuccess()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                        error = (json["error"] as? String) ?? "Unknown error"
                    }
                } else {
                    error = "Unknown error"
                }
            }
        }.resume()
    }
}

struct AddTipModal: View {
    let locationId: String
    let onSuccess: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var auth: AuthManager
    
    @State private var category: String = ""
    @State private var tip: String = ""
    @State private var priority: String = "medium"
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var success = false
    
    let categories = [
        "timing": "⏰ Best Times to Visit",
        "food": "🍽️ Food & Drinks",
        "secrets": "💡 Local Secrets",
        "protips": "🎯 Pro Tips",
        "access": "🚗 Getting There",
        "savings": "💰 Money Saving",
        "recommendations": "📱 What to Order/Try",
        "hidden": "🎪 Hidden Features"
    ]
    
    let priorities = [
        "high": "🔥 Essential",
        "medium": "⭐ Helpful",
        "low": "💡 Nice to Know"
    ]
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    private var isSubmitDisabled: Bool {
        isLoading || category.isEmpty || tip.isEmpty
    }
    
    private var submitButtonOpacity: Double {
        isSubmitDisabled ? 0.6 : 1.0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "lightbulb.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Share Insider Tip")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Help others discover the best of this place")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Picker("Category", selection: $category) {
                                Text("Select a category").tag("")
                                ForEach(categories.keys.sorted(), id: \.self) { key in
                                    Text(categories[key] ?? key).tag(key)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // Tip Content
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Tip")
                                .font(.headline)
                                .fontWeight(.semibold)
                            TipTextEditor(tip: $tip, category: category)
                        }
                        
                        // Priority
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Priority")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 12) {
                                ForEach(priorities.keys.sorted(), id: \.self) { key in
                                    PriorityButton(
                                        key: key,
                                        priority: $priority,
                                        priorities: priorities,
                                        primaryColor: primaryColor,
                                        secondaryColor: secondaryColor
                                    )
                                }
                            }
                        }
                        
                        // Error/Success Messages
                        if let error = error {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if success {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Tip submitted successfully!")
                                    .foregroundColor(.green)
                                Spacer()
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Submit Button
                    Button(action: submitTip) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            Text(isLoading ? "Submitting..." : "Submit Tip")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(GradientBackground(primaryColor: primaryColor, secondaryColor: secondaryColor))
                        .cornerRadius(12)
                        .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isSubmitDisabled)
                    .opacity(submitButtonOpacity)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Add Tip")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    func submitTip() {
        isLoading = true
        error = nil
        success = false
        
        guard let token = auth.getValidToken() else {
            error = "You must be logged in to submit a tip"
            isLoading = false
            return
        }
        
        let tipSubmission = InsiderTipSubmission(category: category, tip: tip, priority: priority)
        LocationsViewModel().submitInsiderTip(for: locationId, tip: tipSubmission, token: token) { success in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    self.success = true
                    onSuccess()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    error = "Failed to submit tip. Please try again."
                }
            }
        }
    }
}

struct AddPhotoModal: View {
    let locationId: String
    let onSuccess: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var auth: AuthManager
    
    @State private var selectedImage: UIImage? = nil
    @State private var imagePickerPresented = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var caption: String = ""
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var success = false
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    private var isSubmitDisabled: Bool {
        isLoading || selectedImage == nil
    }
    
    private var submitButtonOpacity: Double {
        isSubmitDisabled ? 0.6 : 1.0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(primaryColor)
                        
                        Text("Add Community Photo")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Share a photo with the community")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Photo Selection
                    VStack(spacing: 16) {
                        if let image = selectedImage {
                            VStack(spacing: 12) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 250)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                
                                Button("Change Photo") {
                                    imagePickerPresented = true
                                }
                                .foregroundColor(primaryColor)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            }
                        } else {
                            VStack(spacing: 16) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .frame(height: 200)
                                    .overlay(
                                        VStack(spacing: 12) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                            Text("Select a photo")
                                                .font(.headline)
                                                .foregroundColor(.gray)
                                        }
                                    )
                                
                                HStack(spacing: 20) {
                                    Button(action: {
                                        imagePickerSource = .camera
                                        imagePickerPresented = true
                                    }) {
                                        HStack {
                                            Image(systemName: "camera")
                                            Text("Camera")
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(primaryColor)
                                        .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        imagePickerSource = .photoLibrary
                                        imagePickerPresented = true
                                    }) {
                                        HStack {
                                            Image(systemName: "photo.on.rectangle")
                                            Text("Library")
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(secondaryColor)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Caption
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption (Optional)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        TextField("Add a description to your photo", text: $caption)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    // Error/Success Messages
                    if let error = error {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                    }
                    
                    if success {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Photo submitted successfully!")
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                    }
                    
                    // Submit Button
                    Button(action: submitPhoto) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            Text(isLoading ? "Uploading..." : "Submit Photo")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(GradientBackground(primaryColor: primaryColor, secondaryColor: secondaryColor))
                        .cornerRadius(12)
                        .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isSubmitDisabled)
                    .opacity(submitButtonOpacity)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $imagePickerPresented) {
                ImagePicker(image: $selectedImage, sourceType: imagePickerSource)
            }
        }
    }
    
    func submitPhoto() {
        guard let image = selectedImage else { 
            error = "Please select a photo"
            return 
        }
        
        isLoading = true
        error = nil
        success = false
        
        // 1. Upload image to backend
        uploadImage(image: image) { result in
            switch result {
            case .success(let photoUrl):
                // 2. Submit photoUrl and caption to community-photos endpoint
                let urlString = "\(baseAPIURL)/api/mobile/locations/\(locationId)/community-photos"
                guard let url = URL(string: urlString) else {
                    error = "Invalid URL"
                    isLoading = false
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                if let token = auth.getValidToken() {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                
                let body: [String: Any] = [
                    "photoUrl": photoUrl,
                    "caption": caption.isEmpty ? nil : caption
                ].compactMapValues { $0 }
                
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                
                URLSession.shared.dataTask(with: request) { data, response, err in
                    DispatchQueue.main.async {
                        isLoading = false
                        
                        if let err = err {
                            error = err.localizedDescription
                            return
                        }
                        
                        guard let data = data else {
                            error = "No data received"
                            return
                        }
                        
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let successVal = json["success"] as? Bool, successVal {
                            success = true
                            onSuccess()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        } else {
                            let msg = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                            error = msg?["error"] as? String ?? "Unknown error"
                        }
                    }
                }.resume()
                
            case .failure(let uploadError):
                isLoading = false
                error = uploadError.localizedDescription
            }
        }
    }
    
    // Helper to upload image to backend and get URL
    func uploadImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            completion(.failure(NSError(domain: "Image conversion failed", code: 0)))
            return
        }
        
        let url = URL(string: "\(baseAPIURL)/api/mobile/upload/image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = auth.getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body = Data()
        
        // Add image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add locationId
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"locationId\"\r\n\r\n".data(using: .utf8)!)
        body.append(locationId.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add caption (optional)
        if !caption.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".data(using: .utf8)!)
            body.append(caption.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Add category (optional, default to 'other')
        let category = "other"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        body.append(category.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, err in
            if let err = err {
                completion(.failure(err))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let url = json["url"] as? String {
                completion(.success(url))
            } else {
                completion(.failure(NSError(domain: "Invalid response", code: 0)))
            }
        }.resume()
    }
}

// MARK: - Helper Views

struct GradientBackground: View {
    let primaryColor: Color
    let secondaryColor: Color
    
    var body: some View {
        LinearGradient(
            colors: [primaryColor, secondaryColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct StarButton: View {
    let star: Int
    @Binding var rating: Double
    
    private var isSelected: Bool {
        star <= Int(rating)
    }
    
    private var starColor: Color {
        isSelected ? .yellow : .gray
    }
    
    private var starIcon: String {
        isSelected ? "star.fill" : "star"
    }
    
    var body: some View {
        Button(action: {
            rating = Double(star)
        }) {
            Image(systemName: starIcon)
                .font(.title2)
                .foregroundColor(starColor)
        }
    }
}

struct TipTextEditor: View {
    @Binding var tip: String
    let category: String
    
    private var strokeColor: Color {
        category.isEmpty ? Color.clear : Color.orange
    }
    
    var body: some View {
        TextEditor(text: $tip)
            .frame(minHeight: 120)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(strokeColor, lineWidth: 2)
            )
    }
}

struct PriorityButton: View {
    let key: String
    @Binding var priority: String
    let priorities: [String: String]
    let primaryColor: Color
    let secondaryColor: Color
    
    private var isSelected: Bool {
        priority == key
    }
    
    private var textColor: Color {
        isSelected ? .white : .primary
    }
    
    var body: some View {
        Button(action: {
            priority = key
        }) {
            VStack(spacing: 4) {
                Text(priorities[key] ?? key)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .cornerRadius(8)
        }
    }
    
    private var backgroundColor: some View {
        Group {
            if priority == key {
                GradientBackground(primaryColor: primaryColor, secondaryColor: secondaryColor)
            } else {
                Color(.systemGray5)
            }
        }
    }
}