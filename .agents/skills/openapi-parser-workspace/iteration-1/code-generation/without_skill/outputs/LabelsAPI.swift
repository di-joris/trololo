import Foundation

extension TrelloClient {
    /// Fetches a label by its ID.
    ///
    /// - Parameter id: The label ID.
    /// - Returns: The label.
    public func getLabel(id: String) async throws -> Label {
        try await get(Label.self, path: "/labels/\(id)")
    }

    /// Gets all of the labels on a board.
    ///
    /// - Parameter boardId: The board ID.
    /// - Returns: The labels on the board.
    public func getBoardLabels(boardId: String) async throws -> [Label] {
        try await get([Label].self, path: "/boards/\(boardId)/labels")
    }
}
