import SwiftUI

// MARK: - Scientific Calculator (RPN)

struct ScientificCalculatorView: View {
    @Binding var active: CalculatorType
    let engine: HPScientificEngine

    @State private var shiftMode: HPShiftMode = .none
    @State private var showPicker = false
    @State private var hypMode: Bool = false
    @State private var hypInvMode: Bool = false

    // Rows 1 & 2: full 10-key rows
    let row1: [HPKey] = [
        HPKey("√x",  f: "A",      g: "x²"),
        HPKey("eˣ",  f: "B",      g: "LN"),
        HPKey("10ˣ", f: "C",      g: "LOG"),
        HPKey("yˣ",  f: "D",      g: "%"),
        HPKey("1/x", f: "E",      g: "Δ%"),
        HPKey("CHS", f: "MATRIX", g: "ABS"),
        HPKey("7",   f: "FIX",    g: "DEG"),
        HPKey("8",   f: "SCI",    g: "RAD"),
        HPKey("9",   f: "ENG",    g: "GRD"),
        HPKey("÷",   f: "SOLVE",  g: "x≤y"),
    ]
    let row2: [HPKey] = [
        HPKey("SST", f: "LBL",    g: "BST"),
        HPKey("GTO", f: "HYP",    g: "HYP⁻¹"),
        HPKey("SIN", f: "DIM",    g: "SIN⁻¹"),
        HPKey("COS", f: "(i)",    g: "COS⁻¹"),
        HPKey("TAN", f: "I",      g: "TAN⁻¹"),
        HPKey("EEX", f: "RESULT", g: "π"),
        HPKey("4",   f: "x≥0",   g: "SF"),
        HPKey("5",   f: "DSE",    g: "CF"),
        HPKey("6",   f: "ISG",    g: "F?"),
        HPKey("×",   f: "∫xy",   g: "x=0"),
    ]

    // Rows 3 & 4: left 5 cols, tall ENTER, right 4 cols
    let row3Left: [HPKey] = [
        HPKey("R/S", f: "PSE",    g: "P/R"),
        HPKey("GSB", f: "Σ",      g: "RTN"),
        HPKey("R↓",  f: "PRGM",   g: "R↑"),
        HPKey("x≷y", f: "REG",    g: "RND"),
        HPKey("←",   f: "PREFIX", g: "CLx"),
    ]
    let row4Left: [HPKey] = [
        HPKey("ON",  f: "",       g: ""),
        HPKey("f",   f: "",       g: ""),
        HPKey("g",   f: "",       g: ""),
        HPKey("STO", f: "FRAC",   g: "INT"),
        HPKey("RCL", f: "USER",   g: "MEM"),
    ]
    let row3Right: [HPKey] = [
        HPKey("1",  f: "→R",      g: "→P"),
        HPKey("2",  f: "→H.MS",   g: "→H"),
        HPKey("3",  f: "→RAD",    g: "→DEG"),
        HPKey("−",  f: "Re≷Im",   g: "TEST"),
    ]
    let row4Right: [HPKey] = [
        HPKey("0",  f: "x!",      g: "x̄"),
        HPKey(".",  f: "ŷ,r",     g: "s"),
        HPKey("Σ+", f: "L.R.",    g: "Σ−"),
        HPKey("+",  f: "Py,x",    g: "Cy,x"),
    ]
    let enterKey = HPKey("ENTER", f: "RAN#", g: "LSTx")

