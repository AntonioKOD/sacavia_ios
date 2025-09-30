import SwiftUI

struct CrashErrorView: View {
    @State private var isAnimating = false
    @State private var showDetails = false
    let onRetry: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 255/255, green: 107/255, blue: 107/255).opacity(0.1),
                    Color(red: 78/255, green: 205/255, blue: 196/255).opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Animated icon
                ZStack {
                    Circle()
                        .fill(Color(red: 255/255, green: 107/255, blue: 107/255).opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color(red: 255/255, green: 107/255, blue: 107/255))
                        .rotationEffect(.degrees(isAnimating ? 5 : -5))
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                }
                
                // Main content
                VStack(spacing: 20) {
                    Text("Oops! We're just getting started")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("We didn't expect so many amazing people to discover Sacavia at once! Our little team is working hard to keep up with all the love.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.horizontal, 20)
                    
                    // Fun details section
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(Color(red: 78/255, green: 205/255, blue: 196/255))
                            Text("Just a few developers trying to figure it out")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(Color(red: 255/255, green: 107/255, blue: 107/255))
                            Text("We're grateful for your patience")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: onRetry) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                            Text("Try Again")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(red: 78/255, green: 205/255, blue: 196/255))
                        .cornerRadius(25)
                    }
                    
                    Button(action: { showDetails.toggle() }) {
                        Text(showDetails ? "Hide Details" : "What happened?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 78/255, green: 205/255, blue: 196/255))
                    }
                }
                
                // Technical details (expandable)
                if showDetails {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Technical Details:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("• The app encountered an unexpected error\n• Our servers are working overtime\n• We're scaling up to handle the demand\n• Your data is safe and secure")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .transition(.opacity.combined(with: .scale))
                }
                
                Spacer()
                
                // Footer message
                VStack(spacing: 4) {
                    Text("Thanks for being part of our journey! 🚀")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("The Sacavia Team")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct CrashErrorView_Previews: PreviewProvider {
    static var previews: some View {
        CrashErrorView {
            print("Retry tapped")
        }
    }
}
