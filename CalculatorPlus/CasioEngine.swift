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

// MARK: - Physical constants & unit conversions

struct PhysicalConstant: Identifiable {
    let id: Int; let symbol: String; let name: String
    let value: Double; let unit: String; let category: String
}

struct CasioConversion: Identifiable {
    let id: Int; let from: String; let to: String; let category: String
    let factor: Double
    let preAdd: Double   // add to input before multiplying (temp offset)
    let postAdd: Double  // add after multiplying
    func apply(_ x: Double) -> Double { (x + preAdd) * factor + postAdd }
    var label: String { "\(from) → \(to)" }
}

extension CasioEngine {
    static let physConstants: [PhysicalConstant] = [
        // Universal
        .init(id:0,  symbol:"c",   name:"Speed of light",        value:299_792_458,           unit:"m/s",        category:"Universal"),
        .init(id:1,  symbol:"h",   name:"Planck constant",        value:6.62607015e-34,        unit:"J·s",        category:"Universal"),
        .init(id:2,  symbol:"ℏ",   name:"Reduced Planck",         value:1.054571817e-34,       unit:"J·s",        category:"Universal"),
        .init(id:3,  symbol:"NA",  name:"Avogadro constant",      value:6.02214076e23,         unit:"mol⁻¹",      category:"Universal"),
        .init(id:4,  symbol:"k",   name:"Boltzmann constant",     value:1.380649e-23,          unit:"J/K",        category:"Universal"),
        .init(id:5,  symbol:"R",   name:"Molar gas constant",     value:8.314462618,           unit:"J/(mol·K)",  category:"Universal"),
        .init(id:6,  symbol:"σ",   name:"Stefan-Boltzmann",       value:5.670374419e-8,        unit:"W/(m²K⁴)",   category:"Universal"),
        .init(id:7,  symbol:"G",   name:"Gravitational constant", value:6.67430e-11,           unit:"m³/(kg·s²)", category:"Universal"),
        .init(id:8,  symbol:"g",   name:"Standard gravity",       value:9.80665,               unit:"m/s²",       category:"Universal"),
        .init(id:9,  symbol:"atm", name:"Standard atmosphere",    value:101_325,               unit:"Pa",         category:"Universal"),
        // Electromagnetic
        .init(id:10, symbol:"e",   name:"Elementary charge",      value:1.602176634e-19,       unit:"C",          category:"Electromagnetic"),
        .init(id:11, symbol:"μ0",  name:"Magnetic constant",      value:1.25663706212e-6,      unit:"N/A²",       category:"Electromagnetic"),
        .init(id:12, symbol:"ε0",  name:"Electric constant",      value:8.8541878128e-12,      unit:"F/m",        category:"Electromagnetic"),
        .init(id:13, symbol:"α",   name:"Fine-structure constant",value:7.2973525693e-3,       unit:"",           category:"Electromagnetic"),
        .init(id:14, symbol:"F",   name:"Faraday constant",       value:96485.33212,           unit:"C/mol",      category:"Electromagnetic"),
        .init(id:15, symbol:"G0",  name:"Conductance quantum",    value:7.748091729e-5,        unit:"S",          category:"Electromagnetic"),
        .init(id:16, symbol:"Φ0",  name:"Magnetic flux quantum",  value:2.067833848e-15,       unit:"Wb",         category:"Electromagnetic"),
        .init(id:17, symbol:"RK",  name:"Von Klitzing constant",  value:25812.80745,           unit:"Ω",          category:"Electromagnetic"),
        .init(id:18, symbol:"KJ",  name:"Josephson constant",     value:4.835978484e14,        unit:"Hz/V",       category:"Electromagnetic"),
        .init(id:19, symbol:"eV",  name:"Electron volt",          value:1.602176634e-19,       unit:"J",          category:"Electromagnetic"),
        // Atomic & nuclear
        .init(id:20, symbol:"me",  name:"Electron mass",          value:9.1093837015e-31,      unit:"kg",         category:"Atomic & Nuclear"),
        .init(id:21, symbol:"mp",  name:"Proton mass",            value:1.67262192369e-27,     unit:"kg",         category:"Atomic & Nuclear"),
        .init(id:22, symbol:"mn",  name:"Neutron mass",           value:1.67492749804e-27,     unit:"kg",         category:"Atomic & Nuclear"),
        .init(id:23, symbol:"u",   name:"Atomic mass unit",       value:1.66053906660e-27,     unit:"kg",         category:"Atomic & Nuclear"),
        .init(id:24, symbol:"mμ",  name:"Muon mass",              value:1.883531627e-28,       unit:"kg",         category:"Atomic & Nuclear"),
        .init(id:25, symbol:"a0",  name:"Bohr radius",            value:5.29177210903e-11,     unit:"m",          category:"Atomic & Nuclear"),
        .init(id:26, symbol:"re",  name:"Classical electron r.",  value:2.8179403227e-15,      unit:"m",          category:"Atomic & Nuclear"),
        .init(id:27, symbol:"λC",  name:"Compton wavelength",     value:2.42631023867e-12,     unit:"m",          category:"Atomic & Nuclear"),
        .init(id:28, symbol:"μB",  name:"Bohr magneton",          value:9.2740100783e-24,      unit:"J/T",        category:"Atomic & Nuclear"),
        .init(id:29, symbol:"μN",  name:"Nuclear magneton",       value:5.0507837461e-27,      unit:"J/T",        category:"Atomic & Nuclear"),
        // Physico-chemical
        .init(id:30, symbol:"R∞",  name:"Rydberg constant",       value:10_973_731.568160,     unit:"m⁻¹",        category:"Physico-Chemical"),
        .init(id:31, symbol:"Vm",  name:"Molar volume (STP)",     value:0.022413969,           unit:"m³/mol",     category:"Physico-Chemical"),
        .init(id:32, symbol:"Eh",  name:"Hartree energy",         value:4.3597447222e-18,      unit:"J",          category:"Physico-Chemical"),
        .init(id:33, symbol:"c1",  name:"1st radiation constant", value:3.741771852e-16,       unit:"W·m²",       category:"Physico-Chemical"),
        .init(id:34, symbol:"c2",  name:"2nd radiation constant", value:1.438776877e-2,        unit:"m·K",        category:"Physico-Chemical"),
        // Planck units
        .init(id:35, symbol:"lP",  name:"Planck length",          value:1.616255e-35,          unit:"m",          category:"Planck Units"),
        .init(id:36, symbol:"tP",  name:"Planck time",            value:5.391247e-44,          unit:"s",          category:"Planck Units"),
        .init(id:37, symbol:"mP",  name:"Planck mass",            value:2.176434e-8,           unit:"kg",         category:"Planck Units"),
        .init(id:38, symbol:"TP",  name:"Planck temperature",     value:1.416784e32,           unit:"K",          category:"Planck Units"),
        .init(id:39, symbol:"Ep",  name:"Planck energy",          value:1.956082e9,            unit:"J",          category:"Planck Units"),
    ]

