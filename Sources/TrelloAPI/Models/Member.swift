import Foundation

/// A Trello member (user) profile.
public struct Member: Codable, Sendable, Equatable {
    public let id: String
    public let username: String?
    public let fullName: String?
    public let initials: String?
    public let bio: String?
    public let url: String?
    public let email: String?
    public let avatarUrl: String?
    public let memberType: String?
    public let confirmed: Bool?
    public let status: String?

    public init(
        id: String,
        username: String? = nil,
        fullName: String? = nil,
        initials: String? = nil,
        bio: String? = nil,
        url: String? = nil,
        email: String? = nil,
        avatarUrl: String? = nil,
        memberType: String? = nil,
        confirmed: Bool? = nil,
        status: String? = nil
    ) {
        self.id = id
        self.username = username
        self.fullName = fullName
        self.initials = initials
        self.bio = bio
        self.url = url
        self.email = email
        self.avatarUrl = avatarUrl
        self.memberType = memberType
        self.confirmed = confirmed
        self.status = status
    }
}
