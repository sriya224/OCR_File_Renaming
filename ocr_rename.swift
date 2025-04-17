import Foundation
import Vision
import ImageIO

let args = CommandLine.arguments
guard args.count == 3 else {
    print("Usage: swift ocr.swift /path/to/image.png /path/to/file.mrxs")
    exit(1)
}

let imagePath = args[1]
let mrxsPath = args[2]

let imageURL = URL(fileURLWithPath: imagePath)
let mrxsURL = URL(fileURLWithPath: mrxsPath)
let mrxsDirectory = mrxsURL.deletingLastPathComponent()

// Try to load the image as CGImage
guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
      let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
    print("❌ Failed to load CGImage from: \(imagePath)")
    exit(1)
}

// Store extracted lines
var extractedLines: [String] = []

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
            let line = bestCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            print("🔍 \(line)")
            extractedLines.append(line)
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
    exit(1)
}

// Helper to match patterns
func extractMatchingValue(from lines: [String], pattern: String) -> String? {
    let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    for line in lines {
        let range = NSRange(location: 0, length: line.utf16.count)
        if let match = regex?.firstMatch(in: line, options: [], range: range) {
            if let matchRange = Range(match.range, in: line) {
                return String(line[matchRange])
            }
        }
    }
    return nil
}

// Extract parts
guard
    let sampleID = extractMatchingValue(from: extractedLines, pattern: #"^\d{2}-\d{3}"#),
    let marker = extractedLines.first(where: { $0.range(of: #"^[a-zA-Z0-9-]{3,}$"#, options: .regularExpression) != nil }),
    let caseID = extractMatchingValue(from: extractedLines, pattern: #"NP-\d+"#)
else {
    print("❌ Failed to extract all necessary components from OCR.")
    exit(1)
}

let newFileName = "\(sampleID)_\(marker)_\(caseID).mrxs"
let newMRXSPath = mrxsDirectory.appendingPathComponent(newFileName)

do {
    try FileManager.default.moveItem(at: mrxsURL, to: newMRXSPath)
    print("\n✅ OCR text extracted:")
    extractedLines.forEach { print("🔍 \($0)") }
    print("✅ Renamed to: \(newFileName)")
} catch {
    print("❌ Failed to rename .mrxs file: \(error)")
}
