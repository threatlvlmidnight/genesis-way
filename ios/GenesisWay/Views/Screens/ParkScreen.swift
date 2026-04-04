import SwiftUI
import UIKit

struct ParkScreen: View {
    @EnvironmentObject private var store: GenesisStore
    @State private var input = ""

    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Parking Lot")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(GWTheme.textPrimary)
            Text("Someday/Maybe List. Not now. Not never. Just not today.")
                .font(.system(size: 13))
                .foregroundStyle(GWTheme.textMuted)

            if store.isParkingLotReviewOverdue {
                GlassCard {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 16))
                            .foregroundStyle(GWTheme.gold)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Review due")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(GWTheme.textPrimary)
                            Text("Go through each item — promote, delete, or keep for later.")
                                .font(.system(size: 11))
                                .foregroundStyle(GWTheme.textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Button("Done") {
                            store.markParkingLotReviewed()
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "1a1208"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(GWTheme.gold)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                }
            }

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

                    let pendingFollowUps = store.delegatedFollowUps.filter { !$0.completed }
                    if !pendingFollowUps.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pending Delegations")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(GWTheme.textGhost)
                                .textCase(.uppercase)
                                .padding(.top, 12)

                            ForEach(pendingFollowUps) { fu in
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.forward.circle")
                                        .font(.system(size: 12))
                                        .foregroundStyle(GWTheme.gold.opacity(0.7))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(fu.taskText)
                                            .font(.system(size: 13))
                                            .foregroundStyle(GWTheme.textMuted)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)

                                        HStack(spacing: 6) {
                                            if !fu.assignee.isEmpty {
                                                Text("→ \(fu.assignee)")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundStyle(GWTheme.gold.opacity(0.75))
                                            }
                                            Text("Follow up: \(fu.followUpISODate)")
                                                .font(.system(size: 10))
                                                .foregroundStyle(GWTheme.textGhost)
                                        }
                                    }

                                    Spacer()

                                    Button("Done") {
                                        store.toggleDelegateFollowUpCompleted(fu.id)
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(GWTheme.textGhost)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.06))
                                    .clipShape(Capsule())
                                    .buttonStyle(.plain)
                                }
                                .padding(12)
                                .background(GWTheme.gold.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(GWTheme.gold.opacity(0.18), lineWidth: 1)
                                }
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .background(GWTheme.background.ignoresSafeArea())
        .onDisappear {
            isInputFocused = false
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GWTheme.gold)
                .padding(.vertical, 6)
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
