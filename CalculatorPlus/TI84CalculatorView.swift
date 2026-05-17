import SwiftUI

// MARK: - Color palette

extension Color {
    static let tiBody         = Color(red: 0.18, green: 0.18, blue: 0.20)
    static let tiScreen       = Color(red: 0.91, green: 0.93, blue: 0.91)
    static let tiScreenBorder = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let tiKey2nd       = Color(red: 0.13, green: 0.47, blue: 0.87)
    static let tiKeyAlpha     = Color(red: 0.16, green: 0.50, blue: 0.20)
    static let tiKeyClear     = Color(red: 0.62, green: 0.10, blue: 0.10)
    static let tiKeyGraph     = Color(red: 0.28, green: 0.28, blue: 0.32)
    static let tiKeyDark      = Color(red: 0.22, green: 0.22, blue: 0.26)
    static let tiKeyNum       = Color(red: 0.32, green: 0.32, blue: 0.36)
    static let tiKeyEnter     = Color(red: 0.10, green: 0.25, blue: 0.62)
    static let ti2ndLabel     = Color(red: 0.45, green: 0.72, blue: 1.0)
    static let tiAlphaLabel   = Color(red: 0.55, green: 0.85, blue: 0.55)
}

// MARK: - Key model

private struct TIKeyDef: Hashable {
    let label: String
    let second: String
    let alpha: String
    let color: Color
    let accessibilityLabel: String
    var cornerRadius: CGFloat = 3
}

// MARK: - D-Pad component

private struct DPadView: View {
    let dispatch: (String) -> Void
    let size: CGFloat

