enum UserTokenType: String, Codable, DatabaseEnumInterface {
    typealias Module = UserModule

    static let schema = "user_token_type"

    /// Token used to access content.
    case contentAccess

    /// Token used to refresh access tokens.
    case tokenRefresh

    /// Token used to verify a user's identity. Usually sent via E-Mail..
    case verification
}
