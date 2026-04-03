import AppKit

// Isolates the five icon tiles from the original 5-up artwork sheet into
// individual PNGs (raw crop + normalized 1024x1024 export), excluding captions.

let inputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Gemini_Generated_Image_5aflaa5aflaa5afl.png"
let outputRootPath = CommandLine.arguments.count > 2
    ? CommandLine.arguments[2]
    : "ios/icon-workshop/isolated"

let inputURL = URL(fileURLWithPath: inputPath)
let outputRootURL = URL(fileURLWithPath: outputRootPath)
let rawURL = outputRootURL.appendingPathComponent("raw", isDirectory: true)
let out1024URL = outputRootURL.appendingPathComponent("1024", isDirectory: true)

let fileManager = FileManager.default

func ensureDir(_ url: URL) {
    if !fileManager.fileExists(atPath: url.path) {
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
}

func pngData(from image: NSImage) -> Data? {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff) else {
        return nil
    }
    return rep.representation(using: .png, properties: [:])
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let data = pngData(from: image) else {
        throw NSError(domain: "isolate_icon_tiles", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Failed to encode PNG for \(url.lastPathComponent)"
        ])
    }
    try data.write(to: url)
}

func writeScaledPNG(from cgImage: CGImage, side: Int, targetSide: Int, to url: URL) throws {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: targetSide,
        pixelsHigh: targetSide,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "isolate_icon_tiles", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Failed to allocate bitmap rep"
        ])
    }

    NSGraphicsContext.saveGraphicsState()
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        NSGraphicsContext.restoreGraphicsState()
        throw NSError(domain: "isolate_icon_tiles", code: 3, userInfo: [
            NSLocalizedDescriptionKey: "Failed to create graphics context"
        ])
    }

    NSGraphicsContext.current = ctx
    NSGraphicsContext.current?.imageInterpolation = .high
    NSImage(cgImage: cgImage, size: NSSize(width: side, height: side)).draw(
        in: NSRect(x: 0, y: 0, width: targetSide, height: targetSide),
        from: NSRect(x: 0, y: 0, width: side, height: side),
        operation: .copy,
        fraction: 1.0
    )
    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "isolate_icon_tiles", code: 4, userInfo: [
            NSLocalizedDescriptionKey: "Failed to encode scaled PNG"
        ])
    }
    try png.write(to: url)
}

ensureDir(outputRootURL)
ensureDir(rawURL)
ensureDir(out1024URL)

guard let source = NSImage(contentsOf: inputURL),
      let tiff = source.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let cgImage = rep.cgImage else {
    fputs("Failed to load source sheet: \(inputURL.path)\n", stderr)
    exit(1)
}

let names = ["chrome", "textile", "stone", "molten", "obsidian-glass"]

// Pixel-perfect geometry for this specific source sheet.
// Rows 44...373 contain icon + shadow, while captions start below this range.
let topY = 44
let side = 330
let xCenters = [226, 586, 946, 1306, 1666]

for (index, name) in names.enumerated() {
    let xCenter = xCenters[index]
    let xStart = xCenter - (side / 2)
    let yFromBottom = cgImage.height - (topY + side)
    let rect = CGRect(x: xStart, y: yFromBottom, width: side, height: side)

    guard let cropped = cgImage.cropping(to: rect) else {
        fputs("Failed crop for \(name) at rect \(rect)\n", stderr)
        continue
    }

    let rawImage = NSImage(cgImage: cropped, size: NSSize(width: side, height: side))
    let rawOut = rawURL.appendingPathComponent("\(index + 1)-\(name)-raw.png")

    do {
        try writePNG(rawImage, to: rawOut)
    } catch {
        fputs("Failed raw write for \(name): \(error)\n", stderr)
        continue
    }

    let out1024 = out1024URL.appendingPathComponent("\(index + 1)-\(name)-1024.png")
    do {
        try writeScaledPNG(from: cropped, side: side, targetSide: 1024, to: out1024)
        print("Wrote \(rawOut.path)")
        print("Wrote \(out1024.path)")
    } catch {
        fputs("Failed 1024 write for \(name): \(error)\n", stderr)
    }
}

print("Done. Isolated icons are in \(outputRootURL.path)")
