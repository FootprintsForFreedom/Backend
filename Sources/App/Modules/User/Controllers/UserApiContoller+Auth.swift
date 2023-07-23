import AppApi
import JWT
import Vapor

extension User.Token.Detail: Content { }

extension UserApiController {
    func signInApi(req: Request) async throws -> User.Token.Detail {
        /// Require user to be signed in
        let user = try req.auth.require(UserAccountModel.self)
        /// create signed tokens for the user
        let (signedRefreshToken, signedAccessToken) = try await user.createSignedTokenPair(on: req)
        /// return the tokens with the own detail representation of the user
        return try User.Token.Detail(refreshToken: signedRefreshToken, accessToken: signedAccessToken, user: user.ownDetail())
    }

    func refreshTokenApi(req: Request) async throws -> User.Token.Detail {
        /// Require user to be signed in
        let user = try req.auth.require(UserAccountModel.self)
        let tokenFamily = try req.auth.require(UserTokenFamilyModel.self)
        /// create signed tokens for the user
        let (signedRefreshToken, signedAccessToken) = try await user.createSignedTokenPair(in: tokenFamily, on: req)
        /// return the tokens with the own detail representation of the user
        return try User.Token.Detail(refreshToken: signedRefreshToken, accessToken: signedAccessToken, user: user.ownDetail())
    }

    func signOutApi(req: Request) async throws -> HTTPStatus {
        /// Require user to be signed in
        let user = try req.auth.require(UserAccountModel.self)
        let tokenFamily = try req.auth.require(UserTokenFamilyModel.self)
        /// Check if sign out all sessions
        if let signOutAllSessions = try? req.query.get(Bool.self, at: "all"), signOutAllSessions == true {
            /// Remove all token families and thereby invalidate all refresh tokens of this user
            try await user.$tokenFamilies.query(on: req.db).delete(force: true)
        } else {
            /// Remove the token family and thereby invalidate all refresh tokens in this family
            try await tokenFamily.delete(on: req.db)
        }
        /// log the user out
        req.auth.logout(UserAccountModel.self)
        req.auth.logout(UserTokenFamilyModel.self)
        /// return ok if user was signed out successfully
        return .ok
    }

    func setupAuthRoutes(_ routes: RoutesBuilder) {
        routes
            .grouped(UserCredentialsAuthenticator())
            .grouped(UserBasicAuthenticator())
            .grouped(UserAccountModel.guardMiddleware())
            .post("sign-in", use: signInApi)

        routes
            .grouped(UserJWTRefreshTokenAuthenticator())
            .grouped(UserAccountModel.guardMiddleware())
            .post("token-refresh", use: refreshTokenApi)

        routes
            .grouped(UserJWTRefreshTokenAuthenticator())
            .grouped(UserAccountModel.guardMiddleware())
            .post("sign-out", use: signOutApi)
    }
}
