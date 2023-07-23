import AppApi
import Fluent
import Vapor
import JWT

// TODO: split files, add migration

final class UserTokenFamilyModel: DatabaseModelInterface, Authenticatable {
    typealias Module = UserModule

    enum FieldKeys {
        enum v1 {
            static var tokenType: FieldKey { "token_type" }
            static var lastTokenRefresh: FieldKey { "last_token_refresh" }
            static var userId: FieldKey { "user_id" }
        }
    }

    @ID() var id: UUID?
    @Enum(key: FieldKeys.v1.tokenType) var tokenType: UserTokenType
    @Field(key: FieldKeys.v1.lastTokenRefresh) var lastTokenRefresh: Date
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel

    init() { }

    init(
        id: UUID? = nil,
        userId: UUID,
        tokenType: UserTokenType
    ) {
        self.id = id
        self.$user.id = userId
        self.tokenType = tokenType
    }
}

struct UserToken: JWTPayload, Equatable {
    /// Calculates the expiration date for a given token type.
    /// - Parameter tokenType: The type of token for which the expiration date should be calculated.
    /// - Returns: The calculated expiration date for the given token type.
    private static func expiration(for tokenType: UserTokenType, startingAt date: Date) -> Date {
        let calendar = Calendar.current
        switch tokenType {
        case .contentAccess:
            return calendar.date(byAdding: .minute, value: 15, to: date)!
        case .tokenRefresh:
            return calendar.date(byAdding: .day, value: 100, to: date)!
        case .verification:
            return calendar.date(byAdding: .minute, value: 10, to: date)!
        }
    }

    /// The subject (user id) of the token.
    ///
    /// This is the same as the subject claim.
    let userId: UUID

    /// Wether or not the user has verified their E-Mail.
    ///
    /// Only set for Access Tokens.
    let emailVerified: Bool?

    /// The user's role.
    ///
    /// Only set for Access Tokens.
    let userRole: User.Role?

    /// The date and time the token was issued at.
    ///
    /// The issued at date is used to invalidate tokens.
    /// If the issued at date is older than the last saved token refresh in the database
    /// the token is invalid.
    let issuedAt: IssuedAtClaim

    /// The time after which the token expires.
    let expiration: ExpirationClaim

    /// The type of the token
    ///
    /// Default access tokens can be used to access the content the user the token belongs to
    /// is authorized to access.
    ///
    /// Refresh tokens can only be used to request a new default access token.
    /// Whenever a new access token is requested a new refresh token is also returned
    /// and both old tokens are invalidated.
    /// Refresh tokens cannot be used to access content.
    ///
    /// Email Verification tokens can only be used to verify the email address of a user.
    /// They cannot be used for content access or requesting new tokens.
    let tokenType: UserTokenType

    /// The family of the token.
    ///
    /// Only set for Refresh Tokens.
    let tokenFamily: UUID?

    private init(userId: UUID, emailVerified: Bool?, userRole: User.Role?, issuedAt: IssuedAtClaim, expiration: ExpirationClaim, tokenType: UserTokenType, tokenFamily: UUID?) {
        self.userId = userId
        self.emailVerified = emailVerified
        self.userRole = userRole
        self.issuedAt = issuedAt
        self.expiration = expiration
        self.tokenType = tokenType
        self.tokenFamily = tokenFamily
    }

    enum CodingKeys: String, CodingKey {
        case userId = "sub"
        case emailVerified = "email_verified"
        case userRole = "roles"
        case issuedAt = "iat"
        case expiration = "exp"
        case tokenType = "aud"
        case tokenFamily = "token_family"
    }

    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }

    /// Verify that the token was issued after the reference date since otherwise
    /// it is already expired.
    func verify(issuedAfter referenceDate: Date) throws {
        if referenceDate > issuedAt.value {
            throw JWTError.tokenExpired
        }
    }

    /// Verify that the given audience is included as one of the claim's
    /// intended audiences by simple string comparison.
    public func verify(intendedAudienceIncludes audience: UserTokenType) throws {
        guard tokenType == audience else {
            throw JWTError.claimVerificationFailure(name: "aud", reason: "not intended for \(audience)")
        }
    }
}

extension UserToken {
    /// Creates an Access Token for the given user.
    static func createAccessToken(for user: UserAccountModel) throws -> Self {
        let issuedAtDate = Date()
        let expirationDate = expiration(for: .contentAccess, startingAt: issuedAtDate)
        return try .init(
            userId: user.requireID(),
            emailVerified: user.verified,
            userRole: user.role,
            issuedAt: .init(value: issuedAtDate),
            expiration: .init(value: expirationDate),
            tokenType: .contentAccess,
            tokenFamily: nil
        )
    }

    /// Creates a Refresh Token for the given user in a new token family.
    static func createRefreshToken(for user: UserAccountModel, on db: Database) async throws -> Self {
        let tokenFamily = try UserTokenFamilyModel(userId: user.requireID(), tokenType: .tokenRefresh)
        return try await createRefreshToken(for: user, in: tokenFamily, on: db)
    }

    /// Creates a Refresh Token for the given user in the specified token family.
    ///
    /// By creating a new token all existing tokens in this family will be invalidated.
    static func createRefreshToken(for user: UserAccountModel, in tokenFamily: UserTokenFamilyModel, on db: Database) async throws -> Self {
        let issuedAtDate = Date()
        let expirationDate = expiration(for: .tokenRefresh, startingAt: issuedAtDate)

        tokenFamily.lastTokenRefresh = issuedAtDate - 1
        try await tokenFamily.save(on: db)

        return try .init(
            userId: user.requireID(),
            emailVerified: nil,
            userRole: nil,
            issuedAt: .init(value: issuedAtDate),
            expiration: .init(value: expirationDate),
            tokenType: .tokenRefresh,
            tokenFamily: tokenFamily.requireID()
        )
    }

    /// Creates an verification token for the given user in a new token family.
    static func createVerificationToken(for user: UserAccountModel, on db: Database) async throws -> Self {
        let tokenFamily = try UserTokenFamilyModel(userId: user.requireID(), tokenType: .verification)
        return try await createVerificationToken(for: user, in: tokenFamily, on: db)
    }

    /// Creates an verification token for the given user in the specified token family.
    ///
    /// By creating a new token all existing tokens in this family will be invalidated.
    static func createVerificationToken(for user: UserAccountModel, in tokenFamily: UserTokenFamilyModel, on db: Database) async throws -> Self {
        let issuedAtDate = Date()
        let expirationDate = expiration(for: .verification, startingAt: issuedAtDate)

        tokenFamily.lastTokenRefresh = issuedAtDate - 1
        try await tokenFamily.save(on: db)

        return try .init(
            userId: user.requireID(),
            emailVerified: nil,
            userRole: nil,
            issuedAt: .init(value: issuedAtDate),
            expiration: .init(value: expirationDate),
            tokenType: .verification,
            tokenFamily: tokenFamily.requireID()
        )
    }
}

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
