import Vapor
import JWT

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