    var body: some View {
        VStack(spacing: 6) {
            lcdDisplay

            GeometryReader { geo in
                let hPad: CGFloat = 14
                let hGap: CGFloat = 5
                let vGap: CGFloat = 3
                let cols: CGFloat = 10
                let btnW = (geo.size.width - hPad * 2 - hGap * (cols - 1)) / cols
                let fRowH = max(12, min(18, geo.size.height * 0.055))
                let groupH = max(10, min(14, geo.size.height * 0.042))
                let availH = geo.size.height - fRowH * 4 - groupH - vGap * 8
                let btnH = min(min(btnW * 1.3, availH / 4), 80)
                let tallH = btnH * 2 + vGap

                let clearGroups = [
                    FaceplateGroup(label: "CLEAR", startIndex: 1, endIndex: 4),
                ]

                VStack(spacing: vGap) {
                    // Row 1
                    FaceplateRow(keys: row1, keyWidth: btnW, keyHeight: btnH, gap: hGap)
                        .frame(height: fRowH).padding(.horizontal, hPad)
                    HStack(spacing: hGap) {
                        ForEach(row1.indices, id: \.self) { i in
                            HPButtonView(key: row1[i], width: btnW, height: btnH,
                                         shiftMode: shiftMode) { keyTapped(row1[i]) }
                        }
                    }.padding(.horizontal, hPad)

                    // Row 2
                    FaceplateRow(keys: row2, keyWidth: btnW, keyHeight: btnH, gap: hGap)
                        .frame(height: fRowH).padding(.horizontal, hPad)
                    HStack(spacing: hGap) {
                        ForEach(row2.indices, id: \.self) { i in
                            HPButtonView(key: row2[i], width: btnW, height: btnH,
                                         shiftMode: shiftMode) { keyTapped(row2[i]) }
                        }
                    }.padding(.horizontal, hPad)

                    // Rows 3 & 4 (split layout)
                    HStack(alignment: .top, spacing: 0) {
                        // Left block (5 cols)
                        VStack(spacing: vGap) {
                            // CLEAR bracket — above row 3 faceplate labels
                            FaceplateGroupHeader(groups: clearGroups,
                                                 keyWidth: btnW, gap: hGap, totalKeys: row3Left.count)
                                .frame(height: groupH)
                            FaceplateRow(keys: row3Left, keyWidth: btnW, keyHeight: btnH, gap: hGap)
                                .frame(height: fRowH)
                            HStack(spacing: hGap) {
                                ForEach(row3Left.indices, id: \.self) { i in
                                    HPButtonView(key: row3Left[i], width: btnW, height: btnH,
                                                 shiftMode: shiftMode) { keyTapped(row3Left[i]) }
                                }
                            }
                            FaceplateRow(keys: row4Left, keyWidth: btnW, keyHeight: btnH, gap: hGap)
                                .frame(height: fRowH)
                            HStack(spacing: hGap) {
                                ForEach(row4Left.indices, id: \.self) { i in
                                    HPButtonView(key: row4Left[i], width: btnW, height: btnH,
                                                 shiftMode: shiftMode,
                                                 isSettingsKey: i == 0,
                                                 onSettings: { showPicker = true }) { keyTapped(row4Left[i]) }
                                }
                            }
                        }
                        .frame(width: CGFloat(row3Left.count) * (btnW + hGap) - hGap)

                        // ENTER key (tall, 1 col wide) with its faceplate label
                        VStack(spacing: 0) {
                            // Offset matches CLEAR bracket + vGap so RAN# aligns with row3 faceplate labels
                            Color.clear.frame(height: groupH + vGap)
                            Text(enterKey.fShift.isEmpty ? " " : enterKey.fShift)
                                .font(HPDesign.fFont(keyHeight: btnH))
                                .foregroundColor(HPDesign.faceplateGold)
                                .frame(height: fRowH)
                            HPButtonView(key: enterKey, width: btnW, height: tallH + fRowH + vGap,
                                         shiftMode: shiftMode) { keyTapped(enterKey) }
                            Spacer(minLength: 0)
                        }
                        .frame(width: btnW + hGap)

                        // Right block (4 cols)
                        VStack(spacing: vGap) {
                            // Offset matches CLEAR bracket so row3Right faceplate aligns with row3Left
                            Color.clear.frame(height: groupH)
                            FaceplateRow(keys: row3Right, keyWidth: btnW, keyHeight: btnH, gap: hGap)
                                .frame(height: fRowH)
                            HStack(spacing: hGap) {
                                ForEach(row3Right.indices, id: \.self) { i in
                                    HPButtonView(key: row3Right[i], width: btnW, height: btnH,
                                                 shiftMode: shiftMode) { keyTapped(row3Right[i]) }
                                }
                            }
                            FaceplateRow(keys: row4Right, keyWidth: btnW, keyHeight: btnH, gap: hGap)
                                .frame(height: fRowH)
                            HStack(spacing: hGap) {
                                ForEach(row4Right.indices, id: \.self) { i in
                                    HPButtonView(key: row4Right[i], width: btnW, height: btnH,
                                                 shiftMode: shiftMode) { keyTapped(row4Right[i]) }
                                }
                            }
                        }
                        .frame(width: CGFloat(row3Right.count) * (btnW + hGap) - hGap)
                    }
                    .padding(.horizontal, hPad)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.19, green: 0.18, blue: 0.16),
                         Color(red: 0.10, green: 0.10, blue: 0.09)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
        )
        .sheet(isPresented: $showPicker) { CalculatorPickerView(active: $active) }
    }

    // MARK: - LCD

    @ViewBuilder
    private var lcdDisplay: some View {
        let hasTape = !engine.tape.isEmpty
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.62, green: 0.68, blue: 0.52))

