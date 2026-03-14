import AppKit
import Foundation

struct Variant {
    let id: String
    let gradientTop: NSColor
    let gradientBottom: NSColor
    let symbol: String
    let symbolSize: CGFloat
    let overlayAlpha: CGFloat
    let ring: Bool
}

let variants: [Variant] = [
    Variant(
        id: "A",
        gradientTop: NSColor(calibratedRed: 0.79, green: 0.67, blue: 0.44, alpha: 1),
        gradientBottom: NSColor(calibratedRed: 0.53, green: 0.39, blue: 0.17, alpha: 1),
        symbol: "GW",
        symbolSize: 340,
        overlayAlpha: 0.18,
        ring: false
    ),
    Variant(
        id: "B",
        gradientTop: NSColor(calibratedRed: 0.98, green: 0.84, blue: 0.50, alpha: 1),
        gradientBottom: NSColor(calibratedRed: 0.64, green: 0.43, blue: 0.16, alpha: 1),
        symbol: "⟁",
        symbolSize: 360,
        overlayAlpha: 0.12,
        ring: true
    ),
    Variant(
        id: "C",
        gradientTop: NSColor(calibratedRed: 0.74, green: 0.58, blue: 0.30, alpha: 1),
        gradientBottom: NSColor(calibratedRed: 0.22, green: 0.14, blue: 0.06, alpha: 1),
        symbol: "7",
        symbolSize: 380,
        overlayAlpha: 0.22,
        ring: true
    ),
]

let outputDir = "ios/GenesisWay/Assets.xcassets/AppIcon.appiconset"
let fileManager = FileManager.default

func drawIcon(variant: Variant, outputPath: String) throws {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    image.lockFocus()

    let bgRect = NSRect(origin: .zero, size: size)
    let gradient = NSGradient(colors: [variant.gradientTop, variant.gradientBottom])
    gradient?.draw(in: bgRect, angle: 315)

    let inner = NSBezierPath(
        roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824),
        xRadius: 180,
        yRadius: 180
    )
    NSColor(calibratedWhite: 0.05, alpha: variant.overlayAlpha).setFill()
    inner.fill()

    if variant.ring {
        let ringRect = NSRect(x: 250, y: 250, width: 524, height: 524)
        let ringPath = NSBezierPath(ovalIn: ringRect)
        NSColor(calibratedWhite: 1, alpha: 0.16).setStroke()
        ringPath.lineWidth = 22
        ringPath.stroke()
    }

    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: variant.symbolSize, weight: .black),
        .foregroundColor: NSColor(calibratedRed: 0.96, green: 0.91, blue: 0.82, alpha: 1.0)
    ]
    let text = NSAttributedString(string: variant.symbol, attributes: attrs)
    let textSize = text.size()
    let point = NSPoint(
        x: (size.width - textSize.width) / 2,
        y: (size.height - textSize.height) / 2 + 12
    )
    text.draw(at: point)

    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconWorkshop", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to render PNG data"]) 
    }

    try png.write(to: URL(fileURLWithPath: outputPath))
}

for variant in variants {
    let path = "\(outputDir)/Icon-AppStore-1024-\(variant.id).png"
    do {
        try drawIcon(variant: variant, outputPath: path)
        print("Created \(path)")
    } catch {
        fputs("Failed creating \(path): \(error.localizedDescription)\n", stderr)
        exit(1)
    }
}

let active = "B"
let activeSource = "\(outputDir)/Icon-AppStore-1024-\(active).png"
let activeTarget = "\(outputDir)/Icon-AppStore-1024.png"

do {
    if fileManager.fileExists(atPath: activeTarget) {
        try fileManager.removeItem(atPath: activeTarget)
    }
    try fileManager.copyItem(atPath: activeSource, toPath: activeTarget)
    print("Set active icon from variant \(active)")
} catch {
    fputs("Failed to set active icon: \(error.localizedDescription)\n", stderr)
    exit(1)
}
