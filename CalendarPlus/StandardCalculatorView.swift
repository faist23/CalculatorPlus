import SwiftUI

struct StandardCalculatorView: View {
    @State private var displayText = "0"
    @State private var equationText = ""
    @State private var expression: [String] = []
    @State private var isTyping = false
    @State private var memoryValue: Double = 0
    @State private var hasMemory = false
    @State private var showTooltip: Bool = !UserDefaults.standard.bool(forKey: "hasSeenRotateTooltip")

    var acLabel: String { isTyping || !expression.isEmpty ? "C" : "AC" }

    let topRow    = ["AC", "+/-", "%", "÷"]
    let memRow    = ["MC", "MR", "M-", "M+"]
    let numRows   = [
        ["7", "8", "9", "×"],
        ["4", "5", "6", "-"],
        ["1", "2", "3", "+"],
    ]

    var body: some View {
        GeometryReader { outer in
            VStack(spacing: 0) {
                Spacer(minLength: 8)

                if showTooltip {
                    HStack(spacing: 6) {
                        Image(systemName: "rotate.right")
                            .font(.system(size: 13, weight: .medium))
                        Text("Rotate for Financial • Scientific")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                    .transition(.opacity)
                    .padding(.bottom, 8)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { showTooltip = false }
                            UserDefaults.standard.set(true, forKey: "hasSeenRotateTooltip")
                        }
                    }
                }

                // Equation display
                HStack {
                    Spacer()
                    Text(equationText)
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.horizontal, 24)
                .frame(height: 30)

                // Main display
                HStack {
                    if hasMemory {
                        Text("M")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.orange)
                            .padding(.leading, 24)
                    }
                    Spacer()
                    Text(displayText)
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                }
                .padding(.horizontal, 24)
                .frame(height: 96)
                .padding(.bottom, 8)

                // Button grid — adaptive sizing from remaining space
                let hPad: CGFloat = 16
                let spacing: CGFloat = 12
                let cols: CGFloat = 4
                let rows: CGFloat = 6
                let totalVSpace = outer.size.height
                    - (showTooltip ? 43 : 0)
                    - 30 - 96 - 8 - 8
                    - spacing * (rows - 1)
                let btnSize = min(
                    (totalVSpace) / rows,
                    (outer.size.width - hPad * 2 - spacing * (cols - 1)) / cols
                )

                VStack(spacing: spacing) {
                    // Memory row (top)
                    HStack(spacing: spacing) {
                        ForEach(memRow, id: \.self) { btn in
                            CalcButton(title: btn, width: btnSize, height: btnSize, style: .memory) {
                                buttonTapped(btn)
                            }
                        }
                    }

                    // Function row: AC/C, +/-, %, ÷
                    HStack(spacing: spacing) {
                        ForEach(topRow, id: \.self) { btn in
                            let label = btn == "AC" ? acLabel : btn
                            CalcButton(title: label, width: btnSize, height: btnSize, style: buttonStyle(label)) {
                                buttonTapped(label)
                            }
                        }
                    }

                    // Number rows
                    ForEach(numRows, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(row, id: \.self) { btn in
                                CalcButton(title: btn, width: btnSize, height: btnSize, style: buttonStyle(btn)) {
                                    buttonTapped(btn)
                                }
                            }
                        }
                    }

                    // Bottom row: ⌫, 0, ., =
                    HStack(spacing: spacing) {
                        CalcButton(title: "⌫", width: btnSize, height: btnSize, style: .function_) {
                            buttonTapped("⌫")
                        }
                        CalcButton(title: "0", width: btnSize, height: btnSize, style: .digit) {
                            buttonTapped("0")
                        }
                        CalcButton(title: ".", width: btnSize, height: btnSize, style: .digit) {
                            buttonTapped(".")
                        }
                        CalcButton(title: "=", width: btnSize, height: btnSize, style: .operator_) {
                            buttonTapped("=")
                        }
                    }
                }
                .padding(.horizontal, hPad)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func buttonStyle(_ title: String) -> CalcButtonStyle {
        switch title {
        case "AC", "C", "+/-", "%", "⌫": return .function_
        case "÷", "×", "-", "+", "=": return .operator_
        case "MC", "MR", "M-", "M+": return .memory
        default: return .digit
        }
    }

