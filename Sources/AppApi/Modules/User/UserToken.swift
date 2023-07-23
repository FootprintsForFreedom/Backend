import Foundation

public extension User {
    /// Contains the user token data transfer objects.
    enum Token: ApiModelInterface {
        public typealias Module = User
    }
}

public extension User.Token {
    /// Used to detail tokens.
    struct Detail: Codable {
        /// The Refresh  Token which can be used to request a new Access Token and Refresh Token pair.
        public let refreshToken: String
        /// The Access Token which can be used to access other api endpoints.
        public let accessToken: String
        /// The user to which the token belongs.
        public let user: User.Account.Detail

        enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
            case accessToken = "access_token"
            case user
        }

        /// Creates a token detail object.
        /// - Parameters:
        ///   - accessToken: The Access Token which can be used to access other api endpoints.
        ///   - refreshToken: The Refresh  Token which can be used to request a new Access Token and Refresh Token pair.
        ///   - user: The user to which the token belongs.
        public init(refreshToken: String, accessToken: String, user: User.Account.Detail) {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.user = user
        }
    }
}
