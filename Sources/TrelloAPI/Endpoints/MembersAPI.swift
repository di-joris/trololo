import Foundation

extension TrelloClient {
    /// Fetches a member's profile.
    ///
    /// - Parameter id: The member ID or `"me"` for the authenticated user.
    /// - Returns: The member profile.
    public func getMember(id: String = "me") async throws -> Member {
        try await get(Member.self, path: "/members/\(id)")
    }

    /// Fetches the boards that a member belongs to.
    ///
    /// - Parameter memberId: The member ID or `"me"` for the authenticated user.
    /// - Returns: The member's boards.
    public func getMemberBoards(memberId: String = "me") async throws -> [Board] {
        try await get([Board].self, path: "/members/\(memberId)/boards")
    }

    /// Fetches cards the member is assigned to.
    ///
    /// - Parameter memberId: The member ID or `"me"` for the authenticated user.
    /// - Returns: The member's cards.
    public func getMemberCards(memberId: String = "me") async throws -> [Card] {
        try await get([Card].self, path: "/members/\(memberId)/cards")
    }

    /// Fetches the organizations (workspaces) a member belongs to.
    ///
    /// - Parameter memberId: The member ID or `"me"` for the authenticated user.
    /// - Returns: The member's organizations.
    public func getMemberOrganizations(memberId: String = "me") async throws -> [Organization] {
        try await get([Organization].self, path: "/members/\(memberId)/organizations")
    }
}
