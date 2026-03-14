import SwiftUI

struct ShapePlaceholderScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Shape It")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(GWTheme.textPrimary)
            Text("Scaffolded. Next build slice: seven-spoke categorization and rhythm anchors.")
                .font(.system(size: 13))
                .foregroundStyle(GWTheme.textMuted)

            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Planned in this slice")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(GWTheme.textPrimary)
                    Text("• Spoke assignment\n• Imbalance indicators\n• Rhythm and boundary anchors")
                        .font(.system(size: 12))
                        .foregroundStyle(GWTheme.textMuted)
                }
            }
            Spacer()
        }
        .padding(24)
        .background(GWTheme.background.ignoresSafeArea())
    }
}
