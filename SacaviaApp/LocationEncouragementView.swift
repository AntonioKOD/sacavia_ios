import SwiftUI

// MARK: - Location Encouragement View
struct LocationEncouragementView: View {
    let variant: EncouragementVariant
    let onAddLocation: () -> Void
    let onAddBusiness: () -> Void
    
    enum EncouragementVariant {
        case `default`
        case business
        case community
        case compact
    }
    
    init(variant: EncouragementVariant = .default, onAddLocation: @escaping () -> Void, onAddBusiness: @escaping () -> Void) {
        self.variant = variant
        self.onAddLocation = onAddLocation
        self.onAddBusiness = onAddBusiness
    }
    
    var body: some View {
        switch variant {
        case .default:
            DefaultEncouragementView(onAddLocation: onAddLocation, onAddBusiness: onAddBusiness)
        case .business:
            BusinessEncouragementView(onAddBusiness: onAddBusiness)
        case .community:
            CommunityEncouragementView(onAddLocation: onAddLocation)
        case .compact:
            CompactEncouragementView(onAddLocation: onAddLocation)
        }
    }
}

// MARK: - Default Encouragement View
struct DefaultEncouragementView: View {
    let onAddLocation: () -> Void
    let onAddBusiness: () -> Void
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    let accentColor = Color(red: 69/255, green: 183/255, blue: 209/255) // #45B7D1
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card
            VStack(spacing: 20) {
                // Header with icon
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Help Build Our Community")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundColor(.yellow)
                                .opacity(0.8)
                        }
                        
                        Text("Share amazing places you've discovered")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Description
                Text("Every location you add helps others discover hidden gems and amazing experiences. Whether it's a cozy café, scenic viewpoint, or local favorite, your contribution makes our community richer.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                
                // Business owner message
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        
                        Text("Business owners:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                    
                    Text("Get discovered by travelers and locals. Connect with people who value authentic, community-driven recommendations.")
                        .font(.system(size: 12))
                        .foregroundColor(.blue.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(1)
                    
                    Button(action: onAddBusiness) {
                        HStack(spacing: 4) {
                            Text("Add your business")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Stats
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                        Text("Community-driven")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.3")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text("Growing network")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // CTA Button
                Button(action: onAddLocation) {
                    HStack(spacing: 8) {
                        Text("Add a Location")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Business Encouragement View
struct BusinessEncouragementView: View {
    let onAddBusiness: () -> Void
    
    let primaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    let secondaryColor = Color(red: 69/255, green: 183/255, blue: 209/255) // #45B7D1
    let accentColor = Color(red: 150/255, green: 206/255, blue: 180/255) // #96CEB4
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "building.2")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("Are You a Business Owner?")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                        .opacity(0.8)
                }
                
                Text("Join our growing network")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("Connect with travelers and locals who are actively seeking amazing experiences. Get discovered by people who value authentic, community-driven recommendations.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            // CTA Button
            Button(action: onAddBusiness) {
                HStack(spacing: 8) {
                    Text("Add Your Business")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 16)
    }
}

// MARK: - Community Encouragement View
struct CommunityEncouragementView: View {
    let onAddLocation: () -> Void
    
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 255/255, green: 230/255, blue: 109/255) // #FFE66D
    let accentColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "person.3")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("Grow Our Local Network")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                        .opacity(0.8)
                }
                
                Text("Every location matters")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("From hidden gems to popular spots, every location you add helps create a comprehensive guide for your community. Let's build something amazing together.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            // CTA Button
            Button(action: onAddLocation) {
                HStack(spacing: 8) {
                    Text("Contribute Now")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 16)
    }
}

// MARK: - Compact Encouragement View
struct CompactEncouragementView: View {
    let onAddLocation: () -> Void
    
    let primaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 16))
                    .foregroundColor(primaryColor)
                
                Text("Help grow our community")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text("Add locations to help others discover amazing places. Business owners welcome!")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(1)
            
            Button(action: onAddLocation) {
                Text("Add Location")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(primaryColor)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .foregroundColor(primaryColor.opacity(0.3))
                )
        )
        .padding(.horizontal, 16)
    }
}
