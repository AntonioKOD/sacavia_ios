import SwiftUI

struct PrivacySelector: View {
    @Binding var privacy: String
    @Binding var privateAccess: [String]
    let userId: String
    let onPrivacyChange: (String, [String]) -> Void
    
    @State private var isUpdating = false
    @State private var showFollowerSelector = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.42)) // #FF6B6B
                Text("Privacy Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            // Privacy Options
            VStack(spacing: 12) {
                // Public Option
                Button(action: {
                    handlePrivacyChange("public")
                }) {
                    HStack(spacing: 12) {
                        // Radio Button
                        ZStack {
                            Circle()
                                .stroke(privacy == "public" ? Color(red: 1.0, green: 0.42, blue: 0.42) : Color.gray, lineWidth: 2)
                                .frame(width: 20, height: 20)
                            
                            if privacy == "public" {
                                Circle()
                                    .fill(Color(red: 1.0, green: 0.42, blue: 0.42))
                                    .frame(width: 12, height: 12)
                            }
                        }
                        
                        // Icon and Content
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "globe")
                                    .foregroundColor(.green)
                                    .font(.system(size: 18, weight: .medium))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Public Location")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    if privacy == "public" {
                                        Text("PUBLIC")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                                
                                Text("Visible to everyone on the platform")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(privacy == "public" ? Color(red: 1.0, green: 0.42, blue: 0.42).opacity(0.05) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(privacy == "public" ? Color(red: 1.0, green: 0.42, blue: 0.42) : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Private Option
                Button(action: {
                    handlePrivacyChange("private")
                }) {
                    HStack(spacing: 12) {
                        // Radio Button
                        ZStack {
                            Circle()
                                .stroke(privacy == "private" ? Color(red: 1.0, green: 0.42, blue: 0.42) : Color.gray, lineWidth: 2)
                                .frame(width: 20, height: 20)
                            
                            if privacy == "private" {
                                Circle()
                                    .fill(Color(red: 1.0, green: 0.42, blue: 0.42))
                                    .frame(width: 12, height: 12)
                            }
                        }
                        
                        // Icon and Content
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 18, weight: .medium))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Private Location")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    if privacy == "private" {
                                        Text("PRIVATE")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                                
                                Text("Only selected friends can see this location")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(privacy == "private" ? Color(red: 1.0, green: 0.42, blue: 0.42).opacity(0.05) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(privacy == "private" ? Color(red: 1.0, green: 0.42, blue: 0.42) : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Private Access Section
            if privacy == "private" {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.vertical, 8)
                    
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.orange)
                        Text("Select Friends")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    if privateAccess.isEmpty {
                        VStack(spacing: 12) {
                            Text("No friends selected")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showFollowerSelector = true
                            }) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Select Friends")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.42))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(red: 1.0, green: 0.42, blue: 0.42).opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                )
                        )
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(privateAccess.count) friend\(privateAccess.count == 1 ? "" : "s") selected")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.orange)
                            
                            Button(action: {
                                showFollowerSelector = true
                            }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Manage Friends")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.42))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(red: 1.0, green: 0.42, blue: 0.42).opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.05))
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showFollowerSelector) {
            FollowerSelector(
                selectedFollowers: $privateAccess,
                userId: userId,
                onSelectionChange: { newSelection in
                    privateAccess = newSelection
                }
            )
        }
    }
    
    private func handlePrivacyChange(_ newPrivacy: String) {
        privacy = newPrivacy
        
        if newPrivacy == "public" {
            // Clear private access when switching to public
            privateAccess = []
        } else if newPrivacy == "private" && privateAccess.isEmpty {
            // Show follower selector when switching to private with no access set
            showFollowerSelector = true
        }
        
        // Notify parent of changes
        onPrivacyChange(privacy, privateAccess)
    }
}

// MARK: - Preview
struct PrivacySelector_Previews: PreviewProvider {
    @State static var privacy = "public"
    @State static var privateAccess: [String] = []
    
    static var previews: some View {
        VStack {
            PrivacySelector(
                privacy: $privacy,
                privateAccess: $privateAccess,
                userId: "test-user",
                onPrivacyChange: { newPrivacy, newAccess in
                    print("Privacy changed to: \(newPrivacy), Access: \(newAccess)")
                }
            )
            .padding()
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}










