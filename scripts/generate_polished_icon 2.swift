import AppKit
import CoreGraphics

// Usage: swift scripts/generate_polished_icon.swift [output-path]
let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "ios/icon-workshop/polished-c-1024.png"

let iconSize = 1024
let size = CGFloat(iconSize)
let colorSpace = CGColorSpaceCreateDeviceRGB()

// Create a raw CGBitmapContext — y-up, origin at bottom-left (standard CG on macOS)
guard let ctx = CGContext(
    data: nil,
    width: iconSize,
    height: iconSize,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("Failed to create CGContext\n", stderr); exit(1)
}

// ─── Background: diagonal gradient, top-left → bottom-right ───────────────
// In y-up CG: top-left = (0, size), bottom-right = (size, 0)
let bgGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        CGColor(red: 0.098, green: 0.176, blue: 0.267, alpha: 1.0),  // rich deep navy
        CGColor(red: 0.027, green: 0.055, blue: 0.090, alpha: 1.0),  // near-black midnight
    ] as CFArray,
    locations: [0.0, 1.0]
)!

ctx.drawLinearGradient(
    bgGradient,
    start: CGPoint(x: 0, y: size),      // top-left
    end:   CGPoint(x: size, y: 0),      // bottom-right
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
)

// ─── Subtle ambient light: soft radial overlay upper-left ─────────────────
let ambientGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        CGColor(red: 0.18, green: 0.40, blue: 0.65, alpha: 0.10),
        CGColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.00),
    ] as CFArray,
    locations: [0.0, 1.0]
)!

ctx.drawRadialGradient(
    ambientGradient,
    startCenter: CGPoint(x: 360, y: 700),   // upper-left in y-up
    startRadius: 0,
    endCenter:   CGPoint(x: 360, y: 700),
    endRadius:   560,
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
)

// ─── Geometric C arc ──────────────────────────────────────────────────────
//
// Design:
//   • Center:       (512, 512)
//   • Arc radius:   295  (to stroke centerline)
//   • Stroke width: 110  → outer edge 350 from center, inner edge 240
//   • Opening:      ±45° from the right horizontal (gap faces right)
//   • Caps:         round
//
// In y-up CG coordinate system (0° = right, 90° = up):
//   Top terminal    = +45°  → (512 + 295·cos45, 512 + 295·sin45) ≈ (721, 721)
//   Bottom terminal = −45°  → (512 + 295·cos45, 512 − 295·sin45) ≈ (721, 303)
//
//   Counterclockwise from +45° → 90° → 180° → 270° → −45° = 270° arc = C ✓

let arcPath = CGMutablePath()
arcPath.addArc(
    center:     CGPoint(x: 512, y: 512),
    radius:     295,
    startAngle: .pi / 4,    // +45° — top terminal
    endAngle:   -.pi / 4,   // −45° — bottom terminal
    clockwise:  false        // counterclockwise in y-up = C arc going left
)

// Convert the open path into a filled shape using the stroke geometry
let strokedArc = arcPath.copy(
    strokingWithWidth: 110,
    lineCap:   .round,
    lineJoin:  .round,
    miterLimit: 10
)

// Clip to the C shape, then fill with a gradient
ctx.saveGState()
ctx.addPath(strokedArc)
ctx.clip()

// Gradient on the C: bright white (top) → soft warm cream (bottom)
// In y-up:  top of C ≈ y=862  (512 + 295 + 55),  bottom ≈ y=162  (512 − 295 − 55)
let cGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        CGColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.0),  // pure white
        CGColor(red: 0.958, green: 0.937, blue: 0.906, alpha: 1.0),  // warm white
        CGColor(red: 0.824, green: 0.784, blue: 0.722, alpha: 1.0),  // warm cream
    ] as CFArray,
    locations: [0.0, 0.42, 1.0]
)!

ctx.drawLinearGradient(
    cGradient,
    start: CGPoint(x: 512, y: 870),   // top of C in y-up
    end:   CGPoint(x: 512, y: 154),   // bottom of C in y-up
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
)

ctx.restoreGState()

// ─── Output PNG ───────────────────────────────────────────────────────────
guard let cgImage = ctx.makeImage() else {
    fputs("Failed to create CGImage\n", stderr); exit(1)
}

let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: iconSize, height: iconSize))
guard
    let tiff   = nsImage.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png    = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Failed to encode PNG\n", stderr); exit(1)
}

let url = URL(fileURLWithPath: outputPath)
do {
    try png.write(to: url)
    print("Created: \(url.path)")
} catch {
    fputs("Error writing file: \(error)\n", stderr); exit(1)
}
