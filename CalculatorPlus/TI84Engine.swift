import Foundation
import Observation

// MARK: - Supporting types

enum TI84Screen: Equatable {
    case home, yEditor, graph, windowEditor, table, statEditor, matrixEditor, modeEditor
}

enum TI84AngleMode { case degree, radian }

enum TI84MatPhase { case dimEdit, fill, ops }

struct TIHomeLine: Identifiable {
    let id = UUID()
    var expr: String
    var result: String
    var isError: Bool
    var isResult: Bool
}

// MARK: - Error types

enum CalcError: Error { case syntax, domain, dimension, singular }

// MARK: - Token type

private enum TIToken: Equatable {
    case number(Double)
    case ident(String)
    case op(Character)
    case lparen, rparen, comma, end

    static func == (lhs: TIToken, rhs: TIToken) -> Bool {
        switch (lhs, rhs) {
        case (.number(let a), .number(let b)): return a == b
        case (.ident(let a), .ident(let b)): return a == b
        case (.op(let a), .op(let b)): return a == b
        case (.lparen, .lparen): return true
        case (.rparen, .rparen): return true
        case (.comma, .comma): return true
        case (.end, .end): return true
        default: return false
        }
    }
}

// MARK: - Tokenizer

private struct Tokenizer {
    let source: [Character]
    var pos: Int = 0

    init(_ s: String) {
        self.source = Array(s)
    }

    var isAtEnd: Bool { pos >= source.count }

    private func char(at i: Int) -> Character? {
        guard i < source.count else { return nil }
        return source[i]
    }

    mutating func peek() -> TIToken {
        var copy = self
        return copy.next()
    }

    mutating func next() -> TIToken {
        // Skip whitespace
        while pos < source.count && source[pos].isWhitespace {
            pos += 1
        }
        guard pos < source.count else { return .end }

        let c = source[pos]

        // (−) or (-) unary minus marker
        if c == "(" {
            // Check for (−) or (-)
            if pos + 2 < source.count {
                let c1 = source[pos + 1]
                let c2 = source[pos + 2]
                if c2 == ")" && (c1 == "-" || c1 == "\u{2212}" || c1 == "−") {
                    pos += 3
                    return .op("~")
                }
            }
            pos += 1
            return .lparen
        }

        // Superscript suffix operators
        // ⁻¹ (two unicode chars: U+207B U+00B9)
        if c == "\u{207B}" {
            // Could be ⁻¹
            if pos + 1 < source.count && source[pos + 1] == "\u{00B9}" {
                pos += 2
                return .op("⁻")
            }
            pos += 1
            return .op("⁻")
        }

        // ² U+00B2
        if c == "\u{00B2}" {
            pos += 1
            return .op("²")
        }

        // √ → sqrt ident
        if c == "√" {
            pos += 1
            return .ident("sqrt")
        }

        // × and ÷
        if c == "×" { pos += 1; return .op("×") }
        if c == "÷" { pos += 1; return .op("÷") }

        // ᴱ (scientific notation marker, treat as e)
        if c == "\u{1D31}" {
            pos += 1
            return .op("E")
        }

        // Numbers (ASCII digits only — isNumber matches superscripts like ² which are separate ops)
        if c.isASCII && (c.isNumber || c == ".") {
            var numStr = ""
            while pos < source.count && source[pos].isASCII && (source[pos].isNumber || source[pos] == ".") {
                numStr.append(source[pos])
                pos += 1
            }
            // Handle e/E notation
            if pos < source.count && (source[pos] == "e" || source[pos] == "E") {
                let savedPos = pos
                numStr.append(source[pos])
                pos += 1
                if pos < source.count && (source[pos] == "+" || source[pos] == "-" || source[pos] == "\u{2212}") {
                    let sign = source[pos] == "\u{2212}" ? "-" : String(source[pos])
                    numStr.append(contentsOf: sign)
                    pos += 1
                }
                if pos < source.count && source[pos].isASCII && source[pos].isNumber {
                    while pos < source.count && source[pos].isASCII && source[pos].isNumber {
                        numStr.append(source[pos])
                        pos += 1
                    }
                } else {
                    // Not a valid exponent — backtrack
                    pos = savedPos
                    numStr.removeLast()
                }
            }
            return .number(Double(numStr) ?? 0)
        }

        // π
        if c == "π" { pos += 1; return .ident("π") }

        // Letters / identifiers — greedy match in priority order
        if c.isLetter || c == "A" {
            // Build remaining string from current position for prefix matching
            let remaining = String(source[pos...])

            let keywords: [(String, TIToken)] = [
                ("sin⁻¹", .ident("sin⁻¹")),
                ("cos⁻¹", .ident("cos⁻¹")),
                ("tan⁻¹", .ident("tan⁻¹")),
                ("iPart",  .ident("iPart")),
                ("fPart",  .ident("fPart")),
                ("round",  .ident("round")),
                ("sqrt",   .ident("sqrt")),
                ("sin",    .ident("sin")),
                ("cos",    .ident("cos")),
                ("tan",    .ident("tan")),
                ("ln",     .ident("ln")),
                ("log",    .ident("log")),
                ("abs",    .ident("abs")),
                ("int",    .ident("int")),
                ("max",    .ident("max")),
                ("min",    .ident("min")),
                ("nPr",    .ident("nPr")),
                ("nCr",    .ident("nCr")),
                ("Ans",    .ident("Ans")),
            ]

            for (kw, tok) in keywords {
                if remaining.hasPrefix(kw) {
                    pos += kw.count
                    return tok
                }
            }

            // Single letter
            let letter = String(c)
            pos += 1
            return .ident(letter)
        }

        // Single-character operators and punctuation
        switch c {
        case ")": pos += 1; return .rparen
        case ",": pos += 1; return .comma
        case "+", "-", "*", "/", "^": pos += 1; return .op(c)
        case "\u{2212}": pos += 1; return .op("-") // unicode minus
        default:
            pos += 1
            return .op(c)
        }
    }
}

