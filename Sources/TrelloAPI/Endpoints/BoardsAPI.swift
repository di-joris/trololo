import Foundation

extension TrelloClient {
    /// Fetches all open cards on a board.
    ///
    /// - Parameter boardId: The board ID.
    /// - Returns: The cards on the board.
    public func getBoardCards(boardId: String) async throws -> [Card] {
        try await get([Card].self, path: "/boards/\(boardId)/cards")
    }
}
