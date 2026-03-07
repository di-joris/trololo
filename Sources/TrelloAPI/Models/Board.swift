import Foundation

/// A Trello board.
public struct Board: Codable, Sendable, Equatable {
    public let id: String
    public let name: String?
    public let desc: String?
    public let closed: Bool?
    public let url: String?
    public let shortUrl: String?
    public let idOrganization: String?
    public let pinned: Bool?
    public let starred: Bool?

    public init(
        id: String,
        name: String? = nil,
        desc: String? = nil,
        closed: Bool? = nil,
        url: String? = nil,
        shortUrl: String? = nil,
        idOrganization: String? = nil,
        pinned: Bool? = nil,
        starred: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.desc = desc
        self.closed = closed
        self.url = url
        self.shortUrl = shortUrl
        self.idOrganization = idOrganization
        self.pinned = pinned
        self.starred = starred
    }
}