// MARK: - Recursive-descent parser

private func parseExpr(_ tok: inout Tokenizer, engine: TI84Engine) throws -> Double {
    let val = try parseAddSub(&tok, engine: engine)
    return val
}

private func parseAddSub(_ tok: inout Tokenizer, engine: TI84Engine) throws -> Double {
    var lhs = try parseMulDiv(&tok, engine: engine)
    while true {
        let pk = tok.peek()
        if case .op(let c) = pk, c == "+" || c == "-" {
            _ = tok.next()
            let rhs = try parseMulDiv(&tok, engine: engine)
            lhs = (c == "+") ? lhs + rhs : lhs - rhs
        } else {
            break
        }
    }
    return lhs
}

private func parseMulDiv(_ tok: inout Tokenizer, engine: TI84Engine) throws -> Double {
    var lhs = try parseImplicit(&tok, engine: engine)
    while true {
        let pk = tok.peek()
        if case .op(let c) = pk, c == "×" || c == "*" || c == "÷" || c == "/" {
            _ = tok.next()
            let rhs = try parseImplicit(&tok, engine: engine)
            if c == "×" || c == "*" {
                lhs *= rhs
            } else {
                guard rhs != 0 else { throw CalcError.domain }
                lhs /= rhs
            }
        } else {
            break
        }
    }
    return lhs
}

private func parseImplicit(_ tok: inout Tokenizer, engine: TI84Engine) throws -> Double {
    var lhs = try parseUnary(&tok, engine: engine)
    // Implicit multiplication: next token starts a new primary (number, ident, lparen)
    while true {
        let pk = tok.peek()
        switch pk {
        case .number, .ident, .lparen:
            let rhs = try parseUnary(&tok, engine: engine)
            lhs *= rhs
        default:
            return lhs
        }
    }
}

private func parseUnary(_ tok: inout Tokenizer, engine: TI84Engine) throws -> Double {
    let pk = tok.peek()
    if case .op(let c) = pk, c == "-" || c == "~" {
        _ = tok.next()
        return try -parseUnary(&tok, engine: engine)
    }
    return try parsePower(&tok, engine: engine)
}

private func parsePower(_ tok: inout Tokenizer, engine: TI84Engine) throws -> Double {
    let base = try parsePostfix(&tok, engine: engine)
    let pk = tok.peek()
    if case .op(let c) = pk, c == "^" {
        _ = tok.next()
        let exp = try parseUnary(&tok, engine: engine)
        return pow(base, exp)
    }
    return base
}

private func parsePostfix(_ tok: inout Tokenizer, engine: TI84Engine) throws -> Double {
    var val = try parsePrimary(&tok, engine: engine)
    while true {
        let pk = tok.peek()
        if case .op(let c) = pk {
            if c == "²" {
                _ = tok.next()
                val = val * val
            } else if c == "⁻" {
                _ = tok.next()
                val = 1.0 / val
            } else {
                break
            }
        } else {
            break
        }
    }
    return val
}

private func parsePrimary(_ tok: inout Tokenizer, engine: TI84Engine) throws -> Double {
    let t = tok.next()
    switch t {
    case .number(let v):
        return v
    case .ident(let name):
        return try resolveIdent(name, &tok, engine: engine)
    case .lparen:
        let val = try parseExpr(&tok, engine: engine)
        let closing = tok.next()
        guard case .rparen = closing else { throw CalcError.syntax }
        return val
    default:
        throw CalcError.syntax
    }
}

private func parseOneArg(_ tok: inout Tokenizer, engine: TI84Engine) throws -> Double {
    let lp = tok.next()
    guard case .lparen = lp else { throw CalcError.syntax }
    let val = try parseExpr(&tok, engine: engine)
    let rp = tok.next()
    guard case .rparen = rp else { throw CalcError.syntax }
    return val
}

private func parseTwoArgs(_ tok: inout Tokenizer, engine: TI84Engine) throws -> (Double, Double) {
    let lp = tok.next()
    guard case .lparen = lp else { throw CalcError.syntax }
    let a = try parseExpr(&tok, engine: engine)
    let cm = tok.next()
    guard case .comma = cm else { throw CalcError.syntax }
    let b = try parseExpr(&tok, engine: engine)
    let rp = tok.next()
    guard case .rparen = rp else { throw CalcError.syntax }
    return (a, b)
}