    func buttonTapped(_ button: String) {
        switch button {
        case "0"..."9", ".":
            handleDigit(button)
        case "AC":
            clearAll()
        case "C":
            clearEntry()
        case "+/-":
            toggleSign()
        case "%":
            percent()
        case "+", "-", "×", "÷":
            handleOperation(button)
        case "=":
            executeEquals()
        case "⌫":
            deleteDigit()
        case "MC":
            memoryValue = 0; hasMemory = false
        case "MR":
            displayText = format(memoryValue)
            isTyping = true
        case "M+":
            memoryValue += Double(displayText) ?? 0
            hasMemory = memoryValue != 0
            isTyping = false
        case "M-":
            memoryValue -= Double(displayText) ?? 0
            hasMemory = memoryValue != 0
            isTyping = false
        default:
            break
        }
    }

    private func handleDigit(_ digit: String) {
        if !isTyping {
            displayText = digit == "." ? "0." : digit
            isTyping = true
        } else {
            if digit == "." && displayText.contains(".") { return }
            if displayText == "0" && digit != "." {
                displayText = digit
            } else {
                displayText += digit
            }
        }
    }

    private func deleteDigit() {
        guard isTyping else { return }
        if displayText.count <= 1 || (displayText.hasPrefix("-") && displayText.count <= 2) {
            displayText = "0"; isTyping = false
        } else {
            displayText.removeLast()
        }
    }

    private func clearAll() {
        displayText = "0"; equationText = ""; expression = []; isTyping = false
    }

    private func clearEntry() {
        displayText = "0"; isTyping = false
    }

    private func toggleSign() {
        if let val = Double(displayText) { displayText = format(val * -1) }
    }

    private func percent() {
        if let val = Double(displayText) { displayText = format(val / 100); isTyping = false }
    }

    private func handleOperation(_ op: String) {
        if isTyping { expression.append(displayText); isTyping = false }
        if let last = expression.last, ["+", "-", "×", "÷"].contains(last) {
            expression.removeLast()
        }
        expression.append(op)
        updateEquationText()
        let result = evaluateMDAS(expression: expression.dropLast().map { String($0) })
        displayText = format(result)
    }

    private func executeEquals() {
        if isTyping { expression.append(displayText) }
        if let last = expression.last, ["+", "-", "×", "÷"].contains(last) {
            expression.removeLast()
        }
        updateEquationText(withEquals: true)
        let result = evaluateMDAS(expression: expression)
        displayText = format(result)
        expression = []; isTyping = false
    }

    private func updateEquationText(withEquals: Bool = false) {
        equationText = expression.joined(separator: " ") + (withEquals ? " =" : "")
    }

    private func evaluateMDAS(expression: [String]) -> Double {
        guard !expression.isEmpty else { return Double(displayText) ?? 0 }
        var work = expression
        var i = 0
        while i < work.count {
            let token = work[i]
            if token == "×" || token == "÷" {
                let l = Double(work[i-1]) ?? 0, r = Double(work[i+1]) ?? 0
                let res = token == "×" ? l * r : (r != 0 ? l / r : 0)
                work.remove(at: i+1); work.remove(at: i); work.remove(at: i-1)
                work.insert(String(res), at: i-1); i -= 1
            }
            i += 1
        }
        var result = Double(work[0]) ?? 0; i = 1
        while i < work.count {
            let op = work[i], v = Double(work[i+1]) ?? 0
            result = op == "+" ? result + v : result - v
            i += 2
        }
        return result
    }

    private func format(_ n: Double) -> String {
        let f = NumberFormatter()
        f.minimumFractionDigits = 0; f.maximumFractionDigits = 8
        f.numberStyle = .decimal; f.usesGroupingSeparator = false
        return f.string(from: NSNumber(value: n)) ?? "0"
    }

}

// MARK: - Design tokens

enum CalcButtonStyle { case digit, function_, operator_, memory }

struct CalcButton: View {
    let title: String
    let width: CGFloat   // button width (may differ from height for 0 key)
    let height: CGFloat  // button height (always btnSize)
    let style: CalcButtonStyle
    var alignment: Alignment = .center
    let action: () -> Void

    var bgColor: Color {
        switch style {
        case .digit:     return Color(white: 0.2)
        case .function_: return Color(white: 0.6)
        case .operator_: return .orange
        case .memory:    return Color(red: 0.18, green: 0.18, blue: 0.28)
        }
    }

    var fgColor: Color { style == .function_ ? .black : .white }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 30, weight: .medium))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundColor(fgColor)
                .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: alignment)
                .padding(.leading, alignment == .leading ? height * 0.35 : 0)
                .background(bgColor)
                .clipShape(Capsule())
        }
        .buttonStyle(CalcPressStyle())
        .accessibilityLabel(title)
        .frame(width: width, height: height)
    }
}

private struct CalcPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { pressed in
                if pressed { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
            }
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .brightness(configuration.isPressed ? -0.10 : 0)
            .animation(.easeOut(duration: 0.07), value: configuration.isPressed)
    }
}
