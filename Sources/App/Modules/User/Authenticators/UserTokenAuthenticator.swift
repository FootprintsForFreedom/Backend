import Vapor
import JWT

extension JWTError {
    /// JWT Error thrown when the submitted token is expired.
    static let tokenExpired = Self.claimVerificationFailure(name: "exp", reason: "expired")
}

/// Authenticator used to sign in users with a Bearer Token in the format of a JWT.
struct UserJWTAccessTokenAuthenticator: AsyncJWTAuthenticator {
    func authenticate(jwt: UserToken, for req: Request) async throws {
        guard !req.auth.has(UserAccountModel.self) else { return }
//        debugPrint(req.auth)
        do {
            try jwt.verify(intendedAudienceIncludes: .contentAccess)
            req.auth.login(AuthenticatedUser(
                id: jwt.userId,
                verified: jwt.emailVerified!,
                role: jwt.userRole!
            ))
        } catch is JWTError {
            throw Abort(.unauthorized)
        }
    }
}

struct UserJWTRefreshTokenAuthenticator: AsyncJWTAuthenticator {
    func authenticate(jwt: UserToken, for req: Request) async throws {
        do {
            try jwt.verify(intendedAudienceIncludes: .tokenRefresh)
            guard let user = try await UserAccountModel.find(jwt.userId, on: req.db),
                  let tokenFamily = try await UserTokenFamilyModel.find(jwt.tokenFamily, on: req.db) else {
                throw JWTError.tokenExpired
            }
            try jwt.verify(issuedAfter: tokenFamily.lastTokenRefresh)
            req.auth.login(user)
            req.auth.login(tokenFamily)
        } catch is JWTError {
            throw Abort(.unauthorized)
        }
    }
}

struct UserJWTVerificationTokenAuthenticator: AsyncJWTAuthenticator {
    func authenticate(jwt: UserToken, for req: Request) async throws {
        do {
            try jwt.verify(intendedAudienceIncludes: .verification)
            guard let user = try await UserAccountModel.find(jwt.userId, on: req.db),
                  let tokenFamily = try await UserTokenFamilyModel.find(jwt.tokenFamily, on: req.db) else {
                throw JWTError.tokenExpired
            }
            try jwt.verify(issuedAfter: tokenFamily.lastTokenRefresh)
            req.auth.login(user)
        } catch is JWTError {
            throw Abort(.unauthorized)
        }
    }
}
