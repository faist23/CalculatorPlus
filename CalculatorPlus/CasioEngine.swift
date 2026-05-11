import Foundation
import Observation

// MARK: - Mode types

enum CasioMode: Equatable, Hashable {
    case comp, cmplx, stat, baseN, eqn, matrix, table, vector
    var title: String {
        switch self {
        case .comp: return "COMP"
        case .cmplx: return "CMPLX"
        case .stat: return "STAT"
        case .baseN: return "BASE"
        case .eqn: return "EQN"
        case .matrix: return "MAT"
        case .table: return "TABLE"
        case .vector: return "VCT"
        }
    }
}

enum StatSubMode: String, CaseIterable {
    case oneVar = "1-VAR"
    case linReg = "y=a+bx"
    case quadReg = "y=a+bx²"
    case logReg = "y=a+b·lnx"
    case expReg = "y=a·e^bx"
    case powerReg = "y=a·x^b"
    case invReg = "y=a+b/x"
}

enum EqnSubMode: String, CaseIterable {
    case quad  = "ax²+bx+c=0"
    case cubic = "ax³+bx²+cx+d=0"
    case sim2  = "2 unknowns"
    case sim3  = "3 unknowns"
}

enum AngleUnit: String, Equatable {
    case deg = "D", rad = "R", grad = "G"
    func toRadians(_ v: Double) -> Double {
        switch self { case .deg: return v * .pi / 180; case .rad: return v; case .grad: return v * .pi / 200 }
    }
    func fromRadians(_ v: Double) -> Double {
        switch self { case .deg: return v * 180 / .pi; case .rad: return v; case .grad: return v * 200 / .pi }
    }
}

enum BaseRadix: String { case bin = "BIN", oct = "OCT", dec = "DEC", hex = "HEX" }

enum DisplayFmt: Equatable {
    case norm, fix(Int), sci(Int), eng(Int)
}

struct StatPoint: Identifiable { var id = UUID(); var x: Double; var y: Double = 0; var freq: Double = 1 }

// MARK: - CasioEngine

@Observable
final class CasioEngine: CalculatorEngine {

    // MARK: CalculatorEngine
    var displayText: String = "0"
    var displayDecimalPlaces: Int = 10
    var tape: [TapeEntry] = []

    // MARK: View-readable state
    var expression: String   = ""
    var modeLabel: String    = "COMP"
    var angleLabel: String   = "D"
    var hypActive: Bool      = false
    var stoActive: Bool      = false
    var rclActive: Bool      = false

    // MARK: Mode
    var mode: CasioMode = .comp {
        didSet { modeLabel = mode.title; clearInput() }
    }
    var angleUnit: AngleUnit = .deg { didSet { angleLabel = angleUnit.rawValue } }
    var displayFmt: DisplayFmt = .norm
    var baseRadix: BaseRadix = .dec

    // MARK: Memory
    var ans: Double = 0
    var vars: [String: Double] = [:]          // A B C D E F X Y M

    // MARK: STAT
    var statSubMode: StatSubMode = .oneVar
    var statData: [StatPoint] = []
    var statInputX: String = ""
    var statInputY: String = ""
    var statInputFreq: String = "1"
    var statInputPhase: Int = 0               // 0=x 1=y 2=freq

    // MARK: EQN
    var eqnSubMode: EqnSubMode = .quad
    var eqnCoeffs: [Double] = []
    var eqnStep: Int = 0
    var eqnInput: String = ""
    var eqnResults: [String] = []
    var eqnShowResults: Bool = false

    // MARK: Private
    private var hasResult = false
    private var pendingSTO = false
    private var pendingRCL = false

    // MARK: - Dispatch

    func dispatch(_ key: String) {
        // STO / RCL interception
        if pendingSTO {
            pendingSTO = false; stoActive = false
            if validVarName(key) {
                let v = Double(displayText) ?? ans
                vars[key] = v
                tape.append(TapeEntry(label: "→\(key)", result: fmt(v)))
            }
            return
        }
        if pendingRCL {
            pendingRCL = false; rclActive = false
            if key == "Ans" || validVarName(key) {
                let v = key == "Ans" ? ans : (vars[key] ?? 0)
                inject(key, displayValue: fmt(v))
            }
            return
        }
        switch mode {
        case .stat:   dispatchStat(key)
        case .eqn:    dispatchEqn(key)
        case .baseN:  dispatchBaseN(key)
        default:      dispatchComp(key)
        }
    }

