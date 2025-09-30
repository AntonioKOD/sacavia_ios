import Foundation
import SwiftUI

// MARK: - Mention Parser
class MentionParser: ObservableObject {
    static let shared = MentionParser()
    
    private let mentionPattern = "@([a-zA-Z0-9_]+)"
    private let mentionRegex: NSRegularExpression
    
    private init() {
        do {
            mentionRegex = try NSRegularExpression(pattern: mentionPattern, options: [])
        } catch {
            fatalError("Failed to create mention regex: \(error)")
        }
    }
    
    // MARK: - Parse Mentions
    func parseMentions(from text: String) -> [Mention] {
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = mentionRegex.matches(in: text, options: [], range: range)
        
        return matches.compactMap { match in
            guard match.numberOfRanges >= 2,
                  let usernameRange = Range(match.range(at: 1), in: text) else {
                return nil
            }
            
            let username = String(text[usernameRange])
            let fullRange = Range(match.range, in: text)!
            let fullMention = String(text[fullRange])
            
            return Mention(
                username: username,
                fullMention: fullMention,
                range: fullRange
            )
        }
    }
    
    // MARK: - Extract Usernames
    func extractUsernames(from text: String) -> [String] {
        return parseMentions(from: text).map { $0.username }
    }
    
    // MARK: - Highlight Mentions
    func highlightMentions(in text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        let mentions = parseMentions(from: text)
        
        for mention in mentions {
            if let range = Range(mention.range, in: attributedString) {
                attributedString[range].foregroundColor = .blue
                attributedString[range].font = .system(.body, design: .default, weight: .medium)
            }
        }
        
        return attributedString
    }
}

// MARK: - Mention Model
struct Mention {
    let username: String
    let fullMention: String
    let range: Range<String.Index>
}

// MARK: - TikTok-Style Mention Input View
struct MentionInputView: View {
    @Binding var text: String
    @State private var suggestions: [User] = []
    @State private var showSuggestions = false
    @State private var currentMentionRange: Range<String.Index>?
    @State private var currentMentionText = ""
    
    let placeholder: String
    let maxLength: Int
    
    init(text: Binding<String>, placeholder: String = "Type your message...", maxLength: Int = 500) {
        self._text = text
        self.placeholder = placeholder
        self.maxLength = maxLength
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main text input - TikTok style
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .frame(minHeight: 80)
                        .font(.system(size: 16))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .onChange(of: text) { newValue in
                            handleTextChange(newValue)
                        }
                    
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Character count - TikTok style
                HStack {
                    Spacer()
                    Text("\(text.count)/\(maxLength)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(text.count > Int(Double(maxLength) * 0.9) ? .red : .secondary)
                        .padding(.trailing, 16)
                        .padding(.top, 4)
                }
            }
            
            // Mention suggestions overlay - TikTok style
            if showSuggestions && !suggestions.isEmpty {
                VStack(spacing: 0) {
                    // Clean header
                    HStack {
                        Text("Mention")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(suggestions.count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    
                    // User suggestions - clean list
                    ForEach(Array(suggestions.prefix(4)), id: \.id) { user in
                        TikTokMentionRow(
                            user: user,
                            onTap: {
                                insertMention(user: user)
                            }
                        )
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }
    
    private func handleTextChange(_ newText: String) {
        print("🔍 [MentionInputView] Text changed: '\(newText)'")
        
        // Check if we're typing a mention
        if let lastAtIndex = newText.lastIndex(of: "@") {
            let afterAt = newText[newText.index(after: lastAtIndex)...]
            print("🔍 [MentionInputView] Found @ at position, after @: '\(afterAt)'")
            
            // Check if there's a space after @ (not a mention)
            if afterAt.first == " " {
                print("🔍 [MentionInputView] Space after @, hiding suggestions")
                showSuggestions = false
                return
            }
            
            // Check if we're still typing the mention
            if !afterAt.contains(" ") {
                currentMentionRange = lastAtIndex..<newText.endIndex
                currentMentionText = String(afterAt)
                print("🔍 [MentionInputView] Searching for: '\(currentMentionText)'")
                searchUsers(for: currentMentionText)
                showSuggestions = true
                return
            }
        }
        
        print("🔍 [MentionInputView] No @ found or space detected, hiding suggestions")
        showSuggestions = false
    }
    
    private func searchUsers(for query: String) {
        print("🔍 [MentionInputView] Starting search for: '\(query)'")
        guard !query.isEmpty else {
            print("🔍 [MentionInputView] Query is empty, clearing suggestions")
            suggestions = []
            return
        }
        
        Task {
            do {
                print("🔍 [MentionInputView] Calling API search...")
                let foundUsers = try await APIService.shared.searchUsers(query: query)
                print("🔍 [MentionInputView] API returned \(foundUsers.count) users")
                
                await MainActor.run {
                    // Sort users to prioritize exact username matches
                    suggestions = foundUsers.sorted { user1, user2 in
                        let username1 = user1.username ?? user1.name
                        let username2 = user2.username ?? user2.name
                        
                        // Exact username match gets highest priority
                        if username1.lowercased() == query.lowercased() {
                            return true
                        }
                        if username2.lowercased() == query.lowercased() {
                            return false
                        }
                        
                        // Then prioritize username matches over name matches
                        if user1.username != nil && user2.username == nil {
                            return true
                        }
                        if user1.username == nil && user2.username != nil {
                            return false
                        }
                        
                        // Finally sort alphabetically
                        return username1.lowercased() < username2.lowercased()
                    }
                    print("🔍 [MentionInputView] Set \(suggestions.count) suggestions")
                }
            } catch {
                print("❌ [MentionInputView] Error searching users: \(error)")
                await MainActor.run {
                    suggestions = []
                }
            }
        }
    }
    
    private func insertMention(user: User) {
        guard let range = currentMentionRange else { return }
        
        // Use username if available, otherwise use name
        let displayName = user.username ?? user.name
        let mention = "@\(displayName)"
        text.replaceSubrange(range, with: mention)
        
        showSuggestions = false
        currentMentionRange = nil
        currentMentionText = ""
    }
}

// MARK: - TikTok-Style Mention Row
struct TikTokMentionRow: View {
    let user: User
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            HStack(spacing: 12) {
                // Profile image - clean and simple
                AsyncImage(url: URL(string: user.profileImage?.url ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Text(String((user.username ?? user.name).prefix(1)).uppercased())
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        )
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                
                // User info - clean typography
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("@\(user.username ?? user.name)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        
                        if user.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 10))
                        }
                    }
                    
                    Text(user.name)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(isPressed ? Color(.systemGray6) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Legacy Mention Suggestion Row (for backward compatibility)
struct MentionSuggestionRow: View {
    let user: User
    let onTap: () -> Void
    
    var body: some View {
        TikTokMentionRow(user: user, onTap: onTap)
    }
}

// MARK: - Mention Display View
struct MentionDisplayView: View {
    let text: String
    
    var body: some View {
        Text(highlightedText)
    }
    
    private var highlightedText: AttributedString {
        let parser = MentionParser.shared
        return parser.highlightMentions(in: text)
    }
}

// MARK: - Mock Data
private let mockUsers: [User] = []
