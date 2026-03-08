import Foundation

public struct TrelloList: Codable, Sendable, Equatable {
    public let id: String
    public let name: String?
    public let closed: Bool?
    public let pos: Double?
    public let softLimit: String?
    public let idBoard: String?
    public let subscribed: Bool?

    public init(
        id: String,
        name: String? = nil,
        closed: Bool? = nil,
        pos: Double? = nil,
        softLimit: String? = nil,
        idBoard: String? = nil,
        subscribed: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.closed = closed
        self.pos = pos
        self.softLimit = softLimit
        self.idBoard = idBoard
        self.subscribed = subscribed
    }
}