    // MARK: - COMP

    private func dispatchComp(_ key: String) {
        switch key {
        case "0","1","2","3","4","5","6","7","8","9":
            if hasResult { expression = ""; hasResult = false }
            expression += key; displayText = expression

        case ".":
            if hasResult { expression = "0"; hasResult = false }
            if !lastToken().contains(".") { expression += "."; displayText = expression }

        case "+","-","×","÷":
            hasResult = false
            guard !expression.isEmpty else { return }
            if let last = expression.last, "+-×÷".contains(last) { expression.removeLast() }
            expression += key; displayText = expression

        case "^":
            guard !expression.isEmpty else { return }
            hasResult = false; expression += "^"; displayText = expression

        case "=": performEval()

        case "AC": clearInput(); hypActive = false

        case "DEL","←":
            if hasResult { clearInput(); return }
            if !expression.isEmpty { expression.removeLast(); displayText = expression.isEmpty ? "0" : expression }

        case "(-)","±":
            if expression.hasPrefix("-") { expression.removeFirst() }
            else if !expression.isEmpty { expression = "-" + expression }
            displayText = expression.isEmpty ? "0" : expression

        case "(":
            if hasResult { expression = ""; hasResult = false }
            expression += "("; displayText = expression

        case ")":
            if !expression.isEmpty { expression += ")"; displayText = expression }

        case "π":
            inject("π", displayValue: fmt(.pi))

        case "e":
            inject("e", displayValue: fmt(M_E))

        case "Ans":
            inject("Ans", displayValue: fmt(ans))

        case "EXP","×10ˣ":
            if hasResult { expression = ""; hasResult = false }
            if expression.isEmpty { expression = "1" }
            expression += "×10^("; displayText = expression

        case "%":
            performEval()
            if let v = Double(displayText) { let r = fmt(v / 100); displayText = r; expression = r }

        case "M+":
            if let v = evaluate(expression) { vars["M"] = (vars["M"] ?? 0) + v
                tape.append(TapeEntry(label: "M+", result: fmt(vars["M"]!))) }
        case "M-":
            if let v = evaluate(expression) { vars["M"] = (vars["M"] ?? 0) - v
                tape.append(TapeEntry(label: "M-", result: fmt(vars["M"]!))) }

        case "STO": pendingSTO = true; stoActive = true
        case "RCL": pendingRCL = true; rclActive = true

        // Trig
        case "sin": insertFn(hypActive ? "sinh" : "sin"); hypActive = false
        case "cos": insertFn(hypActive ? "cosh" : "cos"); hypActive = false
        case "tan": insertFn(hypActive ? "tanh" : "tan"); hypActive = false
        case "sin⁻¹": insertFn(hypActive ? "sinh⁻¹" : "sin⁻¹"); hypActive = false
        case "cos⁻¹": insertFn(hypActive ? "cosh⁻¹" : "cos⁻¹"); hypActive = false
        case "tan⁻¹": insertFn(hypActive ? "tanh⁻¹" : "tan⁻¹"); hypActive = false
        case "HYP": hypActive.toggle()

        // Log / exp
        case "log":   insertFn("log")
        case "ln":    insertFn("ln")
        case "log_b": insertFn("log_b")      // log_b(value,base)
        case "10^x":  if hasResult { expression=""; hasResult=false }
                      expression += "10^("; displayText = expression
        case "e^x":   insertFn("e^")

        // Powers / roots
        case "x²":
            guard let v = evaluate(expression) else { return }
            applyUnary(label: "(\(expression))²", result: v * v)
        case "x³":
            guard let v = evaluate(expression) else { return }
            applyUnary(label: "(\(expression))³", result: v * v * v)
        case "x^y","yˣ":
            guard !expression.isEmpty else { return }
            hasResult = false; expression += "^"; displayText = expression
        case "√","√x": insertFn("√")
        case "³√":     insertFn("³√")
        case "ˣ√","x√y":
            guard !expression.isEmpty else { return }
            hasResult = false; expression += "√("; displayText = expression
        case "1/x","x⁻¹":
            guard let v = evaluate(expression), v != 0 else { displayText = "Math ERROR"; return }
            applyUnary(label: "1/(\(expression))", result: 1.0 / v)

        // Number functions
        case "Abs":    insertFn("Abs")
        case "Int":    insertFn("Int")
        case "Frac":   insertFn("Frac")
        case "Rnd":    insertFn("Rnd")
        case "Ran#":   applyUnary(label: "Ran#", result: Double.random(in: 0..<1))
        case "RanInt#":insertFn("RanInt")
        case "GCD":    insertFn("GCD")
        case "LCM":    insertFn("LCM")
        case "Rem":    insertFn("Rem")

        // Combinatorics
        case "x!","!":
            guard let v = evaluate(expression), v >= 0, v <= 69, v == floor(v) else {
                displayText = "Math ERROR"; return }
            applyUnary(label: "(\(expression))!", result: factorial(Int(v)))
        case "nCr":
            guard !expression.isEmpty else { return }
            hasResult = false; expression += "C"; displayText = expression
        case "nPr":
            guard !expression.isEmpty else { return }
            hasResult = false; expression += "P"; displayText = expression

        // Angle
        case "DRG▸","DRG":
            switch angleUnit { case .deg: angleUnit = .rad; case .rad: angleUnit = .grad; case .grad: angleUnit = .deg }
        case "°","°'\"":
            if !expression.isEmpty { expression += "°"; displayText = expression }

        // Display format
        case "FIX":   displayFmt = .fix(displayDecimalPlaces)
        case "SCI":   displayFmt = .sci(displayDecimalPlaces)
        case "ENG":   displayFmt = .eng(displayDecimalPlaces)
        case "NORM":  displayFmt = .norm

        default:
            // Variable names A-F X Y M
            if validVarName(key) {
                let v = vars[key] ?? 0
                inject(key, displayValue: fmt(v))
            }
        }
    }

