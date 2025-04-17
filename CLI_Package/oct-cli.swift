import Foundation
import Vision
import ImageIO
import ArgumentParser

struct LabelRenamer: ParsableCommand {
    @Option(name: [.short, .customLong("image")], help: "Path to label image (.png)")
    var imagePath: String

    @Option(name: [.short, .customLong("mrxs")], help: "Path to MRXS file to rename")
    var mrxsPath: String

    @Flag(name: .customLong("auto"), help: "Automatically rename if confidence is high")
    var autoRename: Bool = false

    let confidenceThreshold: Float = 0.85

    mutating func run() throws {
        let imageURL = URL(fileURLWithPath: imagePath)
        let mrxsURL = URL(fileURLWithPath: mrxsPath)
        let mrxsDirectory = mrxsURL.deletingLastPathComponent()

        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            print("❌ Failed to load CGImage.")
            return
        }

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

        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])

        let lines = extracted.map { $0.0 }

        func extract(pattern: String) -> (String, Float)? {
            for (line, confidence) in extracted {
                if let match = line.range(of: pattern, options: .regularExpression) {
                    return (String(line[match]), confidence)
                }
            }
            return nil
        }

        guard
            let (sampleID, confSample) = extract(pattern: #"^\d{2}-\d{3}"#),
            let (marker, confMarker) = extracted.first(where: { $0.0.range(of: #"^[a-zA-Z0-9-]{3,}$"#, options: .regularExpression) != nil }),
            let (caseID, confCase) = extract(pattern: #"NP-\d+"#)
        else {
            print("❌ Failed to extract required fields.")
            printExtracted(extracted)
            return
        }

        let suggested = "\(sampleID)_\(marker)_\(caseID).mrxs"
        let confidences = [confSample, confMarker, confCase]
        let lowConfidence = confidences.contains(where: { $0 < confidenceThreshold })

        printExtracted(extracted)

        if autoRename && !lowConfidence {
            try rename(to: suggested, from: mrxsURL, in: mrxsDirectory)
        } else {
            print("\n💡 Suggested: \(suggested)")
            print("🧠 Confidence Scores — Sample: \(confSample), Marker: \(confMarker), CaseID: \(confCase)")

            print("\nType new filename (no extension), press Enter to accept, or 'skip' to cancel:")
            if let input = readLine(strippingNewline: true) {
                if input.lowercased() == "skip" {
                    print("⏭️ Skipped.")
                    return
                }
                let finalName = input.isEmpty ? suggested : "\(input).mrxs"
                try rename(to: finalName, from: mrxsURL, in: mrxsDirectory)
            }
        }
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
}

LabelRenamer.main()
