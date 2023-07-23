import AppApi
import Vapor

/// Represents an authenticated user.
public struct AuthenticatedUser: Authenticatable {
    /// The user id.
    public let id: UUID

    /// Wether or not the user has verified their E-Mail.
    public let verified: Bool

    /// The user's role.
    public let role: User.Role

    /// Initializes an authenticated user.
    /// - Parameters:
    ///   - id: The user id.
    ///   - verified: Wether or not the user has verified their E-Mail.
    ///   - role: The user's role.
    public init(id: UUID, verified: Bool, role: User.Role) {
        self.id = id
        self.verified = verified
        self.role = role
    }
}