    // MARK: - Helpers

    private func inject(_ label: String, displayValue: String) {
        if hasResult { expression = ""; hasResult = false }
        expression += label; displayText = displayValue
    }

    private func insertFn(_ name: String) {
        if hasResult { expression = ""; hasResult = false }
        expression += "\(name)("; displayText = expression
    }

    private func clearInput() {
        expression = ""; displayText = "0"; hasResult = false
    }

    private func validVarName(_ k: String) -> Bool {
        ["A","B","C","D","E","F","X","Y","M"].contains(k)
    }

    private func lastToken() -> String {
        var token = expression
        for op in ["+","-","×","÷","(","^","E","P","C"] {
            if let r = expression.range(of: op, options: .backwards) {
                let after = String(expression[r.upperBound...])
                if !after.isEmpty { token = after }
            }
        }
        return token
    }

    private func performEval() {
        guard !expression.isEmpty else { return }
        guard let v = evaluate(expression) else { displayText = "Math ERROR"; return }
        let r = fmt(v)
        tape.append(TapeEntry(label: expression, result: r))
        ans = v; expression = r; displayText = r; hasResult = true
    }

    private func applyUnary(label: String, result: Double) {
        let r = fmt(result)
        tape.append(TapeEntry(label: label, result: r))
        ans = result; expression = r; displayText = r; hasResult = true
    }

    // MARK: - Evaluate (substitutes variables then runs parser)

    private func evaluate(_ raw: String) -> Double? {
        var s = raw
        s = s.replacingOccurrences(of: "Ans", with: "(\(fmt(ans)))")
        for (k, v) in vars { s = s.replacingOccurrences(of: k, with: "(\(fmt(v)))") }
        var p = ExprParser(input: s, angle: angleUnit)
        guard let result = p.parseExpr(), p.atEnd else { return nil }
        return result.isFinite ? result : nil
    }

    // MARK: - STAT dispatch