private func resolveIdent(_ name: String, _ tok: inout Tokenizer, engine: TI84Engine) throws -> Double {
    let deg = engine.angleMode == .degree
    let toRad = Double.pi / 180.0
    let toDeg = 180.0 / Double.pi

    switch name {
    case "sin":
        let x = try parseOneArg(&tok, engine: engine)
        return sin(deg ? x * toRad : x)
    case "cos":
        let x = try parseOneArg(&tok, engine: engine)
        return cos(deg ? x * toRad : x)
    case "tan":
        let x = try parseOneArg(&tok, engine: engine)
        let r = deg ? x * toRad : x
        return tan(r)
    case "sin⁻¹":
        let x = try parseOneArg(&tok, engine: engine)
        guard x >= -1 && x <= 1 else { throw CalcError.domain }
        return asin(x) * (deg ? toDeg : 1)
    case "cos⁻¹":
        let x = try parseOneArg(&tok, engine: engine)
        guard x >= -1 && x <= 1 else { throw CalcError.domain }
        return acos(x) * (deg ? toDeg : 1)
    case "tan⁻¹":
        let x = try parseOneArg(&tok, engine: engine)
        return atan(x) * (deg ? toDeg : 1)
    case "ln":
        let x = try parseOneArg(&tok, engine: engine)
        guard x > 0 else { throw CalcError.domain }
        return log(x)
    case "log":
        let x = try parseOneArg(&tok, engine: engine)
        guard x > 0 else { throw CalcError.domain }
        return log10(x)
    case "sqrt":
        let x = try parseOneArg(&tok, engine: engine)
        guard x >= 0 else { throw CalcError.domain }
        return sqrt(x)
    case "abs":
        let x = try parseOneArg(&tok, engine: engine)
        return abs(x)
    case "int":
        let x = try parseOneArg(&tok, engine: engine)
        return trunc(x)
    case "iPart":
        let x = try parseOneArg(&tok, engine: engine)
        return trunc(x)
    case "fPart":
        let x = try parseOneArg(&tok, engine: engine)
        return x - trunc(x)
    case "round":
        let (v, d) = try parseTwoArgs(&tok, engine: engine)
        let factor = pow(10.0, d)
        return round(v * factor) / factor
    case "max":
        let (a, b) = try parseTwoArgs(&tok, engine: engine)
        return Swift.max(a, b)
    case "min":
        let (a, b) = try parseTwoArgs(&tok, engine: engine)
        return Swift.min(a, b)
    case "nPr":
        let (n, r) = try parseTwoArgs(&tok, engine: engine)
        let ni = Int(n), ri = Int(r)
        guard ni >= 0 && ri >= 0 && ri <= ni else { throw CalcError.domain }
        return Double(factorial(ni) / factorial(ni - ri))
    case "nCr":
        let (n, r) = try parseTwoArgs(&tok, engine: engine)
        let ni = Int(n), ri = Int(r)
        guard ni >= 0 && ri >= 0 && ri <= ni else { throw CalcError.domain }
        return Double(factorial(ni) / (factorial(ri) * factorial(ni - ri)))
    case "e^":
        let x = try parseOneArg(&tok, engine: engine)
        return exp(x)
    case "10^":
        let x = try parseOneArg(&tok, engine: engine)
        return pow(10.0, x)
    case "Ans":
        return engine.ansValue
    case "X":
        return engine.variables["X"] ?? 0
    case "π":
        return Double.pi
    case "e":
        // Check if followed by ^ meaning e^(...)
        let pk = tok.peek()
        if case .op(let c) = pk, c == "^" {
            _ = tok.next()
            let x = try parseUnary(&tok, engine: engine)
            return exp(x)
        }
        // Check if followed by lparen — implicit e^(
        if case .lparen = pk {
            // standalone e followed by ( is implicit multiply
            return M_E
        }
        return M_E
    default:
        // Single letter variable A-Z
        if name.count == 1, let first = name.first, first.isLetter {
            return engine.variables[name] ?? 0
        }
        throw CalcError.syntax
    }
}

private func factorial(_ n: Int) -> Int {
    guard n > 1 else { return 1 }
    return n * factorial(n - 1)
}

// MARK: - TI84Engine

@Observable final class TI84Engine: CalculatorEngine {

    // MARK: Screen & shift state
    var screen: TI84Screen = .home
    var shift2nd: Bool = false
    var shiftAlpha: Bool = false

    // MARK: Home screen
    var inputLine: String = ""
    var homeHistory: [TIHomeLine] = []
    var ansValue: Double = 0
    var ansStr: String = "0"
    var variables: [String: Double] = [:]

    // MARK: Y= editor
    var yFunctions: [String] = Array(repeating: "", count: 10) {
        didSet { cachedGraphData.removeAll() }
    }
    var yEnabled: [Bool] = Array(repeating: true, count: 10) {
        didSet { cachedGraphData.removeAll() }
    }
    var yEditIndex: Int = 0

