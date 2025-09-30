import SwiftUI

struct TestConnectionView: View {
    @StateObject private var apiService = APIService()
    @State private var testResult: String = "Testing connection..."
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text("API Connection Test")
                .font(.title)
                .fontWeight(.bold)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                Text(testResult)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: testResult.contains("Success") ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(testResult.contains("Success") ? .green : .red)
                
                Text(testResult)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Test Again") {
                    testConnection()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            testConnection()
        }
    }
    
    private func testConnection() {
        isLoading = true
        testResult = "Testing connection..."
        
        Task {
            do {
                let success = try await apiService.testConnection()
                await MainActor.run {
                    isLoading = false
                    if success {
                        testResult = "Success! Connected to \(baseAPIURL) API"
                    } else {
                        testResult = "Connection failed - API returned false"
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    testResult = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    TestConnectionView()
} 