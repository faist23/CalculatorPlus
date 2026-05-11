import SwiftUI

// MARK: - Key model

private struct CKey: Hashable {
    let main:  String
    let shift: String  // orange label (SHIFT active)
    let alpha: String  // red label   (ALPHA active)
    init(_ m: String, s: String = "", a: String = "") { main = m; shift = s; alpha = a }
}

// MARK: - Main View

struct CasioCalculatorView: View {
    @Binding var active: CalculatorType
    let engine: CasioEngine

    @State private var shiftOn        = false
    @State private var alphaOn        = false
    @State private var showModePicker = false
    @State private var showCalcPicker = false
    @State private var showEqnPicker  = false
    @State private var showStatPicker = false

    // MARK: Key grid — 5 cols × 9 rows (modifier + 8 function/number rows)

    private let modRow: [CKey] = [
        CKey("SHIFT"), CKey("ALPHA"), CKey("MODE"), CKey("DEL"), CKey("AC"),
    ]
    private let row1: [CKey] = [
        CKey("sin",  s: "sin⁻¹", a: "A"),
        CKey("cos",  s: "cos⁻¹", a: "B"),
        CKey("tan",  s: "tan⁻¹", a: "C"),
        CKey("log",  s: "10^x",  a: "D"),
        CKey("ln",   s: "e^x",   a: "E"),
    ]
    private let row2: [CKey] = [
        CKey("x²",  s: "x³",    a: "F"),
        CKey("√",   s: "³√",    a: "X"),
        CKey("^",   s: "1/x",   a: "Y"),
        CKey("(",   s: "Abs",   a: "M"),
        CKey(")",   s: "Frac"),
    ]
    private let row3: [CKey] = [
        CKey("HYP",  s: "HYP"),
        CKey("nCr",  s: "nPr"),
        CKey("x!",   s: "Ran#"),
        CKey("GCD",  s: "LCM"),
        CKey("%",    s: "Int"),
    ]
    private let row4: [CKey] = [
        CKey("STO",  s: "RCL"),
        CKey("RCL",  s: "STO"),
        CKey("Ans",  s: "DRG"),
        CKey("π",    s: "e"),
        CKey("M+",   s: "M-"),
    ]
    private let row5: [CKey] = [
        CKey("7"), CKey("8"), CKey("9"), CKey("÷", s: "log_b"), CKey("×", s: "Rem"),
    ]
    private let row6: [CKey] = [
        CKey("4"), CKey("5"), CKey("6"), CKey("-"), CKey("+"),
    ]
    private let row7: [CKey] = [
        CKey("1"), CKey("2"), CKey("3"), CKey("(-)"), CKey("EXP"),
    ]
    private let row8: [CKey] = [
        CKey("0"), CKey("."), CKey("×10ˣ", s: "Rnd"), CKey("Σ+", s: "Σ−"), CKey("="),
    ]

    // MARK: Mode-specific function rows (rows 1-4)

    private var cmplxFnRows: [[CKey]] { [
        [CKey("i"), CKey("Re"), CKey("Im"), CKey("|z|"), CKey("Arg")],
        [CKey("Conj"), CKey("+"), CKey("-"), CKey("×"), CKey("÷")],
        [CKey("sin", s:"sin⁻¹"), CKey("cos", s:"cos⁻¹"), CKey("tan", s:"tan⁻¹"),
         CKey("log", s:"10^x"), CKey("ln", s:"e^x")],
        [CKey("STO"), CKey("RCL"), CKey("Ans"), CKey("π"), CKey("M+")],
    ] }

    private var matFnRows: [[CKey]] { [
        [CKey("MatA",s:""), CKey("MatB",s:""), CKey("MatC",s:""), CKey("Det",s:""), CKey("Trn",s:"")],
        [CKey("Inv",s:""),  CKey("+",s:""),    CKey("-",s:""),    CKey("×",s:""),   CKey("=",s:"")],
        [CKey("A",s:""),    CKey("B",s:""),    CKey("C",s:""),    CKey("(-)"),       CKey("DEL",s:"")],
        [CKey("STO"),       CKey("RCL"),       CKey("Ans"),       CKey("π"),        CKey("M+")],
    ] }

