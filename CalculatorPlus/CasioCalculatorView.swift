import SwiftUI

// MARK: - Key model

private struct CKey: Hashable {
    let main:  String
    let shift: String  // yellow label (SHIFT active)
    let alpha: String  // pink label   (ALPHA active)
    let blue:  String  // blue label   (Base-N mode)
    let top:   String  // white label above key

    init(_ m: String, s: String = "", a: String = "", b: String = "", t: String = "") {
        self.main = m
        self.shift = s
        self.alpha = a
        self.blue = b
        self.top = t
    }
}

// MARK: - Navigation cross (D-pad) — diamond ♦ shape

private struct CasioDPad: View {
    let dispatch: (String) -> Void
    let size: CGFloat

    private var centerD: CGFloat { size * 0.24 }
    private var chevOff: CGFloat { size * 0.32 }
    private var chevSz:  CGFloat { size * 0.14 }

    var body: some View {
        ZStack {
            // Diamond base
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(LinearGradient(colors: [Color(white: 0.84), Color(white: 0.60)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size * 0.82, height: size * 0.82)
                .rotationEffect(.degrees(45))
                .shadow(color: .black.opacity(0.50), radius: 2, x: 0, y: 2)

            // Gaps to create the petals (matches background color)
            Rectangle().fill(Color(red: 0.06, green: 0.07, blue: 0.13))
                .frame(width: size * 0.08, height: size)
            Rectangle().fill(Color(red: 0.06, green: 0.07, blue: 0.13))
                .frame(width: size, height: size * 0.08)

            // Dark center disc
            Circle()
                .fill(Color(white: 0.15))
                .frame(width: centerD, height: centerD)
                .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)

            // Tap zones (non-overlapping cross)
            let edgeH = (size - centerD) / 2
            VStack(spacing: 0) {
                Button { dispatch("UP") } label: {
                    Color.clear.frame(width: size, height: edgeH)
                }
                HStack(spacing: 0) {
                    Button { dispatch("LEFT") } label: {
                        Color.clear.frame(width: edgeH, height: centerD)
                    }
                    Color.clear.frame(width: centerD, height: centerD)
                    Button { dispatch("RIGHT") } label: {
                        Color.clear.frame(width: edgeH, height: centerD)
                    }
                }
                Button { dispatch("DOWN") } label: {
                    Color.clear.frame(width: size, height: edgeH)
                }
            }

            // Arrow chevrons
            Image(systemName: "chevron.up")
                .font(.system(size: chevSz, weight: .bold))
                .foregroundColor(Color(white: 0.2))
                .offset(y: -chevOff).allowsHitTesting(false)
            Image(systemName: "chevron.down")
                .font(.system(size: chevSz, weight: .bold))
                .foregroundColor(Color(white: 0.2))
                .offset(y:  chevOff).allowsHitTesting(false)
            Image(systemName: "chevron.left")
                .font(.system(size: chevSz, weight: .bold))
                .foregroundColor(Color(white: 0.2))
                .offset(x: -chevOff).allowsHitTesting(false)
            Image(systemName: "chevron.right")
                .font(.system(size: chevSz, weight: .bold))
                .foregroundColor(Color(white: 0.2))
                .offset(x:  chevOff).allowsHitTesting(false)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Main View

struct CasioCalculatorView: View {
    @Binding var active: CalculatorType
    let engine: CasioEngine

    @State private var shiftOn        = false
    @State private var alphaOn        = false
    @State private var showModePicker   = false
    @State private var showCalcPicker   = false
    @State private var showEqnPicker    = false
    @State private var showStatPicker   = false
    @State private var showConst        = false
    @State private var showConv         = false
    @State private var showFormatPicker = false
    @State private var showDigitPicker  = false
    @State private var pendingFmt       = ""
    @State private var showDist         = false

    // MARK: Key grid — modifier zone (2 levels) + 3 fn rows + 4 num rows

    // -- COMP function rows (rows B, C, D) — 6 keys each --
    private let rowB: [CKey] = [
        CKey("a/b",  s: "■a/b"),
        CKey("√",    s: "³√"),
        CKey("x²",   s: "x³",    b: "DEC"),
        CKey("x^",   s: "ⁿ√",    b: "HEX"),
        CKey("log□", s: "10^x",  b: "BIN"),
        CKey("ln",   s: "e^x",   b: "OCT"),
    ]
    private let rowC: [CKey] = [
        CKey("(-)",  s: "log",   a: "A"),
        CKey("°'\"", s: "FACT",  a: "B"),
        CKey("x⁻¹",  s: "x!",    a: "C"),
        CKey("sin",  s: "sin⁻¹", a: "D"),
        CKey("cos",  s: "cos⁻¹", a: "E"),
        CKey("tan",  s: "tan⁻¹", a: "F"),
    ]
    private let rowD: [CKey] = [
        CKey("STO",  s: "RECALL"),
        CKey("ENG",  s: "∠",       a: "i"),
        CKey("(",    s: "Abs"),
        CKey(")",    s: ",",       a: "x"),
        CKey("S⟺D",  s: "a⇔d/c",  a: "y"),
        CKey("M+",   s: "M-",      a: "M"),
    ]
    // -- Number rows (white keys) --
    private let row5: [CKey] = [
        CKey("7", s: "CONST"), CKey("8", s: "CONV"), CKey("9", s: "RESET"),
        CKey("DEL", s: "INS", a: "UNDO"), CKey("AC", s: "OFF"),
    ]
    private let row6: [CKey] = [
        CKey("4"), CKey("5"), CKey("6"),
        CKey("×", s: "nPr"), CKey("÷", s: "nCr"),
    ]
    private let row7: [CKey] = [
        CKey("1"), CKey("2"), CKey("3"),
        CKey("+", s: "Pol"), CKey("-", s: "Rec"),
    ]
    private let row8: [CKey] = [
        CKey("0", s: "Rnd"), CKey(".", s: "Ran#", a: "RanInt"),
        CKey("×10ˣ", s: "π", a: "e"), CKey("Ans", s: "%"), CKey("=", s: "≈"),
    ]

    // MARK: Mode-specific function rows (rows 1-4)

    private var cmplxFnRows: [[CKey]] { [
        [CKey("i"), CKey("Re"), CKey("Im"), CKey("|z|"), CKey("Arg"), CKey("POLAR")],
        [CKey("Conj"), CKey("+"), CKey("-"), CKey("×"), CKey("÷"), CKey("()")],
        [CKey("sin",s:"sin⁻¹"), CKey("cos",s:"cos⁻¹"), CKey("tan",s:"tan⁻¹"),
         CKey("log",s:"10^x"), CKey("ln",s:"e^x"), CKey("Ans")],
    ] }

    private var matFnRows: [[CKey]] { [
        [CKey("MatA"), CKey("MatB"), CKey("MatC"), CKey("Det"), CKey("Trn"), CKey("Inv")],
        [CKey("+"),    CKey("-"),    CKey("×"),    CKey("A"),   CKey("B"),   CKey("C")],
        [CKey("(-)"),  CKey("DEL"), CKey("STO"),  CKey("Ans"), CKey("π"),   CKey("M+")],
    ] }

    private var vctFnRows: [[CKey]] { [
        [CKey("VctA"), CKey("VctB"), CKey("·",s:"Dot"), CKey("×",s:"Cross"), CKey("|v|"), CKey("Ang")],
        [CKey("+"),    CKey("-"),    CKey("A"),          CKey("B"),           CKey("(-)"), CKey("DEL")],
        [CKey("STO"),  CKey("Ans"), CKey("π"),           CKey("M+"),         CKey("("),   CKey(")")],
    ] }

    private var tableFnRows: [[CKey]] { [
        [CKey("sin",s:"sin⁻¹"), CKey("cos",s:"cos⁻¹"), CKey("tan",s:"tan⁻¹"),
         CKey("log",s:"10^x"),  CKey("ln",s:"e^x"),     CKey("x²",s:"x³")],
        [CKey("√",s:"³√"),      CKey("x^",s:"x⁻¹"),    CKey("(",s:"Abs"),
         CKey(")",s:"Frac"),    CKey("π",s:"e"),         CKey("x")],
        [CKey("↑"),             CKey("↓"),               CKey("Ans"),
         CKey("STO"),           CKey("(-)"),             CKey("=")],
    ] }

    private var stat1VarFnRows: [[CKey]] { [
        [CKey("n"),   CKey("x̄"),   CKey("Σx"),  CKey("Σx²"),  CKey("σx"),  CKey("Sx")],
        [CKey("minX"),CKey("maxX"),CKey("DT"),  CKey("CL"),   CKey("Ans"), CKey("M+")],
        [CKey("STO"), CKey("("),   CKey(")"),   CKey("(-)"),  CKey("DEL"), CKey("AC")],
    ] }

    private var statRegFnRows: [[CKey]] {
        let lastCoeff = engine.statSubMode == .quadReg ? CKey("c") : CKey("r")
        return [
            [CKey("n"),    CKey("x̄"),   CKey("Σx"),  CKey("Σx²"),  CKey("Σxy"), CKey("ȳ")],
            [CKey("Σy"),   CKey("Σy²"), CKey("σx"),  CKey("Sx"),   CKey("a"),   CKey("b")],
            [lastCoeff,    CKey("DT"),  CKey("CL"),  CKey("STO"),  CKey("Ans"), CKey("M+")],
        ]
    }

    private var baseNFnRows: [[CKey]] { [
        [CKey("BIN"), CKey("OCT"), CKey("DEC"), CKey("HEX"), CKey("NEG"), CKey("AND")],
        [CKey("OR"),  CKey("XOR"), CKey("NOT"), CKey("XNOR"),CKey("A"),   CKey("B")],
        [CKey("C"),   CKey("D"),   CKey("E"),   CKey("F"),   CKey("DEL"), CKey("AC")],
    ] }

    private var activeFnRows: [[CKey]] {
        switch engine.mode {
        case .cmplx:  return cmplxFnRows
        case .matrix: return matFnRows
        case .vector: return vctFnRows
        case .table:  return tableFnRows
        case .baseN:  return baseNFnRows
        case .stat:   return engine.statSubMode == .oneVar ? stat1VarFnRows : statRegFnRows
        default:      return [rowB, rowC, rowD]
        }
    }

    var body: some View {
        VStack(spacing: 5) {
            lcdDisplay

            GeometryReader { geo in
                let hPad: CGFloat    = 14
                let hGap: CGFloat    = 8
                let vGap: CGFloat    = 8
                let zoneGap: CGFloat = 12

                // D-pad drives modifier zone height; zone spans 2 sub-rows
                let dPadSize = min(geo.size.width * 0.235, geo.size.height * 0.148)
                let modH     = dPadSize
                let modRowH  = (dPadSize - hGap) / 2   // height of each sub-row
                // 4 keys flank D-pad (2 left, 2 right); same total-width formula as before
                let domeW    = (geo.size.width - hPad * 2 - dPadSize - 4 * hGap) / 4

                // 6 vGap spacers: 1 after mod + 2 between 3 fn rows + 3 between 4 num rows
                let keysAvail = geo.size.height - modH - vGap * 6 - zoneGap
                let fnH  = (keysAvail * 0.35) / 3   // 3 function rows
                let numH = (keysAvail * 0.65) / 4   // 4 number rows

                // 6-column fn key width vs 5-column num key width
                let fnBtnW  = (geo.size.width - hPad * 2 - hGap * 5) / 6
                let numBtnW = (geo.size.width - hPad * 2 - hGap * 4) / 5

                let fn = activeFnRows

                VStack(spacing: 0) {
                    // Modifier zone — D-pad spans 2 sub-rows; dome keys top, dark keys bottom
                    HStack(spacing: hGap) {
                        // Left column pair
                        VStack(spacing: hGap) {
                            HStack(spacing: hGap) {
                                keyView(CKey("SHIFT", s: "SHIFT"), w: domeW, h: modRowH)
                                keyView(CKey("ALPHA", a: "ALPHA"), w: domeW, h: modRowH)
                            }
                            HStack(spacing: hGap) {
                                keyView(CKey("OPTN", s: "QR"),          w: domeW, h: modRowH)
                                keyView(CKey("CALC", s: "SOLVE", a: "="), w: domeW, h: modRowH)
                            }
                        }
                        CasioDPad(dispatch: { engine.dispatch($0) }, size: dPadSize)
                        // Right column pair
                        VStack(spacing: hGap) {
                            HStack(spacing: hGap) {
                                keyView(CKey("MENU", s: "SETUP", t: "MENU"), w: domeW, h: modRowH)
                                keyView(CKey("ON", t: "ON"),    w: domeW, h: modRowH)
                            }
                            HStack(spacing: hGap) {
                                keyView(CKey("∫□", s: "d/dx", a: ":"), w: domeW, h: modRowH)
                                keyView(CKey("x",  s: "Σ□",  a: ":"), w: domeW, h: modRowH)
                            }
                        }
                    }
                    .padding(.horizontal, hPad)

                    // Function section (3 rows × 6 keys, dark)
                    Spacer().frame(height: vGap)
                    keyRow(fn[0], w: fnBtnW, h: fnH, spacing: hGap)
                    Spacer().frame(height: vGap)
                    keyRow(fn[1], w: fnBtnW, h: fnH, spacing: hGap)
                    Spacer().frame(height: vGap)
                    keyRow(fn[2], w: fnBtnW, h: fnH, spacing: hGap)

                    // Zone separator
                    Spacer().frame(height: zoneGap)

                    // Number section (4 rows × 5 keys, white/light, taller)
                    keyRow(row5, w: numBtnW, h: numH, spacing: hGap)
                    Spacer().frame(height: vGap)
                    keyRow(row6, w: numBtnW, h: numH, spacing: hGap)
                    Spacer().frame(height: vGap)
                    keyRow(row7, w: numBtnW, h: numH, spacing: hGap)
                    Spacer().frame(height: vGap)
                    keyRow(row8, w: numBtnW, h: numH, spacing: hGap)
                }
            }
        }
        .background(Color(red: 0.06, green: 0.07, blue: 0.13).ignoresSafeArea())
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
        .sheet(isPresented: $showCalcPicker) { CalculatorPickerView(active: $active) }
        // Display format — SHIFT+MODE
        .confirmationDialog("Display Format", isPresented: $showFormatPicker, titleVisibility: .visible) {
            Button("FIX — fixed decimal") { pendingFmt = "FIX"; showDigitPicker = true }
            Button("SCI — scientific")    { pendingFmt = "SCI"; showDigitPicker = true }
            Button("ENG — engineering")   { pendingFmt = "ENG"; showDigitPicker = true }
            Button("NORM — normal")       { engine.dispatch("NORM") }
            Button("Cancel", role: .cancel) {}
        }
        // Decimal places selector (0–9)
        .confirmationDialog("Decimal Places", isPresented: $showDigitPicker, titleVisibility: .visible) {
            ForEach(0...9, id: \.self) { n in
                Button("\(n)") { engine.dispatch("\(pendingFmt):\(n)") }
            }
            Button("Cancel", role: .cancel) {}
        }
        // Physical constants catalog
        .sheet(isPresented: $showConst) {
            ConstantPickerSheet { idx in
                engine.dispatch("CONST:\(idx)")
                showConst = false
            }
        }
        // Unit conversions catalog
        .sheet(isPresented: $showConv) {
            ConversionPickerSheet { idx in
                engine.dispatch("CONV:\(idx)")
                showConv = false
            }
        }
        // Statistical distributions
        .sheet(isPresented: $showDist) {
            DistPickerSheet { key in
                engine.dispatch(key)
                showDist = false
            }
        }
    }

    // MARK: - LCD

    @ViewBuilder
    private var lcdDisplay: some View {
        let isTableView = engine.mode == .table && engine.tablePhase == .view
        let hasTape = !engine.tape.isEmpty && !isTableView
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
                    if engine.mode == .cmplx && engine.cmplxPolar {
                        ann("POL", Color(red:0.20,green:0.40,blue:0.90))
                    }
                    if shiftOn { ann("SHIFT", Color(red:0.85,green:0.60,blue:0.04)) }
                    if alphaOn { ann("ALPHA", Color(red:0.85,green:0.15,blue:0.55)) }
                    Spacer()
                    Text(active.rawValue)
                        .font(.system(size: 9))
                        .foregroundColor(.black.opacity(0.35))
                }
                .padding(.horizontal, 8).padding(.top, 4).frame(height: 18)

                if isTableView {
                    tableGridView
                } else {
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
        }
        .frame(height: isTableView ? 148 : (hasTape ? 146 : 90))
        .padding(.horizontal, 12).padding(.top, 6)
    }

    // Two-column table grid shown when TABLE mode reaches .view phase
    @ViewBuilder
    private var tableGridView: some View {
        let data = engine.tableData
        let sel  = engine.tableViewRow
        let visibleCount = 4
        // Window: keep selected row visible, centered if possible
        let startIdx = max(0, min(sel - 1, data.count - visibleCount))

        VStack(spacing: 0) {
            // Column header
            HStack(spacing: 0) {
                Text("x")
                    .frame(maxWidth: .infinity, alignment: .center)
                Divider().frame(height: 14)
                Text("f(x)")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.black.opacity(0.55))
            .frame(height: 16)
            .padding(.horizontal, 8)

            Divider().background(Color.black.opacity(0.20))

            // Visible rows
            ForEach(0..<visibleCount, id: \.self) { offset in
                let idx = startIdx + offset
                if idx < data.count {
                    let row = data[idx]
                    let isSelected = idx == sel
                    HStack(spacing: 0) {
                        Text(engine.fmt(row.x))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 6)
                        Rectangle()
                            .frame(width: 0.5)
                            .foregroundColor(.black.opacity(0.20))
                        Text(engine.fmt(row.fx))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 6)
                    }
                    .font(.custom("Courier", size: 12))
                    .foregroundColor(isSelected ? .black : .black.opacity(0.65))
                    .frame(height: 26)
                    .background(isSelected
                        ? Color.black.opacity(0.12)
                        : Color.clear)
                    .padding(.horizontal, 4)
                } else {
                    Color.clear.frame(height: 26)
                }
            }

            // Scroll hint
            HStack {
                Image(systemName: "chevron.up")
                    .opacity(sel > 0 ? 0.5 : 0.15)
                Spacer()
                Text("\(sel + 1)/\(data.count)")
                    .font(.system(size: 9))
                    .foregroundColor(.black.opacity(0.40))
                Spacer()
                Image(systemName: "chevron.down")
                    .opacity(sel < data.count - 1 ? 0.5 : 0.15)
            }
            .font(.system(size: 9))
            .foregroundColor(.black.opacity(0.45))
            .padding(.horizontal, 12)
            .frame(height: 14)
        }
        .padding(.top, 2)
    }

    private func ann(_ t: String, _ c: Color) -> some View {
        Text(t).font(.system(size: 9, weight: .semibold)).foregroundColor(c)
    }

    // MARK: - Row builder

    @ViewBuilder
    private func keyRow(_ keys: [CKey], w: CGFloat, h: CGFloat, spacing: CGFloat = 4) -> some View {
        HStack(spacing: spacing) {
            ForEach(keys, id: \.self) { k in keyView(k, w: w, h: h) }
        }
    }

    // MARK: - Individual key

    private func baseNKeyEnabled(_ k: CKey) -> Bool {
        guard engine.mode == .baseN else { return true }
        switch engine.baseRadix {
        case .bin: return !["2","3","4","5","6","7","8","9","A","B","C","D","E","F"].contains(k.main)
        case .oct: return !["8","9","A","B","C","D","E","F"].contains(k.main)
        case .dec: return !["A","B","C","D","E","F"].contains(k.main)
        case .hex: return true
        }
    }

    @ViewBuilder
    private func keyView(_ k: CKey, w: CGFloat, h: CGFloat) -> some View {
        let isDome = ["SHIFT", "ALPHA", "MENU", "ON"].contains(k.main)
        let effective = resolveLabel(k)
        let enabled   = baseNKeyEnabled(k)
        
        let labelH: CGFloat = min(17, h * 0.28)
        let btnH: CGFloat = h - labelH - 2
        
        VStack(spacing: 2) {
            // Secondary labels above the key
            ZStack {
                if !k.top.isEmpty && k.shift.isEmpty && k.alpha.isEmpty && k.blue.isEmpty {
                    Text(k.top)
                        .font(.system(size: labelH * 0.85, weight: .bold))
                        .foregroundColor(Color(white: 0.85))
                        .lineLimit(1).minimumScaleFactor(0.5)
                } else if !k.shift.isEmpty && k.alpha.isEmpty && k.blue.isEmpty && k.top.isEmpty {
                    Text(k.shift)
                        .font(.system(size: labelH * 0.85, weight: .bold))
                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.15))
                        .lineLimit(1).minimumScaleFactor(0.5)
                } else if !k.alpha.isEmpty && k.shift.isEmpty && k.blue.isEmpty && k.top.isEmpty {
                    Text(k.alpha)
                        .font(.system(size: labelH * 0.85, weight: .bold))
                        .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.55))
                        .lineLimit(1).minimumScaleFactor(0.5)
                } else {
                    HStack(spacing: 0) {
                        if !k.top.isEmpty {
                            Text(k.top)
                                .font(.system(size: labelH * 0.85, weight: .bold))
                                .foregroundColor(Color(white: 0.85))
                                .lineLimit(1).minimumScaleFactor(0.5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else if !k.shift.isEmpty {
                            Text(k.shift)
                                .font(.system(size: labelH * 0.85, weight: .bold))
                                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.15))
                                .lineLimit(1).minimumScaleFactor(0.5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Spacer(minLength: 0).frame(maxWidth: .infinity)
                        }
                        
                        if !k.alpha.isEmpty {
                            Text(k.alpha)
                                .font(.system(size: labelH * 0.85, weight: .bold))
                                .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.55))
                                .lineLimit(1).minimumScaleFactor(0.5)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else if !k.blue.isEmpty {
                            Text(k.blue)
                                .font(.system(size: labelH * 0.85, weight: .bold))
                                .foregroundColor(Color(red: 0.20, green: 0.65, blue: 0.90)) // Base-N blue
                                .lineLimit(1).minimumScaleFactor(0.5)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else if k.main == "MENU" && !k.shift.isEmpty {
                            // Specific layout for MENU/SETUP
                            Text(k.shift)
                                .font(.system(size: labelH * 0.85, weight: .bold))
                                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.15))
                                .lineLimit(1).minimumScaleFactor(0.5)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else {
                            Spacer(minLength: 0).frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .frame(width: w * 0.9, height: labelH)
            
            Button { tapped(k) } label: {
                if isDome {
                    let diam = min(w, btnH) - 2
                    ZStack {
                        Circle()
                            .fill(bodyColor(k))
                            .shadow(color: .black.opacity(0.55), radius: 2, x: 0, y: 2)
                            .frame(width: diam, height: diam)
                        LinearGradient(colors: [.white.opacity(0.28), .clear],
                                       startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.65))
                            .clipShape(Circle()).frame(width: diam, height: diam)
                        if k.main == "ON" {
                            Image(systemName: "gearshape")
                                .font(.system(size: max(11, diam * 0.38), weight: .medium))
                                .foregroundColor(Color(white: 0.18))
                        }
                        // SHIFT, ALPHA, and MENU have blank metallic domes
                    }
                    .frame(width: w, height: btnH)
                } else {
                    let isNum = Self.numKeys.contains(k.main) || k.main == "DEL" || k.main == "AC"
                    let cr: CGFloat = isNum ? min(btnH * 0.20, 10) : min(btnH * 0.18, 7)
                    ZStack {
                        RoundedRectangle(cornerRadius: cr)
                            .fill(bodyColor(k))
                            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 2)
                        LinearGradient(colors: [.white.opacity(isNum ? 0.14 : 0.08), .clear],
                                       startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.5))
                            .clipShape(RoundedRectangle(cornerRadius: cr))
                        RoundedRectangle(cornerRadius: cr)
                            .stroke(Color(white: isNum ? 0.70 : 0.55).opacity(0.30), lineWidth: 0.5)
                        Text(effective)
                            .font(mainFont(effective, h: btnH))
                            .foregroundColor(labelColor(k))
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .padding(.horizontal, 1)
                    }
                    .frame(width: w, height: btnH)
                    .opacity(enabled ? 1 : 0.3)
                }
            }
            .buttonStyle(CalcPressStyle())
            .disabled(!enabled)
            .accessibilityLabel(k.main == "ON" ? "Switch calculator" : effective)
        }
    }

    // When SHIFT/ALPHA is active, keys temporarily show the shifted label
    private func resolveLabel(_ k: CKey) -> String {
        if alphaOn && !k.alpha.isEmpty { return k.alpha }
        if shiftOn && !k.shift.isEmpty { return k.shift }
        return k.main
    }

    // MARK: - Styling helpers

    private static let numKeys: Set<String> = [
        "0","1","2","3","4","5","6","7","8","9",
        ".","×10ˣ","Ans","+","-","×","÷","EXP","=",
    ]

    private func bodyColor(_ k: CKey) -> Color {
        switch k.main {
        case "SHIFT", "ALPHA", "MENU", "ON":
            return Color(white: 0.76)                              // silver dome
        case "DEL", "AC":
            return Color(red: 0.13, green: 0.42, blue: 0.88)      // bright blue
        default:
            if Self.numKeys.contains(k.main) {
                return Color(white: 0.87)                          // warm white for number section
            }
            return Color(white: 0.15)                              // near-black for function keys
        }
    }

    private func labelColor(_ k: CKey) -> Color {
        switch k.main {
        case "DEL", "AC": return .white
        default:
            if Self.numKeys.contains(k.main) {
                return Color(white: 0.10)                          // dark text on white keys
            }
            return Color(white: 0.92)                              // off-white text on dark keys
        }
    }

    private func mainFont(_ label: String, h: CGFloat) -> Font {
        let n = label.count
        let size: CGFloat
        switch n {
        case 0...1: size = max(20, h * 0.48)
        case 2...3: size = max(15, h * 0.36)
        case 4...5: size = max(12, h * 0.28)
        default:    size = max(10, h * 0.22)
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
        case "MENU":
            let wasShift = shiftOn
            shiftOn = false; alphaOn = false
            if wasShift { showFormatPicker = true } else { showModePicker = true }
            return
        case "ON":
            showCalcPicker = true
            return
        case "OPTN":
            shiftOn = false; alphaOn = false; return   // no-op stub
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

        if effective == "CONST" { showConst = true; return }
        if effective == "CONV"  { showConv  = true; return }
        if effective == "DIST"  { showDist  = true; return }

        // Normalise labels to engine tokens
        switch effective {
        case "(-)":   engine.dispatch("(-)")
        case "×10ˣ":  engine.dispatch("EXP")
        case "x^":    engine.dispatch("^")
        case "S⟺D":   engine.dispatch("S<>D")
        case "°'\"":  engine.dispatch("°'\"")
        case "a/b":   engine.dispatch("FRAC")
        case "■a/b":  engine.dispatch("MIXED")
        case "log□":  engine.dispatch("log_b")
        case "∫□":    engine.dispatch("∫")
        case "a⇔d/c": engine.dispatch("S<>D")
        case "RECALL": engine.dispatch("RCL")
        case "FACT":  engine.dispatch("x!")
        case "ⁿ√":   engine.dispatch("ˣ√")
        case "RanInt": engine.dispatch("RanInt#")
        case "≈":     engine.dispatch("≈")
        case "INS":   break
        case "∠":     engine.dispatch("∠")
        default:      engine.dispatch(effective)
        }
    }
}

