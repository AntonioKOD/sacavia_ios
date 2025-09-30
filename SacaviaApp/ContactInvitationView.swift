import SwiftUI
import Contacts
import ContactsUI

struct ContactInvitationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var contactManager = ContactManager.shared
    
    // UI State
    @State private var selectedContacts: Set<CNContact> = []
    @State private var isShowingContactPicker = false
    @State private var isSendingInvitations = false
    @State private var showSuccessMessage = false
    @State private var invitationResult: InvitationResult?
    @State private var customMessage = ""
    @State private var showCustomMessage = false
    
    // Colors
    private let primaryColor = Color(red: 0.0, green: 0.5, blue: 1.0)
    private let secondaryColor = Color(red: 0.0, green: 0.8, blue: 0.6)
    private let backgroundColor = Color(red: 0.95, green: 0.95, blue: 0.95)
    private let cardBackgroundColor = Color.white
    private let mutedTextColor = Color.gray
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Content
                    if contactManager.contacts.isEmpty {
                        emptyStateView
                    } else {
                        contactsListView
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $isShowingContactPicker) {
            ContactPickerView(selectedContacts: $selectedContacts)
        }
        .alert("Invitations Sent!", isPresented: $showSuccessMessage) {
            Button("OK") {
                dismiss()
            }
        } message: {
            if let result = invitationResult {
                Text("Successfully invited \(result.invited) friends! \(result.alreadyUsers) were already users, and \(result.alreadyInvited) were already invited.")
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(primaryColor)
                
                Spacer()
                
                Text("Invite Friends")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !selectedContacts.isEmpty {
                    Button("Send") {
                        sendInvitations()
                    }
                    .foregroundColor(primaryColor)
                    .fontWeight(.semibold)
                } else {
                    Text("Send")
                        .foregroundColor(mutedTextColor)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Stats
            if !contactManager.contacts.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(contactManager.contacts.count) contacts found")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        Text("Select friends to invite")
                            .font(.system(size: 12))
                            .foregroundColor(mutedTextColor)
                    }
                    
                    Spacer()
                    
                    if !selectedContacts.isEmpty {
                        Text("\(selectedContacts.count) selected")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(primaryColor)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 16)
        .background(cardBackgroundColor)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [primaryColor.opacity(0.1), secondaryColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(primaryColor)
                }
                
                VStack(spacing: 8) {
                    Text("No Contacts Found")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("We couldn't find any contacts on your device. Make sure you've granted permission to access your contacts.")
                        .font(.system(size: 14))
                        .foregroundColor(mutedTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .padding(24)
            .background(cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            
            Button("Grant Permission") {
                requestContactPermission()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: primaryColor.opacity(0.25), radius: 4, x: 0, y: 2)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Contacts List
    private var contactsListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(contactManager.contacts, id: \.identifier) { contact in
                    ContactRowView(
                        contact: contact,
                        isSelected: selectedContacts.contains(contact),
                        onToggle: {
                            toggleContactSelection(contact)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Helper Methods
    private func toggleContactSelection(_ contact: CNContact) {
        if selectedContacts.contains(contact) {
            selectedContacts.remove(contact)
        } else {
            selectedContacts.insert(contact)
        }
    }
    
    private func requestContactPermission() {
        contactManager.requestPermission { granted in
            if granted {
                contactManager.fetchContacts()
            }
        }
    }
    
    private func sendInvitations() {
        guard !selectedContacts.isEmpty else { return }
        
        isSendingInvitations = true
        
        let contacts = selectedContacts.map { contact in
            ContactInvitation(
                name: CNContactFormatter.string(from: contact, style: .fullName),
                email: contact.emailAddresses.first?.value as String?,
                phone: contact.phoneNumbers.first?.value.stringValue,
                message: customMessage.isEmpty ? nil : customMessage
            )
        }
        
        Task {
            do {
                let result = try await InvitationAPI.sendInvitations(contacts: contacts)
                await MainActor.run {
                    self.invitationResult = result
                    self.isSendingInvitations = false
                    self.showSuccessMessage = true
                }
            } catch {
                await MainActor.run {
                    self.isSendingInvitations = false
                    // Handle error
                }
            }
        }
    }
}

// MARK: - Contact Row View
struct ContactRowView: View {
    let contact: CNContact
    let isSelected: Bool
    let onToggle: () -> Void
    
    private let primaryColor = Color(red: 0.0, green: 0.5, blue: 1.0)
    private let secondaryColor = Color(red: 0.0, green: 0.8, blue: 0.6)
    private let mutedTextColor = Color.gray
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [primaryColor.opacity(0.1), secondaryColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 48, height: 48)
                    
                    if let imageData = contact.imageData,
                       let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Text(contactInitials)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(primaryColor)
                    }
                }
                
                // Contact Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(contactName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let email = contact.emailAddresses.first?.value as String? {
                        Text(email)
                            .font(.system(size: 14))
                            .foregroundColor(mutedTextColor)
                            .lineLimit(1)
                    } else if let phone = contact.phoneNumbers.first?.value.stringValue {
                        Text(phone)
                            .font(.system(size: 14))
                            .foregroundColor(mutedTextColor)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? primaryColor : mutedTextColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(primaryColor)
                            .frame(width: 16, height: 16)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? primaryColor.opacity(0.3) : Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var contactName: String {
        CNContactFormatter.string(from: contact, style: .fullName) ?? "Unknown"
    }
    
    private var contactInitials: String {
        let firstName = contact.givenName
        let lastName = contact.familyName
        
        let firstInitial = firstName.isEmpty ? "" : String(firstName.prefix(1))
        let lastInitial = lastName.isEmpty ? "" : String(lastName.prefix(1))
        
        return (firstInitial + lastInitial).uppercased()
    }
}

// MARK: - Contact Picker View
struct ContactPickerView: UIViewControllerRepresentable {
    @Binding var selectedContacts: Set<CNContact>
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0 OR phoneNumbers.@count > 0")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerView
        
        init(_ parent: ContactPickerView) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            parent.selectedContacts = Set(contacts)
            parent.dismiss()
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - Contact Manager
class ContactManager: ObservableObject {
    static let shared = ContactManager()
    
    @Published var contacts: [CNContact] = []
    @Published var permissionStatus: CNAuthorizationStatus = .notDetermined
    
    private let contactStore = CNContactStore()
    
    private init() {
        permissionStatus = CNContactStore.authorizationStatus(for: .contacts)
        if permissionStatus == .authorized {
            fetchContacts()
        }
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        contactStore.requestAccess(for: .contacts) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.permissionStatus = CNContactStore.authorizationStatus(for: .contacts)
                if granted {
                    self?.fetchContacts()
                }
                completion(granted)
            }
        }
    }
    
    func fetchContacts() {
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey,
            CNContactImageDataKey
        ] as [CNKeyDescriptor]
        
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        var fetchedContacts: [CNContact] = []
        
        do {
            try contactStore.enumerateContacts(with: request) { contact, _ in
                // Only include contacts with email or phone
                if !contact.emailAddresses.isEmpty || !contact.phoneNumbers.isEmpty {
                    fetchedContacts.append(contact)
                }
            }
        } catch {
            print("Error fetching contacts: \(error)")
        }
        
        DispatchQueue.main.async {
            self.contacts = fetchedContacts.sorted { contact1, contact2 in
                let name1 = CNContactFormatter.string(from: contact1, style: .fullName) ?? ""
                let name2 = CNContactFormatter.string(from: contact2, style: .fullName) ?? ""
                return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
            }
        }
    }
}

// MARK: - Models
struct ContactInvitation: Codable {
    let name: String?
    let email: String?
    let phone: String?
    let message: String?
}

struct InvitationResult: Codable {
    let invited: Int
    let alreadyUsers: Int
    let alreadyInvited: Int
    let errors: [String]
}

// MARK: - Invitation API
class InvitationAPI {
    static func sendInvitations(contacts: [ContactInvitation]) async throws -> InvitationResult {
        guard let token = AuthManager.shared.token else {
            throw InvitationAPIError.unauthorized
        }
        
        let url = URL(string: "\(baseAPIURL)/api/mobile/invitations/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["contacts": contacts]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw InvitationAPIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let responseData = try JSONDecoder().decode(InvitationResponse.self, from: data)
            return responseData.result
        } else {
            let errorData = try JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw InvitationAPIError.serverError(errorData.error)
        }
    }
}

struct InvitationResponse: Codable {
    let success: Bool
    let result: InvitationResult
}

struct APIErrorResponse: Codable {
    let error: String
}

enum InvitationAPIError: Error {
    case unauthorized
    case invalidResponse
    case serverError(String)
}
