import Foundation

/// A Trello organization (workspace).
public struct Organization: Codable, Sendable, Equatable {
    public let id: String
    public let name: String?
    public let displayName: String?
    public let url: String?
    public let idBoards: [String]?

    public init(
        id: String,
        name: String? = nil,
        displayName: String? = nil,
        url: String? = nil,
        idBoards: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.url = url
        self.idBoards = idBoards
    }
}
