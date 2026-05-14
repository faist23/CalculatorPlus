import Foundation

// MARK: - Shared tape type (used by all calculator engines)

struct TapeEntry: Identifiable {
    let id = UUID()
    let label: String
    let result: String
}

// MARK: - Calculator engine protocol

protocol CalculatorEngine: AnyObject {
    var displayText: String { get }
    var tape: [TapeEntry] { get }
    var displayDecimalPlaces: Int { get set }
    func dispatch(_ key: String)
    func recallTapeValue(_ v: Double)
}

// MARK: - Calculator type

enum CalculatorType: String, CaseIterable {
    case hp12c = "Financial"
    case hp15c = "Scientific"
    case casio = "Natural"
    case ti84  = "Graphing"
}

// MARK: - Router

@Observable
final class CalculatorRouter {
    var active: CalculatorType {
        didSet { UserDefaults.standard.set(active.rawValue, forKey: "activeCalculator") }
    }

    let hp12c = HPFinancialEngine()
    let hp15c = HPScientificEngine()
    let casio = CasioEngine()
    let ti84  = TI84Engine()

    init() {
        if let raw = UserDefaults.standard.string(forKey: "activeCalculator"),
           let saved = CalculatorType(rawValue: raw) {
            active = saved
        } else {
            active = .hp12c
        }
    }
}