    private func dispatchStat(_ key: String) {
        switch key {
        case "AC":
            statData = []; statInputX = ""; statInputY = ""; statInputFreq = "1"
            statInputPhase = 0; displayText = "n=0"; expression = "STAT"
        case "DEL","←":
            switch statInputPhase {
            case 0: if !statInputX.isEmpty { statInputX.removeLast() }; displayText = statInputX.isEmpty ? "0" : statInputX
            case 1: if !statInputY.isEmpty { statInputY.removeLast() }; displayText = statInputY.isEmpty ? "0" : statInputY
            default: if !statInputFreq.isEmpty { statInputFreq.removeLast() }; displayText = statInputFreq.isEmpty ? "1" : statInputFreq
            }
        case "=","DT","M+","Σ+":
            commitStat()
        case "CL","Σ−":
            if !statData.isEmpty { statData.removeLast(); displayText = "n=\(statN)" }
        default:
            if "0123456789.".contains(key) || (key == "-" && statInputX.isEmpty && statInputPhase == 0) {
                switch statInputPhase {
                case 0: statInputX += key; displayText = statInputX
                case 1: statInputY += key; displayText = statInputY
                default: statInputFreq += key; displayText = statInputFreq
                }
            }
        }
    }

    private func commitStat() {
        let isBI = statSubMode != .oneVar
        if isBI && statInputPhase == 0 {
            statInputPhase = 1; displayText = statInputY.isEmpty ? "0" : statInputY; return
        }
        guard let x = Double(statInputX.isEmpty ? "0" : statInputX) else { return }
        let y = Double(statInputY.isEmpty ? "0" : statInputY) ?? 0
        let freq = Double(statInputFreq.isEmpty ? "1" : statInputFreq) ?? 1
        statData.append(StatPoint(x: x, y: y, freq: freq))
        statInputX = ""; statInputY = ""; statInputFreq = "1"; statInputPhase = 0
        displayText = "n=\(statN)"
    }

    private var statN: Int { Int(statData.map(\.freq).reduce(0, +)) }

    func statResult(_ key: String) -> Double? {
        guard !statData.isEmpty else { return nil }
        let pts = statData.flatMap { p in Array(repeating: (p.x, p.y), count: max(1, Int(p.freq))) }
        let xs = pts.map(\.0), ys = pts.map(\.1)
        let n = Double(xs.count)
        let sx = xs.reduce(0,+), sx2 = xs.map{$0*$0}.reduce(0,+)
        let sy = ys.reduce(0,+), sy2 = ys.map{$0*$0}.reduce(0,+)
        let sxy = zip(xs,ys).map(*).reduce(0,+)
        let xm = sx/n, ym = sy/n
        switch key {
        case "n":   return n
        case "Σx":  return sx
        case "Σx²": return sx2
        case "Σy":  return sy
        case "Σy²": return sy2
        case "Σxy": return sxy
        case "x̄":   return xm
        case "ȳ":   return ym
        case "σx":  return sqrt(sx2/n - xm*xm)
        case "Sx":  return n>1 ? sqrt((sx2 - n*xm*xm)/(n-1)) : nil
        case "σy":  return sqrt(sy2/n - ym*ym)
        case "Sy":  return n>1 ? sqrt((sy2 - n*ym*ym)/(n-1)) : nil
        case "minX":return xs.min()
        case "maxX":return xs.max()
        case "a":   return linReg(xs,ys).a
        case "b":   return linReg(xs,ys).b
        case "r":   return linReg(xs,ys).r
        default:    return nil
        }
    }

    private func linReg(_ xs:[Double],_ ys:[Double]) -> (a:Double,b:Double,r:Double) {
        let n = Double(xs.count)
        let sx = xs.reduce(0,+), sy = ys.reduce(0,+)
        let sx2 = xs.map{$0*$0}.reduce(0,+), sy2 = ys.map{$0*$0}.reduce(0,+)
        let sxy = zip(xs,ys).map(*).reduce(0,+)
        let b = (n*sxy - sx*sy) / (n*sx2 - sx*sx)
        let a = (sy - b*sx) / n
        let denom = sqrt((n*sx2-sx*sx) * (n*sy2-sy*sy))
        let r = denom == 0 ? 0 : (n*sxy - sx*sy) / denom
        return (a, b, r)
    }

    // MARK: - EQN dispatch

    private func dispatchEqn(_ key: String) {
        if eqnShowResults {
            if key == "AC" { eqnShowResults = false; resetEqn() }
            return
        }
        switch key {
        case "AC": resetEqn()
        case "DEL","←":
            if !eqnInput.isEmpty { eqnInput.removeLast()
                displayText = eqnInput.isEmpty ? "0" : eqnInput }
        case "=":
            eqnCoeffs[eqnStep] = Double(eqnInput) ?? 0
            eqnInput = ""
            eqnStep += 1
            if eqnStep >= eqnCoeffCount { solveEqn() }
            else { displayText = eqnPrompt(eqnStep) }
        default:
            if "0123456789.".contains(key) || (key == "-" && eqnInput.isEmpty) {
                eqnInput += key; displayText = eqnInput
            }
        }
    }

