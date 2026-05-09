import SwiftUI

// MARK: - HP 12C Financial Calculator

struct FinancialCalculatorView: View {
    @Binding var useScientific: Bool
    let engine: HPFinancialEngine

    @State private var shiftMode: HPShiftMode = .none
    @State private var showModeMenu = false

    // Rows 1 & 2: full 10-key rows
    let row1: [HPKey] = [
        HPKey("n",   f: "AMORT", g: "12×"),
        HPKey("i",   f: "INT",   g: "12÷"),
        HPKey("PV",  f: "NPV",   g: "CFo"),
        HPKey("PMT", f: "RND",   g: "CFj"),
        HPKey("FV",  f: "IRR",   g: "Nj"),
        HPKey("CHS", f: "",      g: "DATE"),
        HPKey("7",   f: "",      g: "BEG"),
        HPKey("8",   f: "",      g: "END"),
        HPKey("9",   f: "",      g: "MEM"),
        HPKey("÷",   f: "",      g: ""),
    ]
    let row2: [HPKey] = [
        HPKey("yˣ",  f: "PRICE", g: "√x"),
        HPKey("1/x", f: "YTM",   g: "eˣ"),
        HPKey("%T",  f: "SL",    g: "LN"),
        HPKey("Δ%",  f: "SOYD",  g: "FRAC"),
        HPKey("%",   f: "DB",    g: "INTG"),
        HPKey("EEX", f: "",      g: "ΔDYS"),
        HPKey("4",   f: "",      g: "D.MY"),
        HPKey("5",   f: "",      g: "M.DY"),
        HPKey("6",   f: "",      g: "x̄w"),
        HPKey("×",   f: "",      g: ""),
    ]

    // Rows 3 & 4 split: left 5 cols, tall ENTER, right 4 cols
    let row3Left: [HPKey] = [
        HPKey("R/S",  f: "P/R",   g: "PSE"),
        HPKey("SST",  f: "Σ",     g: "BST"),
        HPKey("R↓",   f: "PRGM",  g: "GTO"),
        HPKey("x≷y",  f: "FIN",   g: "x≤y"),
        HPKey("CLx",  f: "REG",   g: "x=0"),
    ]
    let row4Left: [HPKey] = [
        HPKey("⚙",   f: "",      g: ""),
        HPKey("f",   f: "",      g: ""),
        HPKey("g",   f: "",      g: ""),
        HPKey("STO", f: "",      g: ""),
        HPKey("RCL", f: "",      g: ""),
    ]
    let row3Right: [HPKey] = [
        HPKey("1",  f: "",       g: "x̂,r"),
        HPKey("2",  f: "",       g: "ŷ,r"),
        HPKey("3",  f: "",       g: "n!"),
        HPKey("-",  f: "",       g: ""),
    ]
    let row4Right: [HPKey] = [
        HPKey("0",  f: "",       g: "x̄"),
        HPKey(".",  f: "",       g: "s"),
        HPKey("Σ+", f: "",       g: "Σ−"),
        HPKey("+",  f: "",       g: ""),
    ]
    let enterKey = HPKey("ENTER", f: "PREFIX", g: "LSTx")

    var body: some View {
        VStack(spacing: 6) {
            lcdDisplay

            GeometryReader { geo in
                let hPad: CGFloat = 14
                let hGap: CGFloat = 5
                let vGap: CGFloat = 3
                let cols: CGFloat = 10
                let btnW = (geo.size.width - hPad * 2 - hGap * (cols - 1)) / cols
                let fRowH = max(12, geo.size.height * 0.055)
                // "BOND / DEPRECIATION" header sits between rows 1 and 2 — give it its own slot
                let groupH = max(10, geo.size.height * 0.042)
                let availH = geo.size.height - fRowH * 4 - groupH * 2 - vGap * 9
                let btnH = min(btnW * 1.3, availH / 4)
                let tallH = btnH * 2 + vGap

                // Bond/Depreciation groups for row 2 (indices into a 10-key row2)
                let bondGroups = [
                    FaceplateGroup(label: "BOND",        startIndex: 0, endIndex: 1),
                    FaceplateGroup(label: "DEPRECIATION", startIndex: 2, endIndex: 4),
                ]
                // Clear group for row 3 left (indices into a 5-key row; excludes R/S at index 0)
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

                    // Bond / Depreciation group header
                    FaceplateGroupHeader(groups: bondGroups,
                                        keyWidth: btnW, gap: hGap, totalKeys: row2.count)
                        .frame(height: groupH).padding(.horizontal, hPad)

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
                                    let key = row4Left[i]
                                    HPButtonView(key: key, width: btnW, height: btnH,
                                                 shiftMode: shiftMode,
                                                 isSettingsKey: key.main == "⚙",
                                                 onSettings: { showModeMenu = true }) { keyTapped(key) }
                                }
                            }
                        }
                        .frame(width: CGFloat(row3Left.count) * (btnW + hGap) - hGap)

                        // ENTER key (tall, 1 col wide) with its faceplate label
                        VStack(spacing: 0) {
                            // Offset matches CLEAR bracket + vGap so PREFIX aligns with row3 faceplate labels
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
