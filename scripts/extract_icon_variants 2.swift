import AppKit

let inputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Gemini_Generated_Image_5aflaa5aflaa5afl.png"
let outputDirPath = CommandLine.arguments.count > 2
    ? CommandLine.arguments[2]
    : "ios/GenesisWay/Assets.xcassets/AppIcon.appiconset"

let input = URL(fileURLWithPath: inputPath)
let outputDir = URL(fileURLWithPath: outputDirPath)

guard let source = NSImage(contentsOf: input),
      let tiff = source.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let cgImage = rep.cgImage else {
    fputs("Failed to load source image\n", stderr)
    exit(1)
}

let sheetHeight = cgImage.height
// Deterministic crop geometry from the supplied 5-up sheet.
// Uses icon centers with a tighter square to guarantee labels are excluded.
let topY = 58
let side = 308
let xCenters = [226, 586, 946, 1306, 1666]

for (index, xCenter) in xCenters.enumerated() {
    let xStart = xCenter - (side / 2)
    let yFromBottom = sheetHeight - (topY + side)
    let rect = CGRect(x: xStart, y: yFromBottom, width: side, height: side)
    guard let cropped = cgImage.cropping(to: rect) else {
        fputs("Failed crop \(index + 1)\n", stderr)
        continue
    }

    let targetSize = NSSize(width: 1024, height: 1024)
    let out = NSImage(size: targetSize)
    out.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    NSImage(cgImage: cropped, size: NSSize(width: side, height: side)).draw(
        in: NSRect(x: 0, y: 0, width: 1024, height: 1024),
        from: NSRect(x: 0, y: 0, width: side, height: side),
        operation: .copy,
        fraction: 1.0
    )
    out.unlockFocus()

    guard let outTiff = out.tiffRepresentation,
          let outRep = NSBitmapImageRep(data: outTiff),
          let png = outRep.representation(using: .png, properties: [:]) else {
        fputs("Failed render \(index + 1)\n", stderr)
        continue
    }

    let outURL = outputDir.appendingPathComponent("Icon-AppStore-1024-\(index + 1).png")
    do {
        try png.write(to: outURL)
        print("Wrote \(outURL.path)")
    } catch {
        fputs("Failed write for icon \(index + 1): \(error)\n", stderr)
    }
}