    private func resetEqn() {
        eqnCoeffs = Array(repeating: 0, count: eqnCoeffCount)
        eqnStep = 0; eqnInput = ""
        displayText = eqnPrompt(0); expression = "EQN"
    }

    private var eqnCoeffCount: Int {
        switch eqnSubMode { case .quad: return 3; case .cubic: return 4; case .sim2: return 6; case .sim3: return 12 }
    }

    private func eqnPrompt(_ i: Int) -> String {
        let q = ["a=?","b=?","c=?"]
        let cu = ["a=?","b=?","c=?","d=?"]
        let s2 = ["a₁=?","b₁=?","c₁=?","a₂=?","b₂=?","c₂=?"]
        let s3 = ["a₁=?","b₁=?","c₁=?","d₁=?","a₂=?","b₂=?","c₂=?","d₂=?","a₃=?","b₃=?","c₃=?","d₃=?"]
        switch eqnSubMode {
        case .quad:  return q[safe: i] ?? ""
        case .cubic: return cu[safe: i] ?? ""
        case .sim2:  return s2[safe: i] ?? ""
        case .sim3:  return s3[safe: i] ?? ""
        }
    }

    private func solveEqn() {
        switch eqnSubMode {
        case .quad:
            let a=eqnCoeffs[0], b=eqnCoeffs[1], c=eqnCoeffs[2]
            let d=b*b-4*a*c
            if d >= 0 {
                eqnResults = ["x₁=\(fmt((-b+sqrt(d))/(2*a)))", "x₂=\(fmt((-b-sqrt(d))/(2*a)))"]
            } else {
                let re = -b/(2*a), im = sqrt(-d)/(2*a)
                eqnResults = ["x₁=\(fmt(re))+\(fmt(im))i", "x₂=\(fmt(re))-\(fmt(im))i"]
            }
        case .cubic:
            eqnResults = solveCubic(eqnCoeffs[0], eqnCoeffs[1], eqnCoeffs[2], eqnCoeffs[3])
        case .sim2:
            let c=eqnCoeffs
            let det=c[0]*c[4]-c[1]*c[3]
            if abs(det)<1e-12 { eqnResults=["No solution"]; break }
            eqnResults=["x=\(fmt((c[2]*c[4]-c[1]*c[5])/det))","y=\(fmt((c[0]*c[5]-c[2]*c[3])/det))"]
        case .sim3:
            eqnResults = solveLinear3(eqnCoeffs)
        }
        eqnShowResults = true
        tape.append(TapeEntry(label: eqnSubMode.rawValue, result: eqnResults.joined(separator: " ")))
        displayText = eqnResults.first ?? "Error"
        expression = eqnSubMode.rawValue
    }

    private func solveCubic(_ a:Double,_ b:Double,_ c:Double,_ d:Double) -> [String] {
        guard a != 0 else { return ["a≠0 required"] }
        let p=(3*a*c-b*b)/(3*a*a), q=(2*b*b*b-9*a*b*c+27*a*a*d)/(27*a*a*a)
        let disc=q*q/4+p*p*p/27
        let off = -b/(3*a)
        if disc > 1e-12 {
            let sq=sqrt(disc)
            let u=cbrt(-q/2+sq), v=cbrt(-q/2-sq)
            return ["x₁=\(fmt(u+v+off))"]
        } else if disc > -1e-12 {
            let u=cbrt(-q/2)
            return ["x₁=\(fmt(2*u+off))","x₂=\(fmt(-u+off))"]
        } else {
            let m=2*sqrt(-p/3), th=acos(3*q/(p*m))/3
            return ["x₁=\(fmt(m*cos(th)+off))","x₂=\(fmt(m*cos(th-2*Double.pi/3)+off))","x₃=\(fmt(m*cos(th-4*Double.pi/3)+off))"]
        }
    }

