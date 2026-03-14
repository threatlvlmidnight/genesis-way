import AppKit

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "ios/GenesisWay/Assets.xcassets/AppIcon.appiconset/Icon-AppStore-1024.png"

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let bgRect = NSRect(origin: .zero, size: size)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.78, green: 0.66, blue: 0.43, alpha: 1.0),
    NSColor(calibratedRed: 0.54, green: 0.41, blue: 0.19, alpha: 1.0)
])
gradient?.draw(in: bgRect, angle: 315)

let inner = NSBezierPath(
    roundedRect: NSRect(x: 96, y: 96, width: 832, height: 832),
    xRadius: 180,
    yRadius: 180
)
NSColor(calibratedRed: 0.1, green: 0.07, blue: 0.03, alpha: 0.2).setFill()
inner.fill()

let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 360, weight: .black),
    .foregroundColor: NSColor(calibratedRed: 0.96, green: 0.91, blue: 0.82, alpha: 1.0)
]
let text = NSAttributedString(string: "GW", attributes: attrs)
let textSize = text.size()
let point = NSPoint(
    x: (size.width - textSize.width) / 2,
    y: (size.height - textSize.height) / 2 + 15
)
text.draw(at: point)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
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
