import SwiftUI

struct CategoryFilterTabs: View {
    @Binding var selectedCategory: String
    let categories: [String]
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryTabButton(
                        title: getCategoryTitle(category),
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private func getCategoryTitle(_ category: String) -> String {
        switch category {
        case "all":
            return "All"
        case "nearby":
            return "Nearby"
        case "mutual":
            return "Mutual"
        case "suggested":
            return "Suggested"
        default:
            return category.capitalized
        }
    }
}

struct CategoryTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    // Brand colors
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color(.label))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? primaryColor : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? primaryColor : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CategoryFilterTabs(
        selectedCategory: .constant("all"),
        categories: ["all", "nearby", "mutual", "suggested"]
    )
} 