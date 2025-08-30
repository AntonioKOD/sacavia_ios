import Foundation

// MARK: - API Configuration
// Production: Use https://sacavia.com for production

// ===== ENVIRONMENT CONFIGURATION =====
// Set this to true for development (localhost:3000), false for production (sacavia.com)
let isDevelopment = false

// Base API URL - automatically set based on environment
let baseAPIURL = isDevelopment ? "http://localhost:3000" : "https://sacavia.com"

// ===== END CONFIGURATION =====

// Function to log API configuration (call this from app startup)
func logAPIConfiguration() {
    #if DEBUG
    print("🌐 [Utils] API Configuration:")
    print("🌐 [Utils] Environment: \(isDevelopment ? "Development" : "Production")")
    print("🌐 [Utils] Base URL: \(baseAPIURL)")
    #endif
}

func absoluteMediaURL(_ url: String) -> URL? {
    guard !url.isEmpty else { return nil }
    
    var processedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // If it's already a full URL, return it
    if processedUrl.hasPrefix("http") {
        // Fix common domain issues
        if processedUrl.contains("www.sacavia.com") {
            processedUrl = processedUrl.replacingOccurrences(of: "www.sacavia.com", with: "sacavia.com")
        }
        return URL(string: processedUrl)
    }
    
    // If it's a relative URL, add the base URL
    if processedUrl.hasPrefix("/") {
        // Ensure proper API endpoint for media files
        if processedUrl.contains("/api/media/") && !processedUrl.contains("/api/media/file/") {
            processedUrl = processedUrl.replacingOccurrences(of: "/api/media/", with: "/api/media/file/")
        }
        
        return URL(string: "\(baseAPIURL)\(processedUrl)")
    }
    
    // If it's just a filename or ID, construct the full URL
    if !processedUrl.contains("/") {
        return URL(string: "\(baseAPIURL)/api/media/file/\(processedUrl)")
    }
    
    // Fallback: add base URL
    return URL(string: "\(baseAPIURL)\(processedUrl)")
}

func getInitials(_ name: String) -> String {
    let components = name.components(separatedBy: " ")
    if components.count >= 2 {
        let first = components[0].prefix(1).uppercased()
        let last = components[1].prefix(1).uppercased()
        return "\(first)\(last)"
    } else if components.count == 1 {
        return components[0].prefix(2).uppercased()
    } else {
        return "U"
    }
} 