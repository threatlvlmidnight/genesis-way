import AppKit

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "ios/GenesisWay/Assets.xcassets/AppIcon.appiconset/Icon-AppStore-1024-6.png"

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

NSColor.black.setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

let cAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 640, weight: .black),
    .foregroundColor: NSColor.white,
    .kern: 0.8
]

let cText = NSAttributedString(string: "C", attributes: cAttributes)
let cSize = cText.size()
let cPoint = NSPoint(
    x: (size.width - cSize.width) / 2 - 18,
    y: (size.height - cSize.height) / 2 - 36
)
cText.draw(at: cPoint)

let dhAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 220, weight: .bold),
    .foregroundColor: NSColor.white,
    .kern: 4.0
]

let dhText = NSAttributedString(string: "DH", attributes: dhAttributes)
let dhSize = dhText.size()
let dhPoint = NSPoint(
    x: (size.width - dhSize.width) / 2 + 6,
    y: (size.height - dhSize.height) / 2 - 2
)
dhText.draw(at: dhPoint)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("Failed to generate monochrome icon data\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: outputPath)
do {
    try png.write(to: outputURL)
    print("Created \(outputURL.path)")
} catch {
    fputs("Failed to write monochrome icon: \(error)\n", stderr)
    exit(1)
}