    var body: some View {
        let arm = size / 3
        ZStack {
            Circle().fill(Color.tiKeyDark).frame(width: size, height: size)
            VStack(spacing: 0) {
                Button { dispatch("UP") } label: {
                    Text("▲").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                        .frame(width: size, height: arm)
                }
                .accessibilityLabel("Up")
                HStack(spacing: 0) {
                    Button { dispatch("LEFT") } label: {
                        Text("◄").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            .frame(width: arm, height: arm)
                    }
                    .accessibilityLabel("Left")
                    Circle().fill(Color(red: 0.14, green: 0.14, blue: 0.17)).frame(width: arm, height: arm)
                    Button { dispatch("RIGHT") } label: {
                        Text("►").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            .frame(width: arm, height: arm)
                    }
                    .accessibilityLabel("Right")
                }
                Button { dispatch("DOWN") } label: {
                    Text("▼").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                        .frame(width: size, height: arm)
                }
                .accessibilityLabel("Down")
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Individual key button

private struct TIKeyButton: View {
    let def: TIKeyDef
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                // Secondary labels above key
                HStack(spacing: 2) {
                    if !def.second.isEmpty {
                        Text(def.second)
                            .font(.system(size: 8))
                            .foregroundColor(.ti2ndLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    if !def.alpha.isEmpty {
                        Text(def.alpha)
                            .font(.system(size: 7))
                            .foregroundColor(.tiAlphaLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .frame(height: 10)

                // Key body
                ZStack {
                    RoundedRectangle(cornerRadius: def.cornerRadius)
                        .fill(def.color)
                        .shadow(color: .black.opacity(0.4), radius: 1.5, x: 0, y: 1.5)
                    Text(def.label)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(width: width, height: height - 12)
            }
        }
        .buttonStyle(CalcPressStyle())
        .frame(width: width, height: height)
        .accessibilityLabel(def.accessibilityLabel)
    }
}

// MARK: - Main view

struct TI84CalculatorView: View {
    @Binding var active: CalculatorType
    let engine: TI84Engine

    @State private var showCalcPicker = false

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            if isLandscape {
                ZStack {
                    Color.tiBody.ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "rotate.right").font(.largeTitle)
                        Text("Rotate to portrait\nto use TI-84")
                            .multilineTextAlignment(.center)
                    }
                    .foregroundColor(.white)
                }
            } else {
                VStack(spacing: 0) {
                    screenArea
                        .frame(height: geo.size.height * 0.38)
                    keyGrid(totalHeight: geo.size.height * 0.62, totalWidth: geo.size.width)
                }
                .background(Color.tiBody)
            }
        }
        .sheet(isPresented: Binding(
            get: { engine.showStatResults },
            set: { engine.showStatResults = $0 }
        )) {
            StatResultsView(engine: engine)
        }
        .sheet(isPresented: $showCalcPicker) { CalculatorPickerView(active: $active) }
    }

    // MARK: Screen area

    @ViewBuilder
    private var screenArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.tiScreenBorder)
                .padding(.horizontal, 8)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.tiScreen)
                .padding(.horizontal, 12)

            Group {
                switch engine.screen {
                case .home:         HomeScreenView(engine: engine, active: $active)
                case .yEditor:      YEditorView(engine: engine)
                case .graph:        GraphView(engine: engine)
                case .windowEditor: WindowEditorView(engine: engine)
                case .table:        TableView(engine: engine)
                case .statEditor:   StatEditorView(engine: engine)
                case .matrixEditor: MatrixEditorView(engine: engine)
                case .modeEditor:   ModeEditorView(engine: engine)
                }
            }
            .padding(.horizontal, 16)
            .animation(.easeInOut(duration: 0.15), value: engine.screen)
        }
    }

    // MARK: Key grid

    @ViewBuilder
    private func keyGrid(totalHeight: CGFloat, totalWidth: CGFloat) -> some View {
        let hPad: CGFloat = 4
        let hGap: CGFloat = 4
        let kW = (totalWidth - 2 * hPad - 4 * hGap) / 5
        let rowH = totalHeight / 10

        VStack(spacing: 0) {
            // Row 0: Y= WINDOW ZOOM TRACE GRAPH
            standardRow(keys: row0Keys, kW: kW, rowH: rowH, hGap: hGap)
            // Rows 1–2: 3 keys left + D-pad right
            dPadZone(kW: kW, rowH: rowH, hGap: hGap)
            // Row 3: MATH APPS PRGM VARS CLEAR
            standardRow(keys: row3Keys, kW: kW, rowH: rowH, hGap: hGap)
            // Row 4: x⁻¹ SIN COS TAN ^
            standardRow(keys: row4Keys, kW: kW, rowH: rowH, hGap: hGap)
            // Row 5: x² , ( ) ÷
            standardRow(keys: row5Keys, kW: kW, rowH: rowH, hGap: hGap)
            // Row 6: log 7 8 9 ×
            standardRow(keys: row6Keys, kW: kW, rowH: rowH, hGap: hGap)
            // Row 7: ln 4 5 6 −
            standardRow(keys: row7Keys, kW: kW, rowH: rowH, hGap: hGap)
            // Row 8: STO→ 1 2 3 +
            standardRow(keys: row8Keys, kW: kW, rowH: rowH, hGap: hGap)
            // Row 9: ⚙(picker) 0 . (-) ENTER
            HStack(spacing: hGap) {
                Button { showCalcPicker = true } label: {
                    VStack(spacing: 1) {
                        Color.clear.frame(height: 10)
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.tiKeyDark)
                                .shadow(color: .black.opacity(0.4), radius: 1.5, x: 0, y: 1.5)
                            Image(systemName: "gearshape")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: kW, height: rowH - 12)
                    }
                }
                .buttonStyle(CalcPressStyle())
                .frame(width: kW, height: rowH)
                .accessibilityLabel("Switch calculator")
                ForEach(row9Trailing.indices, id: \.self) { i in
                    TIKeyButton(def: row9Trailing[i].0, width: kW, height: rowH) {
                        engine.dispatch(row9Trailing[i].1)
                    }
                }
            }
        }
        .padding(.horizontal, hPad)
        .padding(.bottom, 4)
    }

    // Standard 5-column row
    @ViewBuilder
    private func standardRow(keys: [(TIKeyDef, String)], kW: CGFloat, rowH: CGFloat, hGap: CGFloat) -> some View {
        HStack(spacing: hGap) {
            ForEach(keys.indices, id: \.self) { i in
                TIKeyButton(def: keys[i].0, width: kW, height: rowH) {
                    engine.dispatch(keys[i].1)
                }
            }
        }
    }

    // Rows 1–2: 3 keys on left, D-pad spanning right 2 columns
    @ViewBuilder
    private func dPadZone(kW: CGFloat, rowH: CGFloat, hGap: CGFloat) -> some View {
        let row1Left: [(TIKeyDef, String)] = [
            (TIKeyDef(label: "2nd",    second: "",     alpha: "LOCK", color: .tiKey2nd,   accessibilityLabel: "2nd", cornerRadius: 6), "2ND"),
            (TIKeyDef(label: "MODE",   second: "QUIT", alpha: "",     color: .tiKeyDark,  accessibilityLabel: "Mode"), "MODE"),
            (TIKeyDef(label: "DEL",    second: "INS",  alpha: "",     color: .tiKeyDark,  accessibilityLabel: "Delete"), "DEL"),
        ]
        let row2Left: [(TIKeyDef, String)] = [
            (TIKeyDef(label: "ALPHA",  second: "",      alpha: "LOCK", color: .tiKeyAlpha, accessibilityLabel: "Alpha", cornerRadius: 6), "ALPHA"),
            (TIKeyDef(label: "X,T,θ",  second: "",      alpha: "W",    color: .tiKeyDark,  accessibilityLabel: "X T theta n"), "X,T,θ,n"),
            (TIKeyDef(label: "STAT",   second: "",      alpha: "",     color: .tiKeyDark,  accessibilityLabel: "Stat"), "STAT"),
        ]
        let dpadZoneW = 2 * kW + hGap
        let dpadZoneH = 2 * rowH
        let dpadSize = min(dpadZoneW, dpadZoneH) * 0.82

        HStack(spacing: hGap) {
            VStack(spacing: 0) {
                HStack(spacing: hGap) {
                    ForEach(row1Left.indices, id: \.self) { i in
                        TIKeyButton(def: row1Left[i].0, width: kW, height: rowH) { engine.dispatch(row1Left[i].1) }
                    }
                }
                HStack(spacing: hGap) {
                    ForEach(row2Left.indices, id: \.self) { i in
                        TIKeyButton(def: row2Left[i].0, width: kW, height: rowH) { engine.dispatch(row2Left[i].1) }
                    }
                }
            }

            DPadView(dispatch: engine.dispatch, size: dpadSize)
                .frame(width: dpadZoneW, height: dpadZoneH)
        }
    }

    // MARK: Key definitions

    private var row0Keys: [(TIKeyDef, String)] { [
        (TIKeyDef(label: "Y=",     second: "STAT PLT", alpha: "", color: .tiKeyGraph, accessibilityLabel: "Y equals"), "Y="),
        (TIKeyDef(label: "WINDOW", second: "TBLSET",   alpha: "", color: .tiKeyGraph, accessibilityLabel: "Window"), "WINDOW"),
        (TIKeyDef(label: "ZOOM",   second: "FORMAT",   alpha: "", color: .tiKeyGraph, accessibilityLabel: "Zoom"), "ZOOM"),
        (TIKeyDef(label: "TRACE",  second: "CALC",     alpha: "", color: .tiKeyGraph, accessibilityLabel: "Trace"), "TRACE"),
        (TIKeyDef(label: "GRAPH",  second: "TABLE",    alpha: "", color: .tiKeyGraph, accessibilityLabel: "Graph"), "GRAPH"),
    ] }

    private var row3Keys: [(TIKeyDef, String)] { [
        (TIKeyDef(label: "MATH",  second: "TEST", alpha: "A", color: .tiKeyDark,  accessibilityLabel: "Math"), "MATH"),
        (TIKeyDef(label: "APPS",  second: "",     alpha: "B", color: .tiKeyDark,  accessibilityLabel: "Apps"), "APPS"),
        (TIKeyDef(label: "PRGM",  second: "",     alpha: "C", color: .tiKeyDark,  accessibilityLabel: "Program"), "PRGM"),
        (TIKeyDef(label: "VARS",  second: "",     alpha: "",  color: .tiKeyDark,  accessibilityLabel: "Variables"), "VARS"),
        (TIKeyDef(label: "CLEAR", second: "",     alpha: "",  color: .tiKeyClear, accessibilityLabel: "Clear"), "CLEAR"),
    ] }

    private var row4Keys: [(TIKeyDef, String)] { [
        (TIKeyDef(label: "x⁻¹", second: "MATRIX", alpha: "D", color: .tiKeyDark, accessibilityLabel: "x inverse"), "x⁻¹"),
        (TIKeyDef(label: "sin", second: "sin⁻¹",  alpha: "E", color: .tiKeyDark, accessibilityLabel: "Sine"), "SIN"),
        (TIKeyDef(label: "cos", second: "cos⁻¹",  alpha: "F", color: .tiKeyDark, accessibilityLabel: "Cosine"), "COS"),
        (TIKeyDef(label: "tan", second: "tan⁻¹",  alpha: "G", color: .tiKeyDark, accessibilityLabel: "Tangent"), "TAN"),
        (TIKeyDef(label: "^",   second: "",        alpha: "",  color: .tiKeyDark, accessibilityLabel: "Power"), "^"),
    ] }

    private var row5Keys: [(TIKeyDef, String)] { [
        (TIKeyDef(label: "x²", second: "√(",  alpha: "H", color: .tiKeyDark, accessibilityLabel: "x squared"), "x²"),
        (TIKeyDef(label: ",",  second: "EE",  alpha: "I", color: .tiKeyDark, accessibilityLabel: "Comma"), ","),
        (TIKeyDef(label: "(",  second: "{",   alpha: "J", color: .tiKeyDark, accessibilityLabel: "Left parenthesis"), "("),
        (TIKeyDef(label: ")",  second: "}",   alpha: "K", color: .tiKeyDark, accessibilityLabel: "Right parenthesis"), ")"),
        (TIKeyDef(label: "÷",  second: "",    alpha: "L", color: .tiKeyDark, accessibilityLabel: "Divide"), "÷"),
    ] }

    private var row6Keys: [(TIKeyDef, String)] { [
        (TIKeyDef(label: "log", second: "10ˣ", alpha: "M", color: .tiKeyDark, accessibilityLabel: "Log"), "LOG"),
        (TIKeyDef(label: "7",   second: "",    alpha: "N", color: .tiKeyNum,  accessibilityLabel: "7"), "7"),
        (TIKeyDef(label: "8",   second: "",    alpha: "O", color: .tiKeyNum,  accessibilityLabel: "8"), "8"),
        (TIKeyDef(label: "9",   second: "",    alpha: "P", color: .tiKeyNum,  accessibilityLabel: "9"), "9"),
        (TIKeyDef(label: "×",   second: "",    alpha: "Q", color: .tiKeyDark, accessibilityLabel: "Multiply"), "×"),
    ] }

    private var row7Keys: [(TIKeyDef, String)] { [
        (TIKeyDef(label: "ln", second: "eˣ", alpha: "R", color: .tiKeyDark, accessibilityLabel: "Natural log"), "LN"),
        (TIKeyDef(label: "4",  second: "",   alpha: "S", color: .tiKeyNum,  accessibilityLabel: "4"), "4"),
        (TIKeyDef(label: "5",  second: "",   alpha: "T", color: .tiKeyNum,  accessibilityLabel: "5"), "5"),
        (TIKeyDef(label: "6",  second: "",   alpha: "U", color: .tiKeyNum,  accessibilityLabel: "6"), "6"),
        (TIKeyDef(label: "−",  second: "",   alpha: "V", color: .tiKeyDark, accessibilityLabel: "Minus"), "-"),
    ] }

    private var row8Keys: [(TIKeyDef, String)] { [
        (TIKeyDef(label: "STO→", second: "",  alpha: "",  color: .tiKeyDark, accessibilityLabel: "Store"), "STO→"),
        (TIKeyDef(label: "1",    second: "",  alpha: "X", color: .tiKeyNum,  accessibilityLabel: "1"), "1"),
        (TIKeyDef(label: "2",    second: "",  alpha: "Y", color: .tiKeyNum,  accessibilityLabel: "2"), "2"),
        (TIKeyDef(label: "3",    second: "",  alpha: "Z", color: .tiKeyNum,  accessibilityLabel: "3"), "3"),
        (TIKeyDef(label: "+",    second: "",  alpha: "θ", color: .tiKeyDark, accessibilityLabel: "Plus"), "+"),
    ] }

    private var row9Trailing: [(TIKeyDef, String)] { [
        (TIKeyDef(label: "0",     second: "",      alpha: "",  color: .tiKeyNum,   accessibilityLabel: "0"), "0"),
        (TIKeyDef(label: ".",     second: "",      alpha: "",  color: .tiKeyNum,   accessibilityLabel: "Decimal point"), "."),
        (TIKeyDef(label: "(-)",   second: "ANS",   alpha: "",  color: .tiKeyNum,   accessibilityLabel: "Negative"), "(-)"),
        (TIKeyDef(label: "ENTER", second: "ENTRY", alpha: "",  color: .tiKeyEnter, accessibilityLabel: "Enter", cornerRadius: 6), "ENTER"),
    ] }
}

