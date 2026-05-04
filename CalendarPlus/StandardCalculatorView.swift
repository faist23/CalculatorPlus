import SwiftUI

enum CalculatorOperation {
    case add, subtract, multiply, divide, none
}

struct StandardCalculatorView: View {
    @State private var displayText = "0"
    @State private var currentValue: Double = 0
    @State private var previousValue: Double = 0
    @State private var operation: CalculatorOperation = .none
    @State private var isTypingNumber = false
    
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
        switch button {
        case "0"..."9", ".":
            if isTypingNumber {
                if button == "." && displayText.contains(".") { return }
                displayText += button
            } else {
                displayText = button == "." ? "0." : button
                isTypingNumber = true
            }
            currentValue = Double(displayText) ?? 0
        case "AC":
            displayText = "0"
            currentValue = 0
            previousValue = 0
            operation = .none
            isTypingNumber = false
        case "+/-":
            currentValue = -currentValue
            displayText = format(currentValue)
        case "%":
            currentValue = currentValue / 100
            displayText = format(currentValue)
        case "+":
            setOperation(.add)
        case "-":
            setOperation(.subtract)
        case "×":
            setOperation(.multiply)
        case "÷":
            setOperation(.divide)
        case "=":
            calculateResult()
        default:
            break
        }
    }
    
    private func setOperation(_ op: CalculatorOperation) {
        if isTypingNumber {
            calculateResult()
        }
        previousValue = currentValue
        operation = op
        isTypingNumber = false
    }
    
    private func calculateResult() {
        switch operation {
        case .add:
            currentValue = previousValue + currentValue
        case .subtract:
            currentValue = previousValue - currentValue
        case .multiply:
            currentValue = previousValue * currentValue
        case .divide:
            if currentValue != 0 {
                currentValue = previousValue / currentValue
            } else {
                displayText = "Error"
                isTypingNumber = false
                return
            }
        case .none:
            break
        }
        displayText = format(currentValue)
        operation = .none
        isTypingNumber = false
    }
    
    private func format(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: number)) ?? "0"
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