    private var vctFnRows: [[CKey]] { [
        [CKey("VctA",s:""), CKey("VctB",s:""), CKey("·",s:"Dot"), CKey("×",s:"Cross"), CKey("|v|",s:"")],
        [CKey("+",s:""),    CKey("-",s:""),    CKey("Ang",s:""),  CKey("A",s:""),       CKey("B",s:"")],
        [CKey("sin",s:"sin⁻¹"),CKey("cos",s:"cos⁻¹"),CKey("tan",s:"tan⁻¹"),
         CKey("log",s:"10^x"),CKey("ln",s:"e^x")],
        [CKey("STO"),       CKey("RCL"),       CKey("Ans"),       CKey("π"),           CKey("M+")],
    ] }

    private var tableFnRows: [[CKey]] { [
        [CKey("sin",s:"sin⁻¹"),CKey("cos",s:"cos⁻¹"),CKey("tan",s:"tan⁻¹"),
         CKey("log",s:"10^x"),CKey("ln",s:"e^x")],
        [CKey("x²",s:"x³"),   CKey("√",s:"³√"),      CKey("^",s:"1/x"),
         CKey("(",s:"Abs"),   CKey(")",s:"Frac")],
        [CKey("↑",s:"UP"),    CKey("↓",s:"DOWN"),    CKey("π",s:"e"),
         CKey("x",s:""),      CKey("Ans",s:"")],
        [CKey("STO"),          CKey("RCL"),            CKey("(-)"),
         CKey("DEL"),          CKey("=")],
    ] }

    private var activeFnRows: [[CKey]] {
        switch engine.mode {
        case .cmplx:  return cmplxFnRows
        case .matrix: return matFnRows
        case .vector: return vctFnRows
        case .table:  return tableFnRows
        default:      return [row1, row2, row3, row4]
        }
    }