// MARK: - Home screen

private struct HomeScreenView: View {
    let engine: TI84Engine
    @Binding var active: CalculatorType
    @State private var cursorVisible = true

    var body: some View {
        VStack(spacing: 0) {
            // Status bar
            HStack {
                Text("NORMAL  FLOAT  AUTO  REAL  \(engine.angleMode == .degree ? "DEG" : "RAD")")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(Color(white: 0.27))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
            }
            .padding(.bottom, 2)

            // History
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if engine.homeHistory.isEmpty {
                            Text("Enter an expression")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(white: 0.65))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 8)
                        }
                        ForEach(engine.homeHistory) { line in
                            if line.isResult {
                                Text(line.result)
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundColor(line.isError ? .red : Color(white: 0.07))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            } else if !line.expr.isEmpty {
                                Text(line.expr)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(Color(white: 0.40))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                }
                .onChange(of: engine.homeHistory.count) {
                    withAnimation { proxy.scrollTo("bottom") }
                }
            }

            // Input line
            HStack(spacing: 0) {
                Text(engine.inputLine.isEmpty ? "" : engine.inputLine)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(Color(white: 0.07))
                Text("▌")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(Color(white: 0.07))
                    .opacity(cursorVisible ? 1 : 0)
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(6)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                cursorVisible.toggle()
            }
        }
    }
}

