import Foundation

/// A Trello card.
public struct Card: Codable, Sendable, Equatable {
    public let id: String
    public let name: String?
    public let desc: String?
    public let closed: Bool?
    public let due: String?
    public let dueComplete: Bool?
    public let idBoard: String?
    public let idList: String?
    public let url: String?
    public let shortUrl: String?
    public let pos: Double?
    public let idMembers: [String]?

    public init(
        id: String,
        name: String? = nil,
        desc: String? = nil,
        closed: Bool? = nil,
        due: String? = nil,
        dueComplete: Bool? = nil,
        idBoard: String? = nil,
        idList: String? = nil,
        url: String? = nil,
        shortUrl: String? = nil,
        pos: Double? = nil,
        idMembers: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.desc = desc
        self.closed = closed
        self.due = due
        self.dueComplete = dueComplete
        self.idBoard = idBoard
        self.idList = idList
        self.url = url
        self.shortUrl = shortUrl
        self.pos = pos
        self.idMembers = idMembers
    }
}
