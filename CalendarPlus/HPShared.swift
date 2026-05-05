import SwiftUI

// MARK: - Shared HP calculator types

enum HPShiftMode { case none, f, g }

struct TapeEntry: Identifiable {
    let id = UUID()
    let label: String
    let result: String
}

struct HPKey {
    let main: String
    let fShift: String
    let gShift: String
    init(_ main: String, f: String = "", g: String = "") {
        self.main = main; self.fShift = f; self.gShift = g
    }
}

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
        if isF { return Color(red: 0.82, green: 0.42, blue: 0.05) }
        if isG { return Color(red: 0.22, green: 0.42, blue: 0.82) }
        if isEnter { return Color(red: 0.22, green: 0.28, blue: 0.38) }
        let digits = Set("0123456789.")
        if key.main.count == 1, let ch = key.main.first, digits.contains(ch) {
            return Color(red: 0.30, green: 0.30, blue: 0.30)
        }
        return Color(red: 0.17, green: 0.17, blue: 0.17)
    }

    private let fColor = Color(red: 0.9, green: 0.6, blue: 0.1)
    private let gColor = Color(red: 0.45, green: 0.65, blue: 1.0)

    var body: some View {
        Button(action: isSettingsKey ? (onSettings ?? action) : action) {
            ZStack {
                bodyColor
                    .cornerRadius(3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )

                if isSettingsKey {
                    Image(systemName: "gear")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                } else if isVertical {
                    // Vertical ENTER text
                    VStack(spacing: 0) {
                        ForEach(Array("ENTER".enumerated()), id: \.offset) { _, ch in
                            Text(String(ch))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    VStack(spacing: 1) {
                        // f-shift label (gold, above key)
                        Group {
                            if !key.fShift.isEmpty {
                                Text(key.fShift)
                                    .foregroundColor(fColor)
                                    .opacity(shiftMode == .f ? 1 : 0.5)
                            } else {
                                Color.clear
                            }
                        }
                        .font(.system(size: 8.5, weight: .semibold))
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .frame(height: 11)

                        // Main label
                        if isF || isG {
                            Text(key.main)
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(.white)
                        } else {
                            Text(key.main)
                                .font(.system(size: mainFontSize, weight: .bold))
                                .lineLimit(1).minimumScaleFactor(0.35)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        }

                        // g-shift label (blue, below key)
                        Group {
                            if !key.gShift.isEmpty {
                                Text(key.gShift)
                                    .foregroundColor(gColor)
                                    .opacity(shiftMode == .g ? 1 : 0.5)
                            } else {
                                Color.clear
                            }
                        }
                        .font(.system(size: 8.5, weight: .semibold))
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .frame(height: 11)
                    }
                }
            }
            .frame(width: width, height: height)
        }
        .accessibilityLabel(isSettingsKey ? "Settings" : key.main)
    }

    private var mainFontSize: CGFloat {
        let len = key.main.count
        if len >= 5 { return 10 }
        if len >= 4 { return 11 }
        if len >= 3 { return 12 }
        return 14
    }
}
