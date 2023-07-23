import Vapor
import JWT

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