    // MARK: Window settings
    var xMin: Double = -10 { didSet { cachedGraphData.removeAll() } }
    var xMax: Double = 10  { didSet { cachedGraphData.removeAll() } }
    var xScl: Double = 1
    var yMin: Double = -10
    var yMax: Double = 10
    var yScl: Double = 1
    var xRes: Int = 1      { didSet { cachedGraphData.removeAll() } }
    var winField: Int = 0
    var winFieldInput: String = ""

    // MARK: Trace
    var traceActive: Bool = false
    var traceX: Double = 0
    var traceFuncIdx: Int = 0

    // MARK: Table
    var tableTblStart: Double = 0
    var tableDeltaTbl: Double = 1
    var tableTopRow: Int = 0

    // MARK: Angle mode
    var angleMode: TI84AngleMode = .degree

    // MARK: Graph cache
    var cachedGraphData: [Int: [(x: Double, y: Double)?]] = [:]

    // MARK: STAT
    var statLists: [[Double]] = Array(repeating: [], count: 6)
    var statEditList: Int = 0
    var statEditRow: Int = 0
    var showStatResults: Bool = false
    private var statCellBuffer: String = ""

    // MARK: Matrix
    var matrices: [[[Double]]] = Array(repeating: [], count: 3)
    var matrixDims: [(rows: Int, cols: Int)] = [(2, 2), (2, 2), (2, 2)]
    var matEditIdx: Int = 0
    var matCursorR: Int = 0
    var matCursorC: Int = 0
    var matPhase: TI84MatPhase = .dimEdit
    var matDimInput: String = ""
    var matDimStep: Int = 0

    // MARK: Mode editor
    var modeRow: Int = 0
    var modeCol: Int = 0

    // MARK: Protocol — displayDecimalPlaces
    var displayDecimalPlaces: Int = 10

    // MARK: Protocol — displayText
    var displayText: String {
        inputLine.isEmpty ? ansStr : inputLine
    }

    // MARK: Protocol — tape
    var tape: [TapeEntry] {
        homeHistory.filter { $0.isResult }.map { TapeEntry(label: $0.expr, result: $0.result) }
    }

    // MARK: Protocol — recallTapeValue
    func recallTapeValue(_ v: Double) {
        inputLine += formatResult(v)
    }

    // MARK: - dispatch

    func dispatch(_ key: String) {
        // Global keys
        switch key {
        case "2ND":
            shift2nd.toggle()
            return
        case "ALPHA":
            shiftAlpha.toggle()
            return
        case "MODE":
            if shift2nd {
                // QUIT → home
                screen = .home
                consumeShift()
                return
            }
        case "ON":
            if !inputLine.isEmpty {
                inputLine = ""
            } else {
                screen = .home
            }
            shift2nd = false
            shiftAlpha = false
            return
        default:
            break
        }

        // Screen-specific dispatch
        switch screen {
        case .home:         homeDispatch(key)
        case .yEditor:      yEditorDispatch(key)
        case .windowEditor: windowDispatch(key)
        case .graph:        graphDispatch(key)
        case .table:        tableDispatch(key)
        case .statEditor:   statDispatch(key)
        case .matrixEditor: matrixDispatch(key)
        case .modeEditor:   modeDispatch(key)
        }

        consumeShift()
    }

    // MARK: - consumeShift

    private func consumeShift() {
        shift2nd = false
        shiftAlpha = false
    }

    // MARK: - Home dispatch

    private func homeDispatch(_ key: String) {
        switch key {
        case "Y=":
            screen = .yEditor
        case "WINDOW":
            screen = .windowEditor
        case "ZOOM":
            break // no-op stub
        case "TRACE":
            screen = .graph
            traceActive = true
            traceX = (xMin + xMax) / 2
            traceFuncIdx = firstEnabledY()
        case "GRAPH":
            screen = .graph
            traceActive = false
        case "STAT":
            screen = .statEditor
        case "MATRIX":
            screen = .matrixEditor
            matPhase = .dimEdit
            matDimStep = 0
            matDimInput = ""
        case "MODE":
            screen = .modeEditor
        case "CLEAR":
            if inputLine.isEmpty {
                homeHistory.removeAll()
            } else {
                inputLine = ""
            }
        case "DEL":
            if !inputLine.isEmpty { inputLine.removeLast() }
        case "ENTER":
            evaluateInputLine()
        case "SIN":
            inputLine += shift2nd ? "sin⁻¹(" : "sin("
        case "COS":
            inputLine += shift2nd ? "cos⁻¹(" : "cos("
        case "TAN":
            inputLine += shift2nd ? "tan⁻¹(" : "tan("
        case "LN":
            inputLine += shift2nd ? "e^(" : "ln("
        case "LOG":
            inputLine += shift2nd ? "10^(" : "log("
        case "x²":
            if shift2nd { inputLine += "√(" } else { inputLine += "²" }
        case "x⁻¹":
            inputLine += "⁻¹"
        case "X,T,θ,n":
            inputLine += "X"
        case "ANS":
            if shift2nd { recallLastExpr() } else { inputLine += "Ans" }
        case "MATH":
            break // no-op stub
        case "PRGM":
            break // no-op stub
        case "VARS":
            break // no-op stub
        case "STO→":
            break // no-op stub
        case "EE":
            inputLine += "ᴱ"
        case "UP", "DOWN", "LEFT", "RIGHT":
            break
        case "(-)":
            inputLine += shift2nd ? "Ans" : "(−)"
        case "^":
            inputLine += "^"
        default:
            appendToInput(key, target: &inputLine)
        }
    }

