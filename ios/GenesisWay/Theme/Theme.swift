import SwiftUI

enum GWTheme {
    static let background = Color(hex: "0c0a06")
    static let gold = Color(hex: "c8a96e")
    static let goldDark = Color(hex: "8a6830")
    static let textPrimary = Color(hex: "f0e4d0")
    static let textMuted = Color(hex: "6a5840")
    static let textGhost = Color(hex: "3a2e18")
}

extension Color {
    init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: value).scanHexInt64(&int)

        let r, g, b: UInt64
        switch value.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