    private func solveLinear3(_ c:[Double]) -> [String] {
        guard c.count >= 12 else { return ["Input error"] }
        var m=[[c[0],c[1],c[2],c[3]],[c[4],c[5],c[6],c[7]],[c[8],c[9],c[10],c[11]]]
        for col in 0..<3 {
            var maxR=col
            for r in (col+1)..<3 { if abs(m[r][col])>abs(m[maxR][col]) { maxR=r } }
            m.swapAt(col,maxR)
            guard abs(m[col][col])>1e-12 else { return ["No unique solution"] }
            for r in (col+1)..<3 {
                let f=m[r][col]/m[col][col]
                for j in col..<4 { m[r][j]-=f*m[col][j] }
            }
        }
        var x=[0.0,0.0,0.0]
        for i in stride(from:2,through:0,by:-1) {
            x[i]=m[i][3]
            for j in (i+1)..<3 { x[i]-=m[i][j]*x[j] }
            x[i]/=m[i][i]
        }
        return ["x=\(fmt(x[0]))","y=\(fmt(x[1]))","z=\(fmt(x[2]))"]
    }

    // MARK: - BASE-N dispatch

    private func dispatchBaseN(_ key: String) {
        switch key {
        case "BIN","OCT","DEC","HEX":
            let cur = Int(displayText, radix: radixBase(baseRadix)) ?? 0
            if let r = BaseRadix(rawValue: key) {
                baseRadix = r; displayText = String(cur, radix: radixBase(r)).uppercased()
            }
        case "AC": displayText = "0"; expression = ""
        case "DEL","←":
            if displayText.count > 1 { displayText.removeLast() } else { displayText = "0" }
        case "and","or","xor","not","neg":
            expression += " \(key) "; displayText = expression
        case "=":
            // evaluate base-N expression (simplified: just passthrough for now)
            displayText = displayText
        default:
            let valid: Set<String>
            switch baseRadix {
            case .bin: valid=["0","1"]
            case .oct: valid=["0","1","2","3","4","5","6","7"]
            case .dec: valid=["0","1","2","3","4","5","6","7","8","9"]
            case .hex: valid=["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
            }
            if valid.contains(key.uppercased()) {
                if displayText == "0" { displayText = "" }
                displayText += key.uppercased(); expression = displayText
            }
        }
    }

    private func radixBase(_ r: BaseRadix) -> Int {
        switch r { case .bin: return 2; case .oct: return 8; case .dec: return 10; case .hex: return 16 }
    }

    // MARK: - Format

    func fmt(_ n: Double) -> String {
        guard n.isFinite else { return "Math ERROR" }
        switch displayFmt {
        case .fix(let d): return String(format: "%.\(d)f", n)
        case .sci(let d): return String(format: "%.\(d)E", n)
        case .eng(let d):
            let e = n == 0 ? 0 : Int(floor(log10(abs(n))/3))*3
            return String(format: "%.\(d)f×10^\(e)", n/pow(10,Double(e)))
        default:
            let a = Swift.abs(n)
            if a >= 1e10 || (a < 1e-4 && a != 0) { return String(format: "%.9g", n) }
            var s = String(format: "%.10f", n)
            while s.hasSuffix("0") { s.removeLast() }
            if s.hasSuffix(".") { s.removeLast() }
            return s
        }
    }

    private func factorial(_ n: Int) -> Double {
        guard n >= 0, n <= 69 else { return .nan }
        return n <= 1 ? 1 : Double(n) * factorial(n - 1)
    }

    func recallTapeValue(_ v: Double) { let s=fmt(v); expression=s; displayText=s; hasResult=false }
}

// MARK: - Safe subscript
private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

// MARK: - Recursive Descent Parser

private enum Tok {
    case num(Double), op(String), fn(String), lp, rp, comma, bang
}

private struct ExprParser {
    var toks: [Tok]
    var pos:  Int = 0
    let angle: AngleUnit

    var atEnd: Bool { pos >= toks.count }
    var cur: Tok?   { pos < toks.count ? toks[pos] : nil }

    init(input: String, angle: AngleUnit) {
        self.toks  = ExprParser.tokenize(input)
        self.angle = angle
    }

    // expression = additive
    mutating func parseExpr() -> Double? { parseAdd() }

    // additive = mul (('+' | '-') mul)*
    mutating func parseAdd() -> Double? {
        guard var L = parseMul() else { return nil }
        while let t = cur, case .op(let c) = t, c == "+" || c == "-" {
            pos += 1
            guard let R = parseMul() else { return nil }
            L = c == "+" ? L + R : L - R
        }
        return L
    }

