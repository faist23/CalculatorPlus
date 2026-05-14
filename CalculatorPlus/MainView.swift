import SwiftUI

struct MainView: View {
    @State private var router = CalculatorRouter()
    @State private var showPicker = false

    private var isPortraitOnly: Bool {
        router.active == .ti84 || router.active == .casio
    }

    var body: some View {
        @Bindable var r = router
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            ZStack(alignment: .topTrailing) {
                Group {
                    if isLandscape && isPortraitOnly {
                        ZStack {
                            Color(red: 0.12, green: 0.12, blue: 0.14).ignoresSafeArea()
                            VStack(spacing: 16) {
                                Image(systemName: "rotate.right").font(.system(size: 44))
                                Text("Rotate to portrait\nto use \(router.active.rawValue)")
                                    .multilineTextAlignment(.center)
                                    .font(.title3)
                            }
                            .foregroundColor(.white)
                        }
                    } else {
                        switch router.active {
                        case .hp12c:
                            FinancialCalculatorView(active: $r.active, engine: router.hp12c)
                                .transition(.opacity)
                        case .hp15c:
                            ScientificCalculatorView(active: $r.active, engine: router.hp15c)
                                .transition(.opacity)
                        case .casio:
                            CasioCalculatorView(active: $r.active, engine: router.casio)
                                .transition(.opacity)
                        case .ti84:
                            TI84CalculatorView(active: $r.active, engine: router.ti84)
                                .transition(.opacity)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.25), value: isLandscape)
                .animation(.easeInOut(duration: 0.25), value: router.active)

                Button { showPicker = true } label: {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(9)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Switch calculator")
                .padding(.top, geometry.safeAreaInsets.top + 8)
                .padding(.trailing, 14)
            }
        }
        .sheet(isPresented: $showPicker) {
            CalculatorPickerView(active: $router.active)
        }
        .ignoresSafeArea()
    }
}
