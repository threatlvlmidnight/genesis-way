import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments

guard args.count >= 3 else {
    fputs("Usage: swift clean_icon.swift <input.png> <output.png>\n", stderr)
    exit(1)
}

let inputURL = URL(fileURLWithPath: args[1])
let outputURL = URL(fileURLWithPath: args[2])

let ciContext = CIContext(options: [
    .useSoftwareRenderer: false
])

guard
    let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
    let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
else {
    fputs("Failed to read input image.\n", stderr)
    exit(1)
}

var image = CIImage(cgImage: cgImage)

// Mild denoise to clean grain/jagged edges from generated images.
if let denoise = CIFilter(name: "CINoiseReduction") {
    denoise.setValue(image, forKey: kCIInputImageKey)
    denoise.setValue(0.018, forKey: "inputNoiseLevel")
    denoise.setValue(0.40, forKey: "inputSharpness")
    if let output = denoise.outputImage {
        image = output
    }
}

// Slight local contrast boost for crisper chrome/details.
if let controls = CIFilter(name: "CIColorControls") {
    controls.setValue(image, forKey: kCIInputImageKey)
    controls.setValue(1.08, forKey: kCIInputContrastKey)
    controls.setValue(0.0, forKey: kCIInputSaturationKey)
    if let output = controls.outputImage {
        image = output
    }
}

// Final very light sharpening pass.
if let sharpen = CIFilter(name: "CISharpenLuminance") {
    sharpen.setValue(image, forKey: kCIInputImageKey)
    sharpen.setValue(0.32, forKey: kCIInputSharpnessKey)
    if let output = sharpen.outputImage {
        image = output
    }
}

guard let cleaned = ciContext.createCGImage(image, from: CIImage(cgImage: cgImage).extent) else {
    fputs("Failed to render cleaned image.\n", stderr)
    exit(1)
}

guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fputs("Failed to create destination file.\n", stderr)
    exit(1)
}

let options: [CFString: Any] = [
    kCGImageDestinationLossyCompressionQuality: 1.0
]

CGImageDestinationAddImage(destination, cleaned, options as CFDictionary)

if !CGImageDestinationFinalize(destination) {
    fputs("Failed to write output file.\n", stderr)
    exit(1)
}

print("Wrote cleaned icon:")
print(outputURL.path)