// MARK: - Y= Editor

private struct YEditorView: View {
    let engine: TI84Engine

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { i in
                    let name = i < 9 ? "Y\(i+1)" : "Y0"
                    HStack(spacing: 4) {
                        Button {
                            engine.dispatch("TOGGLE_Y\(i)")
                        } label: {
                            Image(systemName: engine.yEnabled[i] ? "checkmark.square.fill" : "square")
                                .font(.system(size: 12))
                                .foregroundColor(engine.yEnabled[i] ? Color.tiKey2nd : Color(white: 0.5))
                        }

                        Text("\(name)=")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(Color(white: 0.3))

                        if engine.yEditIndex == i {
                            Text(engine.yFunctions[i].isEmpty ? "" : engine.yFunctions[i])
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(Color(white: 0.07))
                            + Text("▌")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(Color.tiKey2nd)
                        } else {
                            Text(engine.yFunctions[i].isEmpty ? "" : engine.yFunctions[i])
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(engine.yFunctions[i].isEmpty ? Color(white: 0.65) : Color(white: 0.07))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .background(engine.yEditIndex == i ? Color.tiKey2nd.opacity(0.18) : Color.clear)
                    .onTapGesture { engine.yEditIndex = i }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Graph view

private struct GraphView: View {
    let engine: TI84Engine

    private let funcColors: [Color] = [.blue, .red, .green, .purple, .orange, Color(red:0.6,green:0,blue:0.8), .teal, .pink, .indigo, .mint]

    var body: some View {
        GeometryReader { geo in
            let enabledIdxs = engine.yFunctions.indices.filter { engine.yEnabled[$0] && !engine.yFunctions[$0].isEmpty }

            if enabledIdxs.isEmpty {
                Text("No functions enabled")
                    .font(.caption)
                    .foregroundColor(Color(white: 0.55))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if engine.cachedGraphData.isEmpty {
                ZStack {
                    Color.tiScreen
                    ProgressView().scaleEffect(0.7)
                }
            } else {
                Canvas { ctx, size in
                    // Background
                    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.tiScreen))

                    let toSx: (Double) -> CGFloat = { x in
                        CGFloat((x - engine.xMin) / (engine.xMax - engine.xMin)) * size.width
                    }
                    let toSy: (Double) -> CGFloat = { y in
                        CGFloat(1 - (y - engine.yMin) / (engine.yMax - engine.yMin)) * size.height
                    }

                    // Axes
                    if engine.yMin <= 0 && 0 <= engine.yMax {
                        let ay = toSy(0)
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: ay))
                        path.addLine(to: CGPoint(x: size.width, y: ay))
                        ctx.stroke(path, with: .color(Color(white: 0.2)), lineWidth: 1)
                    }
                    if engine.xMin <= 0 && 0 <= engine.xMax {
                        let ax = toSx(0)
                        var path = Path()
                        path.move(to: CGPoint(x: ax, y: 0))
                        path.addLine(to: CGPoint(x: ax, y: size.height))
                        ctx.stroke(path, with: .color(Color(white: 0.2)), lineWidth: 1)
                    }

                    // Tick marks
                    let xScl = max(engine.xScl, 0.01)
                    let yScl = max(engine.yScl, 0.01)
                    var xt = (floor(engine.xMin / xScl) + 1) * xScl
                    while xt < engine.xMax {
                        let sx = toSx(xt)
                        var path = Path()
                        path.move(to: CGPoint(x: sx, y: size.height/2 - 3))
                        path.addLine(to: CGPoint(x: sx, y: size.height/2 + 3))
                        ctx.stroke(path, with: .color(Color(white: 0.35)), lineWidth: 0.5)
                        xt += xScl
                    }
                    var yt = (floor(engine.yMin / yScl) + 1) * yScl
                    while yt < engine.yMax {
                        let sy = toSy(yt)
                        var path = Path()
                        path.move(to: CGPoint(x: size.width/2 - 3, y: sy))
                        path.addLine(to: CGPoint(x: size.width/2 + 3, y: sy))
                        ctx.stroke(path, with: .color(Color(white: 0.35)), lineWidth: 0.5)
                        yt += yScl
                    }

                    // Plot each function
                    for (fi, funcIdx) in enabledIdxs.enumerated() {
                        let pts = engine.graphPoints(for: funcIdx, pixelWidth: Int(size.width))
                        guard !pts.isEmpty else { continue }
                        let color = funcColors[fi % funcColors.count]
                        var path = Path()
                        var moved = false
                        for pt in pts {
                            if let (x, y) = pt {
                                let sx = toSx(x), sy = toSy(y)
                                if !moved { path.move(to: CGPoint(x: sx, y: sy)); moved = true }
                                else { path.addLine(to: CGPoint(x: sx, y: sy)) }
                            } else {
                                moved = false
                            }
                        }
                        ctx.stroke(path, with: .color(color), lineWidth: 1.5)
                    }

                    // Trace crosshair
                    if engine.traceActive {
                        let tx = CGFloat((engine.traceX - engine.xMin) / (engine.xMax - engine.xMin)) * size.width
                        if let ty = traceY(engine: engine, size: size, toSy: toSy) {
                            let arm: CGFloat = 5
                            var h = Path(); h.move(to: CGPoint(x: tx-arm, y: ty)); h.addLine(to: CGPoint(x: tx+arm, y: ty))
                            var v = Path(); v.move(to: CGPoint(x: tx, y: ty-arm)); v.addLine(to: CGPoint(x: tx, y: ty+arm))
                            ctx.stroke(h, with: .color(.black), lineWidth: 1.5)
                            ctx.stroke(v, with: .color(.black), lineWidth: 1.5)
                        }
                    }
                }
                .overlay(alignment: .top) {
                    if engine.traceActive {
                        let yName = engine.traceFuncIdx < 9 ? "Y\(engine.traceFuncIdx+1)" : "Y0"
                        Text("\(yName)  X=\(String(format: "%.4g", engine.traceX))  Y=\(traceYStr(engine: engine))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Color(white: 0.1))
                            .padding(.horizontal, 4)
                            .background(Color.tiScreen.opacity(0.85))
                    }
                }
                .onAppear {
                    // Trigger initial graph computation
                    _ = enabledIdxs.first.map { engine.graphPoints(for: $0, pixelWidth: 263) }
                }
            }
        }
    }

    private func traceY(engine: TI84Engine, size: CGSize, toSy: (Double) -> CGFloat) -> CGFloat? {
        let funcIdx = engine.traceFuncIdx
        guard funcIdx < engine.yFunctions.count, engine.yEnabled[funcIdx], !engine.yFunctions[funcIdx].isEmpty else { return nil }
        guard let y = try? engine.evaluateExpr(engine.yFunctions[funcIdx], x: engine.traceX), y.isFinite else { return nil }
        return toSy(y)
    }

    private func traceYStr(engine: TI84Engine) -> String {
        let funcIdx = engine.traceFuncIdx
        guard funcIdx < engine.yFunctions.count, engine.yEnabled[funcIdx], !engine.yFunctions[funcIdx].isEmpty else { return "---" }
        guard let y = try? engine.evaluateExpr(engine.yFunctions[funcIdx], x: engine.traceX), y.isFinite else { return "ERR" }
        return String(format: "%.4g", y)
    }
}

// MARK: - Window editor

private struct WindowEditorView: View {
    let engine: TI84Engine

    private let fieldNames = ["Xmin", "Xmax", "Xscl", "Ymin", "Ymax", "Yscl", "Xres"]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("WINDOW")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(Color(white: 0.1))
                .padding(.bottom, 2)

            ForEach(0..<7, id: \.self) { i in
                HStack {
                    Text(fieldNames[i] + "=")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(white: 0.3))
                    if engine.winField == i {
                        Text(engine.winFieldInput.isEmpty ? "" : engine.winFieldInput)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(white: 0.07))
                        + Text("▌")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.tiKey2nd)
                        Spacer()
                    } else {
                        Text(fieldValueStr(i))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(white: 0.07))
                        Spacer()
                    }
                }
                .padding(.vertical, 3)
                .padding(.horizontal, 4)
                .background(engine.winField == i ? Color.tiKey2nd.opacity(0.15) : Color.clear)
                .cornerRadius(3)
            }
            Spacer()
        }
        .padding(6)
    }

    private func fieldValueStr(_ i: Int) -> String {
        switch i {
        case 0: return formatD(engine.xMin)
        case 1: return formatD(engine.xMax)
        case 2: return formatD(engine.xScl)
        case 3: return formatD(engine.yMin)
        case 4: return formatD(engine.yMax)
        case 5: return formatD(engine.yScl)
        case 6: return "\(engine.xRes)"
        default: return ""
        }
    }

    private func formatD(_ v: Double) -> String { String(format: "%.4g", v) }
}

