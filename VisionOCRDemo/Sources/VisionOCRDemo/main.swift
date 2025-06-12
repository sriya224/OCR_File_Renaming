import Foundation
import Vision
import ImageIO

let args = CommandLine.arguments
guard args.count > 1 else {
    print("Usage: swift ocr_folder.swift /path/to/folder")
    exit(1)
}

let folderPath = args[1]
let folderURL = URL(fileURLWithPath: folderPath, isDirectory: true)

let outputFileURL = folderURL.appendingPathComponent("vision_ocr_results.txt")
let fileManager = FileManager.default
if fileManager.fileExists(atPath: outputFileURL.path) {
    try? fileManager.removeItem(at: outputFileURL)
}

guard let contents = try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: []) else {
    print("❌ Failed to read folder contents at: \(folderPath)")
    exit(1)
}

let pngFiles = contents.filter { $0.pathExtension.lowercased() == "png" }

guard !pngFiles.isEmpty else {
    print("📂 No PNG files found in the folder.")
    exit(0)
}

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

    if let observations = request.results as? [VNRecognizedTextObservation] {
        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        output += lines.isEmpty ? "No text found\n\n" : lines.joined(separator: "\n") + "\n\n"
    } else {
        output += "No text results found\n\n"
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
