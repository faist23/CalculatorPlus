import SwiftUI

// MARK: - HP 15C Scientific Calculator

struct ScientificCalculatorView: View {
    @Binding var useScientific: Bool
    let engine: HPScientificEngine

    @State private var shiftMode: HPShiftMode = .none
    @State private var hypMode: Bool = false
    @State private var showModeMenu = false

    // Rows 1 & 2: full 10-key rows
    let row1: [HPKey] = [
        HPKey("√x",  f: "x²",    g: "LN"),
        HPKey("eˣ",  f: "LN",    g: "LOG"),
        HPKey("10ˣ", f: "LOG",   g: "ex"),
        HPKey("yˣ",  f: "1/x",   g: "%"),
        HPKey("1/x", f: "%",     g: "Δ%"),
        HPKey("CHS", f: "ABS",   g: "⌈x⌉"),
        HPKey("7",   f: "FIX",   g: "DEG"),
        HPKey("8",   f: "SCI",   g: "RAD"),
        HPKey("9",   f: "ENG",   g: "GRD"),
        HPKey("÷",   f: "x≷(i)", g: "TEST"),
    ]
    let row2: [HPKey] = [
        HPKey("SIN", f: "SIN⁻¹", g: "HYP"),
        HPKey("COS", f: "COS⁻¹", g: "HYP"),
        HPKey("TAN", f: "TAN⁻¹", g: "HYP"),
        HPKey("π",   f: "→P",    g: "→R"),
        HPKey("ABS", f: "→H.MS", g: "→H"),
        HPKey("EEX", f: "SEED",  g: "RAN#"),
        HPKey("4",   f: "x̄",     g: "s"),
        HPKey("5",   f: "ȳ",     g: "sy"),
        HPKey("6",   f: "n",     g: "Σxy"),
        HPKey("×",   f: "→°C",   g: "→°F"),
    ]

    // Rows 3 & 4: left 5 cols, tall ENTER, right 4 cols
    let row3Left: [HPKey] = [
        HPKey("R/S",  f: "PSE",   g: "P/R"),
        HPKey("SST",  f: "BST",   g: "GTO"),
        HPKey("R↓",   f: "LSTx",  g: "RTN"),
        HPKey("x≷y",  f: "RND",   g: "CLx"),
        HPKey("CLx",  f: "CLΣ",   g: "CLRG"),
    ]
    let row4Left: [HPKey] = [
        HPKey("⚙",   f: "",      g: ""),
        HPKey("f",   f: "",      g: ""),
        HPKey("g",   f: "",      g: ""),
        HPKey("STO", f: "FRAC",  g: "INT"),
        HPKey("RCL", f: "→R",    g: "→P"),
    ]
    let row3Right: [HPKey] = [
        HPKey("1",  f: "→km",  g: "→mi"),
        HPKey("2",  f: "→cm",  g: "→in"),
        HPKey("3",  f: "→m",   g: "→ft"),
        HPKey("-",  f: "→kg",  g: "→lb"),
    ]
    let row4Right: [HPKey] = [
        HPKey("0",  f: "x!",  g: "x̄"),
        HPKey(".",  f: "…",   g: "→H"),
        HPKey("Σ+", f: "Σ-", g: "n!"),
        HPKey("+",  f: "LR",  g: "Pxy"),
    ]
    let enterKey = HPKey("ENTER", f: "PRFX", g: "LST")

    var body: some View {
        VStack(spacing: 6) {
            lcdDisplay

            GeometryReader { geo in
                let hPad: CGFloat = 14
                let hGap: CGFloat = 5
                let vGap: CGFloat = 5
                let cols: CGFloat = 10
                let btnW = (geo.size.width - hPad * 2 - hGap * (cols - 1)) / cols
                let btnH = min(btnW * 1.3, (geo.size.height - vGap * 3) / 4)
                let tallH = btnH * 2 + vGap

                VStack(spacing: vGap) {
                    HStack(spacing: hGap) {
                        ForEach(row1.indices, id: \.self) { i in
                            HPButtonView(key: row1[i], width: btnW, height: btnH,
                                         shiftMode: shiftMode) { keyTapped(row1[i]) }
                        }
                    }
                    HStack(spacing: hGap) {
                        ForEach(row2.indices, id: \.self) { i in
                            HPButtonView(key: row2[i], width: btnW, height: btnH,
                                         shiftMode: shiftMode) { keyTapped(row2[i]) }
                        }
                    }
                    HStack(alignment: .top, spacing: hGap) {
                        VStack(spacing: vGap) {
                            HStack(spacing: hGap) {
                                ForEach(row3Left.indices, id: \.self) { i in
                                    HPButtonView(key: row3Left[i], width: btnW, height: btnH,
                                                 shiftMode: shiftMode) { keyTapped(row3Left[i]) }
                                }
                            }
                            HStack(spacing: hGap) {
                                ForEach(row4Left.indices, id: \.self) { i in
                                    let key = row4Left[i]
                                    HPButtonView(key: key, width: btnW, height: btnH,
                                                 shiftMode: shiftMode,
                                                 isSettingsKey: key.main == "⚙",
                                                 onSettings: { showModeMenu = true }) { keyTapped(key) }
                                }
                            }
                        }

                        HPButtonView(key: enterKey, width: btnW, height: tallH,
                                     shiftMode: shiftMode) { keyTapped(enterKey) }

                        VStack(spacing: vGap) {
                            HStack(spacing: hGap) {
                                ForEach(row3Right.indices, id: \.self) { i in
                                    HPButtonView(key: row3Right[i], width: btnW, height: btnH,
                                                 shiftMode: shiftMode) { keyTapped(row3Right[i]) }
                                }
                            }
                            HStack(spacing: hGap) {
                                ForEach(row4Right.indices, id: \.self) { i in
                                    HPButtonView(key: row4Right[i], width: btnW, height: btnH,
                                                 shiftMode: shiftMode) { keyTapped(row4Right[i]) }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, hPad)
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
        .confirmationDialog("Calculator Mode", isPresented: $showModeMenu, titleVisibility: .visible) {
            Button("Financial") {
                useScientific = false
                UserDefaults.standard.set(false, forKey: "hpUseScientific")
            }
            Button("Scientific") {
                useScientific = true
                UserDefaults.standard.set(true, forKey: "hpUseScientific")
            }
            Button("Cancel", role: .cancel) {}
        }
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
                    Spacer()
                    Button { showModeMenu = true } label: {
                        Image(systemName: "gear")
                            .font(.system(size: 13))
                            .foregroundColor(.black.opacity(0.45))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 5)
                .frame(height: 20)

                if hasTape {
                    TapeView(entries: engine.tape, onRecall: { engine.recallTapeValue($0) })
                        .frame(maxHeight: 56)
                }

                Spacer(minLength: 4)

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
        .frame(height: hasTape ? 140 : 68)
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }

    // MARK: - Key handling

    private func keyTapped(_ key: HPKey) {
        let label = key.main

        if label == "f" { shiftMode = shiftMode == .f ? .none : .f; return }
        if label == "g" { shiftMode = shiftMode == .g ? .none : .g; return }
        if label == "⚙" { showModeMenu = true; return }

        var effective: String
        switch shiftMode {
        case .f: effective = key.fShift.isEmpty ? label : key.fShift
        case .g: effective = key.gShift.isEmpty ? label : key.gShift
        case .none: effective = label
        }
        shiftMode = .none

        if effective == "HYP" { hypMode.toggle(); return }

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
        }

        engine.dispatch(effective)
    }
}