// MARK: - Table view

private struct TableView: View {
    let engine: TI84Engine

    var body: some View {
        VStack(spacing: 0) {
            let enabledIdxs = engine.yFunctions.indices.filter { engine.yEnabled[$0] && !engine.yFunctions[$0].isEmpty }.prefix(2)
            let rows = engine.tableRows(count: 7)

            // Header
            HStack(spacing: 0) {
                Text("X").font(.system(size: 13, weight: .bold, design: .monospaced)).frame(maxWidth: .infinity)
                ForEach(Array(enabledIdxs), id: \.self) { i in
                    Text(i < 9 ? "Y\(i+1)" : "Y0").font(.system(size: 13, weight: .bold, design: .monospaced)).frame(maxWidth: .infinity)
                }
            }
            .foregroundColor(Color(white: 0.1))
            Divider()

            ForEach(rows.indices, id: \.self) { ri in
                HStack(spacing: 0) {
                    Text(String(format: "%.4g", rows[ri].x))
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity)
                    ForEach(rows[ri].ys.indices, id: \.self) { yi in
                        if let y = rows[ri].ys[yi] {
                            Text(String(format: "%.4g", y))
                                .font(.system(size: 12, design: .monospaced))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("———")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(white: 0.55))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .foregroundColor(Color(white: 0.1))
                .padding(.vertical, 3)
            }
            Spacer()
        }
        .padding(6)
    }
}

// MARK: - STAT editor

private struct StatEditorView: View {
    let engine: TI84Engine

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("L1").font(.system(size: 13, weight: .bold, design: .monospaced)).frame(maxWidth: .infinity)
                Text("L2").font(.system(size: 13, weight: .bold, design: .monospaced)).frame(maxWidth: .infinity)
            }
            .foregroundColor(Color(white: 0.1))
            Divider()

