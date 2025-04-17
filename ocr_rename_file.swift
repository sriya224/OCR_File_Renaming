import Foundation
import Vision
import ImageIO

//With confidence score

// MARK: - Handle Command Line Arguments
let args = CommandLine.arguments
guard args.count > 2 else {
    print("Usage: swift ocr.swift /path/to/image.png /path/to/file.mrxs")
    exit(1)
}

let imagePath = args[1]
let mrxsPath = args[2]
let confidenceThreshold: Float = 0.85

let imageURL = URL(fileURLWithPath: imagePath)
let mrxsURL = URL(fileURLWithPath: mrxsPath)
let mrxsDirectory = mrxsURL.deletingLastPathComponent()

// MARK: - Load Image
guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
      let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
    print("❌ Failed to load CGImage.")
    exit(1)
}

// MARK: - Run OCR
var extracted: [(String, Float)] = []

let request = VNRecognizeTextRequest { request, error in
    guard let results = request.results as? [VNRecognizedTextObservation], error == nil else {
        print("❌ OCR failed: \(error?.localizedDescription ?? "Unknown error")")
        return
    }

    for observation in results {
        if let top = observation.topCandidates(1).first {
            extracted.append((top.string, top.confidence))
        }
    }
}

request.recognitionLevel = .accurate
request.usesLanguageCorrection = true

do {
    try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
} catch {
    print("❌ OCR failed: \(error.localizedDescription)")
    exit(1)
}

// MARK: - Helpers
func extract(pattern: String) -> (String, Float)? {
    for (line, confidence) in extracted {
        if let match = line.range(of: pattern, options: .regularExpression) {
            return (String(line[match]), confidence)
        }
    }
    return nil
}

func printExtracted(_ extracted: [(String, Float)]) {
    print("\n🔍 Extracted OCR Lines:")
    for (line, conf) in extracted {
        let confidence = String(format: "%.2f", conf)
        print("🔍 \(line) (confidence: \(confidence))")
    }
}

func rename(to newName: String, from oldURL: URL, in directory: URL) throws {
    let newPath = directory.appendingPathComponent(newName)
    try FileManager.default.moveItem(at: oldURL, to: newPath)
    print("✅ Renamed to: \(newName)")
}

// MARK: - Extract Components & Rename
guard
    let (sampleID, confSample) = extract(pattern: #"^\d{2}-\d{3}"#),
    let (marker, confMarker) = extracted.first(where: { $0.0.range(of: #"^[a-zA-Z0-9-]{3,}$"#, options: .regularExpression) != nil }),
    let (caseID, confCase) = extract(pattern: #"NP-\d+"#)
else {
    print("❌ Failed to extract required fields.")
    printExtracted(extracted)
    exit(1)
}

let suggested = "\(sampleID)_\(marker)_\(caseID).mrxs"
let confidences = [confSample, confMarker, confCase]
let lowConfidence = confidences.contains(where: { $0 < confidenceThreshold })

printExtracted(extracted)

print("\n💡 Suggested: \(suggested)")
print("🧠 Confidence Scores — Sample: \(confSample), Marker: \(confMarker), CaseID: \(confCase)")

if !lowConfidence {
    print("Confidence is high. Rename file? [Y/n]")
    if let input = readLine(strippingNewline: true), input.lowercased() == "n" {
        print("⏭️ Skipped.")
        exit(0)
    }
    try rename(to: suggested, from: mrxsURL, in: mrxsDirectory)
} else {
    print("⚠️ Confidence is low. Enter a custom filename (no extension), press Enter to accept suggestion, or type 'skip':")
    if let input = readLine(strippingNewline: true) {
        if input.lowercased() == "skip" {
            print("⏭️ Skipped.")
            exit(0)
        }
        let finalName = input.isEmpty ? suggested : "\(input).mrxs"
        try rename(to: finalName, from: mrxsURL, in: mrxsDirectory)
    }
}
