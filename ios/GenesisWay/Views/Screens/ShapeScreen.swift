import SwiftUI

struct ShapeScreen: View {
    @EnvironmentObject private var store: GenesisStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Seven Spokes")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(GWTheme.textPrimary)

                        ForEach(Spoke.allCases, id: \.rawValue) { spoke in
                            HStack(spacing: 10) {
                                Image(systemName: spoke.icon)
                                    .foregroundStyle(GWTheme.gold)
                                    .frame(width: 20)
                                Text(spoke.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(GWTheme.textMuted)
                                Spacer()
                                Text("\(store.count(for: spoke))")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(GWTheme.gold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(GWTheme.gold.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Text("Assign Dump Items")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(GWTheme.textGhost)
                    .textCase(.uppercase)

                if store.dumpItems.isEmpty {
                    GlassCard {
                        Text("No dumped items yet. Capture items in Dump first.")
                            .font(.system(size: 12))
                            .foregroundStyle(GWTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    ForEach(store.dumpItems) { item in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.text)
                                    .font(.system(size: 13))
                                    .foregroundStyle(GWTheme.textPrimary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)

                                Picker("Spoke", selection: Binding<Spoke?>(
                                    get: { item.spoke },
                                    set: { store.assignDumpItem(item.id, to: $0) }
                                )) {
                                    Text("Unassigned").tag(Optional<Spoke>.none)
                                    ForEach(Spoke.allCases, id: \.rawValue) { spoke in
                                        Text(spoke.title).tag(Optional(spoke))
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(GWTheme.gold)
                            }
                        }
                    }
                }

                Text("Rhythm Anchors")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(GWTheme.textGhost)
                    .textCase(.uppercase)

                ForEach(Spoke.allCases, id: \.rawValue) { spoke in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(spoke.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GWTheme.textMuted)
                        TextField(
                            "Set one rhythm anchor",
                            text: Binding(
                                get: { store.rhythmAnchor(for: spoke) },
                                set: { store.setRhythmAnchor(for: spoke, value: $0) }
                            )
                        )
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(GWTheme.textPrimary)
                    }
                }
            }
            .padding(24)
        }
        .background(GWTheme.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Step 2 of 3")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GWTheme.textGhost)
            Text("Shape It")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(GWTheme.textPrimary)
            Text("Assign each item to one spoke and define simple rhythms.")
                .font(.system(size: 13))
                .foregroundStyle(GWTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
