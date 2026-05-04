import SwiftUI

struct MainView: View {
    @State private var useScientific = false

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                if useScientific {
                    ScientificCalculatorView(useScientific: $useScientific)
                } else {
                    FinancialCalculatorView(useScientific: $useScientific)
                }
            } else {
                VStack {
                    Text("Standard Calculator")
                        .font(.largeTitle)
                        .padding()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
