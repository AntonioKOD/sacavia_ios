import SwiftUI

struct BottomTabBar: View {
    enum Tab {
        case feed, map, create, events, profile
    }
    
    @Binding var selectedTab: Tab
    var onCreatePost: () -> Void
    
    // Modern minimalistic brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    let backgroundColor = Color(red: 249/255, green: 250/255, blue: 251/255) // #F9FAFB
    let mutedTextColor = Color(red: 107/255, green: 114/255, blue: 128/255) // #6B7280
    let borderColor = Color(red: 229/255, green: 231/255, blue: 235/255) // #E5E7EB
    
    var body: some View {
        HStack(spacing: 0) {
            tabButton(tab: .feed, icon: "house", label: "Feed")
            tabButton(tab: .map, icon: "map", label: "Map")
            
            // Create Post Button (Center) - Modern clean design
            Button(action: onCreatePost) {
                ZStack {
                    // Clean circular background
                    Circle()
                        .fill(primaryColor)
                        .frame(width: 52, height: 52)
                        .shadow(color: primaryColor.opacity(0.25), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                .offset(y: -16)
            }
            .frame(maxWidth: .infinity)
            
            tabButton(tab: .events, icon: "calendar", label: "Events")
            tabButton(tab: .profile, icon: "person", label: "Profile")
        }
        .frame(height: 56) // Reduced from 72 to 56
        .padding(.horizontal, 12) // Reduced from 16 to 12
        .padding(.bottom, 16) // Reduced from 24 to 16
        .padding(.top, 8) // Reduced from 12 to 8
        .background(
            // Modern glass background effect inspired by VisionOS - smaller radius
            RoundedRectangle(cornerRadius: 20) // Reduced from 28 to 20
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20) // Reduced from 28 to 20
                        .fill(Color.white)
                        .opacity(0.9)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20) // Reduced from 28 to 20
                        .stroke(borderColor.opacity(0.3), lineWidth: 0.5)
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: -8)
        .shadow(color: primaryColor.opacity(0.1), radius: 30, x: 0, y: -5)
    }
    
    // Helper function to get the correct filled icon for each tab
    private func getSelectedIcon(for icon: String) -> String {
        switch icon {
        case "house":
            return "house.fill"
        case "map":
            return "map.fill" 
        case "calendar":
            return "calendar" // Keep same icon, rely on styling for selection state
        case "person":
            return "person.fill"
        default:
            return "\(icon).fill"
        }
    }
    
    private func tabButton(tab: Tab, icon: String, label: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                // Enhanced icon with background indicator
                ZStack {
                    if selectedTab == tab {
                        Circle()
                            .fill(primaryColor.opacity(0.1))
                            .frame(width: 30, height: 30) // Reduced from 36 to 30
                            .scaleEffect(1.0)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Image(systemName: selectedTab == tab ? getSelectedIcon(for: icon) : icon)
                        .font(.system(size: 18, weight: selectedTab == tab ? .bold : .medium)) // Reduced from 20 to 18
                        .foregroundColor(selectedTab == tab ? primaryColor : mutedTextColor)
                        .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                }
                .frame(height: 30) // Reduced from 36 to 30
                
                Text(label)
                    .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .medium))
                    .foregroundColor(selectedTab == tab ? primaryColor : mutedTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4) // Reduced from 8 to 4
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
    }
}

struct BottomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            BottomTabBar(selectedTab: .constant(.feed)) {
                print("Create post tapped")
            }
        }
        .background(Color.gray.opacity(0.1))
    }
} 