    var body: some View {
        VStack(spacing: 5) {
            lcdDisplay

            GeometryReader { geo in
                let hPad: CGFloat = 10
                let hGap: CGFloat = 4
                let vGap: CGFloat = 2
                let cols: CGFloat = 5
                let btnW   = (geo.size.width - hPad * 2 - hGap * (cols - 1)) / cols
                let modH   = max(16, min(24, geo.size.height * 0.065))
                let availH = geo.size.height - modH - vGap * 9
                let btnH   = availH / 8

                let fn = activeFnRows

                VStack(spacing: vGap) {
                    keyRow(modRow,  w: btnW, h: modH)
                    keyRow(fn[0],   w: btnW, h: btnH)
                    keyRow(fn[1],   w: btnW, h: btnH)
                    keyRow(fn[2],   w: btnW, h: btnH)
                    keyRow(fn[3],   w: btnW, h: btnH)
                    keyRow(row5,    w: btnW, h: btnH)
                    keyRow(row6,    w: btnW, h: btnH)
                    keyRow(row7,    w: btnW, h: btnH)
                    keyRow(row8,    w: btnW, h: btnH)
                }
                .padding(.horizontal, hPad)
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5).onEnded { _ in showCalcPicker = true }
            )
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.13, blue: 0.18),
                         Color(red: 0.07, green: 0.07, blue: 0.10)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
        )
        // Mode picker
        .confirmationDialog("Calculator Mode", isPresented: $showModePicker, titleVisibility: .visible) {
            Button("1: COMP")   { engine.mode = .comp }
            Button("2: CMPLX") { engine.mode = .cmplx }
            Button("3: STAT")  { showStatPicker = true }
            Button("4: BASE-N") { engine.mode = .baseN }
            Button("5: EQN")   { showEqnPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        // EQN sub-mode
        .confirmationDialog("Equation Type", isPresented: $showEqnPicker, titleVisibility: .visible) {
            Button("1: Quadratic")        { engine.eqnSubMode = .quad;  engine.mode = .eqn }
            Button("2: Cubic")            { engine.eqnSubMode = .cubic; engine.mode = .eqn }
            Button("3: Simultaneous 2×2") { engine.eqnSubMode = .sim2;  engine.mode = .eqn }
            Button("4: Simultaneous 3×3") { engine.eqnSubMode = .sim3;  engine.mode = .eqn }
            Button("Cancel", role: .cancel) {}
        }
        // STAT sub-mode
        .confirmationDialog("Statistics Type", isPresented: $showStatPicker, titleVisibility: .visible) {
            Button("1: 1-VAR")       { engine.statSubMode = .oneVar;  engine.mode = .stat }
            Button("2: y=a+bx")      { engine.statSubMode = .linReg;  engine.mode = .stat }
            Button("3: y=a+bx²")     { engine.statSubMode = .quadReg; engine.mode = .stat }
            Button("4: y=a+b·lnx")   { engine.statSubMode = .logReg;  engine.mode = .stat }
            Button("5: y=a·e^bx")    { engine.statSubMode = .expReg;  engine.mode = .stat }
            Button("6: y=a·x^b")     { engine.statSubMode = .powerReg;engine.mode = .stat }
            Button("7: y=a+b/x")     { engine.statSubMode = .invReg;  engine.mode = .stat }
            Button("Cancel", role: .cancel) {}
        }
        // Calc switcher
        .confirmationDialog("Switch Calculator", isPresented: $showCalcPicker, titleVisibility: .visible) {
            Button(CalculatorType.hp12c.rawValue) { active = .hp12c }
            Button(CalculatorType.hp15c.rawValue) { active = .hp15c }
            Button(CalculatorType.casio.rawValue)  { active = .casio }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - LCD

    @ViewBuilder
    private var lcdDisplay: some View {
        let hasTape = !engine.tape.isEmpty
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.79, green: 0.84, blue: 0.74))

            VStack(spacing: 0) {
                // Annunciator strip
                HStack(spacing: 5) {
                    ann(engine.modeLabel, .black.opacity(0.55))
                    ann(engine.angleLabel, .black.opacity(0.55))
                    if engine.hypActive { ann("HYP", Color(red:0.85,green:0.60,blue:0.04)) }
                    if engine.stoActive { ann("STO", Color(red:0.15,green:0.52,blue:0.22)) }
                    if engine.rclActive { ann("RCL", Color(red:0.15,green:0.52,blue:0.22)) }
                    if shiftOn { ann("SHIFT", Color(red:0.85,green:0.60,blue:0.04)) }
                    if alphaOn { ann("ALPHA", Color(red:0.72,green:0.12,blue:0.12)) }
                    Spacer()
                    Button { showCalcPicker = true } label: {
                        Text(active.rawValue)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.black.opacity(0.45))
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 8).padding(.top, 4).frame(height: 18)

                if hasTape {
                    TapeView(entries: engine.tape, onRecall: { engine.recallTapeValue($0) })
                        .frame(maxHeight: 48)
                }

                Spacer(minLength: 2)

                // Expression line (natural display — what the user typed)
                HStack {
                    Spacer()
                    Text(engine.expression.isEmpty ? " " : engine.expression)
                        .font(.custom("Courier", size: 15))
                        .foregroundColor(.black.opacity(0.48))
                        .lineLimit(1).minimumScaleFactor(0.5)
                }
                .padding(.horizontal, 8).frame(height: 20)

                // Result line — smaller font for long mode-specific strings
                let isBig = engine.displayText.count <= 12
                HStack {
                    Spacer()
                    Text(engine.displayText)
                        .font(.custom("Courier", size: isBig ? 34 : 18))
                        .foregroundColor(.black.opacity(0.85))
                        .lineLimit(2).minimumScaleFactor(0.35)
                }
                .padding(.horizontal, 8).padding(.bottom, 4).frame(height: 42)
            }
        }
        .frame(height: hasTape ? 146 : 90)
        .padding(.horizontal, 12).padding(.top, 6)
    }

    private func ann(_ t: String, _ c: Color) -> some View {
        Text(t).font(.system(size: 9, weight: .semibold)).foregroundColor(c)
    }

    // MARK: - Row builder

    @ViewBuilder
    private func keyRow(_ keys: [CKey], w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: 4) {
            ForEach(keys, id: \.self) { k in keyView(k, w: w, h: h) }
        }
    }

    // MARK: - Individual key

    @ViewBuilder
    private func keyView(_ k: CKey, w: CGFloat, h: CGFloat) -> some View {
        let effective = resolveLabel(k)
        Button { tapped(k) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(bodyColor(k))
                    .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 2)
                LinearGradient(colors: [.white.opacity(0.15), .clear],
                               startPoint: .top, endPoint: UnitPoint(x:0.5, y:0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.white.opacity(0.10), lineWidth: 0.5)

                VStack(spacing: 0) {
                    // Shift hint (always visible in orange, above)
                    if !k.shift.isEmpty && h > 28 {
                        Text(k.shift)
                            .font(.system(size: max(5.5, h * 0.15), weight: .medium))
                            .foregroundColor(Color(red:0.95, green:0.72, blue:0.12))
                            .lineLimit(1).minimumScaleFactor(0.5)
                            .padding(.top, 2)
                    } else {
                        Spacer(minLength: 0).frame(height: h > 28 ? 2 : 0)
                    }
                    Spacer(minLength: 0)
                    // Main label
                    Text(effective)
                        .font(mainFont(effective, h: h))
                        .foregroundColor(labelColor(k))
                        .lineLimit(1).minimumScaleFactor(0.45)
                        .padding(.horizontal, 1)
                    Spacer(minLength: 0)
                }
            }
            .frame(width: w, height: h)
        }
        .buttonStyle(CasioPressStyle())
        .accessibilityLabel(effective)
    }

    // When SHIFT/ALPHA is active, keys temporarily show the shifted label
    private func resolveLabel(_ k: CKey) -> String {
        if alphaOn && !k.alpha.isEmpty { return k.alpha }
        if shiftOn && !k.shift.isEmpty { return k.shift }
        return k.main
    }

    // MARK: - Styling helpers

    private func bodyColor(_ k: CKey) -> Color {
        switch k.main {
        case "SHIFT":   return Color(red:0.85, green:0.60, blue:0.04)
        case "ALPHA":   return Color(red:0.68, green:0.10, blue:0.10)
        case "AC":      return Color(red:0.52, green:0.08, blue:0.08)
        case "=":       return Color(red:0.10, green:0.34, blue:0.68)
        case "0","1","2","3","4","5","6","7","8","9",".":
            return Color(red:0.23, green:0.24, blue:0.31)
        default:        return Color(red:0.17, green:0.18, blue:0.25)
        }
    }

    private func labelColor(_ k: CKey) -> Color {
        k.main == "SHIFT" ? .black.opacity(0.85) : .white
    }

    private func mainFont(_ label: String, h: CGFloat) -> Font {
        let n = label.count
        let size: CGFloat
        switch n {
        case 0...1: size = max(12, h * 0.36)
        case 2...3: size = max(10, h * 0.28)
        case 4...5: size = max(8,  h * 0.22)
        default:    size = max(6,  h * 0.18)
        }
        return .system(size: size, weight: .bold)
    }

    // MARK: - Tap handler

    private func tapped(_ k: CKey) {
        switch k.main {
        case "SHIFT":
            shiftOn.toggle(); alphaOn = false; return
        case "ALPHA":
            alphaOn.toggle(); shiftOn = false; return
        case "MODE":
            shiftOn = false; alphaOn = false
            showModePicker = true; return
        default: break
        }

        let effective: String
        if alphaOn && !k.alpha.isEmpty {
            effective = k.alpha
        } else if shiftOn && !k.shift.isEmpty {
            effective = k.shift
        } else {
            effective = k.main
        }
        shiftOn = false; alphaOn = false

        // Normalise labels to engine tokens
        switch effective {
        case "(-)":  engine.dispatch("(-)")
        case "EXP","×10ˣ": engine.dispatch("EXP")
        case "^":    engine.dispatch("^")
        case "Σ−":   engine.dispatch("Σ−")
        case "Σ+":   engine.dispatch("Σ+")
        default:     engine.dispatch(effective)
        }
    }
}

// MARK: - Press style

private struct CasioPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            }
            .scaleEffect(configuration.isPressed ? 0.91 : 1.0)
            .brightness(configuration.isPressed ? -0.12 : 0)
            .animation(.easeOut(duration: 0.07), value: configuration.isPressed)
    }
}
