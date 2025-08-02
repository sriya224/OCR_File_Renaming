import Foundation
import Vision
import ImageIO

let args = CommandLine.arguments
guard args.count > 2 else {
    print("Usage: swift ocr_folder.swift /path/to/input_folder /path/to/output_folder")
    exit(1)
}

let inputFolderPath = args[1]
let outputFolderPath = args[2]

let inputFolderURL = URL(fileURLWithPath: inputFolderPath, isDirectory: true)
let outputFolderURL = URL(fileURLWithPath: outputFolderPath, isDirectory: true)
// let dateFormatter = DateFormatter()
// dateFormatter.dateFormat = "yyyy-M-d_HH-mm"
// let date = dateFormatter.string(from: Date())
let outputFileURL = outputFolderURL.appendingPathComponent("ocr_results.txt")

let fileManager = FileManager.default

// Ensure output directory exists
if !fileManager.fileExists(atPath: outputFolderURL.path) {
    do {
        try fileManager.createDirectory(at: outputFolderURL, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print("❌ Failed to create output directory at: \(outputFolderURL.path)")
        exit(1)
    }
}

// Remove old output file if it exists
if fileManager.fileExists(atPath: outputFileURL.path) {
    try? fileManager.removeItem(at: outputFileURL)
}

// Get .png files in input folder
guard let contents = try? fileManager.contentsOfDirectory(at: inputFolderURL, includingPropertiesForKeys: nil, options: []) else {
    print("❌ Failed to read folder contents at: \(inputFolderPath)")
    exit(1)
}

let pngFiles = contents.filter { $0.pathExtension.lowercased() == "png" }

guard !pngFiles.isEmpty else {
    print("📂 No PNG files found in the folder.")
    exit(0)
}

// OCR processing loop
for imageURL in pngFiles {
    guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        print("❌ Failed to load CGImage from: \(imageURL.lastPathComponent)")
        continue
    }

    let request = VNRecognizeTextRequest()
    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

    do {
        try requestHandler.perform([request])
    } catch {
        print("❌ Failed to perform OCR on \(imageURL.lastPathComponent): \(error)")
        continue
    }

    var output = "--- \(imageURL.lastPathComponent) ---\n"

    // if let observations = request.results as? [VNRecognizedTextObservation] {
    //     let lines = observations.compactMap { $0.topCandidates(1).first?.string }
    //     output += lines.isEmpty ? "No text found\n\n" : lines.joined(separator: "\n") + "\n\n"
    // } else {
    //     output += "No text results found\n\n"
    // }
    if let error = error {
        output += "OCR Error: \(error)\n\n"
    } else if let observations = request.results as? [VNRecognizedTextObservation] {
        let lines = observations.compactMap { observation -> String? in
            if let top = observation.topCandidates(1).first {
                return String(format: "[%.2f] %@", top.confidence, top.string)
            }
            return nil
        }

        if lines.isEmpty {
            output += "No text found\n\n"
        } else {
            output += lines.joined(separator: "\n") + "\n\n"
        }
    }

    do {
        if fileManager.fileExists(atPath: outputFileURL.path) {
            let handle = try FileHandle(forWritingTo: outputFileURL)
            handle.seekToEndOfFile()
            if let data = output.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        } else {
            try output.write(to: outputFileURL, atomically: true, encoding: .utf8)
        }
        print("✅ Wrote OCR result for \(imageURL.lastPathComponent)")
    } catch {
        print("❌ Failed to write output: \(error)")
    }
}
