import Foundation

/// Defines the four suits in a standard deck.
enum Suit: String, CaseIterable, Sendable {
    case clubs = "Clubs"
    case spades = "Spades"
    case hearts = "Hearts"
    case diamonds = "Diamonds"
    
    var color: CardColor {
        switch self {
        case .clubs, .spades: return .black
        case .hearts, .diamonds: return .red
        }
    }
    
    var symbol: String {
        switch self {
        case .clubs: return "♣️"
        case .spades: return "♠️"
        case .hearts: return "❤️"
        case .diamonds: return "♦️"
        }
    }
}

/// Defines the ranks from Ace to King.
enum Rank: Int, CaseIterable, Comparable, Sendable {
    case ace = 1, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king
    
    static func < (lhs: Rank, rhs: Rank) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var shortName: String {
        switch self {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default: return "\(self.rawValue)"
        }
    }
}

/// Simple color classification.
enum CardColor: String, Sendable {
    case red = "Red"
    case black = "Black"
}

/// Represents a single Solitaire card.
struct Card: Equatable, Sendable, CustomStringConvertible {
    let rank: Rank
    let color: CardColor
    let suit: Suit? // May be null if only rank and color are identified
    let location: CGRect // Normalized bounding box (0-1) from Vision
    
    var description: String {
        return "[\(color.rawValue) \(rank.shortName)]"
    }
}

/// Represents a region on the board.
enum BoardRegion: Equatable, Sendable {
    case tableau(index: Int)   // Columns 0-6
    case foundation(index: Int) // Piles 0-3
    case stock
    case waste
}

/// Represents a potential move identified by the Brain.
struct SolitaireMove: Sendable {
    let card: Card
    let source: BoardRegion
    let destination: BoardRegion
    let priority: Int // Higher means more important
}
