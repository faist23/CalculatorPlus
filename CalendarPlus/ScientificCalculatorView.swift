import SwiftUI
import Foundation

struct ScientificCalculatorView: View {
    @Binding var useScientific: Bool
    
    @State private var displayText = "0.0000"
    @State private var stack: [Double] = [0.0, 0.0, 0.0, 0.0] // X, Y, Z, T
    @State private var isTypingNumber = false
    
    let row1 = ["√x", "eˣ", "10ˣ", "yˣ", "1/x", "CHS", "7", "8", "9", "÷"]
    let row2 = ["LN", "LOG", "%", "Δ%", "ABS", "EEX", "4", "5", "6", "×"]
    let row3 = ["SIN", "COS", "TAN", "π", "R↓", "x≷y", "1", "2", "3", "-"]
    let row4 = ["ON", "f", "g", "STO", "RCL", "ENTER", "0", ".", "Σ+", "+"]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("HP 15C Style")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button("Switch to 12C (Fin)") {
                    useScientific = false
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
                    ForEach(row1, id: \.self) { btn in SciButton(title: btn) { buttonTapped(btn) } }
                }
                GridRow {
                    ForEach(row2, id: \.self) { btn in SciButton(title: btn) { buttonTapped(btn) } }
                }
                GridRow {
                    ForEach(row3, id: \.self) { btn in SciButton(title: btn) { buttonTapped(btn) } }
                }
                GridRow {
                    SciButton(title: row4[0]) { buttonTapped(row4[0]) }
                    SciButton(title: row4[1]) { buttonTapped(row4[1]) }
                    SciButton(title: row4[2]) { buttonTapped(row4[2]) }
                    SciButton(title: row4[3]) { buttonTapped(row4[3]) }
                    SciButton(title: row4[4]) { buttonTapped(row4[4]) }
                    SciButton(title: row4[5]) { buttonTapped(row4[5]) }
                    SciButton(title: row4[6]) { buttonTapped(row4[6]) }
                    SciButton(title: row4[7]) { buttonTapped(row4[7]) }
                    SciButton(title: row4[8]) { buttonTapped(row4[8]) }
                    SciButton(title: row4[9]) { buttonTapped(row4[9]) }
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
            
        case "π":
            isTypingNumber = false
            pushStack()
            stack[0] = Double.pi
            displayText = format(stack[0])
            
        case "SIN":
            executeUnaryOperation { sin($0) }
        case "COS":
            executeUnaryOperation { cos($0) }
        case "TAN":
            executeUnaryOperation { tan($0) }
        case "LN":
            executeUnaryOperation { log($0) }
        case "LOG":
            executeUnaryOperation { log10($0) }
        case "eˣ":
            executeUnaryOperation { exp($0) }
        case "10ˣ":
            executeUnaryOperation { pow(10, $0) }
        case "√x":
            executeUnaryOperation { sqrt($0) }
        case "ABS":
            executeUnaryOperation { abs($0) }
            
        case "+":
            executeBinaryOperation { $0 + $1 }
        case "-":
            executeBinaryOperation { $0 - $1 }
        case "×":
            executeBinaryOperation { $0 * $1 }
        case "÷":
            if stack[0] != 0 {
                executeBinaryOperation { $0 / $1 }
            } else {
                displayText = "Error"
                isTypingNumber = false
            }
        case "yˣ":
            executeBinaryOperation { pow($0, $1) }
            
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
    
    private func executeUnaryOperation(_ operation: (Double) -> Double) {
        stack[0] = operation(stack[0])
        displayText = format(stack[0])
        isTypingNumber = false
    }
    
    private func executeBinaryOperation(_ operation: (Double, Double) -> Double) {
        let result = operation(stack[1], stack[0])
        popStack()
        stack[0] = result
        displayText = format(stack[0])
        isTypingNumber = false
    }
    
    private func format(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 8
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: number)) ?? "0.0000"
    }
}

struct SciButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
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