    // mul = comb (('×' | '÷' | implicit) comb)*
    mutating func parseMul() -> Double? {
        guard var L = parseComb() else { return nil }
        loop: while let t = cur {
            switch t {
            case .op(let c) where c == "×" || c == "÷":
                pos += 1
                guard let R = parseComb() else { return nil }
                if c == "÷" { guard R != 0 else { return nil }; L = L / R } else { L = L * R }
            case .num, .fn, .lp:          // implicit multiply: 2sin(x), 2(x+1)
                guard let R = parseComb() else { return nil }
                L = L * R
            default: break loop
            }
        }
        return L
    }

    // comb = pow (('C'|'P') pow)*
    mutating func parseComb() -> Double? {
        guard var L = parsePow() else { return nil }
        while let t = cur, case .op(let c) = t, c == "C" || c == "P" {
            pos += 1
            guard let R = parsePow() else { return nil }
            let n = Int(L), r = Int(R)
            L = c == "C" ? comb(n, r) : perm(n, r)
        }
        return L
    }

    // pow = post ('^' unary)?   right-associative
    mutating func parsePow() -> Double? {
        guard let base = parsePost() else { return nil }
        if let t = cur, case .op(let c) = t, c == "^" {
            pos += 1
            guard let exp = parseUnary() else { return nil }
            return pow(base, exp)
        }
        return base
    }

    // post = unary ('!')*
    mutating func parsePost() -> Double? {
        guard var v = parseUnary() else { return nil }
        while let t = cur, case .bang = t {
            pos += 1
            guard v >= 0 && v <= 69 && v == floor(v) else { return nil }
            let n = Int(v); v = (1...max(1,n)).map(Double.init).reduce(1, *)
        }
        return v
    }

    // unary = '-' post | primary
    mutating func parseUnary() -> Double? {
        if let t = cur, case .op(let c) = t, c == "-" { pos += 1
            guard let v = parsePost() else { return nil }; return -v }
        return parsePrimary()
    }

    mutating func parsePrimary() -> Double? {
        guard let t = cur else { return nil }
        switch t {
        case .num(let v): pos += 1; return v
        case .lp:
            pos += 1
            guard let v = parseExpr() else { return nil }
            if let c = cur, case .rp = c { pos += 1 }
            return v
        case .fn(let name):
            pos += 1
            guard let c = cur, case .lp = c else { return nil }; pos += 1
            guard let a1 = parseExpr() else { return nil }
            var a2: Double? = nil
            if let c2 = cur, case .comma = c2 { pos += 1; a2 = parseExpr() }
            if let c3 = cur, case .rp = c3 { pos += 1 }
            return applyFn(name, a1, a2)
        default: return nil
        }
    }

    // MARK: Function application

    private func applyFn(_ name: String, _ a: Double, _ b: Double?) -> Double? {
        let rad = angle.toRadians(a)
        switch name {
        case "sin":    return sin(rad)
        case "cos":    return cos(rad)
        case "tan":    guard abs(cos(rad)) > 1e-10 else { return nil }; return tan(rad)
        case "sin⁻¹","arcsin","asin": guard abs(a)<=1 else{return nil}; return angle.fromRadians(asin(a))
        case "cos⁻¹","arccos","acos": guard abs(a)<=1 else{return nil}; return angle.fromRadians(acos(a))
        case "tan⁻¹","arctan","atan": return angle.fromRadians(atan(a))
        case "sinh":   return sinh(a)
        case "cosh":   return cosh(a)
        case "tanh":   return tanh(a)
        case "sinh⁻¹": return log(a + sqrt(a*a+1))
        case "cosh⁻¹": guard a>=1 else{return nil}; return log(a+sqrt(a*a-1))
        case "tanh⁻¹": guard abs(a)<1 else{return nil}; return 0.5*log((1+a)/(1-a))
        case "log":    guard a>0 else{return nil}; return log10(a)
        case "ln":     guard a>0 else{return nil}; return log(a)
        case "log_b":  guard let base=b, a>0, base>0, base != 1 else{return nil}; return log(a)/log(base)
        case "e^":     return exp(a)
        case "10^":    return pow(10, a)
        case "√","sqrt": guard a>=0 else{return nil}; return sqrt(a)
        case "³√","cbrt": return cbrt(a)
        case "Abs","abs": return Swift.abs(a)
        case "Int":    return a>=0 ? floor(a) : ceil(a)
        case "Frac":   return a - (a>=0 ? floor(a) : ceil(a))
        case "Rnd":    return Double.random(in: 0..<1)
        case "GCD":    guard let b else{return nil}; return Double(gcd(Int(Swift.abs(a)),Int(Swift.abs(b))))
        case "LCM":
            guard let b else{return nil}
            let g=gcd(Int(Swift.abs(a)),Int(Swift.abs(b)))
            return g==0 ? 0 : Double(Int(Swift.abs(a))/g * Int(Swift.abs(b)))
        case "Rem":    guard let b, b != 0 else{return nil}; return a.truncatingRemainder(dividingBy: b)
        case "RanInt","RandInt":
            guard let b else{return nil}; return Double(Int.random(in: Int(a)...Int(b)))
        default: return nil
        }
    }

