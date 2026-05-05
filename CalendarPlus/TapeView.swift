import SwiftUI

struct TapeView: View {
    let entries: [TapeEntry]
    var onRecall: ((Double) -> Void)? = nil

    @State private var highlightedID: UUID? = nil

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .trailing, spacing: 1) {
                    ForEach(entries) { entry in
                        HStack(spacing: 4) {
                            Text(entry.label)
                                .foregroundColor(.black.opacity(0.4))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Text(entry.result)
                                .foregroundColor(.black.opacity(0.7))
                                .lineLimit(1)
                        }
                        .font(.custom("Courier", size: 10))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(
                            highlightedID == entry.id
                                ? Color.black.opacity(0.15)
                                : Color.clear
                        )
                        .cornerRadius(3)
                        .id(entry.id)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.4)
                                .onEnded { _ in
                                    guard let value = parseResult(entry.result) else { return }
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    withAnimation(.easeIn(duration: 0.08)) { highlightedID = entry.id }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        withAnimation(.easeOut(duration: 0.2)) { highlightedID = nil }
                                    }
                                    onRecall?(value)
                                }
                        )
                    }
                }
                .padding(.vertical, 2)
            }
            .onChange(of: entries.count) { _, _ in
                if let last = entries.last {
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func parseResult(_ s: String) -> Double? {
        Double(s.replacingOccurrences(of: ",", with: ""))
    }
}