// MARK: - Physical constants picker

private struct ConstantPickerSheet: View {
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    private let grouped = Dictionary(grouping: CasioEngine.physConstants, by: \.category)
    private let order   = ["Universal","Electromagnetic","Atomic & Nuclear","Physico-Chemical","Planck Units"]

    var body: some View {
        NavigationStack {
            List {
                ForEach(order, id: \.self) { cat in
                    Section(cat) {
                        ForEach(grouped[cat] ?? []) { c in
                            Button {
                                onSelect(c.id); dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(c.name).font(.subheadline).foregroundStyle(.primary)
                                        Text("\(c.symbol)  \(c.unit)")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(formatSci(c.value))
                                        .font(.caption.monospaced()).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Physical Constants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func formatSci(_ v: Double) -> String {
        let s = String(format: "%.4e", v)
        return s
    }
}

// MARK: - Unit conversion picker

private struct ConversionPickerSheet: View {
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    private let grouped = Dictionary(grouping: CasioEngine.physConversions, by: \.category)
    private let order   = ["Length","Area","Volume","Mass","Speed","Temperature","Energy","Pressure","Time"]

    var body: some View {
        NavigationStack {
            List {
                ForEach(order, id: \.self) { cat in
                    Section(cat) {
                        ForEach(grouped[cat] ?? []) { c in
                            Button {
                                onSelect(c.id); dismiss()
                            } label: {
                                Text(c.label)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Unit Conversions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Distribution picker

private struct DistPickerSheet: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private struct DistItem: Identifiable {
        let id: String
        let label: String
        let detail: String
    }

    private let items: [DistItem] = [
        DistItem(id: "NormPD",    label: "NormPD",    detail: "Normal probability density — NormPD(x, σ, μ)"),
        DistItem(id: "NormCD",    label: "NormCD",    detail: "Normal cumulative — NormCD(lo, hi, σ, μ)"),
        DistItem(id: "InvNorm",   label: "InvNorm",   detail: "Inverse normal — InvNorm(area, σ, μ)"),
        DistItem(id: "BinomPD",   label: "BinomPD",   detail: "Binomial probability — BinomPD(k, n, p)"),
        DistItem(id: "BinomCD",   label: "BinomCD",   detail: "Binomial cumulative — BinomCD(k, n, p)"),
        DistItem(id: "PoissonPD", label: "PoissonPD", detail: "Poisson probability — PoissonPD(k, λ)"),
        DistItem(id: "PoissonCD", label: "PoissonCD", detail: "Poisson cumulative — PoissonCD(k, λ)"),
    ]

    var body: some View {
        NavigationStack {
            List(items) { item in
                Button {
                    onSelect(item.id); dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.label)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Distributions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Press style

