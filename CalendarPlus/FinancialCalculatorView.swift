import SwiftUI

struct FinancialCalculatorView: View {
    @Binding var useScientific: Bool
    
    @State private var displayText = "0.00"
    @State private var stack: [Double] = [0.0, 0.0, 0.0, 0.0] // X, Y, Z, T
    @State private var isTypingNumber = false
    
    let row1 = ["n", "i", "PV", "PMT", "FV", "CHS", "7", "8", "9", "÷"]
    let row2 = ["yˣ", "1/x", "%T", "Δ%", "%", "EEX", "4", "5", "6", "×"]
    let row3 = ["R/S", "SST", "R↓", "x≷y", "CLX", "ENTER", "1", "2", "3", "-"]
    let row4 = ["ON", "f", "g", "STO", "RCL", "0", ".", "Σ+", "+"]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("HP 12C Style")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button("Switch to 15C (Sci)") {
                    useScientific = true
                }
                .font(.subheadline)
                .padding(6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // LCD Display
            HStack {
                Spacer()
                Text(displayText)
                    .font(.custom("Courier", size: 64))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(Color(red: 0.65, green: 0.7, blue: 0.55))
            .cornerRadius(8)
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Keypad
            Grid(horizontalSpacing: 12, verticalSpacing: 16) {
                GridRow {
                    ForEach(row1, id: \.self) { btn in FinButton(title: btn) { buttonTapped(btn) } }
                }
                GridRow {
                    ForEach(row2, id: \.self) { btn in FinButton(title: btn) { buttonTapped(btn) } }
                }
                GridRow {
                    ForEach(row3, id: \.self) { btn in FinButton(title: btn) { buttonTapped(btn) } }
                }
                GridRow {
                    FinButton(title: row4[0]) { buttonTapped(row4[0]) }
                    FinButton(title: row4[1]) { buttonTapped(row4[1]) }
                    FinButton(title: row4[2]) { buttonTapped(row4[2]) }
                    FinButton(title: row4[3]) { buttonTapped(row4[3]) }
                    FinButton(title: row4[4]) { buttonTapped(row4[4]) }
                    FinButton(title: row4[5]) { buttonTapped(row4[5]) }
                        .gridCellColumns(2)
                    FinButton(title: row4[6]) { buttonTapped(row4[6]) }
                    FinButton(title: row4[7]) { buttonTapped(row4[7]) }
                    FinButton(title: row4[8]) { buttonTapped(row4[8]) }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(red: 0.15, green: 0.15, blue: 0.15).ignoresSafeArea())
    }
    
    private func buttonTapped(_ button: String) {
        switch button {
        case "0"..."9", ".":
            if isTypingNumber {
                if button == "." && displayText.contains(".") { return }
                displayText += button
            } else {
                displayText = button == "." ? "0." : button
                isTypingNumber = true
            }
            stack[0] = Double(displayText) ?? 0.0
            
        case "ENTER":
            isTypingNumber = false
            pushStack()
            displayText = format(stack[0])
            
        case "CHS":
            if isTypingNumber {
                if displayText.hasPrefix("-") {
                    displayText.removeFirst()
                } else {
                    displayText = "-" + displayText
                }
                stack[0] = Double(displayText) ?? 0.0
            } else {
                stack[0] = -stack[0]
                displayText = format(stack[0])
            }
            
        case "CLX":
            isTypingNumber = false
            stack[0] = 0.0
            displayText = "0.00"
            
        case "+":
            executeOperation { $0 + $1 }
        case "-":
            executeOperation { $0 - $1 }
        case "×":
            executeOperation { $0 * $1 }
        case "÷":
            if stack[0] != 0 {
                executeOperation { $0 / $1 }
            } else {
                displayText = "Error"
                isTypingNumber = false
            }
            
        case "1/x":
            if stack[0] != 0 {
                stack[0] = 1.0 / stack[0]
                displayText = format(stack[0])
                isTypingNumber = false
            }
            
        case "x≷y":
            let temp = stack[0]
            stack[0] = stack[1]
            stack[1] = temp
            displayText = format(stack[0])
            isTypingNumber = false
            
        case "R↓":
            let temp = stack[0]
            stack[0] = stack[1]
            stack[1] = stack[2]
            stack[2] = stack[3]
            stack[3] = temp
            displayText = format(stack[0])
            isTypingNumber = false
            
        default:
            break
        }
    }
    
    private func pushStack() {
        stack[3] = stack[2]
        stack[2] = stack[1]
        stack[1] = stack[0]
    }
    
    private func popStack() {
        stack[0] = stack[1]
        stack[1] = stack[2]
        stack[2] = stack[3]
    }
    
    private func executeOperation(_ operation: (Double, Double) -> Double) {
        let result = operation(stack[1], stack[0])
        popStack()
        stack[0] = result
        displayText = format(stack[0])
        isTypingNumber = false
    }
    
    private func format(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 8
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: number)) ?? "0.00"
    }
}

struct FinButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .foregroundColor(title == "f" ? .orange : (title == "g" ? .blue : .white))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    title == "ENTER" ? Color.blue :
                        (title == "f" ? Color.black :
                            (title == "g" ? Color.black :
                                (title >= "0" && title <= "9" || title == "." ? Color(red: 0.3, green: 0.3, blue: 0.3) : Color.black)))
                )
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
        }
    }
}
