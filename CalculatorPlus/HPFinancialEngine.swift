import Foundation
import Observation

enum PendingInput { case none, sto, rcl }

@Observable
final class HPFinancialEngine {

    // MARK: - RPN Stack  (X = index 0, Y = 1, Z = 2, T = 3)
    var stack: [Double] = [0, 0, 0, 0]
    var displayText: String = "0.00"
    var displayDecimalPlaces: Int = 2
    var isTypingNumber: Bool = false
    var stackLiftEnabled: Bool = true

    // MARK: - Tape (max 200 entries)
    var tape: [TapeEntry] = []

    // MARK: - TVM registers
    var tvmN:   Double = 0
    var tvmI:   Double = 0   // periodic rate stored as percent (0.5 = 0.5 %/period)
    var tvmPV:  Double = 0
    var tvmPMT: Double = 0
    var tvmFV:  Double = 0
    var tvmBEG: Bool   = false

    // MARK: - Storage registers R0–R9
    var storageRegs: [Double] = Array(repeating: 0, count: 10)

    // MARK: - Cash flow registers (CF0 at index 0, CFj at 1…)
    var cfCashFlows: [Double] = []
    var cfRepeatCounts: [Int] = []

    // MARK: - Date mode
    var dateUsFormat: Bool = true   // true = MM.DDYYYY, false = DD.MMYYYY

    // MARK: - Stats (1-D accumulator)
    var statN:    Double = 0
    var statSumX: Double = 0
    var statSumX2: Double = 0

    // MARK: - Last X register
    var lastX: Double = 0

    // MARK: - Pending two-key sequence (STO/RCL)
    var pendingInput: PendingInput = .none

    // MARK: - LCD annunciators
    var annunciators: [String] = []

    // MARK: - Dispatch

