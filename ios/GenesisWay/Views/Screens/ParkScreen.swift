import SwiftUI

struct ParkScreen: View {
    @EnvironmentObject private var store: GenesisStore
    @State private var input = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("The Park")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(GWTheme.textPrimary)
            Text("Not now. Not never. Just not today.")
                .font(.system(size: 13))
                .foregroundStyle(GWTheme.textMuted)

            HStack(spacing: 8) {
                TextField("Park an item for later", text: $input)
                    .submitLabel(.done)
                    .focused($isInputFocused)
                    .onSubmit {
                        addParkedItem()
                    }
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(GWTheme.textPrimary)

                Button("P") {
                    addParkedItem()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "1a1208"))
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(colors: [GWTheme.gold, GWTheme.goldDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(store.parked) { item in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(GWTheme.gold.opacity(0.5))
                                .frame(width: 8, height: 8)
                            Text(item.text)
                                .font(.system(size: 13))
                                .foregroundStyle(GWTheme.textMuted)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            Button("×") {
                                store.removeParkItem(id: item.id)
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(GWTheme.textGhost)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .background(GWTheme.background.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputFocused = false
                }
                .foregroundStyle(GWTheme.gold)
            }
        }
    }

    private func addParkedItem() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isInputFocused = false
            return
        }
        store.addParkItem(trimmed)
        input = ""
    }
}
