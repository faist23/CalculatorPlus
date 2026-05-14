import SwiftUI

// MARK: - Shared HP calculator types

enum HPShiftMode { case none, f, g }

struct HPKey {
    let main: String
    let fShift: String
    let gShift: String
    init(_ main: String, f: String = "", g: String = "") {
        self.main = main; self.fShift = f; self.gShift = g
    }
}

// MARK: - Button view

struct HPButtonView: View {
    let key: HPKey
    let width: CGFloat
    let height: CGFloat
    let shiftMode: HPShiftMode
    var isSettingsKey: Bool = false
    var onSettings: (() -> Void)? = nil
    let action: () -> Void

    private var isF: Bool { key.main == "f" }
    private var isG: Bool { key.main == "g" }
    private var isEnter: Bool { key.main == "ENTER" }
    private var isVertical: Bool { height > width * 1.4 }

    private var bodyColor: Color {
        if isF     { return HPDesign.keyF }
        if isG     { return HPDesign.keyG }
        if isEnter { return HPDesign.keyEnter }
        let digits = Set("0123456789.")
        if key.main.count == 1, let ch = key.main.first, digits.contains(ch) {
            return HPDesign.keyDigit
        }
        return HPDesign.keyDark
    }

    // ENTER key body: top face with stacked letters + darker slanted bottom with g-label
    @ViewBuilder
    private var enterKeyBody: some View {
        let slopeH = height * 0.26
        let topH = height - slopeH
        // Size to fit 5 letters in 80% of topH; line height ≈ 1.2× font size
        let letterSize = max(9, topH * 0.80 / 5 / 1.2)
        let letters: [String] = ["E", "N", "T", "E", "R"]
        VStack(spacing: 0) {
            // Top face: gradient sheen + stacked ENTER letters
            ZStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.22), Color.clear],
                    startPoint: .top, endPoint: .bottom
                )
                VStack(spacing: 0) {
                    Spacer()
                    ForEach(letters.indices, id: \.self) { i in
                        Text(letters[i])
                            .font(.system(size: letterSize, weight: .bold))
                            .foregroundColor(HPDesign.mainWhite)
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height - slopeH)

            // Slanted bottom face: darker + g-label
            ZStack {
                Color.black.opacity(0.28)
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.white.opacity(0.20))
                        .frame(height: 0.75)
                    Spacer()
                }
                if !key.gShift.isEmpty {
                    Text(key.gShift)
                        .font(HPDesign.gFont(height: height * 0.5))
                        .foregroundColor(HPDesign.gLabelBlue)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: slopeH)
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    var body: some View {
        Button(action: isSettingsKey ? (onSettings ?? action) : action) {
            ZStack {
                // Keycap base fill + shadow
                RoundedRectangle(cornerRadius: 3)
                    .fill(bodyColor)
                    .shadow(color: .black.opacity(0.55), radius: 2.5, x: 0, y: 2)

                if isSettingsKey {
                    // Gradient sheen over settings key
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.clear],
                        startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    Image(systemName: "gear")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)

                } else if isVertical {
                    // Tall ENTER key: split face handled inside enterKeyBody
                    enterKeyBody

                } else if isF || isG {
                    // f / g shift keys: gradient sheen + dominant label
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.clear],
                        startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    Text(key.main)
                        .font(.system(size: max(14, height * 0.32), weight: .black))
                        .foregroundColor(HPDesign.mainWhite)

                } else {
                    // Standard key: top face (lighter) + slanted lower face (darker) with g-label
                    VStack(spacing: 0) {
                        // Top face — gradient sheen + main label centered
                        ZStack {
                            LinearGradient(
                                colors: [Color.white.opacity(0.22), Color.clear],
                                startPoint: .top, endPoint: .bottom
                            )
                            Text(key.main)
                                .font(HPDesign.mainFont(height: height * 0.64, charCount: key.main.count))
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                                .foregroundColor(HPDesign.mainWhite)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: height * 0.64)

                        // Slanted lower face — darker + g-label
                        ZStack {
                            Color.black.opacity(0.28)
                            // Thin highlight line at the face/slope step
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.20))
                                    .frame(height: 0.75)
                                Spacer()
                            }
                            if !key.gShift.isEmpty {
                                Text(key.gShift)
                                    .font(HPDesign.gFont(height: height))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .foregroundColor(HPDesign.gLabelBlue)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: height * 0.36)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }

                // Border drawn last (on top of all content)
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
            }
            .frame(width: width, height: height)
        }
        .buttonStyle(HPPressStyle())
        .accessibilityLabel(isSettingsKey ? "Settings" : key.main)
        .accessibilityHint([key.fShift, key.gShift].filter { !$0.isEmpty }.joined(separator: ", "))
    }
}

