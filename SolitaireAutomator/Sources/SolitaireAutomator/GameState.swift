import Foundation

/// Manages the visual memory and logical state of the Solitaire game.
@MainActor
class GameState {
    static let shared = GameState()
    
    // MARK: - Memory (The Current View)
    
    /// The 7 columns of the tableau. The last item is the top-most (front) card.
    private(set) var tableauPiles: [[Card]] = Array(repeating: [], count: 7)
    
    /// The 4 foundation piles (by suit).
    private(set) var foundationPiles: [[Card]] = Array(repeating: [], count: 4)
    
    /// The current playable card from the Waste pile.
    private(set) var topWasteCard: Card?
    
    private init() {}
    
    // MARK: - State Updates
    
    /// Updates the observed top card for a specific tableau column.
    func updateTableau(index: Int, cards: [Card]) {
        guard index >= 0 && index < 7 else { return }
        if tableauPiles[index] != cards {
             Log.debug("Memory Update: Tableau[\(index)] changed to \(cards)")
             tableauPiles[index] = cards
        }
    }
    
    /// Updates the observed top card for a specific foundation.
    func updateFoundation(index: Int, cards: [Card]) {
        guard index >= 0 && index < 4 else { return }
        if foundationPiles[index] != cards {
            Log.debug("Memory Update: Foundation[\(index)] changed to \(cards)")
            foundationPiles[index] = cards
        }
    }
    
    func updateWaste(card: Card?) {
        if topWasteCard != card {
            Log.debug("Memory Update: Top Waste Card changed to \(card?.description ?? "Empty")")
            self.topWasteCard = card
        }
    }
    
    // MARK: - Legal Move Detection
    
    /// Generates all possible legal moves based on the current observed state.
    func findLegalMoves() -> [SolitaireMove] {
        var moves: [SolitaireMove] = []
        Log.debug("Brain Evaluation: Scanning for legal moves among \(tableauPiles.map { $0.count }.reduce(0, +)) visible tableau cards...")
        
        // 1. Check Tableau to Foundation moves
        for (i, pile) in tableauPiles.enumerated() {
            guard let topCard = pile.last else { continue }
            if canMoveToFoundation(topCard) {
                let move = SolitaireMove(
                    card: topCard,
                    source: .tableau(index: i),
                    destination: findBestFoundation(for: topCard),
                    priority: topCard.rank == .ace ? 100 : 80 // Aces are top priority
                )
                Log.debug("Potential Move Found: \(topCard) -> Foundation (Priority: \(move.priority))")
                moves.append(move)
            }
        }
        
        // 2. Check Tableau to Tableau moves
        for (srcIndex, srcPile) in tableauPiles.enumerated() {
            guard let card = srcPile.last else { continue }
            
            for (dstIndex, dstPile) in tableauPiles.enumerated() {
                if srcIndex == dstIndex { continue }
                
                if let dstCard = dstPile.last {
                    if isLegalTableauMove(card: card, onto: dstCard) {
                        moves.append(SolitaireMove(
                            card: card,
                            source: .tableau(index: srcIndex),
                            destination: .tableau(index: dstIndex),
                            priority: 50
                        ))
                    }
                } else if card.rank == .king {
                    // Empty column can take a King
                    moves.append(SolitaireMove(
                        card: card,
                        source: .tableau(index: srcIndex),
                        destination: .tableau(index: dstIndex),
                        priority: 40
                    ))
                }
            }
        }
        
        // 3. Waste to Tableu/Foundation (TODO)
        
        return moves.sorted { $0.priority > $1.priority }
    }
    
    // MARK: - Rule Helpers
    
    private func isLegalTableauMove(card: Card, onto destCard: Card) -> Bool {
        // Descending order and alternating colors
        return card.rank.rawValue == destCard.rank.rawValue - 1 && 
               card.color != destCard.color
    }
    
    private func canMoveToFoundation(_ card: Card) -> Bool {
        // Find if this card is Ace or follows the current foundation top
        for pile in foundationPiles {
            if pile.isEmpty {
                if card.rank == .ace { return true }
            } else if let top = pile.last {
                if top.suit == card.suit && card.rank.rawValue == top.rank.rawValue + 1 {
                    return true
                }
            }
        }
        return false
    }
    
    private func findBestFoundation(for card: Card) -> BoardRegion {
        // Simplified: return first empty or matching suit
        return .foundation(index: 0) // Placeholder
    }
}
