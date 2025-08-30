import SwiftUI

struct Guide: Identifiable, Decodable {
    let id: String
    let title: String
    let description: String?
    let createdAt: String?
}

struct BrowseGuidesView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var guides: [Guide] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showMoreOptions = false
    @State private var showReportContent = false
    @State private var selectedGuide: Guide?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading guides...")
                } else if let error = error {
                    VStack(spacing: 16) {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                        Button("Retry") { fetchGuides() }
                    }
                } else if guides.isEmpty {
                    Text("No guides found.")
                        .foregroundColor(.secondary)
                } else {
                    List(guides) { guide in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(guide.title)
                                    .font(.headline)
                                if let desc = guide.description, !desc.isEmpty {
                                    Text(desc)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                selectedGuide = guide
                                showMoreOptions = true
                            }) {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.secondary)
                                    .padding(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Browse Guides")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .confirmationDialog("More Options", isPresented: $showMoreOptions) {
                Button("Report Guide", role: .destructive) {
                    showReportContent = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showReportContent) {
                if let guide = selectedGuide {
                    ReportContentView(
                        contentType: "guide",
                        contentId: guide.id,
                        contentTitle: guide.title
                    )
                }
            }
        }
        .onAppear(perform: fetchGuides)
    }
    
    private func fetchGuides() {
        isLoading = true
        error = nil
        let url = URL(string: "\(baseAPIURL)/api/mobile/guides")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Add auth headers if needed
        URLSession.shared.dataTask(with: request) { data, response, err in
            DispatchQueue.main.async {
                if let err = err {
                    self.error = err.localizedDescription
                    self.isLoading = false
                    return
                }
                guard let data = data else {
                    self.error = "No data received"
                    self.isLoading = false
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(GuidesResponse.self, from: data)
                    self.guides = decoded.guides
                    self.isLoading = false
                } catch {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }.resume()
    }
}

struct GuidesResponse: Decodable {
    let guides: [Guide]
}

struct BrowseGuidesView_Previews: PreviewProvider {
    static var previews: some View {
        BrowseGuidesView()
    }
} 