            VStack(spacing: 0) {
                HStack {
                    Text("f")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.88, green: 0.52, blue: 0.08))
                        .opacity(shiftMode == .f ? 1 : 0.25)
                    Text("g")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.95))
                        .opacity(shiftMode == .g ? 1 : 0.25)
                    Text(engine.angleMode == .deg ? "DEG" : "RAD")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.black.opacity(0.5))
                        .padding(.leading, 6)
                    if hypMode {
                        Text("HYP")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.95))
                            .padding(.leading, 4)
                    }
                    if hypInvMode {
                        Text("HYP⁻¹")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.95))
                            .padding(.leading, 4)
                    }
                    Spacer()
                    Text(active.rawValue)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.black.opacity(0.35))
                }
                .padding(.horizontal, 8)
                .padding(.top, 5)
                .frame(height: 20)

                if hasTape {
                    TapeView(entries: engine.tape, onRecall: { engine.recallTapeValue($0) })
                        .frame(maxHeight: 56)
                }

                Spacer(minLength: 4)

                // Y register
                HStack {
                    Text("y")
                        .font(.custom("Courier", size: 13))
                        .foregroundColor(.black.opacity(0.35))
                    Spacer()
                    Text(engine.fmt(engine.stack[1]))
                        .font(.custom("Courier", size: 21))
                        .foregroundColor(.black.opacity(0.45))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.horizontal, 8)
                .frame(height: 28)

                // X register (main display)
                HStack {
                    Spacer()
                    Text(engine.displayText)
                        .font(.custom("Courier", size: 34))
                        .foregroundColor(.black.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 5)
                .frame(height: 42)
            }
        }
        .frame(height: hasTape ? 156 : 100)
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }

    // MARK: - Key handling

    private func keyTapped(_ key: HPKey) {
        let label = key.main

        if label == "f" { shiftMode = shiftMode == .f ? .none : .f; return }
        if label == "g" { shiftMode = shiftMode == .g ? .none : .g; return }
        if label == "ON" { showPicker = true; return }

        // f + digit 0-9 → FIX n (HP-15C authentic behaviour)
        if shiftMode == .f, label.count == 1, let n = Int(label) {
            engine.displayDecimalPlaces = n
            engine.displayText = engine.fmt(engine.stack[0])
            shiftMode = .none
            return
        }

        var effective: String
        switch shiftMode {
        case .f: effective = key.fShift.isEmpty ? label : key.fShift
        case .g: effective = key.gShift.isEmpty ? label : key.gShift
        case .none: effective = label
        }
        shiftMode = .none

        if effective == "HYP" { hypMode = true; hypInvMode = false; return }
        if effective == "HYP⁻¹" { hypInvMode = true; hypMode = false; return }

        if hypMode {
            switch effective {
            case "SIN":   effective = "SINH"
            case "COS":   effective = "COSH"
            case "TAN":   effective = "TANH"
            case "SIN⁻¹": effective = "SINH⁻¹"
            case "COS⁻¹": effective = "COSH⁻¹"
            case "TAN⁻¹": effective = "TANH⁻¹"
            default: break
            }
            hypMode = false
        } else if hypInvMode {
            switch effective {
            case "SIN":   effective = "SINH⁻¹"
            case "COS":   effective = "COSH⁻¹"
            case "TAN":   effective = "TANH⁻¹"
            default: break
            }
            hypInvMode = false
        }

        engine.dispatch(effective)
    }
}
