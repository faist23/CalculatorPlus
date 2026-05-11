import SwiftUI

struct MainView: View {
    @State private var router = CalculatorRouter()

    var body: some View {
        @Bindable var r = router
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            Group {
                if router.active == .casio {
                    CasioCalculatorView(active: $r.active, engine: router.casio)
                        .transition(.opacity)
                } else if isLandscape {
                    if router.active == .hp15c {
                        ScientificCalculatorView(active: $r.active, engine: router.hp15c)
                            .transition(.opacity)
                    } else {
                        FinancialCalculatorView(active: $r.active, engine: router.hp12c)
                            .transition(.opacity)
                    }
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
