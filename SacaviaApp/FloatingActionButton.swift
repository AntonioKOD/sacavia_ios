import SwiftUI

struct FloatingActionButton: View {
    @State private var isOpen = false
    @State private var showAddLocation = false
    @State private var showCreateEvent = false
    @State private var showPlanner = false
    @State private var showSaved = false
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    let warmYellow = Color(red: 255/255, green: 230/255, blue: 109/255) // #FFE66D
    let whisperGray = Color(red: 243/255, green: 244/255, blue: 246/255) // #F3F4F6
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dimmed background when open
                if isOpen {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture { 
                            withAnimation(.spring()) { 
                                isOpen = false 
                            } 
                        }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack(alignment: .bottomTrailing) {
                            // Menu buttons - positioned closer to the main button
                            if isOpen {
                                VStack(alignment: .trailing, spacing: 16) {
                                    // Create Event - closest to main button
                                    FloatingMenuButton(
                                        label: "Create Event", 
                                        icon: "calendar.badge.plus", 
                                        color: primaryColor
                                    ) {
                                        showCreateEvent = true
                                        isOpen = false
                                    }
                                    
                                    // Add Location
                                    FloatingMenuButton(
                                        label: "Add Location", 
                                        icon: "mappin.and.ellipse", 
                                        color: secondaryColor
                                    ) {
                                        showAddLocation = true
                                        isOpen = false
                                    }
                                    
                                    // Gem Agent
                                    FloatingMenuButton(
                                        label: "Gem Agent", 
                                        icon: "sparkles", 
                                        color: warmYellow
                                    ) {
                                        showPlanner = true
                                        isOpen = false
                                    }
                                    
                                    // Saved - furthest from main button
                                    FloatingMenuButton(
                                        label: "Saved", 
                                        icon: "bookmark.fill", 
                                        color: primaryColor.opacity(0.8)
                                    ) {
                                        showSaved = true
                                        isOpen = false
                                    }
                                }
                                                            .padding(.trailing, 20)
                            .padding(.bottom, 180) // Positioned above main FAB with proper spacing
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                                    removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.8))
                                ))
                            }
                            
                            // Main FAB with improved design
                            Button(action: { 
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { 
                                    isOpen.toggle() 
                                } 
                            }) {
                                Image(systemName: isOpen ? "xmark" : "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: primaryColor.opacity(0.3), radius: 12, x: 0, y: 6)
                                    .scaleEffect(isOpen ? 1.1 : 1.0)
                                    .rotationEffect(.degrees(isOpen ? 90 : 0))
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 88) // Just above bottom bar with minimal spacing
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isOpen)
        .fullScreenCover(isPresented: $showSaved) {
            SavedView()
        }
        .fullScreenCover(isPresented: $showPlanner) {
            PlannerView()
        }
        .fullScreenCover(isPresented: $showAddLocation) {
            AddLocationView()
        }
        .fullScreenCover(isPresented: $showCreateEvent) {
            CreateEventView()
        }
    }
}

struct FloatingMenuButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 3)
            )
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
            removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.9))
        ))
    }
}

struct FloatingActionButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
            
            FloatingActionButton()
        }
    }
} 