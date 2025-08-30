import SwiftUI

// Simple progress indicator that won't cause compiler issues
struct SimpleProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let primaryColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Rectangle()
                        .fill(index <= currentStep ? primaryColor : Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// Simple text field component
struct SimpleTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let isRequired: Bool
    let primaryColor: Color
    
    init(title: String, placeholder: String, text: Binding<String>, isRequired: Bool = false, primaryColor: Color) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isRequired = isRequired
        self.primaryColor = primaryColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .fontWeight(.semibold)
                if isRequired {
                    Text("*")
                        .foregroundColor(primaryColor)
                }
            }
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

// Simple text editor component
struct SimpleTextEditor: View {
    let title: String
    @Binding var text: String
    let height: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .fontWeight(.semibold)
            TextEditor(text: $text)
                .frame(height: height)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

// Simple button component
struct SimpleButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    let primaryColor: Color
    
    enum ButtonStyle {
        case primary, secondary
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.medium)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(style == .primary ? primaryColor : Color.gray.opacity(0.1))
                .foregroundColor(style == .primary ? .white : .primary)
                .cornerRadius(12)
        }
    }
}










