import SwiftUI

struct FinancialCalculatorView: View {
    @Binding var useScientific: Bool
    
    var body: some View {
        VStack {
            Text("HP 12C Style (Financial)")
                .font(.largeTitle)
                .padding()
            
            Button("Switch to Scientific (HP 15C)") {
                useScientific = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.2))
    }
}

struct ScientificCalculatorView: View {
    @Binding var useScientific: Bool
    
    var body: some View {
        VStack {
            Text("HP 15C Style (Scientific)")
                .font(.largeTitle)
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
        .background(Color.orange.opacity(0.2))
    }
}
