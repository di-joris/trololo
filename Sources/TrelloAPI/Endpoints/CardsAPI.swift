import Foundation

extension TrelloClient {
    /// Fetches a card by its ID.
    ///
    /// - Parameter id: The card ID.
    /// - Returns: The card.
    public func getCard(id: String) async throws -> Card {
        try await get(Card.self, path: "/cards/\(id)")
    }
}
