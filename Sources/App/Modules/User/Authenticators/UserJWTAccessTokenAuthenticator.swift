import JWT
import Vapor

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
