import SwiftUI

struct MainView: View {
    @State private var useScientific = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if geometry.size.width > geometry.size.height {
                    if useScientific {
                        ScientificCalculatorView(useScientific: $useScientific)
                    } else {
                        FinancialCalculatorView(useScientific: $useScientific)
                    }
                } else {
                    StandardCalculatorView()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
