import Foundation

extension TrelloClient {
    /// Gets all of the open cards on a board.
    ///
    /// - Parameter boardId: The board ID.
    /// - Returns: The cards on the board.
    public func getBoardCards(boardId: String) async throws -> [Card] {
        try await get([Card].self, path: "/boards/\(boardId)/cards")
    }
}