    private func appendToInput(_ key: String, target: inout String) {
        switch key {
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
             ".", "(", ")", "+", "-", "×", "÷", "^", ",":
            target += key
        default:
            break
        }
    }

    private func recallLastExpr() {
        if let line = homeHistory.last(where: { !$0.isResult }) {
            inputLine = line.expr
        }
    }

    // MARK: - Evaluate input line

    private func evaluateInputLine() {
        guard !inputLine.isEmpty else { return }
        let expr = inputLine
        homeHistory.append(TIHomeLine(expr: expr, result: "", isError: false, isResult: false))
        inputLine = ""
        do {
            let val = try evaluate(expr)
            ansValue = val
            ansStr = formatResult(val)
            homeHistory.append(TIHomeLine(expr: expr, result: ansStr, isError: false, isResult: true))
        } catch {
            homeHistory.append(TIHomeLine(expr: "", result: "ERR:SYNTAX", isError: true, isResult: true))
        }
        if homeHistory.count > 40 {
            homeHistory = Array(homeHistory.suffix(40))
        }
    }

    // MARK: - Expression evaluator

    func evaluate(_ expr: String) throws -> Double {
        // Replace "Ans" text with actual value before tokenizing? No — handle via resolveIdent.
        var tok = Tokenizer(expr)
        let val = try parseExpr(&tok, engine: self)
        let remaining = tok.peek()
        guard case .end = remaining else { throw CalcError.syntax }
        return val
    }

    func evaluateExpr(_ expr: String, x: Double) throws -> Double {
        variables["X"] = x
        return try evaluate(expr)
    }

    // MARK: - Y= editor dispatch

    private func yEditorDispatch(_ key: String) {
        switch key {
        case "UP":
            yEditIndex = max(0, yEditIndex - 1)
        case "DOWN":
            yEditIndex = min(9, yEditIndex + 1)
        case "DEL":
            if !yFunctions[yEditIndex].isEmpty { yFunctions[yEditIndex].removeLast() }
        case "CLEAR":
            yFunctions[yEditIndex] = ""
        case "ENTER":
            yEditIndex = min(9, yEditIndex + 1)
        case "GRAPH":
            screen = .graph
            traceActive = false
        case "SIN":
            yFunctions[yEditIndex] += shift2nd ? "sin⁻¹(" : "sin("
        case "COS":
            yFunctions[yEditIndex] += shift2nd ? "cos⁻¹(" : "cos("
        case "TAN":
            yFunctions[yEditIndex] += shift2nd ? "tan⁻¹(" : "tan("
        case "LN":
            yFunctions[yEditIndex] += shift2nd ? "e^(" : "ln("
        case "LOG":
            yFunctions[yEditIndex] += shift2nd ? "10^(" : "log("
        case "x²":
            if shift2nd { yFunctions[yEditIndex] += "√(" } else { yFunctions[yEditIndex] += "²" }
        case "x⁻¹":
            yFunctions[yEditIndex] += "⁻¹"
        case "X,T,θ,n":
            yFunctions[yEditIndex] += "X"
        case "ANS":
            if shift2nd { recallLastExpr() } else { yFunctions[yEditIndex] += "Ans" }
        case "(-)":
            yFunctions[yEditIndex] += "(−)"
        default:
            // Toggle Y enabled
            if key.hasPrefix("TOGGLE_Y") {
                let suffix = key.dropFirst("TOGGLE_Y".count)
                if let i = Int(suffix), i >= 0 && i < 10 {
                    yEnabled[i].toggle()
                }
                return
            }
            appendToInput(key, target: &yFunctions[yEditIndex])
        }
    }

    // MARK: - Window dispatch

    private func windowDispatch(_ key: String) {
        switch key {
        case "UP":
            winField = max(0, winField - 1)
            winFieldInput = currentFieldValueStr()
        case "DOWN":
            commitWinField()
            winField = min(6, winField + 1)
            winFieldInput = currentFieldValueStr()
        case "ENTER":
            commitWinField()
            winField = min(6, winField + 1)
            winFieldInput = currentFieldValueStr()
        case "GRAPH":
            commitWinField()
            screen = .graph
            cachedGraphData.removeAll()
        case "DEL":
            if !winFieldInput.isEmpty { winFieldInput.removeLast() }
        case "CLEAR":
            winFieldInput = ""
        default:
            // Digit, ".", or minus sign
            switch key {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".":
                winFieldInput += key
            case "-", "(-)":
                if winFieldInput.isEmpty { winFieldInput = "-" }
            default:
                break
            }
        }
    }