    func dispatch(_ key: String) {
        // Resolve pending STO/RCL sequence
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
                    isTypingNumber = false
                    stackLiftEnabled = true
                    appendTape(label: "RCL \(digit)", result: displayText)
                }
                pendingInput = .none
                return
            }
            pendingInput = .none
            // fall through and process key normally
        }

        switch key {
        // DIGIT ENTRY — explicit list avoids range matching multi-char strings like "1/x", "12÷"
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

        case "CLX", "CLx":
            isTypingNumber = false; stack[0] = 0; displayText = fmt(0)

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
            if isTypingNumber { commitTyping() }
            lastX = stack[0]
            stack[0] = 1 / stack[0]; displayText = fmt(stack[0])
            isTypingNumber = false; stackLiftEnabled = true

        // TVM — store X if typing, solve if not
        case "n":
            if isTypingNumber { commitTyping(); tvmN = stack[0]; appendTape(label: "→n", result: displayText) }
            else { solveTVM(.n) }
        case "i":
            if isTypingNumber { commitTyping(); tvmI = stack[0]; appendTape(label: "→i", result: displayText) }
            else { solveTVM(.i) }
        case "PV":
            if isTypingNumber { commitTyping(); tvmPV = stack[0]; appendTape(label: "→PV", result: displayText) }
            else { solveTVM(.pv) }
        case "PMT":
            if isTypingNumber { commitTyping(); tvmPMT = stack[0]; appendTape(label: "→PMT", result: displayText) }
            else { solveTVM(.pmt) }
        case "FV":
            if isTypingNumber { commitTyping(); tvmFV = stack[0]; appendTape(label: "→FV", result: displayText) }
            else { solveTVM(.fv) }

        // Cash flows
        case "CF₀", "CF0":
            if isTypingNumber { commitTyping() }
            cfCashFlows = [stack[0]]
            cfRepeatCounts = [1]
            displayText = fmt(stack[0])
            isTypingNumber = false; stackLiftEnabled = true
            appendTape(label: "CF₀", result: displayText)

        case "CFⱼ", "CFj":
            if isTypingNumber { commitTyping() }
            if cfCashFlows.isEmpty {
                cfCashFlows = [stack[0]]; cfRepeatCounts = [1]
            } else {
                cfCashFlows.append(stack[0]); cfRepeatCounts.append(1)
            }
            displayText = fmt(stack[0])
            isTypingNumber = false; stackLiftEnabled = true
            appendTape(label: "CFⱼ \(cfCashFlows.count - 1)", result: displayText)

        case "Nⱼ", "Nj":
            if isTypingNumber { commitTyping() }
            guard !cfRepeatCounts.isEmpty else { return }
            let nj = max(1, Int(stack[0]))
            cfRepeatCounts[cfRepeatCounts.count - 1] = nj
            displayText = fmt(Double(nj))
            isTypingNumber = false; stackLiftEnabled = true
            appendTape(label: "Nⱼ", result: displayText)

        case "NPV":
            solveNPV()

        case "IRR":
            solveIRR()

        case "AMORT":
            if isTypingNumber { commitTyping() }
            solveAMORT()

        case "RND":
            if isTypingNumber { commitTyping() }
            stack[0] = (stack[0] * 100).rounded() / 100
            displayText = fmt(stack[0])
            isTypingNumber = false; stackLiftEnabled = true
            appendTape(label: "RND", result: displayText)

        case "INT":
            if isTypingNumber { commitTyping() }
            let simpleInterest = tvmPV * (tvmI / 100.0) * tvmN / 365.0
            stack[1] = tvmPV + simpleInterest
            stack[0] = simpleInterest
            displayText = fmt(simpleInterest)
            isTypingNumber = false; stackLiftEnabled = true
            appendTape(label: "S.INT", result: displayText)
            appendTape(label: "TOT", result: fmt(stack[1]))

        case "D.MY":
            dateUsFormat.toggle()
            if dateUsFormat {
                annunciators = annunciators.filter { $0 != "D.MY" }
            } else {
                if !annunciators.contains("D.MY") { annunciators.append("D.MY") }
            }

        case "DATE":
            if isTypingNumber { commitTyping() }
            guard let base = hpToDate(stack[1]) else { displayText = "Error"; return }
            let addDays = Int(stack[0].rounded())
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "UTC")!
            guard let result = cal.date(byAdding: .day, value: addDays, to: base) else {
                displayText = "Error"; return
            }
            let dow = cal.dateComponents([.weekday], from: result).weekday ?? 1
            stack[1] = Double((dow + 5) % 7 + 1)   // 1=Mon … 7=Sun
            stack[0] = dateToHP(result)
            displayText = fmtDate(result)
            isTypingNumber = false; stackLiftEnabled = true
            appendTape(label: "DATE", result: displayText)

        case "ΔDAYS":
            if isTypingNumber { commitTyping() }
            guard let d1 = hpToDate(stack[1]),
                  let d2 = hpToDate(stack[0]) else { displayText = "Error"; return }
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "UTC")!
            let days = cal.dateComponents([.day], from: d1, to: d2).day ?? 0
            stack[0] = Double(days)
            displayText = fmt(Double(days))
            isTypingNumber = false; stackLiftEnabled = true
            appendTape(label: "ΔDAYS", result: displayText)

        case "12÷":
            if isTypingNumber { commitTyping() }
            let v12d = stack[0] / 12.0
            stack[0] = v12d; tvmI = v12d; displayText = fmt(v12d)
        case "12×":
            if isTypingNumber { commitTyping() }
            let v12m = stack[0] * 12.0
            stack[0] = v12m; tvmI = v12m; displayText = fmt(v12m)

        case "BEG":
            tvmBEG = true;  annunciators = ["BEG"]
        case "END":
            tvmBEG = false; annunciators = []

        // PERCENT
        case "%":
            if isTypingNumber { commitTyping() }
            stack[0] = stack[1] * stack[0] / 100.0
            displayText = fmt(stack[0]); isTypingNumber = false; stackLiftEnabled = true

        case "Δ%":
            if isTypingNumber { commitTyping() }
            guard stack[1] != 0 else { displayText = "Error"; return }
            stack[0] = (stack[0] - stack[1]) / abs(stack[1]) * 100.0
            displayText = fmt(stack[0]); isTypingNumber = false; stackLiftEnabled = true

        case "%T":
            if isTypingNumber { commitTyping() }
            guard stack[1] != 0 else { displayText = "Error"; return }
            stack[0] = stack[0] / stack[1] * 100.0
            displayText = fmt(stack[0]); isTypingNumber = false; stackLiftEnabled = true

        // STATS
        case "Σ+":
            if isTypingNumber { commitTyping() }
            statN += 1; statSumX += stack[0]; statSumX2 += stack[0] * stack[0]
            stack[0] = statN; displayText = fmt(statN); isTypingNumber = false; stackLiftEnabled = true
            appendTape(label: "Σ+", result: displayText)

        case "Σ-":
            if isTypingNumber { commitTyping() }
            statN -= 1; statSumX -= stack[0]; statSumX2 -= stack[0] * stack[0]
            stack[0] = statN; displayText = fmt(statN); isTypingNumber = false; stackLiftEnabled = true

        case "x̄":
            guard statN > 0 else { displayText = "Error"; return }
            if isTypingNumber { commitTyping() }
            stack[0] = statSumX / statN
            displayText = fmt(stack[0]); isTypingNumber = false; stackLiftEnabled = true

        // STO / RCL
        case "STO":
            if isTypingNumber { commitTyping() }
            pendingInput = .sto
        case "RCL":
            pendingInput = .rcl

        case "CLΣ":
            statN = 0; statSumX = 0; statSumX2 = 0

        case "LSTx":
            if isTypingNumber { commitTyping() }
            if stackLiftEnabled { pushStack() }
            stack[0] = lastX
            displayText = fmt(lastX)
            isTypingNumber = false; stackLiftEnabled = true

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

    private func binary(_ op: (Double, Double) -> Double) {
        if isTypingNumber { commitTyping() }
        lastX = stack[0]
        let result = op(stack[1], stack[0])
        popStack()
        stack[0] = result; displayText = fmt(result)
        isTypingNumber = false; stackLiftEnabled = true
    }

    // MARK: - TVM Solver

    private enum TVMUnknown {
        case n, i, pv, pmt, fv
        var label: String {
            switch self {
            case .n:   return "n"
            case .i:   return "i"
            case .pv:  return "PV"
            case .pmt: return "PMT"
            case .fv:  return "FV"
            }
        }
    }

    private func solveTVM(_ unknown: TVMUnknown) {
        let n   = tvmN
        let i   = tvmI / 100.0   // convert % to decimal
        let pv  = tvmPV
        let pmt = tvmPMT
        let fv  = tvmFV
        let b   = tvmBEG ? 1.0 : 0.0

        var result: Double

        switch unknown {
        case .pmt:
            if i == 0 {
                guard n != 0 else { displayText = "Error"; return }
                result = -(pv + fv) / n
            } else {
                let f = pow(1.0 + i, n)
                result = -(pv * f + fv) * i / ((f - 1.0) * (1.0 + i * b))
            }
            tvmPMT = result

        case .pv:
            if i == 0 {
                result = -(pmt * n + fv)
            } else {
                let f = pow(1.0 + i, n)
                result = -(pmt * (1.0 + i * b) * (f - 1.0) / i + fv) / f
            }
            tvmPV = result

        case .fv:
            if i == 0 {
                result = -(pv + pmt * n)
            } else {
                let f = pow(1.0 + i, n)
                result = -(pv * f + pmt * (1.0 + i * b) * (f - 1.0) / i)
            }
            tvmFV = result

        case .n:
            if i == 0 {
                guard pmt != 0 else { displayText = "Error"; return }
                result = -(pv + fv) / pmt
            } else {
                let num = -fv * i + pmt * (1.0 + i * b)
                let den =  pv * i + pmt * (1.0 + i * b)
                guard den != 0, (num / den) > 0 else { displayText = "Error"; return }
                result = log(num / den) / log(1.0 + i)
            }
            tvmN = result

        case .i:
            guard let solved = solveForI(n: n, pv: pv, pmt: pmt, fv: fv, b: b) else {
                displayText = "Error"; return
            }
            result = solved * 100.0
            tvmI = result
        }

        stack[0] = result
        displayText = fmt(result)
        isTypingNumber = false; stackLiftEnabled = true
        appendTape(label: unknown.label, result: displayText)
    }

    // Newton-Raphson for interest rate
    private func solveForI(n: Double, pv: Double, pmt: Double, fv: Double, b: Double) -> Double? {
        func f(_ i: Double) -> Double {
            if abs(i) < 1e-10 { return pv + pmt * n + fv }
            let factor = pow(1.0 + i, n)
            return pv * factor + pmt * (1.0 + i * b) * (factor - 1.0) / i + fv
        }

        var i = 0.1
        for _ in 0..<100 {
            let h   = max(abs(i) * 1e-6, 1e-10)
            let dfi = (f(i + h) - f(i - h)) / (2.0 * h)
            guard abs(dfi) > 1e-15 else { break }
            let iNew = i - f(i) / dfi
            if abs(iNew - i) < 1e-10 { return iNew }
            i = max(iNew, -0.9999)
        }
        return f(i).isFinite ? i : nil
    }

    // MARK: - Amortization

    private func solveAMORT() {
        let periods = max(1, Int(stack[0].rounded()))
        guard tvmI != 0 || tvmPMT != 0 else { displayText = "Error"; return }

        var pv = tvmPV
        let i  = tvmI / 100.0
        let pmt = tvmPMT

        var totalInterest = 0.0
        var totalPVChange = 0.0

        for _ in 0..<periods {
            // BEG: payment at start reduces balance before interest accrues
            let interest = tvmBEG ? (pv + pmt) * i : pv * i
            let pvChange = interest + pmt
            totalInterest += interest
            totalPVChange += pvChange
            pv += pvChange
        }

        tvmPV = pv

        // X = interest (negative outflow for borrower), Y = principal (same sign)
        stack[1] = totalPVChange
        stack[0] = -totalInterest
        displayText = fmt(stack[0])
        isTypingNumber = false; stackLiftEnabled = true
        appendTape(label: "INT", result: fmt(-totalInterest))
        appendTape(label: "PRIN", result: fmt(totalPVChange))
        appendTape(label: "BAL", result: fmt(pv))
    }

    // MARK: - Date helpers

    private func hpToDate(_ value: Double) -> Date? {
        let str = String(format: "%.6f", abs(value))
        let parts = str.components(separatedBy: ".")
        guard parts.count == 2, let intPart = Int(parts[0]) else { return nil }
        var frac = parts[1]; while frac.count < 6 { frac += "0" }
        guard frac.count >= 6,
              let twoDigit = Int(frac.prefix(2)),
              let year = Int(frac.suffix(4)), year > 0 else { return nil }
        let month = dateUsFormat ? intPart : twoDigit
        let day   = dateUsFormat ? twoDigit : intPart
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.date(from: DateComponents(year: year, month: month, day: day))
    }

    private func dateToHP(_ date: Date) -> Double {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let c = cal.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 0, m = c.month ?? 0, d = c.day ?? 0
        let a = dateUsFormat ? m : d
        let b = dateUsFormat ? d : m
        return Double(a) + Double(b * 10000 + y) / 1_000_000.0
    }

    private func fmtDate(_ date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let c = cal.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 0, m = c.month ?? 0, d = c.day ?? 0
        return dateUsFormat
            ? String(format: "%d.%02d%04d", m, d, y)
            : String(format: "%d.%02d%04d", d, m, y)
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

    // MARK: - Cash Flow Solvers

    private func expandedFlows() -> [Double] {
        var out: [Double] = []
        for (j, cf) in cfCashFlows.enumerated() {
            let n = j < cfRepeatCounts.count ? cfRepeatCounts[j] : 1
            for _ in 0..<n { out.append(cf) }
        }
        return out
    }

    private func npvAt(rate r: Double, flows: [Double]) -> Double {
        var sum = 0.0
        for (t, cf) in flows.enumerated() {
            sum += t == 0 ? cf : (abs(r) < 1e-12 ? cf : cf / pow(1.0 + r, Double(t)))
        }
        return sum
    }

    private func solveNPV() {
        guard cfCashFlows.count > 1 else { displayText = "Error"; return }
        let r = tvmI / 100.0
        let result = npvAt(rate: r, flows: expandedFlows())
        stack[0] = result
        displayText = fmt(result)
        isTypingNumber = false; stackLiftEnabled = true
        appendTape(label: "NPV", result: displayText)
    }

    private func solveIRR() {
        guard cfCashFlows.count > 1 else { displayText = "Error"; return }
        let flows = expandedFlows()

        func f(_ r: Double) -> Double { npvAt(rate: r, flows: flows) }

        var r = 0.1
        for _ in 0..<300 {
            let h = max(abs(r) * 1e-6, 1e-10)
            let dfdx = (f(r + h) - f(r - h)) / (2.0 * h)
            guard abs(dfdx) > 1e-15 else { break }
            let rNew = r - f(r) / dfdx
            if abs(rNew - r) < 1e-10 { r = rNew; break }
            r = max(rNew, -0.9999)
            if !r.isFinite { r = 0.1 }
        }

        guard r.isFinite else { displayText = "Error"; return }
        let irr = r * 100.0
        tvmI = irr
        stack[0] = irr
        displayText = fmt(irr)
        isTypingNumber = false; stackLiftEnabled = true
        appendTape(label: "IRR", result: displayText)
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
            return String(format: "%.\(max(4, displayDecimalPlaces))g", n)
        }
        return String(format: "%.\(displayDecimalPlaces)f", n)
    }
}