    static let physConversions: [CasioConversion] = [
        // Length (8)
        .init(id:0,  from:"in",    to:"cm",    category:"Length",      factor:2.54,              preAdd:0,   postAdd:0),
        .init(id:1,  from:"cm",    to:"in",    category:"Length",      factor:1/2.54,            preAdd:0,   postAdd:0),
        .init(id:2,  from:"ft",    to:"m",     category:"Length",      factor:0.3048,            preAdd:0,   postAdd:0),
        .init(id:3,  from:"m",     to:"ft",    category:"Length",      factor:1/0.3048,          preAdd:0,   postAdd:0),
        .init(id:4,  from:"yd",    to:"m",     category:"Length",      factor:0.9144,            preAdd:0,   postAdd:0),
        .init(id:5,  from:"mi",    to:"km",    category:"Length",      factor:1.609344,          preAdd:0,   postAdd:0),
        .init(id:6,  from:"km",    to:"mi",    category:"Length",      factor:1/1.609344,        preAdd:0,   postAdd:0),
        .init(id:7,  from:"n mi",  to:"km",    category:"Length",      factor:1.852,             preAdd:0,   postAdd:0),
        // Area (4)
        .init(id:8,  from:"in²",   to:"cm²",   category:"Area",        factor:6.4516,            preAdd:0,   postAdd:0),
        .init(id:9,  from:"ft²",   to:"m²",    category:"Area",        factor:0.09290304,        preAdd:0,   postAdd:0),
        .init(id:10, from:"m²",    to:"ft²",   category:"Area",        factor:1/0.09290304,      preAdd:0,   postAdd:0),
        .init(id:11, from:"acre",  to:"m²",    category:"Area",        factor:4046.8564224,      preAdd:0,   postAdd:0),
        // Volume (6)
        .init(id:12, from:"in³",   to:"cm³",   category:"Volume",      factor:16.387064,         preAdd:0,   postAdd:0),
        .init(id:13, from:"cm³",   to:"in³",   category:"Volume",      factor:1/16.387064,       preAdd:0,   postAdd:0),
        .init(id:14, from:"fl oz", to:"mL",    category:"Volume",      factor:29.5735296,        preAdd:0,   postAdd:0),
        .init(id:15, from:"mL",    to:"fl oz", category:"Volume",      factor:1/29.5735296,      preAdd:0,   postAdd:0),
        .init(id:16, from:"gal",   to:"L",     category:"Volume",      factor:3.785411784,       preAdd:0,   postAdd:0),
        .init(id:17, from:"L",     to:"gal",   category:"Volume",      factor:1/3.785411784,     preAdd:0,   postAdd:0),
        // Mass (6)
        .init(id:18, from:"oz",    to:"g",     category:"Mass",        factor:28.349523125,      preAdd:0,   postAdd:0),
        .init(id:19, from:"g",     to:"oz",    category:"Mass",        factor:1/28.349523125,    preAdd:0,   postAdd:0),
        .init(id:20, from:"lb",    to:"kg",    category:"Mass",        factor:0.45359237,        preAdd:0,   postAdd:0),
        .init(id:21, from:"kg",    to:"lb",    category:"Mass",        factor:1/0.45359237,      preAdd:0,   postAdd:0),
        .init(id:22, from:"t",     to:"kg",    category:"Mass",        factor:1000,              preAdd:0,   postAdd:0),
        .init(id:23, from:"st",    to:"kg",    category:"Mass",        factor:6.35029318,        preAdd:0,   postAdd:0),
        // Speed (4)
        .init(id:24, from:"km/h",  to:"m/s",   category:"Speed",       factor:1/3.6,             preAdd:0,   postAdd:0),
        .init(id:25, from:"m/s",   to:"km/h",  category:"Speed",       factor:3.6,               preAdd:0,   postAdd:0),
        .init(id:26, from:"mph",   to:"km/h",  category:"Speed",       factor:1.609344,          preAdd:0,   postAdd:0),
        .init(id:27, from:"knot",  to:"km/h",  category:"Speed",       factor:1.852,             preAdd:0,   postAdd:0),
        // Temperature (4)
        .init(id:28, from:"°F",    to:"°C",    category:"Temperature", factor:5.0/9.0,           preAdd:-32, postAdd:0),
        .init(id:29, from:"°C",    to:"°F",    category:"Temperature", factor:9.0/5.0,           preAdd:0,   postAdd:32),
        .init(id:30, from:"°C",    to:"K",     category:"Temperature", factor:1,                 preAdd:0,   postAdd:273.15),
        .init(id:31, from:"K",     to:"°C",    category:"Temperature", factor:1,                 preAdd:0,   postAdd:-273.15),
        // Energy (4)
        .init(id:32, from:"cal",   to:"J",     category:"Energy",      factor:4.184,             preAdd:0,   postAdd:0),
        .init(id:33, from:"J",     to:"cal",   category:"Energy",      factor:1/4.184,           preAdd:0,   postAdd:0),
        .init(id:34, from:"BTU",   to:"J",     category:"Energy",      factor:1055.05585,        preAdd:0,   postAdd:0),
        .init(id:35, from:"kWh",   to:"J",     category:"Energy",      factor:3_600_000,         preAdd:0,   postAdd:0),
        // Pressure (2)
        .init(id:36, from:"atm",   to:"Pa",    category:"Pressure",    factor:101_325,           preAdd:0,   postAdd:0),
        .init(id:37, from:"Pa",    to:"atm",   category:"Pressure",    factor:1/101_325,         preAdd:0,   postAdd:0),
        // Time (2)
        .init(id:38, from:"h",     to:"s",     category:"Time",        factor:3600,              preAdd:0,   postAdd:0),
        .init(id:39, from:"day",   to:"h",     category:"Time",        factor:24,                preAdd:0,   postAdd:0),
    ]
}

// MARK: - CMPLX types

struct CasioComplex: Equatable {
    var re: Double = 0; var im: Double = 0
    static func +(a: Self, b: Self) -> Self { Self(re: a.re+b.re, im: a.im+b.im) }
    static func -(a: Self, b: Self) -> Self { Self(re: a.re-b.re, im: a.im-b.im) }
    static func *(a: Self, b: Self) -> Self { Self(re: a.re*b.re - a.im*b.im, im: a.re*b.im + a.im*b.re) }
    static func /(a: Self, b: Self) -> Self {
        let d = b.re*b.re + b.im*b.im
        return Self(re: (a.re*b.re + a.im*b.im)/d, im: (a.im*b.re - a.re*b.im)/d)
    }
    var magnitude: Double { (re*re + im*im).squareRoot() }
    var argument:  Double { atan2(im, re) }
    var conjugate: Self   { Self(re: re, im: -im) }
}

// MARK: - MATRIX / VECTOR / TABLE types

struct CasioMatrix: Equatable {
    var rows: Int; var cols: Int; var data: [[Double]]
    init(rows: Int = 2, cols: Int = 2) {
        self.rows = rows; self.cols = cols
        data = Array(repeating: Array(repeating: 0.0, count: cols), count: rows)
    }
    subscript(r: Int, c: Int) -> Double {
        get { data[r][c] }
        set { data[r][c] = newValue }
    }
}

