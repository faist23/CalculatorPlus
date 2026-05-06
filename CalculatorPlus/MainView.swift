import SwiftUI

struct MainView: View {
    @State private var useScientific: Bool = UserDefaults.standard.bool(forKey: "hpUseScientific")
    @State private var financialEngine = HPFinancialEngine()
    @State private var scientificEngine = HPScientificEngine()

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            Group {
                if isLandscape {
                    if useScientific {
                        ScientificCalculatorView(useScientific: $useScientific, engine: scientificEngine)
                            .transition(.opacity)
                    } else {
                        FinancialCalculatorView(useScientific: $useScientific, engine: financialEngine)
                            .transition(.opacity)
                    }
                } else {
                    StandardCalculatorView()
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.25), value: isLandscape)
        }
    }
}
