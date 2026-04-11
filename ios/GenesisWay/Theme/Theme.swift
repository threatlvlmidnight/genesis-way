import SwiftUI
import UIKit

enum GWTheme {
    private struct Palette {
        let background: Color
        let gold: Color
        let goldDark: Color
        let textPrimary: Color
        let textMuted: Color
        let textGhost: Color
    }

    private static var style: AppThemeStyle = .brown

    static var background: Color { palette(for: style).background }
    static var gold: Color { palette(for: style).gold }
    static var goldDark: Color { palette(for: style).goldDark }
    static var textPrimary: Color { palette(for: style).textPrimary }
    static var textMuted: Color { palette(for: style).textMuted }
    static var textGhost: Color { palette(for: style).textGhost }

    static func setThemeStyle(_ newStyle: AppThemeStyle) {
        style = newStyle
    }

    private static func palette(for style: AppThemeStyle) -> Palette {
        switch style {
        case .brown:
            return Palette(
                background: Color(hex: "0c0a06"),
                gold: Color(hex: "c8a96e"),
                goldDark: Color(hex: "8a6830"),
                textPrimary: Color(hex: "f0e4d0"),
                textMuted: Color(hex: "b49a72"),
                textGhost: Color(hex: "8b7454")
            )
        case .oledBlack:
            return Palette(
                background: Color(hex: "000000"),
                gold: Color(hex: "f2f2f2"),
                goldDark: Color(hex: "8f8f8f"),
                textPrimary: Color(hex: "f7f7f7"),
                textMuted: Color(hex: "8a8a8a"),
                textGhost: Color(hex: "555555")
            )
        case .lightSunrise:
            return Palette(
                background: Color(hex: "f3eee6"),
                gold: Color(hex: "ff9f7a"),
                goldDark: Color(hex: "f16f8b"),
                textPrimary: Color(hex: "5f3b2d"),
                textMuted: Color(hex: "8e6650"),
                textGhost: Color(hex: "b19179")
            )
        case .darkNightfall:
            return Palette(
                background: Color(hex: "0b1020"),
                gold: Color(hex: "7f8cff"),
                goldDark: Color(hex: "33c6ff"),
                textPrimary: Color(hex: "dae5ff"),
                textMuted: Color(hex: "7e8cae"),
                textGhost: Color(hex: "49577a")
            )
        case .oceanGlass:
            return Palette(
                background: Color(hex: "07171c"),
                gold: Color(hex: "3be0c5"),
                goldDark: Color(hex: "2190ff"),
                textPrimary: Color(hex: "d8fbff"),
                textMuted: Color(hex: "6db0bd"),
                textGhost: Color(hex: "3e6d75")
            )
        case .emberGlass:
            return Palette(
                background: Color(hex: "1a0b0b"),
                gold: Color(hex: "ff8b5f"),
                goldDark: Color(hex: "ff4f7d"),
                textPrimary: Color(hex: "ffe7de"),
                textMuted: Color(hex: "b88778"),
                textGhost: Color(hex: "7e5447")
            )
        case .coachNavy:
            return Palette(
                background: Color(hex: "0d1c2e"),
                gold: Color(hex: "c8bfae"),
                goldDark: Color(hex: "4a7aaa"),
                textPrimary: Color(hex: "e8dfd0"),
                textMuted: Color(hex: "7a8fa8"),
                textGhost: Color(hex: "4a5d70")
            )
        }
    }
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

enum GWHaptics {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
}
