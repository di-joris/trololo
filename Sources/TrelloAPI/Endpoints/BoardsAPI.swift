import Foundation

extension TrelloClient {
    /// Gets all of the open cards on a board.
    ///
    /// - Parameter boardId: The board ID.
    /// - Returns: The cards on the board.
    public func getBoardCards(boardId: String) async throws -> [Card] {
        try await get([Card].self, path: "/boards/\(boardId)/cards")
    }

    /// Fetches a board by its ID.
    ///
    /// - Parameter id: The board ID.
    /// - Returns: The board.
    public func getBoard(id: String) async throws -> Board {
        try await get(Board.self, path: "/boards/\(id)")
    }

    /// Gets all of the lists on a board.
    ///
    /// - Parameter boardId: The board ID.
    /// - Returns: The lists on the board.
    public func getBoardLists(boardId: String) async throws -> [TrelloList] {
        try await get([TrelloList].self, path: "/boards/\(boardId)/lists")
    }
}