    private func commitWinField() {
        guard let val = Double(winFieldInput), val.isFinite else {
            winFieldInput = currentFieldValueStr()
            return
        }
        switch winField {
        case 0:
            if val < xMax { xMin = val }
        case 1:
            if val > xMin { xMax = val }
        case 2:
            xScl = val
        case 3:
            if val < yMax { yMin = val }
        case 4:
            if val > yMin { yMax = val }
        case 5:
            yScl = val
        case 6:
            let intVal = Int(val)
            if intVal >= 1 { xRes = intVal }
        default:
            break
        }
        winFieldInput = currentFieldValueStr()
    }

    private func currentFieldValueStr() -> String {
        switch winField {
        case 0: return formatResult(xMin)
        case 1: return formatResult(xMax)
        case 2: return formatResult(xScl)
        case 3: return formatResult(yMin)
        case 4: return formatResult(yMax)
        case 5: return formatResult(yScl)
        case 6: return "\(xRes)"
        default: return ""
        }
    }

    // MARK: - Graph dispatch

    private func graphDispatch(_ key: String) {
        switch key {
        case "TRACE":
            if traceActive {
                traceActive = false
            } else {
                traceActive = true
                traceX = (xMin + xMax) / 2
                traceFuncIdx = firstEnabledY()
            }
        case "UP":
            if traceActive { cycleTraceFuncUp() }
        case "DOWN":
            if traceActive { cycleTraceFuncDown() }
        case "LEFT":
            if traceActive {
                traceX -= (xMax - xMin) / 263.0
                if traceX < xMin {
                    let w = xMax - xMin
                    xMin -= w / 2
                    xMax -= w / 2
                    cachedGraphData.removeAll()
                }
            }
        case "RIGHT":
            if traceActive {
                traceX += (xMax - xMin) / 263.0
                if traceX > xMax {
                    let w = xMax - xMin
                    xMin += w / 2
                    xMax += w / 2
                    cachedGraphData.removeAll()
                }
            }
        case "GRAPH":
            traceActive = false
        case "CLEAR":
            traceActive = false
        case "Y=":
            screen = .yEditor
        case "WINDOW":
            screen = .windowEditor
        case "TABLE":
            screen = .table
        default:
            break
        }
    }

    // MARK: - Table dispatch

    private func tableDispatch(_ key: String) {
        switch key {
        case "UP":
            tableTopRow = max(0, tableTopRow - 1)
        case "DOWN":
            tableTopRow += 1
        case "Y=":
            screen = .yEditor
        case "GRAPH":
            screen = .graph
        default:
            break
        }
    }

    // MARK: - STAT dispatch

    private func statDispatch(_ key: String) {
        switch key {
        case "UP":
            statEditRow = max(0, statEditRow - 1)
        case "DOWN":
            statEditRow += 1
        case "LEFT":
            statEditList = 0
        case "RIGHT":
            statEditList = min(5, statEditList + 1)
        case "DEL":
            if !statCellBuffer.isEmpty {
                statCellBuffer.removeLast()
            }
        case "CLEAR":
            if !statCellBuffer.isEmpty {
                statCellBuffer = ""
            } else {
                statLists[statEditList].removeAll()
            }
        case "ENTER":
            if let val = Double(statCellBuffer) {
                // Grow list if needed
                while statLists[statEditList].count <= statEditRow {
                    statLists[statEditList].append(0)
                }
                statLists[statEditList][statEditRow] = val
                statCellBuffer = ""
                statEditRow += 1
            }
        case "STAT":
            if shift2nd {
                showStatResults = true
            } else {
                screen = .statEditor
            }
        default:
            // Digit input into cell buffer
            switch key {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "-":
                statCellBuffer += key
            case "(-)":
                if statCellBuffer.isEmpty { statCellBuffer = "-" }
            default:
                break
            }
        }
    }

    // MARK: - Mode dispatch

    private func modeDispatch(_ key: String) {
        switch key {
        case "UP":
            modeRow = max(0, modeRow - 1)
        case "DOWN":
            modeRow = min(6, modeRow + 1)
        case "LEFT":
            modeCol = max(0, modeCol - 1)
        case "RIGHT":
            modeCol += 1
        case "ENTER":
            // Row 2 (0-indexed) = angle mode row: col 0 = radian, col 1 = degree
            if modeRow == 2 {
                angleMode = (modeCol == 0) ? .radian : .degree
            }
        default:
            break
        }
    }

    // MARK: - Matrix dispatch

    private func matrixDispatch(_ key: String) {
        switch matPhase {
        case .dimEdit:
            matrixDimEditDispatch(key)
        case .fill:
            matrixFillDispatch(key)
        case .ops:
            matrixOpsDispatch(key)
        }
    }

    private func matrixDimEditDispatch(_ key: String) {
        switch key {
        case "DEL":
            if !matDimInput.isEmpty { matDimInput.removeLast() }
        case "ENTER":
            if matDimStep == 0 {
                if let val = Int(matDimInput), val >= 1 && val <= 5 {
                    matrixDims[matEditIdx].rows = val
                    matDimInput = ""
                    matDimStep = 1
                }
            } else {
                if let val = Int(matDimInput), val >= 1 && val <= 5 {
                    matrixDims[matEditIdx].cols = val
                    initMatrix()
                    matDimInput = ""
                    matPhase = .fill
                    matCursorR = 0
                    matCursorC = 0
                    winFieldInput = ""
                }
            }
        default:
            switch key {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                matDimInput += key
            default:
                break
            }
        }
    }

