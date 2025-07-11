import Foundation
import Vision
import ImageIO

let args = CommandLine.arguments
guard args.count > 1 else {
    print("Usage: swift ocr_simple.swift /path/to/label.png")
    exit(1)
}

let imagePath = args[1]
let imageURL = URL(fileURLWithPath: imagePath)

// Load the image
guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
      let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
    print("❌ Failed to load image from \(imagePath)")
    exit(1)
}

var extracted: [(String, Float)] = []

let request = VNRecognizeTextRequest { request, error in
    guard let results = request.results as? [VNRecognizedTextObservation], error == nil else {
        print("❌ OCR failed: \(error?.localizedDescription ?? "Unknown error")")
        return
    }

    for observation in results {
        if let topCandidate = observation.topCandidates(1).first {
            extracted.append((topCandidate.string, topCandidate.confidence))
        }
    }
}

request.recognitionLevel = .accurate
request.usesLanguageCorrection = true

do {
    try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
} catch {
    print("❌ Vision OCR failed: \(error)")
    exit(1)
}

print("📄 File: \(imagePath)\n")
print("🔍 Extracted OCR Results:")
for (line, confidence) in extracted {
    let formattedConfidence = String(format: "%.2f", confidence)
    print("🔹 \"\(line)\" (confidence: \(formattedConfidence))")
}