            let maxRows = max(engine.statLists[0].count, engine.statLists[1].count) + 1
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<maxRows, id: \.self) { ri in
                        HStack(spacing: 0) {
                            cellText(list: 0, row: ri)
                            cellText(list: 1, row: ri)
                        }
                        .padding(.vertical, 3)
                        .background(engine.statEditRow == ri ? Color.tiKey2nd.opacity(0.15) : Color.clear)
                    }
                }
            }
        }
        .padding(6)
    }

    @ViewBuilder
    private func cellText(list: Int, row: Int) -> some View {
        let vals = engine.statLists[list]
        let isActive = engine.statEditList == list && engine.statEditRow == row
        if isActive {
            (Text(engine.winFieldInput) + Text("▌").foregroundColor(.tiKey2nd))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color(white: 0.07))
                .frame(maxWidth: .infinity)
        } else if row < vals.count {
            Text(String(format: "%.6g", vals[row]))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color(white: 0.07))
                .frame(maxWidth: .infinity)
        } else {
            Text("")
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - STAT results sheet

struct StatResultsView: View {
    let engine: TI84Engine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            let s = engine.stat1Var()
            let lr = engine.linReg()
            List {
                Section("1-Var Stats") {
                    row("n",  "\(s.n)")
                    row("x̄",  fmt(s.mean))
                    row("Σx", fmt(s.sumX))
                    row("Σx²", fmt(s.sumX2))
                    row("σx", fmt(s.sigmaX))
                    row("Sx", fmt(s.sx))
                }
                Section("LinReg (a+bx)") {
                    if engine.statLists[0].count >= 2 && engine.statLists[1].count >= 2 {
                        row("a", fmt(lr.a))
                        row("b", fmt(lr.b))
                        row("r", fmt(lr.r))
                    } else {
                        Text("INSUFFICIENT DATA").foregroundColor(.red)
                            .font(.system(size: 13, design: .monospaced))
                    }
                }
            }
            .navigationTitle("STAT RESULTS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 13, design: .monospaced)).foregroundColor(Color(white: 0.4))
            Spacer()
            Text(value).font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundColor(Color(white: 0.07))
        }
    }

    private func fmt(_ v: Double) -> String { engine.formatResult(v) }
}