    private func matrixFillDispatch(_ key: String) {
        switch key {
        case "DEL":
            if !winFieldInput.isEmpty { winFieldInput.removeLast() }
        case "ENTER":
            let val = Double(winFieldInput) ?? 0
            let d = matrixDims[matEditIdx]
            guard matCursorR < d.rows && matCursorC < d.cols else { break }
            matrices[matEditIdx][matCursorR][matCursorC] = val
            winFieldInput = ""
            // Advance cursor
            matCursorC += 1
            if matCursorC >= d.cols {
                matCursorC = 0
                matCursorR += 1
            }
            if matCursorR >= d.rows {
                matPhase = .ops
            }
        default:
            switch key {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".":
                winFieldInput += key
            case "-", "(-)":
                if winFieldInput.isEmpty { winFieldInput = "-" }
            default:
                break
            }
        }
    }

    private func matrixOpsDispatch(_ key: String) {
        switch key {
        case "MAT_OP_ADD":
            matrices[0] = matAdd(matrices[0], matrices[1])
        case "MAT_OP_SUB":
            matrices[0] = matSub(matrices[0], matrices[1])
        case "MAT_OP_MUL":
            if let result = try? matMul(matrices[0], matrices[1]) {
                matrices[0] = result
            } else {
                ansStr = "ERR:DIMENSION"
            }
        case "MAT_OP_DET":
            if let det = try? matDet(matrices[0]) {
                ansValue = det
                ansStr = formatResult(det)
            } else {
                ansStr = "ERR:DIMENSION"
            }
        case "MAT_OP_INV":
            if let inv = try? matInv(matrices[0]) {
                matrices[0] = inv
            } else {
                ansStr = "ERR:SINGULAR"
            }
        case "MAT_OP_TRP":
            matrices[0] = matTranspose(matrices[0])
        default:
            break
        }
    }

    // MARK: - Graph points

    func graphPoints(for funcIdx: Int, pixelWidth: Int) -> [(x: Double, y: Double)?] {
        if let cached = cachedGraphData[funcIdx] { return cached }
        guard funcIdx < yFunctions.count,
              yEnabled[funcIdx],
              !yFunctions[funcIdx].isEmpty else { return [] }
        let n = max(2, pixelWidth / max(1, xRes))
        var result: [(x: Double, y: Double)?] = []
        for i in 0..<n {
            let x = xMin + (xMax - xMin) * Double(i) / Double(n - 1)
            variables["X"] = x
            let y = try? evaluate(yFunctions[funcIdx])
            if let y = y, y.isFinite {
                result.append((x, y))
            } else {
                result.append(nil)
            }
        }
        cachedGraphData[funcIdx] = result
        return result
    }

    // MARK: - Table rows

    func tableRows(count: Int) -> [(x: Double, ys: [Double?])] {
        let enabledIdxs = yFunctions.indices.filter { yEnabled[$0] && !yFunctions[$0].isEmpty }
        return (0..<count).map { i in
            let x = tableTblStart + Double(tableTopRow + i) * tableDeltaTbl
            variables["X"] = x
            let ys: [Double?] = enabledIdxs.map { idx in
                try? evaluate(yFunctions[idx])
            }
            return (x, ys)
        }
    }

    // MARK: - STAT helpers

    func stat1Var() -> (n: Int, mean: Double, sumX: Double, sumX2: Double, sigmaX: Double, sx: Double) {
        let data = statLists[0]
        let n = data.count
        guard n > 0 else { return (0, 0, 0, 0, 0, 0) }
        let sumX = data.reduce(0, +)
        let mean = sumX / Double(n)
        let sumX2 = data.map { $0 * $0 }.reduce(0, +)
        let variance = sumX2 / Double(n) - mean * mean
        let sigmaX = variance >= 0 ? sqrt(variance) : 0
        let sx = n > 1 ? sqrt(data.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(n - 1)) : 0
        return (n, mean, sumX, sumX2, sigmaX, sx)
    }

    func linReg() -> (a: Double, b: Double, r: Double) {
        let xs = statLists[0], ys = statLists[1]
        let n = min(xs.count, ys.count)
        guard n >= 2 else { return (0, 0, 0) }
        let xData = Array(xs.prefix(n)), yData = Array(ys.prefix(n))
        let sumX = xData.reduce(0, +), sumY = yData.reduce(0, +)
        let sumXY = zip(xData, yData).map(*).reduce(0, +)
        let sumX2 = xData.map { $0 * $0 }.reduce(0, +)
        let dn = Double(n)
        let denom = dn * sumX2 - sumX * sumX
        guard abs(denom) > 1e-12 else { return (0, 0, 0) }
        let b = (dn * sumXY - sumX * sumY) / denom
        let a = (sumY - b * sumX) / dn
        let meanY = sumY / dn
        let ssRes = zip(xData, yData).map { ($1 - (a + b * $0)) * ($1 - (a + b * $0)) }.reduce(0, +)
        let ssTot = yData.map { ($0 - meanY) * ($0 - meanY) }.reduce(0, +)
        let r = ssTot > 0 ? sqrt(max(0, 1 - ssRes / ssTot)) * (b >= 0 ? 1 : -1) : 0
        return (a, b, r)
    }

