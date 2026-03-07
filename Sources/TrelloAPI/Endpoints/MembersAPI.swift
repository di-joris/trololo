import Foundation

extension TrelloClient {
    /// Fetches a member's profile.
    ///
    /// - Parameter id: The member ID or `"me"` for the authenticated user.
    /// - Returns: The member profile.
    public func getMember(id: String = "me") async throws -> Member {
        try await get(Member.self, path: "/members/\(id)")
    }
}
