import Foundation

/// A Trello label.
public struct Label: Codable, Sendable, Equatable {
    public let id: String
    public let idBoard: String?
    public let name: String?
    public let color: String?

    public init(
        id: String,
        idBoard: String? = nil,
        name: String? = nil,
        color: String? = nil
    ) {
        self.id = id
        self.idBoard = idBoard
        self.name = name
        self.color = color
    }
}
