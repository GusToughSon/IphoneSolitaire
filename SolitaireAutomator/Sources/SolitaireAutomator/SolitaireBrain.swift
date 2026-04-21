import Foundation
import CoreGraphics

/// The logic engine that decides which moves to make based on the visual state.
@MainActor
class SolitaireBrain {
    static let shared = SolitaireBrain()
    
    // State tracking
    private var lastActionTime = Date()
    private let minimumActionInterval: TimeInterval = 1.0 // Faster actions now
    
    private init() {}
    
    /// Main entry point for decision making, called after vision scan.
    func think() async {
        guard Date().timeIntervalSince(lastActionTime) > minimumActionInterval else { return }
        
        Log.debug("Brain Thinking Strategy: Analyzing current board model...")
        let moves = GameState.shared.findLegalMoves()
        
        if let bestMove = moves.first {
            Log.action("Strategy Decision: Executing BEST MOVE: \(bestMove.card) from \(bestMove.source) to \(bestMove.destination) (Priority: \(bestMove.priority))")
            if moves.count > 1 {
                Log.debug("Reasoning: Chosen over \(moves.count - 1) other potential legal moves.")
            }
            executeMove(bestMove)
            lastActionTime = Date()
        } else {
            // No legal moves seen, try clicking the stock pile
            tryClickStock()
        }
    }
    
    /// Handles detected ad buttons or UI prompts.
    func handleDetectedText(_ text: String, at normalizedRect: CGRect) {
        let textLower = text.lowercased()
        
        if textLower == "x" || textLower == "close" || textLower == "skip" {
            Log.action("UI Handler: INTERRUPT DETECTED (Ad/Popup). Text: '\(text)'. Attempting to close...")
            clickNormalized(at: normalizedRect)
            lastActionTime = Date()
        } else if textLower == "done" || textLower == "collect" {
            Log.action("UI Handler: End-game trigger '\(text)' detected. Collecting results...")
            clickNormalized(at: normalizedRect)
            lastActionTime = Date()
        }
    }
    
    // MARK: - Execution Helpers
    
    private func executeMove(_ move: SolitaireMove) {
        // We click the card at its exact detected location from Vision.
        Log.action("Brain: Clicking card \(move.card) at normalized rect \(move.card.location)")
        clickNormalized(at: move.card.location)
    }
    
    private func tryClickStock() {
        // Only click stock if enough time has passed
        guard Date().timeIntervalSince(lastActionTime) > 3.0 else { return }
        
        Log.debug("Brain: No moves. Clicking Stock Pile area.")
        // Stock is usually in the top-right corner. 
        // Normalized: midX ~ 0.9, midY ~ 0.9 (Bottom-left is 0,0)
        let stockRect = CGRect(x: 0.8, y: 0.85, width: 0.15, height: 0.1)
        clickNormalized(at: stockRect)
        lastActionTime = Date()
    }
    
    /// Helper to click a region defined by normalized coordinates (0.0 - 1.0).
    private func clickNormalized(at rect: CGRect) {
        Task { @MainActor in
            guard let window = await MirroringEngine.shared.findMirroringWindow() else { 
                Log.error("Brain: Cannot click. Mirroring window not found.")
                return 
            }
            
            let windowWidth = window.frame.width
            let windowHeight = window.frame.height
            
            // Vision coordinates: 0,0 is bottom-left
            // Mouse coordinates: 0,0 is top-left
            let pixelX = rect.midX * windowWidth
            let pixelY = (1.0 - rect.midY) * windowHeight
            
            Log.action("Brain: Sending click to pixel (\(Int(pixelX)), \(Int(pixelY))) relative to window.")
            InputSimulator.shared.click(at: CGPoint(x: pixelX, y: pixelY))
        }
    }
}
