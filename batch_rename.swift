import Foundation
import Vision
import ImageIO

let args = CommandLine.arguments
guard args.count > 2 else {
    print("Usage: swift ocr_batch.swift /path/to/label_images_folder /path/to/mrxs_folder")
    exit(1)
}

let labelFolder = URL(fileURLWithPath: args[1])
let mrxsFolder = URL(fileURLWithPath: args[2])
let fileManager = FileManager.default

let logFileURL = labelFolder.appendingPathComponent("ocr_batch_log.csv")
let confidenceThreshold: Float = 0.85

// Start log with CSV headers
try? "Label Image,Sample ID,Marker,Case ID,Confidences,Rename Result,Error\n".write(to: logFileURL, atomically: true, encoding: .utf8)

func log(_ entry: String) {
    if let handle = try? FileHandle(forWritingTo: logFileURL) {
        handle.seekToEndOfFile()
        if let data = (entry + "\n").data(using: .utf8) {
            handle.write(data)
        }
        try? handle.close()
    }
}

func extractFields(from extracted: [(String, Float)]) -> (String, String, String, [Float])? {
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
        return nil
    }

    return (sampleID, marker, caseID, [confSample, confMarker, confCase])
}

func process(labelURL: URL) {
    let labelName = labelURL.lastPathComponent
    let baseName = labelURL.deletingPathExtension().lastPathComponent
    let mrxsURL = mrxsFolder.appendingPathComponent("\(baseName).mrxs")

    guard fileManager.fileExists(atPath: mrxsURL.path) else {
        print("⚠️ Missing MRXS file for \(labelName)")
        log("\(labelName),,,,,Missing MRXS,")
        return
    }

    guard let imageSource = CGImageSourceCreateWithURL(labelURL as CFURL, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        print("❌ Failed to load image \(labelName)")
        log("\(labelName),,,,,Image Load Failed,")
        return
    }

    var extracted: [(String, Float)] = []

    let request = VNRecognizeTextRequest { request, error in
        guard let results = request.results as? [VNRecognizedTextObservation], error == nil else {
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
        print("❌ OCR failed for \(labelName)")
        log("\(labelName),,,,,OCR Failed,")
        return
    }

    guard let (sampleID, marker, caseID, confidences) = extractFields(from: extracted) else {
        print("❌ Could not extract fields from \(labelName)")
        let lines = extracted.map { "\($0.0):\($0.1)" }.joined(separator: " | ")
        log("\(labelName),,,,,Extraction Failed,\(lines)")
        return
    }

    let newFileName = "\(sampleID)_\(marker)_\(caseID).mrxs"
    let newFilePath = mrxsFolder.appendingPathComponent(newFileName)

    do {
        try fileManager.moveItem(at: mrxsURL, to: newFilePath)
        print("✅ Renamed \(mrxsURL.lastPathComponent) → \(newFileName)")

        let confidenceStr = confidences.map { String(format: "%.2f", $0) }.joined(separator: ";")
        log("\(labelName),\(sampleID),\(marker),\(caseID),\(confidenceStr),Renamed,")
    } catch {
        print("❌ Rename failed for \(labelName)")
        log("\(labelName),\(sampleID),\(marker),\(caseID),,Rename Failed,\(error.localizedDescription)")
    }
}

// MARK: - Run Batch
do {
    let files = try fileManager.contentsOfDirectory(at: labelFolder, includingPropertiesForKeys: nil)
    let pngs = files.filter { $0.pathExtension.lowercased() == "png" }

    if pngs.isEmpty {
        print("No PNG files found in folder: \(labelFolder.path)")
        exit(0)
    }

    print("🔁 Processing \(pngs.count) label images...\n")
    for labelImage in pngs {
        process(labelURL: labelImage)
    }

    print("\n📦 Done. Results logged to: \(logFileURL.path)")
} catch {
    print("❌ Failed to read folder: \(error)")
}