// MARK: - Mode editor

private struct ModeEditorView: View {
    let engine: TI84Engine

    private let rows: [[String]] = [
        ["NORMAL", "SCI", "ENG"],
        ["RADIAN", "DEGREE"],
        ["FUNCTION", "PARAM", "POLAR"],
    ]
    private let rowLabels = ["Number", "Angle", "Graph"]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("MODE")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(Color(white: 0.1))
                .padding(.bottom, 2)

            ForEach(rows.indices, id: \.self) { ri in
                HStack(spacing: 8) {
                    ForEach(rows[ri].indices, id: \.self) { ci in
                        let isSelected = isOptionSelected(row: ri, col: ci)
                        Text(rows[ri][ci])
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(isSelected ? Color.tiKey2nd : Color(white: 0.4))
                            .underline(isSelected)
                            .onTapGesture { commitMode(row: ri, col: ci) }
                    }
                    Spacer()
                }
                .padding(.vertical, 3)
                .padding(.horizontal, 4)
                .background(engine.modeRow == ri ? Color.tiKey2nd.opacity(0.10) : Color.clear)
                .cornerRadius(3)
            }
            Spacer()
        }
        .padding(6)
    }

    private func isOptionSelected(row: Int, col: Int) -> Bool {
        if row == 1 { return (col == 0) == (engine.angleMode == .radian) }
        return engine.modeCol == col && engine.modeRow == row
    }

    private func commitMode(row: Int, col: Int) {
        if row == 1 { engine.angleMode = col == 0 ? .radian : .degree }
        engine.modeRow = row
        engine.modeCol = col
    }
}

