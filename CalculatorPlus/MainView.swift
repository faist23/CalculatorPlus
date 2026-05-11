import SwiftUI

struct MainView: View {
    @State private var router = CalculatorRouter()

    var body: some View {
        @Bindable var r = router
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            Group {
                if isLandscape {
                    // Casio is portrait-only; fall back to hp15c when landscape and Casio is active
                    if router.active == .hp12c {
                        FinancialCalculatorView(active: $r.active, engine: router.hp12c)
                            .transition(.opacity)
                    } else {
                        ScientificCalculatorView(active: $r.active, engine: router.hp15c)
                            .transition(.opacity)
                    }
                } else if router.active == .casio {
                    CasioCalculatorView(active: $r.active, engine: router.casio)
                        .transition(.opacity)
                } else {
                    StandardCalculatorView()
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.25), value: isLandscape)
            .animation(.easeInOut(duration: 0.25), value: router.active)
        }
    }
}
