import SwiftUI

// MARK: - Calculator metadata

private struct CalcMeta {
    let type: CalculatorType
    let icon: String
    let tagline: String
    let accentColor: Color
}

private let calcMeta: [CalcMeta] = [
    CalcMeta(type: .hp12c,  icon: "building.columns",  tagline: "RPN • Financial",  accentColor: Color(red: 0.72, green: 0.45, blue: 0.12)),
    CalcMeta(type: .hp15c,  icon: "x.squareroot",      tagline: "RPN • Scientific", accentColor: Color(red: 0.20, green: 0.47, blue: 0.25)),
    CalcMeta(type: .casio,  icon: "function",           tagline: "Natural Display",  accentColor: Color(red: 0.15, green: 0.40, blue: 0.75)),
    CalcMeta(type: .ti84,   icon: "chart.xyaxis.line",  tagline: "Graphing",         accentColor: Color(red: 0.13, green: 0.47, blue: 0.87)),
]

// MARK: - Picker sheet

struct CalculatorPickerView: View {
    @Binding var active: CalculatorType
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(calcMeta, id: \.type) { meta in
                        CalcCard(meta: meta, isActive: active == meta.type) {
                            active = meta.type
                            dismiss()
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Card

private struct CalcCard: View {
    let meta: CalcMeta
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(meta.accentColor.opacity(isActive ? 0.18 : 0.09))
                        .frame(width: 56, height: 56)
                    Image(systemName: meta.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(meta.accentColor)
                }
                Text(meta.type.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)
                Text(meta.tagline)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isActive ? meta.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(meta.type.rawValue) calculator\(isActive ? ", selected" : "")")
    }
}
