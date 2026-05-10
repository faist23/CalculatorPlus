import SwiftUI

enum HPDesign {

    // MARK: - Faceplate text
    static let faceplateGold    = Color(red: 0.84, green: 0.57, blue: 0.08)
    static let groupHeaderGold  = Color(red: 0.84, green: 0.57, blue: 0.08)
    static let groupBracketGold = Color(red: 0.84, green: 0.57, blue: 0.08).opacity(0.7)

    // MARK: - Keycap labels
    static let gLabelBlue  = Color(red: 0.45, green: 0.65, blue: 1.0)
    static let mainWhite   = Color.white

    // MARK: - Keycap bodies
    static let keyDark   = Color(red: 0.17, green: 0.17, blue: 0.17)
    static let keyDigit  = Color(red: 0.30, green: 0.30, blue: 0.30)
    static let keyEnter  = Color(red: 0.22, green: 0.28, blue: 0.38)
    static let keyF      = Color(red: 0.82, green: 0.42, blue: 0.05)
    static let keyG      = Color(red: 0.22, green: 0.42, blue: 0.82)

    // MARK: - Calculator body gradient
    static let bodyTop    = Color(red: 0.19, green: 0.18, blue: 0.16)
    static let bodyBottom = Color(red: 0.10, green: 0.10, blue: 0.09)

    // MARK: - Typography

    /// Main label font for a keycap. Caps are sized so the label dominates the key face.
    static func mainFont(height: CGFloat, charCount: Int) -> Font {
        let (scale, cap): (CGFloat, CGFloat)
        switch charCount {
        case 0...2: (scale, cap) = (0.50, 30)
        case 3:     (scale, cap) = (0.44, 26)
        case 4:     (scale, cap) = (0.38, 22)
        case 5:     (scale, cap) = (0.32, 20)
        default:    (scale, cap) = (0.27, 17)
        }
        let size = min(max(11, height * scale), cap)
        return .system(size: size, weight: .bold)
    }

    /// g-shift label font, printed on the slanted lower face of the keycap.
    static func gFont(height: CGFloat) -> Font {
        let size = min(max(9, height * 0.22), 13)
        return .system(size: size, weight: .semibold)
    }

    /// Faceplate f-shift label font (gold labels above each key row).
    static func fFont(keyHeight: CGFloat) -> Font {
        let size = min(max(9, keyHeight * 0.22), 12)
        return .system(size: size, weight: .semibold)
    }

    /// Faceplate group header font (Bond, Depreciation, Clear).
    static let groupHeaderFont = Font.system(size: 9, weight: .semibold)
}
