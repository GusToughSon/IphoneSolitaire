import Foundation
import Vision
import CoreImage
import VideoToolbox

/// Handles the visual analysis of the game screen using Apple's Vision framework.
@MainActor
class VisionScanner {
    static let shared = VisionScanner()
    
    // Thresholds for detection
    private let textConfidenceThreshold: Float = 0.5
    
    private init() {}
    
    /// Analyzes a frame to detect game elements.
    func scan(image: CGImage) {
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        // 1. Text Recognition (for card values and UI buttons)
        let textRequest = VNRecognizeTextRequest { [weak self] request, error in
            self?.handleTextRecognition(request: request, error: error, in: image)
        }
        textRequest.recognitionLevel = .accurate
        
        do {
            try handler.perform([textRequest])
            // After scanning the whole board, let the brain think
            Task {
                 await SolitaireBrain.shared.think()
            }
        } catch {
            Log.error("Vision processing error: \(error.localizedDescription)")
        }
    }
    
    private func handleTextRecognition(request: VNRequest, error: Error?, in image: CGImage) {
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first,
                  candidate.confidence > textConfidenceThreshold else { continue }
            
            let rawText = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            let box = observation.boundingBox
            
            // Clean up the text (e.g. handle common OCR errors)
            let text = sanitizeOcrText(rawText)
            
            // 1. Determine Color by sampling pixels in the bounding box
            let (color, rgb) = sampleColor(in: box, from: image)
            
            // 2. Map to Regions
            let region = mapCoordinateToRegion(box)
            
            // 3. Log findings
            if let rank = Rank.from(text: text) {
                let card = Card(rank: rank, color: color, suit: nil, location: box)
                Log.debug("Vision Board Update: Detected \(card) at normalized [X: \(String(format: "%.2f", box.midX)), Y: \(String(format: "%.2f", box.midY))] -> Region: \(region). (RGB Sample: \(rgb))")
                
                // Update Memory
                updateGameState(with: card, in: region)
            } else {
                // Check if this might be a button we care about
                if text.count < 10 { // Buttons are usually short strings
                    Log.debug("Vision Scanner: Found non-card text '\(text)' in region \(region). Passing to UI handler.")
                    SolitaireBrain.shared.handleDetectedText(text, at: box)
                }
            }
        }
    }
    
    private func sanitizeOcrText(_ text: String) -> String {
        // Some OCRs might miss characters or mistake 'A' for '^' etc.
        return text
    }
    
    private func sampleColor(in normalizedRect: CGRect, from image: CGImage) -> (CardColor, String) {
        // Sample a point in the middle of the text observation
        let x = Int(normalizedRect.midX * CGFloat(image.width))
        let y = Int((1.0 - normalizedRect.midY) * CGFloat(image.height))
        
        guard let pixelData = image.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else { return (.black, "N/A") }
        
        let bytesPerRow = image.bytesPerRow
        let offset = (y * bytesPerRow) + (x * 4) // Assuming 32-bit RGBA
        
        let b = data[offset]
        let g = data[offset + 1]
        let r = data[offset + 2]
        
        // Basic red vs black threshold
        let color: CardColor = (r > 150 && g < 100 && b < 100) ? .red : .black
        let rgbString = "R:\(r) G:\(g) B:\(b)"
        return (color, rgbString)
    }
    
    private func mapCoordinateToRegion(_ box: CGRect) -> BoardRegion {
        let x = box.midX
        let y = box.midY
        
        // Tableau is in the bottom half (mostly)
        if y < 0.7 {
            let col = Int(x * 7.0)
            return .tableau(index: min(col, 6))
        } else {
            // Top area: Foundations on left, Stock/Waste on right
            if x < 0.6 {
                let pile = Int(x / 0.15)
                return .foundation(index: min(pile, 3))
            } else {
                return x > 0.8 ? .stock : .waste
            }
        }
    }
    
    private func updateGameState(with card: Card, in region: BoardRegion) {
        switch region {
        case .tableau(let i):
            GameState.shared.updateTableau(index: i, cards: [card])
        case .foundation(let i):
            GameState.shared.updateFoundation(index: i, cards: [card])
        case .waste:
            GameState.shared.updateWaste(card: card)
        default: break
        }
    }
}

extension Rank {
    static func from(text: String) -> Rank? {
        switch text.uppercased() {
        case "A": return .ace
        case "J": return .jack
        case "Q": return .queen
        case "K": return .king
        case "10": return .ten
        case let s where (2...9).contains(Int(s) ?? 0): return Rank(rawValue: Int(s)!)
        default: return nil
        }
    }
}