    // MARK: - Matrix helpers

    private func initMatrix() {
        let d = matrixDims[matEditIdx]
        matrices[matEditIdx] = Array(repeating: Array(repeating: 0.0, count: d.cols), count: d.rows)
    }

    private func matAdd(_ a: [[Double]], _ b: [[Double]]) -> [[Double]] {
        guard a.count == b.count, a.first?.count == b.first?.count else { return a }
        return a.indices.map { r in a[r].indices.map { c in a[r][c] + b[r][c] } }
    }

    private func matSub(_ a: [[Double]], _ b: [[Double]]) -> [[Double]] {
        guard a.count == b.count, a.first?.count == b.first?.count else { return a }
        return a.indices.map { r in a[r].indices.map { c in a[r][c] - b[r][c] } }
    }

    private func matMul(_ a: [[Double]], _ b: [[Double]]) throws -> [[Double]] {
        let m = a.count
        let n = a.first?.count ?? 0
        let p = b.first?.count ?? 0
        guard n == b.count else { throw CalcError.dimension }
        return (0..<m).map { r in
            (0..<p).map { c in
                (0..<n).map { k in a[r][k] * b[k][c] }.reduce(0, +)
            }
        }
    }

    private func matDet(_ m: [[Double]]) throws -> Double {
        let n = m.count
        guard m.allSatisfy({ $0.count == n }) else { throw CalcError.dimension }
        if n == 1 { return m[0][0] }
        if n == 2 { return m[0][0] * m[1][1] - m[0][1] * m[1][0] }
        var mat = m
        var det = 1.0
        var sign = 1.0
        for col in 0..<n {
            guard let pivotRow = (col..<n).first(where: { abs(mat[$0][col]) > 1e-12 }) else { return 0 }
            if pivotRow != col {
                mat.swapAt(col, pivotRow)
                sign *= -1
            }
            det *= mat[col][col]
            for row in (col + 1)..<n {
                let factor = mat[row][col] / mat[col][col]
                for k in col..<n {
                    mat[row][k] -= factor * mat[col][k]
                }
            }
        }
        return det * sign
    }

    private func matInv(_ m: [[Double]]) throws -> [[Double]] {
        let n = m.count
        guard m.allSatisfy({ $0.count == n }) else { throw CalcError.dimension }
        var aug = m.indices.map { r in
            m[r] + (0..<n).map { c in r == c ? 1.0 : 0.0 }
        }
        for col in 0..<n {
            guard let pivotRow = (col..<n).first(where: { abs(aug[$0][col]) > 1e-12 }) else {
                throw CalcError.singular
            }
            if pivotRow != col { aug.swapAt(col, pivotRow) }
            let pivot = aug[col][col]
            aug[col] = aug[col].map { $0 / pivot }
            for row in 0..<n where row != col {
                let factor = aug[row][col]
                aug[row] = aug[row].indices.map { aug[row][$0] - factor * aug[col][$0] }
            }
        }
        return aug.map { Array($0.suffix(n)) }
    }

    private func matTranspose(_ m: [[Double]]) -> [[Double]] {
        guard !m.isEmpty, !m[0].isEmpty else { return m }
        return m[0].indices.map { c in m.indices.map { r in m[r][c] } }
    }

    // MARK: - Format result

    func formatResult(_ v: Double) -> String {
        if v == 0 { return "0" }
        let absV = abs(v)
        if absV >= 0.001 && absV < 1e10 {
            let s = String(format: "%.10g", v)
            return s
        } else {
            var s = String(format: "%.6E", v)
            s = s.replacingOccurrences(of: "E+0", with: "E")
                 .replacingOccurrences(of: "E-0", with: "E-")
                 .replacingOccurrences(of: "E+", with: "E")
            return s
        }
    }

    // MARK: - Trace helpers

    private func firstEnabledY() -> Int {
        yFunctions.indices.first { yEnabled[$0] && !yFunctions[$0].isEmpty } ?? 0
    }

    private func cycleTraceFuncUp() {
        let enabled = yFunctions.indices.filter { yEnabled[$0] && !yFunctions[$0].isEmpty }
        guard !enabled.isEmpty else { return }
        if let current = enabled.firstIndex(of: traceFuncIdx) {
            let prev = (current - 1 + enabled.count) % enabled.count
            traceFuncIdx = enabled[prev]
        } else {
            traceFuncIdx = enabled[0]
        }
    }

    private func cycleTraceFuncDown() {
        let enabled = yFunctions.indices.filter { yEnabled[$0] && !yFunctions[$0].isEmpty }
        guard !enabled.isEmpty else { return }
        if let current = enabled.firstIndex(of: traceFuncIdx) {
            let next = (current + 1) % enabled.count
            traceFuncIdx = enabled[next]
        } else {
            traceFuncIdx = enabled[0]
        }
    }
}
