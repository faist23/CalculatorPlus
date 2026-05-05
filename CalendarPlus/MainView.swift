import SwiftUI

struct MainView: View {
    @State private var useScientific: Bool = UserDefaults.standard.bool(forKey: "hpUseScientific")
    @State private var financialEngine = HPFinancialEngine()
    @State private var scientificEngine = HPScientificEngine()

    var body: some View {
        GeometryReader { geometry in
            Group {
                if geometry.size.width > geometry.size.height {
                    if useScientific {
                        ScientificCalculatorView(useScientific: $useScientific, engine: scientificEngine)
                    } else {
                        FinancialCalculatorView(useScientific: $useScientific, engine: financialEngine)
                    }
                } else {
                    StandardCalculatorView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
