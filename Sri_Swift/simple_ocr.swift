import Foundation
import Vision
import ImageIO

let args = CommandLine.arguments
guard args.count > 1 else {
    print("Usage: swift ocr.swift /path/to/image.png")
    exit(1)
}

let imagePath = args[1]
let imageURL = URL(fileURLWithPath: imagePath)

// Try to load the image as CGImage
guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
      let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
    print("❌ Failed to load CGImage from: \(imagePath)")
    exit(1)
}

// Configure the OCR request
let request = VNRecognizeTextRequest { request, error in
    if let error = error {
        print("OCR Error: \(error)")
        return
    }
    guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
        print("No text found")
        return
    }

    for observation in observations {
        if let bestCandidate = observation.topCandidates(1).first {
            print("🔍 \(bestCandidate.string)")
        }
    }
}
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true

// Perform OCR
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
do {
    try handler.perform([request])
} catch {
    print("❌ Vision OCR failed: \(error)")
}
