import Foundation

extension TrelloClient {
    /// Fetches a list by its ID.
    ///
    /// - Parameter id: The list ID.
    /// - Returns: The list.
    public func getList(id: String) async throws -> TrelloList {
        try await get(TrelloList.self, path: "/lists/\(id)")
    }

    /// Gets all of the cards on a list.
    ///
    /// - Parameter listId: The list ID.
    /// - Returns: The cards on the list.
    public func getListCards(listId: String) async throws -> [Card] {
        try await get([Card].self, path: "/lists/\(listId)/cards")
    }
}
