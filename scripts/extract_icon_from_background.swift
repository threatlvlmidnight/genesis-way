import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct RGBA {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8
}

func loadImage(_ url: URL) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

func savePNG(_ image: CGImage, to url: URL) -> Bool {
    guard let dst = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        return false
    }
    CGImageDestinationAddImage(dst, image, nil)
    return CGImageDestinationFinalize(dst)
}

func averageCorners(_ pixels: UnsafeMutableBufferPointer<RGBA>, width: Int, height: Int, sample: Int) -> (Double, Double, Double) {
    func idx(_ x: Int, _ y: Int) -> Int { y * width + x }

    var sumR = 0.0
    var sumG = 0.0
    var sumB = 0.0
    var count = 0.0

    let corners = [
        (0, 0),
        (max(0, width - sample), 0),
        (0, max(0, height - sample)),
        (max(0, width - sample), max(0, height - sample))
    ]

    for (startX, startY) in corners {
        for y in startY..<(min(height, startY + sample)) {
            for x in startX..<(min(width, startX + sample)) {
                let p = pixels[idx(x, y)]
                sumR += Double(p.r)
                sumG += Double(p.g)
                sumB += Double(p.b)
                count += 1
            }
        }
    }

    guard count > 0 else { return (0, 0, 0) }
    return (sumR / count, sumG / count, sumB / count)
}

func main() {
    guard CommandLine.arguments.count >= 3 else {
        fputs("Usage: swift extract_icon_from_background.swift <input.png> <output_dir>\n", stderr)
        exit(1)
    }

    let inputPath = CommandLine.arguments[1]
    let outputDir = CommandLine.arguments[2]

    let inputURL = URL(fileURLWithPath: inputPath)
    let outputDirURL = URL(fileURLWithPath: outputDir)

    let fileManager = FileManager.default
    try? fileManager.createDirectory(at: outputDirURL, withIntermediateDirectories: true)

    guard let image = loadImage(inputURL) else {
        fputs("Failed to load input image.\n", stderr)
        exit(1)
    }

    let width = image.width
    let height = image.height
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let bitsPerComponent = 8

    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        fputs("Failed to create color space.\n", stderr)
        exit(1)
    }

    let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * bytesPerPixel)
    defer { rawData.deallocate() }

    guard let context = CGContext(
        data: rawData,
        width: width,
        height: height,
        bitsPerComponent: bitsPerComponent,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fputs("Failed to create context.\n", stderr)
        exit(1)
    }

    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

    let pixelBuffer = UnsafeMutableBufferPointer<RGBA>(
        start: UnsafeMutableRawPointer(rawData).assumingMemoryBound(to: RGBA.self),
        count: width * height
    )

    let (bgR, bgG, bgB) = averageCorners(pixelBuffer, width: width, height: height, sample: 20)
    let threshold = 34.0

    var minX = width
    var minY = height
    var maxX = 0
    var maxY = 0

    for y in 0..<height {
        for x in 0..<width {
            let i = y * width + x
            var p = pixelBuffer[i]

            let dr = Double(p.r) - bgR
            let dg = Double(p.g) - bgG
            let db = Double(p.b) - bgB
            let dist = sqrt(dr * dr + dg * dg + db * db)

            if dist < threshold {
                p.a = 0
                pixelBuffer[i] = p
            } else if p.a > 10 {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
    }

    guard minX <= maxX, minY <= maxY else {
        fputs("No foreground detected after background removal.\n", stderr)
        exit(1)
    }

    let pad = 24
    minX = max(0, minX - pad)
    minY = max(0, minY - pad)
    maxX = min(width - 1, maxX + pad)
    maxY = min(height - 1, maxY + pad)

    let workingImage = context.makeImage()!
    let cropRect = CGRect(
        x: minX,
        y: minY,
        width: maxX - minX + 1,
        height: maxY - minY + 1
    )

    guard let cropped = workingImage.cropping(to: cropRect) else {
        fputs("Failed to crop image.\n", stderr)
        exit(1)
    }

    let rawOut = outputDirURL.appendingPathComponent("icon-cutout-raw.png")
    guard savePNG(cropped, to: rawOut) else {
        fputs("Failed to write raw output.\n", stderr)
        exit(1)
    }

    let targetSize = 1024
    guard let squareContext = CGContext(
        data: nil,
        width: targetSize,
        height: targetSize,
        bitsPerComponent: bitsPerComponent,
        bytesPerRow: targetSize * bytesPerPixel,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fputs("Failed to create square context.\n", stderr)
        exit(1)
    }

    squareContext.clear(CGRect(x: 0, y: 0, width: targetSize, height: targetSize))

    let scale = min(Double(targetSize) / Double(cropped.width), Double(targetSize) / Double(cropped.height))
    let drawW = Double(cropped.width) * scale
    let drawH = Double(cropped.height) * scale
    let drawX = (Double(targetSize) - drawW) / 2.0
    let drawY = (Double(targetSize) - drawH) / 2.0

    squareContext.interpolationQuality = .high
    squareContext.draw(cropped, in: CGRect(x: drawX, y: drawY, width: drawW, height: drawH))

    guard let squared = squareContext.makeImage() else {
        fputs("Failed to create 1024 output image.\n", stderr)
        exit(1)
    }

    let squareOut = outputDirURL.appendingPathComponent("icon-cutout-1024.png")
    guard savePNG(squared, to: squareOut) else {
        fputs("Failed to write 1024 output.\n", stderr)
        exit(1)
    }

    print("Created:")
    print(rawOut.path)
    print(squareOut.path)
}

main()
