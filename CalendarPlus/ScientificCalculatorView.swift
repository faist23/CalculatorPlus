import SwiftUI

struct ScientificCalculatorView: View {
    @Binding var useScientific: Bool
    
    var body: some View {
        VStack {
            Text("HP 15C Style (Scientific) Placeholder")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()
            
            Button("Switch to Financial (HP 12C)") {
                useScientific = false
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}
