import Foundation
import Vision
import CoreImage
import ImageIO

func performOCR(on image: CGImage, completion: @escaping (String?) -> Void) {
    let requestHandler = VNImageRequestHandler(cgImage: image)
    let request = VNRecognizeTextRequest { request, error in
        guard error == nil,
              let observations = request.results as? [VNRecognizedTextObservation] else {
            completion(nil)
            return
        }
        
        let text = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: "\n")
        
        completion(text)
    }
    
    request.recognitionLanguages = ["zh-Hans", "zh-Hant"]
    
    do {
        try requestHandler.perform([request])
    } catch {
        print("Error performing OCR: \(error)")
        completion(nil)
    }
}

func loadCGImage(from path: String) -> CGImage? {
    guard let imageSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        return nil
    }
    return cgImage
}

func scanPNGFiles() {
    let fileManager = FileManager.default
    let currentPath = fileManager.currentDirectoryPath
    
    do {
        let contents = try fileManager.contentsOfDirectory(atPath: currentPath)
        let pngFiles = contents.filter { $0.lowercased().hasSuffix(".png") }
        
        for pngFile in pngFiles {
            let filePath = (currentPath as NSString).appendingPathComponent(pngFile)
            guard let cgImage = loadCGImage(from: filePath) else {
                print("Could not load image: \(pngFile)")
                continue
            }
            
            performOCR(on: cgImage) { recognizedText in
                if let text = recognizedText, text.contains("考试题目") {
                    print("Found '考试题目' in file: \(pngFile)")
                }
            }
        }
    } catch {
        print("Error reading directory: \(error)")
    }
}

// Run the scanner
scanPNGFiles()
RunLoop.main.run()

