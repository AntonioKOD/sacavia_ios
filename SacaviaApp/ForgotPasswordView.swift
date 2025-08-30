import SwiftUI
import WebKit

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Brand colors from globals.css
    private let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    private let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    private let backgroundColor = Color(red: 243/255, green: 244/255, blue: 246/255) // #F3F4F6
    private let textColor = Color(red: 51/255, green: 51/255, blue: 51/255) // #333333
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Navigation Bar
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(primaryColor)
                        }
                        
                        Spacer()
                        
                        Text("Forgot Password")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        // Invisible spacer to center the title
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .opacity(0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                    
                    // WebView Container
                    ZStack {
                        // Loading indicator
                        if isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .progressViewStyle(CircularProgressViewStyle(tint: primaryColor))
                                
                                Text("Loading...")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(textColor.opacity(0.7))
                            }
                        }
                        
                        // Error state
                        if showError {
                            VStack(spacing: 20) {
                                Image(systemName: "wifi.slash")
                                    .font(.system(size: 48))
                                    .foregroundColor(textColor.opacity(0.5))
                                
                                Text("Connection Error")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(textColor)
                                
                                Text(errorMessage)
                                    .font(.system(size: 16))
                                    .foregroundColor(textColor.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                
                                Button(action: {
                                    showError = false
                                    isLoading = true
                                    // Reload the webview
                                }) {
                                    Text("Try Again")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(primaryColor)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, 32)
                            }
                        }
                        
                        // WebView
                        if !showError {
                            ForgotPasswordWebView(
                                url: URL(string: "\(baseAPIURL)/forgot-password/webview")!,
                                isLoading: $isLoading,
                                showError: $showError,
                                errorMessage: $errorMessage
                            )
                            .opacity(isLoading ? 0 : 1)
                            .animation(.easeInOut(duration: 0.3), value: isLoading)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// WebView wrapper using WKWebView
struct ForgotPasswordWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = false
        
        // Load the URL
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Updates handled by navigation delegate
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ForgotPasswordWebView
        
        init(_ parent: ForgotPasswordWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.showError = false
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.showError = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.showError = true
            parent.errorMessage = "Unable to load the forgot password page. Please check your internet connection and try again."
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.showError = true
            parent.errorMessage = "Unable to load the forgot password page. Please check your internet connection and try again."
        }
    }
}

#Preview {
    ForgotPasswordView()
} 