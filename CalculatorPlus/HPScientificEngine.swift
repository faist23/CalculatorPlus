import Foundation
import Observation

@Observable
final class HPScientificEngine {

    // MARK: - RPN Stack  (X = index 0, Y = 1, Z = 2, T = 3)
    var stack: [Double] = [0, 0, 0, 0]
    var displayText: String = "0.0000"
    var isTypingNumber: Bool = false
    var stackLiftEnabled: Bool = true

    // MARK: - Tape
    var tape: [TapeEntry] = []

    // MARK: - Angle mode
    enum AngleMode { case deg, rad }
    var angleMode: AngleMode = .deg

    // MARK: - Storage registers R0–R9
    var storageRegs: [Double] = Array(repeating: 0, count: 10)

    // MARK: - RNG (HP 15C LCG: r = frac(9821r + 0.211327))
    var rngSeed: Double = 0.5

    // MARK: - Stats (2-D accumulator for x,y pairs)
    var statN:     Double = 0
    var statSumX:  Double = 0
    var statSumY:  Double = 0
    var statSumX2: Double = 0
    var statSumY2: Double = 0
    var statSumXY: Double = 0

    // MARK: - Pending two-key sequence (STO/RCL)
    var pendingInput: PendingInput = .none

    // MARK: - Annunciators
    var annunciators: [String] = []

    // MARK: - Dispatch

