import SwiftUI
import Foundation

class CrashHandler: ObservableObject {
    @Published var hasCrashed = false
    @Published var crashMessage: String?
    
    static let shared = CrashHandler()
    
    private init() {
        setupCrashHandling()
    }
    
    private func setupCrashHandling() {
        // Set up uncaught exception handler
        NSSetUncaughtExceptionHandler { exception in
            print("🚨 [CrashHandler] Uncaught exception: \(exception)")
            DispatchQueue.main.async {
                CrashHandler.shared.hasCrashed = true
                CrashHandler.shared.crashMessage = "Unexpected error occurred"
            }
        }
        
        // Set up signal handlers for common crashes
        signal(SIGABRT) { _ in
            print("🚨 [CrashHandler] SIGABRT received")
            DispatchQueue.main.async {
                CrashHandler.shared.hasCrashed = true
                CrashHandler.shared.crashMessage = "Application was terminated"
            }
        }
        
        signal(SIGILL) { _ in
            print("🚨 [CrashHandler] SIGILL received")
            DispatchQueue.main.async {
                CrashHandler.shared.hasCrashed = true
                CrashHandler.shared.crashMessage = "Illegal instruction"
            }
        }
        
        signal(SIGSEGV) { _ in
            print("🚨 [CrashHandler] SIGSEGV received")
            DispatchQueue.main.async {
                CrashHandler.shared.hasCrashed = true
                CrashHandler.shared.crashMessage = "Segmentation fault"
            }
        }
        
        signal(SIGFPE) { _ in
            print("🚨 [CrashHandler] SIGFPE received")
            DispatchQueue.main.async {
                CrashHandler.shared.hasCrashed = true
                CrashHandler.shared.crashMessage = "Floating point exception"
            }
        }
        
        signal(SIGBUS) { _ in
            print("🚨 [CrashHandler] SIGBUS received")
            DispatchQueue.main.async {
                CrashHandler.shared.hasCrashed = true
                CrashHandler.shared.crashMessage = "Bus error"
            }
        }
        
        signal(SIGPIPE) { _ in
            print("🚨 [CrashHandler] SIGPIPE received")
            DispatchQueue.main.async {
                CrashHandler.shared.hasCrashed = true
                CrashHandler.shared.crashMessage = "Broken pipe"
            }
        }
    }
    
    func handleError(_ error: Error) {
        print("🚨 [CrashHandler] Error caught: \(error)")
        DispatchQueue.main.async {
            self.hasCrashed = true
            self.crashMessage = error.localizedDescription
        }
    }
    
    func reset() {
        hasCrashed = false
        crashMessage = nil
    }
    
    func simulateCrash() {
        // For testing purposes only
        hasCrashed = true
        crashMessage = "Simulated crash for testing"
    }
}

// Extension to handle Swift errors gracefully
extension CrashHandler {
    func handleSwiftError<T>(_ result: Result<T, Error>, fallback: T) -> T {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            handleError(error)
            return fallback
        }
    }
}

// Global error handler for async operations
func handleAsyncError(_ error: Error) {
    CrashHandler.shared.handleError(error)
}