    // MARK: Combinatorics helpers
    private func comb(_ n: Int, _ r: Int) -> Double {
        guard r>=0, r<=n else { return 0 }
        let r=min(r,n-r); var v=1.0
        for i in 0..<r { v=v*Double(n-i)/Double(i+1) }
        return v
    }
    private func perm(_ n: Int, _ r: Int) -> Double {
        guard r>=0, r<=n else { return 0 }
        var v=1.0; for i in 0..<r { v*=Double(n-i) }; return v
    }
    private func gcd(_ a: Int, _ b: Int) -> Int { b==0 ? a : gcd(b, a%b) }

    // MARK: Tokenizer

    static func tokenize(_ input: String) -> [Tok] {
        // Function names — longer ones must come first
        let fns = [
            "sinh⁻¹","cosh⁻¹","tanh⁻¹","sin⁻¹","cos⁻¹","tan⁻¹",
            "sinh","cosh","tanh","sin","cos","tan",
            "log_b","log","ln","e^","10^",
            "³√","√","Abs","abs","Int","Frac","Rnd",
            "GCD","LCM","Rem","RanInt","RandInt"
        ]
        var toks: [Tok] = []
        var i = input.startIndex

        while i < input.endIndex {
            let c = input[i]
            if c.isWhitespace { i = input.index(after: i); continue }

            // Function names
            var matched = false
            for fn in fns {
                if input[i...].hasPrefix(fn) {
                    toks.append(.fn(fn))
                    i = input.index(i, offsetBy: fn.count)
                    matched = true; break
                }
            }
            if matched { continue }

            // Named constants
            if input[i...].hasPrefix("π") {
                toks.append(.num(.pi)); i = input.index(i, offsetBy: 1); continue
            }
            if input[i...].hasPrefix("e") && (i == input.startIndex || !input[input.index(before:i)].isNumber) {
                // "e" as Euler's constant (not inside scientific notation like 1.5e10)
                toks.append(.num(M_E)); i = input.index(i, offsetBy: 1); continue
            }

            // Number (digits + optional decimal + optional E-notation)
            if c.isNumber || c == "." {
                var ns = ""
                while i < input.endIndex && (input[i].isNumber || input[i] == ".") {
                    ns.append(input[i]); i = input.index(after: i)
                }
                if i < input.endIndex && (input[i] == "E" || input[i] == "e") {
                    ns.append(input[i]); i = input.index(after: i)
                    if i < input.endIndex && (input[i] == "+" || input[i] == "-") {
                        ns.append(input[i]); i = input.index(after: i)
                    }
                    while i < input.endIndex && input[i].isNumber {
                        ns.append(input[i]); i = input.index(after: i)
                    }
                }
                if let v = Double(ns) { toks.append(.num(v)) }
                continue
            }

            // Single-char tokens
            switch c {
            case "+": toks.append(.op("+"))
            case "-": toks.append(.op("-"))
            case "×","*": toks.append(.op("×"))
            case "÷","/": toks.append(.op("÷"))
            case "^":     toks.append(.op("^"))
            case "C":     toks.append(.op("C"))
            case "P":     toks.append(.op("P"))
            case "(":     toks.append(.lp)
            case ")":     toks.append(.rp)
            case ",":     toks.append(.comma)
            case "!":     toks.append(.bang)
            default: break
            }
            i = input.index(after: i)
        }
        return toks
    }
}
