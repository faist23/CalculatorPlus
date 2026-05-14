import SwiftUI

struct MainView: View {
    @State private var router = CalculatorRouter()

    var body: some View {
        @Bindable var r = router
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            Group {
                if isLandscape {
                    // TI-84 is portrait-only — show overlay, no auto-switch
                    if router.active == .ti84 {
                        ZStack {
                            Color(red: 0.18, green: 0.18, blue: 0.20).ignoresSafeArea()
                            VStack(spacing: 12) {
                                Image(systemName: "rotate.right").font(.largeTitle)
                                Text("Rotate to portrait\nto use TI-84")
                                    .multilineTextAlignment(.center)
                            }
                            .foregroundColor(.white)
                        }
                    } else if router.active == .hp12c {
                        FinancialCalculatorView(active: $r.active, engine: router.hp12c)
                            .transition(.opacity)
                    } else {
                        // Casio is portrait-only; fall back to hp15c when landscape and Casio is active
                        ScientificCalculatorView(active: $r.active, engine: router.hp15c)
                            .transition(.opacity)
                    }
                } else if router.active == .casio {
                    CasioCalculatorView(active: $r.active, engine: router.casio)
                        .transition(.opacity)
                } else if router.active == .ti84 {
                    TI84CalculatorView(active: $r.active, engine: router.ti84)
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