    func dispatch(_ key: String) {
        // Resolve pending STO/RCL
        if pendingInput != .none {
            if let digit = Int(key), (0...9).contains(digit) {
                if pendingInput == .sto {
                    if isTypingNumber { commitTyping() }
                    storageRegs[digit] = stack[0]
                    appendTape(label: "STO \(digit)", result: displayText)
                } else {
                    if isTypingNumber { commitTyping() }
                    if stackLiftEnabled { pushStack() }
                    stack[0] = storageRegs[digit]
                    displayText = fmt(stack[0])
                    isTypingNumber = false; stackLiftEnabled = true
                    appendTape(label: "RCL \(digit)", result: displayText)
                }
                pendingInput = .none
                return
            }
            pendingInput = .none
        }

        switch key {
        // DIGIT ENTRY — explicit list avoids range matching multi-char strings like "1/x", "10ˣ"
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".":
            handleDigit(key); return

        case "EEX":
            if !isTypingNumber {
                if stackLiftEnabled { pushStack() }
                displayText = "1"; stack[0] = 1
                isTypingNumber = true; stackLiftEnabled = true
            }
            if !displayText.contains("E") { displayText += "E" }
            return

        case "SEED":
            if isTypingNumber { commitTyping() }
            let s = stack[0]; rngSeed = s - Double(Int(s))
            if rngSeed < 0 { rngSeed += 1.0 }
            appendTape(label: "SEED", result: fmt(rngSeed))

        case "RAN#":
            if isTypingNumber { commitTyping() }
            if stackLiftEnabled { pushStack() }
            let next = 9821.0 * rngSeed + 0.211327
            rngSeed = next - Double(Int(next))
            if rngSeed < 0 { rngSeed += 1.0 }
            stack[0] = rngSeed
            displayText = fmt(rngSeed)
            isTypingNumber = false; stackLiftEnabled = true
            appendTape(label: "RAN#", result: displayText)

        // STACK
        case "ENTER":
            if isTypingNumber { commitTyping() }
            pushStack()
            displayText = fmt(stack[0])
            isTypingNumber = false; stackLiftEnabled = false
            appendTape(label: "ENTER", result: displayText)

        case "CHS":
            if isTypingNumber {
                if displayText.contains("E") {
                    let parts = displayText.components(separatedBy: "E")
                    let exp = parts.count > 1 ? parts[1] : ""
                    displayText = parts[0] + "E" + (exp.hasPrefix("-") ? String(exp.dropFirst()) : "-" + exp)
                } else {
                    displayText = displayText.hasPrefix("-")
                        ? String(displayText.dropFirst()) : "-" + displayText
                }
                stack[0] = parseDisplay()
            } else {
                stack[0] = -stack[0]; displayText = fmt(stack[0]); stackLiftEnabled = true
            }

        case "CLx":
            isTypingNumber = false; stack[0] = 0; displayText = "0.0000"

        case "x≷y":
            if isTypingNumber { commitTyping() }
            stack.swapAt(0, 1)
            displayText = fmt(stack[0]); isTypingNumber = false; stackLiftEnabled = true

        case "R↓":
            if isTypingNumber { commitTyping() }
            let t = stack[0]
            stack[0] = stack[1]; stack[1] = stack[2]
            stack[2] = stack[3]; stack[3] = t
            displayText = fmt(stack[0]); isTypingNumber = false; stackLiftEnabled = true

        // ARITHMETIC
        case "+":
            binary { $0 + $1 }; appendTape(label: "+", result: displayText)
        case "-":
            binary { $0 - $1 }; appendTape(label: "−", result: displayText)
        case "×":
            binary { $0 * $1 }; appendTape(label: "×", result: displayText)
        case "÷":
            if stack[0] == 0 { displayText = "Error"; return }
            binary { $0 / $1 }; appendTape(label: "÷", result: displayText)
        case "yˣ":
            binary { pow($0, $1) }; appendTape(label: "yˣ", result: displayText)
        case "1/x":
            if stack[0] == 0 { displayText = "Error"; return }
            unary { 1 / $0 }
        case "x²":
            unary { $0 * $0 }

        // ROOTS / LOG / EXP
        case "√x":
            if stack[0] < 0 { displayText = "Error"; return }
            unary { sqrt($0) }
        case "eˣ":
            unary { exp($0) }
        case "LN":
            if stack[0] <= 0 { displayText = "Error"; return }
            unary { log($0) }
        case "10ˣ":
            unary { pow(10.0, $0) }
        case "LOG":
            if stack[0] <= 0 { displayText = "Error"; return }
            unary { log10($0) }
        case "ABS":
            unary { abs($0) }
        case "FRAC":
            unary { $0 - Foundation.trunc($0) }
        case "INT":
            unary { Foundation.trunc($0) }

        // TRIG
        case "SIN":    unary { snapTrig(sin(toRad($0))) }
        case "COS":    unary { snapTrig(cos(toRad($0))) }
        case "TAN":    unary { snapTrig(tan(toRad($0))) }
        case "SIN⁻¹":
            if abs(stack[0]) > 1 { displayText = "Error"; return }
            unary { fromRad(asin($0)) }
        case "COS⁻¹":
            if abs(stack[0]) > 1 { displayText = "Error"; return }
            unary { fromRad(acos($0)) }
        case "TAN⁻¹": unary { fromRad(atan($0)) }

        // HYPERBOLIC TRIG
        case "SINH":   unary { sinh($0) }
        case "COSH":   unary { cosh($0) }
        case "TANH":   unary { tanh($0) }
        case "SINH⁻¹": unary { asinh($0) }
        case "COSH⁻¹":
            if stack[0] < 1 { displayText = "Error"; return }
            unary { acosh($0) }
        case "TANH⁻¹":
            if abs(stack[0]) >= 1 { displayText = "Error"; return }
            unary { atanh($0) }

        // CONSTANTS
        case "π":
            if isTypingNumber { commitTyping() }
            if stackLiftEnabled { pushStack() }
            stack[0] = Double.pi
            displayText = fmt(stack[0])
            isTypingNumber = false; stackLiftEnabled = true

        // MODE
        case "DEG":
            angleMode = .deg; annunciators = ["DEG"]
        case "RAD":
            angleMode = .rad; annunciators = ["RAD"]

        // FACTORIAL
        case "x!", "n!":
            if isTypingNumber { commitTyping() }
            let n = stack[0]
            guard n >= 0, n == Foundation.trunc(n), n <= 170 else { displayText = "Error"; return }
            var r = 1.0
            for k in 1...max(1, Int(n)) { r *= Double(k) }
            if n == 0 { r = 1 }
            stack[0] = r; displayText = fmt(r); isTypingNumber = false; stackLiftEnabled = true

        // STATS — Σ+ accumulates (X=x, Y=y) pair
        case "Σ+":
            if isTypingNumber { commitTyping() }
            let x = stack[0], y = stack[1]
            statN += 1; statSumX += x; statSumY += y
            statSumX2 += x * x; statSumY2 += y * y; statSumXY += x * y
            stack[0] = statN; displayText = fmt(statN); isTypingNumber = false; stackLiftEnabled = true
            appendTape(label: "Σ+", result: displayText)

        case "Σ-":
            if isTypingNumber { commitTyping() }
            let x = stack[0], y = stack[1]
            statN -= 1; statSumX -= x; statSumY -= y
            statSumX2 -= x * x; statSumY2 -= y * y; statSumXY -= x * y
            stack[0] = statN; displayText = fmt(statN); isTypingNumber = false; stackLiftEnabled = true

        case "x̄":
            guard statN > 0 else { displayText = "Error"; return }
            if isTypingNumber { commitTyping() }
            stack[0] = statSumX / statN
            displayText = fmt(stack[0]); isTypingNumber = false; stackLiftEnabled = true

        case "ȳ":
            guard statN > 0 else { displayText = "Error"; return }
            if isTypingNumber { commitTyping() }
            stack[0] = statSumY / statN
            displayText = fmt(stack[0]); isTypingNumber = false; stackLiftEnabled = true

        case "s":
            guard statN > 1 else { displayText = "Error"; return }
            if isTypingNumber { commitTyping() }
            let variance = (statSumX2 - statSumX * statSumX / statN) / (statN - 1)
            stack[0] = sqrt(max(variance, 0))
            displayText = fmt(stack[0]); isTypingNumber = false; stackLiftEnabled = true

        case "sy":
            guard statN > 1 else { displayText = "Error"; return }
            if isTypingNumber { commitTyping() }
            let variance = (statSumY2 - statSumY * statSumY / statN) / (statN - 1)
            stack[0] = sqrt(max(variance, 0))
            displayText = fmt(stack[0]); isTypingNumber = false; stackLiftEnabled = true

        case "n":   // return sample count
            if isTypingNumber { commitTyping() }
            if stackLiftEnabled { pushStack() }
            stack[0] = statN; displayText = fmt(statN)
            isTypingNumber = false; stackLiftEnabled = true

        // STO / RCL
        case "STO":
            if isTypingNumber { commitTyping() }
            pendingInput = .sto
        case "RCL":
            pendingInput = .rcl

        case "CLΣ":
            statN = 0; statSumX = 0; statSumY = 0
            statSumX2 = 0; statSumY2 = 0; statSumXY = 0

        // UNIT CONVERSIONS (g-shift on number keys)
        case "→km": unary { $0 * 1.60934 }   // miles → km
        case "→mi": unary { $0 / 1.60934 }   // km → miles
        case "→cm": unary { $0 * 2.54 }       // inches → cm
        case "→in": unary { $0 / 2.54 }       // cm → inches
        case "→m":  unary { $0 * 0.3048 }     // feet → meters
        case "→ft": unary { $0 / 0.3048 }     // meters → feet
        case "→kg": unary { $0 * 0.453592 }   // lb → kg
        case "→lb": unary { $0 / 0.453592 }   // kg → lb
        case "→°C": unary { ($0 - 32.0) * 5.0 / 9.0 }
        case "→°F": unary { $0 * 9.0 / 5.0 + 32.0 }

        default:
            break
        }
    }

