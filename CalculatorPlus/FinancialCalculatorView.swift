import SwiftUI

// MARK: - HP 12C Financial Calculator

struct FinancialCalculatorView: View {
    @Binding var useScientific: Bool
    let engine: HPFinancialEngine

    @State private var shiftMode: HPShiftMode = .none
    @State private var showModeMenu = false

    // Rows 1 & 2: full 10-key rows
    let row1: [HPKey] = [
        HPKey("n",   f: "AMORT", g: "12÷"),
        HPKey("i",   f: "INT",   g: "12×"),
        HPKey("PV",  f: "NPV",   g: "CF₀"),
        HPKey("PMT", f: "RND",   g: "CFⱼ"),
        HPKey("FV",  f: "IRR",   g: "Nⱼ"),
        HPKey("CHS", f: "DATE",  g: "D.MY"),
        HPKey("7",   f: "BEG",   g: "x̄"),
        HPKey("8",   f: "END",   g: "s"),
        HPKey("9",   f: "MEM",   g: "n!"),
        HPKey("÷",   f: "→",     g: "x̂"),
    ]
    let row2: [HPKey] = [
        HPKey("yˣ",  f: "x̂,r",  g: "Δ%"),
        HPKey("1/x", f: "x≷F",  g: "%T"),
        HPKey("%T",  f: "Σ+",   g: "%"),
        HPKey("Δ%",  f: "ΔDAYS", g: "EEX"),
        HPKey("%",   f: "D",    g: "ALG"),
        HPKey("EEX", f: "M",    g: "PRGM"),
        HPKey("4",   f: "CF₀",  g: "ȳ"),
        HPKey("5",   f: "CFⱼ",  g: "r"),
        HPKey("6",   f: "Nⱼ",   g: "ŷ"),
        HPKey("×",   f: "⌀,r",  g: "ȳ"),
    ]

    // Rows 3 & 4 split: left 5 cols, tall ENTER, right 4 cols
    let row3Left: [HPKey] = [
        HPKey("R/S",   f: "PSE",   g: "P/R"),
        HPKey("SST",   f: "BST",   g: "GTO"),
        HPKey("R↓",    f: "LSTx",  g: "RTN"),
        HPKey("x≷y",   f: "→H.MS", g: "→H"),
        HPKey("CLX",   f: "→RAD",  g: "→DEG"),
    ]
    let row4Left: [HPKey] = [
        HPKey("⚙",    f: "",      g: ""),
        HPKey("f",    f: "",      g: ""),
        HPKey("g",    f: "",      g: ""),
        HPKey("STO",  f: "FDISP", g: "CLΣ"),
        HPKey("RCL",  f: "ΣReg",  g: "CLx"),
    ]
    let row3Right: [HPKey] = [
        HPKey("1",  f: "→$",   g: "INT"),
        HPKey("2",  f: "→P",   g: "FRAC"),
        HPKey("3",  f: "N!",   g: "INTG"),
        HPKey("-",  f: "→P,r", g: "ABS"),
    ]
    let row4Right: [HPKey] = [
        HPKey("0",  f: "x!",  g: "x̄"),
        HPKey(".",  f: "",    g: "→H"),
        HPKey("Σ+", f: "Σ-", g: "n!"),
        HPKey("+",  f: "T",  g: "Pxy"),
    ]
    let enterKey = HPKey("ENTER", f: "PRFX", g: "LSTx")

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
                    ForEach(engine.annunciators, id: \.self) { ann in
                        Text(ann)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.black.opacity(0.65))
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

        let effective: String
        switch shiftMode {
        case .f: effective = key.fShift.isEmpty ? label : key.fShift
        case .g: effective = key.gShift.isEmpty ? label : key.gShift
        case .none: effective = label
        }
        shiftMode = .none

        engine.dispatch(effective)
    }
}
