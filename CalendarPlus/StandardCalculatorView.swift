import SwiftUI

struct StandardCalculatorView: View {
    @State private var displayText = "0"
    
    let buttons = [
        ["AC", "+/-", "%", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "-"],
        ["1", "2", "3", "+"]
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            // Display
            HStack {
                Spacer()
                Text(displayText)
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            
            // Button Grid
            Grid(horizontalSpacing: 16, verticalSpacing: 16) {
                ForEach(buttons, id: \.self) { row in
                    GridRow {
                        ForEach(row, id: \.self) { button in
                            CalculatorButton(title: button) {
                                self.buttonTapped(button)
                            }
                        }
                    }
                }
                
                // Bottom Row with spanning zero
                GridRow {
                    CalculatorButton(title: "0", alignment: .leading) {
                        self.buttonTapped("0")
                    }
                    .gridCellColumns(2)
                    
                    CalculatorButton(title: ".") {
                        self.buttonTapped(".")
                    }
                    
                    CalculatorButton(title: "=") {
                        self.buttonTapped("=")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
    
    func buttonTapped(_ button: String) {
        // Placeholder for calculator logic
        if button == "AC" {
            displayText = "0"
        } else {
            if displayText == "0" {
                displayText = button
            } else if displayText.count < 9 { // Prevent overflow for now
                displayText += button
            }
        }
    }
}

struct CalculatorButton: View {
    let title: String
    var alignment: Alignment = .center
    let action: () -> Void
    
    var backgroundColor: Color {
        switch title {
        case "AC", "+/-", "%":
            return Color(.lightGray)
        case "÷", "×", "-", "+", "=":
            return .orange
        default:
            return Color(.darkGray)
        }
    }
    
    var foregroundColor: Color {
        switch title {
        case "AC", "+/-", "%":
            return .black
        default:
            return .white
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                .padding(.horizontal, alignment == .leading ? 28 : 0)
                .background(backgroundColor)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    StandardCalculatorView()
}