// MARK: - Faceplate f-shift label row

/// Renders the gold f-shift labels on the calculator faceplate above a key row.
/// Each label is aligned to its corresponding key using the same width and gap.
struct FaceplateRow: View {
    let keys: [HPKey]
    let keyWidth: CGFloat
    let keyHeight: CGFloat
    let gap: CGFloat

    var body: some View {
        HStack(spacing: gap) {
            ForEach(keys.indices, id: \.self) { i in
                Group {
                    if keys[i].fShift == "∫xy" {
                        let sz = min(max(9.0, keyHeight * 0.22), 12.0)
                        HStack(alignment: .center, spacing: 1) {
                            Text("∫")
                                .font(.system(size: sz, weight: .semibold))
                            VStack(spacing: -1) {
                                Text("x").font(.system(size: max(5, sz * 0.58), weight: .semibold))
                                Text("y").font(.system(size: max(5, sz * 0.58), weight: .semibold))
                            }
                        }
                        .foregroundColor(HPDesign.faceplateGold)
                    } else if !keys[i].fShift.isEmpty {
                        Text(keys[i].fShift)
                            .foregroundColor(HPDesign.faceplateGold)
                    } else {
                        Color.clear
                    }
                }
                .font(HPDesign.fFont(keyHeight: keyHeight))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: keyWidth)
            }
        }
    }
}

// MARK: - Faceplate group header (Bond / Depreciation / Clear)

/// A labeled bracket spanning a range of keys on the faceplate.
struct FaceplateGroup {
    let label: String
    /// Key indices this group spans (inclusive).
    let startIndex: Int
    let endIndex: Int
}

/// Renders one or more FaceplateGroup labels with bracket lines above a key row.
struct FaceplateGroupHeader: View {
    let groups: [FaceplateGroup]
    let keyWidth: CGFloat
    let gap: CGFloat
    let totalKeys: Int

    var body: some View {
        GeometryReader { geo in
            let leftEdge: CGFloat = 0
            Canvas { ctx, size in
                for group in groups {
                    let x0 = xCenter(group.startIndex) - keyWidth / 2
                    let x1 = xCenter(group.endIndex)   + keyWidth / 2
                    let midX = (x0 + x1) / 2
                    let lineY: CGFloat = size.height * 0.72

                    var path = Path()
                    path.move(to: CGPoint(x: x0, y: lineY))
                    path.addLine(to: CGPoint(x: x1, y: lineY))
                    ctx.stroke(path, with: .color(HPDesign.groupBracketGold), lineWidth: 0.8)

                    // Tick marks down from line ends
                    for x in [x0, x1] {
                        var tick = Path()
                        tick.move(to: CGPoint(x: x, y: lineY))
                        tick.addLine(to: CGPoint(x: x, y: lineY + 3))
                        ctx.stroke(tick, with: .color(HPDesign.groupBracketGold), lineWidth: 0.8)
                    }

                    // Label above the line
                    let labelStr = AttributedString(group.label)
                    ctx.draw(
                        Text(group.label)
                            .font(HPDesign.groupHeaderFont)
                            .foregroundColor(HPDesign.groupHeaderGold),
                        at: CGPoint(x: midX, y: size.height * 0.18),
                        anchor: .top
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func xCenter(_ index: Int) -> CGFloat {
        CGFloat(index) * (keyWidth + gap) + keyWidth / 2
    }
}

// MARK: - Shared calculator press style (used by Casio and TI-84)

struct CalcPressStyle: ButtonStyle {
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

// MARK: - HP calculator press style

struct HPPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { pressed in
                if pressed { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
            }
            .scaleEffect(configuration.isPressed ? 0.91 : 1.0)
            .brightness(configuration.isPressed ? -0.14 : 0)
            .animation(.easeOut(duration: 0.07), value: configuration.isPressed)
    }
}
