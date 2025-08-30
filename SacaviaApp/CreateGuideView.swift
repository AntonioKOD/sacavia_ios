import SwiftUI

struct CreateGuideView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var description = ""
    @State private var content = ""
    @State private var categories = ""
    @State private var price = ""
    @State private var isPublic = true
    @State private var isLoading = false
    @State private var error: String?
    @State private var success = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Guide Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    TextField("Content", text: $content)
                    TextField("Categories (comma separated)", text: $categories)
                    TextField("Price (optional)", text: $price)
                        .keyboardType(.decimalPad)
                    Toggle("Public", isOn: $isPublic)
                }
                if let error = error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                if isLoading {
                    Section {
                        ProgressView("Creating guide...")
                    }
                }
                if success {
                    Section {
                        Text("Guide created successfully!")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Create Guide")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { submit() }
                        .disabled(!isFormValid || isLoading || success)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty && !content.isEmpty
    }
    
    private func submit() {
        guard isFormValid else { return }
        isLoading = true
        error = nil
        let url = URL(string: "\(baseAPIURL)/api/mobile/guides")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let cats = categories.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let body: [String: Any] = [
            "title": title,
            "description": description,
            "content": content,
            "categories": cats,
            "price": Double(price) ?? 0,
            "isPublic": isPublic
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, err in
            DispatchQueue.main.async {
                isLoading = false
                if let err = err {
                    self.error = err.localizedDescription
                    return
                }
                guard let data = data else {
                    self.error = "No data received"
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(CreateGuideResponse.self, from: data)
                    if decoded.success {
                        self.success = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                        self.error = decoded.error ?? "Unknown error"
                    }
                } catch {
                    self.error = error.localizedDescription
                }
            }
        }.resume()
    }
}

struct CreateGuideResponse: Decodable {
    let success: Bool
    let error: String?
}

struct CreateGuideView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGuideView()
    }
} 