enum CasioMatPhase   { case select, dimR, dimC, fill, ops, rhs, result }
enum CasioVctPhase   { case select, dim, fill, ops, rhs, result }
enum CasioTablePhase { case expr, start, end, step, view }
enum CasioCalcPhase  { case idle, prompt }
enum CasioSolvePhase { case idle, prompt }
enum CasioIntPhase   { case idle, lower, upper }
enum CasioDiffPhase  { case idle, xVal }

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
        didSet {
            modeLabel = mode.title; clearInput()
            switch mode {
            case .cmplx:  resetCmplx()
            case .matrix: resetMatrix()
            case .vector: resetVector()
            case .table:  resetTable()
            case .baseN:  resetBaseN()
            default: break
            }
        }
    }
    var angleUnit: AngleUnit = .deg { didSet { angleLabel = angleUnit.rawValue } }
    var displayFmt: DisplayFmt = .norm
    var baseRadix:     BaseRadix = .dec
    var baseNLhsVal:   Int = 0
    var baseNOp:       String? = nil
    var baseNInputStr: String = "0"

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

    // MARK: CMPLX
    var cmplxAns:   CasioComplex = CasioComplex()
    var cmplxLhs:   CasioComplex? = nil
    var cmplxOp:    String? = nil
    var cmplxReStr: String = ""
    var cmplxImStr: String = ""
    var cmplxPhase: Int = 0          // 0 = entering Re, 1 = entering Im
    var cmplxPolar: Bool = false     // false = a+bi, true = r∠θ

    // MARK: MATRIX
    var matrices: [String: CasioMatrix] = [
        "A": CasioMatrix(), "B": CasioMatrix(), "C": CasioMatrix(),
        "Ans": CasioMatrix()
    ]
    var matTarget:  String = "A"
    var matPhase:   CasioMatPhase = .select
    var matCurRow:  Int = 0; var matCurCol: Int = 0
    var matInputStr: String = ""
    var matOp:      String? = nil
    var matLhsName: String? = nil

    // MARK: VECTOR
    var vectors:    [String: [Double]] = ["A": [0, 0], "B": [0, 0]]
    var vctTarget:  String = "A"
    var vctPhase:   CasioVctPhase = .select
    var vctCurIdx:  Int = 0
    var vctInputStr: String = ""
    var vctOp:      String? = nil
    var vctLhsName: String? = nil

    // MARK: TABLE
    var tableExpr:    String = ""
    var tableStart:   Double = 1
    var tableEnd:     Double = 5
    var tableStep:    Double = 1
    var tablePhase:   CasioTablePhase = .expr
    var tableData:    [(x: Double, fx: Double)] = []
    var tableInputStr: String = ""
    var tableViewRow: Int = 0

    // MARK: CALC / SOLVE / ∫ / d∕dx
    var calcPhase:       CasioCalcPhase  = .idle
    var calcExprStr:     String = ""
    var calcVarQueue:    [String] = []
    var calcCurrentVar:  String = ""
    var subInput:        String = ""        // numeric entry during CALC / SOLVE prompts

    var solvePhase:      CasioSolvePhase = .idle
    var solveExprStr:    String = ""

    var intPhase:        CasioIntPhase   = .idle
    var intFExpr:        String = ""
    var intLowerExpr:    String = ""

    var diffPhase:       CasioDiffPhase  = .idle
    var diffFExpr:       String = ""

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
        case .cmplx:  dispatchCmplx(key)
        case .matrix: dispatchMatrix(key)
        case .vector: dispatchVector(key)
        case .table:  dispatchTable(key)
        default:      dispatchComp(key)
        }
    }

    // MARK: - COMP

    private func dispatchComp(_ key: String) {
        // Sub-workflow phase interception (precedes main switch)
        if calcPhase  == .prompt { handleCalcKey(key);  return }
        if solvePhase == .prompt { handleSolveKey(key); return }
        if intPhase  != .idle && (key == "=" || key == "AC") {
            if key == "AC" { intPhase  = .idle; clearInput() } else { handleIntEquals()  }
            return
        }
        if diffPhase != .idle && (key == "=" || key == "AC") {
            if key == "AC" { diffPhase = .idle; clearInput() } else { handleDiffEquals() }
            return
        }

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

        // Display format  (bare keys use current displayDecimalPlaces)
        case "FIX":  displayFmt = .fix(displayDecimalPlaces); refreshDisplay()
        case "SCI":  displayFmt = .sci(displayDecimalPlaces); refreshDisplay()
        case "ENG":  displayFmt = .eng(displayDecimalPlaces); refreshDisplay()
        case "NORM": displayFmt = .norm;                      refreshDisplay()

        // FIX:n / SCI:n / ENG:n sent by the format picker (n = decimal places)
        case let k where k.hasPrefix("FIX:"):
            if let d = Int(k.dropFirst(4)) { displayDecimalPlaces = d; displayFmt = .fix(d); refreshDisplay() }
        case let k where k.hasPrefix("SCI:"):
            if let d = Int(k.dropFirst(4)) { displayDecimalPlaces = d; displayFmt = .sci(d); refreshDisplay() }
        case let k where k.hasPrefix("ENG:"):
            if let d = Int(k.dropFirst(4)) { displayDecimalPlaces = d; displayFmt = .eng(d); refreshDisplay() }

        case "CALC":   startCalc()
        case "SOLVE":  startSolve()
        case "∫","∫dx": startIntegral()
        case "d/dx":   startDerivative()

        case "NormPD","NormCD","InvNorm",
             "BinomPD","BinomCD",
             "PoissonPD","PoissonCD":
            insertFn(key)

        case "S<>D":
            // Toggle between decimal and fraction representation
            if displayText.contains("/") {
                if let v = evaluate(displayText) { displayText = fmt(v); ans = v }
            } else {
                let v = Double(displayText) ?? ans
                if let f = decimalToFraction(v, maxDenom: 1000) { displayText = f }
                else { displayText = fmt(v) }
            }

        case "FRAC":
            // Fraction template — append division separator
            if hasResult { expression = ""; hasResult = false }
            if !expression.isEmpty { expression += "/"; displayText = expression }

        case "MIXED":
            // Mixed number template — append mixed-number separator
            if hasResult { expression = ""; hasResult = false }
            expression += "+"; displayText = expression

        case "≈":
            // Approximate (same as = but always decimal)
            performEval()

        case "Pol":  insertFn("Pol")
        case "Rec":  insertFn("Rec")

        case "∠":
            // Append angle symbol for polar notation
            if !expression.isEmpty { expression += "∠"; displayText = expression }

        case let key where key.hasPrefix("CONST:"):
            if let idx = Int(key.dropFirst(6)), idx < CasioEngine.physConstants.count {
                let c = CasioEngine.physConstants[idx]
                inject(c.symbol, displayValue: fmt(c.value))
            }

        case let key where key.hasPrefix("CONV:"):
            if let idx = Int(key.dropFirst(5)), idx < CasioEngine.physConversions.count {
                let conv = CasioEngine.physConversions[idx]
                let v = Double(displayText) ?? ans
                let result = conv.apply(v)
                let r = fmt(result)
                tape.append(TapeEntry(label: "\(fmt(v)) \(conv.from)→\(conv.to)", result: "\(r) \(conv.to)"))
                ans = result; expression = fmt(result); displayText = r; hasResult = true
            }

        default:
            // Variable names A-F X Y M
            if validVarName(key) {
                let v = vars[key] ?? 0
                inject(key, displayValue: fmt(v))
            }
        }
    }

    // MARK: - Helpers

    private func refreshDisplay() {
        let v = Double(displayText) ?? ans
        displayText = fmt(v)
    }

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

    // MARK: - CALC / SOLVE / ∫ / d∕dx  entry points

    private func startCalc() {
        guard !expression.isEmpty else { return }
        calcExprStr = expression
        calcVarQueue = extractVars(expression)
        guard !calcVarQueue.isEmpty else { performEval(); return }
        calcCurrentVar = calcVarQueue.removeFirst()
        calcPhase = .prompt
        subInput = ""
        displayText = "\(calcCurrentVar)=?"
    }

    private func startSolve() {
        guard !expression.isEmpty else { return }
        solveExprStr = expression
        solvePhase = .prompt
        subInput = ""
        expression = ""
        displayText = "X=?(guess)"
    }

    private func startIntegral() {
        intFExpr = expression.isEmpty ? "X" : expression
        intPhase = .lower
        expression = ""
        displayText = "Lower?"
        hasResult = true
    }

    private func startDerivative() {
        diffFExpr = expression.isEmpty ? "X" : expression
        diffPhase = .xVal
        expression = ""
        displayText = "X=?"
        hasResult = true
    }

    // MARK: - CALC numeric prompt

    private func handleCalcKey(_ key: String) {
        switch key {
        case "AC":
            calcPhase = .idle; clearInput()
        case "DEL","←":
            if !subInput.isEmpty { subInput.removeLast() }
            displayText = subInput.isEmpty ? "\(calcCurrentVar)=?" : subInput
        case "=":
            handleCalcEquals()
        case "(-)","±":
            if subInput.hasPrefix("-") { subInput.removeFirst() }
            else { subInput = "-" + subInput }
            displayText = subInput.isEmpty ? "\(calcCurrentVar)=?" : subInput
        case "π":   subInput = fmt(.pi);  displayText = subInput
        case "e":   subInput = fmt(M_E);  displayText = subInput
        case "Ans": subInput = fmt(ans);  displayText = subInput
        default:
            if "0123456789".contains(key) {
                subInput += key; displayText = subInput
            } else if key == "." && !subInput.contains(".") {
                subInput += "."; displayText = subInput
            }
        }
    }

    private func handleCalcEquals() {
        vars[calcCurrentVar] = Double(subInput) ?? 0
        subInput = ""
        if calcVarQueue.isEmpty {
            calcPhase = .idle
            let formula = calcExprStr
            expression = formula
            performEval()
            expression = formula    // restore so user can re-CALC with new values
        } else {
            calcCurrentVar = calcVarQueue.removeFirst()
            displayText = "\(calcCurrentVar)=?"
        }
    }

    // MARK: - SOLVE numeric prompt

    private func handleSolveKey(_ key: String) {
        switch key {
        case "AC":
            solvePhase = .idle; clearInput()
        case "DEL","←":
            if !subInput.isEmpty { subInput.removeLast() }
            displayText = subInput.isEmpty ? "X=?(guess)" : subInput
        case "=":
            handleSolveEquals()
        case "(-)","±":
            if subInput.hasPrefix("-") { subInput.removeFirst() }
            else { subInput = "-" + subInput }
            displayText = subInput.isEmpty ? "X=?" : subInput
        case "π":   subInput = fmt(.pi);  displayText = subInput
        case "e":   subInput = fmt(M_E);  displayText = subInput
        case "Ans": subInput = fmt(ans);  displayText = subInput
        default:
            if "0123456789".contains(key) {
                subInput += key; displayText = subInput
            } else if key == "." && !subInput.contains(".") {
                subInput += "."; displayText = subInput
            }
        }
    }

    private func handleSolveEquals() {
        solvePhase = .idle
        let x0 = Double(subInput) ?? 0
        subInput = ""
        if let root = newtonSolve(expr: solveExprStr, x0: x0) {
            vars["X"] = root
            let r = fmt(root)
            tape.append(TapeEntry(label: "SOLVE \(solveExprStr)=0", result: "X=\(r)"))
            ans = root; expression = solveExprStr; displayText = r; hasResult = true
        } else {
            displayText = "No Solution"; expression = solveExprStr
        }
    }

    // MARK: - ∫  phase handler

    private func handleIntEquals() {
        switch intPhase {
        case .lower:
            intLowerExpr = expression
            intPhase = .upper
            expression = ""
            displayText = "Upper?"
            hasResult = true
        case .upper:
            intPhase = .idle
            guard let a = evaluate(intLowerExpr), let b = evaluate(expression) else {
                displayText = "Math ERROR"; return
            }
            if let result = simpsonIntegral(expr: intFExpr, a: a, b: b) {
                let r = fmt(result)
                tape.append(TapeEntry(label: "∫(\(intFExpr))[\(fmt(a)),\(fmt(b))]", result: r))
                ans = result; expression = r; displayText = r; hasResult = true
            } else {
                displayText = "Math ERROR"
            }
        case .idle: break
        }
    }

    // MARK: - d∕dx  phase handler

    private func handleDiffEquals() {
        diffPhase = .idle
        guard let x = evaluate(expression) else { displayText = "Math ERROR"; return }
        if let result = centralDiff(expr: diffFExpr, x: x) {
            let r = fmt(result)
            tape.append(TapeEntry(label: "d/dx[\(diffFExpr)] x=\(fmt(x))", result: r))
            ans = result; expression = r; displayText = r; hasResult = true
        } else {
            displayText = "Math ERROR"
        }
    }

    // MARK: - Numerical computation

    private func simpsonIntegral(expr: String, a: Double, b: Double, n: Int = 1000) -> Double? {
        let steps = n % 2 == 0 ? n : n + 1
        let h = (b - a) / Double(steps)
        let savedX = vars["X"]
        var sum = 0.0
        for i in 0...steps {
            let x = a + Double(i) * h
            vars["X"] = x
            guard let fx = evaluate(expr) else { vars["X"] = savedX; return nil }
            let coeff: Double = (i == 0 || i == steps) ? 1 : (i % 2 == 1 ? 4 : 2)
            sum += coeff * fx
        }
        vars["X"] = savedX
        return (h / 3.0) * sum
    }

    private func centralDiff(expr: String, x: Double) -> Double? {
        let h = max(1e-6, Swift.abs(x) * 1e-6)
        let savedX = vars["X"]
        vars["X"] = x + h
        guard let fp = evaluate(expr) else { vars["X"] = savedX; return nil }
        vars["X"] = x - h
        guard let fm = evaluate(expr) else { vars["X"] = savedX; return nil }
        vars["X"] = savedX
        return (fp - fm) / (2.0 * h)
    }

    private func newtonSolve(expr: String, x0: Double) -> Double? {
        let savedX = vars["X"]
        var x = x0
        let h = 1e-7
        for _ in 0..<200 {
            vars["X"] = x
            guard let fx = evaluate(expr) else { vars["X"] = savedX; return nil }
            if Swift.abs(fx) < 1e-12 { return x }
            vars["X"] = x + h
            guard let fxh = evaluate(expr) else { vars["X"] = savedX; return nil }
            let df = (fxh - fx) / h
            guard Swift.abs(df) > 1e-15 else { break }
            let xn = x - fx / df
            if Swift.abs(xn - x) < 1e-12 { return xn }
            x = xn
        }
        vars["X"] = x
        guard let fx = evaluate(expr) else { vars["X"] = savedX; return nil }
        if Swift.abs(fx) < 1e-6 { return x }
        vars["X"] = savedX; return nil
    }

    private func extractVars(_ expr: String) -> [String] {
        // C and P are nCr/nPr binary operators, exclude from variable detection
        let varNames = ["X","A","B","D","E","F","Y","M"]
        var found: [String] = []
        var seen  = Set<String>()
        let chars = Array(expr)
        for i in chars.indices {
            let ch = String(chars[i])
            guard varNames.contains(ch), !seen.contains(ch) else { continue }
            let prevLower = i > 0 && chars[i-1].isLowercase
            let nextLower = i < chars.count-1 && chars[i+1].isLowercase
            if !prevLower && !nextLower { found.append(ch); seen.insert(ch) }
        }
        return found
    }

    // MARK: - CMPLX dispatch

    private func dispatchCmplx(_ key: String) {
        switch key {
        case "AC":
            resetCmplx()
        case "DEL","←":
            if cmplxPhase == 0 { if !cmplxReStr.isEmpty { cmplxReStr.removeLast() } }
            else               { if !cmplxImStr.isEmpty { cmplxImStr.removeLast() } }
            refreshCmplxDisplay()
        case "i":
            cmplxPhase = 1; refreshCmplxDisplay()
        case "0","1","2","3","4","5","6","7","8","9":
            if cmplxPhase == 0 { cmplxReStr += key } else { cmplxImStr += key }
            refreshCmplxDisplay()
        case ".":
            if cmplxPhase == 0 { if !cmplxReStr.contains(".") { cmplxReStr += "." } }
            else               { if !cmplxImStr.contains(".") { cmplxImStr += "." } }
            refreshCmplxDisplay()
        case "(-)":
            if cmplxPhase == 0 {
                cmplxReStr = cmplxReStr.hasPrefix("-") ? String(cmplxReStr.dropFirst()) : "-" + cmplxReStr
            } else {
                cmplxImStr = cmplxImStr.hasPrefix("-") ? String(cmplxImStr.dropFirst()) : "-" + cmplxImStr
            }
            refreshCmplxDisplay()
        case "+","-","×","÷":
            let z = cmplxFromInput()
            cmplxLhs = z; cmplxOp = key
            cmplxReStr = ""; cmplxImStr = ""; cmplxPhase = 0
            expression = cmplxFmt(z) + key; displayText = cmplxFmt(z)
        case "=":
            let rhs = cmplxFromInput()
            let lhs = cmplxLhs ?? cmplxAns
            let op  = cmplxOp  ?? "+"
            var result = CasioComplex()
            switch op {
            case "+": result = lhs + rhs
            case "-": result = lhs - rhs
            case "×": result = lhs * rhs
            case "÷":
                guard rhs.magnitude > 1e-15 else { displayText = "Math ERROR"; return }
                result = lhs / rhs
            default: result = rhs
            }
            let label = cmplxFmt(lhs) + op + cmplxFmt(rhs)
            tape.append(TapeEntry(label: label, result: cmplxFmt(result)))
            expression = label; displayText = cmplxDisplayFmt(result)
            cmplxAns = result; cmplxLhs = nil; cmplxOp = nil
            cmplxReStr = ""; cmplxImStr = ""; cmplxPhase = 0
        case "Re":
            displayText = fmt(cmplxAns.re); expression = "Re(" + cmplxFmt(cmplxAns) + ")"
        case "Im":
            displayText = fmt(cmplxAns.im); expression = "Im(" + cmplxFmt(cmplxAns) + ")"
        case "|z|":
            displayText = fmt(cmplxAns.magnitude); expression = "|" + cmplxFmt(cmplxAns) + "|"
        case "Arg":
            displayText = fmt(angleUnit.fromRadians(cmplxAns.argument))
            expression = "Arg(" + cmplxFmt(cmplxAns) + ")"
        case "Conj":
            cmplxAns = cmplxAns.conjugate
            displayText = cmplxDisplayFmt(cmplxAns); expression = "Conj"
        case "POLAR":
            cmplxPolar.toggle()
            displayText = cmplxDisplayFmt(cmplxAns)
        default: break
        }
    }

    private func cmplxFromInput() -> CasioComplex {
        CasioComplex(re: Double(cmplxReStr) ?? 0, im: Double(cmplxImStr) ?? 0)
    }

    private func refreshCmplxDisplay() {
        let re = cmplxReStr.isEmpty ? "0" : cmplxReStr
        expression = cmplxPhase == 0 ? "Re:" : "Im:"
        if cmplxPhase == 0 { displayText = re }
        else {
            let im = cmplxImStr.isEmpty ? "?" : cmplxImStr
            displayText = re + (cmplxImStr.hasPrefix("-") ? "" : "+") + im + "i"
        }
    }

    func cmplxFmt(_ z: CasioComplex) -> String {
        let r = fmt(z.re), a = fmt(Swift.abs(z.im))
        if Swift.abs(z.im) < 1e-14 { return r }
        if Swift.abs(z.re) < 1e-14 { return (z.im < 0 ? "-" : "") + a + "i" }
        return r + (z.im < 0 ? "-" : "+") + a + "i"
    }

    // Formats z in the current display mode (rectangular or polar)
    func cmplxDisplayFmt(_ z: CasioComplex) -> String {
        if cmplxPolar {
            let r = fmt(z.magnitude)
            let theta = angleUnit.fromRadians(z.argument)
            return "\(r)∠\(fmt(theta))"
        }
        return cmplxFmt(z)
    }

    private func resetCmplx() {
        cmplxAns = CasioComplex(); cmplxLhs = nil; cmplxOp = nil
        cmplxReStr = ""; cmplxImStr = ""; cmplxPhase = 0
        cmplxPolar = false
        expression = "CMPLX"; displayText = "0"
    }

    // MARK: - MATRIX dispatch

    private func dispatchMatrix(_ key: String) {
        switch matPhase {

        case .select:
            switch key {
            case "A","MatA": startMatFill("A")
            case "B","MatB": startMatFill("B")
            case "C","MatC": startMatFill("C")
            case "AC":       resetMatrix()
            default: break
            }

        case .dimR:
            if let n = Int(key), (1...3).contains(n) {
                matrices[matTarget]?.rows = n
                matPhase = .dimC; expression = "Mat\(matTarget) \(n)×?"
                displayText = "Cols (1-3)?"
            } else if key == "AC" { resetMatrix() }

        case .dimC:
            if let n = Int(key), (1...3).contains(n) {
                let r = matrices[matTarget]?.rows ?? 2
                matrices[matTarget] = CasioMatrix(rows: r, cols: n)
                matCurRow = 0; matCurCol = 0; matInputStr = ""
                matPhase = .fill
                expression = "Mat\(matTarget)[\(matCurRow+1),\(matCurCol+1)]=?"
                displayText = "0"
            } else if key == "AC" { resetMatrix() }

        case .fill:
            switch key {
            case "0","1","2","3","4","5","6","7","8","9",".":
                matInputStr += key; displayText = matInputStr
            case "(-)":
                matInputStr = matInputStr.hasPrefix("-") ? String(matInputStr.dropFirst()) : "-"+matInputStr
                displayText = matInputStr.isEmpty ? "0" : matInputStr
            case "DEL","←":
                if !matInputStr.isEmpty { matInputStr.removeLast()
                    displayText = matInputStr.isEmpty ? "0" : matInputStr }
            case "=":
                matrices[matTarget]?.data[matCurRow][matCurCol] = Double(matInputStr) ?? 0
                matInputStr = ""
                let m = matrices[matTarget]!
                matCurCol += 1
                if matCurCol >= m.cols { matCurCol = 0; matCurRow += 1 }
                if matCurRow >= m.rows {
                    matPhase = .ops; expression = "Mat\(matTarget)"
                    displayText = matSummary(matTarget)
                } else {
                    expression = "Mat\(matTarget)[\(matCurRow+1),\(matCurCol+1)]=?"
                    displayText = "0"
                }
            case "AC": resetMatrix()
            default: break
            }

        case .ops:
            switch key {
            case "+","-","×":
                matLhsName = matTarget; matOp = key; matPhase = .rhs
                expression = "Mat\(matTarget)\(key)?"; displayText = "A B C"
            case "Det":
                guard let m = matrices[matTarget], m.rows == m.cols else { displayText = "Dim ERROR"; return }
                let d = matDet(m)
                tape.append(TapeEntry(label: "det(Mat\(matTarget))", result: fmt(d)))
                displayText = fmt(d); expression = "det(Mat\(matTarget))"
            case "Trn":
                guard let m = matrices[matTarget] else { return }
                matrices["Ans"] = matTranspose(m)
                matTarget = "Ans"; matPhase = .result
                displayText = matSummary("Ans"); expression = "Trn(Mat\(matTarget))"
            case "Inv":
                guard let m = matrices[matTarget], m.rows == m.cols else { displayText = "Dim ERROR"; return }
                guard let inv = matInverse(m) else { displayText = "Singular MAT"; return }
                matrices["Ans"] = inv; matTarget = "Ans"; matPhase = .result
                displayText = matSummary("Ans"); expression = "Mat\(matTarget)⁻¹"
            case "AC": resetMatrix()
            default:
                if ["A","B","C","MatA","MatB","MatC"].contains(key) {
                    let t = key.hasSuffix("A") ? "A" : key.hasSuffix("B") ? "B" : "C"
                    matTarget = t; expression = "Mat\(t)"; displayText = matSummary(t)
                }
            }

        case .rhs:
            let rhsName: String?
            switch key {
            case "A","MatA": rhsName = "A"
            case "B","MatB": rhsName = "B"
            case "C","MatC": rhsName = "C"
            case "AC":       resetMatrix(); return
            default:         rhsName = nil
            }
            guard let rn = rhsName,
                  let lhs = matrices[matLhsName ?? matTarget],
                  let rhs = matrices[rn] else { break }
            switch matOp {
            case "+":
                guard lhs.rows == rhs.rows, lhs.cols == rhs.cols else { displayText = "Dim ERROR"; matPhase = .ops; return }
                var res = CasioMatrix(rows: lhs.rows, cols: lhs.cols)
                for r in 0..<lhs.rows { for c in 0..<lhs.cols { res[r,c] = lhs[r,c] + rhs[r,c] } }
                matrices["Ans"] = res
            case "-":
                guard lhs.rows == rhs.rows, lhs.cols == rhs.cols else { displayText = "Dim ERROR"; matPhase = .ops; return }
                var res = CasioMatrix(rows: lhs.rows, cols: lhs.cols)
                for r in 0..<lhs.rows { for c in 0..<lhs.cols { res[r,c] = lhs[r,c] - rhs[r,c] } }
                matrices["Ans"] = res
            case "×":
                guard lhs.cols == rhs.rows else { displayText = "Dim ERROR"; matPhase = .ops; return }
                matrices["Ans"] = matMul(lhs, rhs)
            default: break
            }
            matTarget = "Ans"; matPhase = .result
            expression = "Mat\(matLhsName ?? "?")\(matOp ?? "")Mat\(rn)"
            displayText = matSummary("Ans")
            tape.append(TapeEntry(label: expression, result: displayText))

        case .result:
            if key == "AC" { resetMatrix() }
        }
    }

    // Matrix helpers
    private func startMatFill(_ name: String) {
        matTarget = name; matPhase = .dimR
        expression = "Mat\(name) Rows?"; displayText = "1-3"
    }

    private func matSummary(_ name: String) -> String {
        guard let m = matrices[name] else { return "?" }
        let rows = m.data.map { row in
            row.map { v in fmt(v) }.joined(separator: " ")
        }.joined(separator: " | ")
        return "[\(m.rows)×\(m.cols)] \(rows)"
    }

    private func matDet(_ m: CasioMatrix) -> Double {
        let n = m.rows
        if n == 1 { return m.data[0][0] }
        if n == 2 { return m.data[0][0]*m.data[1][1] - m.data[0][1]*m.data[1][0] }
        // 3×3 cofactor expansion
        var d = 0.0
        for c in 0..<n {
            var sub = CasioMatrix(rows: n-1, cols: n-1)
            for r in 1..<n {
                var cc = 0
                for j in 0..<n { if j == c { continue }; sub.data[r-1][cc] = m.data[r][j]; cc += 1 }
            }
            d += (c % 2 == 0 ? 1 : -1) * m.data[0][c] * matDet(sub)
        }
        return d
    }

    private func matTranspose(_ m: CasioMatrix) -> CasioMatrix {
        var t = CasioMatrix(rows: m.cols, cols: m.rows)
        for r in 0..<m.rows { for c in 0..<m.cols { t.data[c][r] = m.data[r][c] } }
        return t
    }

    private func matInverse(_ m: CasioMatrix) -> CasioMatrix? {
        let n = m.rows; guard n == m.cols else { return nil }
        var aug = m.data.enumerated().map { (i, row) -> [Double] in
            var r = row; r += Array(repeating: 0.0, count: n)
            r[n + i] = 1.0; return r
        }
        for col in 0..<n {
            guard let pivot = (col..<n).max(by: { Swift.abs(aug[$0][col]) < Swift.abs(aug[$1][col]) }) else { return nil }
            aug.swapAt(col, pivot)
            guard Swift.abs(aug[col][col]) > 1e-12 else { return nil }
            let scale = aug[col][col]
            aug[col] = aug[col].map { $0 / scale }
            for r in 0..<n where r != col {
                let f = aug[r][col]
                aug[r] = zip(aug[r], aug[col]).map { $0 - f * $1 }
            }
        }
        var inv = CasioMatrix(rows: n, cols: n)
        for r in 0..<n { for c in 0..<n { inv.data[r][c] = aug[r][n+c] } }
        return inv
    }

    private func matMul(_ a: CasioMatrix, _ b: CasioMatrix) -> CasioMatrix {
        var res = CasioMatrix(rows: a.rows, cols: b.cols)
        for i in 0..<a.rows { for j in 0..<b.cols { for k in 0..<a.cols {
            res.data[i][j] += a.data[i][k] * b.data[k][j]
        } } }
        return res
    }

    private func resetMatrix() {
        matPhase = .select; matTarget = "A"; matOp = nil; matLhsName = nil
        matCurRow = 0; matCurCol = 0; matInputStr = ""
        expression = "MATRIX"; displayText = "A  B  C"
    }

    // MARK: - VECTOR dispatch

    private func dispatchVector(_ key: String) {
        switch vctPhase {

        case .select:
            switch key {
            case "A","VctA": startVctFill("A")
            case "B","VctB": startVctFill("B")
            case "AC":       resetVector()
            default: break
            }

        case .dim:
            switch key {
            case "2": setVctDim("A", dim: 2); setVctDim("B", dim: 2)
                      vctCurIdx = 0; vctInputStr = ""
                      vctPhase = .fill
                      expression = "Vct\(vctTarget)[\(vctCurIdx+1)]=?"; displayText = "0"
            case "3": setVctDim("A", dim: 3); setVctDim("B", dim: 3)
                      vctCurIdx = 0; vctInputStr = ""
                      vctPhase = .fill
                      expression = "Vct\(vctTarget)[\(vctCurIdx+1)]=?"; displayText = "0"
            case "AC": resetVector()
            default: break
            }

        case .fill:
            switch key {
            case "0","1","2","3","4","5","6","7","8","9",".":
                vctInputStr += key; displayText = vctInputStr
            case "(-)":
                vctInputStr = vctInputStr.hasPrefix("-") ? String(vctInputStr.dropFirst()) : "-"+vctInputStr
                displayText = vctInputStr.isEmpty ? "0" : vctInputStr
            case "DEL","←":
                if !vctInputStr.isEmpty { vctInputStr.removeLast()
                    displayText = vctInputStr.isEmpty ? "0" : vctInputStr }
            case "=":
                vectors[vctTarget]?[vctCurIdx] = Double(vctInputStr) ?? 0
                vctInputStr = ""; vctCurIdx += 1
                let dim = vectors[vctTarget]?.count ?? 2
                if vctCurIdx >= dim {
                    vctPhase = .ops; expression = "Vct\(vctTarget)"
                    displayText = vctSummary(vctTarget)
                } else {
                    expression = "Vct\(vctTarget)[\(vctCurIdx+1)]=?"; displayText = "0"
                }
            case "AC": resetVector()
            default: break
            }

        case .ops:
            switch key {
            case "+","-":
                vctLhsName = vctTarget; vctOp = key; vctPhase = .rhs
                expression = "Vct\(vctTarget)\(key)?"; displayText = "A  B"
            case "·","Dot":
                vctLhsName = vctTarget; vctOp = "·"; vctPhase = .rhs
                expression = "Vct\(vctTarget)·?"; displayText = "A  B"
            case "×","Cross":
                vctLhsName = vctTarget; vctOp = "×"; vctPhase = .rhs
                expression = "Vct\(vctTarget)×?"; displayText = "A  B"
            case "|v|":
                let v = vectors[vctTarget] ?? []
                let mag = v.map { $0*$0 }.reduce(0,+).squareRoot()
                tape.append(TapeEntry(label: "|Vct\(vctTarget)|", result: fmt(mag)))
                displayText = fmt(mag); expression = "|Vct\(vctTarget)|"
            case "Ang":
                guard let a = vectors["A"], let b = vectors["B"],
                      a.count == b.count else { displayText = "Dim ERROR"; return }
                let dot = zip(a,b).map(*).reduce(0,+)
                let ma = a.map{$0*$0}.reduce(0,+).squareRoot()
                let mb = b.map{$0*$0}.reduce(0,+).squareRoot()
                guard ma > 1e-15, mb > 1e-15 else { displayText = "Math ERROR"; return }
                let angle = angleUnit.fromRadians(acos(max(-1, min(1, dot/(ma*mb)))))
                displayText = fmt(angle); expression = "∠(VctA,VctB)"
            case "AC": resetVector()
            default:
                if ["A","VctA"].contains(key) { vctTarget = "A"; expression = "VctA"; displayText = vctSummary("A") }
                if ["B","VctB"].contains(key) { vctTarget = "B"; expression = "VctB"; displayText = vctSummary("B") }
            }

        case .rhs:
            let rhsName: String?
            switch key {
            case "A","VctA": rhsName = "A"
            case "B","VctB": rhsName = "B"
            case "AC":       resetVector(); return
            default:         rhsName = nil
            }
            guard let rn = rhsName,
                  let lv = vectors[vctLhsName ?? vctTarget],
                  let rv = vectors[rn] else { break }
            switch vctOp {
            case "+":
                guard lv.count == rv.count else { displayText = "Dim ERROR"; vctPhase = .ops; return }
                let res = zip(lv, rv).map(+)
                vectors["Ans"] = res; vctTarget = "Ans"; vctPhase = .result
                displayText = vctSummary("Ans")
            case "-":
                guard lv.count == rv.count else { displayText = "Dim ERROR"; vctPhase = .ops; return }
                let res = zip(lv, rv).map(-)
                vectors["Ans"] = res; vctTarget = "Ans"; vctPhase = .result
                displayText = vctSummary("Ans")
            case "·":
                guard lv.count == rv.count else { displayText = "Dim ERROR"; vctPhase = .ops; return }
                let dot = zip(lv, rv).map(*).reduce(0,+)
                tape.append(TapeEntry(label: "Vct\(vctLhsName ?? "?")·Vct\(rn)", result: fmt(dot)))
                displayText = fmt(dot); expression = "Vct\(vctLhsName ?? "?")·Vct\(rn)"
                vctPhase = .ops; return
            case "×":
                guard lv.count == 3, rv.count == 3 else { displayText = "3D only"; vctPhase = .ops; return }
                let cx = lv[1]*rv[2] - lv[2]*rv[1]
                let cy = lv[2]*rv[0] - lv[0]*rv[2]
                let cz = lv[0]*rv[1] - lv[1]*rv[0]
                vectors["Ans"] = [cx, cy, cz]; vctTarget = "Ans"; vctPhase = .result
                displayText = vctSummary("Ans")
            default: break
            }
            expression = "Vct\(vctLhsName ?? "?")\(vctOp ?? "")Vct\(rn)"
            tape.append(TapeEntry(label: expression, result: displayText))

        case .result:
            if key == "AC" { resetVector() }
        }
    }

    private func startVctFill(_ name: String) {
        vctTarget = name; vctPhase = .dim
        expression = "Vct\(name) Dim?"; displayText = "2  or  3"
    }

    private func setVctDim(_ name: String, dim: Int) {
        vectors[name] = Array(repeating: 0.0, count: dim)
    }

    private func vctSummary(_ name: String) -> String {
        guard let v = vectors[name] else { return "?" }
        return "(" + v.map { fmt($0) }.joined(separator: ", ") + ")"
    }

    private func resetVector() {
        vctPhase = .select; vctTarget = "A"; vctOp = nil; vctLhsName = nil
        vctCurIdx = 0; vctInputStr = ""
        expression = "VECTOR"; displayText = "A  B"
    }

    // MARK: - TABLE dispatch

    private func dispatchTable(_ key: String) {
        switch tablePhase {

        case .expr:
            switch key {
            case "AC":                 resetTable()
            case "=":
                if !tableExpr.isEmpty {
                    tablePhase = .start; tableInputStr = ""
                    expression = "f(x)=\(tableExpr)"; displayText = "Start?"
                }
            case "DEL","←":
                if !tableExpr.isEmpty { tableExpr.removeLast()
                    expression = "f(x)="; displayText = tableExpr.isEmpty ? "_" : tableExpr }
            default:
                // Allow any expression input the user types
                tableExpr += key
                expression = "f(x)="; displayText = tableExpr
            }

        case .start:
            numericEntry(key, into: &tableInputStr,
                         prompt: "f(x)=\(tableExpr)  Start?",
                         onCommit: { v in
                             self.tableStart = v
                             self.tablePhase = .end; self.tableInputStr = ""
                             self.expression = "Start=\(self.fmt(v))"; self.displayText = "End?"
                         },
                         onAC: resetTable)

        case .end:
            numericEntry(key, into: &tableInputStr,
                         prompt: "Start=\(fmt(tableStart))  End?",
                         onCommit: { v in
                             self.tableEnd = v
                             self.tablePhase = .step; self.tableInputStr = ""
                             self.expression = "End=\(self.fmt(v))"; self.displayText = "Step?"
                         },
                         onAC: resetTable)

        case .step:
            numericEntry(key, into: &tableInputStr,
                         prompt: "End=\(fmt(tableEnd))  Step?",
                         onCommit: { v in
                             guard v != 0 else { self.displayText = "Step≠0"; return }
                             self.tableStep = v
                             self.generateTable()
                         },
                         onAC: resetTable)

        case .view:
            switch key {
            case "AC":              resetTable()
            case "↑","UP":          tableViewRow = max(0, tableViewRow - 1); showTableRow()
            case "↓","DOWN":        tableViewRow = min(tableData.count-1, tableViewRow + 1); showTableRow()
            case "=","↓","Scroll":  tableViewRow = min(tableData.count-1, tableViewRow + 1); showTableRow()
            default: break
            }
        }
    }

    private func numericEntry(_ key: String, into str: inout String,
                              prompt: String, onCommit: (Double) -> Void, onAC: () -> Void) {
        switch key {
        case "0","1","2","3","4","5","6","7","8","9",".":
            str += key; displayText = str
        case "(-)":
            str = str.hasPrefix("-") ? String(str.dropFirst()) : "-"+str
            displayText = str.isEmpty ? "0" : str
        case "DEL","←":
            if !str.isEmpty { str.removeLast(); displayText = str.isEmpty ? "0" : str }
        case "=":
            onCommit(Double(str) ?? 0)
        case "AC":
            onAC()
        default: break
        }
    }

    private func generateTable() {
        tableData = []
        var x = tableStart
        let sign: Double = tableStep > 0 ? 1 : -1
        while sign * x <= sign * tableEnd + 1e-10 {
            if let fx = evaluateTable(x) {
                tableData.append((x: x, fx: fx))
            }
            x += tableStep
        }
        guard !tableData.isEmpty else { displayText = "No data"; return }
        tablePhase = .view; tableViewRow = 0
        showTableRow()
    }

    private func showTableRow() {
        guard tableViewRow < tableData.count else { return }
        let row = tableData[tableViewRow]
        expression = "x=\(fmt(row.x))"
        displayText = fmt(row.fx)
    }

    private func evaluateTable(_ x: Double) -> Double? {
        var s = tableExpr
        s = s.replacingOccurrences(of: "x", with: "(\(fmt(x)))")
        s = s.replacingOccurrences(of: "Ans", with: "(\(fmt(ans)))")
        for (k, v) in vars { s = s.replacingOccurrences(of: k, with: "(\(fmt(v)))") }
        var p = ExprParser(input: s, angle: angleUnit)
        guard let result = p.parseExpr(), p.atEnd else { return nil }
        return result.isFinite ? result : nil
    }

    private func resetTable() {
        tableExpr = ""; tableStart = 1; tableEnd = 5; tableStep = 1
        tablePhase = .expr; tableData = []; tableViewRow = 0; tableInputStr = ""
        expression = "f(x)="; displayText = "_"
        tape = []
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

        // Stat result recall
        case "n","x̄","Σx","Σx²","σx","Sx","minX","maxX",
             "ȳ","Σy","Σy²","σy","Sy","Σxy","a","b","c","r":
            if let v = statResult(key) {
                let r = fmt(v)
                tape.append(TapeEntry(label: key, result: r))
                expression = key; displayText = r
            } else {
                displayText = "No Data"
            }

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
        case "σx":  return sqrt(max(0, sx2/n - xm*xm))
        case "Sx":  return n>1 ? sqrt(max(0, (sx2 - n*xm*xm)/(n-1))) : nil
        case "σy":  return sqrt(max(0, sy2/n - ym*ym))
        case "Sy":  return n>1 ? sqrt(max(0, (sy2 - n*ym*ym)/(n-1))) : nil
        case "minX":return xs.min()
        case "maxX":return xs.max()
        default: break
        }

        // Regression coefficients — mode-dependent
        switch statSubMode {
        case .oneVar:
            return nil

        case .linReg:
            let r = linReg(xs, ys)
            switch key { case "a": return r.a; case "b": return r.b; case "r": return r.r; default: return nil }

        case .quadReg:
            guard xs.count >= 3 else { return nil }
            let q = quadReg(xs, ys)
            switch key { case "a": return q.a; case "b": return q.b; case "c": return q.c; default: return nil }

        case .logReg:
            guard xs.allSatisfy({ $0 > 0 }) else { return nil }
            let r = linReg(xs.map { log($0) }, ys)
            switch key { case "a": return r.a; case "b": return r.b; case "r": return r.r; default: return nil }

        case .expReg:
            guard ys.allSatisfy({ $0 > 0 }) else { return nil }
            let r = linReg(xs, ys.map { log($0) })
            switch key { case "a": return exp(r.a); case "b": return r.b; case "r": return r.r; default: return nil }

        case .powerReg:
            guard xs.allSatisfy({ $0 > 0 }), ys.allSatisfy({ $0 > 0 }) else { return nil }
            let r = linReg(xs.map { log($0) }, ys.map { log($0) })
            switch key { case "a": return exp(r.a); case "b": return r.b; case "r": return r.r; default: return nil }

        case .invReg:
            guard xs.allSatisfy({ $0 != 0 }) else { return nil }
            let r = linReg(xs.map { 1.0/$0 }, ys)
            switch key { case "a": return r.a; case "b": return r.b; case "r": return r.r; default: return nil }
        }
    }

    private func linReg(_ xs:[Double],_ ys:[Double]) -> (a:Double,b:Double,r:Double) {
        let n = Double(xs.count)
        let sx = xs.reduce(0,+), sy = ys.reduce(0,+)
        let sx2 = xs.map{$0*$0}.reduce(0,+), sy2 = ys.map{$0*$0}.reduce(0,+)
        let sxy = zip(xs,ys).map(*).reduce(0,+)
        let b = (n*sxy - sx*sy) / (n*sx2 - sx*sx)
        let a = (sy - b*sx) / n
        let denom = sqrt(max(0, (n*sx2-sx*sx) * (n*sy2-sy*sy)))
        let r = denom == 0 ? 0 : (n*sxy - sx*sy) / denom
        return (a, b, r)
    }

    // Quadratic regression: y = a + bx + cx²
    // Solves the 3×3 normal-equations system via Gaussian elimination.
    private func quadReg(_ xs:[Double],_ ys:[Double]) -> (a:Double,b:Double,c:Double) {
        let n  = Double(xs.count)
        let s1 = xs.reduce(0,+)
        let s2 = xs.map{$0*$0}.reduce(0,+)
        let s3 = xs.map{$0*$0*$0}.reduce(0,+)
        let s4 = xs.map{$0*$0*$0*$0}.reduce(0,+)
        let t0 = ys.reduce(0,+)
        let t1 = zip(xs,ys).map{$0*$1}.reduce(0,+)
        let t2 = zip(xs.map{$0*$0},ys).map{$0*$1}.reduce(0,+)

        // Augmented matrix [A|b]
        var m: [[Double]] = [
            [n,  s1, s2, t0],
            [s1, s2, s3, t1],
            [s2, s3, s4, t2],
        ]
        for col in 0..<3 {
            var maxRow = col
            for row in (col+1)..<3 { if Swift.abs(m[row][col]) > Swift.abs(m[maxRow][col]) { maxRow = row } }
            m.swapAt(col, maxRow)
            guard Swift.abs(m[col][col]) > 1e-15 else { return (0, 0, 0) }
            let piv = m[col][col]
            m[col] = m[col].map { $0 / piv }
            for row in 0..<3 where row != col {
                let f = m[row][col]
                m[row] = zip(m[row], m[col]).map { $0 - f * $1 }
            }
        }
        return (m[0][3], m[1][3], m[2][3])
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
            guard let r = BaseRadix(rawValue: key) else { return }
            let cur = baseNParse(baseNInputStr)
            baseRadix = r
            baseNInputStr = baseNFormat(cur)
            displayText = baseNInputStr
            expression = baseNCtxExpr()

        case "AC":
            resetBaseN()

        case "DEL","←":
            if baseNInputStr.count > 1 { baseNInputStr.removeLast() }
            else { baseNInputStr = "0" }
            displayText = baseNInputStr

        case "AND","OR","XOR","XNOR":
            baseNLhsVal = baseNParse(baseNInputStr)
            baseNOp = key
            baseNInputStr = "0"
            expression = "\(baseNFormat(baseNLhsVal)) \(key)"
            displayText = "0"

        case "NOT":
            let v = baseNParse(baseNInputStr)
            let r = baseNFormat((~v) & 0xFFFF_FFFF)
            tape.append(TapeEntry(label: "NOT \(baseNInputStr)", result: r))
            baseNInputStr = r; expression = ""; displayText = r

        case "NEG":
            let v = baseNParse(baseNInputStr)
            let r = baseNFormat((-v) & 0xFFFF_FFFF)
            tape.append(TapeEntry(label: "NEG \(baseNInputStr)", result: r))
            baseNInputStr = r; expression = ""; displayText = r

        case "=":
            guard let op = baseNOp else { return }
            let lhs = baseNLhsVal
            let rhs = baseNParse(baseNInputStr)
            let result: Int
            switch op {
            case "AND":  result = (lhs & rhs)     & 0xFFFF_FFFF
            case "OR":   result = (lhs | rhs)     & 0xFFFF_FFFF
            case "XOR":  result = (lhs ^ rhs)     & 0xFFFF_FFFF
            case "XNOR": result = (~(lhs ^ rhs))  & 0xFFFF_FFFF
            default: return
            }
            let label = "\(baseNFormat(lhs)) \(op) \(baseNFormat(rhs))"
            let r = baseNFormat(result)
            tape.append(TapeEntry(label: label, result: r))
            baseNInputStr = r; baseNLhsVal = 0; baseNOp = nil
            expression = label; displayText = r

        default:
            let k = key.uppercased()
            let (valid, maxLen): (Set<String>, Int)
            switch baseRadix {
            case .bin: valid = Set("01".map(String.init));         maxLen = 32
            case .oct: valid = Set("01234567".map(String.init));   maxLen = 11
            case .dec: valid = Set("0123456789".map(String.init)); maxLen = 10
            case .hex: valid = Set("0123456789ABCDEF".map(String.init)); maxLen = 8
            }
            guard valid.contains(k), baseNInputStr.count < maxLen else { return }
            if baseNInputStr == "0" { baseNInputStr = k } else { baseNInputStr += k }
            displayText = baseNInputStr
            expression = baseNCtxExpr()
        }
    }

    private func resetBaseN() {
        baseNLhsVal = 0; baseNOp = nil; baseNInputStr = "0"
        expression = ""; displayText = "0"
    }

    private func baseNParse(_ s: String) -> Int {
        (Int(s, radix: radixBase(baseRadix)) ?? 0) & 0xFFFF_FFFF
    }

    private func baseNFormat(_ v: Int) -> String {
        String(v & 0xFFFF_FFFF, radix: radixBase(baseRadix), uppercase: true)
    }

    private func baseNCtxExpr() -> String {
        guard let op = baseNOp else { return "" }
        return "\(baseNFormat(baseNLhsVal)) \(op)"
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

    private func decimalToFraction(_ x: Double, maxDenom: Int) -> String? {
        guard !x.isInfinite, !x.isNaN else { return nil }
        let neg = x < 0
        let v = Swift.abs(x)
        let whole = Int(v)
        let frac = v - Double(whole)
        guard frac > 1e-10 else { return nil }
        var p0 = 0, q0 = 1, p1 = 1, q1 = 0
        var x1 = frac
        for _ in 0..<30 {
            let a = Int(x1)
            let p2 = a * p1 + p0
            let q2 = a * q1 + q0
            if q2 > maxDenom { break }
            p0 = p1; q0 = q1; p1 = p2; q1 = q2
            let rem = x1 - Double(a)
            if rem < 1e-12 { break }
            x1 = 1.0 / rem
        }
        guard q1 > 1, Swift.abs(Double(p1)/Double(q1) - frac) < 1e-9 else { return nil }
        let sign = neg ? "-" : ""
        return whole == 0 ? "\(sign)\(p1)/\(q1)" : "\(sign)\(whole)+\(p1)/\(q1)"
    }
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
            var args: [Double] = []
            if let a1 = parseExpr() {
                args.append(a1)
                while let c2 = cur, case .comma = c2 { pos += 1; if let a = parseExpr() { args.append(a) } }
            }
            if let c3 = cur, case .rp = c3 { pos += 1 }
            return applyFn(name, args)
        default: return nil
        }
    }

    // MARK: Function application

    private func applyFn(_ name: String, _ args: [Double]) -> Double? {
        let a = args.first ?? 0
        let b: Double? = args.count > 1 ? args[1] : nil
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

        // Statistical distributions
        // NormPD(x, σ, μ)
        case "NormPD":
            let sigma = args.count > 1 ? args[1] : 1.0
            let mu    = args.count > 2 ? args[2] : 0.0
            guard sigma > 0 else { return nil }
            let z = (a - mu) / sigma
            return exp(-0.5*z*z) / (sigma * sqrt(2 * .pi))

        // NormCD(lower, upper, σ, μ)
        case "NormCD":
            guard args.count >= 2 else { return nil }
            let upper = args[1]
            let sigma = args.count > 2 ? args[2] : 1.0
            let mu    = args.count > 3 ? args[3] : 0.0
            guard sigma > 0 else { return nil }
            return normCDF((upper-mu)/sigma) - normCDF((a-mu)/sigma)

        // InvNorm(area, σ, μ)  — area = cumulative probability
        case "InvNorm":
            let sigma = args.count > 1 ? args[1] : 1.0
            let mu    = args.count > 2 ? args[2] : 0.0
            guard a > 0, a < 1, sigma > 0 else { return nil }
            return mu + sigma * invNormCDF(a)

        // BinomPD(k, n, p)
        case "BinomPD":
            guard args.count >= 3 else { return nil }
            let n = args[1]; let p = args[2]
            guard p >= 0, p <= 1, n >= 0, a >= 0, a <= n else { return nil }
            let k = Int(a.rounded()); let ni = Int(n.rounded())
            return exp(logComb(ni, k) + Double(k)*log(max(p,1e-300)) + Double(ni-k)*log(max(1-p,1e-300)))

        // BinomCD(k, n, p) — cumulative P(X ≤ k)
        case "BinomCD":
            guard args.count >= 3 else { return nil }
            let n = args[1]; let p = args[2]
            guard p >= 0, p <= 1, n >= 0, a >= 0, a <= n else { return nil }
            let kMax = Int(a.rounded()); let ni = Int(n.rounded())
            var sum = 0.0
            for k in 0...kMax {
                sum += exp(logComb(ni, k) + Double(k)*log(max(p,1e-300)) + Double(ni-k)*log(max(1-p,1e-300)))
            }
            return sum

        // PoissonPD(k, λ)
        case "PoissonPD":
            guard args.count >= 2 else { return nil }
            let lambda = args[1]
            guard lambda > 0, a >= 0 else { return nil }
            let k = Int(a.rounded())
            return exp(Double(k)*log(lambda) - lambda - lgamma(Double(k+1)))

        // PoissonCD(k, λ) — cumulative P(X ≤ k)
        case "PoissonCD":
            guard args.count >= 2 else { return nil }
            let lambda = args[1]
            guard lambda > 0, a >= 0 else { return nil }
            let kMax = Int(a.rounded())
            var sum = 0.0
            for k in 0...kMax {
                sum += exp(Double(k)*log(lambda) - lambda - lgamma(Double(k+1)))
            }
            return sum

        case "Pol":
            // Pol(x, y) → r  (θ stored in Y by dispatchComp after evaluation)
            guard let y = b else { return nil }
            return sqrt(a*a + y*y)

        case "Rec":
            // Rec(r, θ) → x  (y-component stored in Y by dispatchComp after evaluation)
            guard let theta = b else { return nil }
            let thetaRad = angle.toRadians(theta)
            return a * cos(thetaRad)

        default: return nil
        }
    }

    // Standard normal CDF via erf
    private func normCDF(_ z: Double) -> Double {
        return 0.5 * (1.0 + erf(z / sqrt(2.0)))
    }

    // Inverse normal CDF — Acklam's rational approximation (max error ≈ 1.15e-9)
    private func invNormCDF(_ p: Double) -> Double {
        let a = [-3.969683028665376e+01,  2.209460984245205e+02,
                 -2.759285104469687e+02,  1.383577518672690e+02,
                 -3.066479806614716e+01,  2.506628277459239e+00]
        let b = [-5.447609879822406e+01,  1.615858368580409e+02,
                 -1.556989798598866e+02,  6.680131188771972e+01,
                 -1.328068155288572e+01]
        let c = [-7.784894002430293e-03, -3.223964580411365e-01,
                 -2.400758277161838e+00, -2.549732539343734e+00,
                  4.374664141464968e+00,  2.938163982698783e+00]
        let d = [ 7.784695709041462e-03,  3.224671290700398e-01,
                  2.445134137142996e+00,  3.754408661907416e+00]
        let plo = 0.02425, phi = 1 - plo
        if p < plo {
            let q = sqrt(-2*log(p))
            return (((((c[0]*q+c[1])*q+c[2])*q+c[3])*q+c[4])*q+c[5]) /
                   ((((d[0]*q+d[1])*q+d[2])*q+d[3])*q+1)
        } else if p <= phi {
            let q = p - 0.5; let r = q*q
            return (((((a[0]*r+a[1])*r+a[2])*r+a[3])*r+a[4])*r+a[5])*q /
                   (((((b[0]*r+b[1])*r+b[2])*r+b[3])*r+b[4])*r+1)
        } else {
            let q = sqrt(-2*log(1-p))
            return -(((((c[0]*q+c[1])*q+c[2])*q+c[3])*q+c[4])*q+c[5]) /
                    ((((d[0]*q+d[1])*q+d[2])*q+d[3])*q+1)
        }
    }

    // log(C(n,k)) using lgamma for numerical stability
    private func logComb(_ n: Int, _ k: Int) -> Double {
        guard k >= 0, k <= n else { return -Double.infinity }
        return lgamma(Double(n+1)) - lgamma(Double(k+1)) - lgamma(Double(n-k+1))
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
            "GCD","LCM","Rem","RanInt","RandInt",
            "NormPD","NormCD","InvNorm","BinomPD","BinomCD","PoissonPD","PoissonCD",
            "Pol","Rec"
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
