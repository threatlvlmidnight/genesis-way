import AppKit

let arguments = Array(CommandLine.arguments.dropFirst())
let outputPath = arguments.first
    ?? "ios/GenesisWay/Assets.xcassets/AppIcon.appiconset/Icon-AppStore-1024.png"
let glyph = arguments.count > 1 ? arguments[1] : "G"
let style = arguments.count > 2 ? arguments[2] : "genesis"

let size = NSSize(width: 1024, height: 1024)
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Failed to create bitmap context\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

let bgRect = NSRect(origin: .zero, size: size)
switch style.lowercased() {
case "simple-c":
    NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.13, alpha: 1.0).setFill()
    bgRect.fill()

    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 620, weight: .bold),
        .foregroundColor: NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.91, alpha: 1.0),
        .kern: -18
    ]
    let text = NSAttributedString(string: glyph, attributes: attrs)
    let textSize = text.size()
    let point = NSPoint(
        x: (size.width - textSize.width) / 2 + 8,
        y: (size.height - textSize.height) / 2 - 22
    )
    text.draw(at: point)
default:
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.34, green: 0.38, blue: 0.43, alpha: 1.0),
        NSColor(calibratedRed: 0.23, green: 0.27, blue: 0.31, alpha: 1.0)
    ])
    gradient?.draw(in: bgRect, angle: 300)

    let inner = NSBezierPath(
        roundedRect: NSRect(x: 84, y: 84, width: 856, height: 856),
        xRadius: 190,
        yRadius: 190
    )
    NSColor(calibratedRed: 0.08, green: 0.11, blue: 0.14, alpha: 0.22).setFill()
    inner.fill()

    let ringOuter = NSBezierPath(ovalIn: NSRect(x: 188, y: 188, width: 648, height: 648))
    NSColor(calibratedRed: 0.86, green: 0.90, blue: 0.94, alpha: 0.14).setStroke()
    ringOuter.lineWidth = 16
    ringOuter.stroke()

    let ringInner = NSBezierPath(ovalIn: NSRect(x: 232, y: 232, width: 560, height: 560))
    NSColor(calibratedRed: 0.84, green: 0.89, blue: 0.95, alpha: 0.10).setStroke()
    ringInner.lineWidth = 6
    ringInner.stroke()

    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 500, weight: .black),
        .foregroundColor: NSColor(calibratedRed: 0.92, green: 0.95, blue: 0.98, alpha: 0.98),
        .kern: 1.5
    ]
    let text = NSAttributedString(string: glyph, attributes: attrs)
    let textSize = text.size()
    let point = NSPoint(
        x: (size.width - textSize.width) / 2,
        y: (size.height - textSize.height) / 2 - 8
    )
    text.draw(at: point)

    if glyph == "G" {
        let cutPath = NSBezierPath(roundedRect: NSRect(x: 558, y: 468, width: 208, height: 56), xRadius: 18, yRadius: 18)
        NSColor(calibratedRed: 0.25, green: 0.29, blue: 0.34, alpha: 1.0).setFill()
        cutPath.fill()

        let accentPath = NSBezierPath(roundedRect: NSRect(x: 610, y: 486, width: 112, height: 20), xRadius: 10, yRadius: 10)
        NSColor(calibratedRed: 0.94, green: 0.97, blue: 1.0, alpha: 0.95).setFill()
        accentPath.fill()
    }
}

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Failed to generate icon data\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: outputPath)
do {
    try png.write(to: outputURL)
    print("Created \(outputURL.path)")
} catch {
    fputs("Failed to write icon: \(error)\n", stderr)
    exit(1)
}