    // MARK: - Digit entry

    private func handleDigit(_ d: String) {
        if !isTypingNumber {
            if stackLiftEnabled { pushStack() }
            displayText = d == "." ? "0." : d
            isTypingNumber = true; stackLiftEnabled = true
        } else if displayText.contains("E") {
            if d == "." { return }
            let expPart = displayText.components(separatedBy: "E").last ?? ""
            let expDigits = expPart.hasPrefix("-") ? String(expPart.dropFirst()) : expPart
            if expDigits.count >= 2 { return }
            displayText += d
        } else {
            if d == "." && displayText.contains(".") { return }
            if displayText == "0" && d != "." { displayText = d }
            else if displayText == "-0" && d != "." { displayText = "-" + d }
            else { displayText += d }
        }
        stack[0] = parseDisplay()
    }

    // MARK: - Stack helpers

    private func commitTyping() {
        stack[0] = parseDisplay(); isTypingNumber = false
    }

    private func parseDisplay() -> Double {
        var text = displayText.replacingOccurrences(of: "E", with: "e")
        if text.hasSuffix("e") || text.hasSuffix("e-") { text = text.components(separatedBy: "e")[0] }
        return Double(text) ?? 0
    }

    private func pushStack() {
        stack[3] = stack[2]; stack[2] = stack[1]; stack[1] = stack[0]
    }

    private func popStack() {
        stack[0] = stack[1]; stack[1] = stack[2]; stack[2] = stack[3]
    }

    private func unary(_ op: (Double) -> Double) {
        if isTypingNumber { commitTyping() }
        stack[0] = op(stack[0])
        displayText = fmt(stack[0]); isTypingNumber = false; stackLiftEnabled = true
    }

    private func binary(_ op: (Double, Double) -> Double) {
        if isTypingNumber { commitTyping() }
        let result = op(stack[1], stack[0])
        popStack()
        stack[0] = result; displayText = fmt(result)
        isTypingNumber = false; stackLiftEnabled = true
    }

    // MARK: - Angle conversion

    private func toRad(_ v: Double) -> Double {
        angleMode == .deg ? v * .pi / 180.0 : v
    }

    private func fromRad(_ v: Double) -> Double {
        angleMode == .deg ? v * 180.0 / .pi : v
    }

    // Snap floating-point trig results that should be exact integers to their true values.
    private func snapTrig(_ v: Double) -> Double {
        let rounded = v.rounded()
        return abs(v - rounded) < 1e-10 ? rounded : v
    }

    // MARK: - Tape recall

    func recallTapeValue(_ v: Double) {
        if isTypingNumber { commitTyping() }
        if stackLiftEnabled { pushStack() }
        stack[0] = v
        displayText = fmt(v)
        isTypingNumber = false
        stackLiftEnabled = true
    }

    // MARK: - Tape

    private func appendTape(label: String, result: String) {
        tape.append(TapeEntry(label: label, result: result))
        if tape.count > 200 { tape.removeFirst() }
    }

    // MARK: - Formatting

    func fmt(_ n: Double) -> String {
        guard n.isFinite else { return "Error" }
        let absN = abs(n)
        if absN >= 1e10 || (absN < 1e-4 && absN != 0) {
            return String(format: "%.6g", n)
        }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = true
        f.minimumFractionDigits = 4
        f.maximumFractionDigits = 8
        return f.string(from: NSNumber(value: n)) ?? "0.0000"
    }
}