// MARK: - Matrix editor

private struct MatrixEditorView: View {
    let engine: TI84Engine
    @State private var showOps = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let name = ["[A]", "[B]", "[C]"][engine.matEditIdx]

            switch engine.matPhase {
            case .dimEdit:
                Text("MATRIX \(name)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(white: 0.1))
                let prompt = engine.matDimStep == 0 ? "Rows? " : "Cols? "
                let dims = engine.matrixDims[engine.matEditIdx]
                let hint = "\(dims.rows) × \(dims.cols)"
                HStack {
                    Text(prompt).font(.system(size: 12, design: .monospaced)).foregroundColor(Color(white: 0.3))
                    Text(engine.matDimInput).font(.system(size: 12, design: .monospaced)).foregroundColor(Color(white: 0.07))
                    Text("▌").font(.system(size: 12, design: .monospaced)).foregroundColor(.tiKey2nd)
                    Spacer()
                    Text(hint).font(.system(size: 10, design: .monospaced)).foregroundColor(Color(white: 0.55))
                }
                Spacer()

            case .fill:
                Text("MATRIX \(name) \(engine.matrixDims[engine.matEditIdx].rows)×\(engine.matrixDims[engine.matEditIdx].cols)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(white: 0.1))
                let d = engine.matrixDims[engine.matEditIdx]
                let mat = engine.matrices[engine.matEditIdx]
                ForEach(0..<d.rows, id: \.self) { r in
                    HStack(spacing: 4) {
                        ForEach(0..<d.cols, id: \.self) { c in
                            let isActive = engine.matCursorR == r && engine.matCursorC == c
                            ZStack {
                                RoundedRectangle(cornerRadius: 2).fill(isActive ? Color.tiKey2nd.opacity(0.18) : Color.clear)
                                if isActive {
                                    (Text(engine.winFieldInput.isEmpty ? "0" : engine.winFieldInput) +
                                     Text("▌").foregroundColor(.tiKey2nd))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(Color(white: 0.07))
                                } else {
                                    Text(r < mat.count && c < mat[r].count ? String(format: "%.3g", mat[r][c]) : "0")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(Color(white: 0.07))
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                Spacer()

            case .ops:
                Text("MATRIX \(name) — operations")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(white: 0.1))
                    .padding(.bottom, 4)
                VStack(spacing: 6) {
                    ForEach(["[A]+[B]", "[A]−[B]", "[A]×[B]", "det([A])", "[A]⁻¹", "transpose([A])"], id: \.self) { op in
                        Button {
                            let key: String
                            switch op {
                            case "[A]+[B]": key = "MAT_OP_ADD"
                            case "[A]−[B]": key = "MAT_OP_SUB"
                            case "[A]×[B]": key = "MAT_OP_MUL"
                            case "det([A])": key = "MAT_OP_DET"
                            case "[A]⁻¹": key = "MAT_OP_INV"
                            default: key = "MAT_OP_TRP"
                            }
                            engine.dispatch(key)
                        } label: {
                            Text(op)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.tiKey2nd)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(6)
    }
}
